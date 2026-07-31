-- 开服尊享

-- 可购买，刷新中，售罄
local STATE_TYPE = {
	canbuy = 1,
	refresh = 2,
	sellout = 3,
}
local ActivityView = require "app.views.city.activity.view"

local ActivityMiixGiftView = class("ActivityMiixGiftView", Dialog)

ActivityMiixGiftView.RESOURCE_FILENAME = "activity_miix_gift.json"
ActivityMiixGiftView.RESOURCE_BINDING = {
	["btnClose"] = {
		binds = {
			event = "touch",
			methods = { ended = bindHelper.self("onClose") }
		},
	},
	["timeBg"] = "timeBg",
	["item"] = "item",
	["list"] = {
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("giftDatas"),
				item = bindHelper.self("item"),
				dataOrderCmp = function(a, b)
					if a.sort ~= b.sort then
						return a.sort < b.sort
					end
					return a.csvId < b.csvId
				end,
				onItem = function(list, node, k, v)
					local cfg = v.cfg

					local childs = node:multiget("title", "icon", "list", "times", "btn_buy")

					childs.title:text(cfg.name)

					childs.icon:texture("activity/server_open/kfzx/kfzx_icon" .. k .. ".png")

					childs.times:text(string.format(gLanguageCsv.directBuyGiftOnetimeBuy, v.leftTimes, cfg.limit))
					text.addEffect(childs.times,
						{ color = ui.COLORS.NORMAL.WHITE, outline = { color = ui.NEWCOLORS.OUTLINE.BLACK, size = 2 } })
					local rewards = dataEasy.getItemData(cfg.item)
					uiEasy.createItemsToList(list, childs.list, rewards,
						{
							scale = 0.6,
							margin = 5,
							onAfterBuild = function()
								childs.list:setItemAlignCenter()
							end
						})

					if v.state == STATE_TYPE.canbuy then
						bind.touch(list, childs.btn_buy,
							{ methods = { ended = functools.partial(list.clickCell, k, v) } })
						uiEasy.setBtnShader(childs.btn_buy, false, 1)
					else
						if v.state == STATE_TYPE.sellout then
							childs.btn_buy:get("price"):text(gLanguageCsv.hasBuy)
							uiEasy.setBtnShader(childs.btn_buy, false, 2)
						end
					end

					childs.btn_buy:get("price"):text(string.format(gLanguageCsv.symbolMoney, v.price))
					text.addEffect(childs.btn_buy:get("price"),
						{ color = ui.COLORS.NORMAL.WHITE, outline = { color = ui.NEWCOLORS.OUTLINE.YELLOW } })
					bind.touch(list, childs.btn_buy,
						{ clicksafe = true, methods = { ended = functools.partial(list.clickItem, k, v) } })
				end,
			},
			handlers = {
				clickItem = bindHelper.self("onItemClick"),
			},
		},
	},

}

function ActivityMiixGiftView:onCreate(actId)
	gGameModel.currday_dispatch:getIdlerOrigin("miixGiftClick"):set(true)

	self:initModel()

	self.activityId:set(actId)
	self:onCountDownTime()

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
						state = STATE_TYPE.sellout
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
							sort = v.sort
						})
				end
			end

			self.giftDatas:update(datas)
		end)

	Dialog.onCreate(self, { blackType = 1 })
end

function ActivityMiixGiftView:initModel()
	self.yyhuodongs = gGameModel.role:getIdler("yyhuodongs")
	self.yyOpen = gGameModel.role:getIdler('yy_open')
	self.level = gGameModel.role:read("level")
	self.activityId = idler.new()

	self.giftDatas = idlers.new()
	-- self.showTab = idler.new(1)
	-- self.rightItem:visible(false)
end

function ActivityMiixGiftView:onCountDownTime()
	local cfg = csv.yunying.yyhuodong[self.activityId:read()]

	if cfg.clientParam.isShowCountDown ~= false then
		local uiTimeLabel = self.timeBg:get("title")
		local uiTime = self.timeBg:get("time")
		ActivityView.setCountdown(self, self.activityId:read(), uiTimeLabel, uiTime, {
			labelChangeCb = function()
				adapt.oneLinePos(uiTime, { uiTimeLabel }, cc.p(5, 0), "right")
			end,
			tag = 1
		})
	else
		self.timeBg:hide()
	end
	-- body
end

function ActivityMiixGiftView:onItemClick(list, k, v)
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

return ActivityMiixGiftView
