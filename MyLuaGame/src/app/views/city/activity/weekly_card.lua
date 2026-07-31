local GET_TYPE = {
	GOTTEN = 0,      --已领取
	CAN_GOTTEN = 1,  --可领取
	CAN_NOT_GOTTEN = 2, --未完成
}

local COUNTDOWN_TYPE = {
	BUY = 1, --售卖倒计时
	GET = 2, --领取倒计时
}

local ActivityWeeklyCardDialog = class("ActivityWeeklyCardDialog", Dialog)
ActivityWeeklyCardDialog.RESOURCE_FILENAME = "activity_weekly_card.json"
ActivityWeeklyCardDialog.RESOURCE_BINDING = {
	["btnBuy"] = {
		varname = "btnBuy",
		binds = {
			{
				event = "touch",
				clicksafe = true,
				methods = { ended = bindHelper.self("buyWeeklyCard") }
			},
			{
				event = "visible",
				idler = bindHelper.self("notbuy"),
			}
		},
	},
	["btnBought"] = {
		varname = "btnBought",
		binds = {
			event = "visible",
			idler = bindHelper.self("buy"),
		},
	},
	["text1"] = {
		varname = "text1",
		binds = {
			event = "effect",
			data = { outline = { color = cc.c4b(230, 100, 80, 255), size = 3 } },
		}
	},
	["text2"] = {
		binds = {
			{
				event = "effect",
				data = { outline = { color = cc.c4b(230, 100, 80, 255), size = 3 } },
			},
		}
	},
	["textCountDown"] = {
		varname = "textCountDown",
		binds = {
			{
				event = "effect",
				data = { outline = { color = cc.c4b(230, 100, 80, 255), size = 3 } },
			},
		}
	},
	["item"] = "item",
	["iconItem"] = "iconItem",
	["list"] = {
		varname = "list",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("itemsData"),
				item = bindHelper.self("item"),
				preloadCenter = bindHelper.self("preloadCenter"),
				itemAction = { isAction = true },
				onItem = function(list, node, k, v)
					list.initItem(node, k, v)
				end,
				asyncPreload = 5,
			},
			handlers = {
				initItem = bindHelper.self("initItem"),
			},
		},
	},
	["imgAward1_0"] = "imgAward",
	["imgTitle"] = "imgTitle",
	["imgGift"] = "imgGift",
	["heroNode"] = "heroNode",
	["textTitle"] = "textTitle",
	["imgAward1"] = "imgAward1",
	["imgAward2"] = "imgAward2",
	["imgCheng1"] = "imgCheng1",
	["imgCheng2"] = "imgCheng2",
	["atlasLabel1"] = "atlasLabel1",
	["atlasLabel2"] = "atlasLabel2"
}

function ActivityWeeklyCardDialog:onCreate(activityId)
	self.activityId = activityId
	cache.setShader(self.btnBought, false, "hsl_gray")
	self:initModel()
	self:initData()
	self:initTitle()
	gGameModel.currday_dispatch:getIdlerOrigin("newPlayerWeffare"):set(true)
end

-- 初始化model
function ActivityWeeklyCardDialog:initModel()
	self.yyhuodongs = gGameModel.role:getIdler("yyhuodongs")
	self.itemsData = idlertable.new({}) -- 存放 奖励和领取状态
	self.date = idler.new("")        -- 活动时间
	self.buy = idler.new()
	self.notbuy = idler.new()
end

--初始化界面
function ActivityWeeklyCardDialog:initData()
	-- 每日奖励数据
	local weeklycardData = {}
	local yyCfg = csv.yunying.yyhuodong[self.activityId]
	local huodongID = yyCfg.huodongID
	for k, v in csvPairs(csv.yunying.weeklycard) do
		if v.huodongID == huodongID then
			weeklycardData[v.day] = { award = v.award, id = k }
		end
	end

	self.clientBuyTimes = idler.new(true)
	idlereasy.any({ self.yyhuodongs, self.clientBuyTimes }, function(_, yyhuodong)
		local yydata = yyhuodong[self.activityId] or {}
		local itemsData = {}
		for day, wealData in pairs(weeklycardData) do
			if yydata.stamps == nil then
				itemsData[day] = { award = wealData.award, id = wealData.id, getType = GET_TYPE.CAN_NOT_GOTTEN }
			else
				if yydata.stamps[wealData.id] == nil then
					itemsData[day] = { award = wealData.award, id = wealData.id, getType = GET_TYPE.CAN_NOT_GOTTEN }
				else
					itemsData[day] = { award = wealData.award, id = wealData.id, getType = yydata.stamps[wealData.id] }
					if not self.preloadCenter and itemsData[day].getType == GET_TYPE.CAN_GOTTEN then
						self.preloadCenter = day
					end
				end
			end
		end
		self.itemsData:set(itemsData)

		local buyTimes = dataEasy.getPayClientBuyTimes("directBuyData", self.activityId, 0, 0)
		if buyTimes == 0 and yydata.buy == nil then
			self.buy:set(false)
			self.notbuy:set(true)
			self:initCountDown(COUNTDOWN_TYPE.BUY)
		else
			self.buy:set(true)
			self.notbuy:set(false)
			self:initCountDown(COUNTDOWN_TYPE.GET)
		end
	end)
end

--标题
function ActivityWeeklyCardDialog:initTitle()
	local yyCfg = csv.yunying.yyhuodong[self.activityId]
	self.imgGift:hide()

	if yyCfg.clientParam.unitID then
		if self.cardSprite then
			self.cardSprite:removeFromParent()
		end

		local unitCsv = csv.unit[yyCfg.clientParam.unitID]
		if unitCsv and unitCsv.showOpen then
			self.cardSprite = widget.addAnimation(self.heroNode, unitCsv.showOpen, "default", 5, true):scale(0.6)
		end
	end

	self.textTitle:text(yyCfg.clientParam.titleText)

	if matchLanguage({ "en" }) then
		adapt.setTextScaleWithWidth(self.textTitle, nil, 580)
		adapt.setTextScaleWithWidth(self.textCountDown, nil, 230)
	end

	self.imgAward:hide()
	if yyCfg.clientParam.award1 then
		self.imgAward1:show()
		self.imgCheng1:show()
		self.atlasLabel1:show()
		self.imgAward1:texture(yyCfg.clientParam.award1.res)
		self.atlasLabel1:text(yyCfg.clientParam.award1.count)
		self.atlasLabel1:scale(yyCfg.clientParam.award1.scale)
	else
		self.imgAward1:hide()
		self.imgCheng1:hide()
		self.atlasLabel1:hide()
	end

	if yyCfg.clientParam.award2 then
		self.imgAward2:show()
		self.imgCheng2:show()
		self.atlasLabel2:show()
		self.imgAward2:texture(yyCfg.clientParam.award2.res)
		self.atlasLabel2:text(yyCfg.clientParam.award2.count)
		self.atlasLabel2:scale(yyCfg.clientParam.award2.scale)
	else
		self.imgAward2:hide()
		self.imgCheng2:hide()
		self.atlasLabel2:hide()
	end

	local rechargeId = yyCfg.paramMap.recharge
	local rechargeCfg = csv.recharges[rechargeId]
	self.btnBuy:get("textPrice"):text(string.format(gLanguageCsv.symbolMoney, rechargeCfg["rmbDisplay_"..LOCAL_LANGUAGE] or rechargeCfg.rmbDisplay))
	text.addEffect(self.btnBuy:get("textPrice"), { outline = { color = ui.NEWCOLORS.OUTLINE.YELLOW, size = 4 } })
end

--倒计时
function ActivityWeeklyCardDialog:initCountDown(type)
	local textTime = self.textCountDown
	local yyCfg = csv.yunying.yyhuodong[self.activityId]
	local endTime = 0
	if type == COUNTDOWN_TYPE.BUY then
		self.text1:text(gLanguageCsv.sellCountDown)
		-- local hour, min = time.getHourAndMin(yyCfg.beginTime)
		local _, startTime = time.getActivityOpenDate(self.activityId)
		local buyDay = yyCfg.paramMap.buyDay
		endTime = startTime + buyDay * 24 * 60 * 60
		self.text1:show()
		self.textCountDown:show()
	else
		if yyCfg.clientParam.isShowCountDown == false then
			self.text1:hide()
			self.textCountDown:hide()
		end
		self.text1:text(gLanguageCsv.getCountDown)
		local yyEndtime = gGameModel.role:read("yy_endtime")
		if yyEndtime[self.activityId] then
			endTime = yyEndtime[self.activityId]
		end
		-- local hour, min = time.getHourAndMin(yyCfg.endTime)
		-- endTime = time.getNumTimestamp(yyCfg.endDate,hour,min)
	end
	local function setLabel()
		local remainTime = time.getCutDown(endTime - time.getTime())
		textTime:text(remainTime.str)
		if endTime - time.getTime() <= 0 then
			textTime:text(gLanguageCsv.activityOver)
			self:unSchedule(1)
			return false
		end
		return true
	end
	self:enableSchedule()
	self:schedule(function(dt)
		if not setLabel() then
			return false
		end
	end, 1, 0, 1)
end

--初始化list的item
function ActivityWeeklyCardDialog:initItem(list, node, k, itemData)
	local childs = node:multiget("textDay", "btnGet", "list", "imgBg", "imgDayBg", "imgGotten")
	-- 天数
	local dayNum = childs.textDay:setString(k)
	--奖励
	local awards = itemData.award
	local param = {}
	uiEasy.createItemsToList(list, childs.list, awards, param)

	--按钮限时处理
	if itemData.getType == GET_TYPE.CAN_NOT_GOTTEN then
		-- 未达成
		adapt.setTextScaleWithWidth(childs.btnGet:get("textGet"), gLanguageCsv.notReach, 200)
		childs.btnGet:setEnabled(false)
		cache.setShader(childs.btnGet, false, "hsl_gray")
		childs.btnGet:get("textGet"):setTextColor(cc.c4b(255, 252, 237, 255))
		childs.textDay:setTextColor(ui.COLORS.WHITE)
		childs.imgGotten:hide()
	elseif itemData.getType == GET_TYPE.CAN_GOTTEN then
		-- 可领取
		adapt.setTextScaleWithWidth(childs.btnGet:get("textGet"), gLanguageCsv.spaceReceive, 200)
		childs.btnGet:get("textGet"):setTextColor(cc.c4b(255, 252, 237, 255))
		childs.textDay:setTextColor(ui.COLORS.YELLOW)
		childs.btnGet:setEnabled(true)
		childs.imgGotten:hide()
	elseif itemData.getType == GET_TYPE.GOTTEN then
		--已领取
		childs.btnGet:hide()
		childs.textDay:setTextColor(ui.COLORS.WHITE)
		childs.imgGotten:show()
	end
	text.addEffect(childs.btnGet:get("textGet"), { outline = { color = ui.NEWCOLORS.OUTLINE.YELLOW, size = 4 } })

	bind.touch(self, childs.btnGet, { methods = { ended = functools.partial(self.sendGetAward, self, itemData.id) } })
end

-- 发送领取
function ActivityWeeklyCardDialog:sendGetAward(id)
	gGameApp:requestServer("/game/yy/award/get", function(tb)
		gGameUI:showGainDisplay(tb)
	end, self.activityId, id)
end

-- 购买周卡
-- 未购买点击购买；未领取点击领取；已领取显示今日已领取
function ActivityWeeklyCardDialog:buyWeeklyCard()
	local cfg = csv.yunying.yyhuodong[self.activityId]
	local rechargeId = cfg.paramMap.recharge
	gGameApp:payDirect(self,
		{ rechargeId = rechargeId, yyID = self.activityId, csvID = 0, buyTimes = 0, name = cfg.desc },
		self.clientBuyTimes)
		:sdkLongTimeCb()
		:serverCb(function()
			self.buy:set(true)
			self.notbuy:set(false)
		end)
		:doit()
end

return ActivityWeeklyCardDialog
