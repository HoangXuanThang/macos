--

-- 0 - disable debug info, 1 - less debug info, 2 - verbose debug info
DEBUG = 2

-- use framework, will disable all deprecated API, false - use legacy API
CC_USE_FRAMEWORK = true

-- show FPS on screen
CC_SHOW_FPS = false

-- disable create unexpected global variable
CC_DISABLE_GLOBAL = true

-- for module display
local width = 1280 * 2
local height = 720 * 2
local maxWidth = 1560 * 2
CC_DESIGN_RESOLUTION = {
	width = width,
	height = height,
	maxWidth = maxWidth,
	autoscale = "FIXED_HEIGHT",
	callback = function(display, framesize)
		local ratio = framesize.width / framesize.height

		--战斗逻辑中不能使用这函数里的变量，只给view使用
		local scale = framesize.height / height
		local tmp1 = (width - framesize.width/scale) / 2

		-- sx<0 指 左边画面会被截断
		-- sx>0 指 左边画面补边长度
		local sx = 0
		if ratio > 1.6 then
			sx = -tmp1
		end
		local sxMax = math.min(sx, (maxWidth - width) / 2)

		-- 与cocos的Origin含义不同,慎用
		display.uiOrigin = cc.p(sx, 0) -- 场景起点，相对屏幕坐标
		display.uiOriginMax = cc.p(sxMax, 0) -- 超过最大分辨率时的相对屏幕坐标
		-- Sets a 2D projection (orthogonal projection).
		display.director:setProjection(cc.DIRECTOR_PROJECTION_2D) --改为正交投影 改善资源 字体 模糊

		if ratio <= 1.6 then
			-- iPad 768*1024(1536*2048) is 4:3 screen
			-- huawei M2 1920*1200 1.6 screen
			return {autoscale = "SHOW_ALL"}
		end

		-- test iphoneX in windows
		if device.platform == "windows" then
			if framesize.width * framesize.height == 2436 * 1125 or framesize.width * framesize.height == 2436 * 1125 / 9 then
				device.model = "iphone x"
				printInfo("simulator device model:%s", device.model)
			end
		end
	end
}
