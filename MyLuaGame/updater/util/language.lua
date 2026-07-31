--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2017 TianJi Information Technology Inc.
--
-- 语言本地化处理
--

local format = string.format

-- @desc 返回本地化描述文字的字段
function globals.getL10nField(field)
	if LOCAL_LANGUAGE == 'cn' then
		return field
	else
		return format('%s_%s', field, LOCAL_LANGUAGE)
	end
end

-- @desc 返回本地化描述文字
function globals.getL10nStr(csv, field)
	if LOCAL_LANGUAGE == 'en' then
		return csv[field]
	else
		return csv[format('%s_%s', field, LOCAL_LANGUAGE)]
	end
end

-- @desc 判断是否是本地版本
function globals.checkLanguage(language)
	language = language or 'en'
	return LOCAL_LANGUAGE == language
end

-- @desc 判断t是否包含本地语言
function globals.matchLanguage(t)
	t = t or {}
	for k,v in pairs(t) do
		if v == LOCAL_LANGUAGE then
			return true
		end
	end
	return false
end
