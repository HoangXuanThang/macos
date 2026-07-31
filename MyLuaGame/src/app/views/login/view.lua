-- @desc 登录界面

-- 线上渠道帐号
local ONLINE_USER_NAME = dev.ONLINE_USER_NAME

if dev.LOGIN_ACCOUNT then
	userDefault.setForeverLocalKey("account", dev.LOGIN_ACCOUNT, { rawKey = true })
end
if dev.LOGIN_SERVER_KEY then
	userDefault.setForeverLocalKey("serverKey", dev.LOGIN_SERVER_KEY, { rawKey = true })
end

require "battle.app_views.battle.battle_entrance.include"

local LoginView = class("LoginView", cc.load("mvc").ViewBase)

LoginView.RESOURCE_FILENAME = "login.json"
LoginView.RESOURCE_BINDING = {
	["logo"] = "logo",
	["btn_enter"] = {
		varname = "btnLogin",
		binds = {
			event = "touch",
			clicksafe = true,
			methods = { ended = bindHelper.self("onLoginClick") },
		},
	},
	["btnPanel.btn_gonggao"] = {
		varname = "btn_gonggao",
		binds = {
			event = "touch",
			clicksafe = true,
			methods = { ended = bindHelper.self("onPlacardClick") },
		},
	},
	["btnPanel.btn_kefu"] = {
		varname = "btn_kefu",
		binds = {
			event = "touch",
			clicksafe = true,
			methods = { ended = bindHelper.self("onKefu") },
		},
	},
	["btnPanel.btn_zhanghao"] = {
		varname = "btn_zhanghao",
		binds = {
			event = "touch",
			clicksafe = true,
			methods = { ended = bindHelper.self("onSwitchAccount") },
		},
	},

	["server"] = {
		varname = "loginServer",
		binds = {
			event = "click",
			method = bindHelper.self("onChooseServer"),
		},
	},

	["server.chooseServer"] = {
		varname = "chooseServer",
		binds = {
			event = "click",
			method = bindHelper.self("onChooseServer"),
		},
	},
	["server.status"] = {
		varname = "statusImg",
		binds = {
			event = "texture",
			idler = bindHelper.self("serverStatus"),
		},
	},
	["server.currServer"] = "currentServer",
	["server.bg"] = "serverBg",
	["version"] = {
		binds = {
			{
				event = "text",
				data = "v" .. PATCH_VERSION,
			},
			{
				event = "effect",
				data = { outline = { color = ui.NEWCOLORS.OUTLINE.BLACK } },
			},
		},
	},
	["bg"] = "bg"

}

local input = {}
input.RESOURCE_FILENAME = "login_input.json"
input.RESOURCE_BINDING = {
	account = "account",
	txtAccount = "txtAccount",
	password = "password",
	txtPassword = "txtPassword",
	switchModeBtn = "switchModeBtn",
	bgConfirmPassword = "bgConfirmPassword",
	confirmPasswordLabel = "confirmPasswordLabel",
	txtConfirmPassword = "txtConfirmPassword",
}

-- API URL cho login và register
local LOGIN_API_URL = "http://163.223.12.142/gameAPI/login.php"
local REGISTER_API_URL = "http://163.223.12.142/gameAPI/register.php"

-- local STATUS = {
-- 	[1] = "login/logo_red.png",
-- 	[2] = "login/logo_green.png",
-- 	[3] = "login/logo_gray.png",
-- }

local STATUS = {
	[1] = gLanguageCsv.hot,
	[2] = gLanguageCsv.fluency,
	[3] = gLanguageCsv.preserve,
}

local STATUSCOLOR = {
	[1] = ui.COLORS.NORMAL.RED,
	[2] = cc.c4b(107, 201, 145, 255),
	[3] = cc.c4b(187, 187, 187, 255),
}


function LoginView:onCreate()
	self.userName = nil
	self.isRegisterMode = false
	print("APP_CHANNEL:", APP_CHANNEL)
	-- widget.addAnimation(self.bg, "lihui/lihui_mega_jierjiameishi.skel", "default", 1, true):alignCenter(self.bg:size()):setScale(0.5)
	 widget.addAnimation(self.bg, "login/login.skel", "effect_loop", 1, true):alignCenter(self.bg:size())

	--self:getResourceNode():getChildByName("btnPanel"):getChildByName("btn_gonggao"):hide()
	--self:getResourceNode():getChildByName("btnPanel"):getChildByName("btn_kefu"):hide()
	self:getResourceNode():getChildByName("btnPanel"):getChildByName("btn_zhanghao"):hide()

	self.serverStatus = idler.new("serverStatus")
	self.currentServer:text("currentServer")
	
	-- Tạo form đăng nhập/đăng ký với username và password
	if (APP_CHANNEL == "none" or APP_CHANNEL == "luo") then
		-- Giữ lại input widget cũ để tương thích
		local pos = gGameUI:getConvertPos(self.loginServer)
		self.inputWidget = gGameUI:createSimpleView(input, self):init()
		local size = self.inputWidget:getResourceNode():size()
		self.inputWidget:xy(pos.x - size.width / 2, pos.y - size.height / 2)
		local account = userDefault.getForeverLocalKey("account", "", { rawKey = true })
		self.inputWidget.txtAccount:setText(account)
		self.inputWidget.txtAccount:setPlaceHolderColor(ui.COLORS.DISABLED.GRAY)
		self.inputWidget.txtPassword:setPlaceHolderColor(ui.COLORS.DISABLED.GRAY)
		if self.inputWidget.txtConfirmPassword then
			self.inputWidget.txtConfirmPassword:setPlaceHolderColor(ui.COLORS.DISABLED.GRAY)
		end
		if dev.ONLINE_VERSION_LANGUAGE and ONLINE_USER_NAME then
			self.inputWidget.txtAccount:setString(ONLINE_USER_NAME)
		end
		adapt.oneLinePos(self.inputWidget.account, self.inputWidget.txtAccount, cc.p(15, 0))
		adapt.oneLinePos(self.inputWidget.password, self.inputWidget.txtPassword, cc.p(15, 0))
		if self.inputWidget.confirmPasswordLabel and self.inputWidget.txtConfirmPassword then
			adapt.oneLinePos(self.inputWidget.confirmPasswordLabel, self.inputWidget.txtConfirmPassword, cc.p(15, 0))
		end
		
		-- Bind touch event cho nút đăng ký
		if self.inputWidget.switchModeBtn then
			bind.click(self, self.inputWidget.switchModeBtn, {method = bindHelper.self("onSwitchMode")})
		end
	end

	sdk.getSDKCfg(function(sdkInfo)
		if sdkInfo then
			local sdkCfg = json.decode(sdkInfo)

			local sdkAttach = sdkCfg.sdk_attach
			if sdkAttach then
				SERVER_CONF_URL = string.format("%s/servers", sdkAttach.baseUrl)
				NOTICE_CONF_URL = string.format("%s/notice", sdkAttach.baseUrl)

				REPORT_CONF_URL = sdkAttach.reportUrl
				FEED_BACK_URL = string.format("%s/feedback", sdkAttach.reportUrl)
				DISABLE_WORD_CHECK_URL = string.format("%s/check", sdkAttach.disableWordCheckUrl)
				PAYMENT_URL = sdkAttach.paymentUrl

				LOGIN_SERVRE_HOSTS_TABLE = { sdkAttach.loginServer }

				if ymdump then
					ymdump.setUserInfo("url", REPORT_CONF_URL)
				end
				
				gGameApp.net:initLoginUrl()
			end
		end

		if not dev.IGNORE_POPUP_BOX then
			local currTime = os.date("%Y%m%d", os.time())
			local data = userDefault.getForeverLocalKey("placardStatusDay", {}, { rawKey = true, rawData = true })
			-- 配置list管理打开的界面
			local list = {
				{
					key = data[currTime],
					cb = function(f)
						self:showPlacard()
					end
				}
			}
			self:managerOpenView(list, 1)
		end

		-- audio.playMusic("login.mp3")

		userDefault.setForeverLocalKey("posterLoginShow", false, { rawKey = true })


		self:testInLogin()
		if device.platform ~= "windows" and (not (APP_CHANNEL == "none" or APP_CHANNEL == "luo")) then
			-- 自动登录
			self:onLoginClick()
		end
	end)
	sdk.trackEvent(2)
	-- self:additionForEN()
	--self:addChangeLanguage()
	self:testInLogin()

end

function LoginView:createSupportLabel(parent, text, fontSize, onClick)
	local lbl = label.create(text, {
		fontPath = "font/youmi1.ttf",
		fontSize = fontSize,
		color = ui.COLORS.NORMAL.WHITE,
		pos = cc.p(parent:getContentSize().width/2, -20),
		effect = {outline = {color = ui.COLORS.OUTLINE.DEFAULT}},
	}):addTo(parent)
	bind.touch(self, parent, {methods = {ended = onClick}})
	return lbl
end

function LoginView:addChangeLanguage()
	print("IS_SEA = ", IS_SEA)
	if not IS_SEA then
		print("Language button not show IS_SEA = false")
		return
	end

	local btnZhanghao = self.btn_zhanghao
	local pos = cc.p(btnZhanghao:getPosition())
	local size = btnZhanghao:getContentSize()

	local newPos = cc.p(pos.x, pos.y - size.height - 200)

	-- Tạo nút language
	local btn = ccui.Button:create("login/language.png")
	btn:setPosition(newPos)
	btn:addTo(btnZhanghao:getParent())
	btn:scale(1) -- chỉnh scale nếu cần

	-- Tạo label
	self:createSupportLabel(btn, "Language", 38, functools.partial(self.onChangeLanguageBtnClick, self, 3))
	print("Language button added")
end

function LoginView:onChangeLanguageBtnClick(tag)
	gGameUI:stackUI("login.language", nil, nil, {
		onClose = function()
			
		end,
	})
	
end

function LoginView:additionForEN()
	if not matchLanguage({"en"}) then
		return
	end

	local btn
	local startPos = cc.p(self.btnProtocol:getPosition())

	btn = ccui.Button:create("login/icon_fanpage.png")
		:setPosition(startPos)
		:addTo(self.leftPanel)
		:scale(0.83)
	self:createSupportLabel(btn, "Fanpage", 38, functools.partial(self.onAdditionBtnClick, self, 3))

	startPos.y = startPos.y - 160
	btn = ccui.Button:create("login/icon_groupfb.png")
		:setPosition(startPos)
		:addTo(self.leftPanel)
		:scale(0.83)
	self:createSupportLabel(btn, "Group", 38, functools.partial(self.onAdditionBtnClick, self, 4))

	startPos.y = startPos.y - 160
	btn = ccui.Button:create("login/icon_zalo.png")
		:setPosition(startPos)
		:addTo(self.leftPanel)
		:scale(0.83)
	self:createSupportLabel(btn, "Zalo", 38, functools.partial(self.onAdditionBtnClick, self, 5))

	if APP_CHANNEL== "lp_en"  then
		self:getResourceNode():getChildByName("btnPanel"):getChildByName("btn_zhanghao"):hide()

	end
	
end

function LoginView:onAdditionBtnClick(tag)
	if matchLanguage({"kr"}) then
		if tag == 1 then
			-- 个人情报
			sdk.commitRoleInfo(51,function()
				print("sdk commitRoleInfo self infomation")
			end)
		elseif tag == 2 then
			-- 运营政策
			sdk.commitRoleInfo(52,function()
				print("sdk commitRoleInfo policy")
			end)
		elseif tag == 3 then
			-- 用户协议
			sdk.commitRoleInfo(53,function()
				print("sdk commitRoleInfo user protocol")
			end)
		elseif tag == 4 then
			-- 客服中心
			sdk.commitRoleInfo(54,function()
				print("sdk commitRoleInfo customerService")
			end)
		end
	elseif matchLanguage({"cn"}) then
		if tag == 1 then
			gGameUI:stackUI("common.rule", nil, nil, self:createHandler("getRuleContext"), {width = 1500})
		end
	elseif matchLanguage({"en"}) then
		if tag == 4 then
			cc.Application:getInstance():openURL(SUPPORT_URL)
		elseif tag == 5 then
			cc.Application:getInstance():openURL(DISCORD_URL)
		end
	elseif matchLanguage({"vn"}) then
		if tag == 3 then
			cc.Application:getInstance():openURL(FACEBOOK_URL)
		elseif tag == 4 then
				cc.Application:getInstance():openURL(GROUP_URL)
		elseif tag == 5 then
			cc.Application:getInstance():openURL(ZALO_URL)
		elseif tag == 6 then
			sdk.switch(function(code, info)
				printInfo("LoginView:sdk.switch %s %s", code, info)
				if code == 1 then		
					self:getResourceNode():getChildByName("btnPanel"):getChildByName("btn_zhanghao"):hide()
					gGameApp:onBackLogin()
					-- sdk.logout(function(info)
					-- 	print("sdk logout callback", info)
					-- 	gGameApp:onBackLogin()
					-- end)
				end
				if code == 0 then
					--self.leftPanel:getChildByName("Switch"):hide()
					--sdk.logout(function(info)
						--print("sdk logout callback", info)
						--gGameApp:onBackLogin()
					--end)
				end
			end)
		elseif tag == 7 then
			sdk.logout(function(info)
				print("sdk logout callback===>", info)
			end)

			self.leftPanel:getChildByName("Switch"):hide()
			gGameApp:onBackLogin()
		end
	end
end

-- 测试用
function LoginView:testInLogin()
	if device.platform == "windows" then
		local testInject = require "app.views.login.test"
		testInject(LoginView)

		self:createTestScene()
	end

	if APP_CHANNEL == "none" and false then
		local testInject = require "app.views.login.test"
		testInject(LoginView)

		performWithDelay(self, handler(self, "showBenchmark"), 4)
	end
end

function LoginView:onPlacardClick()
	self:showPlacard()
end

function LoginView:onKefu()
	sdk.openCustomerService(function()
		printInfo('LoginView:openCustomerService')
	end)
	cc.Application:getInstance():openURL("https://www.facebook.com/profile.php?id=61580437318313")
end

function LoginView:onSwitchAccount()
	if (APP_CHANNEL == "none" or APP_CHANNEL == "luo") then
		sdk.logout(function(info)
			print("sdk logout callback", info)
		end)
		gGameApp:onBackLogin()
		return
	end
	-- if not self.serverSelected then
	-- 	return
	-- end
	-- sdk.logout(function(info)
	-- 	print("sdk logout callback", info)
	-- end)
	-- gGameApp:onBackLogin()
	sdk.switch(function(code, info)
		printInfo("LoginView:sdk.switch %s %s", code, info)
		if code == 1 then		
			--self.leftPanel:getChildByName("Switch"):hide()
			self:getResourceNode():getChildByName("btnPanel"):getChildByName("btn_zhanghao"):hide()
			gGameApp:onBackLogin()
			-- sdk.logout(function(info)
			-- 	print("sdk logout callback", info)
			-- 	gGameApp:onBackLogin()
			-- end)
		end
		if code == 0 then
			--self.leftPanel:getChildByName("Switch"):hide()
			--sdk.logout(function(info)
				--print("sdk logout callback", info)
				--gGameApp:onBackLogin()
			--end)
		end
	end)
	
end

function LoginView:onChooseServer()
	gGameUI:stackUI("login.server", {
		setServerInfo = self:createHandler("setServerInfo"),
	}, nil, self.servers)
end

function LoginView:onLoginClick(node, event)
	if self.serverSelected and self.servers then
		sdk.trackEvent(20)
		local server = self.servers[self.serverSelected]
		print("selected server", self.serverSelected, dumps(server))

		gGameApp:requestServerCustom("/login/enter_server")
			:params(server)
			:onErrCall(function(err)
				if err.servers and #err.servers > 0 then
					self:setServers(err.servers)
				end
				if err.err == "register_disable" then
					local function autoChooseNew()
						local server = self.servers[self:selectServerIdx()]
						self:setServerInfo(server)
						gGameUI:showTip(gLanguageCsv.serverAutoChooseNew .. getServerName(server.key, true))
					end
					gGameUI:showDialog({
						title = gLanguageCsv.tips,
						content = gLanguageCsv.serverRegisterDisable,
						dialogParams = { clickClose = false },
						cb = autoChooseNew,
						closeCb = autoChooseNew,
					})
				else
					gGameUI:showDialog({
						title = gLanguageCsv.tips,
						content = gLanguageCsv[err.err] or err.err,
						dialogParams = { clickClose = false },
					})
				end
			end)
			:doit(function(tb)
				gGameApp:setGameServerAddr(server)
				gGameApp:requestServer("/game/login", function(tb)
					
					userDefault.setForeverLocalKey("serverKey", self.servers[self.serverSelected].key, { rawKey = true })
					local fps = userDefault.getForeverLocalKey("fps", 60, { rawKey = true })
					cc.Director:getInstance():setAnimationInterval(1.0 / fps)
					-- -2.特殊隐藏左上角15次跳过引导, -1. 第一次新手战斗, 1. 选形象名字, 2.选初始卡牌
					if gGameUI.guideManager:checkFinished(1) and gGameUI.guideManager:checkFinished(2) then
						-- 2. 去城镇
						sdk.commitRoleInfo(1, function()
							print("sdk commitRoleInfo and go to city")
						end) --进入游戏为1
						
						--gGameUI.skinCardBalance = gGameUI.skinCardBalance or idler.new(0)
						gGameUI:switchUI("city.view")
					else
						dataEasy.isSkipNewbieBattle(function()
							if not gGameUI.guideManager:checkFinished(-1) then
								gGameApp:requestServer("/game/role/guide/newbie", nil, -1)
							end
							gGameUI:switchUI("new_character.view")
						end, function()
							self:newbieBattle()
						end)
					end
				end)
			end)
	else
		sdk.trackEvent(19)
		local userName = ""
		if (APP_CHANNEL == "none" or APP_CHANNEL == "luo") then
			if self.inputWidget then
				userName = self.inputWidget.txtAccount:getString()
				local password = self.inputWidget.txtPassword:getString()
				
				if userName == "" then
					gGameUI:showTip("Vui lòng nhập tài khoản")
					return
				end
				if password == "" then
					gGameUI:showTip("Vui lòng nhập mật khẩu")
					return
				end
				
				-- Gọi API login hoặc register
				if self.isRegisterMode then
					self:doAPIRegister(userName, password)
				else
					self:doAPILogin(userName, password)
				end
			end
		else
			sdk.login(function(code, info)
				printInfo('LoginView:sdkLogin %s %s', code, info)
				if code == 0 then
					-- Giải mã chuỗi JSON nếu cần
					local infoTable = type(info) == "table" and info or json.decode(info)
					-- Kiểm tra lại
					if not infoTable or not infoTable.token then
						printWarn("info.token nil, infoTable:", info)
						return
					end
					self:onServerLogin(info)


				
				end
				if code == -2 then
					gGameUI:showDialog { content = 'SDK Khởi tạo chưa hoàn tất' }
				end
			end)
		end
	end

	-- 引擎之前没有在updater更新后重新获取patch，导致平台显示的patch有延后，这里再重新设置下
	local versionPlist = cc.FileUtils:getInstance():getValueMapFromFile('res/version.plist')
	ymdump.setUserInfo("patch", tostring(versionPlist.patch))
end

function LoginView:onReturnClick(node, event)
	self.btnLogin:get("login"):setText("Bước vào trò chơi")

	self.isregister = 0
end

-- [{"id":1,"name":"S1","key":"game.shenhe.1","status":2,"addr":"172.81.227.66:10888"},{"id":1,"name":"xxx","key":"game.cn.1","status":2,"addr":"212.64.40.75:10888"}]
-- 20.3.18 由服务器根据 channel 做过滤，客户端只用判 shenhe 的
local function filterServer(info)
	local key = info.key
	-- none 全显示
	-- luo 裸包看配置
	if APP_CHANNEL == "none" then
		return true
	end

	-- local isShenheServer = key:find("game.shenhe.") ~= nil
	-- if FOR_SHENHE then
	-- 	return isShenheServer
	-- end

	-- return not isShenheServer
	return true
end

function LoginView:showServerTip()
	local title = gLanguageCsv.serverOpenTime
	if APP_CHANNEL == "tc_beta" then
		title = gLanguageCsv.serverCloseTime
	end
	gGameUI:showDialog({
		title = gLanguageCsv.tips,
		content = title,
		dialogParams = { clickClose = false },
	})
end

-- 用服务器数据获得服务器列表
function LoginView:setServers(serversStr)
	local servers = json.decode(serversStr)
	collectgarbage()

	self.servers = {}
	SERVERS_INFO = {}
	for k, v in ipairs(servers) do
		-- 后续有双平台，server.id 会重复，使用 server.key
		SERVERS_INFO[v.key] = v
		if filterServer(v) then
			table.insert(self.servers, v)
		else
			printDebug("the server %s be ignore", dumps(v))
		end
	end
	table.sort(self.servers, function(a, b)
		local tagA = string.split(a.key, ".")[2]
		local tagB = string.split(b.key, ".")[2]
		local orderA = SERVER_MAP[tagA] and SERVER_MAP[tagA].order or math.huge
		local orderB = SERVER_MAP[tagB] and SERVER_MAP[tagB].order or math.huge
		if orderA ~= orderB then
			return orderA < orderB
		end
		return a.id < b.id
	end)
end

-- 选择流畅服下标
function LoginView:selectServerIdx()
	local t = {}
	for i, v in ipairs(self.servers) do
		if v.status == 2 then
			table.insert(t, i)
		end
	end
	if #t > 0 then
		return t[math.random(1, #t)]
	end
	return #self.servers
end

function LoginView:onServerLogin(userName)
	-- 防止重复通知导致的多次login请求
	if userName == self.userName then
		printWarn("onServerLogin %s too much", userName)
		
		return
	end
	self.userName = userName

	gGameApp:requestServerCustom("login")
		:onErrClose(function()
			self.userName = nil
		end)
		:params(userName)
		:doit(function(tb)
			self:setServers(tb.servers)
			if #self.servers == 0 then
				self:showServerTip()
				self.userName = nil
				return
			end

			-- get serverSelected
			local serverKey = userDefault.getForeverLocalKey("serverKey", nil, { rawKey = true })
			if serverKey then
				self.serverSelected = itertools.first(self.servers, function(v)
					return v.key == serverKey
				end)
			else
				self.serverSelected = userDefault.getForeverLocalKey("serverId", nil, { rawKey = true })
			end
			if not self.servers[self.serverSelected] then
				self.serverSelected = self:selectServerIdx()
			end

			if dev.ONLINE_VERSION_LANGUAGE then
				-- 内网登录线上服默认读取已有最高等级的帐号区服
				local roleInfos = gGameModel.account:read("role_infos")
				local maxLevel = 0
				for k, v in ipairs(self.servers) do
					if roleInfos[v.key] and roleInfos[v.key].level > maxLevel then
						maxLevel = roleInfos[v.key].level
						self.serverSelected = k
					end
				end
			end

			local current = self.servers[self.serverSelected]
			self:setServerInfo(self.servers[self.serverSelected])
			self:showLoginServer()
		end)
end

function LoginView:showPlacard()
	sdk.trackEvent(17)
	gGameApp:getNotice(function(ret)
		gGameUI:stackUI("login.placard", nil, nil, ret.notice)
	end)
end

-- Xử lý đăng nhập qua API
function LoginView:doAPILogin(username, password)
	gGameUI:showConnecting()
	
	-- Mã hóa MD5 password
	require "3rd.MD5"
	local md5Password = md5(password)
	
	local xhr = cc.XMLHttpRequest:new()
	xhr.responseType = cc.XMLHTTPREQUEST_RESPONSE_STRING
	xhr:open("POST", LOGIN_API_URL)
	xhr.timeout = 10
	xhr:setRequestHeader("Content-Type", "application/x-www-form-urlencoded")
	
	xhr:registerScriptHandler(function()
		if xhr.readyState ~= 4 then
			return
		end
		
		gGameUI:hideConnecting()
		
		if xhr.status == 200 then
			local response = xhr.response
			print("Login API response:", response)
			
			local ok, result = pcall(json.decode, response)
			print("JSON decode ok:", ok, "result:", result and dumps(result) or "nil")
			
			if ok and result then
				print("result.status:", result.status, "type:", type(result.status))
			end
			
			-- Kiểm tra status == 0 (number) hoặc status == "0" (string)
			local isSuccess = ok and result and (result.status == 0 or result.status == "0")
			
			if isSuccess then
				-- Login thành công
				print("Login success:", username)
				userDefault.setForeverLocalKey("account", username, { rawKey = true })
				cc.UserDefault:getInstance():setStringForKey("username", username)
				cc.UserDefault:getInstance():flush()
				sdk.loginInfo = username
				self:onServerLogin(username)
			else
				-- Login thất bại
				local errMsg = (ok and result and result.msg) or "Đăng nhập thất bại"
				print("Login failed, showing tip:", errMsg)
				gGameUI:showTip(errMsg)
			end
		else
			gGameUI:showTip("Lỗi kết nối server: " .. tostring(xhr.status))
		end
	end)
	
	local postData = string.format("username=%s&password=%s", username, md5Password)
	xhr:send(postData)
end

-- Chuyển đổi giữa đăng nhập và đăng ký
function LoginView:onSwitchMode()
	self.isRegisterMode = not self.isRegisterMode
	
	if self.inputWidget then
		if self.isRegisterMode then
			if self.inputWidget.switchModeBtn then
				self.inputWidget.switchModeBtn:setString("Đăng nhập")
			end
			self.inputWidget.txtAccount:setPlaceHolder("Nhập tài khoản")
			-- Hiện trường nhập lại mật khẩu
			if self.inputWidget.bgConfirmPassword then
				self.inputWidget.bgConfirmPassword:setVisible(true)
			end
			if self.inputWidget.confirmPasswordLabel then
				self.inputWidget.confirmPasswordLabel:setVisible(true)
			end
			if self.inputWidget.txtConfirmPassword then
				self.inputWidget.txtConfirmPassword:setVisible(true)
			end
		else
			if self.inputWidget.switchModeBtn then
				self.inputWidget.switchModeBtn:setString("Đăng ký")
			end
			self.inputWidget.txtAccount:setPlaceHolder("Nhập tài khoản")
			-- Ẩn trường nhập lại mật khẩu
			if self.inputWidget.bgConfirmPassword then
				self.inputWidget.bgConfirmPassword:setVisible(false)
			end
			if self.inputWidget.confirmPasswordLabel then
				self.inputWidget.confirmPasswordLabel:setVisible(false)
			end
			if self.inputWidget.txtConfirmPassword then
				self.inputWidget.txtConfirmPassword:setVisible(false)
				self.inputWidget.txtConfirmPassword:setString("")
			end
		end
	end
end

-- Xử lý đăng ký qua API
function LoginView:doAPIRegister(username, password)
	-- Kiểm tra nhập lại mật khẩu
	local confirmPassword = ""
	if self.inputWidget and self.inputWidget.txtConfirmPassword then
		confirmPassword = self.inputWidget.txtConfirmPassword:getString()
	end
	
	if confirmPassword == "" then
		gGameUI:showTip("Vui lòng nhập lại mật khẩu")
		return
	end
	
	if password ~= confirmPassword then
		gGameUI:showTip("Mật khẩu không khớp")
		return
	end
	
	-- Validate username
	if string.len(username) < 6 or string.len(username) > 20 then
		gGameUI:showTip("Tên đăng nhập phải từ 6-20 ký tự")
		return
	end
	
	if not string.match(username, "^[a-z0-9]+$") then
		gGameUI:showTip("Tên đăng nhập chỉ chứa chữ thường và số")
		return
	end
	
	gGameUI:showConnecting()
	
	-- Mã hóa MD5 password
	require "3rd.MD5"
	local md5Password = md5(password)
	
	local xhr = cc.XMLHttpRequest:new()
	xhr.responseType = cc.XMLHTTPREQUEST_RESPONSE_STRING
	xhr:open("POST", REGISTER_API_URL)
	xhr.timeout = 10
	xhr:setRequestHeader("Content-Type", "application/x-www-form-urlencoded")
	
	xhr:registerScriptHandler(function()
		if xhr.readyState ~= 4 then
			return
		end
		
		gGameUI:hideConnecting()
		
		if xhr.status == 200 then
			local response = xhr.response
			print("Register API response:", response)
			
			local ok, result = pcall(json.decode, response)
			print("JSON decode ok:", ok, "result:", result and dumps(result) or "nil")
			
			local isSuccess = ok and result and (result.status == 0 or result.status == "0")
			
			if isSuccess then
				-- Đăng ký thành công
				print("Register success:", username)
				gGameUI:showTip("Đăng ký thành công! Vui lòng đăng nhập")
				-- Chuyển về mode đăng nhập
				self.isRegisterMode = false
				if self.inputWidget then
					if self.inputWidget.switchModeBtn then
						self.inputWidget.switchModeBtn:setString("Đăng ký")
					end
					self.inputWidget.txtAccount:setPlaceHolder("Nhập tài khoản")
					-- Ẩn trường nhập lại mật khẩu
					if self.inputWidget.bgConfirmPassword then
						self.inputWidget.bgConfirmPassword:setVisible(false)
					end
					if self.inputWidget.confirmPasswordLabel then
						self.inputWidget.confirmPasswordLabel:setVisible(false)
					end
					if self.inputWidget.txtConfirmPassword then
						self.inputWidget.txtConfirmPassword:setVisible(false)
						self.inputWidget.txtConfirmPassword:setString("")
					end
				end
			else
				-- Đăng ký thất bại
				local errMsg = (ok and result and result.msg) or "Đăng ký thất bại"
				print("Register failed:", errMsg)
				gGameUI:showTip(errMsg)
			end
		else
			gGameUI:showTip("Lỗi kết nối server: " .. tostring(xhr.status))
		end
	end)
	
	local postData = string.format("username=%s&password=%s", username, md5Password)
	xhr:send(postData)
end

function LoginView:showLoginServer()
	if (APP_CHANNEL == "none" or APP_CHANNEL == "luo") then
		if self.inputWidget then
			self.inputWidget:onClose()
		end
	end
	if matchLanguage({"en", "vn", "th", "in", "ma"}) and APP_CHANNEL == "lp_en" then
		if device.platform ~= "windows" then
			self:getResourceNode():getChildByName("btnPanel"):getChildByName("btn_zhanghao"):show()
		end
	end
	self.loginServer:show()
end

function LoginView:setServerInfo(server)
	self.serverStatus:set(STATUS[server.status])
	self.currentServer:text(string.format("S%s. %s", getServerId(server.key, true), getServerName(server.key, true)))
	self.serverSelected = itertools.first(self.servers, function(v)
		return v.key == server.key
	end)
	local maxWidth = math.max(self.currentServer:width() + self.statusImg:width() + self.chooseServer:width() + 150,
		823)
	self.serverBg:width(maxWidth)
	adapt.oneLineCenterPos(cc.p(self.serverBg:xy()), { self.statusImg, self.currentServer, self.chooseServer },
		cc.p(50, 0))
end

-- 新号登录战斗界面
function LoginView:newbieBattle()
	local data = {
		sceneID = 1, -- 新手关卡id
		roleOut = csvClone(csv.role_out_init),
		randSeed = 123456,
		moduleType = 1, -- 战斗选择类型默认为 1: 常规  2: 全手动
		roleLevel = 1,

		names = { gLanguageCsv.newbieName1, gLanguageCsv.newbieName2 },
		levels = { 99, 99 },
		logos = { 52, 50 },
		preData = {},
	}
	printInfo("in newbieBattle")
	-- print_r(data.roleOut)

	local view = gGameUI:switchUIAndStash("battle.loading", data, data.sceneID, { baseMusic = "battle4.mp3" }, {})
	view:onLoadOver()
	-- 视频第 53 秒播放背景音乐
	--performWithDelay(view, function()
	--	if gGameUI.isPlayVideo then
	--		--view:onPlayMusic("battle4_pre.mp3")
	--	end
	--end, 53)
	--performWithDelay(view, function()
	--	if gGameUI.isPlayVideo then
	--		view:onPlayMusic()
	--	end
	--end, 53 + 8)
	--gGameUI:playVideo("new.mp4", function ()
	--	view:onLoadOver()
	--end)
	if device.platform == "ios" then
		gGameUI:playVideo("new.mp4", function()
			view:onLoadOver()
		end)
	else
		gGameUI:playVideo("new.mp4", function()
			view:onLoadOver()
		end)
	end
end

function LoginView:onVideoPlayEnd(view)
	performWithDelay(view, function()
		view:onLoadOver()
	end, 0)
end

function LoginView:managerOpenView(list, num)
	local data = list[num]
	if not data then return end
	if not data.key then
		data.cb(self:createHandler("managerOpenView", list, num + 1))
	else
		self:managerOpenView(list, num + 1)
	end
end

return LoginView
