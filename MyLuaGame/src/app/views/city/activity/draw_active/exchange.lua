local Activity = require "app.views.city.activity.view"
local YY_TYPE = game.YYHUODONG_TYPE_ENUM_TABLE

-- 可兑换，未达成 (不可兑换)，已兑换
local STATE_TYPE = {
	canExchange = 1,
	noReach = 2,
	exchanged = 3,
}

local ActivityThemeSpExchange = class("ActivityThemeSpExchange", cc.load("mvc").ViewBase)

ActivityThemeSpExchange.RESOURCE_FILENAME = "activity_draw_active_exchange.json"
ActivityThemeSpExchange.RESOURCE_BINDING = {
	["bg"] = "bg",
	["item"] = "item",
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
				columnSize = 5,
				asyncPreload = 15,
				topPadding = 1,
				paddingData = { up = 0, down = 100, left = 0, right = 0 },
				itemAction = { isAction = true },
				onCell = function(list, node, k, v)
					local cfg = v.cfg
					local childs = node:multiget("icon", "times", "btnBuy", "title", "bg", "headBg")
					childs.headBg:visible(k == 1)

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
					local btnBuy = childs.btnBuy:multiget("icon", "price")
					btnBuy.icon:texture(iconRes)
					btnBuy.price:text(num)
					adapt.oneLineCenterPos(cc.p(150, 60), { btnBuy.icon, btnBuy.price }, cc.p(10, 0))
					childs.times:text(string.format("Exchange times: " .. " %s/%s", cfg.exchangeTimes - v.cnt,
						cfg.exchangeTimes))
					bind.touch(list, childs.btnBuy, { methods = { ended = functools.partial(list.clickCell, k, v) } })
					text.addEffect(btnBuy.price, { outline = { color = ui.NEWCOLORS.OUTLINE.YELLOW, size = 4 } })
				end,
			},
			handlers = {
				clickCell = bindHelper.self("onExchangeClick"),
			},
		},
	},
}

function ActivityThemeSpExchange:onCreate(activityId, topType)
	local yyCfg = csv.yunying.yyhuodong[activityId]

	if topType == YY_TYPE.drawLimitHelditem then
		gGameModel.currday_dispatch:getIdlerOrigin("redHintDaily")
		:modify(function(data)
			data[game.DAILY_REDHINT.drawHeldItemEx] = true
		end, true)

		gGameUI.topuiManager:createView("draw_helditem", self, { onClose = self:createHandler("onClose") })
        :init({ title = yyCfg.name, subTitle = "DRAW HELDITEM" })
	else
		gGameModel.currday_dispatch:getIdlerOrigin("redHintDaily")
		:modify(function(data)
			data[game.DAILY_REDHINT.drawExplorEx] = true
		end, true)

		gGameUI.topuiManager:createView("draw_explor", self, { onClose = self:createHandler("onClose") })
        :init({ title = yyCfg.name, subTitle = "DRAW EXPLOR" })
	end

	self:initModel()

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
				table.insert(costMap, { key = k, num = num, targetNum = v })
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
			datas[k] = {
				csvId = k,
				cfg = v,
				key = key,
				num = num,
				state = state,
				cnt = cnt,
				cost = v.costMap,
				costMap =
					costMap
			}
		end
	end
	self.datas:update(datas)

	idlereasy.any({ self.yyhuodongs }, function(_, yyhuodongs)
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
					table.insert(costMap, { key = k, num = num, targetNum = v })
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

function ActivityThemeSpExchange:initModel()
	self.yyhuodongs = gGameModel.role:getIdler("yyhuodongs")
end

function ActivityThemeSpExchange:getBuyInfoCb(csvId, num)
	gGameApp:requestServer("/game/yy/award/get", function(tb)
		gGameUI:showGainDisplay(tb)
	end, self.activityId, csvId, num)
end

function ActivityThemeSpExchange:onExchangeClick(list, k, v)
	if v.state == STATE_TYPE.canExchange then
		-- maxNum 最大数量
		local maxNum1 = math.floor(v.costMap[1].num / v.costMap[1].targetNum)
		local maxNum = math.min(v.cfg.exchangeTimes - v.cnt, maxNum1)

		gGameUI:stackUI("common.buy_info", nil, nil, v.cost, { id = v.key, num = v.num },
			{ maxNum = maxNum, flag = "exchange", contentType = "num" }, self:createHandler("getBuyInfoCb", v.csvId))
	elseif v.state == STATE_TYPE.noReach then
		gGameUI:showTip(gLanguageCsv.exchangeItemNotEnough)
	end
end

return ActivityThemeSpExchange
