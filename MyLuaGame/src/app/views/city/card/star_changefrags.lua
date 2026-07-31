local function setIcon(list, node, key, num)
	local binds = {
		class = "icon_key",
		props = {
			data = {
				key = key,
				num = num,
			},
		},
	}
	bind.extend(list, node, binds)
end
local TXT_TAB = {
	[1] = { txt = gLanguageCsv.change, spaceTxt = gLanguageCsv.spaceChange, success = gLanguageCsv.advanceSuccess },
	[2] = { txt = gLanguageCsv.comb, spaceTxt = gLanguageCsv.spaceComb, success = gLanguageCsv.combSuccess },
	[3] = { txt = gLanguageCsv.comb, spaceTxt = gLanguageCsv.spaceComb, success = gLanguageCsv.combSuccess },
}
local function getItemId(tabIdx, cardId)
	--普通万能碎片ID
	local changeId = gCommonConfigCsv.universalFragGeneral
	--神兽万能碎片ID
	local targetId = gCommonConfigCsv.universalFragSpecial
	--tabIdx 1卡牌碎片转化 2万能碎片合成
	if tabIdx == 1 then
		targetId = csv.cards[cardId].fragID
		local fragCsv = csv.fragments[targetId]
		changeId = fragCsv.universalFragID
	elseif tabIdx == 3 then
		changeId = gCommonConfigCsv.universalFragSpecial
		targetId = gCommonConfigCsv.universalSuperFragSpecial
	end
	return changeId, targetId
end

local function createRichTxt(parent, isShow, val)
	local size = parent:size()
	local richText = parent:get("txt")
	if richText then
		richText:removeFromParent()
	end
	if isShow then
		local changeId = (val == 2 and gCommonConfigCsv.universalFragGeneral or gCommonConfigCsv.universalFragSpecial)
		local targetId = (val == 2 and gCommonConfigCsv.universalFragSpecial or gCommonConfigCsv.universalSuperFragSpecial)

		local changeCfg = dataEasy.getCfgByKey(changeId)
		local targetCfg = dataEasy.getCfgByKey(targetId)
		local str = string.format(gLanguageCsv.universalFragCombTip,
			"#C0x5B545B#" .. (val == 2 and gCommonConfigCsv.universalFragSwitch or
				gCommonConfigCsv.universalSuperFragSwitch),
			ui.QUALITY_OUTLINE_COLOR[changeCfg.quality] .. changeCfg.name .. "#C0x5B545B#",
			1,
			ui.QUALITY_OUTLINE_COLOR[targetCfg.quality] .. targetCfg.name
		)
		rich.createByStr(str, 34)
			:anchorPoint(0.5, 0.5)
			:xy(size.width / 2, size.height / 2)
			:addTo(parent, 6, "txt")
	end
	-- if richText then
	-- 	richText:visible(isShow)
	-- end
end
local ViewBase = cc.load("mvc").ViewBase
local CardStarChangeFragsView = class("CardStarChangeFragsView", Dialog)

CardStarChangeFragsView.RESOURCE_FILENAME = "card_star_changefrags.json"
CardStarChangeFragsView.RESOURCE_BINDING = {
	["closeBtn"] = {
		binds = {
			event = "touch",
			methods = { ended = bindHelper.self("onClose") }
		}
	},
	["titleTxt"] = {
		varname = "title",
		binds = {
			event = "effect",
			data = { color = ui.COLORS.NORMAL.WHITE, outline = { color = ui.NEWCOLORS.OUTLINE.BLUE1, size = 4 } },
		},
	},
	["item"] = "item",
	["btnList"] = {
		varname = "btnList",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("tabDatas"),
				item = bindHelper.self("item"),
				onItem = function(list, node, k, v)
					local btn = node:get("btn")
					local txt = node:get("title")
					txt:text(v.name)
					btn:setBright(not v.isSelected)
					node:onClick(functools.partial(list.itemClick, k))
					if v.isSelected then
						text.addEffect(txt,
							{ color = ui.COLORS.NORMAL.WHITE, outline = { color = ui.NEWCOLORS.OUTLINE.YELLOW, size = 4 } })
					else
						text.addEffect(txt,
							{ color = ui.COLORS.NORMAL.WHITE, outline = { color = ui.NEWCOLORS.OUTLINE.BLUE, size = 4 } })
					end
				end,
			},
			handlers = {
				itemClick = bindHelper.self("onChangePage"),
			},
		},
	},
	["cardPanel"] = "cardPanel",
	["cardPanel.card1"] = "card1",
	["cardPanel.card2"] = "card2",
	["cardPanel.textName1"] = "textName1",
	["cardPanel.textName2"] = "textName2",
	["barPanel"] = "barPanel",
	["barPanel.myFrags"] = "myFrags",
	["barPanel.needFrags"] = "needFrags",
	["barPanel.bar"] = "slider",
	["barPanel.subBtn"] = {
		varname = "subBtn",
		binds = {
			event = "touch",
			methods = { ended = bindHelper.self("onReduceClick") }
		}
	},
	["barPanel.addBtn"] = {
		varname = "addBtn",
		binds = {
			event = "touch",
			methods = { ended = bindHelper.self("onAddClick") }
		}
	},
	["combTipPos"] = "combTipPos",
	["note"] = "needNumNote",
	["textNeedNum"] = "textNeedNum",
	["changeBtn"] = {
		varname = "changeBtn",
		binds = {
			event = "touch",
			methods = { ended = bindHelper.self("onChangeClick") }
		}
	},
	["changeBtn.title"] = {
		varname = "btnTxt",
		binds = {
			event = "effect",
			--data = {color = ui.COLORS.NORMAL.WHITE, glow = {color = ui.COLORS.GLOW.WHITE}},
			data = { color = ui.COLORS.NORMAL.WHITE, outline = { color = ui.NEWCOLORS.OUTLINE.YELLOW, size = 4 } },
		},
	},
}
function CardStarChangeFragsView:onCreate(selectDbId)
	self.selectDbId = selectDbId
	self:initModel()
	--页签数据
	local tabDatas = {}
	local cardId
	local tabIdx = 2
	--如果没有selectDbId 只有合成没有转化
	if selectDbId then
		tabDatas = {
			{ name = gLanguageCsv.fragmentTransformation, isSelected = false },
			{ name = gLanguageCsv.universalSynthesis, isSelected = false },
			{ name = gLanguageCsv.universalSuperSynthesis, isSelected = false },
		}
		cardId = self.cardId:read()
		tabIdx = 1
	else
		self.cardPanel:y(self.cardPanel:y() + 50)
		self.barPanel:y(self.barPanel:y() + 25)
	end
	self.selectNum = idler.new(0)
	self.tabIdx = idler.new(tabIdx)
	local canMaxNum
	idlereasy.any({ self.selectNum, self.tabIdx }, function(_, selectNum, tabIdx)
		local changeId, targetId = getItemId(tabIdx, cardId)
		self.fragsId = targetId
		local changeCfg = dataEasy.getCfgByKey(changeId)
		local targetCfg = dataEasy.getCfgByKey(targetId)
		local changeNum = dataEasy.getNumByKey(changeId)
		local targetNum = dataEasy.getNumByKey(targetId)
		--可转换的最大数量
		canMaxNum = changeNum
		--1卡牌碎片转化 2万能碎片合成
		if tabIdx == 2 then
			canMaxNum = math.floor(changeNum / gCommonConfigCsv.universalFragSwitch)
		elseif tabIdx == 3 then
			canMaxNum = math.floor(changeNum / gCommonConfigCsv.universalSuperFragSwitch)
		end
		--设置滑动条
		if not self.slider:isHighlighted() then
			local num = math.ceil(selectNum / canMaxNum * 100)
			self.slider:setPercent(num)
		end
		if tabIdx == 1 then
			--卡牌合成数量提示
			local fragCsv = csv.fragments[targetId]
			self.textNeedNum:text(math.max(fragCsv.combCount - dataEasy.getNumByKey(targetId), 0))
		end
		--设置滑动条上边的显示数量
		self.needFrags:text("/" .. canMaxNum)
		self.myFrags:text(selectNum)
		adapt.oneLineCenterPos(cc.p(self.barPanel:size().width / 2, self.myFrags:y()), { self.myFrags, self.needFrags })
		self.textName1:text(changeCfg.name)
		self.textName2:text(targetCfg.name)
		text.addEffect(self.textName1, { color = ui.COLORS.QUALITY[changeCfg.quality] })
		text.addEffect(self.textName2, { color = ui.COLORS.QUALITY[targetCfg.quality] })
		--加减按钮
		uiEasy.setBtnShader(self.addBtn, nil, selectNum < canMaxNum and 1 or 2)
		uiEasy.setBtnShader(self.subBtn, nil, selectNum > 0 and 1 or 2)
		--万能碎片icon
		setIcon(self, self.card1, changeId, changeNum)
		--碎片icon
		setIcon(self, self.card2, targetId, selectNum)
	end)

	self.slider:setPercent(0)
	self.slider:addEventListener(function(sender, eventType)
		if eventType == ccui.SliderEventType.percentChanged then
			local percent = sender:getPercent()
			local fragCsv = csv.fragments[fragsId]
			local selectNum = self.selectNum:read()
			local num = math.ceil(canMaxNum / 100 * percent)
			self.selectNum:set(math.min(num, canMaxNum))
		end
	end)

	self.tabDatas = idlers.newWithMap(tabDatas)
	self.tabIdx:addListener(function(val, oldval, idler)
		self.title:text(TXT_TAB[val].txt)
		self.btnTxt:text(TXT_TAB[val].spaceTxt)
		self.needNumNote:visible(val == 1)
		self.textNeedNum:visible(val == 1)
		--合成提示文本
		createRichTxt(self.combTipPos, val == 2 or val == 3, val)
		if self.tabDatas:atproxy(oldval) then
			self.tabDatas:atproxy(oldval).isSelected = false
		end
		if self.tabDatas:atproxy(val) then
			self.tabDatas:atproxy(val).isSelected = true
		end
	end)
	Dialog.onCreate(self)
end

function CardStarChangeFragsView:initModel()
	local card = gGameModel.cards:find(self.selectDbId)
	if card then
		self.cardId = card:getIdler("card_id")
	end
end

function CardStarChangeFragsView:onAddClick()
	self.selectNum:set(self.selectNum:read() + 1)
end

function CardStarChangeFragsView:onReduceClick()
	self.selectNum:set(self.selectNum:read() - 1)
end

--切换页签
function CardStarChangeFragsView:onChangePage(list, k)
	self.selectNum:set(0)
	self.tabIdx:set(k)
end

function CardStarChangeFragsView:onChangeClick()
	if self.selectNum:read() == 0 then
		gGameUI:showTip(string.format(gLanguageCsv.pleaseSelectNumber, TXT_TAB[self.tabIdx:read()].txt))
		return
	end
	local fragsId
	if self.tabIdx:read() == 1 then
		fragsId = self.fragsId
	elseif self.tabIdx:read() == 3 then
		fragsId = -1
	end
	gGameApp:requestServer("/game/role/acitem/switch", function(tb)
		gGameUI:showTip(TXT_TAB[self.tabIdx:read()].success)
		ViewBase.onClose(self)
	end, self.selectNum, fragsId)
end

return CardStarChangeFragsView
