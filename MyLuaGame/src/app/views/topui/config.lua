-- @desc: topui 通用配置

local title = {
	["leftTopPanel.title"] = {
		varname = "titleText",
		binds = {
			event = "effect",
			data = { glow = { color = cc.c4b(255, 255, 255, 255) } },
		},
	},
	["leftTopPanel.subTitle"] = {
		varname = "subTitleText",
		binds = {
			event = "effect",
			data = { glow = { color = cc.c4b(255, 255, 255, 255) } },
		},
	},
	["leftTopPanel.back"] = {
		binds = {
			event = "touch",
			methods = { ended = bindHelper.self("onClose") }
		},
	},
	["rightTopClosePanel.back"] = {
		binds = {
			event = "touch",
			methods = { ended = bindHelper.self("onClose") }
		},
	},
}

local gold = {
	["rightTopPanel.goldPanel.num"] = {
		binds = {
			event = "text",
			idler = bindHelper.model("role", 'gold'),
			method = function(val)
				return mathEasy.getShortNumber(val, 2)
			end
		},
	},
	["rightTopPanel.goldPanel.btnAdd"] = "goldBtnAdd",
	["rightTopPanel.goldPanel"] = {
		binds = {
			event = "touch",
			methods = { ended = bindHelper.self("onGoldClick") }
		},
	},
}

local diamond = {
	["rightTopPanel.diamondPanel.num"] = {
		binds = {
			event = "text",
			idler = bindHelper.model("role", 'rmb'),
			method = function(val)
				return mathEasy.getShortNumber(val, 2)
			end
		},
	},
	["rightTopPanel.diamondPanel.btnAdd"] = "diamondBtnAdd",
	["rightTopPanel.diamondPanel"] = {
		binds = {
			event = "touch",
			methods = { ended = bindHelper.self("onDiamondClick") }
		},
	},
}
--钻石抽卡
local rmbCard = {
	["rightTopPanel.rmbCardPanel.num"] = {
		binds = {
			event = "text",
			idler = bindHelper.model("role", 'items'),
			method = function(val)
				return mathEasy.getShortNumber(val[game.ITEM_TICKET.rmbCard] or 0, 2)
			end
		},
	},
	["rightTopPanel.rmbCardPanel.btnAdd"] = "rmbCardBtnAdd",
	["rightTopPanel.rmbCardPanel"] = {
		binds = {
			event = "touch",
			methods = { ended = bindHelper.self("onRmbCardClick") }
		},
	},
}

-- 皮肤卡
local skinCard = {
	["rightTopPanel.skinCardPanel.num"] = {
		binds = {
			event = "text",
			idler = bindHelper.self("skinCardBalance"),
			method = function(val)
				return mathEasy.getShortNumber(val or 0, 2)
			end
		},
	},
	["rightTopPanel.skinCardPanel.btnAdd"] = "rmbSkinBtnAdd",
	["rightTopPanel.skinCardPanel"] = {
		binds = {
			event = "touch",
			methods = { ended = bindHelper.self("onSkinCardClick") }
		},
	},
}

--金币抽卡
local goldCard = {
	["rightTopPanel.goldCardPanel.num"] = {
		binds = {
			event = "text",
			idler = bindHelper.model("role", 'items'),
			method = function(val)
				return mathEasy.getShortNumber(val[game.ITEM_TICKET.goldCard] or 0, 2)
			end
		},
	},
	["rightTopPanel.goldCardPanel.btnAdd"] = "goldCardBtnAdd",
	["rightTopPanel.goldCardPanel"] = {
		binds = {
			event = "touch",
			methods = { ended = bindHelper.self("onGoldCardClick") }
		},
	},
}

--限时抽卡（旧魂匣）
local limitCard = {
	["rightTopPanel.limitCardPanel.num"] = {
		binds = {
			event = "text",
			idler = bindHelper.model("role", 'items'),
			method = function(val)
				return mathEasy.getShortNumber(val[game.ITEM_TICKET.limitCard] or 0, 2)
			end
		},
	},
	["rightTopPanel.limitCardPanel.btnAdd"] = "limitCardBtnAdd",
	["rightTopPanel.limitCardPanel"] = {
		binds = {
			event = "touch",
			methods = { ended = bindHelper.self("onLimitCardClick") }
		},
	},
}
--饰品抽卡
local equipCard = {
	["rightTopPanel.equipCardPanel.num"] = {
		binds = {
			event = "text",
			idler = bindHelper.model("role", 'items'),
			method = function(val)
				return mathEasy.getShortNumber(val[game.ITEM_TICKET.equipCard] or 0, 2)
			end
		},
	},
	["rightTopPanel.equipCardPanel.btnAdd"] = "equipCardBtnAdd",
	["rightTopPanel.equipCardPanel"] = {
		binds = {
			event = "touch",
			methods = { ended = bindHelper.self("onEquipCardClick") }
		},
	},
}
-- 限时轮换钻石抽卡
local diamondUpCard = {
	["rightTopPanel.diamondUpCardPanel.num"] = {
		binds = {
			event = "text",
			idler = bindHelper.model("role", 'items'),
			method = function(val)
				return mathEasy.getShortNumber(val[game.ITEM_TICKET.diamondUpCard] or 0, 2)
			end
		},
	},
	["rightTopPanel.diamondUpCardPanel.btnAdd"] = "diamondUpCardBtnAdd",
	["rightTopPanel.diamondUpCardPanel"] = {
		binds = {
			event = "touch",
			methods = { ended = bindHelper.self("onDiamondUpCardClick") }
		},
	},
}

local luckyEgg = {
	["rightTopPanel.luckyEggCardPanel.num"] = {
		binds = {
			event = "text",
			idler = bindHelper.model("role", 'items'),
			method = function(val)
				return mathEasy.getShortNumber(val[game.ITEM_TICKET.luckyEggCard] or 0, 2)
			end
		},
	},
	["rightTopPanel.luckyEggCardPanel"] = {
		binds = {
			event = "touch",
			methods = { ended = bindHelper.self("onluckyEggCardClick") }
		},
	},
}

local union = {
	["rightTopPanel.unionCoinPanel.num"] = {
		binds = {
			event = "text",
			idler = bindHelper.model("role", 'coin3'),
			method = function(val)
				return mathEasy.getShortNumber(val, 2)
			end
		},
	},
	["rightTopPanel.unionCoinPanel"] = {
		binds = {
			event = "touch",
			methods = { ended = bindHelper.self("onUnionCoinClick") }
		},
	},
}

local drawcard = {
	["rightTopPanel.equipCoinPanel.num"] = {
		binds = {
			event = "text",
			idler = bindHelper.model("role", 'equip_awake_frag'),
			method = function(val)
				return mathEasy.getShortNumber(val, 2)
			end
		},
	},
	["rightTopPanel.equipCoinPanel"] = {
		binds = {
			event = "touch",
			methods = { ended = bindHelper.self("onDrawcardCoinClick") }
		},
	},
}

local passportCoin = {
	["rightTopPanel.coinPanel.num"] = {
		binds = {
			event = "text",
			idler = bindHelper.model("role", 'items'),
			method = function(val)
				return mathEasy.getShortNumber(val[game.ITEM_TICKET.passportCoin] or 0, 2)
			end
		},
	},
	["rightTopPanel.coinPanel"] = {
		binds = {
			event = "touch",
			methods = { ended = bindHelper.self("onCoinClick") }
		},
	},
}

local passportVipCoin = {
	["rightTopPanel.coinVipPanel.num"] = {
		binds = {
			event = "text",
			idler = bindHelper.model("role", 'items'),
			method = function(val)
				return mathEasy.getShortNumber(val[game.ITEM_TICKET.passportVipCoin] or 0, 2)
			end
		},
	},
	["rightTopPanel.coinVipPanel"] = {
		binds = {
			event = "touch",
			methods = { ended = bindHelper.self("onVipCoinClick") }
		},
	},
}

local arena = {
	["rightTopPanel.pvpCoinPanel.num"] = {
		binds = {
			event = "text",
			idler = bindHelper.model("role", 'coin1'),
			method = function(val)
				return mathEasy.getShortNumber(val, 2)
			end
		},
	},
	["rightTopPanel.pvpCoinPanel"] = {
		binds = {
			event = "touch",
			methods = { ended = bindHelper.self("onPvpCoinClick") }
		},
	},
}
--公会战
local union_combet = {
	["rightTopPanel.pvpCoinPanel.num"] = {
		binds = {
			event = "text",
			idler = bindHelper.model("role", 'coin10'),
			method = function(val)
				return mathEasy.getShortNumber(val, 2)
			end
		},
	},
	["rightTopPanel.pvpCoinPanel"] = {
		binds = {
			event = "touch",
			methods = { ended = bindHelper.self("onUnionCombetClick") }
		},
	},
}

local explorer = {
	["rightTopPanel.explorerCoinPanel.num"] = {
		binds = {
			event = "text",
			idler = bindHelper.model("role", 'coin4'),
			method = function(val)
				return mathEasy.getShortNumber(val, 2)
			end
		},
	},
	["rightTopPanel.explorerCoinPanel"] = {
		binds = {
			event = "touch",
			methods = { ended = bindHelper.self("onExplorerCoinClick") }
		},
	},
}

local randomTower = {
	["rightTopPanel.randomTowerCoinPanel.num"] = {
		binds = {
			event = "text",
			idler = bindHelper.model("role", 'coin2'),
			method = function(val)
				return mathEasy.getShortNumber(val, 2)
			end
		},
	},
	["rightTopPanel.randomTowerCoinPanel"] = {
		binds = {
			event = "touch",
			methods = { ended = bindHelper.self("onRandomTowerCoinClick") }
		},
	},
}

local fragment = {
	["rightTopPanel.fragmentCoinPanel.num"] = {
		binds = {
			event = "text",
			idler = bindHelper.model("role", 'coin5'),
			method = function(val)
				return mathEasy.getShortNumber(val, 2)
			end
		},
	},
	["rightTopPanel.fragmentCoinPanel"] = {
		binds = {
			event = "touch",
			methods = { ended = bindHelper.self("onFragmentCoinClick") }
		},
	},
}

local stamina = {
	["rightTopPanel.staminaPanel"] = {
		varname = "staminaPanel",
		binds = {
			event = "touch",
			longtouch = true,
			method = bindHelper.self("onStaminaLongTouch")
		},

	},
	["rightTopPanel.staminaPanel.num"] = "staminaText",
	["rightTopPanel.staminaPanel.max"] = "staminaMaxText",
	["rightTopPanel.staminaPanel.btnAdd"] = {
		binds = {
			event = "touch",
			methods = { ended = bindHelper.self("onStaminaClick") }
		},
	},
}

local craft = { -- craft
	["rightTopPanel.pvpCoinPanel.num"] = {
		binds = {
			event = "text",
			idler = bindHelper.model("role", 'coin6'),
			method = function(val)
				return mathEasy.getShortNumber(val, 2)
			end
		},
	},
	["rightTopPanel.pvpCoinPanel"] = {
		binds = {
			event = "touch",
			methods = { ended = bindHelper.self("onCraftCoinClick") }
		},
	},
}

local rightTopPanel = {
	["rightTopPanel"] = "rightTopPanel"
}

local capture = {
	["rightTopPanel.ballPanel1.num"] = "num1",
	["rightTopPanel.ballPanel1"] = {
		binds = {
			event = "touch",
			methods = { ended = bindHelper.self("onBallClick") }
		},
	},
	["rightTopPanel.ballPanel2.num"] = "num2",
	["rightTopPanel.ballPanel2"] = {
		binds = {
			event = "touch",
			methods = { ended = bindHelper.self("onBallClick") }
		},
	},
	["rightTopPanel.ballPanel3.num"] = "num3",
	["rightTopPanel.ballPanel3"] = {
		binds = {
			event = "touch",
			methods = { ended = bindHelper.self("onBallClick") }
		},
	},
}
local crossCraft = {
	["rightTopPanel.coin8Panel.num"] = {
		binds = {
			event = "text",
			idler = bindHelper.model("role", 'coin8'),
			method = function(val)
				return mathEasy.getShortNumber(val, 2)
			end
		},
	},
	["rightTopPanel.coin8Panel"] = {
		binds = {
			event = "touch",
			methods = { ended = bindHelper.self("onCrossCraftCoinClick") }
		},
	},
}
local crossArena = {
	["rightTopPanel.coin8Panel.num"] = {
		binds = {
			event = "text",
			idler = bindHelper.model("role", 'coin12'),
			method = function(val)
				return mathEasy.getShortNumber(val, 2)
			end
		},
	},
	["rightTopPanel.coin8Panel"] = {
		binds = {
			event = "touch",
			methods = { ended = bindHelper.self("onCrossArenaCoinClick") }
		},
	},
}

local crossMine = {
	["rightTopPanel.coin8Panel.num"] = {
		binds = {
			event = "text",
			idler = bindHelper.model("role", 'coin13'),
			method = function(val)
				return mathEasy.getShortNumber(val, 2)
			end
		},
	},
	["rightTopPanel.coin8Panel.btnAdd"] = "btnAdd",
	["rightTopPanel.coin8Panel"] = {
		varname = "coin8Panel",
		binds = {
			event = "touch",
			methods = { ended = bindHelper.self("onCrossMineCoinClick") }
		},
	},
}

local goldGem = {
	["rightTopPanel.goldGemPanel.num"] = {
		binds = {
			event = "text",
			idler = bindHelper.model("role", 'items'),
			method = function(val)
				return mathEasy.getShortNumber(val[game.ITEM_TICKET.goldGem] or 0, 2)
			end
		},
	},
	["rightTopPanel.goldGemPanel.btnAdd"] = "goldGemBtnAdd",
	["rightTopPanel.goldGemPanel"] = {
		binds = {
			event = "touch",
			methods = { ended = bindHelper.self("onGoldGemClick") }
		},
	},
}

local rmbGem = {
	["rightTopPanel.rmbGemPanel.num"] = {
		binds = {
			event = "text",
			idler = bindHelper.model("role", 'items'),
			method = function(val)
				return mathEasy.getShortNumber(val[game.ITEM_TICKET.rmbGem] or 0, 2)
			end
		},
	},
	["rightTopPanel.rmbGemPanel.btnAdd"] = "rmbGemBtnAdd",
	["rightTopPanel.rmbGemPanel"] = {
		binds = {
			event = "touch",
			methods = { ended = bindHelper.self("onRmbGemClick") }
		},
	},
}

local fishingGold = {
	["rightTopPanel.fishingSilverPanel.num"] = {
		binds = {
			event = "text",
			idler = bindHelper.model("role", 'items'),
			method = function(val)
				return mathEasy.getShortNumber(val[535] or 0, 2)
			end
		},
	},
	["rightTopPanel.fishingSilverPanel"] = {
		binds = {
			event = "touch",
			methods = { ended = bindHelper.self("onBtnClick") }
		},
	},
	["rightTopPanel.fishingGoldPanel.num"] = {
		binds = {
			event = "text",
			idler = bindHelper.model("role", 'items'),
			method = function(val)
				return mathEasy.getShortNumber(val[534] or 0, 2)
			end
		},
	},
	["rightTopPanel.fishingGoldPanel"] = {
		binds = {
			event = "touch",
			methods = { ended = bindHelper.self("onBtnClick") }
		},
	},

}

local onlineFight = {
	["rightTopPanel.coin8Panel.num"] = {
		binds = {
			event = "text",
			idler = bindHelper.model("role", 'coin12'),
			method = function(val)
				return mathEasy.getShortNumber(val, 2)
			end
		},
	},
	["rightTopPanel.coin8Panel"] = {
		binds = {
			event = "touch",
			methods = { ended = bindHelper.self("onOnlineFightCoinClick") }
		},
	},
}

local gridWalk = {
	["rightTopPanel.gridWalkPanel.num"] = "num1",
}

local actionPoint = {
	["rightTopPanel.actionPointPanel.num"] = "num1",
}

local chip = {
	["rightTopPanel.coin8Panel.num"] = {
		binds = {
			event = "text",
			idler = bindHelper.model("role", 'items'),
			method = function(val)
				return mathEasy.getShortNumber(val[121] or 0, 2)
			end
		},
	},
}

local huntingArea = {

	["rightTopPanel.coin8Panel.num"] = {
		binds = {
			event = "text",
			idler = bindHelper.model("role", 'coin14'),
			method = function(val)
				return mathEasy.getShortNumber(val, 2)
			end
		},
	},
	["rightTopPanel.coin8Panel"] = {
		binds = {
			event = "touch",
			methods = { ended = bindHelper.self("onHuntingAreaClick") }
		},
	},
}

local fereClothClip = {
	["rightTopPanel.fereClothClipPanel.num"] = {
		binds = {
			event = "text",
			idler = bindHelper.model("role", 'items'),
			method = function(val)
				return mathEasy.getShortNumber(val[game.ITEM_TICKET.fereHouseClothChip] or 0, 2)
			end
		},
	},
	["rightTopPanel.fereClothClipPanel.btnAdd"] = "fereClothClipBtnAdd",
	["rightTopPanel.fereClothClipPanel"] = {
		binds = {
			event = "touch",
			methods = { ended = bindHelper.self("onFereClothClipClick") }
		},
	},
}

local fereVideoClip = {
	["rightTopPanel.fereVideoClipPanel.num"] = {
		binds = {
			event = "text",
			idler = bindHelper.model("role", 'items'),
			method = function(val)
				return mathEasy.getShortNumber(val[game.ITEM_TICKET.fereHouseVideoChip] or 0, 2)
			end
		},
	},
	["rightTopPanel.fereVideoClipPanel.btnAdd"] = "fereVideoClipBtnAdd",
	["rightTopPanel.fereVideoClipPanel"] = {
		binds = {
			event = "touch",
			methods = { ended = bindHelper.self("onFereVideoClipClick") }
		},
	},
}

local crossSupremacy = {
	["rightTopPanel.coin15Panel.num"] = {
		binds = {
			event = "text",
			idler = bindHelper.model("role", 'coin15'),
			method = function(val)
				return mathEasy.getShortNumber(val, 2)
			end
		},
	},
	["rightTopPanel.coin15Panel.btnAdd"] = "btnAdd",
	["rightTopPanel.coin15Panel"] = {
		varname = "coin15Panel",
		binds = {
			event = "touch",
			methods = { ended = bindHelper.self("onCrossSupremacyCoinClick") }
		},
	},
}

local heldShop = {
	["rightTopPanel.heldCoinPanel.num"] = {
		binds = {
			event = "text",
			idler = bindHelper.model("role", 'items'),
			method = function(val)
				return mathEasy.getShortNumber(val[6071] or 0, 2)
			end
		},
	},
	["rightTopPanel.heldCoinPanel.btnAdd"] = "btnAdd",
	["rightTopPanel.heldCoinPanel"] = {
		varname = "heldCoinPanel",
		binds = {
			event = "touch",
			methods = { ended = bindHelper.self("onHeldShopCoinClick") }
		},
	},
}

local christmas = {
	["rightTopPanel.sdPanel.num"] = {
		binds = {
			event = "text",
			idler = bindHelper.model("role", 'items'),
			method = function(val)
				return mathEasy.getShortNumber(val[97] or 0, 2)
			end
		},
	},
	["rightTopPanel.sdPanel"] = {
		varname = "sdPanel",
		binds = {
			event = "touch",
			methods = { ended = bindHelper.self("onItem97CoinClick") }
		},
	},
}

local themeSkin = {
	["rightTopPanel.lhsjPanel.num"] = {
		binds = {
			event = "text",
			idler = bindHelper.model("role", 'items'),
			method = function(val)
				return mathEasy.getShortNumber(val[94] or 0, 2)
			end
		},
	},
	["rightTopPanel.lhsjPanel"] = {
		varname = "lhsjPanel",
		binds = {
			event = "touch",
			methods = { ended = bindHelper.self("onItem94CoinClick") }
		},
	},
	["rightTopPanel.qyxhPanel.num"] = {
		binds = {
			event = "text",
			idler = bindHelper.model("role", 'items'),
			method = function(val)
				return mathEasy.getShortNumber(val[95] or 0, 2)
			end
		},
	},
	["rightTopPanel.qyxhPanel"] = {
		varname = "qyxhPanel",
		binds = {
			event = "touch",
			methods = { ended = bindHelper.self("onItem95CoinClick") }
		},
	},
}


local zhutiYingxiong = {
	["rightTopPanel.hjlpPanel.num"] = {
		binds = {
			event = "text",
			idler = bindHelper.model("role", 'items'),
			method = function(val)
				return mathEasy.getShortNumber(val[87] or 0, 2)
			end
		},
	},
	["rightTopPanel.hjlpPanel"] = {
		varname = "hjlpPanel",
		binds = {
			event = "touch",
			methods = { ended = bindHelper.self("onItemWHJLPClick") }
		},
	},
}

local jiuWei = {
	["rightTopPanel.exp1Panel.num"] = {
		binds = {
			event = "text",
			idler = bindHelper.model("role", 'items'),
			method = function(val)
				return mathEasy.getShortNumber(val[game.ITEM_TICKET.lotteryJiuWeiItem] or 0, 2)
			end
		},
	},
	["rightTopPanel.exp1Panel"] = {
		varname = "exp1Panel",
		binds = {
			event = "touch",
			methods = { ended = bindHelper.self("onItemExp1CoinClick") }
		},
	},
	["rightTopPanel.exp2Panel.num"] = {
		binds = {
			event = "text",
			idler = bindHelper.model("role", 'items'),
			method = function(val)
				return mathEasy.getShortNumber(val[104] or 0, 2)
			end
		},
	},
	["rightTopPanel.exp2Panel"] = {
		varname = "exp2Panel",
		binds = {
			event = "touch",
			methods = { ended = bindHelper.self("onItemExp2CoinClick") }
		},
	},
}

local monopoly = {
	["rightTopPanel.coin1Panel.num"] = {
		binds = {
			event = "text",
			idler = bindHelper.model("role", 'items'),
			method = function(val)
				return mathEasy.getShortNumber(val[105] or 0, 2)
			end
		},
	},
	["rightTopPanel.coin1Panel"] = {
		varname = "coin1Panel",
		binds = {
			event = "touch",
			methods = { ended = bindHelper.self("onCoin105Click") }
		},
	},
	["rightTopPanel.coin2Panel.num"] = {
		binds = {
			event = "text",
			idler = bindHelper.model("role", 'items'),
			method = function(val)
				return mathEasy.getShortNumber(val[106] or 0, 2)
			end
		},
	},
	["rightTopPanel.coin2Panel"] = {
		varname = "coin2Panel",
		binds = {
			event = "touch",
			methods = { ended = bindHelper.self("onCoin106Click") }
		},
	},
}

local throne = {
	["rightTopPanel.coin1Panel.num"] = {
		binds = {
			event = "text",
			idler = bindHelper.model("role", 'items'),
			method = function(val)
				return mathEasy.getShortNumber(val[107] or 0, 2)
			end
		},
	},
	["rightTopPanel.coin1Panel"] = {
		varname = "coin1Panel",
		binds = {
			event = "touch",
			methods = { ended = bindHelper.self("onCoin107Click") }
		},
	},
	["rightTopPanel.coin2Panel.num"] = {
		binds = {
			event = "text",
			idler = bindHelper.model("role", 'items'),
			method = function(val)
				return mathEasy.getShortNumber(val[108] or 0, 2)
			end
		},
	},
	["rightTopPanel.coin2Panel"] = {
		varname = "coin2Panel",
		binds = {
			event = "touch",
			methods = { ended = bindHelper.self("onCoin108Click") }
		},
	},
}

local drawLimitExp = {
	["rightTopPanel.coin1Panel.num"] = {
		binds = {
			event = "text",
			idler = bindHelper.model("role", 'items'),
			method = function(val)
				return mathEasy.getShortNumber(val[115] or 0, 2)
			end
		},
	},
	["rightTopPanel.coin1Panel"] = {
		varname = "coin1Panel",
		binds = {
			event = "touch",
			methods = { ended = bindHelper.self("onCoin115Click") }
		},
	},
	["rightTopPanel.coin2Panel.num"] = {
		binds = {
			event = "text",
			idler = bindHelper.model("role", 'items'),
			method = function(val)
				return mathEasy.getShortNumber(val[116] or 0, 2)
			end
		},
	},
	["rightTopPanel.coin2Panel"] = {
		varname = "coin2Panel",
		binds = {
			event = "touch",
			methods = { ended = bindHelper.self("onCoin116Click") }
		},
	},
}


local drawLimitHelditem = {
	["rightTopPanel.coin1Panel.num"] = {
		binds = {
			event = "text",
			idler = bindHelper.model("role", 'items'),
			method = function(val)
				return mathEasy.getShortNumber(val[113] or 0, 2)
			end
		},
	},
	["rightTopPanel.coin1Panel"] = {
		varname = "coin1Panel",
		binds = {
			event = "touch",
			methods = { ended = bindHelper.self("onCoin113Click") }
		},
	},
	["rightTopPanel.coin2Panel.num"] = {
		binds = {
			event = "text",
			idler = bindHelper.model("role", 'items'),
			method = function(val)
				return mathEasy.getShortNumber(val[114] or 0, 2)
			end
		},
	},
	["rightTopPanel.coin2Panel"] = {
		varname = "coin2Panel",
		binds = {
			event = "touch",
			methods = { ended = bindHelper.self("onCoin114Click") }
		},
	},
}


return {
	title = title,
	gold = gold,
	diamond = diamond,
	stamina = stamina,
	rightTopPanel = rightTopPanel,
	union = union,
	arena = arena,
	union_combet = union_combet,
	explorer = explorer,
	fragment = fragment,
	randomTower = randomTower,
	skinCard = skinCard,
	craft = craft,
	capture = capture,
	drawcard = drawcard,
	rmbCard = rmbCard,
	limitCard = limitCard,
	crossMine = crossMine,
	goldCard = goldCard,
	equipCard = equipCard,
	diamondUpCard = diamondUpCard,
	luckyEgg = luckyEgg,
	crossCraft = crossCraft,
	crossArena = crossArena,
	goldGem = goldGem,
	rmbGem = rmbGem,
	passportCoin = passportCoin,
	passportVipCoin = passportVipCoin,
	fishingGold = fishingGold,
	onlineFight = onlineFight,
	gridWalk = gridWalk,
	actionPoint = actionPoint,
	chip = chip,
	huntingArea = huntingArea,
	fereClothClip = fereClothClip,
	fereVideoClip = fereVideoClip,
	crossSupremacy = crossSupremacy,
	heldShop = heldShop,
	christmas = christmas,
	themeSkin = themeSkin,
	zhutiYingxiong = zhutiYingxiong,
	jiuWei = jiuWei,
	monopoly = monopoly,
	throne = throne,
	drawLimitHelditem = drawLimitHelditem,
	drawLimitExp = drawLimitExp,
}
