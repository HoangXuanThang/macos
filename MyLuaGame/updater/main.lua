--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2016 TianJi Information Technology Inc.
--
-- updater入口
--

print("Updater UI working...")

require "exception_handler"
function __G__TRACKBACK__(msg)
	print("----------------------------------------")
	print("LUA ERROR: " .. tostring(msg) .. "\n")
	print(debug.traceback())
	print("----------------------------------------")
	handleLuaException(msg)
end

function __G__GCCOUNT__()
	return collectgarbage("count")
end

sdk = {}

require "3rd.stringzutils"
require "defines"
require "cocos_init"
require "net"
require "l10n"
require "json"
require "ui_defines"

-- util
require "util.maptools"
require "util.nodetools"
require "util.language"
require "util.config"
require "util.csv"

--easy
require "easy.text"
require "easy.label"
require "easy.richtext"
require "easy.beauty"
require "easy.ui_adapter"
require "easy.user_default"

-- config_defines
--require "config.csv"
local function _setDefalutMeta(t)
	local strsub = string.sub
	for k, v in pairs(t) do
		if type(k) == 'string' and type(v) == 'table' then
			if strsub(k, 1, 2) ~= '__' then
				-- print (k,v)
				_setDefalutMeta(v)
			end
		elseif t.__default and type(k) == 'number' and type(v) == 'table' then
			setmetatable(v, t.__default)
		end
	end
end
local csv = {}
globals.csv = csv
require "huodong_display_replace"
require "loading_tips"
_setDefalutMeta(csv)

require "sdk.init"

-- 默认是简体中文
if LOCAL_LANGUAGE ~= 'cn' then
	setL10nConfig(csv)
end


local EventCodeMap = {}
for k, v in pairs(cc.EventAssetsManagerEx.EventCode) do
	EventCodeMap[v] = k
end

local showPromptBox = require("views.prompt_box")
local showLoginPlacard = require("views.placard")

local _zlib = require("3rd.zlib2")
local zuncompress = _zlib.uncompress

local scene = nil
local curTime = 0
local delayTime = 1 -- test
local notice = nil
local loadingWidget = nil
local lastTotalFiles, lastTotalBytes
local errHappened = false

local isBeginLoading = false
local isProgress30 = false
local isProgress60 = false

local versionPlist = cc.FileUtils:getInstance():getValueMapFromFile('res/version.plist')
--local versionPlist = cc.FileUtils:getInstance():getValueMapFromFile('config.plist')
--local NOTICE_CONF_URL = versionPlist.noticeUrl

local channelPlist = cc.FileUtils:getInstance():getValueMapFromFile('res/channel.plist')
--local channelPlist = cc.FileUtils:getInstance():getValueMapFromFile('config.plist')
local APP_CHANNEL = channelPlist.channel
local APP_BUCKET = channelPlist.bucket or "dld"
print('APP_CHANNEL', APP_CHANNEL)

-- 小y专服，更新包是cn的，地址代码定义
--if APP_CHANNEL == "xy51" then
--	NOTICE_CONF_URL = "http://124.71.138.126:18080/notice"
--	Language.wifiTip = "本次有最新资源需要更新，确定进行更新?"
--end

local LoadingBgTotal = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11}

-----------------------------
local function createBoardForLayer(layer)
	-- 上下黑边
	if CC_DESIGN_RESOLUTION.autoscale == "SHOW_ALL" then
		local outSceneNode = cc.Node:create()
		display.director:setNotificationNode(outSceneNode)

		local scaleX, scaleY = display.sizeInPixels.width / display.sizeInView.width,
			display.sizeInPixels.height / display.sizeInView.height
		local scale = math.min(scaleX, scaleY)
		local heightInPixels = (display.sizeInPixels.height - scale * display.sizeInView.height) / 2
		-- local backBoard1 = cc.LayerColor:create(cc.c4b(0, 0, 0, 255), display.sizeInView.width, heightInPixels / scaleY)
		-- local backBoard2 = cc.LayerColor:create(cc.c4b(0, 0, 0, 255), display.sizeInView.width, heightInPixels / scaleY)
		-- backBoard2:setPositionY((heightInPixels + scale * display.sizeInView.height) / scaleY)
		-- outSceneNode:addChild(backBoard1)
		-- outSceneNode:addChild(backBoard2)

		local top = cc.Sprite:create("img/scene_board_bottom.png")
		top:setFlippedY(true)
		top:setAnchorPoint(0, 0)
		top:setContentSize(2560, 315)
		top:setPosition(0, (heightInPixels + scale * display.sizeInView.height) / scaleY)
		outSceneNode:addChild(top)
		local bottom = cc.Sprite:create("img/scene_board_bottom.png")
		bottom:setAnchorPoint(0, 1)
		bottom:setContentSize(2560, 315)
		bottom:setPosition(0, heightInPixels / scaleY)
		outSceneNode:addChild(bottom)
	end
	-- 大于最大分辨率两边黑边
	if display.uiOrigin.x > display.uiOriginMax.x then
		local outSceneNode = cc.Node:create()
		display.director:setNotificationNode(outSceneNode)

		local widthInPixels = display.uiOrigin.x - display.uiOriginMax.x
		-- local backBoard1 = cc.LayerColor:create(cc.c4b(0, 0, 0, 255), widthInPixels, display.sizeInView.height)
		-- local backBoard2 = cc.LayerColor:create(cc.c4b(0, 0, 0, 255), widthInPixels, display.sizeInView.height)
		-- backBoard2:setPositionX(widthInPixels + display.maxWidth) -- board加在outSceneNode上，而非viewLayer
		-- outSceneNode:addChild(backBoard1)
		-- outSceneNode:addChild(backBoard2)

		local left = cc.Sprite:create("img/scene_board_right.png")
		left:setFlippedX(true)
		left:setAnchorPoint(1, 0)
		left:setContentSize(600, 1440)
		left:setPosition(widthInPixels, 0)
		outSceneNode:addChild(left)
		local right = cc.Sprite:create("img/scene_board_right.png")
		right:setAnchorPoint(0, 0)
		right:setContentSize(600, 1440)
		right:setPosition(widthInPixels + display.maxWidth, 0)
		outSceneNode:addChild(right)
	end

	return layer
end

local function printEvent(event)
	local code = event:getEventCode()
	print('onEvent ------------------')
	print('getAssetId', event:getAssetId())
	print('getCURLECode', event:getCURLECode())
	print('getCURLMCode', event:getCURLMCode())
	print('getMessage', event:getMessage())
	print('getEventCode', code, EventCodeMap[code] or "???")
	print('getPercent', event:getPercent(), event:getTotalBytes())
	print('getPercentByFile', event:getPercentByFile(), event:getTotalFiles())
end

local function showLoadingProgress(event, full)
	if not isBeginLoading then
		sdk.trackEvent(12)
		isBeginLoading = true
	end

	local loading = loadingWidget:getChildByName("bar")
	local loadingSpr = loadingWidget:getChildByName("loadingIcon")
	local loadingStatus = loadingWidget:getChildByName("loadingStatus")
	local updateDesc = loadingWidget:getChildByName("updateDesc")

	if full then
		loading:setPercent(100)
		local percentX = loading:getContentSize().width + loading:getPositionX() + 480
		loadingSpr:setPosition(percentX, 200)

		local file, size = lastTotalFiles or 0, lastTotalBytes or 0
		updateDesc:setString(string.format(Language.downloading, file, file, size / 1024, size / 1024))
		loadingStatus:setString("100.00%")
	else
		local percent = event:getPercent()
		loading:setVisible(true)
		loadingSpr:setVisible(true)
		loadingStatus:setVisible(true)

		-- if percent > 20 then
		-- 	error("err when percent 20")
		-- end

		loading:setPercent(percent)
		local percentX = percent / 100 * loading:getContentSize().width + 480
		loadingSpr:setPosition(percentX, 200)

		lastTotalFiles, lastTotalBytes = event:getTotalFiles(), event:getTotalBytes()
		local file, size = event:getPercentByFile() / 100 * event:getTotalFiles(), percent / 100 * event:getTotalBytes()
		if lastTotalBytes > 2048 then
			updateDesc:setString(string.format(Language.downloadingM, file, event:getTotalFiles(), size / 1024 / 1024,
				lastTotalBytes / 1024 / 1024))
		else
			updateDesc:setString(string.format(Language.downloading, file, event:getTotalFiles(), size / 1024,
				lastTotalBytes / 1024))
		end
		loadingStatus:setString(string.format("%.2f%%", percent))

		if not isProgress30 and percent > 30 then
			sdk.trackEvent(13)
			isProgress30 = true
		end
		if not isProgress60 and percent > 60 then
			sdk.trackEvent(14)
			isProgress60 = true
		end
	end
end

local function showLoadingOK()
	showLoadingProgress(nil, true)
	loadingWidget:getChildByName("updateDesc"):setString(Language.umcompress)

	print("success")
	loadingWidget:runAction(cc.Sequence:create(cc.DelayTime:create(delayTime), cc.CallFunc:create(function()
		local manager = cc.AssetsManagerEx:getInstance()
		manager:onLuaSuccess()
	end)))
end

local function addBackGround(panel)
	local backLayer = ccui.Layout:create()
	backLayer:setContentSize(display.sizeInView)
	backLayer:setBackGroundColorType(1)
	backLayer:setBackGroundColor(cc.c3b(91, 84, 91))
	backLayer:setOpacity(204)
	backLayer:setTouchEnabled(true)
	backLayer:setPosition(cc.p(display.board_left, 0))
	panel:addChild(backLayer, -1)
	return backLayer
end

local function showPlacard()
	sdk.trackEvent(17)
	local view = showLoginPlacard(notice)
	view.node:setTouchEnabled(false)
	addBackGround(view.node):onClick(function()
		sdk.trackEvent(18)
		view:onClose()
	end)
	scene:getChildByName("layer"):addChild(view.node, 999, "placard")
end

local function showDialog(params)
	local view = showPromptBox(params)
	addBackGround(view.node)
	scene:getChildByName("layer"):addChild(view.node, 999)
	return view
end

local function addSearchPath(path)
	if LOCAL_LANGUAGE ~= "cn" and device.platform == "windows" then
		local pathL10n = string.format("%s_%s", path, LOCAL_LANGUAGE)
		cc.FileUtils:getInstance():addSearchResolutionsOrder(pathL10n)
	end
	cc.FileUtils:getInstance():addSearchResolutionsOrder(path)
end
local function isDisplayReplaceHuodong(typeStr)
	local function getTimestamp(huodongDate, huodongTime)
		local t = {
			year = math.floor(huodongDate / 10000),
			month = math.floor((huodongDate % 10000) / 100),
			day = math.floor(huodongDate % 100),
			hour = math.floor(huodongTime / 100) or 0,
			min = huodongTime % 100 or 0,
			sec = 0
		}
		t.isdst = false
		local lt = os.time(t)
		local now = os.time()
		local ldelta = os.difftime(now, os.time(os.date("!*t", now)))
		return lt - UNIVERSAL_TIMEDELTA + ldelta
	end
	if not typeStr then return false end
	local nowTime = os.time()
	for _, cfg in csvPairs(csv.huodong_display_replace) do
		local beginTime = getTimestamp(cfg.beginDate, cfg.beginTime)
		local endTime = getTimestamp(cfg.endDate, cfg.endTime)
		if cfg.clientParam[typeStr] and nowTime > beginTime and nowTime < endTime then
			return true, cfg.clientParam[typeStr]
		end
	end
	return false
end
local function createLayer()
	local layer = cc.Layer:create()
	local loginWidget = ccs.GUIReader:getInstance():widgetFromJsonFile("login.json")
	if CC_DESIGN_RESOLUTION.autoscale == "FIXED_HEIGHT" then
		layer:setPosition(display.uiOrigin.x, 0)
	end
	local btnPanel = loginWidget:getChildByName("btnPanel")
	adapt.dockWithScreen(btnPanel, "right", "up")
	loginWidget:getChildByName("version"):setString("")
	loginWidget:getChildByName("server"):setVisible(false)
	loginWidget:getChildByName("btn_enter"):setVisible(false)
	-- weihao todo
	-- local loginSpine = "login/login.skel"
	-- local effect = sp.SkeletonAnimation:create(loginSpine, string.gsub(loginSpine, ".skel", ".atlas"))
	-- effect:setAnimation(0, "login_00", true)
	-- effect:setScale(2)

	-- effect:setPosition(cc.p(display.size.width / 2, display.size.height / 2))
	-- loginWidget:addChild(effect, 0)

	-- 适配， 弹出处理是否需要像其他二级弹框一样
	local placard = btnPanel:getChildByName("btn_gonggao"):setTouchEnabled(true)
	placard:onClick(function()
		if notice == nil then
			print("NOTICE_CONF_URL updater.main " .. NOTICE_CONF_URL)
			doGET(NOTICE_CONF_URL, function(data, err)
				if data then
					print('notice data', data)
					notice = json.decode(data).notice
					showPlacard()
				else
					print('notice err', err)
				end
			end)
		else
			showPlacard()
		end
	end)

	math.newrandomseed()
	loadingWidget = ccs.GUIReader:getInstance():widgetFromJsonFile("login_updater.json")
	loadingWidget:setPosition(cc.p(display.width / 2, display.height / 2))
	loadingWidget:getChildByName("updateDesc"):setString(Language.checkUpdate)
	loadingWidget:getChildByName("loadingDesc"):setVisible(true)
	local function randomText()
		local idx = math.random(1, csvSize(csv.loading_tips))
		loadingWidget:getChildByName("loadingDesc"):setString(csv.loading_tips[idx]["tip_"..LOCAL_LANGUAGE] or csv.loading_tips[idx].tip)
	end
	randomText()
	local loadingIcon = loadingWidget:getChildByName("loadingIcon")
	loadingWidget:runAction(cc.RepeatForever:create(cc.Sequence:create(cc.DelayTime:create(5),
		cc.CallFunc:create(randomText))))
	loadingWidget:getChildByName("bar"):setVisible(false)
	loadingWidget:getChildByName("loadingStatus"):setVisible(false)
	local z = loadingIcon:getLocalZOrder()
	loadingWidget:removeChildByName("loadingIcon")
	local runingEffect = sp.SkeletonAnimation:create("loading/loading_dog.skel", "loading/loading_dog.atlas")
	runingEffect:setAnimation(0, "effect_loop", true)
	runingEffect:setVisible(false)
	runingEffect:setName("loadingIcon")
	runingEffect:setAnchorPoint(cc.p(1, 0))
	runingEffect:setScale(1.6)
	loadingWidget:add(runingEffect, z)
	
	local bgIdx = math.random(1, #LoadingBgTotal)
	local bgDi = loadingWidget:getChildByName("bgDi")
	-- bgDi:loadTexture(string.format("loading/bg_%d.jpg", LoadingBgTotal[bgIdx]))
	bgDi:loadTexture("loading/bg_12.jpg")

	layer:add(loginWidget)
		:add(loadingWidget)
	layer:setName("layer")
	return layer
end

local function checkForShenhe(shenheCb, notShenheCb)

end

local function main()
	-- avoid memory leak
	collectgarbage("setpause", 100)
	collectgarbage("setstepmul", 5000)
	collectgarbage("stop")

	cc.Texture2D:setDefaultAlphaPixelFormat(cc.TEXTURE2_D_PIXEL_FORMAT_AUTO)

	scene = cc.Scene:create()

	if device.platform == "windows" then
		-- 开发优先索引路径设置，特殊加 dev_defines
		require "src.app.defines.dev_defines"
		if dev.DEBUG_MODE and dev.DEV_PATH then
			cc.FileUtils:getInstance():addSearchResolutionsOrder(dev.DEV_PATH .. "/res")
			cc.FileUtils:getInstance():addSearchResolutionsOrder(dev.DEV_PATH .. "/res/uijson")
			addSearchPath(dev.DEV_PATH .. "/res/resources")
			addSearchPath(dev.DEV_PATH .. "/res/spine")
			addSearchPath(dev.DEV_PATH .. "/res/sound")
			addSearchPath(dev.DEV_PATH .. "/res/video")
		end
	end

	cc.FileUtils:getInstance():addSearchResolutionsOrder("res")
	cc.FileUtils:getInstance():addSearchResolutionsOrder("res/uijson")
	addSearchPath("res/resources")
	addSearchPath("res/spine")
	addSearchPath("res/sound")

	display.director:setDisplayStats(false)
	display.director:setDirtyDrawEnable(false)
	scene:addChild(createBoardForLayer(createLayer()))
	display.director:runWithScene(scene)

	-- error("err after runWithScene")

	local volume = userDefault.getForeverLocalKey("musicVolume", 100, { rawKey = true })
	audio.setMusicVolume(volume / 100)
	local volume = userDefault.getForeverLocalKey("effectVolume", 100, { rawKey = true })
	audio.setSoundsVolume(volume / 100)
	audio.playMusic("login.mp3")

	-- 屏幕常亮
	-- 审核包更新时间较长
	cc.Device:setKeepScreenOn(true)

	curTime = os.time()
	local manager = cc.AssetsManagerEx:getInstance()
	local errCount = 0
	local errView = nil

	local function onEvent(event)
		-- printEvent(event)

		local code = event:getEventCode()
		if code == cc.EventAssetsManagerEx.EventCode.ALREADY_UP_TO_DATE then
			print('no new version')
			showLoadingOK()
		elseif code == cc.EventAssetsManagerEx.EventCode.UPDATE_FINISHED then
			sdk.trackEvent(15)
			print('updated ok')
			showLoadingOK()
		elseif code == cc.EventAssetsManagerEx.EventCode.UPDATE_CHECK then
			if event:getAssetId() == '@check' then
				sdk.trackEvent(11)
				print('update confirm')
				printEvent(event)
				local totalBytes = event:getTotalBytes() / 1024 / 1024
				loadingWidget:runAction(cc.Sequence:create(cc.DelayTime:create(delayTime), cc.CallFunc:create(function()
					-- enum class NetworkType
					-- {
					-- 	NONE = 0x00,
					-- 	M2G  = 0x01,
					-- 	M3G  = 0x02,
					-- 	M4G  = 0x03,
					-- 	WIFI = 0x04,
					-- 	ADSL = 0x05,
					-- };
					local network = cc.Device:getNetworkType()
					-- network = 1 -- TEST:
					print('network', network)
					if network < 4 and totalBytes > 10 then
						print('are you confirm update?')
						showDialog({
							content = string.format(Language.wifiTip, totalBytes),
							cb = function(doupdate)
								manager:update()
							end,
							closeCb = function()
								-- exit
								print('no, end lua')
								display.director:endToLua()
							end
						})
					else
						manager:update()
					end
				end)))
			end
		elseif code == cc.EventAssetsManagerEx.EventCode.UPDATE_PROGRESSION then
			if event:getAssetId() ~= '@version' then
				errCount = 0
				if errView then
					errView:onClickOK()
				end
				showLoadingProgress(event)
			end
		elseif code == cc.EventAssetsManagerEx.EventCode.ERROR_DOWNLOAD_MANIFEST then
			printEvent(event)
			print('download diff error')
			showDialog({
				content = Language.noConnected,
				cb = function(doupdate)
					sdk.trackEvent(16)
					errCount = 0
					manager:update()
				end,
				closeCb = function()
					-- exit
					print('no, end lua')
					display.director:endToLua()
				end
			})
		elseif code == cc.EventAssetsManagerEx.EventCode.ERROR_UPDATING then
			showLoadingProgress(event)
			-- 可能是服务器的更新包有问题
			if event:getMessage() == "Asset file verification failed after downloaded" then
				return
			end
			errCount = errCount + 1
			if errCount > 32 and not errView then -- 32 is _maxConcurrentTask
				printEvent(event)
				errView = showDialog({
					content = Language.noConnected,
					cb = function(doupdate)
						errCount = 0
						errView = nil
					end,
					closeCb = function()
						-- exit
						print('no, end lua')
						display.director:endToLua()
					end
				})
			end
		elseif code == cc.EventAssetsManagerEx.EventCode.UPDATE_FAILED then
			printEvent(event)
			print('download end with failed')
			if errView then
				errView:onClickOK()
			end
			local left = math.ceil((100 - event:getPercentByFile()) / 100 * event:getTotalFiles())
			showDialog({
				content = Language.reConnect:format(left),
				cb = function(doupdate)
					errCount = 0
					manager:downloadFailedAssets()
				end,
				closeCb = function()
					-- exit
					print('no, end lua')
					display.director:endToLua()
				end
			})
		end
	end

	-- test loading bar
	-- local percent = 0
	-- schedule(loadingWidget, function ()
	-- 	if delayTime > 0 then
	-- 		percent = percent + 100 / 60 / delayTime
	-- 	end
	-- 	local loading = loadingWidget:getChildByName("bar")
	-- 	loading:setVisible(true)
	-- 	loading:setPercent(percent)
	-- end, 0.01)

	local function safeOnEvent(...)
		if errHappened then return end

		local args = { ... }
		local function wrap()
			return onEvent(unpack(args))
		end
		local status, msg = xpcall(wrap, __G__TRACKBACK__)
		if not status then
			print('xpcall updater safeOnEvent error', status, msg)
			local manager = cc.AssetsManagerEx:getInstance()
			if manager.onLuaError then
				manager:onLuaError()
			end
			errHappened = true
		end
	end

	-- local function shenHeFunc()
	-- 	printInfo("check ip Shenhe")
	-- 	local KEY_OF_VERSION = "tianji_version2"
	-- 	userDefault.setForeverLocalKey(md5(KEY_OF_VERSION), PATCH_MIN_VERSION, { rawKey = true })
	-- 	manager:onLuaSuccess()
	-- end

	local function notShenheFunc()
		printInfo("check ip not Shenhe")
		local listener = cc.EventListenerAssetsManagerEx:create(manager, safeOnEvent)
		display.director:getEventDispatcher():addEventListenerWithSceneGraphPriority(listener, scene)
	end
	-- if LOCAL_LANGUAGE == "en" or LOCAL_LANGUAGE == "kr" and device.platform ~= "windows" then
	-- 	checkForShenhe(shenHeFunc, notShenheFunc)
	-- else
		notShenheFunc()
	-- end
end

local status, msg = xpcall(main, __G__TRACKBACK__)
if not status then
	print('xpcall updater main error', status, msg)
	local manager = cc.AssetsManagerEx:getInstance()
	if manager.onLuaError then
		manager:onLuaError()
	end
	errHappened = true
end
