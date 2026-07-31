local Activity = require "app.views.city.activity.view"

-- 可购买，刷新中，售罄
local STATE_TYPE = {
	canbuy = 1,
	refresh = 2,
	sellout = 3,
}

local ActivityThemeSkinGive = class("ActivityThemeSkinGive", cc.load("mvc").ViewBase)

ActivityThemeSkinGive.RESOURCE_FILENAME = "activity_theme_skin_give.json"
ActivityThemeSkinGive.RESOURCE_BINDING = {
	["bg"] = "bg",
	["item"] = "item",
	["panel.list"] = {
		varname = "list",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("datas"),
				item = bindHelper.self("item"),
				theme = bindHelper.self("curTheme"),
				giftCount = bindHelper.self("giftCount"),
				margin = 20,
				preloadCenterIndex = 1,
				dataOrderCmp = function(a, b)
					if a.state ~= b.state then
						return a.state < b.state
					end
					if a.sort ~= b.sort then
						return a.sort < b.sort
					end
					return a.csvId < b.csvId
				end,
				itemAction = { isAction = true },
				onItem = function(list, node, k, v)
					local cfg = v.cfg
					local childs = node:multiget("list", "btnBuy", "next", "btnLock")

					childs.btnLock:visible(v.isLock)
					childs.next:visible(v.sort ~= list.giftCount)
					uiEasy.createItemsToList(list, childs.list, cfg.item,
						{
							scale = 0.8,
							margin = 10,
						})

					local price = childs.btnBuy:get("price")
					local rmbIcon = childs.btnBuy:get("rmb")
					rmbIcon:visible(false)
					if v.rmb then
						price:text(v.rmb)
						if type(v.rmb) ~= "string" then
							rmbIcon:visible(true)
							adapt.oneLineCenterPos(cc.p(200, 50), { price, rmbIcon }, cc.p(10, 0))
						end
					elseif v.price then
						price:text(string.format(gLanguageCsv.symbolMoney, v.price))
					end
					childs.btnBuy:setTouchEnabled(false)
					if v.state == STATE_TYPE.canbuy then
						if not v.isLock then
							childs.btnBuy:setTouchEnabled(true)
							bind.touch(list, childs.btnBuy,
								{ clicksafe = true, methods = { ended = functools.partial(list.clickCell, k, v) } })
						end
					else
						cache.setShader(childs.btnBuy, false, "hsl_gray")
						childs.btnBuy:get("price"):text(gLanguageCsv.received)
					end

					bind.touch(list, childs.btnLock,
						{ clicksafe = true, methods = { ended = functools.partial(list.clickLockCell, k, v) } })
				end,
			},
			handlers = {
				clickCell = bindHelper.self("onBuyClick"),
				clickLockCell = bindHelper.self("onLockClick"),
			},
		},
	},
	["panel.timeBg"] = "timeBg",
	["panel.bg"] = "awardBg",
	["nodSkel"] = "nodSkel",
}

function ActivityThemeSkinGive:onCreate(activityId)
	local yyCfg = csv.yunying.yyhuodong[activityId]
	gGameModel.currday_dispatch:getIdlerOrigin("themeSkinGiveClick"):set(true)
	self:initModel()
	gGameUI.topuiManager:createView("theme_skin", self, { onClose = self:createHandler("onClose") })
		:init({ title = yyCfg.name, subTitle = "STAR UPGRADE" })

	self.datas = idlers.new()
	self.activityId = idler.new(activityId)
	self.giftCount = 0

	self.clientBuyTimes = idler.new(true)
	idlereasy.any({ self.yyhuodongs, self.clientBuyTimes, self.activityId },
		function(_, yyhuodongs, clientBuyTimes, activityId)
			local huodongID = csv.yunying.yyhuodong[activityId].huodongID
			local yydata = yyhuodongs[activityId] or {}
			local stamps = yydata.stamps or {}
			local datas = {}
			for k, v in csvPairs(csv.yunying.directbuygift) do
				if v.huodongID == huodongID and self.level >= v.levelLimit then
					local state = STATE_TYPE.canbuy
					local buyTimes = stamps[k] or 0
					buyTimes = dataEasy.getPayClientBuyTimes("directBuyData", activityId, k, buyTimes)
					local leftTimes = math.max(0, v.limit - buyTimes)
					local status = v.status
					if leftTimes == 0 then
						if v.refresh then
							state = STATE_TYPE.refresh
						else
							state = STATE_TYPE.sellout
						end
					end
					--# 判断是免费还是钻石和钱
					local rmb, price
					if v.rmbCost == 0 then
						rmb = gLanguageCsv.freeToReceive
					elseif v.rmbCost >= 1 then
						rmb = v.rmbCost
					else
						price = csv.recharges[v.rechargeID]["rmbDisplay_"..LOCAL_LANGUAGE] or csv.recharges[v.rechargeID].rmbDisplay
					end

					local isLock = false
					if v.unlock then
						isLock = (stamps[v.unlock] or 0) == 0 and true or false
					end

					table.insert(datas,
						{
							csvId = k,
							cfg = v,
							state = state,
							buyTimes = buyTimes,
							leftTimes = leftTimes,
							price = price,
							rmb =
								rmb,
							status = status,
							sort = v.sort,
							isLock = isLock
						})
				end
			end
			self.giftCount = table.length(datas)
			self.datas:update(datas)
		end)


	local uiLabel = self.timeBg:get("title")
	local uiTime = self.timeBg:get("time")
	Activity.setCountdown(self, self.activityId:read(), uiLabel, uiTime, {
		labelChangeCb = function()
			adapt.oneLineCenterPos(cc.p(200, 30), { uiLabel, uiTime }, cc.p(10, 0))
		end,
		tag = "give" .. self.activityId:read()
	})
	text.addEffect(uiLabel, { outline = { color = ui.NEWCOLORS.OUTLINE.BLACK, size = 3 } })
	text.addEffect(uiTime, { outline = { color = ui.NEWCOLORS.OUTLINE.BLACK, size = 3 } })

	local clientParam = yyCfg.clientParam
	local unitCsv = csv.unit[clientParam.unitID]
	local spine = widget.addAnimationByKey(self.nodSkel, unitCsv.showOpen, unitCsv.showOpen, "default", 1, true)
	spine:xy(clientParam.x, clientParam.y):scale(clientParam.scale)
end

function ActivityThemeSkinGive:initModel()
	self.yyhuodongs = gGameModel.role:getIdler("yyhuodongs")
	self.level = gGameModel.role:read("level")
end

function ActivityThemeSkinGive:onLockClick(list, k, v)
	gGameUI:showTip("Need to claim pre-rewards")
end

function ActivityThemeSkinGive:onBuyClick(list, k, v)
	local activityId = self.activityId:read()
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

return ActivityThemeSkinGive
