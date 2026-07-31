-- @date: 2019-07-03 17:15:34
-- @desc:设置主界面

local SettingView = class("SettingView", Dialog)

local BTN_TYPE = {
	RADIO = 1,
	BTN = 2,
}

local BTN_DATA = {
	[BTN_TYPE.RADIO] = {
		resNormal = "common/icon/radio_normal.png",
		resSelected = "common/icon/radio_normal.png",
		resBtnImg = "common/icon/radio_selected.png",
	},
	[BTN_TYPE.BTN] = {
		resNormal = "city/setting/btn_off.png",
		resSelected = "city/setting/btn_on.png",
		resBtnImg = "common/btn/btn_inner_close.png",
	},
}

SettingView.BTN_TYPE = BTN_TYPE
SettingView.BTN_DATA = BTN_DATA

SettingView.RESOURCE_FILENAME = "setting.json"
SettingView.RESOURCE_BINDING = {
	["btnClose"] = {
		varname = "btnClose",
		binds = {
			event = "touch",
			methods = { ended = bindHelper.self("onClose") }
		},
	},
	["normalBtn"] = {
		varname = "normalBtn",
		binds = {
			event = "touch",
			methods = { ended = bindHelper.self("onBtnClick") }
		},
	},
	["voiceBtn"] = {
		varname = "voiceBtn",
		binds = {
			event = "touch",
			methods = { ended = bindHelper.self("onBtnClick") }
		},
	},
}

function SettingView:onCreate()
	self.btns = {
		[self.normalBtn] = {
			name = "city.setting.normal",
		},
		[self.voiceBtn] = {
			name = "city.setting.voice",
		},
	}

	self.curBtn = idler.new()
	self.curBtn:addListener(function(val, oldval)
		for btn, tb in pairs(self.btns) do
			-- 设置按钮状态
			local state = btn == val
			local color = state and ui.NEWCOLORS.ORANGE or ui.NEWCOLORS.WHITE
			local anchorPointX = state and 0.5 or 0.5
			local fontSize = state and 45 or 45

			btn:get("select"):visible(state)
			btn:get("text"):anchorPoint(anchorPointX, 0.5):setFontSize(fontSize)
			if (state) then
				text.addEffect(
					btn:get("text"),
					{ color = color, outline = { color = ui.NEWCOLORS.OUTLINE.WHITE, size = 2 } }
				)
			else
				text.deleteAllEffect(btn:get("text"))
				text.addEffect(btn:get("text"), { color = color })
			end
			local maxHeight = btn:size().height - 20
			adapt.setAutoText(btn:get("text"), nil, maxHeight)
			-- 界面显示相关
			if not tb.view then
				tb.view = gGameUI:createView(tb.name, self:getResourceNode())
					:init()
					:x(display.uiOrigin.x)
			end
			tb.view:visible(state)
		end
	end)
	self.curBtn:set(self.normalBtn)

	Dialog.onCreate(self)
end

function SettingView:onBtnClick(node, t)
	self.curBtn:set(t.target)
end

return SettingView
