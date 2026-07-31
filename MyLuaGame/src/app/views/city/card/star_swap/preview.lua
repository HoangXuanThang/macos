local StarTools = require("app.views.city.card.star_swap.tools")
local zawakeTools = require("app.views.city.zawake.tools")
local ViewBase = cc.load("mvc").ViewBase
local StarSwapPreviewView = class("StarSwapPreviewView", ViewBase)
StarSwapPreviewView.RESOURCE_FILENAME = "confirm_preview.json"
StarSwapPreviewView.RESOURCE_BINDING = {
	["centerPanel.rightIcon"] = "rightIcon",
	["centerPanel.leftList"] = "leftList",
	["centerPanel.starItem"] = "starItem",
	["centerPanel.rightList"] = "rightList",
	["bottomPanel.costList"] = "costList",
	["centerPanel.leftIcon"] = "leftIcon",
	closeBtn = {
		binds = {
			event = "touch",
			methods = {
				ended = bindHelper.self("onClose")
			}
		}
	},
	["centerPanel.leftStarList"] = {
		varname = "leftStarList",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				asyncPreload = 6,
				data = bindHelper.self("starLeftDatas"),
				item = bindHelper.self("starItem"),
				onItem = function(list, node, k, v)
					node:get("img"):texture(v.icon)
				end
			}
		}
	},
	["centerPanel.rightStarList"] = {
		varname = "rightStarList",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				asyncPreload = 6,
				data = bindHelper.self("starRightDatas"),
				item = bindHelper.self("starItem"),
				onItem = function(list, node, k, v)
					node:get("img"):texture(v.icon)
				end
			}
		}
	},
	["bottomPanel.confirmBtn"] = {
		varname = "confirmBtn",
		binds = {
			event = "touch",
			methods = {
				ended = bindHelper.self("onConfirm")
			}
		}
	},
	["bottomPanel.text"] = {
		binds = {
			event = "effect",
			data = {
				outline = {
					size = 4,
					color = cc.c4b(66, 61, 66, 255)
				}
			}
		}
	},
	["bottomPanel.confirmBtn.text"] = {
		varname = "confirmText",
		binds = {
			event = "effect",
			data = {
				outline = { color = ui.NEWCOLORS.OUTLINE.YELLOW, size = 4 }
			}
		}
	},
	["topPanel.title"] = {
		binds = {
			event = "effect",
			data = {
				outline = {
					size = 4,
					color = cc.c4b(215, 124, 35, 255)
				}
			}
		}
	},
	["topPanel.tip"] = {
		binds = {
			event = "effect",
			data = {
				outline = {
					size = 4,
					color = cc.c4b(66, 61, 66, 255)
				}
			}
		}
	}
}

function StarSwapPreviewView:onCreate(params)
	self.leftDbId = params.leftDbId
	self.rightDbId = params.rightDbId
	self.onShowCost = params.onShowCost
	self.onExchangeSuccess = params.onExchangeSuccess
	self.onShowAidSuccessAnim = params.onShowAidSuccessAnim
	self.type = params.type
	self.seatId = params.seatId
	self.starLeftDatas = idlertable.new({})
	self.starRightDatas = idlertable.new({})

	self.addTime(self)
	self.cardStarChanged(self)
	self.updateIcon(self)
	self.updateCostList(self)
	self.showText(self)
end

function StarSwapPreviewView:onConfirm()
	if self.isChillDown then
		gGameUI:showTip(gLanguageCsv.starPreviewWait)
		return
	end

	local leftDbId = self.leftDbId
	local rightDbId = self.rightDbId
	local seatId = self.seatId

	if not self.isEnough then
		gGameUI:showTip(gLanguageCsv.starSwapCostNotEnough)
		return
	end

	local leftCard = gGameModel.cards:find(leftDbId)
	local leftCardParam = leftCard:read("card_id", "name", "advance")
	local rightCard = gGameModel.cards:find(rightDbId)
	local rightCardParam = rightCard:read("card_id", "name", "advance")
	local leftNameText = uiEasy.setIconName("card", leftCard:read("card_id"), {
		noColor = true,
		space = true,
		name = leftCardParam.name,
		advance = leftCardParam.advance
	})
	local rightNameText = uiEasy.setIconName("card", rightCard:read("card_id"), {
		noColor = true,
		space = true,
		name = rightCardParam.name,
		advance = rightCardParam.advance
	})

	if self.type == 1 then
		local cdCfg = string.format(gLanguageCsv.hour, csv.card_star_swap_field[seatId].chillDown)

		gGameUI:showDialog({
			isRich = true,
			btnType = 2,
			cb = function()
				gGameApp:requestServer("/game/card/star/swap", function(tb)
					gGameUI:showTip(gLanguageCsv.starAidSuccess)
					self:addCallbackOnExit(functools.partial(self.onShowAidSuccessAnim))
					self:onClose()
				end, seatId, leftDbId, rightDbId, "on")
			end,
			content = string.format(gLanguageCsv.confirmAid, leftNameText, rightNameText, cdCfg),
			dialogParams = {
				clickClose = false
			}
		})
	elseif self.type == 2 then
		local onExchangeSuccess = self.onExchangeSuccess

		gGameUI:showDialog({
			isRich = true,
			btnType = 2,
			cb = function()
				gGameApp:requestServer("/game/card/star/swap", function(tb)
					self:addCallbackOnExit(function()
						onExchangeSuccess()
						gGameUI:stackUI("city.card.star_swap.swap_over", nil, nil, {
							leftDbId = leftDbId,
							rightDbId = rightDbId
						})
					end)
					self:onClose()
				end, 0, leftDbId, rightDbId)
			end,
			content = string.format(gLanguageCsv.confirmExchange, leftNameText, rightNameText),
			dialogParams = {
				clickClose = false
			}
		})
	end
end

function StarSwapPreviewView:addTime()
	local diffTime = 5
	local endTime = time.getTime() + diffTime
	local text1 = self.type == 1 and gLanguageCsv.starAid or gLanguageCsv.starExchange

	uiEasy.setBtnShader(self.confirmBtn, self.confirmText, 3)

	self.isChillDown = true

	self:enableSchedule():schedule(function()
		local nowTime = time.getTime()

		if nowTime == endTime then
			self:unScheduleAll()

			self.isChillDown = false

			uiEasy.setBtnShader(self.confirmBtn, self.confirmText, 1)
			self.confirmText:text(string.format(text1, " "))
			text.addEffect(self.confirmText, { outline = { color = ui.NEWCOLORS.OUTLINE.YELLOW, size = 4 } })
		else
			self.confirmText:text(string.format(text1, "") ..
				gLanguageCsv.symbolBracketLeft .. endTime - nowTime .. gLanguageCsv.symbolBracketRight)
			text.addEffect(self.confirmText, { outline = { color = ui.NEWCOLORS.OUTLINE.YELLOW, size = 4 } })
		end
	end, 1, 0, "PreView")
end

function StarSwapPreviewView:updateCostList()
	local card = gGameModel.cards:find(self.leftDbId)
	local cardCsv = csv.cards[card:read("card_id")]
	local rarity = csv.unit[cardCsv.unitID].rarity
	local leftStar = gGameModel.cards:find(self.leftDbId):read("star")
	local rightStar = gGameModel.cards:find(self.rightDbId):read("star")
	local award, isEnough, costTip = StarTools.getCostList(self.type, rarity, math.max(leftStar, rightStar))
	self.isEnough = isEnough

	uiEasy.createItemsToList(self, self.costList, award, {
		scale = 0.9
	})
end

function StarSwapPreviewView:cardStarChanged()
	local leftStar = gGameModel.cards:find(self.leftDbId):read("star")
	local rightStar = gGameModel.cards:find(self.rightDbId):read("star")
	local data = {
		self.starRightDatas,
		self.starLeftDatas
	}

	for i, v in ipairs({
		leftStar,
		rightStar
	}) do
		data[i]:set(StarTools.getStarData(v))
	end
end

function StarSwapPreviewView:showText()
	for _, f in ipairs({
		self.getStarText,
		-- self.getZawakeText,
	}) do
		local maxHeight = 0
		local panelTb = {}
		local listTb = {
			self.leftList,
			self.rightList
		}

		for k, v in ipairs(listTb) do
			local panel = ccui.Layout:create():size(850, 170)
			local richText = rich.createWithWidth(f(self, k), 44, nil, 850):addTo(panel):name("richText")
			local textHeight = richText:height()

			if maxHeight < textHeight then
				maxHeight = textHeight
			end

			richText:anchorPoint(0, 1):xy(0, maxHeight)
			table.insert(panelTb, panel)
		end

		for i, v in ipairs(listTb) do
			panelTb[i]:height(maxHeight)
			panelTb[i]:get("richText"):y(maxHeight)
			v:setScrollBarEnabled(false):pushBackCustomItem(panelTb[i])
		end
	end
end

function StarSwapPreviewView:getStarText(index)
	local leftCard = gGameModel.cards:find(self.leftDbId)
	local rightCard = gGameModel.cards:find(self.rightDbId)
	local leftStar = leftCard:read("star")
	local rightStar = rightCard:read("star")
	local changeStar = index == 2 and leftStar or rightStar
	local star = index == 1 and leftStar or rightStar
	local text = {
		noEeffect = gLanguageCsv.starNoEffect,
		starAdditionText = gLanguageCsv.starAddition,
		starAdditionMore = gLanguageCsv.starAddition1,
		starAdditionMoreLimit = gLanguageCsv.starAddition2,
		starAdditionMoreLimit1 = gLanguageCsv.starAddition3,
		starAdditionLess = gLanguageCsv.starAddition4
	}
	local str = text.starAdditionText

	if changeStar == 12 then
		if self.type == 1 then
			str = str .. text.starAdditionMoreLimit
		else
			str = str .. text.starAdditionMoreLimit1
		end
	elseif star < changeStar then
		str = str .. text.starAdditionMore
	elseif changeStar < star then
		str = str .. string.format(text.starAdditionLess, changeStar)
	else
		str = str .. text.noEeffect
	end

	return str
end

function StarSwapPreviewView:getZawakeText(index)
	local leftCard = gGameModel.cards:find(self.leftDbId)
	local rightCard = gGameModel.cards:find(self.rightDbId)
	local cardTb = {
		leftCard,
		rightCard
	}
	local leftCardData = leftCard:read("star", "card_id", "advance")
	local rightCardData = rightCard:read("star", "card_id", "advance")
	local changeCardStar = index == 2 and leftCardData.star or rightCardData.star
	local curCardStar = index == 1 and leftCardData.star or rightCardData.star

	local getZawakeID = function()
		local card = cardTb[index]
		local cardId = card:read("card_id")
		local zawakeID = csv.cards[cardId].zawakeID

		if zawakeTools.isOpenByStage(zawakeID) then
			return zawakeID
		end

		return 0
	end

	local curState = 0

	for k = 1, zawakeTools.MAXSTAGE do
		local zawakeId = getZawakeID()

		if zawakeId == 0 then
			break
		end

		local stageCfg = zawakeTools.getStagesCfg(zawakeId, k)
		local needStar = stageCfg.unlockLimit1.star

		if needStar then
			if curCardStar < needStar then
				break
			else
				curState = k
			end
		end
	end

	local changeState = 0

	for k = 1, zawakeTools.MAXSTAGE do
		local zawakeId = getZawakeID()

		if zawakeId == 0 then
			break
		end

		local stageCfg = zawakeTools.getStagesCfg(zawakeId, k)
		local needStar = stageCfg.unlockLimit1.star

		if needStar then
			if changeCardStar < needStar then
				break
			else
				changeState = k
			end
		end
	end

	local text = {
		noEeffect = gLanguageCsv.starNoEffect,
		starZawake = gLanguageCsv.starZawake,
		starZawake1 = gLanguageCsv.starZawake1,
		starZawake2 = gLanguageCsv.starZawake2
	}
	local str = text.starZawake

	if curState == 0 and changeState == 0 or curState == changeState then
		str = str .. text.noEeffect
	elseif curState < changeState then
		str = str .. string.format(text.starZawake1, gLanguageCsv["symbolRome" .. changeState] or changeState)
	elseif changeState < curState then
		str = str .. string.format(text.starZawake2, gLanguageCsv["symbolRome" .. changeState] or changeState)
	end

	return str
end

function StarSwapPreviewView:updateIcon()
	local node = {
		self.leftIcon,
		self.rightIcon
	}

	for i, v in ipairs({
		self.leftDbId,
		self.rightDbId
	}) do
		local card = gGameModel.cards:find(v)
		local cardData = card:read("card_id", "skin_id", "star", "advance", "level", "rarity")
		local unitId = dataEasy.getUnitId(cardData.card_id, cardData.skin_id)
		bind.extend(self, node[i], {
			class = "card_icon",
			props = {
				unitId = unitId,
				advance = cardData.advance,
				rarity = cardData.rarity,
				onNode = function(node)
					node:xy(-50, -60):scale(0.8)
				end,
			}
		})
	end
end

function StarSwapPreviewView:onClose()
	self.addCallbackOnExit(self, self.onShowCost)
	ViewBase.onClose(self)
end

return StarSwapPreviewView
