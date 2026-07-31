-- @Date:   2019-05-30
-- @Desc:

local GET_TYPE = {
	GOTTEN = 0, 	--已领取
	CAN_GOTTEN = 1, --可领取
	CAN_NOT_GOTTEN = 2, --未完成
}
local ActivityView = require "app.views.city.activity.view"

local ActivityDayFound2Gift = class("ActivityDayFound2Gift", cc.load("mvc").ViewBase)

ActivityDayFound2Gift.RESOURCE_FILENAME = "activity_day_found2.json"
ActivityDayFound2Gift.RESOURCE_BINDING = {
	["item"] = "item",
	["sublist"] = "sublist",
	["panel.list"] = {
		binds = {
			event = "extend",
			class = "tableview",
			props = {
				data = bindHelper.self("itemsData"),
				item = bindHelper.self("sublist"),
				cell = bindHelper.self("item"),
				columnSize = 6,
				onCell = function(list, node, k, v)
					local t = list:getIdx(k)
					local childs = node:multiget("textDay", "icon", "check", "mask", "bg")
					if k == 3 or k == 6 then
						childs.bg:texture("activity/day_found/hhjj_2_floor3.png")
					end
					-- 天数
					childs.textDay:setString(string.format(gLanguageCsv.currDay, v.day))
					text.addEffect(childs.textDay, {outline={color=ui.NEWCOLORS.OUTLINE.BLACK}})
					--奖励
					
					local itemID, num = next(v.award)
					
					bind.extend(list, childs.icon, {
						class = "icon_key",
						props = {
							data = {key = itemID, num = num},
							onNode = function(panel)
								panel:scale(0.7)
							end,
						},

					})
					
					-- uiEasy.createItemsToList(list, childs.list, awards,param)

					
					-- text.addEffect(childs.textDay, {outline = {color = ui.NEWCOLORS.OUTLINE.WHITE2, size = 4}})

					-- --按钮限时处理
					childs.mask:hide()
					if v.getType == GET_TYPE.CAN_NOT_GOTTEN then
					-- 	-- 未达成
					-- 	adapt.setTextScaleWithWidth(childs.btnGet:get("textGet"), gLanguageCsv.haveNotLogin, 250)
					-- 	childs.btnGet:setEnabled(false)
						
					elseif v.getType == GET_TYPE.CAN_GOTTEN then
						local signSpine = widget.addAnimationByKey(childs.icon, "effect/wupinguang.skel", 'signSpine', "effect_loop", 99)
							:anchorPoint(cc.p(0.5,0.5))
							:xy(childs.icon:width()/2, childs.icon:height()/2)
							:scale(1.5)
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
	["item1"] = "item1",
	["panel.awardPanel.all.title"] = {
		binds = {
			event = "effect",
			data = { outline = { color = ui.NEWCOLORS.OUTLINE.BLACK, size = 2 } }
		}
	},
	["panel.awardPanel.all.list"] = {
		varname = "list",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("itemDatas1"),
				item = bindHelper.self("item1"),
				onItem = function(list, node, k, v)
					bind.extend(list, node, {
						class = "icon_key",
						props = {
							data = {
								key = v.key,
								num = v.num,
							},
							onNode = function(panel)
								panel:scale(0.7)
							end,
						},
					})
				end,
			},
		},
	},
	["panel.awardPanel.award.title"] = {
		binds = {
			event = "effect",
			data = { outline = { color = ui.NEWCOLORS.OUTLINE.BLACK, size = 2 } }
		}
	},
	["panel.awardPanel.award.list"] = {
		varname = "list",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("itemDatas2"),
				item = bindHelper.self("item1"),
				margin = 20,
				onItem = function(list, node, k, v)
					bind.extend(list, node, {
						class = "icon_key",
						props = {
							data = {
								key = v.key,
								num = v.num,
							},
							onNode = function(panel)
								panel:scale(0.7)
							end,
						},
					})
				end,
				onAfterBuild = function(list)
					list:setItemAlignCenter()
				end,
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
	["btnBuy"] = {
		varname = "btnBuy",
		binds = {
			event = "touch",
			methods = { ended = bindHelper.self("sendBuyAward") }
		},
	},
	["btnBuy.txt"] = {
		varname = "btnBuyTxt",
		binds = {
			{
				event = "effect",
				data = {outline = {color = ui.NEWCOLORS.OUTLINE.YELLOW, size = 4}}
			},
		}
	},
	["timeBg"] = "timeBg"
}

function ActivityDayFound2Gift:onCreate(activityID)
	self.activityId = activityID

	gGameModel.currday_dispatch:getIdlerOrigin("redHintDaily")
	:modify(function(data)
		data[game.DAILY_REDHINT.dayFound2] = true
	end, true)

	self:initModel()

	-- 每日奖励数据
	local loginwealData = {}
	local yyCfg = csv.yunying.yyhuodong[self.activityId]
	self.rechargeID = yyCfg.paramMap.rechargeID
	local huodongID = yyCfg.huodongID
	local itemDatas1 = {}
	local isHave = false
	for k, v in csvPairs(csv.yunying.loginweal) do
		if v.huodongID == huodongID then
			loginwealData[v.daySum] = {award = v.award, id = k}

			local key, val = next(v.award)
			for key1, val1 in ipairs(itemDatas1) do
				if val1.key == key then
					val1.num = val1.num + val
					isHave = true
					break
				end
			end
			if isHave == false then
				table.insert(itemDatas1, {key = key, num = val})
			else
				isHave = false
			end
		end
	end

	self.itemDatas1:update(itemDatas1)

	local award = yyCfg.paramMap.award
	
	local itemDatas2 = { { key = "rmb", num = award["rmb"] } }
	for key, num in csvMapPairs(award) do
		if key ~= "rmb" then
			table.insert(itemDatas2, { key = key, num = num })
		end
	end
	self.itemDatas2:update(itemDatas2)

	idlereasy.when(self.yyhuodongs,function(_, yyhuodong)
		local yydata = yyhuodong[self.activityId]
		local info = yydata.info or {}
		local itemsData = {}

		self.btnGet:hide()
		self.btnBuy:hide()
		local price = csv.recharges[self.rechargeID]["rmbDisplay_"..LOCAL_LANGUAGE] or csv.recharges[self.rechargeID].rmbDisplay
		if yydata.buy and yydata.buy == 1 then
			self.btnGet:show()
		else
			self.btnBuy:show()
			self.btnBuy:get("txt"):text(string.format(gLanguageCsv.symbolMoney, price))
		end

		self.curSigninID = 0
		local getType = GET_TYPE.CAN_NOT_GOTTEN
		for daySum, wealData in pairs(loginwealData) do
			
			if yydata.stamps[wealData.id] == nil then
				getType = GET_TYPE.CAN_NOT_GOTTEN
			else
				getType = yydata.stamps[wealData.id]
			end

			itemsData[daySum] = {day = daySum, award = wealData.award, id = wealData.id, getType = getType, type = yyCfg.paramMap.type}

			if self.curSigninID == 0 and getType == 1 then
				self.curSigninID = wealData.id
			end
		end
		
		self.itemsData:set(itemsData)
		

		local state = self.curSigninID ~= 0
		uiEasy.setBtnShader(self.btnGet, nil, state and 1 or 2)
		if not state then
			text.deleteAllEffect(self.btnGetTxt)
			text.addEffect(self.btnGetTxt, {color = ui.NEWCOLORS.DISABLED.WHITE})
		else
			text.addEffect(self.btnGetTxt, {color = ui.NEWCOLORS.WHITE})
		end
	end)

	local uiTimeLabel = self.timeBg:get("timeLabel")
	local uiTime = self.timeBg:get("time")

	ActivityView.setCountdown(self, activityID, uiTimeLabel, uiTime, {
		labelChangeCb = function()
			adapt.oneLinePos(uiTimeLabel, uiTime, cc.p(20, 0))
		end
	})
	
end

function ActivityDayFound2Gift:initModel()
	self.yyhuodongs = gGameModel.role:getIdler("yyhuodongs")

	self.itemsData = idlertable.new({}) -- 存放 奖励和领取状态
	self.itemDatas1 = idlers.newWithMap({})
	self.itemDatas2 = idlers.newWithMap({})
end

function ActivityDayFound2Gift:sendGetAward()
	gGameApp:requestServer("/game/yy/award/get/onekey", function(tb)
		gGameUI:showGainDisplay(tb)
	end, self.activityId)
end

function ActivityDayFound2Gift:sendBuyAward()
	local rechargeCfg = csv.recharges
	gGameApp:payDirect(self, {rechargeId = self.rechargeID, yyID = self.activityId, csvID = 0, name = rechargeCfg[self.rechargeID].name, buyTimes = 0})
		:sdkLongTimeCb()
		:serverCb(function()
			local cfg = csv.yunying.yyhuodong[self.activityId]
            gGameUI:showGainDisplay(cfg.paramMap.award, { raw = false })
		end)
		:doit()
end

return ActivityDayFound2Gift
