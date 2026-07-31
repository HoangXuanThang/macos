local StarTools = require("app.views.city.card.star_swap.tools")
local StarSwapOverView = class("StarSwapOverView", Dialog)
StarSwapOverView.RESOURCE_FILENAME = "swap_over.json"
StarSwapOverView.RESOURCE_BINDING = {
	starItem = "starItem",
	leftPanel = "leftPanel",
	rightPanel = "rightPanel",
	spinePanel = {
		varname = "spinePanel",
		binds = {
			event = "click",
			method = bindHelper.self("onClose")
		}
	},
	["leftPanel.name"] = {
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
	["leftPanel.leftLevel"] = {
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
	["leftPanel.leftStarList"] = {
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
	["rightPanel.rightStarList"] = {
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
	["rightPanel.rightLevel"] = {
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
	["rightPanel.name"] = {
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

function StarSwapOverView:onCreate(params)
	self.leftDbId = params.leftDbId
	self.rightDbId = params.rightDbId
	self.starLeftDatas = idlertable.new({})
	self.starRightDatas = idlertable.new({})
	local bgEffect = widget.addAnimation(self.spinePanel, "level/jiesuanshengli_1.skel", "jiesuan_shenglitu", 99)

	bgEffect:anchorPoint(cc.p(0.5, 0.5)):name("textSpine"):xy(self.spinePanel:width() / 2,
		self.spinePanel:height() / 2 - 55):addPlay("jiesuan_shenglitu_loop")

	local textEffect = widget.addAnimation(self.spinePanel, "level/jiesuanshengli_1.skel", "xjiesuan_tishengzi", 100)

	textEffect:anchorPoint(cc.p(0.5, 0.5)):name("textSpine"):xy(self.spinePanel:width() / 2,
		self.spinePanel:height() / 2 - 55):addPlay("xjiesuan_tishengzi_loop")
	self:cardStarChanged()
	self:updateBottom()
	Dialog.onCreate(self, {
		clearFast = true
	})
end

function StarSwapOverView:updateBottom()
	local leftNode = {
		name = self.leftPanel:get("name"),
		level = self.leftPanel:get("leftLevel"),
		icon = self.leftPanel:get("leftIcon"),
		sprite = self.leftPanel:get("leftSprite")
	}
	local rightNode = {
		name = self.rightPanel:get("name"),
		level = self.rightPanel:get("rightLevel"),
		icon = self.rightPanel:get("rightIcon"),
		sprite = self.rightPanel:get("rightSprite")
	}
	local dbIds = {
		self.leftDbId,
		self.rightDbId
	}

	for i, v in ipairs({ leftNode, rightNode }) do
		local card = gGameModel.cards:find(dbIds[i])
		local cardData = card:read("card_id", "skin_id", "star", "advance", "level", "rarity")
		local cardId = cardData.card_id
		local unitCsv = dataEasy.getUnitCsv(cardId, cardData.skin_id)

		uiEasy.setIconName("card", cardId, {
			noColor = true,
			space = true,
			node = v.name,
			name = csv.cards[cardId].name,
			advance = cardData.cardData
		})
		local unitId = dataEasy.getUnitId(cardData.card_id, cardData.skin_id)
		bind.extend(self, v.sprite, {
			class = "card_icon",
			props = {
				unitId = unitId,
				advance = cardData.advance,
				star = cardData.star,
				rarity = cardData.rarity,
				levelProps = {
					data = cardData.level,
				},
				onNode = function(node)
					node:xy(-65, -75)
				end,
			}
		})
		v.icon:show():texture(ui.RARITY_ICON[unitCsv.rarity])
		v.level:show():text(string.format(gLanguageCsv.starLevel, cardData.level))
		adapt.oneLinePos(v.level, v.icon, cc.p(10, 0))
	end
end

function StarSwapOverView:cardStarChanged()
	local leftStar = gGameModel.cards:find(self.leftDbId):read("star")
	local rightStar = gGameModel.cards:find(self.rightDbId):read("star")
	local data = {
		self.starLeftDatas,
		self.starRightDatas
	}

	for i, v in ipairs({ leftStar, rightStar }) do
		data[i]:set(StarTools.getStarData(v))
	end
end

return StarSwapOverView
