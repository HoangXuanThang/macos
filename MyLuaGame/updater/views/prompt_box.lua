-- @desc: 通用提示框

local PromptBoxView = {}
PromptBoxView.__index = PromptBoxView

PromptBoxView.RESOURCE_FILENAME = "common_prompt_box.json"
PromptBoxView.RESOURCE_BINDING = {
	["title"] = "titleLabel",
	["content"] = "contentLabel",
	["btnOK"] = {
		varname = "btnOK",
	},
	["btnCancel"] = {
		varname = "btnCancel",
	},
	["btnOkCenter"] = {
		varname = "btnOkCenter",
	},
	["selectPanel"] = "selectPanel",
	["selectPanel.textTip"] = "textTip"
}

local function showPromptBox(params)
	local view = {}
	setmetatable(view, PromptBoxView)

	local node = ccs.GUIReader:getInstance():widgetFromJsonFile(view.RESOURCE_FILENAME)
	view.node = node
	for key, name in pairs(view.RESOURCE_BINDING) do
		if type(name) == "table" then
			if name.varname then
				view[name.varname] = nodetools.get(node, key)
			end
		else
			view[name] = nodetools.get(node, key)
		end
	end

	nodetools.get(node, "closeBtn"):onClick(function()
		view:onClose()
	end)
	view.btnCancel:onClick(function()
		view:onClose()
	end)
	view.btnOK:onClick(function()
		view:onClickOK()
	end)
	view.btnOkCenter:onClick(function()
		view:onClickOK()
	end)
	text.addEffect(nodetools.get(node, "btnOkCenter.title"), {glow = {color = ui.COLORS.GLOW.WHITE}})

	view:onCreate(params)

	return view
end

-- @param params {content, title, cb(ok callback), closeCb, strs, isRich, btnType, btnStr, align, verticalSpace}
-- btnType 按钮类型：1.确定按钮(默认), 2.确定取消按钮；
-- btnStr 确定按钮的文本变动 string for btnOk
function PromptBoxView:onCreate(params)
	params = params or {}
	local btnType = params.btnType or 1
	self._okcb = params.cb
	self._closecb = params.closeCb
	local originX, originY = self.btnOK:getPosition()
	self.titleLabel:setString(Language.tips)
	self.textTip:setString(Language.boxTextTip)
	self.btnOkCenter:getChildByName("title"):setString(Language.sure)
	self.selectPanel:setVisible(false)

	if params.title then
		self.titleLabel:setString(params.title)
	end
	local size = self.contentLabel:getContentSize()
	if btnType == 1 then
		self.btnOK:setVisible(false)
		self.btnCancel:setVisible(false)
		self.btnOkCenter:setVisible(true)
		size.height = size.height - 70
		self.contentLabel:setContentSize(size)
	else
		self.btnOK:setVisible(true)
		self.btnCancel:setVisible(true)
		self.btnOkCenter:setVisible(false)
	end

	-- 统一用 beauty.textScroll 处理
	-- self.contentLabel:text(params.content)
	local defaultAlign = "center"
	local list, height = beauty.textScroll({
		size = size,
		fontSize = params.fontSize or 50,
		effect = {color=ui.COLORS.NORMAL.DEFAULT},
		strs = params.content or params.strs,
		verticalSpace = params.verticalSpace or 10,
		isRich = params.isRich,
		margin = 20,
		align = params.align or defaultAlign,
	})
	local y = 0
	if height < size.height then
		y = -(size.height - height) / 2
	end
	list:setPositionY(y)
	self.contentLabel:addChild(list, 10)
end

function PromptBoxView:onClickOK()
	if self._okcb then
		self._okcb()
	end
	self.node:removeFromParent()
	return self
end

function PromptBoxView:onClose()
	if self._closecb then
		self._closecb()
	end
	self.node:removeFromParent()
	return self
end

return showPromptBox