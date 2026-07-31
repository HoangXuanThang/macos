-- @date: 2019-07-03 17:15:34
-- @desc:设置常规界面

local SettingMainView = require("app.views.city.setting.view")
local BTN_TYPE = SettingMainView.BTN_TYPE
local BTN_DATA = SettingMainView.BTN_DATA

local STATE = {
	OPEN = 1,
	CLOSE = 2,
}

local pageListData = {
	-- [1] = { -- 帧率控制
	-- 	name = gLanguageCsv.settingFPS,
	-- 	select1 = gLanguageCsv.settingFPSSelect1,
	-- 	select2 = gLanguageCsv.settingFPSSelect2,
	-- 	btnType = BTN_TYPE.RADIO,
	-- 	initFunc = function()
	-- 		local fps = userDefault.getForeverLocalKey("fps", 60, { rawKey = true })
	-- 		local state = fps <= 30 and STATE.OPEN or STATE.CLOSE
	-- 		return state
	-- 	end,
	-- 	func = function(state) -- state : true对应select1 false对应select2
	-- 		local fps = state and 30.0 or 60.0
	-- 		cc.Director:getInstance():setAnimationInterval(1.0 / fps)
	-- 		userDefault.setForeverLocalKey("fps", fps, { rawKey = true })
	-- 	end
	-- },
	[1] = {
		name = gLanguageCsv.settingFPS,
		select1 = "30 FPS",
		select2 = "60 FPS",
		select3 = "120 FPS", -- <== เพิ่ม
		btnType = BTN_TYPE.RADIO,
		initFunc = function ()
			local fps = userDefault.getForeverLocalKey("fps", 60, {rawKey = true})
			print(">>> current fps in setting:", fps)

			if math.abs(fps - 30) < 1 then
				return 1
			elseif math.abs(fps - 60) < 1 then
				return 2
			elseif math.abs(fps - 120) < 1 then
				return 3
			else
				return 2
			end
		end,
		func = function (index)
			local fpsList = {30.0, 60.0, 120.0}
			local fps = fpsList[index] or 60.0
			print(">>> set fps to:", index, fps)
			cc.Director:getInstance():setAnimationInterval(1.0 / fps)
			userDefault.setForeverLocalKey("fps", fps, {rawKey = true})
		end
	},
}

local function setNodeItem(parent, children, data)
	children.text:text(data.name)
	children.btnPanel1:get("text"):text(data.select1)
	children.btnPanel2:get("text"):text(data.select2)
	children.btnPanel3:get("text"):text(data.select3)

	local setBtnSwitch = function (panel,btnNumber)
		local dt = BTN_DATA[data.btnType]
		local btn = panel:get("btn")
		local img = btn:get("btnImg")
		btn:texture(dt.resNormal)
		img:texture(dt.resBtnImg)

		img:xy(30,30)		-- 固定位置

		local btnState = idler.new()
		-- btn:get("btnImg"):y(btn:get("btnImg"):y() + 1)

		btnState:addListener(function(val, oldval)
			local state = val == STATE.OPEN
			btn:texture(state and dt.resSelected or dt.resNormal)

			if state then
				img:xy(100,30)		-- 固定位置
			else
				img:xy(30,30)		-- 固定位置
			end
			data.func(state,btnNumber)
		end,true)

		--如回需调则用回调的方式
		if data.needCallBack(btnNumber) then
			data.initFunc(btnNumber,function (state)
				btnState:set(state)
			end)
		else
			local state = data.initFunc()
			btnState:set(state)
		end

		bind.click(parent, panel, {method = function()
			local ty = btnState:read() == STATE.OPEN and STATE.CLOSE or STATE.OPEN
			btnState:set(ty)
		end})
	end

	local setBtnRadio3 = function(panels)
		local dt = BTN_DATA[data.btnType]
		local btns = {}
		for i = 1, 3 do
			local btn = panels[i]:get("btn")
			btn:texture(dt.resNormal)
			btn:get("btnImg"):texture(dt.resBtnImg)
			btn:get("btnImg"):visible(false)
			btns[i] = btn
		end

		local btnState = idler.new()

		btnState:addListener(function(val)
			for i = 1, 3 do
				btns[i]:get("btnImg"):visible(i == val)
			end
			data.func(val)
		end, true)

		btnState:set(data.initFunc())

		for i = 1, 3 do
			bind.click(parent, panels[i], {
				method = function()
					btnState:set(i)
				end
			})
		end
	end

	if data.btnType == BTN_TYPE.RADIO then
		--rves
		--setBtnRadio(children.btnPanel1,children.btnPanel2)
		setBtnRadio3({children.btnPanel1, children.btnPanel2, children.btnPanel3}) -- ใช้ 3 ปุ่ม
	else
		setBtnSwitch(children.btnPanel1,1)
		setBtnSwitch(children.btnPanel2,2)
	end

end

local SettingNormalView = class("SettingNormalView", cc.load("mvc").ViewBase)
SettingNormalView.RESOURCE_FILENAME = "setting_normal.json"
SettingNormalView.RESOURCE_BINDING = {
	["centerPanel.item"] = "listItem",
	["centerPanel.btnList"] = {
		varname = "btnList",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("listData"),
				item = bindHelper.self("listItem"),
				margin = bindHelper.self("margin"),
				padding = 0,
				onItem = function(list, node, k, v)
					local children = node:multiget("text", "btnPanel1", "btnPanel2", "btnPanel3")
					setNodeItem(list, children, v)
				end,
				onAfterBuild = function(list)
					if itertools.size(list.data) < 3 then
						list:setItemAlignCenter()
					end
				end,
			},
		},
	},

	["centerPanel.bottomPanel.btnLogOut"] = {
		varname = "btnLogOut",
		binds = {
			event = "touch",
			methods = { ended = bindHelper.self("onLogOut") },
		},
	},
	["centerPanel.bottomPanel.btnFeedback"] = {
		varname = "btnFeedback",
		binds = {
			{
				event = "visible",
				idler = bindHelper.self("showFeedback"),
			},
			{
				event = "touch",
				methods = { ended = bindHelper.self("onFeedback") },
			}
		}
	},
	["centerPanel.bottomPanel.btnRedeemCode"] = {
		varname = "btnRedeemCode",
		binds = {
			event = "touch",
			methods = { ended = bindHelper.self("onRedeemCode") },
		},
	},
	["centerPanel.bottomPanel.btnNotice"] = {
		varname = "btnNotice",
		binds = {
			event = "touch",
			methods = { ended = bindHelper.self("onNotice") },
		},
	},

	["centerPanel.bottomPanel.btnFeedback.text"] = {
		binds = {
			{
				event = "effect",
				data = { outline = { color = ui.NEWCOLORS.OUTLINE.YELLOW, size = 4 } }
			},
		},
	},

	["centerPanel.bottomPanel.btnLogOut.text"] = {
		binds = {
			{
				event = "effect",
				data = { outline = { color = ui.NEWCOLORS.OUTLINE.YELLOW, size = 4 } }
			},
		},
	},
	["centerPanel.bottomPanel.btnRedeemCode.text"] = {
		binds = {
			{
				event = "effect",
				data = { outline = { color = ui.NEWCOLORS.OUTLINE.YELLOW, size = 4 } }
			},
		},
	},

	["centerPanel.bottomPanel.btnNotice.text"] = {
		binds = {
			{
				event = "effect",
				data = { outline = { color = ui.NEWCOLORS.OUTLINE.YELLOW, size = 4 } }
			},
		},
	},

	["versionPanel.text"] = "versionText",
	["versionPanel.version"] = {
		varname = "version",
		binds = {
			{
				event = "text",
				data = APP_VERSION .. "." .. PATCH_VERSION,
			},
		},
	},
	["serverTimePanel.text"] = "serverTimeText",
	["serverTimePanel.time"] = {
		varname = "serverTime",
		binds = {
			{
				event = "text",
				idler = bindHelper.self("serverTimeValue"),
			},
		},
	},
}

function SettingNormalView:onCreate()
	self.showFeedback = idler.new(gGameModel.role:getIdler("vip_level"):read() >= 10)
	self.listData = clone(pageListData)
	local margin = { 0, 70, 30, 8 }
	self.margin = margin[itertools.size(self.listData)]

	-- self:getResourceNode():getChildByName("centerPanel"):getChildByName("bottomPanel"):getChildByName("btnRedeemCode"):hide()
	-- self:getResourceNode():getChildByName("centerPanel"):getChildByName("bottomPanel"):getChildByName("btnNotice"):hide()

	adapt.oneLinePos(self.version, self.versionText, cc.p(10, 0), "right")

	self.serverTimeValue = idler.new()
	self:enableSchedule():schedule(function()
		local date = time.getNowDate()
		self.serverTimeValue:set(string.format("%02d:%02d:%02d", date.hour, date.min, date.sec))
		adapt.oneLinePos(self.serverTime, self.serverTimeText, cc.p(10, 0), "right")
	end, 1, 0, 1)
end

-- 退出登录
function SettingNormalView:onLogOut()
	sdk.logout(function(info)
		print("sdk logout callback", info)
	end)
	sdk.commitRoleInfo(5, function()
		print("sdk commitRoleInfo logout")
	end)
	gGameApp:onBackLogin()
end

-- 问题反馈
function SettingNormalView:onFeedback()
	local count = userDefault.getCurrDayKey("feedBackDayCount", 0)
	if count >= gCommonConfigCsv.feedBackDayCount then
		gGameUI:showTip(gLanguageCsv.feedBackTooMany)
	else
		gGameUI:stackUI("city.setting.feed_back")
	end
end

-- 公告
function SettingNormalView:onNotice()
	gGameApp:getNotice(function(ret)
		gGameUI:stackUI("login.placard", nil, nil, ret.notice)
	end)
end

-- 兑换码
function SettingNormalView:onRedeemCode()
	gGameUI:stackUI("city.setting.redeem_code")
end

return SettingNormalView
