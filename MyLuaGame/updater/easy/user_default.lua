-- @date: 2018-11-16
-- @desc: 本地数据存储

local ccUserDefault = cc.UserDefault:getInstance()
local isCleanup = false

local userDefault = {}
globals.userDefault = userDefault

-- @desc 启动游戏后的首次调用，自动清理数据
local function onCleanup()
	if isCleanup then
		return
	end
	isCleanup = true
	-- 清理活动不在 yyhuodong 里和 过期30天 的
	local data = userDefault.getForeverLocalKey("activity", {})
	local newData = {}
	local function validActivity(id)
		local cfg = csv.yunying.yyhuodong[id]
		if not cfg then
			return false
		end
		local hour = time.getHourAndMin(cfg.endTime, true)
		local endTime = time.getNumTimestamp(cfg.endDate, hour)
		if time.getTime() -  endTime >= 30 * 24 * 3600 then
			return false
		end
		return true
	end
	for k, v in pairs(data) do
		if validActivity(k) then
			newData[k] = v
		end
	end
	userDefault.setForeverLocalKey("activity", newData, {new = true})
end

-- @desc 转换为关联帐号的key
local function getUserKey(key, raw)
	if raw then
		return key
	end
	local id = gGameModel.role:read("id")
	if assertInWindows(id, string.format("user_default getUserKey is nil, key(%s)", tostring(key))) then
		return ""
	end
	return string.format("%s_%s", stringz.bintohex(id), key)
end

-- @desc 将 data 的 key 转换为 string
local function setKeyToString(data)
	if type(data) ~= "table" then
		return data
	end
	local t = {}
	for k,v in pairs(data) do
		local val = v
		if type(v) == "table" then
			val = setKeyToString(v)
		end
		t[tostring(k)] = val
	end
	return t
end

-- @desc 将 data 的 key 尝试转换为 number
local function trySetKeyToNumber(data)
	if type(data) ~= "table" then
		return data
	end
	local t = {}
	for k,v in pairs(data) do
		local val = v
		if type(v) == "table" then
			val = trySetKeyToNumber(v)
		end
		t[tonumber(k) or k] = val
	end
	return t
end

-- @desc 按天记录数据，freshHour之后认为是当天
-- @params raw: true 则为解析的 string key，不转换为 number
-- @param params: {freshHour, rawKey, rawData}
-- rawKey: 默认转换 key 关联帐号
-- rawData: 默认转换 key 为 number，true 则为 json.decode 解析的 string key，不转换为 number
function userDefault.getCurrDayKey(key, default, params)
	params = params or {}
	local currTime = time.getTodayStrInClock(params.freshHour)
	local str = ccUserDefault:getStringForKey(getUserKey(key, params.rawKey), "")
	local t = str == "" and {} or json.decode(str)
	local data = t[currTime] or default
	if params.rawData then
		return data
	end
	return trySetKeyToNumber(data)
end

-- @desc 按天获取数据，freshHour之后认为是当天
-- @param params: {new, freshHour, rawKey}
function userDefault.setCurrDayKey(key, data, params)
	params = params or {}
	local userKey = getUserKey(key, params.rawKey)
	if data == nil or (type(data) == "table" and next(data) == nil) then
		ccUserDefault:deleteValueForKey(userKey)
		return
	end
	if params.new then
		ccUserDefault:deleteValueForKey(userKey)
	end

	local currTime = time.getTodayStrInClock(params.freshHour)
	local newData = {}
	if type(data) ~= "table" then
		newData[currTime] = data
	else
		newData[currTime] = userDefault.getCurrDayKey(key, {}, maptools.extend({params, {rawData = true}}))
		assert(type(newData[currTime]) == "table", string.format("key(%s) already exist and was not table", key))
		for k,v in pairs(setKeyToString(data)) do
			newData[currTime][k] = v
		end
	end
	ccUserDefault:setStringForKey(userKey, json.encode(newData))
end

-- @desc 按 key 值记录永久数据
-- @param params: {rawKey, rawData}
function userDefault.getForeverLocalKey(key, default, params)
	params = params or {}
	local str = ccUserDefault:getStringForKey(getUserKey(key, params.rawKey), "")
	if str == "" then
		return default
	end
	local data = json.decode(str)
	if params.rawData then
		return data
	end
	return trySetKeyToNumber(data)
end

-- @desc 按 key 值获取永久数据
-- @param params: {new, rawKey}
function userDefault.setForeverLocalKey(key, data, params)
	params = params or {}
	if not params.rawKey then
		onCleanup()
	end
	local userKey = getUserKey(key, params.rawKey)
	if data == nil or (type(data) == "table" and next(data) == nil)then
		ccUserDefault:deleteValueForKey(userKey)
		return
	end
	if params.new then
		ccUserDefault:deleteValueForKey(userKey)
	end

	local newData = data
	if type(data) == "table" then
		newData = userDefault.getForeverLocalKey(key, {}, maptools.extend({params, {rawData = true}}))
		assert(type(newData) == "table", string.format("key(%s) already exist and was not table", key))
		for k,v in pairs(setKeyToString(data)) do
			newData[k] = v
		end
	end
	ccUserDefault:setStringForKey(userKey, json.encode(newData))
end
