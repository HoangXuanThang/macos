-- @Date:   2019-05-30
-- @Desc:

-- 可购买，售罄 不能购买
local STATE_TYPE = {
	canbuy = 1,
	sellout = 2,
	cantbuy = 3,
}
local ActivityView = require "app.views.city.activity.view"
local ActivitySurpriseGift = class("ActivitySurpriseGift", cc.load("mvc").ViewBase)

ActivitySurpriseGift.RESOURCE_FILENAME = "activity_surprise_gift.json"
ActivitySurpriseGift.RESOURCE_BINDING = {
	["item"] = "item",
	["list"] = {
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("datas"),
				item = bindHelper.self("item"),
				selectedGroup = bindHelper.self("selectedGroup"),
				dataOrderCmp = function(a, b)
					if a.sort ~= b.sort then
						return a.sort < b.sort
					end
					return a.id < b.id
				end,
				onItem = function(list, node, k, v)
					local cfg = v.cfg
					local childs = node:multiget("title", "bottomPanel", "list", "awardList")

					childs.title:text(cfg.name)
					text.addEffect(childs.title,
						{ color = ui.COLORS.NORMAL.WHITE, outline = { color = ui.NEWCOLORS.OUTLINE.BLACK } })

					uiEasy.createItemsToList(list, childs.awardList, v.cfg.item, {
						scale = 0.9,
						onAfterBuild = function()
							childs.awardList:setItemAlignCenter()
						end
					})

					local btn = childs.bottomPanel:get("btn")
					local price = childs.bottomPanel:get("price")

					local state = v.state
					if v.rmb then
						price:text(v.rmb)
					elseif v.price then
						price:text(string.format(gLanguageCsv.symbolMoney, v.price))

						local selectedGroup = list.selectedGroup:read()
						if selectedGroup > 0 and selectedGroup ~= v.cfg.group then
							state = STATE_TYPE.cantbuy
						end
					end

					if state == STATE_TYPE.canbuy then
						cache.setShader(btn, false, "normal")
						text.addEffect(price,
							{ color = ui.COLORS.NORMAL.WHITE, outline = { color = ui.NEWCOLORS.OUTLINE.YELLOW, size = 4 } })
						bind.touch(list, btn, { methods = { ended = functools.partial(list.clickItem, k, v) } })
					else
						cache.setShader(btn, false, "hsl_gray")
						text.deleteAllEffect(price)
						text.addEffect(price, { color = ui.COLORS.DISABLED.WHITE })
						if v.group == 1 and v.leftTimes < 1 then
							price:text(gLanguageCsv.hasBuy)
						end
					end
				end,
			},
			handlers = {
				clickItem = bindHelper.self("onBuyClick"),
			},
		},
	},
	["rechargeBtn"] = {
		varname = "combBuy",
		binds = {
			event = "touch",
			methods = { ended = bindHelper.self("onCombGiftBuy") }
		},
	},
	["rechargeBtn.label"] = "combPrice",
	["txtTips1"] = {
		varname = "txtTips1",
		binds = {
			event = "effect",
			data = { outline = { color = ui.NEWCOLORS.OUTLINE.BLACK, size = 3 } },
		},
	},
	["txtTips3"] = "txtTips3"
}

function ActivitySurpriseGift:onCreate(activityID)
	self.activityID = activityID

	local yyCfg = csv.yunying.yyhuodong[activityID]
	local yyHdid = gGameModel.role:read("yy_hdid") or {}
	local huodongID = yyHdid[activityID] or yyCfg.huodongID

	self:initModel()

	self.txtTips1:text(gLanguageCsv.jingxilibao2)
	self.txtTips3:text(gLanguageCsv.jingxilibao4)

	self.selectedGroup = idler.new(0)

	self.datas = idlers.new()
	self.combData = idlereasy.new(false)
	idlereasy.any({ self.combData, self.selectedGroup }, function(_, combData, selectedGroup)
		if not combData then
			return
		end
		self.combPrice:text(gLanguageCsv.jingxilibao1)

		if combData.leftTimes < 1 then
			self.combPrice:text(gLanguageCsv.hasBuy)
		end

		local state = combData.state

		if combData.group ~= selectedGroup and selectedGroup > 0 then
			state = STATE_TYPE.cantbuy
		end

		uiEasy.setBtnShader(self.combBuy, self.combPrice, state == STATE_TYPE.canbuy and 1 or 2)
		if state == STATE_TYPE.canbuy then
			text.addEffect(self.combPrice,
				{ color = ui.COLORS.NORMAL.WHITE, outline = { color = ui.NEWCOLORS.OUTLINE.YELLOW, size = 4 } })
		else
			text.deleteEffect(self.combPrice, { "outline" })
		end
	end)

	self.clientBuyTimes = idler.new(true)

	idlereasy.any({ self.yyhuodongs, self.clientBuyTimes }, function(_, yyhuodongs)
		local yydata = yyhuodongs[activityID] or {}
		local stamps = yydata.stamps or {}

		local datas = {}
		local selGroup = 0
		for k, v in csvPairs(csv.yunying.directbuygift) do
			if v.huodongID == huodongID then
				local state = STATE_TYPE.canbuy
				local buyTimes = stamps[k] or 0
				buyTimes = dataEasy.getPayClientBuyTimes("directBuyData", activityID, k, buyTimes)
				local leftTimes = math.max(0, v.limit - buyTimes)
				local status = v.status
				if leftTimes == 0 then
					state = STATE_TYPE.sellout

					if v.group > 0 then
						selGroup = v.group
					end
				end
				-- 判断是否可以购买
				--# 判断是免费还是钻石和钱
				local rmb, price
				if v.rmbCost == 0 then
					rmb = gLanguageCsv.freeToReceive
				elseif v.rmbCost >= 1 then
					rmb = v.rmbCost
				else
					price = csv.recharges[v.rechargeID].rmbDisplay
				end

				local giftData = {
					csvId = k,
					cfg = v,
					state = state,
					buyTimes = buyTimes,
					leftTimes = leftTimes,
					price =
						price,
					rmb = rmb,
					status = status,
					sort = v.sort
				}

				if v.sort == 4 then
					self.combData:set(giftData)
				else
					table.insert(datas, giftData)
				end
			end
		end

		self.selectedGroup:set(selGroup)
		self.datas:update(datas)
	end)
end

function ActivitySurpriseGift:initModel()
	self.yyhuodongs = gGameModel.role:getIdler("yyhuodongs")
	self.yyOpen = gGameModel.role:getIdler('yy_open')
end

function ActivitySurpriseGift:onCombGiftBuy()
	self:onBuyClick(nil, nil, self.combData:read())
end

function ActivitySurpriseGift:onBuyClick(list, k, v)
	local activityId = self.activityID
	if not v.rmb then
		gGameApp:payDirect(self,
			{
				rechargeId = v.cfg.rechargeID,
				yyID = activityId,
				csvID = v.csvId,
				name = v.cfg.name,
				buyTimes = v
					.buyTimes
			}, self.clientBuyTimes)
			:serverCb(function()
				local cfg = csv.yunying.directbuygift[v.csvId]
				gGameUI:showGainDisplay(cfg.item, { raw = false })
			end)
			:doit()
	else
		gGameApp:requestServer("/game/yy/award/get", function(tb)
			self.clientBuyTimes:notify()
			local cfg = csv.yunying.directbuygift[v.csvId]
			gGameUI:showGainDisplay(cfg.item, { raw = false })
		end, activityId, v.csvId)
	end
end

return ActivitySurpriseGift
