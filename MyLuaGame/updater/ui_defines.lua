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

-- 常用颜色
ui.COLORS = {
	WHITE = cc.c4b(255, 255, 255, 255),				-- #FFFFFF
	BLACK = cc.c4b(0, 0, 0, 255),					-- #000000
	RED = cc.c4b(255, 0, 0, 255),					-- #FF0000
	GREEN = cc.c4b(0, 255, 0, 255),					-- #00FF00
	BLUE = cc.c4b(0, 0, 255, 255),					-- #0000FF
	YELLOW = cc.c4b(255, 255, 0, 255),				-- #FFFF00
	NORMAL = {
		DEFAULT = cc.c4b(91, 84, 91, 255),			-- #5B545B
		WHITE = cc.c4b(255, 252, 237, 255),			-- #FFFCED
		RED = cc.c4b(241, 59, 84, 255),				-- #F13B54
		GRAY = cc.c4b(183, 176, 158, 255),			-- #B7B09E
		LIGHT_GREEN = cc.c4b(174, 233, 126, 255),	-- #AEE97E
		FRIEND_GREEN = cc.c4b(96, 196, 86, 255),	-- #60C456
		ALERT_YELLOW = cc.c4b(236, 183, 42, 255),	-- #ECB72A
		ALERT_ORANGE = cc.c4b(247, 107, 69, 255),	-- #F76B45
	},
	GLOW = {
		WHITE = cc.c4b(255, 255, 255, 128),			-- #FFFFFF
		RED = cc.c4b(146, 12, 47, 153),				-- #920C1B
	},
	DISABLED = {
		WHITE = cc.c4b(222, 218, 208, 255),			-- #DEDAD1
		GRAY = cc.c4b(183, 176, 158, 255),			-- #B7B09E
		TITLE_GRAY = cc.c4b(159, 146, 141, 255),	-- #9F928D
		SUBTITLE_GRAY = cc.c4b(172, 172, 169, 255), -- #ACACA9
	},
	OUTLINE = {
		DEFAULT = cc.c4b(91, 84, 91, 255),			-- #5B545B
		RED = cc.c4b(124, 44, 52, 255),				-- #7C2C34
		GREEN = cc.c4b(77, 94, 67, 255),			-- #4D5E43
		WHITE = cc.c4b(255, 252, 237, 255),			-- #FFFCED
		BLUE = cc.c4b(28, 114, 154, 255),			-- #1C729A
		ATROVIRENS = cc.c4b(19, 140, 104, 255),		-- #138C68
		ORANGE = cc.c4b(240, 75, 52, 255),			-- #CC4B34
	},
	-- 统一品质颜色
	QUALITY = {
		[1] = cc.c4b(153, 153, 153, 255),			-- #999999
		[2] = cc.c4b(92, 153, 112, 255),			-- #5C9970
		[3] = cc.c4b(61, 138, 153, 255),			-- #3D8A99
		[4] = cc.c4b(138, 92, 153, 255),			-- #8A5C99
		[5] = cc.c4b(230, 153, 0, 255),				-- #E69900
		[6] = cc.c4b(230, 116, 34, 255),			-- #E67422
	},
	QUALITY_OUTLINE = {
		[1] = cc.c4b(91, 84, 91, 255),				-- #5B545B
		[2] = cc.c4b(102, 128, 110, 255),			-- #66806E
		[3] = cc.c4b(76, 115, 153, 255),			-- #4C7399
		[4] = cc.c4b(115, 76, 128, 255),			-- #734C80
		[5] = cc.c4b(178, 119, 0, 255),				-- #B27700
		[6] = cc.c4b(178, 74, 45, 255),				-- #B24A2D
	},
}
