local CardDevelop = class("CardDevelop", Dialog)

CardDevelop.RESOURCE_FILENAME = "card_develop.json"
CardDevelop.RESOURCE_BINDING = {
	["btnClose"] = {
		varname = "btnClose",
		binds = {
			event = "touch",
			methods = {
				ended = bindHelper.self("onClose")
			}
		}
	},
	["btnDevelop"] = {
		varname = "btnDevelop",
		binds = {
			event = "touch",
			methods = {
				ended = bindHelper.self("onDevelop")
			}
		}
	},
	["btnDevelop.title"] = {
		binds = {
			event = "effect",
			data = { glow = { color = ui.COLORS.GLOW.WHITE } }
		}
	},
	["tip"] = "tip",
	["item1"] = "item1",
	["item2"] = "item2",
}

function CardDevelop:onDevelop()
	gGameUI:stackUI("city.card.mega.view", nil, { full = true }, self.cardId)
end

function CardDevelop:initItem(item, cardId)
	local unit = csv.unit[cardId]
	local children = item:multiget("rarity", "name", "attr1", "attr2", "cardImg")
	local size = children.cardImg:size()

	if cardId == self.cardId then
		widget.addAnimationByKey(children.cardImg, "effect/jinhuajiemian.skel", 'spineSelect', "effect_down_loop", 2):x(
			size.width / 2)
	end

	widget.addAnimationByKey(children.cardImg, "effect/jinhuajiemian.skel", 'spineDown', "effect_down2_loop", 1):x(size
		.width / 2)
	widget.addAnimationByKey(children.cardImg, "effect/jinhuajiemian.skel", 'spineUp', "effect_up_loop", 4):x(size.width /
		2)

	if unit then
		local sprite2 = widget.addAnimation(children.cardImg, unit.unitRes, "standby_loop", 3)
		sprite2:xy(size.width / 2, size.height / 7)
			:scale(unit.scale * 1.5)
		sprite2:setSkin(unit.skin)

		children.rarity:texture(ui.RARITY_ICON[unit.rarity])
		children.attr1:texture(ui.ATTR_ICON[unit.natureType])
		children.attr2:texture(ui.ATTR_ICON[unit.natureType2])
		children.name:text(unit.name)
		adapt.oneLineCenterPos(cc.p(290, 80), { children.rarity, children.name, children.attr1, children.attr2 }, cc.p(8, 0))
	end
end

function CardDevelop:onCreate(cardId)
	self.cardId = cardId

	local cardCsv = csv.cards[cardId]
	self.tip:visible(cardCsv.develop == 2)
	self.btnDevelop:visible(cardCsv.develop == 1)
	if cardCsv.develop == 1 then
		self:initItem(self.item1, cardId)
		self:initItem(self.item2, cardCsv.megaIndexID)
	elseif cardCsv.develop == 2 then
		self:initItem(self.item1, cardCsv.megaIndexID)
		self:initItem(self.item2, cardId)
	end
	Dialog.onCreate(self)
end

return CardDevelop
