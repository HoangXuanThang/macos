

-- 可兑换，未达成 (不可兑换)，已兑换
local STATE_TYPE = {
	canExchange = 1,
	noReach = 2,
	exchanged = 3,
}

local ActivityMonopolyWalkExchange = class("ActivityMonopolyWalkExchange", cc.load("mvc").ViewBase)

ActivityMonopolyWalkExchange.RESOURCE_FILENAME = "treasure_exchange.json"
ActivityMonopolyWalkExchange.RESOURCE_BINDING = {
    ["bg"] = "bg",
    ["item"] = "item",
	["item.title"] = {
		binds = {
			{
				event = "effect",
				data = {outline = {color = ui.NEWCOLORS.OUTLINE.BLACK, size = 4}}
			},
		}
	},
	["item.times"] = {
		binds = {
			{
				event = "effect",
				data = {outline = {color = ui.NEWCOLORS.OUTLINE.BLACK, size = 4}}
			},
		}
	},
	["item.cost.price"] = {
		binds = {
			{
				event = "effect",
				data = {outline = {color = ui.NEWCOLORS.OUTLINE.BLACK, size = 4}}
			},
		}
	},
	["sublist"] = "sublist",
	["list"] = {
		varname = "list",
		binds = {
			event = "extend",
			class = "tableview",
			props = {
				data = bindHelper.self("datas"),
				item = bindHelper.self("sublist"),
				cell = bindHelper.self("item"),
				columnSize = 4,
				xMargin = 14,
				yMargin = 30,
				itemAction = {isAction = true},
				onCell = function(list, node, k, v)
					local cfg = v.cfg
					local childs = node:multiget("icon", "times", "cost", "mask", "title", "bg")

					childs.title:text(cfg.desc)

					bind.extend(list, childs.icon, {
						class = "icon_key",
						props = {
							data = {
								key = v.key,
								num = v.num
							},
							onNode = function(node)

							end,
						},
					})

					local key, num = next(v.cost)
					local iconRes = dataEasy.getIconResByKey(key)
					local cost = childs.cost:multiget("icon", "price")
					cost.icon:texture(iconRes)
					cost.price:text(num)

					adapt.oneLineCenterPos(cc.p(200, 50),  {cost.icon, cost.price}, cc.p(10, 0))

					childs.mask:visible(v.state == STATE_TYPE.exchanged)

					childs.times:text(string.format(gLanguageCsv.canExchangeTImes, cfg.exchangeTimes - v.cnt, cfg.exchangeTimes))

					-- local state = 1
					-- if v.state == STATE_TYPE.canExchange then
					-- 	state = 1
					-- elseif v.state == STATE_TYPE.noReach then
					-- 	state = 2
					-- end

					-- uiEasy.setBtnShader(childs.exchangebtn,childs.exchangebtn:get("label"), state)
					bind.touch(list, node, {methods = {ended = functools.partial(list.clickCell, k, v)}})
				end,
			},
			handlers = {
				clickCell = bindHelper.self("onExchangeClick"),
			},
		},
	},
	["time"] = "time",
}

function ActivityMonopolyWalkExchange:onCreate(activityId)
	gGameModel.currday_dispatch:getIdlerOrigin("redHintDaily")
		:modify(function(data)
			data[game.DAILY_REDHINT.monomolyEx] = true
		end, true)
	
	local yyCfg = csv.yunying.yyhuodong[activityId]

    self:initModel()
	
	-- local title = TitleRes[cfg.type]
	gGameUI.topuiManager:createView("monopoly", self, { onClose = self:createHandler("onClose") })
		:init({ title = yyCfg.name, subTitle = "MONOPOLY" })

	local huodongID = yyCfg.huodongID
	self.datas = idlers.new()
	self.activityId = activityId

	local datas = {}
	for k, v in csvPairs(csv.yunying.itemexchange) do
		if v.huodongID == huodongID then
			local state = STATE_TYPE.noReach
			local cnt = 0
			local ok = true
			local costMap = {}
			for k, v in csvMapPairs(v.costMap) do
				local num = dataEasy.getNumByKey(k)
				table.insert(costMap, {key = k, num = num, targetNum = v})
				if num < v then
					ok = false
				end
			end
			if cnt >= v.exchangeTimes then
				state = STATE_TYPE.exchanged
			elseif ok then
				state = STATE_TYPE.canExchange
			end
			local key, num = csvNext(v.items)
			datas[k] = {csvId = k, cfg = v, key = key, num = num, state = state, cnt = cnt, cost = v.costMap, costMap = costMap}
		end
	end
	self.datas:update(datas)

	idlereasy.any({self.yyhuodongs}, function(_, yyhuodongs)
		local yydata = yyhuodongs[activityId] or {}
		local stamps = yydata.stamps or {}
		local datas = {}
		for k, v in csvPairs(csv.yunying.itemexchange) do
			if v.huodongID == huodongID then
				local state = STATE_TYPE.noReach
				local cnt = stamps[k] or 0
				local ok = true
				local costMap = {}
				for k, v in csvMapPairs(v.costMap) do
					local num = dataEasy.getNumByKey(k)
					table.insert(costMap, {key = k, num = num, targetNum = v})
					if num < v then
						ok = false
					end
				end
				if cnt >= v.exchangeTimes then
					state = STATE_TYPE.exchanged
				elseif ok then
					state = STATE_TYPE.canExchange
				end

				self.datas:atproxy(k).state = state
				self.datas:atproxy(k).cnt = cnt
			end
		end
	end)
end

function ActivityMonopolyWalkExchange:initModel()
	self.yyhuodongs = gGameModel.role:getIdler("yyhuodongs")
end

function ActivityMonopolyWalkExchange:getBuyInfoCb(csvId, num)
	gGameApp:requestServer("/game/yy/award/get", function(tb)
		gGameUI:showGainDisplay(tb)
	end, self.activityId, csvId, num)
end

function ActivityMonopolyWalkExchange:onExchangeClick(list, k, v)
	if v.state == STATE_TYPE.canExchange then
		-- maxNum 最大数量
		local maxNum = v.cfg.exchangeTimes - v.cnt

		gGameUI:stackUI("common.buy_info", nil, nil, v.cost, {id = v.key, num = v.num}, {maxNum = maxNum, flag = "exchange", contentType = "num"}, self:createHandler("getBuyInfoCb", v.csvId))
	elseif v.state == STATE_TYPE.noReach then
		gGameUI:showTip(gLanguageCsv.exchangeItemNotEnough)
	end
end

return ActivityMonopolyWalkExchange