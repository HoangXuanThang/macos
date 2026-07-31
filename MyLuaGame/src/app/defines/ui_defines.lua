--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2017 TianJi Information Technology Inc.
--
-- UI相关全局变量
--

local ui = {}
globals.ui = ui

ui.FONT_PATH = "font/youmi.ttf"
ui.FONT_SIZE = 40

ui.DEFAULT_OUTLINE_SIZE = 4
-- 拖动阈值设置
ui.TOUCH_MOVED_THRESHOLD = 10
-- 长按取消的阈值
ui.TOUCH_MOVE_CANCAE_THRESHOLD = 35



ui.NEWCOLORS = {
	GREEN = cc.c4b(64, 115, 46, 255),
	GREEN1 = cc.c4b(4, 181, 8, 255),
	GREEN2 = cc.c4b(35, 219, 4, 255),
	GREENLIGHT = cc.c4b(1, 160, 1, 255),
	RED = cc.c4b(200, 71, 40, 255),
	RED1 = cc.c4b(235, 88, 14, 255),
	REDLIGHT = cc.c4b(244, 31, 14, 255),
	BLACK = cc.c4b(0, 0, 0, 255),
	WHITE = cc.c4b(255, 255, 255, 255),
	WHITE1 = cc.c4b(237, 237, 191, 255), --下拉单未选中
	WHITE2 = cc.c4b(250, 248, 222, 255),
	GRAY = cc.c4b(158, 158, 158, 255),
	GRAY1 = cc.c4b(140, 133, 114, 255),
	GRAY2 = cc.c4b(217, 214, 214, 255),
	GRAY3 = cc.c4b(138, 132, 118, 255),
	BROWN = cc.c4b(84, 23, 11, 255),
	BROWN1 = cc.c4b(87, 71, 46, 255),
	BROWN2 = cc.c4b(138, 91, 12, 255),
	ORANGE = cc.c4b(240, 97, 26, 255),
	OUTLINE = {
		BLUE = cc.c4b(54, 85, 129, 255),
		BLUE1 = cc.c4b(27, 69, 101, 255),
		YELLOW = cc.c4b(172, 83, 25, 255),
		BLACK = cc.c4b(0, 0, 0, 255),
		WHITE = cc.c4b(255, 255, 255, 255),
		WHITE1 = cc.c4b(255, 246, 233, 255),
		WHITE2 = cc.c4b(255, 255, 225, 255),
		BROWN = cc.c4b(148, 52, 21, 255),
		GRAY = cc.c4b(158, 158, 158, 255),
		BROWN1 = cc.c4b(84, 23, 11, 255),
		BROWN2 = cc.c4b(166, 80, 20, 255),
		RED = cc.c4b(156, 48, 37, 255),
		RED1 = cc.c4b(164, 47, 1, 255),
	},
	DISABLED = {
		WHITE = cc.c4b(220, 217, 217, 255),
	},

}

-- 常用颜色
ui.COLORS = {
	WHITE = cc.c4b(255, 255, 255, 255),     -- #FFFFFF
	BLACK = cc.c4b(0, 0, 0, 255),           -- #000000
	RED = cc.c4b(255, 0, 0, 255),           -- #FF0000
	GREEN = cc.c4b(0, 255, 0, 255),         -- #00FF00
	BLUE = cc.c4b(0, 0, 255, 255),          -- #0000FF
	YELLOW = cc.c4b(255, 255, 0, 255),      -- #FFFF00
	NORMAL = {
		DEFAULT = cc.c4b(91, 84, 91, 255),  -- #5B545B
		WHITE = cc.c4b(255, 252, 237, 255), -- #FFFCED
		RED = cc.c4b(241, 59, 84, 255),     -- #F13B54
		GRAY = cc.c4b(183, 176, 158, 255),  -- #B7B09E
		LIGHT_GREEN = cc.c4b(1, 160, 1, 255), -- #AEE97E
		FRIEND_GREEN = cc.c4b(1, 160, 1, 255), -- #60C456
		ALERT_YELLOW = cc.c4b(236, 183, 42, 255), -- #ECB72A
		ALERT_ORANGE = cc.c4b(235, 88, 14, 255), -- #F76B45
		ALERT_GREEN = cc.c4b(174, 233, 126, 255), -- #AEE97E
		PINK = cc.c4b(228, 82, 77, 255),    -- #E4524D
		GREEN = cc.c4b(136, 200, 85, 255),  -- #88C855
		CLARET = cc.c4b(139, 34, 16, 255),  -- #8B2210
		WARM_YELLOW = cc.c4b(241, 188, 76, 255), -- #F1BC4C
		DULL_YELLOW = cc.c4b(175, 101, 14, 255), -- #AF650E
		BLACK = cc.c4b(59, 51, 59, 255),    -- #3B333B
		BROWN = cc.c4b(86, 8, 2, 255),      -- #560802

	},
	GLOW = {
		WHITE = cc.c4b(255, 255, 255, 128), -- #FFFFFF
		RED = cc.c4b(146, 12, 47, 153), -- #920C1B
		YELLOW = cc.c4b(255, 234, 0, 255) -- #ffea00
	},
	DISABLED = {
		WHITE = cc.c4b(222, 218, 208, 255),   -- #DEDAD1
		GRAY = cc.c4b(183, 176, 158, 255),    -- #B7B09E
		TITLE_GRAY = cc.c4b(159, 146, 141, 255), -- #9F928D
		SUBTITLE_GRAY = cc.c4b(172, 172, 169, 255), -- #ACACA9
		YELLOW = cc.c4b(239, 95, 28, 255),    -- #EF5F1C
		KHAKI = cc.c4b(147, 134, 98, 255),    -- #938662
	},
	OUTLINE = {
		DEFAULT = cc.c4b(91, 84, 91, 255), -- #5B545B
		RED = cc.c4b(124, 44, 52, 255),   -- #7C2C34
		GREEN = cc.c4b(77, 94, 67, 255),  -- #4D5E43
		WHITE = cc.c4b(255, 252, 237, 255), -- #FFFCED
		BLUE = cc.c4b(28, 114, 154, 255), -- #1C729A
		PURPLE = cc.c4b(126, 58, 222, 255), -- #7E37DE
		ATROVIRENS = cc.c4b(19, 140, 104, 255), -- #138C68
		ORANGE = cc.c4b(240, 75, 52, 255), -- #CC4B34
	},
	-- 统一品质颜色
	QUALITY = {
		[1] = cc.c4b(255, 255, 255, 255), -- #999999
		[2] = cc.c4b(6, 197, 69, 255), -- #5C9970
		[3] = cc.c4b(9, 149, 176, 255), -- #3D8A99
		[4] = cc.c4b(0x83, 0x64, 0xA7, 255), -- #8364A7
		[5] = cc.c4b(246, 128, 1, 255), -- #E69900
		[6] = cc.c4b(205, 180, 0, 255), -- #E67422
		[7] = cc.c4b(231, 2, 18, 255), -- #F13B54
		[8] = cc.c4b(248, 81, 234, 255), -- #f8519c
	},
	-- 统一品质描边，名称
	QUALITY_OUTLINE = {
		[1] = cc.c4b(0, 0, 0, 255), -- #5B545B
		[2] = cc.c4b(102, 128, 110, 255), -- #66806E
		[3] = cc.c4b(76, 115, 153, 255), -- #4C7399
		[4] = cc.c4b(115, 76, 128, 255), -- #734C80
		[5] = cc.c4b(178, 119, 0, 255), -- #B27700
		[6] = cc.c4b(178, 74, 45, 255), -- #B24A2D
		[7] = cc.c4b(218, 60, 79, 255), -- #DA3C4F
		[8] = cc.c4b(248, 81, 234, 255), -- #f8519c
	},
	-- 暗底上品质颜色
	QUALITY_DARK = {
		[1] = cc.c4b(255, 255, 255, 255), -- #999999
		[2] = cc.c4b(6, 197, 69, 255), -- #5C9970
		[3] = cc.c4b(9, 149, 176, 255), -- #3D8A99
		[4] = cc.c4b(0x83, 0x64, 0xA7, 255), -- #8364A7
		[5] = cc.c4b(246, 128, 1, 255), -- #E69900
		[6] = cc.c4b(205, 180, 0, 255), -- #E67422
		[7] = cc.c4b(231, 2, 18, 255), -- #F13B54
		[8] = cc.c4b(248, 81, 234, 255), -- #f8519c
	},
	-- normal      = 1, -- 光
	-- fire        = 2, -- 火
	-- water       = 3, -- 水
	-- grass       = 4, -- 风
	-- electricity = 5, -- 雷
	-- ice         = 6, -- 冰
	-- combat      = 7, -- 斗
	-- poison      = 8, -- 毒
	-- ground      = 9, -- 地
	-- fly         = 10, -- 飞
	-- super       = 11, -- 超
	-- worm        = 12, -- 剑
	-- rock        = 13, -- 岩
	-- ghost       = 14, -- 鬼
	-- dragon      = 15, -- 魔
	-- evil        = 16, -- 黑
	-- steel       = 17, -- 械
	-- fairy       = 18, -- 忍
	ATTR = {
		[game.NATURE_ENUM_TABLE.normal] = cc.c4b(236, 208, 41, 255), -- #ecd029 光
		[game.NATURE_ENUM_TABLE.fire] = cc.c4b(233, 61, 57, 255),    -- #e93d39 火
		[game.NATURE_ENUM_TABLE.water] = cc.c4b(34, 194, 34, 255),   -- #4189ff 水
		[game.NATURE_ENUM_TABLE.grass] = cc.c4b(111, 241, 108, 255), -- #6ff16c 风
		[game.NATURE_ENUM_TABLE.electricity] = cc.c4b(162, 106, 255, 255), -- #a26aff 雷
		[game.NATURE_ENUM_TABLE.ice] = cc.c4b(58, 193, 255, 255),    -- #3ac1ff 冰
		[game.NATURE_ENUM_TABLE.combat] = cc.c4b(254, 132, 63, 255), -- #fe843f 斗
		[game.NATURE_ENUM_TABLE.poison] = cc.c4b(165, 67, 255, 255), -- #a543ff 毒
		[game.NATURE_ENUM_TABLE.ground] = cc.c4b(161, 215, 24, 255), -- #a1d718 地
		[game.NATURE_ENUM_TABLE.fly] = cc.c4b(72, 186, 255, 255),    -- #48baff 飞
		[game.NATURE_ENUM_TABLE.super] = cc.c4b(246, 106, 227, 255), -- #f66ae3 超
		[game.NATURE_ENUM_TABLE.worm] = cc.c4b(253, 83, 137, 255),   -- #fd5389 剑
		[game.NATURE_ENUM_TABLE.rock] = cc.c4b(255, 150, 9, 255),    -- #ff9609 岩
		[game.NATURE_ENUM_TABLE.ghost] = cc.c4b(94, 246, 227, 255),  -- #5ef6e3 鬼
		[game.NATURE_ENUM_TABLE.dragon] = cc.c4b(196, 55, 253, 255), -- #c437fd 魔
		[game.NATURE_ENUM_TABLE.evil] = cc.c4b(87, 113, 253, 255),   -- #5771fd 黑
		[game.NATURE_ENUM_TABLE.steel] = cc.c4b(49, 227, 156, 255),  -- #31e39c 械
		[game.NATURE_ENUM_TABLE.fairy] = cc.c4b(244, 206, 14, 255),  -- #f4ce0e 忍
	}
}

ui.ATTRCOLOR = {
	normal = "#C0xFFC52091#",
	fire = "#C0xFFA87B31#",
	water = "#C0xFF22C222#",
	grass = "#C0xFF2497DD#",
	electricity = "#C0xFFED251B#",
	ice = "#C0xFF6BDBEC#",
	combat = "#C0xFFF98562#",
	poison = "#C0xFFAE7EDE#",
	ground = "#C0xFFB8B7B1#",
	fly = "#C0xFF85CEFC#",
	super = "#C0xFFE76FD7#",
	worm = "#C0xFFC4D138#",
	rock = "#C0xFFBE9E6A#",
	ghost = "#C0xFF788797#",
	dragon = "#C0xFFABA2FF#",
	evil = "#C0xFFAF8B85#",
	steel = "#C0xFFA5B8BE#",
	fairy = "#C0xFFF96494#",
}

ui.QUALITYCOLOR = {
	"#C0xFFFFFF#",
	"#C0x06C545#",
	"#C0x0995B0#",
	"#C0x852FA1#",
	"#C0xF68001#",
	"#C0xCDB400#",
	"#C0xE70212#",
	"#C0xFE6FF9#",
	"#C0xFD9BC9#",
}

ui.QUALITY_DARK_COLOR = {
	"#C0xFFFFFF#",
	"#C0x06C545#",
	"#C0x0995B0#",
	"#C0x852FA1#",
	"#C0xF68001#",
	"#C0xCDB400#",
	"#C0xE70212#",
	"#C0xFE6FF9#",
	"#C0xFD9BC9#",
}

ui.QUALITY_OUTLINE_COLOR = {
	"#C0x5B545B#",
	"#C0x66806E#",
	"#C0x4C7399#",
	"#C0x734C80#",
	"#C0xB27700#",
	"#C0xB24A2D#",
	"#C0xDA3C4F#",
	"#C0xFE6FF9#",
	"#C0xFD9BC9#",
}

ui.QUALITY_COLOR_SINGLE_TEXT = { "white", "green", "blue", "purple", "orange", "red", "rose" }
ui.QUALITY_COLOR_TEXT = { "whiteText", "greenText", "blueText", "purpleText", "orangeText", "redText", "roseText" }

-- 属性标识
ui.ATTR_LOGO = {
	hp = "common/icon/attribute/icon_life.png",               --生命
	damage = "common/icon/attribute/icon_attack.png",         -- 物攻
	specialDamage = "common/icon/attribute/icon_spattack.png", -- 特攻
	defence = "common/icon/attribute/icon_defense.png",       -- 物防
	specialDefence = "common/icon/attribute/icon_spdefense.png", -- 特防
	speed = "common/icon/attribute/icon_speed.png",           -- 速度
}

-- 卡牌属性
ui.ATTR_ICON = {}
ui.ATTR_ICON_1 = {}
ui.SKILL_ICON = {}
ui.SKILL_TEXT_ICON = {}
ui.FIGHT_SKILL_ICON = {}
for i, v in ipairs(game.NATURE_TABLE) do
	ui.ATTR_ICON_1[i] = string.format("common/icon/attr_1/icon_%s.png", v)
	ui.ATTR_ICON[i] = string.format("common/icon/attr/icon_%s.png", v)
	ui.SKILL_ICON[i] = string.format("common/icon/skill/icon_%s.png", v)
	ui.FIGHT_SKILL_ICON[i] = string.format("battle/attr/icon_%s.png", v)
	ui.SKILL_TEXT_ICON[i] = string.format("common/icon/skill_text/icon_%s.png", v)
end
ui.ATTR_MAX = #ui.ATTR_ICON + 1 -- 包含特殊全部

-- 稀有度
ui.RARITY_ICON = {}
for i = 0, 7 do
	ui.RARITY_ICON[i] = string.format("common/icon/icon_rarity%d.png", i + 1)
end
ui.RARITY_LAST_VAL = table.maxn(ui.RARITY_ICON) + 1 -- 包含特殊全部

ui.RARITY_TEXT = {
	[0] = "C",
	[1] = "B",
	[2] = "A",
	[3] = "S",
	[4] = "SS",
	[5] = "SR",
	[6] = "SSR",
	[7] = "SP"
}

-- 稀有度筛选条件
-- 固定只显示 B ~ S+, 后续有扩张可以修改
ui.RARITY_DATAS = {}
for i = 1, 7 do
	table.insert(ui.RARITY_DATAS, { rarity = i })
end

-- 公共数值图标
ui.COMMON_ICON = {
	gold = "common/icon/icon_gold.png",
	rmb = "common/icon/icon_diamond.png",
	stamina = "common/icon/icon_stamina.png",
	coin1 = "common/icon/icon_ryb.png",
	coin2 = "common/icon/icon_ytjj.png",
	coin3 = "common/icon/icon_ghb.png",
	coin4 = "common/icon/icon_jxlj.png",
	coin5 = "common/icon/icon_frgitm.png",
	coin6 = "common/icon/icon_sydhdb1.png",
	coin7 = "common/icon/icon_sydhdb2.png",
	coin8 = "common/icon/icon_kfsydhdb1.png",
	coin9 = "common/icon/icon_kfsydhdb2.png",
	coin10 = "common/icon/icon_ghzb1.png",
	coin11 = "common/icon/icon_ghzb2.png",
	overflow_exp = "common/icon/icon_jyb.png", --经验溢出不是货币，他目前只在购买时的二次弹框上使用
}

-- 品质底图和框
ui.QUALITY_BOX = {}
ui.QUALITY_FRAME = {}
for i = 1, game.QUALITY_MAX do
	ui.QUALITY_BOX[i] = string.format("common/icon/panel_icon_%d.png", i)
	ui.QUALITY_FRAME[i] = string.format("common/icon/tag_digital%d.png", i)
end

ui.VIP_ICON = {}
for i = 1, game.VIP_LIMIT do
	ui.VIP_ICON[i] = string.format("common/icon/vip/icon_vip%d.png", i)
end

ui.RANK_ICON = {
	"city/rank/icon_jp.png",
	"city/rank/icon_yp.png",
	"city/rank/icon_tp.png",
	"common/icon/icon_four.png",
}

-- musicLens 音效时长，weekOpen是否削弱背景音乐
ui.SOUND_LIST = {
	["advance_suc.mp3"] = { musicLens = 2, weekOpen = true },
	["battle_false.mp3"] = { musicLens = 2, weekOpen = true },
	["card_gain.mp3"] = { musicLens = 4, weekOpen = true },
	["drawcard_one.mp3"] = { musicLens = 3, weekOpen = true },
	["drawcard_one2.mp3"] = { musicLens = 2, weekOpen = true },
	["drawcard_ten.mp3"] = { musicLens = 9, weekOpen = true },
	["drawcard_ten2.mp3"] = { musicLens = 2, weekOpen = true },
	["evolution.mp3"] = { musicLens = 13, weekOpen = true },
	["gate_win.mp3"] = { musicLens = 2, weekOpen = true },
	["item_gain.mp3"] = { musicLens = 2, weekOpen = true },
	["pve_win.mp3"] = { musicLens = 4, weekOpen = true },
	["pvp_win.mp3"] = { musicLens = 3, weekOpen = true },
	["qiangdilaixi.mp3"] = { musicLens = 2, weekOpen = true },
	["role_levelup.mp3"] = { musicLens = 3, weekOpen = true },
	["golden.mp3"] = { musicLens = 3, weekOpen = false },  -- 聚宝成功后金币散落
	["refinement.mp3"] = { musicLens = 3, weekOpen = false }, -- 个体值成功洗炼
	["star.mp3"] = { musicLens = 3, weekOpen = false },    -- 潜力值成功提升
	["formation.mp3"] = { musicLens = 3, weekOpen = false }, -- 成功上阵
	["equip.mp3"] = { musicLens = 3, weekOpen = false },   -- 携带道具成功装备
	["click.mp3"] = { musicLens = 3, weekOpen = false },   -- 通用一级按钮点击音效
	["circle.mp3"] = { musicLens = 3, weekOpen = false },  -- 饰品强化
	["flop.mp3"] = { musicLens = 3, weekOpen = true },     -- 竞技场挑战成功奖励翻牌动画
	["zaixianlibao.mp3"] = { musicLens = 5, weekOpen = true },
	["gem_draw_1.mp3"] = { musicLens = 3, weekOpen = true },
	["gem_diamond_10.mp3"] = { musicLens = 3, weekOpen = true },
	["gem_gold_10.mp3"] = { musicLens = 3, weekOpen = true },
}

ui.TOUCH_SOUND_LIST = {
	"click_1.mp3",
	"click_2.mp3",
	"click_3.mp3",
}

-- 预加载音效
ui.PRELOAD_EFFECT_LIST = {
	"advance_suc.mp3",
	"item_gain.mp3",
	"iconpopup.mp3",
	"golden.mp3",
	"card_gain.mp3",
	"role_levelup.mp3",
	"popupopen.mp3",
	"popupclose.mp3",
	"click_1.mp3",
	"click_2.mp3",
	"click_3.mp3",
	"newbie_finish.mp3",
	"drawcard_one.mp3",
	"drawcard_one2.mp3",
	"drawcard_ten.mp3",
	"drawcard_ten2.mp3",
	"zaixianlibao.mp3",
	"evolution.mp3",
	"gem_draw_1.mp3",
	"gem_gold_10.mp3",
	"gem_diamond_10.mp3",
}

ui.IGNORE_CLEAN_MAP = {
	["battle.view"] = true,
	["battle.loading"] = true,
}

ui.GEM_SUIT_ICON = {
	'city/card/gem/suit/icon_t1.png',
	'city/card/gem/suit/icon_t2.png',
	'city/card/gem/suit/icon_t3.png',
	'city/card/gem/suit/icon_t4.png',
	'city/card/gem/suit/icon_t5.png',
	'city/card/gem/suit/icon_t6.png',
	'city/card/gem/suit/icon_t7.png',
	'city/card/gem/suit/icon_t8.png',
	'city/card/gem/suit/icon_t9.png',
}

ui.CONSOLE_COLOR = {
	Dark_black       = 0,
	Dark_Blue        = 1,
	Dark_Green       = 2,
	Dark_Blue_Green  = 3,
	Dark_Red         = 4,
	Dark_Purple      = 5,
	Dark_Yellow      = 6,
	Default          = 7,
	Light_Black      = 8,
	Light_Blue       = 9,
	Light_Green      = 10,
	Light_Blue_Green = 11,
	Light_Red        = 12,
	Light_Purple     = 13,
	Light_Yellow     = 14,
	Light_White      = 15,
}
ui.CARD_USING_TXTS = {
	battle = 'inCityTeam',
	unionTraining = 'inUnionTrain',
	arena = 'inArena',
	craft = 'inCraft',
	unionFight = 'inUnionCombat',
	cloneBattle = 'inCloneBattle',
	crossCraft = 'inCrossCraft',
	crossArena = 'inCrossArena',
	gymBadgeGuard = 'inGymBadgeGuard',
	gymLeader = "inGymEmbattle",
	crossGymLeader = "inCrossGymEmbattle",
	crossMine = "inCrossMine",
	crossunionfight = "inCrossUnionCombat",
	crossSupremacy = "inCrossSupremacy",
}
