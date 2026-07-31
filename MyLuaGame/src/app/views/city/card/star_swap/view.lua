--

local StarTools = require("app.views.city.card.star_swap.tools")
local ViewBase = cc.load("mvc").ViewBase
local StarSwapView = class("StarSwapView", ViewBase)
local TABDATA = {
	{
		-- 永久
		type = 2,
		name = gLanguageCsv.starExchange1,
		unlockKey = gUnlockCsv.cardStarSwap
	},
	-- {
	-- 	-- 临时
	-- 	type = 1,
	-- 	name = gLanguageCsv.starAid1,
	-- 	unlockKey = gUnlockCsv.cardStarTemporarySwap
	-- }

}
StarSwapView.RESOURCE_FILENAME = "star_rating_main.json"
StarSwapView.RESOURCE_BINDING = {
	["leftPanel.item"] = "leftItem",
	["centerPanel.btnLeft.iconLeft"] = "iconLeft",
	["centerPanel.btnRight.iconRight"] = "iconRight",
	["tabPanel.item"] = "tabItem",
	["centerPanel.rightLight"] = "rightLight",
	["centerPanel"] = "centerPanel",
	["centerPanel.starItem"] = "starItem",
	["leftPanel.exchangePanel.downPanel"] = "exchangeDownPanel",
	["tabPanel.awardPanel"] = "awardPanel",
	["centerPanel.rightBottom"] = "rightBottom",
	["leftPanel.aidPanel"] = "aidLeftPanel",
	["centerPanel.leftLight"] = "leftLight",
	["centerPanel.leftBottom"] = "leftBottom",
	["centerPanel.buttom"] = "centerBottom",
	["leftPanel.exchangePanel"] = "exchangeLeftPanel",
	["centerPanel.buttom.consumeList"] = "costList",
	["leftPanel.aidPanel.list"] = {
		varname = "leftList",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("leftListData"),
				item = bindHelper.self("leftItem"),
				itemAction = {
					isAction = true
				},
				onItem = function(list, node, k, v)
					node:get("selImg"):visible(v.isSel)
					node:get("clickPanel"):visible(not v.isSel)
					node:get("bg1"):visible(v.isAiding)

					local realTime = time.getTime()

					node:get("chillDown"):visible(realTime < v.chillDown)

					if csvSize(v.rarities) == 1 then
						if v.rarities[1] == 3 then
							node:get("iconPanel.icon2"):hide()
							node:get("iconPanel.icon1"):y(node:get("iconPanel.icon1"):y() - 40)
						elseif v.rarities[1] == 4 then
							node:get("iconPanel.icon1"):hide()
							node:get("iconPanel.icon2"):y(node:get("iconPanel.icon2"):y() + 45)
						end
					end

					node:get("lock"):visible(not v.vipLevelEnough)
					node:get("vipTip"):visible(not v.vipLevelEnough):text(string.format(gLanguageCsv.aConditionsUnlock,
						uiEasy.getVipStr(v.unlockParam).str))

					local spriteTb = {
						node:get("content.leftBg"),
						node:get("content.rightBg")
					}
					local emptySprite = {
						node:get("content.leftEmpty"),
						node:get("content.rightEmpty")
					}

					for i = 1, 2 do
						local clipping = spriteTb[i]:get("clipping")
						local logo = clipping and clipping:get("logo")
						local data = v.iconData[i] or {}

						if itertools.size(data) == 0 and logo then
							logo.removeSelf(logo)
						end

						local size = spriteTb[i]:size()

						if not clipping then
							local mask = cc.Sprite:create("city/card/star_swap/box_xjjh_tx.png"):alignCenter(size)
							clipping = cc.ClippingNode:create(mask):setAlphaThreshold(0.1):size(size):alignCenter(size)
								:addTo(spriteTb[i], 3, "clipping")
						end

						if itertools.size(data) > 0 then
							local unitCfg = dataEasy.getUnitCsv(data.id, data.skinId)

							if not logo then
								ccui.ImageView:create(unitCfg.cardIcon):alignCenter(size):scale(1.5):addTo(clipping, 3,
									"logo")
							else
								logo.texture(logo, unitCfg.cardIcon)
							end

							emptySprite[i]:hide()
							spriteTb[i]:show()
						else
							emptySprite[i]:visible(v.chillDown <= realTime)
							spriteTb[i]:hide()
						end
					end

					if not v.vipLevelEnough then
						itertools.invoke(spriteTb, "hide")
						itertools.invoke(emptySprite, "hide")
					end

					bind.touch(list, node.get(node, "clickPanel"), {
						methods = {
							ended = functools.partial(list.clickItem, k, v)
						}
					})
				end,
				onAfterBuild = function(list)
					list.setItemAlignCenter(list)
				end
			},
			handlers = {
				clickItem = bindHelper.self("onChangeItemIndex")
			}
		}
	},
	["tabPanel.list"] = {
		varname = "tabList",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("tabsData"),
				item = bindHelper.self("tabItem"),
				onItem = function(list, node, k, v)
					local clickBtn = node:get("btnClick")
					local normalBtn = node:get("btnNormal")
					local clickText = node:get("clickText")
					local normalText = node:get("normalText")

					node:name(k == 1 and "starAidItem" or "starExchangeItem")
					clickBtn:visible(v.isSel)
					normalBtn:visible(not v.isSel)
					clickText:visible(v.isSel)
					normalText:visible(not v.isSel)
					clickText:getVirtualRenderer():setLineSpacing(-10)
					normalText:getVirtualRenderer():setLineSpacing(-10)
					adapt.setAutoText(clickText, v.txt, 240)
					adapt.setAutoText(normalText, v.txt, 240)
					uiEasy.updateUnlockRes(v.unlockKey, node, {
						pos = cc.p(120, 240)
					}):anonyOnly(list, list:getIdx(k))
					bind.touch(list, node, {
						methods = {
							ended = functools.partial(list.clickCell, k, v)
						}
					})
				end
			},
			handlers = {
				clickCell = bindHelper.self("onChangePage")
			}
		}
	},
	["centerPanel.btnLeft"] = {
		varname = "leftBtn",
		binds = {
			event = "touch",
			methods = {
				ended = bindHelper.self("onClockLeftBtn")
			}
		}
	},
	["centerPanel.btnRight"] = {
		varname = "rightBtn",
		binds = {
			event = "touch",
			methods = {
				ended = bindHelper.self("onClockRightBtn")
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
	["centerPanel.btnConfirm"] = {
		varname = "btnConfirm",
		binds = {
			event = "touch",
			methods = {
				ended = bindHelper.self("onClickConfirm")
			}
		}
	},
	["centerPanel.buttom.consumeLabel"] = {
		varname = "consumeLabel",
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
	["centerPanel.btnConfirm.text"] = {
		varname = "textConfirm",
		binds = {
			{
				event = "text",
				idler = bindHelper.self("confirmText")
			},
			{
				event = "effect",
				data = {
					outline = { color = ui.NEWCOLORS.OUTLINE.YELLOW, size = 4 }
				}
			}
		}
	},
	["centerPanel.chillDown"] = {
		varname = "chillDown",
		binds = {
			event = "effect",
			data = {
				outline = {
					size = 4,
					color = cc.c4b(57, 93, 94, 255)
				}
			}
		}
	},
	["centerPanel.leftBottom.leftName"] = {
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
	["centerPanel.leftBottom.leftLevel"] = {
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
	["centerPanel.rightBottom.rightName"] = {
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
	["centerPanel.rightBottom.rightLevel"] = {
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
	["leftPanel.btnHelp"] = {
		binds = {
			event = "touch",
			methods = {
				ended = bindHelper.self("onClickRule")
			}
		}
	},
	["leftPanel.btnHelp.text"] = {
		binds = {
			event = "effect",
			data = {
				outline = {
					size = 4,
					color = cc.c4b(91, 84, 91, 255)
				}
			}
		}
	},
	["tabPanel.awardPanel.icon"] = {
		binds = {
			{
				event = "touch",
				methods = {
					ended = bindHelper.self("onReceive")
				}
			},
			{
				event = "extend",
				class = "red_hint",
				props = {
					specialTag = "starSwapReceiveCount",
					onNode = function(node)
						node:xy(100, 80):scale(1 / 1.8)
					end,
				},
			},
		}
	},
	["tabPanel.awardPanel.receiveText"] = {
		varname = "receiveText",
		binds = {
			{
				event = "text",
				idler = bindHelper.self("receiveCount")
			},
			{
				event = "effect",
				data = {
					outline = {
						size = 4,
						color = cc.c4b(91, 84, 91, 255)
					}
				}
			}
		}
	},
	["tabPanel.awardPanel.receiveTip"] = {
		varname = "receiveTip",
		binds = {
			event = "effect",
			data = {
				outline = {
					size = 4,
					color = cc.c4b(91, 84, 91, 255)
				}
			}
		}
	}
}

function StarSwapView:onCreate(pageIdx)
	gGameUI.topuiManager:createView("default", self, {
		onClose = self:createHandler("onClose")
	}):init({
		subTitle = "POKEMON STAR",
		title = gLanguageCsv.starTitle
	})
	self:initModel()
	self:enableSchedule()

	if matchLanguage({ "en" }) then
		local sprBg = self.exchangeLeftPanel:get("bg")
		sprBg:size(620, 540):x(sprBg:x() + 50)
	end

	self.leftListData = idlers.newWithMap({})
	local seatData = {}

	for _, v in orderCsvPairs(csv.card_star_swap_field) do
		table.insert(seatData, {
			isAiding = false,
			chillDown = 0,
			vipLevelEnough = false,
			isSel = false,
			filedId = v.id,
			rarities = v.rarities,
			unlockType = v.unlockType,
			unlockParam = v.unlockParam,
			iconData = {}
		})
	end

	self.leftListData:update(seatData)

	self.selectAidData = idlertable.new({})
	self.selectExchangeData = idlertable.new({})
	self.starLeftDatas = idlertable.new({})
	self.starRightDatas = idlertable.new({})
	self.confirmText = idler.new("")
	self.pageIdx = idler.new(pageIdx or 1)

	local tabData = TABDATA[pageIdx]
	self.pageType = idler.new(tabData.type)
	self.aidItemIdx = idler.new(1)
	self.receiveCount = idler.new(0)
	self.tabsData = idlers.newWithMap({})
	local tabsData = {}

	for index, data in ipairs(TABDATA) do
		tabsData[index] = {
			isSel = false,
			txt = data.name,
			type = data.type,
			unlockKey = data.unlockKey
		}
	end

	if not dataEasy.isUnlock(gUnlockCsv.cardStarSwap) then
		table.remove(tabsData, 2)
	end

	self.tabsData:update(tabsData)
	idlereasy.when(self.vipLevel, function(_, vipLevel)
		for _, v in self.leftListData:ipairs() do
			local data = v:proxy()
			data.vipLevelEnough = data.unlockType == 1 and data.unlockParam <= vipLevel or false
		end
	end)
	idlereasy.when(self.fieldSeat, function(_, fieldData)
		local aidData = table.deepcopy(self.selectAidData:read(), true)

		for i = 1, self.leftListData:size() do
			aidData[i] = aidData[i] or {}

			if fieldData[i] and itertools.size(fieldData[i].cards) > 0 and fieldData[i].cards[1] ~= 0 then
				self.leftListData:atproxy(i).isAiding = true

				for i1, v1 in ipairs(fieldData[i].cards) do
					aidData[i][i1] = StarTools.getAidCardData(v1)
				end
			else
				self.leftListData:atproxy(i).isAiding = false
				self.leftListData:atproxy(i).iconData = {}
				aidData[i] = {}
			end

			if fieldData[i] and fieldData[i].cd and fieldData[i].cd > 0 then
				self.leftListData:atproxy(i).chillDown = fieldData[i].cd
			end
		end

		self.selectAidData:set(aidData, true)
	end)
	self.pageIdx:addListener(function(val, oldval)
		self.tabsData:atproxy(oldval).isSel = false
		self.tabsData:atproxy(val).isSel = true
	end)
	self.aidItemIdx:addListener(function(val, oldval)
		self.leftListData:atproxy(oldval).isSel = false
		self.leftListData:atproxy(val).isSel = true
	end)
	idlereasy.any({
		self.pageType,
		self.aidItemIdx,
	}, function(_, pageType, aidItemIdx)
		if pageType == 1 then
			self:refreshCenterUI(self.selectAidData:read()[aidItemIdx])
			gGameModel.currday_dispatch:getIdlerOrigin("starAidDailyClick"):set(true)
		else
			self:refreshCenterUI(self.selectExchangeData:read())

			if self.receiveCount:read() > 0 and not gGameUI.guideManager:isInGuiding() then
				self:popReceiveView()
			end

			gGameModel.currday_dispatch:getIdlerOrigin("starExchangeDailyClick"):set(true)
		end

		self.exchangeLeftPanel:visible(pageType == 2)
		self.aidLeftPanel:visible(pageType == 1)
	end)
	idlereasy.when(self.selectAidData, function(_, selectAidData)
		for i = 1, self.leftListData:size() do
			self.leftListData:atproxy(i).iconData = selectAidData[i] or {}
		end

		if self.pageType:read() == 1 then
			self:refreshCenterUI(selectAidData[self.aidItemIdx:read()])
		end
	end)
	idlereasy.when(self.selectExchangeData, function(_, selectExchangeData)
		if self.pageType:read() == 2 then
			self:refreshCenterUI(selectExchangeData)
		end
	end)
	idlereasy.any({
		self.rmb,
		self.gold,
		self.items
	}, function()
		if self.selectType and self.selectRarity then
			self:updateCostList(self.selectType, self.selectRarity, self.maxStar)
		end

		self.selectExchangeData:notify()
	end)
	idlereasy.when(self.deliverRecord, function(_, deliverRecord)
		local count = StarTools.getReceiveCount(deliverRecord)

		self.receiveCount:set(count)
		adapt.oneLinePos(self.receiveTip, self.receiveText, cc.p(10, 0))
	end)
	self.costList:setScrollBarEnabled(false)
	self.exchangeLeftPanel:get("tipText"):text(gLanguageCsv.starExchangeTimes)
	self.exchangeLeftPanel:get("name"):text(gLanguageCsv.starConfigTimes)
	self.exchangeLeftPanel:get("resume"):text(gLanguageCsv.starSConfigTimes2)
	self.exchangeLeftPanel:get("name1"):text(gLanguageCsv.starConfigTimes)
	self.exchangeLeftPanel:get("resumeCount"):text("/" ..
		string.format(gLanguageCsv.starSConfigTimes1, gCommonConfigCsv.cardStarSwapRaritySTimesLimit))
	if matchLanguage({ "en" }) then
		local childs = self.exchangeLeftPanel:multiget("number", "resumeNum", "resumeCount", "downPanel", "number2")
		local rightX = childs.number:x() + 160

		childs.number:x(rightX)
		childs.resumeCount:x(rightX)
		childs.downPanel:x(rightX)
		childs.number2:x(rightX)
		adapt.oneLinePos(childs.resumeCount, childs.resumeNum, cc.p(5, 0), "right")
	end

	local effect = widget.addAnimationByKey(self.centerPanel, "starswap/xingjizhuanyi.skel", "centerSpine", "effect_loop",
		100)

	effect:scale(2):anchorPoint(cc.p(0.5, 0.5)):xy(772, 1022)
end

function StarSwapView:initModel()
	self.vipLevel = gGameModel.role:getIdler("vip_level")
	self.fieldSeat = idlereasy.new({}) -- gGameModel.role:getIdler("card_star_swap_fields")
	self.deliverRecord = gGameModel.role:getIdler("card_star_swap_times_deliver_record")
	self.exchangeTimeCd = gGameModel.role:getIdler("card_star_swap_times_cd")
	self.preExchangeNum = gGameModel.role:getIdler("card_star_swap_times")
	self.rmb = gGameModel.role:getIdler("rmb")
	self.gold = gGameModel.role:getIdler("gold")
	self.items = gGameModel.role:getIdler("items")
end

function StarSwapView:refreshCenterUI(data)
	local dataSize = itertools.size(data)
	local pageType = self.pageType:read()

	if dataSize == 0 then
		self.centerBottom:hide()
	elseif dataSize == 2 then
		local rarity = nil
		local maxStar = 0

		for _, v in pairs(data) do
			rarity = v.rarity
			maxStar = math.max(maxStar, v.star)
		end

		self.updateCostList(self, pageType, rarity, maxStar)
	end

	itertools.invoke({
		self.leftLight,
		self.rightLight,
		self.btnConfirm
	}, "hide")
	uiEasy.setBtnShader(self.leftBtn, nil, 1)
	uiEasy.setBtnShader(self.rightBtn, nil, 1)

	local realTime = time.getTime()

	self:addOrDelStarEffect(data[1] and data[1].star, data[2] and data[2].star,
		pageType == 1 and self.leftListData:atproxy(self.aidItemIdx:read()).isAiding)

	if pageType == 1 then
		self.awardPanel:hide()

		local index = self.aidItemIdx:read()
		local curListData = self.leftListData:atproxy(index)

		if curListData.isAiding then
			self.confirmText:set(gLanguageCsv.starStopAid)
			self.leftLight:show()
			self.rightLight:show()
		else
			self.confirmText:set(string.format(gLanguageCsv.starAid, " "))
		end

		if realTime < curListData.chillDown then
			local diffTime = math.min(csv.card_star_swap_field[index].chillDown * 3600,
				math.ceil(curListData.chillDown - realTime))
			local dayTime = 86400
			local timeText = ""

			self.unSchedule(self, "SwapView")

			if dayTime < diffTime then
				timeText = math.ceil(diffTime / dayTime)

				self.chillDown:text(string.format(gLanguageCsv.starAidCd, timeText))
			else
				local endTime = time.getTime() + diffTime

				self.schedule(self, function()
					local diff = endTime - time.getTime()

					if diff == 0 then
						self:unSchedule("SwapView")
						self.leftListData:notify()
						self.selectAidData:notify()
					else
						timeText = time.getCutDown(diff).str

						self.chillDown:text(string.format(gLanguageCsv.starAidCd1, timeText))
					end
				end, 1, 0, "SwapView")
			end

			self.chillDown:show()
		else
			if itertools.size(data) == 2 then
				self.btnConfirm:show()
			end

			self.chillDown:hide()
		end

		if curListData.isAiding or realTime < curListData.chillDown then
			itertools.invoke({
				self.iconLeft,
				self.iconRight,
				self.leftBtn,
				self.rightBtn
			}, "hide")
		else
			itertools.invoke({
				self.iconLeft,
				self.iconRight,
				self.leftBtn,
				self.rightBtn
			}, "show")
		end
	else
		self.awardPanel:show()
		self.chillDown:hide()

		local rarity = 3
		local sPropCount = dataEasy.getNumByKey(StarTools.SPROPKEY)
		local sPlusPropCount = dataEasy.getNumByKey(StarTools.SPLUSPROPKEY)
		local allCount = sPropCount + sPlusPropCount

		self.exchangeLeftPanel:get("number"):text(string.format(gLanguageCsv.starSConfigTimes1, sPropCount))
		self.exchangeLeftPanel:get("number2"):text(string.format(gLanguageCsv.starSConfigTimes1, sPlusPropCount))

		local resumeNum = self.exchangeLeftPanel:get("resumeNum")
		local preExchangeNum = self.preExchangeNum:read()

		if preExchangeNum == nil or not preExchangeNum[rarity] then
			resumeNum:setTextColor(cc.c4b(91, 84, 91, 255)):text(gCommonConfigCsv.cardStarSwapRaritySDefaultTimes)

			allCount = allCount + gCommonConfigCsv.cardStarSwapRaritySDefaultTimes

			self.exchangeDownPanel:hide()
		else
			local exchangeTimeCd = self.exchangeTimeCd:read()
			local rarityExTimeCd = exchangeTimeCd[rarity]
			if not rarityExTimeCd then
				rarityExTimeCd = realTime
			end
			local cdCount = math.floor(math.max(0, realTime - rarityExTimeCd) /
				(gCommonConfigCsv.cardStarSwapRaritySTimesCD * 3600))
			local count = preExchangeNum[rarity] + cdCount

			resumeNum:text(count)

			allCount = allCount + count

			if count == 0 then
				resumeNum.setTextColor(resumeNum, cc.c4b(247, 107, 69, 255))
			else
				resumeNum.setTextColor(resumeNum, cc.c4b(91, 84, 91, 255))
			end

			if gCommonConfigCsv.cardStarSwapRaritySTimesLimit <= count then
				self.exchangeDownPanel:hide()
			else
				self.exchangeDownPanel:show()

				local diffTime = math.min(gCommonConfigCsv.cardStarSwapRaritySTimesCD * 3600,
					math.ceil(rarityExTimeCd + gCommonConfigCsv.cardStarSwapRaritySTimesCD * 3600 * (cdCount + 1) -
						realTime))
				local timeText = ""
				local dayTime = 86400
				local nodeTb = {
					self.exchangeDownPanel:get("time"),
					self.exchangeDownPanel:get("icon"),
					self.exchangeDownPanel:get("leftBrace")
				}

				if dayTime < diffTime then
					timeText = math.ceil(diffTime / dayTime)

					self.exchangeDownPanel:get("time"):text(string.format(gLanguageCsv.day, timeText))
					adapt.oneLinePos(self.exchangeDownPanel:get("rightBrace"), nodeTb, cc.p(5, 0), "right")
				else
					self.unSchedule(self, "exchangeView")

					local endTime = time.getTime() + diffTime

					self.schedule(self, function()
						local diff = endTime - time.getTime()

						if diff == 0 then
							self:unSchedule("exchangeView")
							self.selectExchangeData:notify()
						else
							timeText = time.getCutDown(diff).str

							self.exchangeDownPanel:get("time"):text(timeText)
							adapt.oneLinePos(self.exchangeDownPanel:get("rightBrace"), nodeTb, cc.p(5, 0), "right")
						end
					end, 1, 0, "exchangeView")
				end
			end
		end

		adapt.oneLinePos(self.exchangeLeftPanel:get("resumeCount"), resumeNum, cc.p(5, 0), "right")
		itertools.invoke({
			self.iconLeft,
			self.iconRight,
			self.leftBtn,
			self.rightBtn
		}, "show")

		self.allCount = allCount

		if allCount <= 0 then
			uiEasy.setBtnShader(self.leftBtn, nil, 3)
			uiEasy.setBtnShader(self.rightBtn, nil, 3)
		elseif itertools.size(data) == 2 then
			self.btnConfirm:show()
		end

		self.confirmText:set(string.format(gLanguageCsv.starExchange, " "))
	end

	for i = 1, 2 do
		local v = data and data[i] or {}

		if itertools.size(v) > 0 then
			local card = gGameModel.cards:find(v.dbid)
			local cardData = card:read("card_id", "skin_id", "star", "advance", "equips", "level", "name")
			local unitInfo = dataEasy.getUnitCsv(cardData.card_id, cardData.skin_id)
			local posTb = {
				self.leftBtn,
				self.rightBtn
			}
			local iconTb = {
				self.iconLeft,
				self.iconRight
			}
			local buttomPanel = {
				self.leftBottom,
				self.rightBottom
			}

			iconTb[i]:hide()
			buttomPanel[i]:show()

			local x = posTb[i]:x()
			local y = posTb[i]:y() - 230
			local name = "leftAnim"

			if i == 1 then
				self.centerPanel:removeChildByName("leftAnim")
				self.starLeftDatas:set(StarTools.getStarData(cardData.star))
			else
				self.starRightDatas:set(StarTools.getStarData(cardData.star))
				self.centerPanel:removeChildByName("rightAnim")

				name = "rightAnim"
			end

			local cardSprite = widget.addAnimation(self.centerPanel, unitInfo.unitRes, "standby_loop", 1):xy(x, y):scale(
				unitInfo.scaleU * 0.5):name(name)

			cardSprite:setSkin(unitInfo.skin)
			self:updateBottom({
				name = cardData.name,
				cardId = cardData.card_id,
				skinId = cardData.skin_id,
				advance = cardData.advance,
				level = cardData.level,
				index = i
			})
		else
			self.clearCenter(self, i)
		end
	end
end

function StarSwapView:addOrDelStarEffect(leftStar, rightStar, isAiding)
	local nodeTb = {
		self.centerPanel:get("leftStarPanel"),
		self.centerPanel:get("rightStarPanel")
	}

	if not isAiding or not leftStar or not rightStar then
		for i = 1, 2 do
			nodeTb[i]:removeAllChildren()
		end

		return
	end

	for k, v in ipairs({ leftStar, rightStar }) do
		nodeTb[k]:removeAllChildren()

		local interval = 66
		local startPos = 32
		local starNum = v > 6 and 6 or v

		for i = 1, starNum do
			nodeTb[k]:z(10)
			widget.addAnimationByKey(nodeTb[k], "starswap/xingji.skel", "effctStar" .. i, "effect_loop", 0)
				:xy(startPos + interval * (i - 1), 35)
				:scale(1.8)
				:setCascadeOpacityEnabled(true)
				:opacity(60)
		end
	end
end

function StarSwapView:updateBottom(params)
	local leftNode = {
		name = self.leftBottom:get("leftName"),
		level = self.leftBottom:get("leftLevel"),
		icon = self.leftBottom:get("leftIcon")
	}
	local rightNode = {
		name = self.rightBottom:get("rightName"),
		level = self.rightBottom:get("rightLevel"),
		icon = self.rightBottom:get("rightIcon")
	}
	local nodeTb = {
		leftNode,
		rightNode
	}
	local index = params.index
	local unitCsv = dataEasy.getUnitCsv(params.cardId, params.skinId)

	nodeTb[index].icon:show():texture(ui.RARITY_ICON[unitCsv.rarity])
	uiEasy.setIconName("card", params.cardId, {
		noColor = true,
		space = true,
		node = nodeTb[index].name,
		name = params.name,
		advance = params.advance
	})
	nodeTb[index].name:show()
	nodeTb[index].level:show():text(string.format(gLanguageCsv.starLevel, params.level))
	adapt.oneLinePos(nodeTb[index].level, nodeTb[index].icon, cc.p(24, 0))
end

function StarSwapView:clearCenter(index)
	if index == 1 then
		self.starLeftDatas:set({})
		self.centerPanel:removeChildByName("leftAnim")
		self.leftBottom:hide()
	else
		self.starRightDatas:set({})
		self.centerPanel:removeChildByName("rightAnim")
		self.rightBottom:hide()
	end
end

function StarSwapView:onClickRule()
	gGameUI:stackUI("common.rule", nil, nil, self:createHandler("getRuleContext"), {
		width = 1200
	})
end

function StarSwapView:getRuleContext(view)
	local c = adaptContext
	local context = {
		c.noteText(129231, 129250)
	}

	return context
end

function StarSwapView:onReceive()
	if self.receiveCount:read() <= 0 then
		gGameUI:showTip(gLanguageCsv.starNotReceive)

		return
	end

	self.popReceiveView(self)
end

function StarSwapView:popReceiveView()
	gGameUI:stackUI("city.card.star_swap.receive_box", nil, nil, {
		count = self.receiveCount
	})
end

function StarSwapView:onSetDbId(aidIndex, index, data)
	if not data then
		return
	end

	if index == 0 then
		index = 2
	else
		index = 1
	end

	local selectAidData = table.deepcopy(self.selectAidData:read(), true)
	local selectExchangeData = table.deepcopy(self.selectExchangeData:read(), true)

	for k, v in pairs(selectAidData) do
		for k1, v1 in pairs(v) do
			if v1 and data.dbid == v1.dbid then
				selectAidData[k][k1] = nil
			end
		end
	end

	for k, v in pairs(selectExchangeData) do
		if v and data.dbid == v.dbid then
			selectExchangeData[k] = nil
		end
	end

	if self.pageType:read() == 1 then
		local tb = selectAidData[aidIndex] or {}
		tb[index] = data
		selectAidData[aidIndex] = tb
	else
		selectExchangeData[index] = data
	end

	self.selectAidData:set(selectAidData, true)
	self.selectExchangeData:set(selectExchangeData, true)
end

function StarSwapView:onClockLeftBtn()
	self.onAddCard(self, 1)
end

function StarSwapView:onClockRightBtn()
	self.onAddCard(self, 0)
end

function StarSwapView:onAddCard(index)
	if self.pageType:read() == 2 and self.allCount and self.allCount <= 0 then
		gGameUI:showTip(gLanguageCsv.noChangeCount)

		return
	end

	local ids = {}
	local k = self.aidItemIdx:read()
	local tb = self.pageType:read() == 1 and self.selectAidData:read()[k] or self.selectExchangeData:read()

	for i = 1, 2 do
		ids[i] = tb[i] and tb[i].dbid
	end

	gGameUI:stackUI("city.card.star_swap.choose_card", nil, nil, {
		from = self.pageType:read(),
		selDbIds = ids,
		curSelDbId = ids[index + 1],
		seatRarity = self.leftListData:atproxy(k).rarities,
		handlers = self:createHandler("onSetDbId", k, index)
	})
end

function StarSwapView:onExchangeSuccess()
	self.selectExchangeData:set({}, true)
end

function StarSwapView:updateCostList(index, rarity, maxStar)
	self.selectType = index
	self.selectRarity = rarity
	self.maxStar = maxStar
	local award = StarTools.getCostList(index, rarity, maxStar)
	local aidItemIdx = self.aidItemIdx:read()
	local condition = self.pageType:read() == 1 and self.leftListData:atproxy(aidItemIdx).isAiding
	local data = nil

	if index == 1 then
		data = self.selectAidData:read()[aidItemIdx]
	elseif index == 2 then
		data = self.selectExchangeData:read()
	end

	if itertools.size(award) == 0 or condition or itertools.size(data) <= 0 then
		self.centerBottom:hide()

		return
	end

	uiEasy.createItemsToList(self, self.costList, award, {
		scale = 0.85,
		onAfterBuild = function()
			self.costList:setItemAlignCenter()
		end
	})
	self.centerBottom:show()
end

function StarSwapView:onChangePage(list, idx, v)
	if not dataEasy.isUnlock(v.unlockKey) then
		gGameUI:showTip(dataEasy.getUnlockTip(v.unlockKey))

		return
	end

	if idx == self.pageIdx:read() then
		return
	end
	self.pageType:set(v.type)
	self.pageIdx:set(idx)
end

function StarSwapView:onChangeItemIndex(list, idx, v)
	if not v.vipLevelEnough then
		gGameUI:showTip(string.format(gLanguageCsv.starVipLock, uiEasy.getVipStr(v.unlockParam).str))

		return
	end

	self.aidItemIdx:set(idx)
end

function StarSwapView:onClickConfirm()
	if self.pageType:read() == 1 then
		local aidIndex = self.aidItemIdx:read()
		local data = self.selectAidData:read()[aidIndex]

		if self.leftListData:atproxy(aidIndex).isAiding then
			local leftCard = gGameModel.cards:find(data[1].dbid)
			local leftData = leftCard:read("advance", "name", "card_id")
			local leftName = uiEasy.setIconName("card", leftData.card_id, {
				noColor = true,
				space = true,
				name = leftData.name,
				advance = leftData.advance
			})
			local rightCard = gGameModel.cards:find(data[2].dbid)
			local rightData = rightCard:read("advance", "name", "card_id")
			local rightName = uiEasy.setIconName("card", rightData.card_id, {
				noColor = true,
				space = true,
				name = rightData.name,
				advance = rightData.advance
			})

			local cdCfg = string.format(gLanguageCsv.hour, csv.card_star_swap_field[self.aidItemIdx:read()].chillDown)

			gGameUI:showDialog({
				isRich = true,
				btnType = 2,
				cb = function()
					gGameApp:requestServer("/game/card/star/swap", function(tb)
						gGameUI:showTip(gLanguageCsv.starStopAid1)
					end, aidIndex, data[1].dbid, data[2].dbid, "off")
				end,
				content = string.format(gLanguageCsv.starStopAid2, cdCfg, leftName, rightName),
				dialogParams = {
					clickClose = false
				}
			})

			return
		end

		gGameUI:stackUI("city.card.star_swap.preview", nil, nil, {
			leftDbId = data[1].dbid,
			rightDbId = data[2].dbid,
			type = self.pageType:read(),
			onShowCost = self:createHandler("onShowCost"),
			onShowAidSuccessAnim = self:createHandler("onShowAidSuccessAnim"),
			seatId = aidIndex
		})
	else
		local data = self.selectExchangeData:read()

		gGameUI:stackUI("city.card.star_swap.preview", nil, nil, {
			leftDbId = data[1].dbid,
			rightDbId = data[2].dbid,
			type = self.pageType:read(),
			onShowCost = self:createHandler("onShowCost"),
			onExchangeSuccess = self:createHandler("onExchangeSuccess")
		})
	end

	self.centerBottom:hide()
	self.btnConfirm:hide()
end

function StarSwapView:onShowCost()
	local aidItemIdx = self.aidItemIdx:read()
	local pageType = self.pageType:read()
	local condition = pageType == 1 and self.leftListData:atproxy(aidItemIdx).isAiding
	local data = nil

	if pageType == 1 then
		data = self.selectAidData:read()[aidItemIdx]
	else
		data = self.selectExchangeData:read()
	end

	if itertools.size(data) <= 0 or condition then
		return
	end

	self.btnConfirm:show()
	self.centerBottom:show()
end

function StarSwapView:onShowAidSuccessAnim()
	local spine = self.centerPanel:get("centerSpine")

	spine:play("effect")

	gGameUI:disableTouchDispatch(nil, false)
	spine:setSpriteEventHandler(function(event, eventArgs)
		if eventArgs.animation == "effect" then
			spine:addPlay("effect_loop")
			gGameUI:disableTouchDispatch(nil, true)
		end
	end, sp.EventType.ANIMATION_COMPLETE)
end

return StarSwapView
