-- 界面显示测试

local originQueueRequest = gGameApp._queueRequest
local main

local LANGUAGES = {"cn", "tw", "en", "kr"}

package.loaded["tests.test_view_data"] = nil
local TEST_VIEW_DATA = require("tests.test_view_data")
local TEST_VIEW_DATA_KEY_HASH = itertools.map(TEST_VIEW_DATA, function(k, v)
	return v.key, k
end)
local TEST_VIEW_DATA_NAME_HASH = itertools.map(TEST_VIEW_DATA, function(k, v)
	return v.name, k
end)

local function setPanelInput(self)
	-- 可以输入工程名或文件路径打开对应界面
	local input1, input2, menu1
	local x = self.testViewData.pos.x
	local y = self.testViewData.pos.y
	local panel = self.testViewData.panel

	-- 选择语言
	label.create("当前语言: ", {fontSize = 45, color = ui.COLORS.NORMAL.DEFAULT})
		:anchorPoint(0, 0.5)
		:xy(x, y)
		:addTo(panel)

	local node = ccui.Layout:create()
		:addTo(panel, 2)

	local showSelected
	for i, v in ipairs(LANGUAGES) do
		if LOCAL_LANGUAGE == v then
			showSelected = i
			break
		end
	end
	bind.extend(self, node, {
		class = "sort_menus",
		props = {
			data = idlertable.new(LANGUAGES),
			showSelected = showSelected,
			width = 300,
			height = 80,
			btnWidth = 300,
			maxCount = 6.5,
			btnClick = function(node, k, v, oldval)
				LOCAL_LANGUAGE = v.name
				gGameApp._queueRequest = originQueueRequest

				-- 字体ttf 需要清理界面引用
				gGameUI.scene:removeAllChildren()
				display.director:purgeCachedData()
				display.director:purgeFontFreeType()

				-- 更换对应语言优先路径
				cc.FileUtils:getInstance():setSearchResolutionsOrder({})
				gGameApp.initSearchPath()

				-- 重新加载对应语言配表
				local editor = gGameUI.scene.clientEditor
				if editor then
					local originAddTipLabel = editor.addTipLabel
					editor.addTipLabel = function(...)
						print("editor reload ok")
					end
					os.remove(string.format("LastModifyList_%s.txt", LOCAL_LANGUAGE))
					editor:onReloadCsv()
					editor.addTipLabel = originAddTipLabel
				end

				package.loaded["easy.ui_l10n"] = nil
				require("easy.ui_l10n")
				package.loaded["easy.ui_adapter"] = nil
				require("easy.ui_adapter")

				require("app.game_app"):create():run("login.view")
				main()
			end,
			onNode = function(node)
				node:xy(x + 400 - 1280 , y - 540)
			end,
		}
	})

	y = y -100
	label.create("注:可以选择工程名(.json)或文件路径打开对应界面", {fontSize = 45, color = ui.COLORS.NORMAL.DEFAULT})
		:anchorPoint(0, 0.5)
		:xy(x, y)
		:addTo(panel)

	y = y - 100
	local str = label.create("工程名:", {fontSize = 45, color = ui.COLORS.NORMAL.DEFAULT})
		:anchorPoint(0, 0.5)
		:xy(x, y)
		:addTo(panel)
	local width = str:width() + 60
	input1 = ccui.EditBox:create(cc.size(1000 - width, 60), "img/editor/input.png")
		:anchorPoint(0, 0.5)
		:xy(x + width, y)
		:setColor(cc.c4b(200, 200, 200, 255))
		:addTo(panel)
	input1:setFontSize(45)
	input1:setFontColor(ui.COLORS.NORMAL.DEFAULT)
	input1:setTextHorizontalAlignment(cc.TEXT_ALIGNMENT_CENTER)
	input1:registerScriptEditBoxHandler(function(name)
		if name == "return" then
			local key = input1:getText()
			if not string.find(key, "%.json$") then
				key = key .. ".json"
			end
			local idx = TEST_VIEW_DATA_KEY_HASH[key]
			if not idx then
				gGameUI:showTip("(%s)未定义", key)
			else
				input1:setText(key)
				input2:setText(TEST_VIEW_DATA[idx].name)
			end
		end
	end)
	input1:hide()

	local node = ccui.Layout:create()
		:addTo(panel, 1)

	local data = itertools.map(TEST_VIEW_DATA, function(k, v)
		return v.key
	end)
	local menu1Selected = idler.new(1)
	local menu1Node
	bind.extend(self, node, {
		class = "sort_menus",
		props = {
			data = idlertable.new(data),
			showSelected = menu1Selected,
			width = 1000 - width,
			height = 80,
			btnWidth = 1000 - width,
			maxCount = 6.5,
			btnClick = function(node, k, v, oldval)
				local key = v.name
				local idx = TEST_VIEW_DATA_KEY_HASH[key]
				input1:setText(key)
				input2:setText(TEST_VIEW_DATA[idx].name)
				menu1Node.btn1:setColor(cc.c4b(255, 255, 255, 255))
			end,
			onNode = function(node)
				menu1Node = node
				node:xy(x + width + (1000 - width)/2 - 1280 , y - 540)
			end,
		}
	})

	y = y - 100
	local str = label.create("文件路径:", {fontSize = 45, color = ui.COLORS.NORMAL.DEFAULT})
		:anchorPoint(0, 0.5)
		:xy(x, y)
		:addTo(panel)
	local width = str:width() + 20
	input2 = ccui.EditBox:create(cc.size(1000 - width, 60), "img/editor/input.png")
		:anchorPoint(0, 0.5)
		:xy(x + width, y)
		:setColor(cc.c4b(200, 200, 200, 255))
		:addTo(panel)
	input2:setFontSize(45)
	input2:setFontColor(ui.COLORS.NORMAL.DEFAULT)
	input2:setTextHorizontalAlignment(cc.TEXT_ALIGNMENT_CENTER)
	input2:registerScriptEditBoxHandler(function(name)
		if name == "return" then
			local path = input2:getText()
			local idx = TEST_VIEW_DATA_NAME_HASH[path]
			if idx then
				input1:setText(TEST_VIEW_DATA[idx].key)
				menu1Selected:set(idx)
				if menu1Node then
					menu1Node.btn1:setColor(cc.c4b(255, 255, 255, 255))
				end
			else
				input1:setText("")
				if menu1Node then
					menu1Node.btn1:setColor(cc.c4b(100, 100, 100, 255))
				end
			end
		end
	end)

	local idx = 1
	local data = TEST_VIEW_DATA[idx]
	input1:setText(data.key)
	input2:setText(data.name)
	y = y - 100
	local btn = ccui.Button:create("common/btn/btn_normal_red.png")
		:setTitleText("上一个")
		:setTitleFontSize(72)
		:xy(display.sizeInView.width/2 - 300, y)
		:addTo(panel)
		:scale(0.5)
	bind.touch(self, btn, {methods = {ended = function()
		idx = idx - 1
		if idx < 1 then idx = #TEST_VIEW_DATA end
		local data = TEST_VIEW_DATA[idx]
		input1:setText(data.key)
		input2:setText(data.name)
		menu1Selected:set(idx)
		menu1Node.btn1:setColor(cc.c4b(255, 255, 255, 255))
	end}})

	local btn = ccui.Button:create("common/btn/btn_normal_red.png")
		:setTitleText("下一个")
		:setTitleFontSize(72)
		:xy(display.sizeInView.width/2 + 300, y)
		:addTo(panel)
		:scale(0.5)
	bind.touch(self, btn, {methods = {ended = function()
		idx = idx + 1
		if idx > #TEST_VIEW_DATA then idx = 1 end
		local data = TEST_VIEW_DATA[idx]
		input1:setText(data.key)
		input2:setText(data.name)
		menu1Selected:set(idx)
		menu1Node.btn1:setColor(cc.c4b(255, 255, 255, 255))
	end}})

	self.testViewData.pos.x = x
	self.testViewData.pos.y = y
	self.testViewData.input1 = input1
	self.testViewData.input2 = input2
end

local function setShowBtn(self)
	local x = display.sizeInView.width/2
	local y = self.testViewData.pos.y - 150
	local panel = self.testViewData.panel
	local input1 = self.testViewData.input1
	local input2 = self.testViewData.input2

	local btnShow = ccui.Button:create("common/btn/btn_normal.png")
		:setTitleText("显示界面")
		:setTitleFontName("font/youmi1.ttf")
		:anchorPoint(0.5, 0.5)
		:setTitleFontSize(45)
		:xy(x, y)
		:addTo(panel)
	bind.touch(self, btnShow, {methods = {ended = function()
		local editor = gGameUI.scene.clientEditor
		if editor then
			editor:onReloadLua()
		end
		xpcall(function()
			local name = input2:getText()
			if name == "" then
				gGameUI:showTip("请输入")
			else
				local styles = {clickClose = false}
				local params
				local key = input1:getText()
				local idx = TEST_VIEW_DATA_KEY_HASH[key]
				if idx then
					styles = TEST_VIEW_DATA[idx].styles
					params = TEST_VIEW_DATA[idx].params
				end
				printInfo("showTestView: %s", name)
				package.loaded["app.views." .. name] = nil
				self.testViewData.view = gGameUI:stackUI(name, nil, styles, unpack(params or {})):z(999)
				self.testViewData.btnViewClose:show()
			end
		end,
		function(err)
			printError("showTestView: ", err)
		end)
	end}})
end


main = function ()
	package.loaded["tests.test_view_model"] = nil
	require "tests.test_view_model"
	gGameApp._queueRequest = function(_, t)
		print("url:", t._url)
		gGameUI:showTip("test_view not login no request %s", t._url)
	end

	local self = gGameUI.uiRoot -- LOGIN_VIEW
	local panel = ccui.Layout:create()
		:size(display.sizeInView)
		:alignCenter(display.sizeInView)
		:addTo(self, 5, "_TestView_")
		:x(display.sizeInView.width/2 - display.uiOrigin.x)
	panel:setTouchEnabled(true)

	ccui.ImageView:create("common/bg/bg_tzjc.png")
		:alignCenter(display.sizeInView)
		:scale(2)
		:addTo(panel, -1, "bg")

	-- view界面关闭返回
	local btnViewClose = ccui.Button:create("common/btn/btn_normal.png")
		:setTitleText("返回")
		:setTitleFontSize(60)
		:xy(display.uiOrigin.x - display.uiOriginMax.x + 100, display.height - 100)
		:scale(0.8)
		:opacity(150)
		:hide()
		:addTo(self, 1000)
	btnViewClose:setTouchEnabled(true)
	bind.touch(self, btnViewClose, {methods = {ended = function()
		local view = self.testViewData.view
		if view and not tolua.isnull(view) then
			view:removeSelf()
			self.testViewData.view = nil
		end
		btnViewClose:hide()
	end}})

	-- 测试主面板关闭返回
	local btnClose = ccui.ImageView:create("common/btn/btn_back.png")
		:xy(display.uiOrigin.x - display.uiOriginMax.x + 150, display.height - 150)
		:addTo(panel, 10)
	btnClose:setTouchEnabled(true)
	bind.touch(self, btnClose, {methods = {ended = function()
		panel:removeSelf()
		btnViewClose:removeSelf()
		gGameApp._queueRequest = originQueueRequest
	end}})

	self.testViewData = {
		panel = panel,
		pos = cc.p(display.sizeInView.width/2 - 500, 1100),
		btnViewClose = btnViewClose,
	}
	setPanelInput(self)
	setShowBtn(self)
end

return main