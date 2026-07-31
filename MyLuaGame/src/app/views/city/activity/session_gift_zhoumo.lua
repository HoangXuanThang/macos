-- 专场礼包

-- 可购买，刷新中，售罄
local STATE_TYPE = {
	canbuy = 1,
	refresh = 2,
	sellout = 3,
}

local ActivitySessionGiftView = class("ActivitySessionGiftView", Dialog)

ActivitySessionGiftView.RESOURCE_FILENAME = "activity_session_gift_zhoumo.json"
ActivitySessionGiftView.RESOURCE_BINDING = {
	["btnClose"] = {
		binds = {
			event = "touch",
			methods = { ended = bindHelper.self("onClose") }
		}
	},
	["bg"] = "bg",
	["title"] = "title",
	["time"] = "time",
	["item"] = "item",
	["list"] = {
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("giftDatas"),
				item = bindHelper.self("item"),
				theme = bindHelper.self("theme"),
				dataOrderCmp = function(a, b)
					if a.sort ~= b.sort then
						return a.sort < b.sort
					end
					return a.csvId < b.csvId
				end,
				onItem = function(list, node, k, v)
					local cfg = v.cfg

					local childs = node:multiget("title", "list", "btn_buy", "times")
					childs.title:text(cfg.name)
					childs.times:text(string.format(gLanguageCsv.directBuyGiftOnetimeBuy, v.leftTimes, cfg.limit))
					text.addEffect(childs.times,
						{ color = ui.COLORS.NORMAL.WHITE, outline = { color = ui.NEWCOLORS.OUTLINE.BLACK, size = 2 } })
					local grayState = v.state == STATE_TYPE.canbuy and 0 or 2
					uiEasy.createItemsToList(list, childs.list, cfg.item,
						{
							scale = 0.65,
							margin = 4,
							grayState = grayState,
							onAfterBuild = function()
							end
						})

					if v.rmb then
						childs.btn_buy:get("price"):text(v.rmb)
					elseif v.price then
						childs.btn_buy:get("price"):text(string.format(gLanguageCsv.symbolMoney, v.price))
					end
					node:setTouchEnabled(v.state == STATE_TYPE.canbuy)
					if v.state == STATE_TYPE.canbuy then
						bind.touch(list, childs.btn_buy,
							{ methods = { ended = functools.partial(list.clickCell, k, v) } })
						uiEasy.setBtnShader(childs.btn_buy, false, 1)
					else
						uiEasy.setTextShader(childs.title, 2, nil, { color = cc.c4b(0xbd, 0xb5, 0xa7, 255) })
						if v.state == STATE_TYPE.sellout then
							childs.btn_buy:get("price"):text(gLanguageCsv.hasBuy)
							uiEasy.setBtnShader(childs.btn_buy, false, 2)
						end
					end
					text.addEffect(childs.btn_buy:get("price"),
						{ color = ui.COLORS.NORMAL.WHITE, outline = { color = ui.NEWCOLORS.OUTLINE.YELLOW } })
				end,
				asyncPreload = 5,
			},
			handlers = {
				clickCell = bindHelper.self("onBuyClick"),
			},
		},
	},
}

function ActivitySessionGiftView:onCreate(activityId)
	self.activityId = activityId

	self:initModel()

	local yyCfg = csv.yunying.yyhuodong[activityId]
	self:onCountDownTime()

	self.giftDatas = idlers.new()

	self.clientBuyTimes = idler.new(true)
	idlereasy.any({ self.yyhuodongs, self.clientBuyTimes }, function(_, yyhuodongs, clientBuyTimes)
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

function ActivitySessionGiftView:initModel()
	self.yyhuodongs = gGameModel.role:getIdler("yyhuodongs")
	self.level = gGameModel.role:read("level")
end

function ActivitySessionGiftView:onCountDownTime()
	local cfg = csv.yunying.yyhuodong[self.activityId]

	local countdown = 0
	local yyEndtime = gGameModel.role:read("yy_endtime")
	if yyEndtime[self.activityId] then
		countdown = yyEndtime[self.activityId] - time.getTime()
	end


	bind.extend(self, self.time, {
		class = 'cutdown_label',
		props = {
			time = countdown,
			tag = "session_gift" .. self.activityId,
			strFunc = function(t)
				if t.day > 0 then
					return t.day .. " day" .. " will disappear"
				else
					if t.str == "00:00:00" then
						return " Ended"
					else
						return t.str .. " Disappeared"
					end
				end
			end,
			callFunc = function()

			end,
			endFunc = function()

			end,
			onNode = function(node)

			end
		}
	})
end

function ActivitySessionGiftView:onBuyClick(list, k, v)
	local activityId = self.activityId
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

return ActivitySessionGiftView
