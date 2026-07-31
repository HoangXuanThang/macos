-- 主题 本命神兽养成

local TitleRes = {
	[98] = "activity/star_upgrade/titleZT.png",
	[99] = "activity/star_upgrade/titleBM.png",
}

local ActivityStarUpgrade = class("ActivityStarUpgrade", Dialog)

ActivityStarUpgrade.RESOURCE_FILENAME = "activity_star_upgrade.json"
ActivityStarUpgrade.RESOURCE_BINDING = {
	["close"] = {
		binds = {
			event = "touch",
			methods = { ended = bindHelper.self("onClose") }
		},
	},
	["titleImage"] = "titleImg",
	["bg.imgBg"] = "imgBg",
	["topPanel.rule"] = {
		varname = "btnRule",
		binds = {
			event = "touch",
			methods = { ended = bindHelper.self("onShowRule") }
		},
	},
	["topPanel.tip"] = "tip",
	["topPanel.slotIcon.pic"] = "slotPic",
	["topPanel.slotIcon.select"] = "slotSelect",
	["topPanel.slotIcon.add"] = {
		varname = "btnSlot",
		binds = {
			event = "touch",
			methods = { ended = bindHelper.self("onShowCustomizeView") }
		},

	},
	["topPanel.title"] = "txtLock",
	["topPanel.btnLock"] = {
		varname = "btnLock",
		binds = {
			event = "touch",
			methods = { ended = bindHelper.self("onLockSprite") }
		},
	},
	["topPanel.timeLabel"] = "timeLabel",
	["panel"] = "panel",
	["center.list"] = {
		varname = "list",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				columnSize = 6,
				data = bindHelper.self("itemsData"),
				item = bindHelper.self("panel"),
				itemAction = {
					isAction = true,
				},
				dataOrderCmp = function(a, b)
					-- if a.isCanBuy ~= b.isCanBuy then
					-- 	return  a.isCanBuy
					-- end
					-- if a.id ~= b.id then
					return a.star < b.star
					-- end
				end,
				onItem = function(list, node, k, v)
					local cfg = v.cfg

					local childs = node:multiget("panelSprite", "panelFree", "itemList", "textContent", "lock")
					childs.textContent:get("bg"):visible(not v.isCanBuy)
					childs.textContent:get("btn"):visible(v.isCanBuy)
					childs.textContent:get("btn"):get("red"):show()
					childs.textContent:get("btn"):get("timesLabel"):text(string.format(gLanguageCsv.foreverLimit,
						v.leftTime, cfg.limit))
					childs.textContent:get("btn"):get("title"):text(string.format(gLanguageCsv.symbolMoney, v.price))

					-- 精灵
					local textStar = childs.panelSprite:get("textStar")
					local imageStar = childs.panelSprite:get("ImageStar")
					if v.star == 0 then
						textStar:hide()
						imageStar:hide()
					else
						textStar:show()
						imageStar:show()
						textStar:text(v.star)
					end
					local unitCsv = csv.unit[v.cardid]
					bind.extend(list, childs.panelSprite:get("iconSprite"), {
						class = "card_icon",
						props = {
							unitId = unitCsv.id,
							rarity = unitCsv.rarity,
							star = v.star,
							params = {
								starScale = 0.85,
								starInterval = 13
							}
						}
					})
					-- 免费的
					local items = {}
					for key, value in pairs(cfg.freeaward) do
						table.insert(items, { key = key, num = value })
					end
					local binds = {
						class = "icon_key",
						props = {
							data = items[1],
						},
					}
					bind.extend(list, childs.panelFree:get("itemfree"), binds)

					local spineNode = childs.panelFree:get("signSpine") -- 签到累积奖励可领取特效
					spineNode:removeChildByName("signSpine") -- 可领取特效

					childs.panelFree:get("mask"):visible(not v.state)
					if not v.lock and v.state then
						spineNode:show()
						widget.addAnimationByKey(spineNode, "effect/wupinguang.skel", 'signSpine', "effect_loop", 99)
							:anchorPoint(cc.p(0.5, 0.5))
							:xy(spineNode:width() / 2, spineNode:height() / 2)
							:scale(2)
						bind.touch(list, spineNode,
							{ clicksafe = false, methods = { ended = functools.partial(list.clickGet, v) } })
					else
						spineNode:hide()
					end

					-- 礼包
					uiEasy.createItemsToList(list, childs.itemList, cfg.item)

					childs.lock:visible(v.lock)
					if not v.lock then
						bind.touch(list, childs.textContent:get("btn"),
							{ clicksafe = false, methods = { ended = functools.partial(list.clickBuy, v) } })
					end
				end,
				asyncPreload = 4,
			},
			handlers = {
				clickBuy = bindHelper.self("clickBuy"),
				clickGet = bindHelper.self("clickGet"),
			}
		}
	},
}

function ActivityStarUpgrade:onCreate(activityId)
	self:initModel()

	self.activityId = activityId
	self.cardStar = 0

	local cfg = csv.yunying.yyhuodong[activityId]

	self.activityType = cfg.type
	self.huodongID = cfg.huodongID

	self.selCardId = idler.new(0)
	self.curCardId = idler.new(0)
	self.showCardId = idler.new(0)

	self.itemsData = idlers.new({})

	self.clientBuyTimes = idler.new(true)

	self.tip:text(gLanguageCsv.shenshoushengxing)

	idlereasy.when(self.showCardId, function(_, showCardId)
		local unitCsv = csv.unit[showCardId]
		if unitCsv then
			bind.extend(self, self.slotPic, {
				class = "card_icon",
				props = {
					unitId = unitCsv.id,
					rarity = unitCsv.rarity,
					params = {
						starScale = 0.85,
						starInterval = 13
					}
				}
			})

			self.slotSelect:removeChildByName("slotAnim")
		end
	end)


	idlereasy.when(self.selCardId, function(_, cardId)
		if cardId > 0 then
			self.btnLock:setEnabled(false)
			self.btnSlot:hide()
		end
	end)

	self.curCardId:addListener(handler(self, "onCurSelectCardChange"))

	-- 主题神兽
	if self.activityType == game.YYHUODONG_TYPE_ENUM_TABLE.limitUpgradeSprite then
		self.selCardId:set(cfg.paramMap.card)
		self.curCardId:set(cfg.paramMap.card)
		self.showCardId:set(cfg.paramMap.card)
		self.btnLock:setEnabled(false)
	else
		local serverData = self.yyhuodongs:read()[activityId]
		local curLockID = 0
		if serverData and serverData.info then
			curLockID = serverData.info['card_id']
		end

		self.cardList = string.split(cfg.paramMap.card, ",")

		if curLockID > 0 then
			self.curCardId:set(curLockID)
			self.selCardId:set(curLockID)
			self.showCardId:set(curLockID)
		else
			self.curCardId:set(tonumber(self.cardList[1]))

			-- 锁定引导
			widget.addAnimationByKey(self.slotSelect, "effect/shouyindao.skel", "slotAnim", "effect_loop", 99)
				:xy(self.slotSelect:width() / 2, self.slotSelect:height() / 2)
		end

		-- 过滤选择的神兽
		self.cusCardIds = {}

		local cardHash = itertools.map(itertools.ivalues(self.fate_card_ids:read()), function(k, v)
			return v or "", k
		end)

		for k, v in pairs(self.cardList) do
			local card_id = tonumber(v)
			local cardCsv = csv.cards[card_id]
			if cardCsv and (not cardHash[card_id]) then
				table.insert(self.cusCardIds, card_id)
			end
		end
	end

	local topBgRes = cfg.clientParam.res or "activity/star_upgrade/bg.png"
	self.imgBg:texture(topBgRes)

	self.titleImg:texture(TitleRes[cfg.type])

	self:initData()
	self:setTimeLabel()

	Dialog.onCreate(self, { blackType = 1 })
end

function ActivityStarUpgrade:getCardStar(cardID)
	local star = 0

	if cardID > 0 then
		local curCardCsv = csv.cards[cardID]
		local cards = self.cards:read()
		for i, v in ipairs(cards) do
			local card = gGameModel.cards:find(v)
			if card then
				local cardData = card:read("card_id", "unit_id", "skin_id", "fighting_point", "level", "star")
				local cardCsv = csv.cards[cardData.card_id]
				if cardCsv.cardMarkID == curCardCsv.cardMarkID then
					star = math.max(star, cardData.star)
				end
			end
		end
	end

	return star
end

function ActivityStarUpgrade:initModel()
	self.cards = gGameModel.role:getIdler("cards")              -- 卡牌
	self.fate_card_ids = gGameModel.role:getIdler("fate_card_ids") -- 卡牌

	self.yyhuodongs = gGameModel.role:getIdler("yyhuodongs")
end

function ActivityStarUpgrade:initData()
	idlereasy.any({ self.yyhuodongs, self.cards }, function(_, yyhuodong)
		local itemData = {}
		itemData       = self:initCsv(yyhuodong[self.activityId])
		self.itemsData:update(itemData, function(v) return v.id end)
	end)
end

function ActivityStarUpgrade:initCsv(serverData)
	local itemsData = {}

	local function getBuyTimes(csvId)
		return serverData and serverData.stamps and serverData.stamps[csvId]
			and (serverData.stamps[csvId] > 0) and serverData.stamps[csvId]
	end

	local function getGetTimes(csvId)
		return serverData and serverData.info and serverData.info[csvId]
			and (serverData.info[csvId] > 0) and serverData.info[csvId]
	end
	local curCardId = self.curCardId:read()

	-- 从配表中获取原始购买数据，然后和服务器选中数组比对，如果数组值不为空，就标记选中
	local curCardStar = self:getCardStar(curCardId)
	self.cardStar = curCardStar

	for key, data in orderCsvPairs(csv.yunying.card_award) do
		if self.huodongID == data.huodongID and curCardId == data.cardid then
			local leftTime = data.limit - (getBuyTimes(key) or 0)

			local getState = getGetTimes(tostring(key)) or 0

			itemsData[key] = {
				id = key,
				csvId = key,
				state = getState < 1,
				cardid = data.cardid,
				star = data.star,
				cfg = data,
				leftTime = leftTime,
				isCanBuy = leftTime > 0,
				lock = curCardStar < data.star,
				price = csv.recharges[data.rechargeID].rmbDisplay
			}
		end
	end
	return itemsData
end

function ActivityStarUpgrade:setTimeLabel()
	self.endTime = gGameModel.role:read("yy_endtime")[self.activityId]
	local timeNum = self.endTime - time.getTime()
	if timeNum < 0 then
		self.timeLabel:text(gLanguageCsv.activityOver)
	end
	self:enableSchedule():schedule(function()
		timeNum = self.endTime - time.getTime()
		local tTime = time.getCutDown(timeNum)
		if timeNum <= 0 then
			self.timeout = true
			self.timeLabel:text(gLanguageCsv.activityOver)
			return false
		else
			local str = ""
			if tTime.day >= 1 then
				str = tTime.str
			else
				str = tTime.clock_str
			end
			self.timeLabel:text(gLanguageCsv.countTime .. str)
			return true
		end
	end, 1, 0)
end

function ActivityStarUpgrade:onShowCustomizeView()
	if not self.cardList or self.selCardId:read() > 0 then
		return
	end

	if #self.cusCardIds == 0 then
		gGameUI:showTip(gLanguageCsv.noshenshou)
		return
	end

	gGameUI:stackUI("city.activity.star_upgrade.customize_sprite", nil, nil, self.cusCardIds,
		self:createHandler("onSelectCard"))
end

function ActivityStarUpgrade:onSelectCard(cardId)
	if not cardId or cardId == 0 then
		return
	end
	self.curCardId:set(cardId)
	self.showCardId:set(cardId)
end

function ActivityStarUpgrade:onCurSelectCardChange()
	local itemData  = {}
	local yyhuodong = self.yyhuodongs:read()
	itemData        = self:initCsv(yyhuodong[self.activityId])
	self.itemsData:update(itemData, function(v) return v.id end)
end

-- 锁定
function ActivityStarUpgrade:onLockSprite()
	local selectID = self.showCardId:read()

	if selectID > 0 then
		gGameUI:showDialog({
			content = gLanguageCsv.jiesuoshengshou,
			cb = function()
				gGameApp:requestServer("/game/fatecard/lock", function(tb)
					local view = tb.view
					local lockId = view.result[self.activityId] or 0
					self.selCardId:set(lockId)
				end, self.activityId, selectID)
			end,
			btnType = 2
		})
	else
		gGameUI:showTip(gLanguageCsv.pleaseSelectSprite)
	end
end

-- 显示规则文本
function ActivityStarUpgrade:onShowRule()
	gGameUI:stackUI("common.rule", nil, nil, self:createHandler("getRuleContext"))
end

function ActivityStarUpgrade:getRuleContext(view)
	local c = adaptContext

	local context = {
		c.clone(view.title, function(item)
			-- item:get("text"):text(csv.note[106])
			item:get("text"):text(gLanguageCsv.zhuanshushengxing)
		end),
		c.noteText(125701, 125805)
	}
	if self.activityType == 99 then
		context[2] = c.noteText(125801, 125806)
	end
	return context
end

function ActivityStarUpgrade:clickBuy(list, v)
	if self.selCardId:read() > 0 then
		gGameApp:payDirect(self,
			{ rechargeId = v.cfg.rechargeID, yyID = self.activityId, csvID = v.csvId, name = v.cfg.name, buyTimes = v
			.cfg.limit }, self.clientBuyTimes)
			:serverCb(function()
				local cfg = csv.yunying.card_award[v.csvId]
				gGameUI:showGainDisplay(cfg.item, { raw = false })
			end)
			:doit()
	else
		gGameUI:showTip(gLanguageCsv.pleaseSelectSprite)
	end
end

function ActivityStarUpgrade:clickGet(list, v)
	if self.selCardId:read() == 0 then
		gGameUI:showTip(gLanguageCsv.pleaseSelectSprite)
		return
	end

	if self.cardStar < v.cfg.star then
		gGameUI:showTip(gLanguageCsv.xingjibuzu)
		return
	end

	gGameApp:requestServer("/game/fatecard/star/freeaward/get", function(tb)
		local cfg = csv.yunying.card_award[v.csvId]
		gGameUI:showGainDisplay(cfg.freeaward, { raw = false })
	end, self.activityId, v.csvId)
end

return ActivityStarUpgrade
