-- @Date:   2019-05-30
-- @Desc:

local GET_TYPE = {
	GOTTEN = 0, 	--已领取
	CAN_GOTTEN = 1, --可领取
	CAN_NOT_GOTTEN = 2, --未完成
}

local ActivityDrawDayGift = class("ActivityDrawDayGift", cc.load("mvc").ViewBase)

ActivityDrawDayGift.RESOURCE_FILENAME = "activity_draw_day_gift.json"
ActivityDrawDayGift.RESOURCE_BINDING = {
	["item"] = "item",
	["sublist"] = "sublist",
	["list"] = {
		binds = {
			event = "extend",
			class = "tableview",
			props = {
				data = bindHelper.self("itemsData"),
				item = bindHelper.self("sublist"),
				cell = bindHelper.self("item"),
				columnSize = 4,
				onCell = function(list, node, k, v)
					local t = list:getIdx(k)
					local childs = node:multiget("textDay", "list", "check", "mask")
					-- 天数
					childs.textDay:setString(string.format(gLanguageCsv.currDay, v.day))
					--奖励
					local awards = v.award
					local param = {}
					
					uiEasy.createItemsToList(list, childs.list, awards,param)

					
					-- text.addEffect(childs.textDay, {outline = {color = ui.NEWCOLORS.OUTLINE.WHITE2, size = 4}})

					-- --按钮限时处理
					childs.check:hide()
					childs.mask:hide()
					if v.getType == GET_TYPE.CAN_NOT_GOTTEN then
						-- childs.mask:show()
					-- 	-- 未达成
					-- 	adapt.setTextScaleWithWidth(childs.btnGet:get("textGet"), gLanguageCsv.haveNotLogin, 250)
					-- 	childs.btnGet:setEnabled(false)
						
					elseif v.getType == GET_TYPE.CAN_GOTTEN then
						childs.check:show()
					-- 	-- 可领取
					-- 	adapt.setTextScaleWithWidth(childs.btnGet:get("textGet"), gLanguageCsv.spaceReceive, 250)
					-- 	--childs.btnGet:get("textGet"):setTextColor(cc.c4b(102, 36, 47, 255))
					-- 	childs.btnGet:setEnabled(true)
						
					elseif v.getType == GET_TYPE.GOTTEN then
						childs.mask:show()
					-- 	--已领取
					-- 	childs.btnGet:get("textGet"):setString(gLanguageCsv.received)
						
					-- 	childs.btnGet:setEnabled(false)
					end

					-- bind.touch(self, childs.btnGet, {methods = {ended = functools.partial(self.sendGetAward, self, itemData.id)}})
				end,
			},
			handlers = {
				clickItem = bindHelper.self("onBuyClick"),
			},
		},
	},
	["btnGet"] = {
		varname = "btnGet",
		binds = {
			event = "touch",
			methods = { ended = bindHelper.self("sendGetAward") }
		},
	},
	["btnGet.txt"] = {
		varname = "btnGetTxt",
		binds = {
			{
				event = "effect",
				data = {outline = {color = ui.NEWCOLORS.OUTLINE.YELLOW, size = 4}}
			},
		}
	},
}

function ActivityDrawDayGift:onCreate(activityID)
	self.activityId = activityID

	self:initModel()

	-- 每日奖励数据
	local loginwealData = {}
	local yyCfg = csv.yunying.yyhuodong[self.activityId]
	local huodongID = yyCfg.huodongID
	for k, v in csvPairs(csv.yunying.loginweal) do
		if v.huodongID == huodongID then
			loginwealData[v.daySum] = {award = v.award, id = k}
		end
	end
	idlereasy.when(self.yyhuodongs,function(_, yyhuodong)
		local yydata = yyhuodong[self.activityId]
		local itemsData = {}
		self.curSigninID = 0
		local getType = GET_TYPE.CAN_NOT_GOTTEN
		for daySum, wealData in pairs(loginwealData) do
			
			if yydata.stamps[wealData.id] == nil then
				getType = GET_TYPE.CAN_NOT_GOTTEN
			else
				getType = yydata.stamps[wealData.id]
			end

			itemsData[daySum] = {day = daySum, award = wealData.award, id = wealData.id, getType = getType}

			if self.curSigninID == 0 and getType == 1 then
				self.curSigninID = wealData.id
			end
		end
		
		self.itemsData:set(itemsData)

		local state = self.curSigninID > 0
		cache.setShader(self.btnGet, false, state and "normal" or "hsl_gray")
		if not state then
			text.deleteAllEffect(self.btnGetTxt)
			text.addEffect(self.btnGetTxt, {color = ui.NEWCOLORS.DISABLED.WHITE})
		else
			text.addEffect(self.btnGetTxt, {color = ui.NEWCOLORS.WHITE})
		end
	end)
end

function ActivityDrawDayGift:initModel()
	self.yyhuodongs = gGameModel.role:getIdler("yyhuodongs")

	self.itemsData = idlertable.new({}) -- 存放 奖励和领取状态
end

function ActivityDrawDayGift:sendGetAward()
	gGameApp:requestServer("/game/yy/award/get/onekey", function(tb)
		gGameUI:showGainDisplay(tb)
	end, self.activityId)
end

return ActivityDrawDayGift
