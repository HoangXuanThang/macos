--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2017 TianJi Information Technology Inc.
--
-- sdk相关
--

local packageUrl = {
	cn = "http://192.168.2.8:18080",
	tw = "http://47.57.237.165:18080",
}

sdk.PACKAGE_URL = packageUrl[LOCAL_LANGUAGE]

sdk.IS_SDK_INITED = false

-- 当前运行平台
local targetPlatform = cc.Application:getInstance():getTargetPlatform()

local eventMap = {
	[1] = "EVENTS_START_LOADING",
	[2] = "EVENTS_FINISHED_LOADING",
	[11] = "PULL_VERSION",
	[12] = "START_CDN",
	[13] = "CDN_30",
	[14] = "CDN_60",
	[15] = "CDN_FINISH",
	[16] = "NOTNETWORK_CLICK",
	[17] = "PULL_GAMESHOW",
	[18] = "CLICK_OK",
	[19] = "START_LOGIN",
	[20] = "START_GAME",
}

function sdk.trackEvent(ctype, data)
	if type(data) ~= "table" then
		data = {data = data}
	end
	data.ctype = ctype
	data.event = eventMap[ctype] or ""
	sdk.callPlatformFunc("trackEvent", json.encode(data), function(info)
		print("trackEvent ret = ", info)
	end)
end

function sdk.callPlatformFunc(funcName, bundle, callback)
	if ((cc.PLATFORM_OS_IPHONE == targetPlatform) or (cc.PLATFORM_OS_IPAD == targetPlatform)) then
		local luaoc = require "cocos.cocos2d.luaoc"
		luaoc.callStaticMethod("SDKDelegate", "proxy",{
			funcName = funcName,
			bundle = bundle,
			callback = callback
		})
	else
		local luaj = require "cocos.cocos2d.luaj"
		luaj.callStaticMethod("www/tianji/finalsdk/MessageHandler","msgFromLua",{
			[1] = funcName,
			[2] = bundle,
			[3] = callback
		})
	end
end

-- @desc 是否是刘海屏 1是 0否
function sdk.isHasNotchScreen(cb)
	if display.isNotchSceen ~= nil then
		cb(display.isNotchSceen)
		return
	end
	sdk.callPlatformFunc("isHasNotchScreen", "data", function(info)
		printInfo("sdk.isHasNotchScreen back info = %s | %s", type(info), info)
		display.isNotchSceen = tonumber(info)
		cb(tonumber(info))
	end)
end

-- @desc 是否初始化成功
function sdk.isSDKInited(cb)
	if sdk.IS_SDK_INITED then
		if cb then
			cb(true)
		end
		return
	end
	sdk.callPlatformFunc("isSDKInited", "", function(info)
		printInfo("sdk.isSDKInited back info = %s", info)
		if info == "true" then
			sdk.IS_SDK_INITED = true
		end
		if cb then cb(sdk.IS_SDK_INITED) end
	end)
end

--@desc 获取Sdk返回配置
function sdk.getSDKCfg(cb)
	sdk.callPlatformFunc("getSDKCfg", "", function(info)
		if cb then cb(info) end
	end)
end


local function init()
	if device.platform ~= "windows" then
		sdk.isHasNotchScreen(function(info)
			if info == 1 then
				display.notchSceenSafeArea = display.fullScreenSafeArea
				display.notchSceenDiffX = display.fullScreenDiffX
				printInfo("# display.notchSceenSafeArea changed   = %d", display.notchSceenSafeArea)
				printInfo("# display.notchSceenDiffX changed      = %d", display.notchSceenDiffX)
			end
		end)
	end
end

init()
