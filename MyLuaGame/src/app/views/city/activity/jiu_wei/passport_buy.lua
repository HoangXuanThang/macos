local ActivityJiuWeiPassportBuy = class("ActivityJiuWeiPassportBuy", Dialog)
ActivityJiuWeiPassportBuy.RESOURCE_FILENAME = "activity_jiuwei_buy.json"
ActivityJiuWeiPassportBuy.RESOURCE_BINDING = {
	["btnClose"] = {
		binds = {
			event = "touch",
			methods = { ended = bindHelper.self("onClose") }
		},
	},
	["btnBuy"] = {
		varname = "btnBuy",
		binds = {
			event = "touch",
			methods = { ended = bindHelper.self("onBuyClick") }
		},
	},
	["btnBuy.price"] = {
		binds = {
			event = "effect",
			data = { outline = { color = ui.NEWCOLORS.OUTLINE.YELLOW, size = 4 } },
		},
	},
	["item"] = "item",
	["subList"] = "subList",
	-- ["awardList"] = {
	-- 	varname = "awardList",
	-- 	binds = {
	-- 		event = "extend",
	-- 		class = "listview",
	-- 		props = {
	-- 			data = bindHelper.self("itemDatas1"),
	-- 			item = bindHelper.self("item"),
	-- 			margin = 10,
	-- 			onItem = function(list, node, k, v)
	-- 				bind.extend(list, node, {
	-- 					class = "icon_key",
	-- 					props = {
	-- 						data = {
	-- 							key = v.key,
	-- 							num = v.num,
	-- 						},
	-- 						onNode = function(panel)
	-- 							panel:scale(0.75)
	-- 						end
	-- 					},
	-- 				})
	-- 			end,
	-- 			onAfterBuild = function(list)
	-- 				local count = list:getChildrenCount()
	-- 				if count < 4 and count > 0 then
	-- 					list:setItemAlignCenter()
	-- 				end
	-- 			end
	-- 		},
	-- 	},
	-- },
	["awardList"] = {
		varname = "awardList",
		binds = {
			event = "extend",
			class = "tableview",
			props = {
				data = bindHelper.self("itemDatas1"),
				item = bindHelper.self("subList"),
				cell = bindHelper.self("item"),
				columnSize = 5,
				xMargin = 10,
				yMargin = 10,
				onCell = function(list, node, k, v)
					bind.extend(list, node, {
						class = "icon_key",
						props = {
							data = v,
							onNode = function(panel)
								panel:scale(0.75)
							end
						},
					})
				end,
			},
		},
	},




	["showList"] = {
		varname = "showList",
		binds = {
			event = "extend",
			class = "tableview",
			props = {
				data = bindHelper.self("itemDatas2"),
				item = bindHelper.self("subList"),
				cell = bindHelper.self("item"),
				columnSize = 5,
				xMargin = 10,
				yMargin = 10,
				onCell = function(list, node, k, v)
					bind.extend(list, node, {
						class = "icon_key",
						props = {
							data = v,
							onNode = function(panel)
								panel:scale(0.75)
							end
						},
					})
				end,
			},
		},
	},

}

function ActivityJiuWeiPassportBuy:onCreate(activityId, cb)
	self:initModel()
	self.cb = cb
	local yyCfg = csv.yunying.yyhuodong[activityId]
	self.endDate = yyCfg.endDate
	self.activityId = activityId

	local rechargeCfg = csv.yunying.playpassport_recharge
	for k, v in csvMapPairs(rechargeCfg) do
		if v.huodongID == yyCfg.huodongID then
			self.csvId = k
		end
	end

	self.btnBuy:get("price"):text(string.format(gLanguageCsv.symbolMoney,
		csv.recharges[rechargeCfg[self.csvId].rechargeID].rmbDisplay))

	local level = self.yyhuodongs:read()[self.activityId].info.level

	self.itemDatas1 = idlers.newWithMap({})
	self.itemDatas2 = idlers.newWithMap({})

	local itemDatas1 = {}
	local itemDatas2 = {}
	local isHave = false
	for k, v in csvPairs(csv.yunying.playpassport_award) do
		if v.huodongID == yyCfg.huodongID and v.level <= level then
			for key, val in csvMapPairs(v.eliteAward) do
				for key1, val1 in ipairs(itemDatas1) do
					if val1.key == key then
						val1.num = val1.num + val
						isHave = true
						break
					end
				end
				if isHave == false then
					table.insert(itemDatas1, { key = key, num = val })
				else
					isHave = false
				end
			end
		end
	end
	self.itemDatas1:update(itemDatas1)

	for k, v in csvPairs(csv.yunying.playpassport_award) do
		if v.huodongID == yyCfg.huodongID and v.level > level then
			for key, val in csvMapPairs(v.eliteAward) do
				for key1, val1 in ipairs(itemDatas2) do
					if val1.key == key then
						val1.num = val1.num + val
						isHave = true
						break
					end
				end
				if isHave == false then
					table.insert(itemDatas2, { key = key, num = val })
				else
					isHave = false
				end
			end
		end
	end
	self.itemDatas2:update(itemDatas2)

	Dialog.onCreate(self, { blackType = 1 })
end

function ActivityJiuWeiPassportBuy:initModel()
	self.yyhuodongs = gGameModel.role:getIdler("yyhuodongs")
end

function ActivityJiuWeiPassportBuy:onBuyClick(list, v)
	local rechargeCfg = csv.yunying.playpassport_recharge
	gGameApp:payDirect(self,
		{
			rechargeId = rechargeCfg[self.csvId].rechargeID,
			yyID = self.activityId,
			csvID = self.csvId,
			name = rechargeCfg
				[self.csvId].name,
			buyTimes = 0
		})
		:sdkLongTimeCb()
		:serverCb(function()
			self:onClose()
		end)
		:doit()
end

function ActivityJiuWeiPassportBuy:onClose()
	self:addCallbackOnExit(self.cb)
	Dialog.onClose(self)
end

return ActivityJiuWeiPassportBuy
