--
-- Author: sir.huangwei@gmail.com
-- Date: 2014-05-30 10:57:04
--

package.path = package.path .. ";../cocos/?.lua;../scripts/?.lua"
--print(package.path)

require "extern"
require "luastl.stlbase"
require "Cocos2d"

function isCCObject(obj)
	-- used in host app
	return false
end

local fmap
local tindex
tindex = function (t, k)
	if fmap[k] then
		return fmap[k]
	end
	return setmetatable({}, {__index = tindex})
end
fmap = {
	getInstance = function ()
		return setmetatable({}, {__index = tindex})
	end,
	getIntegerForKey = function ()
		return 0
	end,
	getBoolForKey = function ()
		return false
	end,
	getValueMapFromFile = function ()
		return {}
	end,
}

cc.FileUtils = setmetatable({}, {__index = tindex})
cc.UserDefault = setmetatable({}, {__index = tindex})