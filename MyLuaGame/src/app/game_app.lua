--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2016 TianJi Information Technology Inc.
--
-- GameApp
--

local isIdler = isIdler

local GameSyncPeriod = 20 * 60  -- 20分钟
local CleanCachePeriod = 5 * 60 -- 5分钟

local GameApp = class("GameApp", cc.load("mvc").AppBase)
local Packet = require 'net.tcpacket'

------ add by chanlong ------
local payHistory = require "app.views.pay.pay_history"

function GameApp:getPayhistory()
	return payHistory:getMe()
end

------ end add ------




local function addSearchPath(path)
	local pathL10n = getL10nField(path)
	-- 0号更新包和常规更新包，通过res_slim已经没有resource_en这样的目录了
	-- resource_en多语言目录只存在windows开发目录
	-- TODO: cocos compile for ios 脚本陈旧，未调用res_slim
	if path ~= pathL10n and device.platform == "windows" then
		cc.FileUtils:getInstance():addSearchResolutionsOrder(pathL10n)
	end
	cc.FileUtils:getInstance():addSearchResolutionsOrder(path)
end

local function initSearchPath()
	if dev.DEBUG_MODE and dev.DEV_PATH then
		cc.FileUtils:getInstance():addSearchResolutionsOrder(dev.DEV_PATH .. "/res")
		cc.FileUtils:getInstance():addSearchResolutionsOrder(dev.DEV_PATH .. "/res/uijson")

		addSearchPath(dev.DEV_PATH .. "/res/resources")
		addSearchPath(dev.DEV_PATH .. "/res/spine")
		addSearchPath(dev.DEV_PATH .. "/res/sound")
		addSearchPath(dev.DEV_PATH .. "/res/video")
	end

	cc.FileUtils:getInstance():addSearchResolutionsOrder("res")
	cc.FileUtils:getInstance():addSearchResolutionsOrder("res/uijson")
	addSearchPath("res/resources")
	addSearchPath("res/spine")
	addSearchPath("res/sound")
	addSearchPath("res/video")

	local paths = cc.FileUtils:getInstance():getSearchPaths()
	for i, v in ipairs(paths) do
		printInfo("SearchPaths %d %s", i, v)
	end
	paths = cc.FileUtils:getInstance():getSearchResolutionsOrder()
	for i, v in ipairs(paths) do
		printInfo("SearchResolutionsOrder %d %s", i, v)
	end
	printInfo("WritablePath %s", cc.FileUtils:getInstance():getWritablePath())
end
GameApp.initSearchPath = initSearchPath

local preloadEntryID
local preloadStartCountdown = 2 -- 2 times
local preloadEffectIdx = 0
local function onPreload()
	preloadStartCountdown = preloadStartCountdown - 1
	if preloadStartCountdown > 0 then return end
	preloadStartCountdown = 0

	if preloadEffectIdx < #ui.PRELOAD_EFFECT_LIST then
		preloadEffectIdx = preloadEffectIdx + 1
		audio.preloadSound(ui.PRELOAD_EFFECT_LIST[preloadEffectIdx])
	else
		display.director:getScheduler():unscheduleScriptEntry(preloadEntryID)
	end
end

local function initAppGlobal()
	if CC_SHOW_FPS then
		--display.director:setDisplayStats(true)
	end

	display.director:setDirtyDrawEnable(true)
	cc.Image:setPVRImagesHavePremultipliedAlpha(true)

	cache.init()
end


function GameApp:onCreate()
	if not globals.ROBOT_TEST then
		initSearchPath()
	end

	self.net = require("app.game_net").new(self)
	self.ui = require("app.game_ui").new(self)
	self.model = require("app.models.game").new(self)
	self.protocol = require("app.game_protocol").new(self)
	self.subPack = require("app.subpackage").new(self)

	self.serverInfo = {}
	self.keepAliveCountdown = nil -- 登录后开始keepalive
	self.reqQueue = {}
	self.reqHead = 0
	self.reqTail = 0
	self.reqing = false -- 请求中，除玩家操作外还有定时等程序行为触发多次请求
	self.reqDelay = false -- 请求延迟，某些关闭动画时进行请求，暂时延迟在内网测试中必现问题
	self.noSlientReqCount = 0

	self.net:initLoginUrl()

	initAppGlobal()

	local scheduler = display.director:getScheduler()
	scheduler:scheduleScriptFunc(functools.partial(self.onCleanCache, self), 1 * 60, false)
	preloadEntryID = scheduler:scheduleScriptFunc(onPreload, 1, false)

	-- 帧率，音量设置
	local fps = userDefault.getForeverLocalKey("fps", 60, { rawKey = true })
	cc.Director:getInstance():setAnimationInterval(1.0 / fps)
	local volume = userDefault.getForeverLocalKey("musicVolume", 100, { rawKey = true })
	audio.setMusicVolume(volume / 100)
	local volume = userDefault.getForeverLocalKey("effectVolume", 100, { rawKey = true })
	audio.setSoundsVolume(volume / 100)

	-- 屏幕常亮
	cc.Device:setKeepScreenOn(true)
end

function GameApp:enterScene(sceneName, transition, time, more)
	local view = self.ui:enterScene(sceneName, transition, time, more)

	self.scene = self.ui.scene
	self.scene:scheduleUpdate(handler(self, self.onUpdate))

	return view
end

function GameApp:setGameServerAddr(addr)
	self.serverInfo = addr
	return self.net:setGameAddr(addr)
end

function GameApp:getNotice(cb)
	if self.notice then return cb(self.notice) end
	self.net:doGET(self.net.noticeUrl, function(result, err)
		if result then
			local obj = json.decode(result)
			self.notice = obj
			return cb(self.notice)
		end
	end)
end

-- auto convert idler to normal lua value
local function flatRequestArgsArray(arr, narr)
	arr = table.flatArray(arr, narr)
	-- fix bug like {nil, 1, nil} paramters
	return unpack(arr, 1, narr)
end

local requestFuncs = {}
requestFuncs.__index = requestFuncs
function requestFuncs.params(t, ...)
	t._nargs = select('#', ...)
	t._args = { ... }
	return t
end

function requestFuncs.slient(t)
	t._slient = true
	return t
end

-- show dialog error box
function requestFuncs.onErrClose(t, f)
	t._onErrClose = f
	return t
end

-- before onErrClose, no error dialog
function requestFuncs.onErrCall(t, f)
	t._onErrCall = f
	return t
end

-- delay game model sync
-- for animation
function requestFuncs.delay(t, delay)
	t._delay = delay
	return t
end

-- wait flag before game model sync
-- TODO: if remoteRunnerFuncs.restart in battle_entrance\remote.lua, it had problem need to fix
function requestFuncs.wait(t, wait)
	assert(type(wait) == "table" or type(wait) == "function", "wait need table or function, like {true}")

	if type(wait) == "table" then
		t._wait = function()
			return wait[1]
		end
	else
		t._wait = wait
	end
	return t
end

function requestFuncs.onResponse(t, f)
	t._onResponse = f
	return t
end

function requestFuncs.onBeforeSync(t, f)
	t:wait({ true }):onResponse(function(...)
		f(...)
	end)
	return t
end

function requestFuncs.doit(t, cb)
	t._cb = cb
	return t._app:_queueRequest(t)
end

-- gGameApp:requestServerCustom("/chat"):params("hello"):onErrClose(f1):doit(f2)
function GameApp:requestServerCustom(url)
	print("requestServerCustom:", url)
	-- protocol
	local reqProtocol = self.protocol[url]
	if reqProtocol == nil then
		error(string.format("no such request protocol %s, see GameProtocol", url))
	end

	return setmetatable({
		_app = self,
		_req = reqProtocol,
		_url = url,
	}, requestFuncs)
end

function GameApp:_queueRequest(t, front)
	local oldID = t._id
	if front then
		self.reqHead = self.reqHead - 1
		t._id = self.reqHead + 1
	else
		self.reqTail = self.reqTail + 1
		t._id = self.reqTail
	end
	t._schedulingView = self.schedulingView
	if t._schedulingView then
		t._schedulingViewName = tostring(t._schedulingView)
	end

	t._topView, t._topViewName = self.ui:getTopStackUI()

	self.reqQueue[t._id] = t
	if oldID then
		printInfo("re-queueRequest %s %s -> %s", front and "front" or "back", oldID, t._id)
	end
	if not t._slient then
		if self.noSlientReqCount == 0 then
			self.ui:showConnecting()
		end
		self.noSlientReqCount = self.noSlientReqCount + 1
	end
	-- if the queue was idle, request right now
	self:_checkRequest()
	self.ui:disableTouchDispatch(0, false)
	return t._id
end

function GameApp:_checkRequest()
	if self.reqing or self.reqDelay then return end

	while self.reqHead < self.reqTail do
		self.reqHead = self.reqHead + 1
		local t = self.reqQueue[self.reqHead]
		if t then
			if self:_doRequest(t) then
				self.reqQueue[t._id] = nil
			else
				self.reqHead = math.min(t._id - 1, self.reqHead)
			end
			return
		end
	end
end

function GameApp:_clearRequest()
	while self.reqHead < self.reqTail do
		self.reqHead = self.reqHead + 1
		self.reqQueue[self.reqHead] = nil
	end
	self.reqing = false
	self.reqDelay = false
end

function GameApp:_doRequest(t)
	printInfo('doRequest %s %s %s', t._id, t._url, t._slient and "slient" or "")
	self.reqing = true

	assert(not (t._delay and t._wait), "could not req with both delay and wait")
	assert((t._onResponse == nil) or (t._onResponse and (t._delay or t._wait)), "pls set delay or wait for request")
	local doSync
	if t._delay or t._wait then
		local sync = self.model:delaySyncOnce()
		self.ui:disableTouchDispatch(nil, false)
		doSync = function()
			sync()
			self.ui:disableTouchDispatch(nil, true)
		end
	end

	local slient = t._slient
	local tic = os.clock()
	t._req(self.protocol, t._url, function(ret, err)
		printInfo("doRequest %s %s, ret=%s err=%s, rtt time cost %s s", t._id, t._url,
			type(ret) == "table" and ret.ret or tostring(ret), dumps(err), os.clock() - tic)
		self.reqing = false

		if self.keepAliveCountdown then
			self.keepAliveCountdown = GameSyncPeriod
		end
		if not slient then
			self.noSlientReqCount = math.max(self.noSlientReqCount - 1, 0)
			if self.noSlientReqCount == 0 then
				if not err then
					if assertInWindows(self.ui:isConnecting(), "request recv %s be rejected, check isConnecting", t._url) then
						return
					end
				end
				self.ui:hideConnecting()
			end
		end

		-- first. error handle
		if err then
			printWarn("doRequest %s %s %s_err=%s", t._id, t._url, err.system and "system" or "server", err.err)
			if doSync then doSync() end

			-- server auth error handler
			if err.err == "auth_error" then
				return self.ui:onAuthError()
			end
			-- system error handler
			if err.system then
				if err.err == "network_lost" then
					self.ui:onRequestError(err, function()
						if not slient then
							if self.noSlientReqCount == 0 then
								self.ui:showConnecting()
							end
							self.noSlientReqCount = self.noSlientReqCount + 1
						end
						if self.net.gameSession:isShutdown() then
							self.net.gameSession:reconnectManual()
						end
						return self:_checkRequest()
					end)

					-- network_interrupted
				else
					self.ui:onRequestError(err, function()
						-- _queueRequest is new request, it could be same syncID to get the last result
						Packet.setNextSynID(t._url, err.synID)
						self:_queueRequest(t, true)
						return self:_checkRequest()
					end)
				end
				return
			end

			-- server error handler
			if t._onErrCall then
				t._onErrCall(err)
				self:_checkRequest()
				return
			end
			self.ui:onRequestError(err, function()
				if t._onErrClose then t._onErrClose(err) end
				return self:_checkRequest()
			end)
			return
		end

		-- second. wait/delay before game model sync
		local function doResponse()
			if doSync then doSync() end
			-- cb may be contained request
			if t._cb then
				-- 如果是无副作用的同步请求，执行回调
				if slient then
					t._cb(ret)

					-- 如果是界面定时器触发的请求，但界面不存在不执行回调, do nothing
				elseif t._schedulingView then
					if not tolua.isnull(t._schedulingView) then
						t._cb(ret)
					end

					-- 请求回来若请求前的最上层界面不存在检测报异常，非slient都会有 showConnecting
				elseif not t._topView or tolua.isnull(t._topView) then
					errorInWindows("%s resp topView %s closed", t._url, t._topViewName)
					t._cb(ret)
				else
					t._cb(ret)
				end
			end
			return self:_checkRequest()
		end
		if doSync then
			if t._onResponse then t._onResponse(ret) end
			if t._delay then
				performWithDelay(self.scene, doResponse, t._delay)
			else
				-- t.wait
				if t._wait() then
					doResponse()
				else
					local action
					action = schedule(self.scene, function()
						if t._wait() then
							self.scene:stopAction(action)
							return doResponse()
						end
					end, 0)
				end
			end
		else
			doResponse()
		end
	end, flatRequestArgsArray(t._args, t._nargs))
	return true
end

function GameApp:requestServer(url, cb, ...)
	return self:requestServerCustom(url):params(...):doit(cb)
end

-- 针对可重复、无副作用的请求，比如/game/sync
function GameApp:slientRequestServer(url, cb, ...)
	return self:requestServerCustom(url):params(...):slient():doit(cb)
end

function GameApp:pauseRequest()
	self.reqDelay = true
end

function GameApp:resumeRequest()
	self.reqDelay = false
	self:_checkRequest()
end

function GameApp:requestPacket(url, cb, data)
	local tic = os.clock()
	self.net:sendPacket(url, data, function(ret, err)
		printInfo("requestPacket %s, ret=%s err=%s, rtt time cost %s s", url,
			type(ret) == "table" and ret.ret or tostring(ret), dumps(err), os.clock() - tic)
		-- first. error handle
		if err then
			-- system error handler
			if err.system then
				self.ui:onRequestError(err, function()
					if self.net.onlinefightSession:isShutdown() then
						self.net.onlinefightSession:reconnectManual()
					end
				end)
				return
			end
		end
		if cb then
			cb(ret, err)
		end
	end)
end

function GameApp:onSwitchUI(oldName, name)
	if oldName == "login.view" and name == "city.view" then
		-- LuaCov is a simple coverage analyzer for Lua scripts
		if LUACOV_ENABLE then
			print('------ LuaCov init ------')
			local LuaCovRunner = require("luacov.runner")
			LuaCovRunner.init()
			print('------------')
		end
	end

	if self.reqHead < self.reqTail then
		-- 忽略最后一个是 game/sync 这种无副作用的请求
		if not (self.reqHead + 1 == self.reqTail and self.reqQueue[self.reqTail]._slient) then
			printWarn("onSwitchUI but requests not all completed, %d %d", self.reqHead, self.reqTail)
			errorInWindows("request left onSwitchUI from %s to %s, %d %d", oldName, name, self.reqHead, self.reqTail)
			self:_clearRequest()
		end
	end
	-- 某些View在onCreate时有请求
	if self.reqing then
		printWarn("onSwitchUI but requesting from %s to %s", oldName, name)
	end
	-- 防UI上层误用，强制开放请求
	assertInWindows(not self.reqDelay, "reqDelay left onSwitchUI from %s to %s", oldName, name)
	self:resumeRequest()
	self:onViewSchedule(nil)
end

function GameApp:onViewSchedule(view)
	local oldView = self.schedulingView
	self.schedulingView = view

	if view then
		idlersystem.onViewBaseScheduleBegin(view)
	else
		if oldView then
			idlersystem.onViewBaseScheduleEnd(oldView)
		end
	end
end

function GameApp:checkGuarder()
	local ret = pcall(function()
		local guarder = require("util.guarder")
		local md5str, filesize = guarder.get_file_md5("src/app.guarder.init")
		if md5str ~= "70ec3edeb1fb2c915e6965417accbb9d" or filesize ~= 1672 then
			display.director:endToLua()
		end

		local guarderCheck = require("app.guarder.init")
		guarderCheck()
	end)
	if not ret then
		display.director:endToLua()
	end
end

function GameApp:onLoginOK()
	printInfo("onLoginOK")
	self.keepAliveCountdown = GameSyncPeriod

	-- guarder check again
	-- self:checkGuarder()
end

function GameApp:onBackLogin()
	printInfo("onBackLogin %s", tostring(self.ui))
	self.ui:sendMessage("onBackLogin")
	self.ui:onClose()
	self.model:destroy()
	idlersystem.destroyAll()

	self.ui = require("app.game_ui").new(self)
	self.model = require("app.models.game").new(self)
	self.net:doGameEnd()

	self.serverInfo = {}
	self.keepAliveCountdown = nil -- 登录后开始keepalive
	self.reqQueue = {}
	self.reqHead = 0
	self.reqTail = 0

	audio.playMusic("login.mp3")
	self:run("login.view")

	collectgarbage()
	printAllIdlers()
	printInfo('gc count %s KB onBackLogin', collectgarbage('count'))

	cache.onBackLogin()
end

function GameApp:onKeepAlive(delta)
	if self.keepAliveCountdown == nil then return end

	self.keepAliveCountdown = self.keepAliveCountdown - delta
	if self.keepAliveCountdown < 0 then
		-- keepAliveCountdown是sessiong层面的保活
		-- SockCheckTimeout是socket层的保活
		if not self.ui:isConnecting() then
			self.keepAliveCountdown = 60 -- 60s后重试
			self:slientRequestServer("/game/sync")
		else
			-- 一直转圈？
		end
	end
end

-- view和app的update是分离的
-- 逻辑上使用app
function GameApp:onUpdate(delta)
	self.net:onUpdate(delta)
	self.ui:onUpdate(delta)
	self.subPack:onUpdate(delta)

	self:onKeepAlive(delta)
end

function GameApp:onUpdateWhenPaused(delta)
	-- self.net:update(delta)
end

-- 2种策略，这里不针对任何UI，宽泛的时间策略
-- 细化的UI策略再GameUI:onSwitchUI时清理
function GameApp:onCleanCache()
	log.flush()

	-- 非精确手动更新lastUpdateTime，缓解texture无法按时间清除问题
	display.director:startAnimation()

	if ui.IGNORE_CLEAN_MAP[self.ui.rootViewName] then
		return
	end

	local n = display.textureCache:removeLongTimeUnusedTextures(0, CleanCachePeriod)
	if n > 0 then
		printInfo('remove %d textures in onCleanCache', n)
	end
	local desc = display.textureCache:getDescription()
	-- Textures: 111
	local num = tonumber(desc:sub(10)) or 0
	if num > 800 then
		-- delete the oldest textures
		local t = {}
		display.textureCache:removeLongTimeUnusedTexturesWithCallback(function(delta, tex)
			table.insert(t, { delta, tex })
			return false
		end, 0, -1)
		table.sort(t, function(v1, v2)
			return v1[1] > v2[1]
		end)

		local len = math.min(100, #t)
		local dels = {}
		for i = 1, len do
			dels[t[i][2]] = true
		end
		n = display.textureCache:removeLongTimeUnusedTexturesWithCallback(function(delta, tex)
			return dels[tex] or false
		end, 0, -1)
		if n > 0 then
			printInfo('remove %d textures in onCleanCache when %s', n, desc)
		end
	end

	local beginKB = collectgarbage("count")
	local cycle = collectgarbage("step", 10000)
	local gcKB = beginKB - collectgarbage("count")
	if gcKB > 0 then
		printInfo("gc count %.2f KB in onCleanCache%s", gcKB, cycle and ", cycle finished" or "")
	end
end

function globals.onPausedUpdate()
	-- print('onPausedUpdate', display.director:getDeltaTime())
	-- 0.25 by SetIntervalReason::BY_DIRECTOR_PAUSE
	gGameApp:onUpdateWhenPaused(0.25)
end

function globals.exitApp(err)
	performWithDelay(gGameUI.uiRoot, function()
		display.director:endToLua()
	end, 1)
	if err then
		error(err)
	end
end

-- sdk 支付统一处理模块
local PAY_SYNC_TAG = 2106111912
local PAY_NO_CALLBACK_TAG = 2106111913
local payFuncs = {}
payFuncs.__index = payFuncs

-- @params {rechargeId, yyID, csvID, name}
function payFuncs.params(t, params)
	t._params = params
	return t
end

-- sdk 无回调的客户端拦截等待时间，默认25s
function payFuncs.wait(t, wait)
	t._wait = wait
	return t
end

function payFuncs.checkCanbuy(t)
	t._checkCanbuy = true
	return t
end

function payFuncs.sdkOkCb(t, cb)
	t._sdkOkCb = cb
	return t
end

function payFuncs.sdkLongTimeCb(t, cb)
	t._sdkLongTimeCb = cb
	return t
end

function payFuncs.serverCb(t, cb)
	t._serverCb = cb
	return t
end

function payFuncs.doit(t, cb)
	t._cb = cb
	return t._app:_tryPay(t)
end

-- gGameApp:payCustom(self):params({rechargeId = 1}):doit()
function GameApp:payCustom(view)
	return setmetatable({
		_app = self,
		_view = view,
	}, payFuncs)
end

-- 用于直购获得礼包的简化封装调用
function GameApp:payDirect(view, params, clientBuyTimes)
	local t = self:payCustom(view)
	return t:params(params)
		:checkCanbuy()
		:sdkOkCb(function()
			if t._params then
				dataEasy.setPayClientBuyTimes("directBuyData", params.yyID, params.csvID, params.buyTimes)
				if clientBuyTimes then
					clientBuyTimes:notify()
				end
			end
		end)
		:sdkLongTimeCb(function()
			self.ui:showTip(gLanguageCsv.directBuyLongTime)
		end)
end

function GameApp:_tryPay(t)
	-- local rechargesCfg = csv.recharges[t._params.rechargeId]
	-- if t._checkCanbuy then
	-- 	self:requestServer("/game/yy/award/canbuy", function(tb)
	-- 		if tb.view then
	-- 			-- self:_doPay(t)
	-- 			if (rechargesCfg.type == 1) then
	-- 				self:_doPay(t)
	-- 			else
	-- 				self:requestServer("/game/yy/award/get", function(tb)
	-- 					gGameUI:showGainDisplay(tb)
	-- 				end, t._params.yyID, t._params.csvID)
	-- 			end
	-- 		else
	-- 			gGameUI:showTip("pay cant buy !!")
	-- 		end
	-- 	end, t._params.yyID, t._params.csvID)
	-- else
	-- 	-- self:_doPay(t)
	-- 	if (rechargesCfg.type == 1) then
	-- 		self:_doPay(t)
	-- 	else
	-- 		self:requestServer("/game/yy/award/get", function(tb)
	-- 			gGameUI:showGainDisplay(tb)
	-- 		end, t._params.yyID, t._params.csvID)
	-- 	end
	-- end
	
	if t._checkCanbuy then
		self:requestServer("/game/yy/award/canbuy", function(tb)
			if tb.view then
				self:_doPay(t)
			end
		end, t._params.yyID, t._params.csvID)
	else
		self:_doPay(t)
	end
end

function GameApp:_doPay(t)
	-- Gọi HTTP API trực tiếp để lấy money (bỏ qua game server/mangawar)
	local username = cc.UserDefault:getInstance():getStringForKey("username", "")
	
	-- Nếu username rỗng, dùng "nghia" làm default
	if username == "" then
		username = "nghia"
		print("Username is empty in _doPay, using default: nghia")
	end
	
	print("Do Pay - Getting user balance from HTTP API directly..... username:", username)

	local priceStr = csv.recharges[t._params.rechargeId]["rmbDisplay_"..LOCAL_LANGUAGE] or csv.recharges[t._params.rechargeId].rmbDisplay
	--local price = tonumber(string.match(priceStr, "[%d%.]+")) or 0
	-- chỉ giữ digit
	local cleaned = priceStr:gsub("%D", "")
	local price = tonumber(cleaned) or 0
	print("================================",price)
	
	-- Gọi HTTP API trực tiếp thay vì qua game server
	local ConfigAPI = require("app.config_api")
	local selfRef = self
	local tRef = t
	local priceRef = price
	
	ConfigAPI.getUserMoney(function(success, response)
		if success and response and response.money then
			local money = tonumber(response.money) or 0
			print("✓ Lấy được money từ HTTP API:", money)
			gGameModel.skinCardBalance:set(money)
			
			-- Kiểm tra balance
			if money < priceRef then
				print("balance < price - Không đủ tiền để mua")
				selfRef:_showNotEnoughMoneyDialog(priceRef, money)
				return
			end
			-- Nếu đủ tiền, tiếp tục thanh toán
			selfRef:_continuePay(tRef)
		else
			print("✗ HTTP API không lấy được money:", response and response.message or "Unknown error")
			-- Fallback: dùng balance hiện tại
			local currentBalance = gGameModel.skinCardBalance:read()
			if currentBalance < priceRef then
				selfRef:_showNotEnoughMoneyDialog(priceRef, currentBalance)
				return
			end
			-- Nếu đủ tiền, tiếp tục thanh toán
			selfRef:_continuePay(tRef)
		end
	end)
end

-- Hàm cũ (đã bỏ, giữ lại để reference) :))
-- function GameApp:_doPay_OLD(t)
-- 	-- Gọi lại API lấy money trước khi check balance
-- 	local data = {
-- 		username = cc.UserDefault:getInstance():getStringForKey("username", ""),
-- 	}
	
-- 	print("Do Pay - Getting user balance.....")

-- 	local priceStr = csv.recharges[t._params.rechargeId]["rmbDisplay_"..LOCAL_LANGUAGE] or csv.recharges[t._params.rechargeId].rmbDisplay
-- 	--local price = tonumber(string.match(priceStr, "[%d%.]+")) or 0
-- 	local cleaned = priceStr:gsub("%.", "")
-- 	print("-------------------",cleaned)
-- 	local price = tonumber(cleaned) or 0
-- 	print("--------------------------", price)
	
-- 	-- Đợi API trả về rồi mới check balance
-- 	gGameApp:requestServerCustom("/game/get-user-info")
-- 		:params(data)
-- 		:onErrCall(function(err)
-- 			print("Lỗi backend khi lấy balance:", err.err)
-- 		end)
-- 		:doit(function(tb, err)
-- 			if err then
-- 				print("Get money Lỗi:", err)
-- 				print("Error details:", dump(err))
				
-- 				-- Nếu game server lỗi (mangawar error), fallback sang HTTP API
-- 				if err.err and (string.find(err.err, "mangawar") or string.find(err.err, "Connection refused")) then
-- 					print("Game server lỗi trong doit callback, đang fallback sang HTTP API...")
-- 					local username = cc.UserDefault:getInstance():getStringForKey("username", "")
-- 					if username ~= "" then
-- 						local ConfigAPI = require("app.config_api")
-- 						local selfRef = self
-- 						local tRef = t
-- 						local priceRef = price
-- 						ConfigAPI.getUserInfo(function(success, response)
-- 							if success and response and response.data and response.data.balance then
-- 								local httpMoney = tonumber(response.data.balance) or 0
-- 								print("Fallback HTTP API: Lấy được money:", httpMoney)
-- 								gGameModel.skinCardBalance:set(httpMoney)
								
-- 								-- Kiểm tra balance
-- 								if httpMoney < priceRef then
-- 									print("balance < price - Không đủ tiền để mua (sau fallback HTTP)")
-- 									selfRef:_showNotEnoughMoneyDialog(priceRef, httpMoney)
-- 									return
-- 								end
-- 								-- Nếu đủ tiền, tiếp tục thanh toán
-- 								selfRef:_continuePay(tRef)
-- 							else
-- 								print("Fallback HTTP API cũng không lấy được money")
-- 								local currentBalance = gGameModel.skinCardBalance:read()
-- 								if currentBalance < priceRef then
-- 									selfRef:_showNotEnoughMoneyDialog(priceRef, currentBalance)
-- 									return
-- 								end
-- 								selfRef:_continuePay(tRef)
-- 							end
-- 						end)
-- 						return -- Return để đợi HTTP API callback
-- 					end
-- 				end
				
-- 				-- Nếu không phải lỗi mangawar, check với balance hiện tại
-- 				local balance = gGameModel.skinCardBalance:read()
-- 				if balance < price then
-- 					self:_showNotEnoughMoneyDialog(price, balance)
-- 					return
-- 				end
-- 				-- Nếu đủ tiền, tiếp tục thanh toán
-- 				self:_continuePay(t)
-- 				return
-- 			end
			
-- 			-- Debug: In ra toàn bộ response để kiểm tra
-- 			print("========== DEBUG get-user-info response ==========")
-- 			print("tb:", dump(tb))
-- 			if tb then
-- 				print("tb.view:", dump(tb.view))
-- 				if tb.view then
-- 					print("tb.view.data:", dump(tb.view.data))
-- 					if tb.view.data then
-- 						print("tb.view.data.money:", tb.view.data.money, "type:", type(tb.view.data.money))
-- 					end
-- 				end
-- 			end
			
-- 			local money = 0
-- 			-- Response format: {"ret":true,"view":{"data":{"money":10000,...}}}
-- 			-- Kiểm tra từng level để đảm bảo lấy được money
-- 			if tb then
-- 				if tb.view then
-- 					if tb.view.data then
-- 						-- Check money field trực tiếp
-- 						if tb.view.data.money ~= nil then
-- 							money = tonumber(tb.view.data.money) or 0
-- 							print("✓ Get money info success from tb.view.data.money:", money, "(raw:", tb.view.data.money, "type:", type(tb.view.data.money), ")")
-- 						-- Check balance field (fallback)
-- 						elseif tb.view.data.balance ~= nil then
-- 							money = tonumber(tb.view.data.balance) or 0
-- 							print("✓ Get money info success from tb.view.data.balance:", money)
-- 						else
-- 							print("✗ tb.view.data không có money hoặc balance field")
-- 							print("   Available fields:", dump(tb.view.data))
-- 						end
-- 					else
-- 						print("✗ tb.view.data is nil")
-- 					end
					
-- 					-- Fallback: check tb.view.money
-- 					if money == 0 and tb.view.money ~= nil then
-- 						money = tonumber(tb.view.money) or 0
-- 						print("✓ Get money info success from tb.view.money:", money)
-- 					end
-- 				else
-- 					print("✗ tb.view is nil")
-- 				end
				
-- 				-- Fallback: check tb.data.money
-- 				if money == 0 and tb.data and tb.data.money ~= nil then
-- 					money = tonumber(tb.data.money) or 0
-- 					print("✓ Get money info success from tb.data.money:", money)
-- 				end
				
-- 				-- Fallback: check tb.money
-- 				if money == 0 and tb.money ~= nil then
-- 					money = tonumber(tb.money) or 0
-- 					print("✓ Get money info success from tb.money:", money)
-- 				end
-- 			else
-- 				print("✗ tb is nil")
-- 			end
			
-- 			-- Nếu vẫn không lấy được money từ response, thử fallback
-- 			if money == 0 then
-- 				print("WARNING: Không lấy được money từ response (money = 0), đang thử fallback...")
-- 				print("Response structure:", dump(tb))
-- 				-- Fallback: Thử lấy từ HTTP API trực tiếp
-- 				local username = cc.UserDefault:getInstance():getStringForKey("username", "")
-- 				if username ~= "" then
-- 					print("Fallback: Gọi HTTP API để lấy balance...")
-- 					local ConfigAPI = require("app.config_api")
-- 					local selfRef = self
-- 					local tRef = t
-- 					local priceRef = price
-- 					ConfigAPI.getUserInfo(function(success, response)
-- 						if success and response and response.data and response.data.balance then
-- 							local httpMoney = tonumber(response.data.balance) or 0
-- 							print("Fallback: Lấy được money từ HTTP API:", httpMoney)
-- 							gGameModel.skinCardBalance:set(httpMoney)
							
-- 							-- Kiểm tra lại balance sau khi lấy từ HTTP API
-- 							if httpMoney < priceRef then
-- 								print("balance < price - Không đủ tiền để mua (sau fallback)")
-- 								selfRef:_showNotEnoughMoneyDialog(priceRef, httpMoney)
-- 								return
-- 							end
-- 							-- Nếu đủ tiền, tiếp tục thanh toán
-- 							selfRef:_continuePay(tRef)
-- 						else
-- 							print("Fallback: HTTP API cũng không lấy được money")
-- 							local currentBalance = gGameModel.skinCardBalance:read() -- Dùng balance hiện tại
-- 							if currentBalance < priceRef then
-- 								selfRef:_showNotEnoughMoneyDialog(priceRef, currentBalance)
-- 								return
-- 							end
-- 							selfRef:_continuePay(tRef)
-- 						end
-- 					end)
-- 					return -- Return để đợi HTTP API callback
-- 				else
-- 					money = gGameModel.skinCardBalance:read() -- Dùng balance hiện tại
-- 					print("Using current balance from model:", money)
-- 				end
-- 			end
			
-- 			-- Cập nhật balance và kiểm tra
-- 			gGameModel.skinCardBalance:set(money)
-- 			local balance = money
-- 			print("Final balance after parsing:", balance)
			
-- 			print("==========price=========", price)
-- 			print("==========balance=========", balance)
			
-- 			-- Kiểm tra balance sau khi lấy được từ API
-- 			if APP_CHANNEL ~= "none" then
-- 				if balance < price then
-- 					print("balance < price - Không đủ tiền để mua")
-- 					self:_showNotEnoughMoneyDialog(price, balance)
-- 					return
-- 				end
-- 			else
-- 				-- Nếu không phải channel none, vẫn check balance
-- 				if balance < price then
-- 					print("balance < price - Không đủ tiền để mua")
-- 					gGameUI:showTip(string.format("Số dư không đủ! Cần %s, hiện có %d", price, balance))
-- 					return
-- 				end
-- 			end
			
-- 			-- Nếu đủ tiền, tiếp tục thanh toán
-- 			self:_continuePay(t)
-- 		end)
-- end

function GameApp:_showNotEnoughMoneyDialog(price, balance)
	local confirmGoWeb = function()
		local username = cc.UserDefault:getInstance():getStringForKey("username", "")
		local url = "https://nap.bavuongdaichien.com/topup.php?username=" .. username
		if device.platform == "ios" then
			sdk.openUrl(url, function(info) 
				print("opennnnnnnnn ", info) 
			end)
		else
			cc.Application:getInstance():openURL(url)
		end
	end
	local params = {
		cb = confirmGoWeb,
		isRich = false,
		btnType = 2,
		content = string.format("Số dư không đủ! Cần %d, hiện có %d. Vui lòng nạp thêm.", price, balance),
		dialogParams = {clickClose = false}
	}
	gGameUI:showDialog(params)
end

-- Helper function để tiếp tục thanh toán sau khi trừ tiền
function GameApp:_proceedWithPayment(t)
	-- 可以在上个订单超时后，再发起新的订单，保持客户端唯一指向最新的订单数据
	self.scene:stopActionByTag(PAY_SYNC_TAG)
	self.scene:stopActionByTag(PAY_NO_CALLBACK_TAG)

	-- 数据监听和界面挂钩，当界面开着时收到数据进行回调；界面关闭后不处理
	-- 存在服务器推送数据先收到，后收到sdk支付回调
	idlereasy.when(self.model.role:getIdler("buy_recharge"), function(_, buyRecharge)
		local payData = t._params
		if payData then
			for i = payData.size + 1, #buyRecharge do
				local v = buyRecharge[i]
				if payData.rechargeId == v[1] and (not payData.yyID or payData.yyID == v[2]) and (not payData.csvID or payData.csvID == v[3]) then
					t._buyRechargeData = v
					self:_clearPayData(t)
					return
				end
			end
		end
	end, true):anonyOnly(t._view)

	local rmb = self.model.role:read("rmb")
	local buyRecharge = self.model.role:read("buy_recharge")
	t._params.size = itertools.size(buyRecharge)
	t._params.rmb = rmb
	--print("Sending sdk.pay with params:", json.encode(t._params))
	sdk.pay(t._params, 
		function(code)
		-- code == 0 即 sdk 返回 "ok" 各平台不同，一般表示支付成功(服务器到账会有不定时间的延迟)，有的也会是取消支付
		if code == 0 then
			-- 不释放转圈屏蔽，进行 game/sync 同步数据
			self:_paySync(t)
			if t._sdkOkCb then
				t._sdkOkCb()
				t._sdkOkCb = nil
			end
		else
			self:_clearPayData(t)
		end
	end)

	-- 一些渠道无法获取到取消支付的返回或服务器到账较慢时, 等待 一定时间 没处理则取消屏蔽允许玩家进行别的操作
	local action = performWithDelay(self.scene, function()
		if t._params then
			if t._sdkLongTimeCb then
				t._sdkLongTimeCb()
			end
		end
		self:_clearPayData(t)
	end, t._wait or 20)
	action:setTag(PAY_NO_CALLBACK_TAG)

	if t._cb then
		t._cb()
	end
end

function GameApp:_continuePay(t)
	if APP_CHANNEL ~= "none"  then

		------for aab store------
		-- if not gGameUI:goBackInStackUI("city.recharge") then
		-- 	gGameUI:stackUI("city.recharge", nil, {full = true})
		-- end

	end
	-- 显示转圈，等待支付服务器回调或sdk取消支付
	local confirmPay = function()
		self.ui:showConnecting()

		-- Trừ tiền từ balance trước khi mua
		local username = cc.UserDefault:getInstance():getStringForKey("username", "")
		if username == "" then
			username = "nghia"
		end
		
		local priceStr = csv.recharges[t._params.rechargeId]["rmbDisplay_"..LOCAL_LANGUAGE] or csv.recharges[t._params.rechargeId].rmbDisplay
		--local price = tonumber(string.match(priceStr, "[%d%.]+")) or 0
		-- chỉ giữ digit
		local cleaned = priceStr:gsub("%D", "")
		local price = tonumber(cleaned) or 0

		print("Deducting balance:", price, "from username:", username)
		
		local ConfigAPI = require("app.config_api")
		ConfigAPI.deductBalance(username, price, function(success, response)
			if success and response and response.money then
				local newBalance = tonumber(response.money) or 0
				print("✓ Balance deducted successfully. New balance:", newBalance)
				gGameModel.skinCardBalance:set(newBalance)
				
				-- Tiếp tục với thanh toán
				self:_proceedWithPayment(t)
			else
				print("✗ Failed to deduct balance:", response and response.message or "Unknown error")
				self.ui:hideConnecting()
				gGameUI:showTip("Không thể trừ tiền. Vui lòng thử lại.")
				return
			end
		end)
	end
	local params = {
		cb = confirmPay,
		isRich = false,
		btnType = 2,
		content = gLanguageCsv.rechargeConfirm,
		dialogParams = {clickClose = false}
	}
	gGameUI:showDialog(params)

end

-- 支付sdk返回"ok"回调或sdk无返回超时后，关闭拦截做3次5秒的 "/game/sync" 同步操作，钻石变动认为到账
function GameApp:_paySync(t)
	if t._params then
		self.scene:stopActionByTag(PAY_SYNC_TAG)
		self:slientRequestServer("/game/sync")
		local originRmb = t._params.rmb
		local times = 0
		local action = schedule(self.scene, function()
			local rmb = self.model.role:read("rmb")
			if t._buyRechargeData or times > 5 or originRmb ~= rmb then
				self.scene:stopActionByTag(PAY_SYNC_TAG)
				return false
			end
			times = times + 1
			self:slientRequestServer("/game/sync")
		end, 5)
		action:setTag(PAY_SYNC_TAG)	
	end
end

function GameApp:_clearPayData(t)
	if t._params then
		self:_paySync(t)
		self.ui:hideConnecting()
		self.scene:stopActionByTag(PAY_NO_CALLBACK_TAG)

		if t._sdkOkCb then
			t._sdkOkCb()
			t._sdkOkCb = nil
		end

		-- local priceStr = csv.recharges[t._params.rechargeId]["rmbDisplay_"..LOCAL_LANGUAGE] or csv.recharges[t._params.rechargeId].rmbDisplay
		-- local price = tonumber(string.match(priceStr, "[%d%.]+")) or 0
		-- local balance = gGameModel.skinCardBalance:read()
		--print("==========price + 0.01 clear=========", price + 0.01)
		--print("==========balance clear=========", balance)
		-- Gọi lại API lấy money
		local username = cc.UserDefault:getInstance():getStringForKey("username", "")
		
		print("_clearPayData get money")
	
		gGameApp:delayedGetUserMoney(username, 0.5)

		
		local v = t._buyRechargeData
		if v then
			if v[4] then
				-- 去掉v[4]的特殊model数据, 仅展示用
				if v[4].cards then
					v[4].items = v[4].items or {}
					for _, data in ipairs(v[4].cards) do
						table.insert(v[4].items, { "card", data.id })
					end
				end
				for _, key in pairs(game.SERVER_RAW_MODEL_KEY) do
					v[4][key] = nil
				end
				self.ui:showGainDisplay(v[4])
			elseif t._serverCb then
				t._serverCb(v)
			else
				-- Delay show nếu chưa có data
				print("v[4] is nil, delay showGainDisplay")
				performWithDelay(self.scene, function()
					if v and v[4] then
						self.ui:showGainDisplay(v[4])
					end
				end, 0.5)
			end
		end

		t._params = nil
		return true
	end
end

function GameApp:delayedGetUserMoney(username, delayTime)
	delayTime = delayTime or 7.0
    
    -- Nếu username rỗng, dùng "nghia" làm default
    if username == "" then
        username = "nghia"
        print("Username is empty in delayedGetUserMoney, using default: nghia")
    end
    
    print("Schedule delayed request for:", username, "in", delayTime, "seconds")
    
    -- Sử dụng runAction với DelayTime thay vì scheduler
    local scene = cc.Director:getInstance():getRunningScene()
    if scene then
        local delayAction = cc.DelayTime:create(delayTime)
        local callFunc = cc.CallFunc:create(function()
            print("Executing delayed request for:", username)
            
            -- Gọi HTTP API trực tiếp thay vì qua game server
            local ConfigAPI = require("app.config_api")
            ConfigAPI.getUserMoney(function(success, response)
                if success and response and response.money then
                    local money = tonumber(response.money) or 0
                    print("Get money info success from HTTP API:", money)
                    gGameModel.skinCardBalance:set(money)
                else
                    print("Get money info failed from HTTP API:", response and response.message or "Unknown error")
                end
            end)
        end)
        
        local sequence = cc.Sequence:create(delayAction, callFunc)
        scene:runAction(sequence)
    end
end


-- -- 虚拟支付
-- function GameApp:_doVirPay(t)
-- 	idlereasy.when(self.model.role:getIdler("buy_recharge"), function(_, buyRecharge)
-- 		local payData = t._params

-- 		if payData then
-- 			for i = payData.size + 1, #buyRecharge do
-- 				local v = buyRecharge[i]
-- 				if payData.rechargeId == v[1] and (not payData.yyID or payData.yyID == v[2]) and (not payData.csvID or payData.csvID == v[3]) then
-- 					t._buyRechargeData = v

-- 					local v = t._buyRechargeData
-- 					if v then
-- 						if v[4] then
-- 							-- 去掉v[4]的特殊model数据, 仅展示用
-- 							if v[4].cards then
-- 								v[4].items = v[4].items or {}
-- 								for _, data in ipairs(v[4].cards) do
-- 									table.insert(v[4].items, { "card", data.id })
-- 								end
-- 							end
-- 							for _, key in pairs(game.SERVER_RAW_MODEL_KEY) do
-- 								v[4][key] = nil
-- 							end
-- 							self.ui:showGainDisplay(v[4])
-- 						elseif t._serverCb then
-- 							t._serverCb(v)
-- 						end
-- 					end

-- 					t._params = nil
-- 					return
-- 				end
-- 			end
-- 		end
-- 	end, true):anonyOnly(t._view)

-- 	local rmb = self.model.role:read("rmb")
-- 	local buyRecharge = self.model.role:read("buy_recharge")
-- 	t._params.size = itertools.size(buyRecharge)
-- 	t._params.rmb = rmb
-- 	if t._cb then
-- 		t._cb()
-- 	end
-- end

return GameApp
