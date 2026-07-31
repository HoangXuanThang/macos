--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2017 TianJi Information Technology Inc.
--

local insert = table.insert
local sort = table.sort

-- map table相关库函数
local maptools = {}
globals.maptools = maptools

-- extend({{ name = 'moe' }, { age = 50 }, ...})
-- => { name = 'moe', age = 50 }
function maptools.extend(t)
	local ret = {}
	for _, arg in ipairs(t) do
		for k, v in pairs(arg) do
			ret[k] = v
		end
	end
	return ret
end

function maptools.extend_inplace(t, t2)
	for _, arg in ipairs(t2) do
		for k, v in pairs(arg) do
			t[k] = v
		end
	end
	return t
end

-- set union, a|b|c|...
maptools.union = maptools.extend

-- set intersection, a&b&c&...
-- intersection({{ name = 'moe' }, { age = 50, name = 'hello' }, ...})
-- => { name = 'hello' }
function maptools.intersection(t)
	local ret = {}
	local first = t[1]
	for k, v in pairs(first) do
		for _, arg in ipairs(t) do
			v = arg[k]
			if v == nil then
				break
			end
		end
		ret[k] = v
	end
	return ret
end

-- set difference, a-b-c-...
-- minus({{ age = 50, name = 'hello' }, { name = 'moe' }, ...})
-- => { age = 50 }
function maptools.minus(t)
	local ret = {}
	local first = t[1]
	for k, v in pairs(first) do
		for i = 2, #t do
			if t[i][k] ~= nil then
				v = nil
				break
			end
		end
		ret[k] = v
	end
	return ret
end

-- set symmetric difference, a^b^c^...
-- xor({{ name = 'moe' }, { age = 50, name = 'hello' }, ...})
-- => { age = 50 }
function maptools.xor(t)
	local ret = {}
	local cnt = {}
	for _, arg in ipairs(t) do
		for k, v in pairs(arg) do
			ret[k] = v
			cnt[k] = (cnt[k] or 0) + 1
		end
	end
	for k, v in pairs(cnt) do
		if v % 2 == 0 then
			ret[k] = nil
		end
	end
	return ret
end

-- default sort by key
-- for k, v in order_pairs({5='b', 1='a'}) do print(k, v) end
-- => 1 a
--    2 b
function maptools.order_pairs(t, cmp)
	local order = {}
	for k, v in pairs(t) do
		insert(order, k)
	end
	local f = cmp
	if type(f) == "string" then
		f = function(v1, v2)
			return v1[cmp] < v2[cmp]
		end
	end
	if f then
		local ff = f
		f = function(k1, k2)
			return ff(t[k1], t[k2])
		end
	end
	sort(order, f)
	local i = 0
	return function()
		i = i + 1
		local idx = order[i]
		return idx, t[idx]
	end
end

function maptools.filter_inplace(t, f)
	for k, v in pairs(t) do
		if not f(k, v) then
			t[k] = nil
		end
	end
	return t
end