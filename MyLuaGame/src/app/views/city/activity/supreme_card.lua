-- 长期月卡

local STATE_TYPE = {
	null = 0,
	buy = 1,
	max = 2, --已达上限
}

local ActivitySupremeCard = class("ActivitySupremeCard", Dialog)

ActivitySupremeCard.RESOURCE_FILENAME = "activity_supreme_card.json"
ActivitySupremeCard.RESOURCE_BINDING = {
	["btnClose"] = {
		binds = {
			event = "touch",
			methods = { ended = bindHelper.self("onClose") }
		},
	},

	["buyBtn"] = {
		varname = "btnBuy",
		binds = {
			event = "touch",
			methods = { ended = bindHelper.self("onBuyClick") }
		},
	},
	["list"] = "list",
}

function ActivitySupremeCard:onCreate(params)
	gGameModel.currday_dispatch:getIdlerOrigin("supremeCard"):set(true)
	local params = params or {}

	self.activityId = 14

	self:initModel()


	local yyCfg = csv.yunying.yyhuodong[self.activityId]


	self.data = {
		rechargeId = yyCfg.paramMap.rechargeID,
		activityId = self.activityId,
		state = idler.new(STATE_TYPE
			.null),
		day = idler.new(0)
	}

	local award = yyCfg.paramMap.award

	local items = { { key = "rmb", num = award["rmb"] } }
	for key, num in csvMapPairs(award) do
		if key ~= "rmb" then
			table.insert(items, { key = key, num = num })
		end
	end

	uiEasy.createItemsToList(self, self.list, items, { scale = 0.8, margin = 40 })

	idlereasy.any({ self.data.state, self.data.day }, function(_, state, day)
		local rechargeCfg = csv.recharges[self.data.rechargeId]

		local btnLabel = self.btnBuy:get("label")
		uiEasy.setBtnShader(self.btnBuy, false, 1)
		self.btnBuy:setTouchEnabled(true)

		text.addEffect(btnLabel,
			{ color = ui.COLORS.NORMAL.WHITE, outline = { color = ui.NEWCOLORS.OUTLINE.YELLOW, size = 4 } })
		if state == STATE_TYPE.buy then
			btnLabel:text(string.format(gLanguageCsv.symbolMoney, rechargeCfg["rmbDisplay_"..LOCAL_LANGUAGE] or rechargeCfg.rmbDisplay))
			btnLabel:setFontSize(60)
			btnLabel:alignCenter(self.btnBuy:size())
		elseif state == STATE_TYPE.max then
			uiEasy.setBtnShader(self.btnBuy, false, 2)
			btnLabel:text(gLanguageCsv.hasBuy)
			btnLabel:setFontSize(50)
			btnLabel:alignCenter(self.btnBuy:size())
		end
	end)

	self.clientBuyTimes = idler.new(true)

	idlereasy.when(self.yyhuodongs, function(_, yyhuodongs)
		if yyhuodongs[self.activityId] then
			local lastday = yyhuodongs[self.activityId].lastday
			local enddate = yyhuodongs[self.activityId].enddate
			local today = tonumber(time.getTodayStrInClock())
			self.data.day:set(math.max(0,
				1 + math.floor((time.getNumTimestamp(enddate) - time.getNumTimestamp(today)) / 24 / 3600)))
			local rechargeCfg = csv.recharges[self.data.rechargeId]

			local yyCfg = csv.yunying.yyhuodong[self.activityId]
			local maxMonthCard = yyCfg.paramMap.most
			if self.data.day:read() > rechargeCfg.param.days * (maxMonthCard - 1) then
				self.data.state:set(STATE_TYPE.max)
			else
				self.data.state:set(STATE_TYPE.buy)
			end
		else
			self.data.state:set(STATE_TYPE.buy)
		end
	end)


	Dialog.onCreate(self, { blackType = 1 })
end

function ActivitySupremeCard:initModel()
	self.yyhuodongs = gGameModel.role:getIdler("yyhuodongs")
end

function ActivitySupremeCard:updateGiftData(data)
	if not data then
		return
	end
	self.showGiftData = data



	local giftInfo = self.guideGifts:read()[data.giftID]


	local label = self.btnBuy:get("label")
	if giftInfo.flag then
		-- 已购买
		label:text(gLanguageCsv.hasBuy)
		uiEasy.setBtnShader(self.btnBuy, nil, 2)
	else
		if giftInfo.expired_date < nowTime then
			-- 已过期
			label:text(gLanguageCsv.giftOutOfDate)
			uiEasy.setBtnShader(self.btnBuy, nil, 2)
		else
			local price = csv.recharges[data.cfg.rechargeID]["rmbDisplay_"..LOCAL_LANGUAGE] or csv.recharges[data.cfg.rechargeID].rmbDisplay
			label:text(string.format(gLanguageCsv.symbolMoney, price))
			uiEasy.setBtnShader(self.btnBuy, nil, 1)
		end
	end
end

function ActivitySupremeCard:onBuyClick()
	local data = self.data

	gGameApp:payCustom(self)
		:params({ rechargeId = data.rechargeId, yyID = data.activityId })
		:checkCanbuy()
		:serverCb(function()
			local rechargeCfg = csv.recharges[data.rechargeId]
			gGameUI:showGainDisplay({ rmb = rechargeCfg.rmb }, { raw = false })
			-- gGameUI:showTip(gLanguageCsv.monthCardBuySuccess)
		end)
		:doit()
end

return ActivitySupremeCard
