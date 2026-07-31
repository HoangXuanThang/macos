local StarTools = {
	SPROPKEY = 8900,
	SPLUSPROPKEY = 8901,
	isCardAid = function (dbId, curSelDbId, rarity)
		local card = gGameModel.cards:find(dbId)
		local cardCsv = csv.cards[card:read("card_id")]
		local unitCsv = csv.unit[cardCsv.unitID]

		if not dataEasy.getIsStarAidState(dbId) then
			if curSelDbId then
				local selectCard = gGameModel.cards:find(curSelDbId)
				local selectCardCsv = csv.cards[selectCard:read("card_id")]
				local selectUnitCsv = csv.unit[selectCardCsv.unitID]

				if unitCsv.rarity == selectUnitCsv.rarity and selectCard.read(selectCard, "star") ~= card.read(card, "star") then
					return true
				end
			elseif itertools.include(rarity, unitCsv.rarity) then
				return true
			end
		end

		return false
	end
}

function StarTools.isCardExchange(dbId, curSelDbId)
	local card = gGameModel.cards:find(dbId)

	if not dataEasy.getIsStarAidState(dbId) then
		local cardCsv = csv.cards[card.read(card, "card_id")]
		local unitCsv = csv.unit[cardCsv.unitID]

		if curSelDbId then
			local cardStar = card:read("star")
			local selectCard = gGameModel.cards:find(curSelDbId)
			local selectCardStar = selectCard:read("star")
			local selectCardCsv = csv.cards[selectCard:read("card_id")]
			local selectUnitCsv = csv.unit[selectCardCsv.unitID]

			if unitCsv.rarity == selectUnitCsv.rarity and (selectCardStar <= 8 and cardStar > 8 or selectCardStar > 8) and selectCardStar ~= cardStar then
				return true
			end
		else
			local rarity = {
				3,
				4
			}

			if itertools.include(rarity, unitCsv.rarity) then
				local preExchangeNum = gGameModel.role:read("card_star_swap_times")
				local sPropCount = dataEasy.getNumByKey(StarTools.SPROPKEY)
				local sPlusPropCount = dataEasy.getNumByKey(StarTools.SPLUSPROPKEY)

				if preExchangeNum and preExchangeNum[3] then
					sPropCount = sPropCount + preExchangeNum[3]
				else
					sPropCount = sPropCount + gCommonConfigCsv.cardStarSwapRaritySDefaultTimes
				end

				if unitCsv.rarity == 3 and sPropCount > 0 or unitCsv.rarity == 4 and sPlusPropCount > 0 then
					return true
				end

				return false
			end
		end
	end

	return false
end

function StarTools.getSelectCard(from, selDbIds, curSelDbId, seatRarity)
	local result = {}
	local csvTab = csv.cards
	local unitTab = csv.unit
	local cards = gGameModel.role:read("cards")

	for _, v in ipairs(cards) do
		local card = gGameModel.cards:find(v)
		local cardId = card:read("card_id")
		local cardCsv = csvTab[cardId]
		local unitCsv = unitTab[cardCsv.unitID]

		if not itertools.include(selDbIds, v) and cardCsv.megaIndex <= 0 and cardCsv.cardType ~= 2 and (from == 2 and StarTools.isCardExchange(v, curSelDbId) or from == 1 and StarTools.isCardAid(v, curSelDbId, seatRarity)) then
			local skinId = card.read(card, "skin_id")
			local unitId = dataEasy.getUnitId(cardId, skinId)

			table.insert(result, {
				isSel = false,
				id = cardId,
				unitId = unitId,
				rarity = unitCsv.rarity,
				fight = card.read(card, "fighting_point"),
				level = card.read(card, "level"),
				star = card.read(card, "star"),
				advance = card.read(card, "advance"),
				skinId = skinId,
				dbid = v,
				markId = cardCsv.cardMarkID,
				cardType = cardCsv.cardType
			})
		end
	end

	return result
end

function StarTools.getAidCardData(dbId)
	local card = gGameModel.cards:find(dbId)

	if not card then
		return {}
	end

	local cardId = card.read(card, "card_id")
	local csvTab = csv.cards
	local unitTab = csv.unit
	local cardCsv = csvTab[cardId]
	local unitCsv = unitTab[cardCsv.unitID]
	local skinId = card.read(card, "skin_id")
	local unitId = dataEasy.getUnitId(cardId, skinId)
	local t = {
		isSel = false,
		id = cardId,
		unitId = unitId,
		rarity = unitCsv.rarity,
		fight = card.read(card, "fighting_point"),
		level = card.read(card, "level"),
		star = card.read(card, "star"),
		advance = card.read(card, "advance"),
		skinId = skinId,
		dbid = dbId,
		markId = cardCsv.cardMarkID,
		cardType = cardCsv.cardType
	}

	return t
end

function StarTools.getCostList(type, rarity, maxStar)
	type = type == 2 and 0 or 1
	local csvData = csv.card_star_swap_cost
	local data = {}
	local isEnough = true

	for _, v in orderCsvPairs(csvData) do
		if v.type == type and v.rarity == rarity and maxStar == v.reachStar then
			for k, v1 in csvMapPairs(v.costItem) do
				local num = dataEasy.getNumByKey(k)

				table.insert(data, {
					key = k,
					targetNum = v1,
					num = num
				})

				if num < v1 then
					isEnough = false
				end
			end
		end
	end

	return data, isEnough
end

function StarTools.getStarData(star)
	local tb = {}
	local perStage = 6  -- số sao mỗi bậc
    local maxStage = 4  -- vàng, tím, đỏ, mới
    local stage = math.floor((star - 1) / perStage)       -- bậc hiện tại (0 = vàng, 1 = tím...)
    local stageStar = (star - 1) % perStage + 1          -- số sao trong bậc hiện tại
    local starNum = star > 6 and 6 or star               -- hiển thị tối đa 6 sao

    local icons = {
        "common/icon/icon_star.png",   -- vàng
        "common/icon/icon_star_z.png", -- tím
        "common/icon/icon_star_r.png", -- đỏ
        "common/icon/icon_star_s.png", -- mới
    }

    for i = 1, starNum do
        local icon = "city/card/star_swap/icon_star_xjzh.png" -- mặc định sao tắt

        if stage > 0 then
            -- bậc cũ full sáng
            icon = icons[stage] or icons[#icons]
        end

        if i <= stageStar then
            -- sao bậc hiện tại
            icon = icons[stage + 1] or icons[#icons]
        end

        table.insert(tb, { icon = icon })
    end

	return tb
end

function StarTools.getReceiveCount(hadReceived)
	hadReceived = hadReceived or gGameModel.role:read("card_star_swap_times_deliver_record")
	local count = 0

	for id, v in orderCsvPairs(csv.card_star_swap_times_deliver) do
		if not hadReceived or not hadReceived[id] then
			local hour, min = time.getHourAndMin(v.time)
			local effectTime = time.getNumTimestamp(v.date, hour, min)
			local endTime = time.getNumTimestamp(v.endDate, hour, min)
			local vipLevel = gGameModel.role:read("vip_level")
			local roleLevel = gGameModel.role:read("level")
			local nowTime = time.getTime()

			if v.type == 3 then
				local createRoleTime = gGameModel.role:read("created_time")
				local startRoleTime = time.getNumTimestamp(v.validRoleCreatedEarliestDate)
				local endRoleTime = time.getNumTimestamp(v.validRoleCreatedLatestDate)

				if v.param <= roleLevel and nowTime <= endTime and effectTime <= nowTime and createRoleTime <= endRoleTime and startRoleTime <= createRoleTime then
					count = count + 1
				end
			elseif v.type == 2 then
				if v.param <= roleLevel and effectTime <= nowTime and nowTime <= endTime then
					count = count + 1
				end
			elseif v.type == 1 and v.param <= vipLevel and effectTime <= nowTime and nowTime <= endTime then
				count = count + 1
			end
		end
	end

	return count
end

return StarTools
