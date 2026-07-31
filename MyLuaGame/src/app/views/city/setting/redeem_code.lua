-- @date: 2019-07-03 17:15:34
-- @desc:设置界面兑换码弹窗

local SettingRedeemCodeView = class("SettingRedeemCodeView", Dialog)
SettingRedeemCodeView.RESOURCE_FILENAME = "setting_redeem_code.json"
SettingRedeemCodeView.RESOURCE_BINDING = {
	["textBg"] = "textBg",
	["textField"] = "textField",
	["title"] = {
		binds = {
			{
				event = "effect",
				data = { outline = { color = ui.NEWCOLORS.OUTLINE.BLUE1, size = 4 } }
			},
		},
	},
	["btnClose"] = {
		binds = {
			event = "touch",
			methods = { ended = bindHelper.self("onClose") },
		},
	},
	["btnCancel"] = {
		binds = {
			event = "touch",
			methods = { ended = bindHelper.self("onClose") },
		},
	},
	["btnComfirm"] = {
		binds = {
			event = "touch",
			methods = { ended = bindHelper.self("onConfirmBtn") },
		},
	},
	["btnPaste"] = {
		varname = "btnPaste",
		binds = {
			event = "touch",
			methods = { ended = bindHelper.self("onPasteBtn") },
		},
	},
	["btnPaste.txt"] = {
		binds = {
			{
				event = "effect",
				--data = {glow={color=ui.COLORS.GLOW.WHITE}}
				data = {outline = {color = ui.NEWCOLORS.OUTLINE.YELLOW, size = 4}}
			},
		}
	},
}

-- ascii 是数字
local function isNumber(num)
	return num >= 48 and num <= 57
end
-- ascii 是大写字母
local function isUpper(num)
	return num >= 65 and num <= 90
end
-- ascii 是小写字母
local function isLower(num)
	return num >= 97 and num <= 122
end

-- 限定字符在指定范围内
local function limitLanguageWord(str)
	local flag = false -- 标记是否有字符超出限定范围
	local idx = 1
	while idx <= #str do
		local curByte = string.byte(str, idx)
		local num = string.utf8charlen(curByte)
		local character = ""
		for i = 1, num do
			character = character .. string.format("%x", string.byte(str, idx + i - 1, idx + i - 1))
		end
		local number = tonumber(character, 16)
		local valid = isNumber(number) or isUpper(number) or isLower(number) -- 是否有效区内的字符
		if not valid then
			return true, { idx }
		end
		idx = idx + num
	end
	return false
end

local function removeOtherFromString(str)
	local repStr = ""
	local flag, t = limitLanguageWord(str)
	if flag then
		table.sort(t, function(a, b)
			return a > b
		end)
		for _, v in ipairs(t) do
			local len = string.utf8charlen(string.byte(str, v))
			str = string.sub(str, 1, v - 1) .. repStr .. string.sub(str, v + len)
		end
	end
	return str
end

function SettingRedeemCodeView:onCreate()
	-- self.textField:addEventListener(function(sender, eventType)
	-- 	if eventType == ccui.TextFiledEventType.insert_text then
	-- 		self.textField:setText(removeOtherFromString(self.textField:text()))
	-- 	end
	-- end)
	self.textField:setPlaceHolderColor(ui.NEWCOLORS.GRAY3)
	self.textField:setTextColor(ui.NEWCOLORS.BROWN1)
	self.textField:setTextHorizontalAlignment(cc.TEXT_ALIGNMENT_CENTER)

	-- 功能按钮
	itertools.invoke({ self.btnPaste }, "hide")
	if string.find(APP_FEATURE, "paste") then
		self.btnPaste:show()
		self.textBg:x(self.textBg:x() - 100)
		self.textField:x(self.textBg:x() - 100)
	end

	Dialog.onCreate(self, { clickClose = false })
end

function SettingRedeemCodeView:onConfirmBtn()
	local str = self.textField:getStringValue()
	gGameApp:requestServer("/game/gift", function(tb)
		gGameUI:showGainDisplay(tb.view.award)
	end, str)
end

function SettingRedeemCodeView:onPasteBtn()
	sdk.getPasteStr(function(str)
		self.textField:setText(tostring(str))
	end)
end

return SettingRedeemCodeView
