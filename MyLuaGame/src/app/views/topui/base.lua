-- @desc: topui 通用函数定义
local YY_TYPE = game.YYHUODONG_TYPE_ENUM_TABLE

local staminaInput = {}
staminaInput.RESOURCE_FILENAME = "topui_stamina_recover.json"
staminaInput.RESOURCE_BINDING = {
	["nextRecover"] = "nextRecover",
	["allRecover"] = "allRecover",
	["buyTimes1"] = "buyTimes1",
	["buyTimes2"] = "buyTimes2",
}

local TopuiBase = class("TopuiBase", cc.load("mvc").ViewBase)

function TopuiBase:onCreate(data, params)
	-- 统一适配
	local node = self:getResourceNode()
	if node:get("leftTopPanel") then
		adapt.dockWithScreen(node:get("leftTopPanel"), "left", "up", false)
	end
	if node:get("rightTopPanel") then
		adapt.dockWithScreen(node:get("rightTopPanel"), "right", "up", false)
		node:get("rightTopPanel"):x(node:get("rightTopPanel"):x() - 30)
	end
	if node:get("rightTopClosePanel") then
		adapt.dockWithScreen(node:get("rightTopClosePanel"), "right", "up", false)
		node:get("rightTopClosePanel"):x(node:get("rightTopClosePanel"):x() - 30)
	end

	params = params or {}
	if matchLanguage({"en"}) then
		params.subTitle = ""
	end
	for _, name in ipairs(data) do
		if name == "stamina" then
			self:staminaInit()
		elseif name == "title" then
			self:updateTitle(params.title, params.subTitle)
		end
	end
end

function TopuiBase:staminaInit()
	self.stamina = gGameModel.role:getIdler("stamina")
	self.level = gGameModel.role:getIdler("level")
	self.staminaLRT = gGameModel.role:getIdler("stamina_last_recover_time")
	self.vipLevel = gGameModel.role:getIdler("vip_level")
	self.buyStaminaTimes = gGameModel.daily_record:getIdler("buy_stamina_times")
	self.yyhuodongs = gGameModel.role:getIdler("yyhuodongs")
	self.trainerLevel = gGameModel.role:getIdler("trainer_level")
	self.showStamina = idler.new(0)
	self.showStaminaMax = idlereasy.any({self.level, self.yyhuodongs, self.trainerLevel}, function(_, level, yyhuodongs, trainerLevel)
		return true, dataEasy.getStaminaMax(level, trainerLevel)
	end)
	self:enableSchedule()

	-- 常驻定时器，若体力值idler不一致，触发
	self:schedule(function()
		self.showStamina:set(dataEasy.getStamina())
	end, 1, 1)

	idlereasy.any({self.stamina, self.showStaminaMax, self.staminaLRT}, function (_, stamina, showStaminaMax, staminaLRT)
		self.showStamina:set(dataEasy.getStamina())
	end)
	idlereasy.any({self.showStamina, self.showStaminaMax, self.staminaLRT}, function(_, showStamina, showStaminaMax, staminaLRT)
		self.staminaText:text(showStamina)
		self.staminaMaxText:text("/" .. showStaminaMax)
		self:unSchedule(1)
		if showStamina <= showStaminaMax then
			text.deleteEffect(self.staminaText, {"outline"})
			text.addEffect(self.staminaText, {color = ui.NEWCOLORS.WHITE})

			-- 体力恢复定时器
			if showStamina < showStaminaMax then
				local dt = time.getTime() - staminaLRT
				local nextRecoverTime = game.STAMINA_COLD_TIME - dt % game.STAMINA_COLD_TIME
				self:schedule(function()
					self:unSchedule(1)
					showStamina = dataEasy.getStamina()
					self.showStamina:set(showStamina)
				end, game.STAMINA_COLD_TIME, nextRecoverTime, 1)
			end
		else
			text.addEffect(self.staminaText, {color = ui.NEWCOLORS.GREEN2})
		end
		adapt.oneLineCenterPos(cc.p(192, 50), {self.staminaText, self.staminaMaxText})
	end)

	-- 体力长按显示内容
	self.staminaInfo = gGameUI:createSimpleView(staminaInput, self):init():hide()
	local pos = gGameUI:getConvertPos(self.staminaPanel)
	local staminaNode = self.staminaInfo:getResourceNode()
	local size = staminaNode:size()
	local staminaPanelSize = self.staminaPanel:size()
	self.staminaInfo:xy(pos.x - size.width + staminaPanelSize.width/2 - display.uiOrigin.x, pos.y - size.height - staminaPanelSize.height/2)

	-- 多指触控会导致 touch ended 被吞掉，界面卡住无法操作
	local pos = gGameUI:getConvertPos(self.staminaInfo)
	local panel = ccui.Layout:create()
		:anchorPoint(0, 0)
		:size(display.sizeInView)
		:xy(-pos.x - display.uiOrigin.x * 2, -pos.y)
		:addTo(self.staminaInfo, -1)
	panel:setTouchEnabled(true)
	panel:onClick(function()
		self.staminaInfo:hide()
		gGameUI:unModal(self.staminaInfo)
	end)

	local function setLabel(t)
		if t <= 0 then
			self.staminaInfo.nextRecover:text(gLanguageCsv.staminaFull)
			self.staminaInfo.allRecover:text(gLanguageCsv.staminaFull)
			text.addEffect(self.staminaInfo.nextRecover, {color = ui.NEWCOLORS.GREEN2})
			text.addEffect(self.staminaInfo.allRecover, {color = ui.NEWCOLORS.GREEN2})
		else
			self.staminaInfo.nextRecover:text(time.getCutDown(t % game.STAMINA_COLD_TIME).str)
			self.staminaInfo.allRecover:text(time.getCutDown(t).str)
			text.addEffect(self.staminaInfo.nextRecover, {color = ui.NEWCOLORS.WHITE})
			text.addEffect(self.staminaInfo.allRecover, {color = ui.NEWCOLORS.WHITE})
		end
	end
	idlereasy.any({self.showStamina, self.showStaminaMax, self.staminaLRT}, function (_, showStamina, showStaminaMax, staminaLRT)
		self:unSchedule(2)
		if showStamina >= showStaminaMax then
			setLabel(0)
		else
			local dt = time.getTime() - staminaLRT
			local nextRecoverTime = game.STAMINA_COLD_TIME - dt % game.STAMINA_COLD_TIME
			local allRecoverTime = (showStaminaMax - showStamina - 1) * game.STAMINA_COLD_TIME + nextRecoverTime
			setLabel(allRecoverTime)
			self:schedule(function()
				allRecoverTime = allRecoverTime - 1
				setLabel(allRecoverTime)
				if allRecoverTime <= 0 then
					return false
				end
			end, 1, 1, 2)
		end
	end)
	idlereasy.any({self.vipLevel, self.buyStaminaTimes}, function(_, vipLevel, buyStaminaTimes)
		self.staminaInfo.buyTimes1:text(buyStaminaTimes)
		self.staminaInfo.buyTimes2:text("/" .. gVipCsv[vipLevel].buyStaminaTimes)
		adapt.oneLinePos(self.staminaInfo.buyTimes1, self.staminaInfo.buyTimes2, nil, "left")
		if buyStaminaTimes > 0 then
			text.addEffect(self.staminaInfo.buyTimes1, {color = ui.NEWCOLORS.GREEN2})
		else
			text.addEffect(self.staminaInfo.buyTimes1, {color = ui.NEWCOLORS.WHITE})
		end
	end)
end

function TopuiBase:updateTitle(title, subTitle)
	self.titleText:text(title or "")
	self.subTitleText:text(subTitle or "")
	adapt.oneLinePos(self.titleText, self.subTitleText, cc.p(15, 0))
end

function TopuiBase:onGoldClick()
	gGameUI:stackUI("common.gain_gold")
end

function TopuiBase:onFereClothClipClick()
	
end

function TopuiBase:onFereVideoClipClick()
	
end

function TopuiBase:onDiamondClick()
	if not gGameUI:goBackInStackUI("city.recharge") then
		gGameUI:stackUI("city.recharge", nil, {full = true})
	end
end

function TopuiBase:sendRequestBuyItem(itemId, num)
	gGameApp:requestServer("/game/buy_item", function(tb)
		gGameUI:showTip(gLanguageCsv.hasBuy)
	end, itemId, num)
end

-- 钻石抽卡代金券
function TopuiBase:onRmbCardClick()
	local itemId = game.ITEM_TICKET.rmbCard
	local cfg = csv.items[itemId]
	local buyStr, cost = csvNext(cfg.specialArgsMap)
	gGameUI:stackUI("common.buy_info", nil, nil,
		{rmb = cost},
		{
			id = itemId,
		},
		{
			contentType = "num",
		},
		self:createHandler("sendRequestBuyItem", itemId))
end

function TopuiBase:onSkinCardClick()
	--gGameUI:stackUI("city.activity.direct_buy_gift", nil, {full = true})
	local confirmGoWeb = function()
		local username = cc.UserDefault:getInstance():getStringForKey("username", "")
		local url = "https://nap.bavuongdaichien.com/topup.php?username=" .. username
		if device.platform == "ios" then
			sdk.openUrl(url, function(info) 
				print("opennnnnnnnn ", info) 
				cb(0, "ok") 
			end)
		else
			cc.Application:getInstance():openURL(url)
		end
	end
	local params = {
		cb = confirmGoWeb,
		isRich = false,
		btnType = 2,
		content = gLanguageCsv.goToRecharge,
		dialogParams = {clickClose = false}
	}
	gGameUI:showDialog(params)

	-------for aab store-------
	-- if not gGameUI:goBackInStackUI("city.recharge") then
	-- 	gGameUI:stackUI("city.recharge", nil, {full = true})
	-- end
	
	-- Open popup recharge---
	-- local success, err = pcall(function()
    --     if gGameUI:findStackUI("city.activity.pop_up_recharge") then
    --         print("city.activity.pop_up_recharge đã có trong stack, không mở lại")
    --         return
    --     end
    --     gGameUI:stackUI("city.activity.pop_up_recharge", nil, { blackType = 1 })
    -- end)
    
end


-- 金币抽卡代金券
function TopuiBase:onGoldCardClick()
	local itemId = game.ITEM_TICKET.goldCard
	local cfg = csv.items[itemId]
	local buyStr, cost = csvNext(cfg.specialArgsMap)
	gGameUI:stackUI("common.buy_info", nil, nil,
		{gold = cost},
		{
			id = itemId,
		},
		{
			contentType = "num",
		},
		self:createHandler("sendRequestBuyItem", itemId))
end


-- 限时抽卡代金券
function TopuiBase:onLimitCardClick()
	local itemId = game.ITEM_TICKET.limitCard
	local cfg = csv.items[itemId]
	local buyStr, cost = csvNext(cfg.specialArgsMap)
	gGameUI:stackUI("common.buy_info", nil, nil,
		{rmb = cost},
		{
			id = itemId,
		},
		{
			contentType = "num",
		},
		self:createHandler("sendRequestBuyItem", itemId))
end

-- 装备抽卡代金券
function TopuiBase:onEquipCardClick()
	local itemId = game.ITEM_TICKET.equipCard
	local cfg = csv.items[itemId]
	local buyStr, cost = csvNext(cfg.specialArgsMap)
	gGameUI:stackUI("common.buy_info", nil, nil,
		{rmb = cost},
		{
			id = itemId,
		},
		{
			contentType = "num",
		},
		self:createHandler("sendRequestBuyItem", itemId))
end

-- 限时轮换抽卡
function TopuiBase:onDiamondUpCardClick()
	local itemId = game.ITEM_TICKET.diamondUpCard
	local cfg = csv.items[itemId]
	local buyStr, cost = csvNext(cfg.specialArgsMap)
	gGameUI:stackUI("common.buy_info", nil, nil,
		{rmb = cost},
		{
			id = itemId,
		},
		{
			contentType = "num",
		},
		self:createHandler("sendRequestBuyItem", itemId))
end

-- 通用购买代券
function TopuiBase:buyTickets(key, costType)
	local itemId = game.ITEM_TICKET[key]
	local cfg = csv.items[itemId]
	local buyStr, cost = csvNext(cfg.specialArgsMap)
	gGameUI:stackUI("common.buy_info", nil, nil,
		{[costType] = cost},
		{
			id = itemId,
		},
		{
			contentType = "num",
		},
		self:createHandler("sendRequestBuyItem", itemId))
end


function TopuiBase:onStaminaLongTouch(node, event)
	if event.name == "click" then
		self:onStaminaClick()

	elseif event.name == "began" then
		self.staminaInfo:show()
		gGameUI:doModal(self.staminaInfo)

	elseif event.name == "ended" or event.name == "cancelled" then
		self.staminaInfo:hide()
		gGameUI:unModal(self.staminaInfo)
	end
end

function TopuiBase:onStaminaClick()
	gGameUI:stackUI("common.gain_stamina")
end

function TopuiBase:onluckyEggCardClick()
	local itemId = game.ITEM_TICKET.luckyEggCard
	local cfg = csv.items[itemId]
	local buyStr, cost = csvNext(cfg.specialArgsMap)
	gGameUI:stackUI("common.buy_info", nil, nil,
		{rmb = cost},
		{
			id = itemId,
		},
		{
			contentType = "num",
		},
		self:createHandler("sendRequestBuyItem", itemId))
end

function TopuiBase:onUnionCoinClick()
	if dataEasy.notUseUnionBuild() then
		gGameUI:showTip(gLanguageCsv.cannotUseBuilding)
		return
	end
	gGameUI:stackUI("city.union.contrib.view")
end

function TopuiBase:onDrawcardCoinClick()
	if not gGameUI:goBackInStackUI("city.drawcard.view") then
		gGameUI:stackUI("city.drawcard.view", nil, {full = true}, "equip")
	end
end

function TopuiBase:onFragmentCoinClick()
	local isUnlock = dataEasy.isUnlock(gUnlockCsv.cardReborn)
	if not isUnlock then
		gGameUI:showTip(dataEasy.getUnlockTip(gUnlockCsv.cardReborn))
		return
	end
	if not gGameUI:goBackInStackUI("city.card.rebirth.view") then
		gGameUI:stackUI("city.card.rebirth.view", nil, {full = true}, 1, 2)
	end
end

function TopuiBase:onPvpCoinClick()
	local isUnlock = dataEasy.isUnlock(gUnlockCsv.arena)
	if not isUnlock then
		gGameUI:showTip(dataEasy.getUnlockTip(gUnlockCsv.arena))
		return
	end
	if not gGameUI:goBackInStackUI("city.pvp.arena.view") then
		gGameApp:requestServer("/game/pw/battle/get", function(tb)
			gGameUI:stackUI("city.pvp.arena.view")
		end)
	end
end

function TopuiBase:onUnionCombetClick()
	local roleLv = gGameModel.role:read("level")
	local unionLv = gGameModel.union:read("level")
	for k,v in orderCsvPairs(csv.sysopen) do
		if (v.goto == "unionFight") then
			if not dataEasy.isUnlock(v.feature) then
				gGameUI:showTip(dataEasy.getUnlockTip(v.feature))
				return
			end
			if unionLv < v.unionlevel then
				gGameUI:showTip(gLanguageCsv.unionLevelLessNoOpened)
				return
			end
			jumpEasy.jumpTo("unionFight")
			return
		end
	end
end

function TopuiBase:onExplorerCoinClick()
	local isUnlock = dataEasy.isUnlock(gUnlockCsv.explorer)
	if not isUnlock then
		gGameUI:showTip(dataEasy.getUnlockTip(gUnlockCsv.explorer))
		return
	end
	if not gGameUI:goBackInStackUI("city.develop.explorer.view") then
		gGameUI:stackUI("city.develop.explorer.view", nil, {full = true})
	end
end

function TopuiBase:onRandomTowerCoinClick()
	local isUnlock = dataEasy.isUnlock(gUnlockCsv.randomTower)
	if not isUnlock then
		gGameUI:showTip(dataEasy.getUnlockTip(gUnlockCsv.randomTower))
		return
	end
	if not gGameUI:goBackInStackUI("city.adventure.random_tower.view") then
		gGameApp:requestServer("/game/random_tower/prepare", function (tb)
			gGameUI:stackUI("city.adventure.random_tower.view", nil, {full = true})
		end)
	end
end

function TopuiBase:onCraftCoinClick()
	jumpEasy.jumpTo("craft")
end

function TopuiBase:onCoinClick()
	-- gGameUI:showTip(gLanguageCsv.upgradeLevelToGetCoins)	--语言添加
end

function TopuiBase:onVipCoinClick()
	-- local passport = gGameModel.role:read("passport")
	-- self.buyHigh = itertools.size(passport.buy) > 0
	-- -- local content = 0
	-- -- local yyCfg = csv.yunying.yyhuodong[self.activityId]
	-- -- if yyCfg.endDate - time.getTime() < 14 * 24 * 3600 then
	-- -- 	content = gLanguageCsv.passwordBuyVipTips		--语言添加
	-- -- else
	-- -- 	content = gLanguageCsv.passwordBuyVipNote
	-- -- end
	-- if self.buyHigh then
	-- 	gGameUI:showTip(gLanguageCsv.upgradeLevelToGetVipCoins)
	-- else
	-- 	local buyVip = function()
	-- 		gGameUI:stackUI("city.activity.passport.buy", nil, nil, self.activityId)
	-- 	end
	-- 	-- local content = gLanguageCsv.passwordBuyVipNote
	-- 	-- local yyCfg = csv.yunying.yyhuodong[self.activityId]
	-- 	-- if yyCfg.endDate - time.getTime() < 14 * 24 * 3600 then
	-- 	-- 	content = gLanguageCsv.passwordBuyVipTips		--语言添加
	-- 	-- else
	-- 	-- 	content = gLanguageCsv.passwordBuyVipNote
	-- 	-- end
	-- 	local params = {
	-- 		cb = buyVip,
	-- 		isRich = true,
	-- 		btnType = 2,
	-- 		content = gLanguageCsv.passwordBuyVipNote, 	--语言添加
	-- 		dialogParams = {clickClose = false},
	-- 	}
	-- 	gGameUI:showDialog(params)
	-- end
end

--精灵球点击
function TopuiBase:onBallClick(sender)
	local senderName = sender:getName()
	if senderName == "ballPanel1" then
		local gold = csv.items[game.SPRITE_BALL_ID.normal].specialArgsMap.buy_gold
		local roleGold = gGameModel.role:read("gold")
		gGameUI:stackUI("common.buy_info", nil, nil,
			{gold = gold},
			{id = game.SPRITE_BALL_ID.normal},
			{contentType = "num"},
			self:createHandler("showBuyInfo"))
	elseif senderName == "ballPanel2" then
		--超级球跳转精选商店
		if not gGameUI:goBackInStackUI("city.shop") then
			gGameApp:requestServer("/game/fixshop/get", function(tb)
				gGameUI:stackUI("city.shop", nil, {full = true}, game.SHOP_INIT.FIX_SHOP)
			end)
		end
	else
		--大师球
		gGameUI:showTip(string.format(gLanguageCsv.getInActOrMysteryShop))
	end
end

function TopuiBase:onCrossCraftCoinClick()
	jumpEasy.jumpTo("crossCraft")
end

function TopuiBase:onCrossArenaCoinClick()
	jumpEasy.jumpTo("crossArena")
end

function TopuiBase:onCrossMineCoinClick()
	if not self.sign then
		jumpEasy.jumpTo("crossMine")
	end
end

function TopuiBase:onCrossSupremacyCoinClick()
	if not self.sign then
		jumpEasy.jumpTo("crossSupremacy")
	end
end

function TopuiBase:showBuyInfo(count)
	--等级是否满足购买道具
	if csv.items[game.SPRITE_BALL_ID.normal].specialArgsMap.buy_level > gGameModel.role:read("level") then
		gGameUI:showTip(gLanguageCsv.buyItemLevelLimit)
		return
	else
		gGameApp:requestServer("/game/ball/buy_item", function(tb)
			gGameUI:showTip(gLanguageCsv.hasBuy)
		end, game.SPRITE_BALL_ID.normal, count)
	end
end

function TopuiBase:onOnlineFightCoinClick()
	jumpEasy.jumpTo("onlineFight")
end

function TopuiBase:onHeldShopCoinClick()
	if not self.sign then
		gGameUI:stackUI("city.activity.direct_buy_gift", nil, {full = true})
	end
end

-- 圣诞
function TopuiBase:onItem97CoinClick()
	-- 礼包
	local activityId = dataEasy.getActivityIdInYYOPEN(game.YYHUODONG_TYPE_ENUM_TABLE.directBuyGift, game.DIRECT_GIFT.CHRISTMAS)
	if activityId then
		gGameUI:stackUI("city.activity.christmas.gift", nil, nil, activityId)
	end
end

--主题英雄
function TopuiBase:onItemWHJLPClick()
	local _, viewName = gGameUI:getTopStackUI()
	if viewName == "city.activity.zhuti_yingxiong.shop" then
	   return
	end
	local activityId = dataEasy.getActivityIdInYYOPEN(game.YYHUODONG_TYPE_ENUM_TABLE.directBuyGift, game.DIRECT_GIFT.ZHUTI_YINGXIONG_SHOP)
	if activityId then
		gGameUI:stackUI("city.activity.zhuti_yingxiong.shop", nil, {blackLayer = true}, activityId)
	end
end

function TopuiBase:onItemExp1CoinClick()
	-- 礼包
	local _, viewName = gGameUI:getTopStackUI()
	if viewName == "city.activity.jiu_wei.gift" then
	   return
	end
    local activityId = dataEasy.getActivityIdInYYOPEN(game.YYHUODONG_TYPE_ENUM_TABLE.directBuyGift, game.DIRECT_GIFT.THEME_JIU_WEI_GIFT)
    if activityId then
        gGameUI:stackUI("city.activity.jiu_wei.gift", nil, {blackLayer = true}, activityId)
    end
end
function TopuiBase:onItemExp2CoinClick()
	-- 兑换
	local activityId = dataEasy.getActivityIdInYYOPEN(game.YYHUODONG_TYPE_ENUM_TABLE.itemExchange, game.EXCHANGE_IND.IDX_JIU_WEI)
    if activityId then
        gGameUI:stackUI("city.activity.jiu_wei.exchange", nil, {blackLayer = true}, activityId)
    end
end

-- 龙魂水晶
function TopuiBase:onItem94CoinClick()
	-- 兑换
	local activityId = dataEasy.getActivityIdInYYOPEN(game.YYHUODONG_TYPE_ENUM_TABLE.itemExchange, 2)
    if activityId then
        gGameUI:stackUI("city.activity.theme_skin.exchange", nil, { blackLayer = true }, activityId)
    end
end

-- 祈愿星魂
function TopuiBase:onItem95CoinClick()
	-- 礼包
	local activityId = dataEasy.getActivityIdInYYOPEN(game.YYHUODONG_TYPE_ENUM_TABLE.directBuyGift, game.DIRECT_GIFT.THEME_SKIN_GIFT)
    if activityId then
        gGameUI:stackUI("city.activity.theme_skin.gift", nil, { blackLayer = true }, activityId)
    end
end

function TopuiBase:onCoin105Click()
	-- 礼包
	local _, viewName = gGameUI:getTopStackUI()
	if viewName == "city.activity.monopoly.gift" then
	   return
	end
    local activityId = dataEasy.getActivityIdInYYOPEN(game.YYHUODONG_TYPE_ENUM_TABLE.directBuyGift, game.DIRECT_GIFT.MONOPOLY_GIFT)
    if activityId then
        gGameUI:stackUI("city.activity.monopoly.gift", nil, {blackLayer = true}, activityId)
    end
end

function TopuiBase:onCoin106Click()
	local _, viewName = gGameUI:getTopStackUI()
	if viewName == "city.activity.monopoly.exchange" then
	   return
	end
	-- 兑换
	local activityId = dataEasy.getActivityIdInYYOPEN(game.YYHUODONG_TYPE_ENUM_TABLE.itemExchange, game.EXCHANGE_IND.IDX_MONOPOLY)
    if activityId then
        gGameUI:stackUI("city.activity.monopoly.exchange", nil, {blackLayer = true}, activityId)
    end
end

function TopuiBase:onCoin107Click()
	-- 礼包
	local _, viewName = gGameUI:getTopStackUI()
	if viewName == "city.activity.throne_draw.shop" then
	   return
	end
    local activityId = dataEasy.getActivityIdInYYOPEN(game.YYHUODONG_TYPE_ENUM_TABLE.directBuyGift, game.DIRECT_GIFT.THRONE_DRAW)
    if activityId then
        gGameUI:stackUI("city.activity.throne_draw.shop", nil, {blackLayer = true}, activityId)
    end
end

function TopuiBase:onCoin108Click()
	local _, viewName = gGameUI:getTopStackUI()
	if viewName == "city.activity.throne_draw.exchange" then
	   return
	end
	-- 兑换
	local activityId = dataEasy.getActivityIdInYYOPEN(game.YYHUODONG_TYPE_ENUM_TABLE.itemExchange, game.EXCHANGE_IND.THRONE_DRAW)
    if activityId then
        gGameUI:stackUI("city.activity.throne_draw.exchange", nil, {blackLayer = true}, activityId)
    end
end

function TopuiBase:onCoin113Click()
	-- 礼包
	local _, viewName = gGameUI:getTopStackUI()
	if viewName == "city.activity.draw_active.gift" then
	   return
	end
	local activityId = dataEasy.getActivityIdInYYOPEN(YY_TYPE.directBuyGift, game.DIRECT_GIFT.DRAW_HELDITEM)
    if activityId then
        gGameUI:stackUI("city.activity.draw_active.gift", nil, { blackLayer = true }, activityId, YY_TYPE.drawLimitHelditem)
    end
end

function TopuiBase:onCoin114Click()
	local _, viewName = gGameUI:getTopStackUI()
	if viewName == "city.activity.draw_active.exchange" then
	   return
	end
	-- 兑换
	local activityId = dataEasy.getActivityIdInYYOPEN(YY_TYPE.itemExchange, game.EXCHANGE_IND.DRAW_HELDITEM)
    if activityId then
        gGameUI:stackUI("city.activity.draw_active.exchange", nil, { blackLayer = true }, activityId, YY_TYPE.drawLimitHelditem)
    end
end

function TopuiBase:onCoin115Click()
	-- 礼包
	local _, viewName = gGameUI:getTopStackUI()
	if viewName == "city.activity.draw_active.gift" then
	   return
	end
	local activityId = dataEasy.getActivityIdInYYOPEN(YY_TYPE.directBuyGift, game.DIRECT_GIFT.DRAW_EXPLOR)
    if activityId then
        gGameUI:stackUI("city.activity.draw_active.gift", nil, { blackLayer = true }, activityId, YY_TYPE.drawLimitExplor)
    end
end

function TopuiBase:onCoin116Click()
	local _, viewName = gGameUI:getTopStackUI()
	if viewName == "city.activity.draw_active.exchange" then
	   return
	end
	-- 兑换
	local activityId = dataEasy.getActivityIdInYYOPEN(YY_TYPE.itemExchange, game.EXCHANGE_IND.DRAW_EXPLOR)
    if activityId then
        gGameUI:stackUI("city.activity.draw_active.exchange", nil, { blackLayer = true }, activityId, YY_TYPE.drawLimitExplor)
    end
end

return TopuiBase