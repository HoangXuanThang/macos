local gGameApp = gGameApp -- root game ui
local gGameUIMain = gGameUI -- root game ui

local RobotView = class("RobotView", cc.load("mvc").ViewBase)

RobotView.RESOURCE_FILENAME = "robot.json"
RobotView.RESOURCE_BINDING = {
	["Button_Temp"] = "temp",
	["Button_OK"] = {
		varname = "btnOK",
		binds = {{
				event = "click",
				method = bindHelper.self("onOK"),
			}, {
				event = "text",
				idler = bindHelper.self("btnOKText"),
			},
		},
	},
	["Label_1"] = {
		varname = "lblTitle",
		binds = {
			event = "text",
			idler = bindHelper.self("title"),
		},
	},
	["Panel_Right"] = "right",
	["ListView_Tab"] = {
		varname = "lstTab",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("tabs"),
				item = bindHelper.self("temp"),
				onItem = function(list, node, k, v)
					node:text(v.name)
					bind.click(list, node, v)
				end,
			},
		},
	},
}

function RobotView:onCreate()
	gGameUI = gGameUIMain
	self.title = idler.new("RobotTest")
	self.btnOKText = idler.new("启 动")
	self.tabChoose = idler.new()
	self.tabs = {
		{name = "Login", func = self.onLoginTest, method = functools.partial(self.onTestClick, self, 1)},
		{name = "Level 6", func = functools.partial(self.onLoginAndLevel6Test, self, true), method = functools.partial(self.onTestClick, self, 2)},
	}
	self.startTest = nil
	self.updateTest = nil
	self.stopTest = nil
	self.endTest = nil
	self.isRun = false

	self.btnOK:setEnabled(false)
	self.tabChoose:addListener(functools.partial(self.onTestChoose, self), true)
end

function RobotView:onUpdate(delta)
	if not self.isRun then return end
	if self.updateTest then
		return self.updateTest(delta)
	end
end

function RobotView:onTestClick(v)
	self.tabChoose:set(v)
end

function RobotView:onTestChoose(idx)
	self.title:set("RobotTest")
	if idx == nil then return end

	local case = self.tabs[idx]
	self.title:set(string.format("RobotTest - %s", case.name))
	self.btnOK:setEnabled(true)
	self.right:removeAllChildren()

	case.func(self)
end


function RobotView:onLoginTest()
	print('RobotView.onLoginTest')


	-- local inputPrefix = ccui.EditBox:create(cc.size(600, 100), "common/box/box_charselected.png", 0)
	-- inputPrefix:xy(400, 800):addTo(self.right):setPlaceHolder("输入账号前缀")
	local inputNum = ccui.EditBox:create(cc.size(600, 100), "common/box/box_charselected.png", 0)
	inputNum:xy(400, 800):addTo(self.right):setPlaceHolder("输入数量")
	local txtStat = ccui.Text:create("0/0\ntest", "", 60)
	txtStat:align(cc.p(0, 1), 800, 800):addTo(self.right)


	local n = 1
	local prefix = "robot_%d"
	local apps = {}
	local tStart = 0
	local ts = {
		login = 0,
		enter = 0,
		game = 0,
		lend = 0,
	}
	local cnt = {
		login = 0,
		enter = 0,
		game = 0,
		lend = 0,
	}

	local function getStatStr()
		local t = {
			string.format("login %d/%d %.2fs", cnt.login, n, ts.login/cnt.login),
			string.format("/login/enter_server %d/%d %.2fs", cnt.enter, n, ts.enter/cnt.enter),
			string.format("/game/login %d/%d %.2fs", cnt.game, n, ts.game/cnt.game),
			string.format("doLoginEnd %d/%d %.2fs", cnt.lend, n, ts.lend/cnt.lend),
		}
		return table.concat(t, "\n")
	end

	self.startTest = function()
		-- print('inputPrefix', inputPrefix:getText())
		print('inputNum', inputNum:getText())
		n = tonumber(inputNum:getText())
		-- prefix = inputPrefix:getText()
		prefix = "testLogin"
		if prefix == "" then
			gGameUI:showDialog({title = "Info", content = "输入正确账号前缀", fontSize = 60, dialogParams = {clickClose = false}})
			return false
		end
		prefix = prefix .. "%d"
		if n == nil then
			gGameUI:showDialog({title = "Info", content = "输入正确数量", fontSize = 60, dialogParams = {clickClose = false}})
			return false
		end

		tStart = os.time()
		for i = 1, n do
			local st
			local app = require("app.game_app"):create()
			local name = string.format(prefix, i)
			apps[i] = {
				app = app,
				name = name,
				finished = false,
			}
			gGameUI = gGameUIMain
			gGameModel = apps[1].app.model
			local doLoginEnd = app.net.doLoginEnd
			app.net.doLoginEnd = function(...)
				app.net.loginSession:close()
				app.net.gameSession:close()

				apps[i].finished = true
				ts.lend = os.time() - st + ts.lend
				cnt.lend = cnt.lend + 1

				txtStat:text(getStatStr())
				return doLoginEnd(...)
			end

			st = os.time()
			app:slientRequestServer("login", function(tb)
				ts.login = os.time() - st + ts.login
				cnt.login = cnt.login + 1
				txtStat:text(getStatStr())

				self.servers = json.decode(tb.servers)
				self.serverSelected = 2
				local server = self.servers[self.serverSelected]
				-- print("selected server", self.serverSelected, dumps(server))

				st = os.time()
				app:slientRequestServer("/login/enter_server", function(tb)
					ts.enter = os.time() - st + ts.enter
					cnt.enter = cnt.enter + 1
					txtStat:text(getStatStr())

					app:setGameServerAddr(server)

					st = os.time()
					app:slientRequestServer("/game/login", function(tb)
						gGameModel = app.model
						userDefault.setForeverLocalKey("serverKey", server.key, {rawKey = true})
						ts.game = os.time() - st + ts.game
						cnt.game = cnt.game + 1
						txtStat:text(getStatStr())

						st = os.time()
					end)
				end, server)
			end, name)
		end
		return true
	end

	self.updateTest = function(delta)
		if n == cnt.lend then
			return self:onEndTest()
		end
		for _, d in pairs(apps) do
			d.app:onUpdate(delta)
		end
	end

	self.endTest = function()
		gGameUI:showDialog({title = "Info", content = "测试完成", fontSize = 60, dialogParams = {clickClose = false}})

		local s = txtStat:text()
		s = s .. "\n-------\n"
		local delta = os.time() - tStart
		s = s .. string.format("%.2f s", delta)
		txtStat:text(s)

		apps = {}

		print(collectgarbage("count"))
		collectgarbage("collect")
		print(collectgarbage("count"))

		printAllIdlers()
	end
end

function RobotView:onLoginAndLevel6Test()
	print('RobotView.onLoginAndLevel6Test')


	local inputNum = ccui.EditBox:create(cc.size(600, 100), "common/box/box_charselected.png", 0)
	inputNum:xy(400, 800):addTo(self.right):setPlaceHolder("输入数量")
	local inputDelta = ccui.EditBox:create(cc.size(600, 100), "common/box/box_charselected.png", 0)
	inputDelta:xy(400, 600):addTo(self.right):setPlaceHolder("输入请求间隔, 默认0")
	local txtStat = ccui.Text:create("0/0\ntest", "", 60)
	txtStat:align(cc.p(0, 1), 800, 800):addTo(self.right)


	local n = 1
	local prefix = "robot_%d"
	local apps = {}
	local tStart = 0
	local ts = {
		login = 0,
		enter = 0,
		game = 0,
		lend = 0,
		gend = 0,
	}
	local cnt = {
		login = 0,
		enter = 0,
		game = 0,
		lend = 0,
		gend = 0,
	}
	local gameReq = {
		{
			url = "/game/role/guide/newbie/award",
			params = {103},
		}, {
			url = "/game/battle/card",
			paramsFunc = function(i)
				return apps[i].app.model.role:read("battle_cards")
			end,
		}, {
			url = "/game/start_gate",
			params = {10101},
		}, {
			url = "/game/role/guide/newbie",
			params = {11},
		}, {
			url = "/game/end_gate",
			paramsFunc = function(i)
				return apps[i].app.model.battle.id, 10101, "win", 3
			end,
		}, {
			url = "/game/role/guide/newbie",
			params = {12},
		}, {
			url = "/game/lottery/card/draw",
			params = {"free1"},
		}, {
			url = "/game/role/guide/newbie",
			params = {13},
		}, {
			url = "/game/battle/card",
			paramsFunc = function(i)
				return apps[i].app.model.role:read("battle_cards")
			end,
		}, {
			url = "/game/role/guide/newbie",
			params = {14},
		}, {
			url = "/game/start_gate",
			params = {10102},
		}, {
			url = "/game/role/guide/newbie",
			params = {15},
		}, {
			url = "/game/end_gate",
			paramsFunc = function(i)
				return apps[i].app.model.battle.id, 10102, "win", 3
			end,
		}, {
			url = "/game/role/guide/newbie",
			params = {16},
		}, {
			url = "/game/card/advance",
			paramsFunc = function(i)
				local cards = apps[i].app.model.role:read("cards")
				return cards[1]
			end,
		}, {
			url = "/game/role/guide/newbie",
			params = {17},
		}, {
			url = "/game/role/gate/award",
			params = {10102, "chest"},
		}, {
			url = "/game/role/guide/newbie",
			params = {18},
		}, {
			url = "/game/start_gate",
			params = {10103},
		}, {
			url = "/game/role/guide/newbie",
			params = {19},
		}, {
			url = "/game/end_gate",
			paramsFunc = function(i)
				return apps[i].app.model.battle.id, 10103, "win", 3
			end,
		}, {
			url = "/game/role/guide/newbie",
			params = {20},
		}, {
			url = "/game/role/map/star_award",
			params = {11, 1},
		}, {
			url = "/game/role/guide/newbie",
			params = {21},
		}, {
		-- 	url = "/game/role/frag/comb",
		-- 	params = {21351},
		-- }, {
			url = "/game/role/guide/newbie",
			params = {23},
		}, {
			url = "/game/card/exp/use_items",
			paramsFunc = function(i)
				local cards = apps[i].app.model.role:read("cards")
				return cards[1], {[11] = 1}
			end,
		}, {
			url = "/game/role/guide/newbie",
			params = {24},
		}, {
			url = "/game/card/exp/use_items",
			paramsFunc = function(i)
				local cards = apps[i].app.model.role:read("cards")
				return cards[1], {[11] = 1}
			end,
		}, {
		-- 	url = "/game/card/skill/level/up",
		-- 	paramsFunc = function(i)
		-- 		local cards = apps[i].app.model.role:read("cards")
		-- 		return cards[1], 11, 1
		-- 	end,
		-- }, {
			url = "/game/role/guide/newbie",
			params = {25},
		}, {
		-- 	url = "/game/card/skill/level/up",
		-- 	paramsFunc = function(i)
		-- 		local cards = apps[i].app.model.role:read("cards")
		-- 		return cards[1], 11, 1
		-- 	end,
		-- }, {
			url = "/game/battle/card",
			paramsFunc = function(i)
				return apps[i].app.model.role:read("battle_cards")
			end,
		}, {
			url = "/game/start_gate",
			params = {10104},
		}, {
			url = "/game/role/guide/newbie",
			params = {26},
		}, {
			url = "/game/end_gate",
			paramsFunc = function(i)
				return apps[i].app.model.battle.id, 10104, "win", 3
			end,
		}, {
			url = "/game/card/advance",
			paramsFunc = function(i)
				local cards = apps[i].app.model.role:read("cards")
				return cards[1], 0
			end,
		}, {
			url = "/game/role/guide/newbie",
			params = {28},
		}, {
			url = "/game/start_gate",
			params = {10105},
		}, {
			url = "/game/role/guide/newbie",
			params = {29},
		}, {
			url = "/game/end_gate",
			paramsFunc = function(i)
				return apps[i].app.model.battle.id, 10105, "win", 3
			end,
		},
	}

	local function getStatStr(gCount)
		local t = {
			string.format("login %d/%d %.2fs", cnt.login, n, ts.login/cnt.login),
			string.format("/login/enter_server %d/%d %.2fs", cnt.enter, n, ts.enter/cnt.enter),
			string.format("/game/login %d/%d %.2fs", cnt.game, n, ts.game/cnt.game),
			string.format("doLoginEnd %d/%d %.2fs", cnt.lend, n, ts.lend/cnt.lend),
			string.format("gameEnd %d/%d %d/%d %.2fs", gCount or 0, #gameReq, cnt.gend, n, ts.gend/cnt.gend),
		}
		return table.concat(t, "\n")
	end

	self.startTest = function()
		print('inputNum', inputNum:getText())
		print('inputDelta', inputDelta:getText())
		n = tonumber(inputNum:getText())
		local prefix = "test" .. os.date("%y%m%d%H%M%S", os.time()) .. "%d"
		if n == nil then
			gGameUI:showDialog({title = "Info", content = "输入正确数量", fontSize = 60, dialogParams = {clickClose = false}})
			return false
		end
		local delta = tonumber(inputDelta:getText()) or 0

		tStart = os.time()
		for i = 1, n do
			local st
			local app = require("app.game_app"):create()
			local name = string.format(prefix, i)
			apps[i] = {
				app = app,
				name = name,
				finished = false,
			}
			gGameUI = gGameUIMain
			gGameModel = apps[1].app.model
			local doLoginEnd = app.net.doLoginEnd
			app.net.doLoginEnd = function(...)
				-- app.net.loginSession:close()
				-- app.net.gameSession:close()

				apps[i].finished = true
				ts.lend = os.time() - st + ts.lend
				cnt.lend = cnt.lend + 1

				txtStat:text(getStatStr())
				return doLoginEnd(...)
			end

			st = os.time()
			app:slientRequestServer("login", function(tb)
				ts.login = os.time() - st + ts.login
				cnt.login = cnt.login + 1
				txtStat:text(getStatStr())

				self.servers = json.decode(tb.servers)
				self.serverSelected = 2
				local server = self.servers[self.serverSelected]
				-- print("selected server", self.serverSelected, dumps(server))

				st = os.time()
				app:slientRequestServer("/login/enter_server", function(tb)
					ts.enter = os.time() - st + ts.enter
					cnt.enter = cnt.enter + 1
					txtStat:text(getStatStr())

					app:setGameServerAddr(server)

					st = os.time()
					app:slientRequestServer("/game/login", function(tb)
						gGameModel = app.model
						userDefault.setForeverLocalKey("serverKey", server.key, {rawKey = true})
						ts.game = os.time() - st + ts.game
						cnt.game = cnt.game + 1
						txtStat:text(getStatStr())

						st = os.time()
						app:slientRequestServer("/game/role/newbie/init", function(tb)
							app:slientRequestServer("/game/role/newbie/card/choose", function()
								local gCount = 0
								local function gameReqFuc()
									ts.gend = os.time() - st + ts.gend
									txtStat:text(getStatStr(gCount))
									if gCount >= #gameReq then
										cnt.gend = cnt.gend + 1
										txtStat:text(getStatStr(gCount))
										app.net.loginSession:close()
										app.net.gameSession:close()
										return
									end
									gCount = gCount + 1
									local req = gameReq[gCount]
									performWithDelay(self, function()
										st = os.time()
										if req.paramsFunc then
											app:slientRequestServer(req.url, gameReqFuc, req.paramsFunc(i))
										else
											app:slientRequestServer(req.url, gameReqFuc, unpack(req.params or {}))
										end
									end, delta)
								end
								gameReqFuc()
							end, 2, 1)
						end, 1, name, 1)
					end)
				end, server)
			end, name)
		end
		return true
	end

	self.updateTest = function(delta)
		if n == cnt.gend then
			return self:onEndTest()
		end
		for _, d in pairs(apps) do
			d.app:onUpdate(delta)
		end
	end

	self.endTest = function()
		gGameUI:showDialog({title = "Info", content = "测试完成", fontSize = 60, dialogParams = {clickClose = false}})

		local s = txtStat:text()
		s = s .. "\n-------\n"
		local delta = os.time() - tStart
		s = s .. string.format("%.2f s", delta)
		txtStat:text(s)

		apps = {}

		print(collectgarbage("count"))
		collectgarbage("collect")
		print(collectgarbage("count"))

		printAllIdlers()
	end
end

function RobotView:onOK()
	print('RobotView:onOK', self.startTest, self.stopTest)

	if self.startTest == nil and self.stopTest == nil then
		gGameUI:showDialog({title = "Warning", content = "请选择测试点", fontSize = 60, dialogParams = {clickClose = false}})
		return
	end
	if self.isRun then
		gGameUI:showDialog({title = "Warning", content = "运行中", fontSize = 60, dialogParams = {clickClose = false}})
		return
	end

	self.lstTab:setEnabled(false)
	if self.startTest then
		local ret = self.startTest()
		if ret then
			self.startTest = nil
			self.isRun = true
			if self.stopTest then
				self.btnOKText:set("取 消")
			else
				self.btnOK:setEnabled(false)
			end
		end
	end
	if self.stopTest then
		local f = self.stopTest
		self.stopTest = nil
		self.btnOKText:set("启 动")
		return f()
	end
end

function RobotView:onEndTest()
	print('RobotView:onEndTest', self.title:read())

	self.tabChoose:set(nil)
	self.btnOKText:set("启 动")
	self.btnOK:setEnabled(false)
	self.lstTab:setEnabled(true)

	if self.endTest then
		self.endTest()
	end
	self.startTest = nil
	self.updateTest = nil
	self.stopTest = nil
	self.endTest = nil
	self.isRun = false
end

return RobotView