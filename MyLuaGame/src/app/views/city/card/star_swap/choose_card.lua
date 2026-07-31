local StarTools = require("app.views.city.card.star_swap.tools")
local StarSwapChooseCardView = class("StarSwapChooseCardView", Dialog)
StarSwapChooseCardView.RESOURCE_FILENAME = "star_select_role.json"
StarSwapChooseCardView.RESOURCE_BINDING = {
	item = "item",
	["down.textNote"] = "textNote",
	innerList = "innerList",
	["title.btnClose"] = {
		binds = {
			event = "touch",
			methods = {
				ended = bindHelper.self("onClose")
			}
		}
	},
	list = {
		varname = "list",
		binds = {
			event = "extend",
			class = "tableview",
			props = {
				columnSize = 7,
				asyncPreload = 28,
				data = bindHelper.self("cardDatas"),
				item = bindHelper.self("innerList"),
				cell = bindHelper.self("item"),
				itemAction = {
					isAction = true
				},
				onCell = function(list, node, k, v)
					bind.extend(list, node:get("head"), {
						class = "card_icon",
						props = {
							unitId = v.unitId,
							advance = v.advance,
							star = v.star,
							rarity = v.rarity,
							grayState = v.isSel and 1 or 0,
							levelProps = {
								data = v.level
							},
							onNode = function(panel)
							end
						}
					})
					node:get("imgTick"):visible(v.isSel)

					local t = list:getIdx(k)

					bind.touch(list, node, {
						methods = {
							ended = functools.partial(list.clickCell, t, v)
						}
					})
				end
			},
			handlers = {
				clickCell = bindHelper.self("onCellClick")
			}
		}
	},
	tipPanel = {
		binds = {
			event = "visible",
			idler = bindHelper.self("showTip")
		}
	},
	["down.btnOk"] = {
		binds = {
			event = "touch",
			methods = {
				ended = bindHelper.self("onSure")
			}
		}
	},
	["down.btnOk.textNote"] = {
		binds = {
			event = "effect",
			data = { outline = { color = ui.NEWCOLORS.OUTLINE.YELLOW, size = 4 } }
		},
	},
}

function StarSwapChooseCardView:onCreate(params)
	self.from = params.from
	self.selDbIds = params.selDbIds
	self.curSelDbId = params.curSelDbId
	self.handlers = params.handlers
	self.seatRarity = params.seatRarity
	self.cardDatas = idlers.newWithMap({})
	self.showTip = idler.new(false)
	local cards = StarTools.getSelectCard(self.from, self.selDbIds, self.curSelDbId, self.seatRarity)

	table.sort(cards, function(a, b)
		if a.rarity ~= b.rarity then
			return b.rarity < a.rarity
		end

		if a.star ~= b.star then
			return b.star < a.star
		end

		return b.fight < a.fight
	end)
	self.cardDatas:update(cards)
	self.showTip:set(self.cardDatas:size() == 0)
	self.textNote:text(self.from == 1 and gLanguageCsv.starAidChooseCard or gLanguageCsv.starExchangeChooseCard)
	Dialog.onCreate(self)
end

function StarSwapChooseCardView:onCellClick(list, t, v)
	if self.lastClickIndex == t.k then
		if self.cardDatas:atproxy(t.k).isSel then
			self.cardDatas:atproxy(self.lastClickIndex).isSel = false
			self.selected = nil
			self.lastClickIndex = nil
		else
			self.cardDatas:atproxy(t.k).isSel = true
			self.selected = v
			self.lastClickIndex = t.k
		end
	else
		if self.lastClickIndex then
			self.cardDatas:atproxy(self.lastClickIndex).isSel = false
		end

		self.cardDatas:atproxy(t.k).isSel = true
		self.selected = v
		self.lastClickIndex = t.k
	end
end

function StarSwapChooseCardView:onSure()
	if self.cardDatas:size() == 0 then
		gGameUI:showTip(gLanguageCsv.noCardChoose)

		return
	end

	self.addCallbackOnExit(self, functools.partial(self.handlers, self.selected))
	self.onClose(self)
end

return StarSwapChooseCardView
