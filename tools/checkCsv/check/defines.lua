--
-- Author: erriyue
-- Date: 2014-06-27 21:17:00
--

function try(block)

    -- get the try function
    local try = block[1]
    assert(try)

    -- get catch and finally functions
    local funcs = block[2]
    if funcs and block[3] then
        table.join2(funcs, block[2])
    end

    -- try to call it
    local ok, errors = pcall(try)
    if not ok then

        -- run the catch function
        if funcs and funcs.catch then
            funcs.catch(errors)
        end
    end

    -- run the finally function
    if funcs and funcs.finally then
        funcs.finally(ok, errors)
    end

    -- ok?
    if ok then
        return errors
    end
end

--local str = "fsdfas$123$fgds"
--split(str,'%$') --注意$是特殊字符 前面要加%！！ 结果返回{"fsdfas","123","fgds"}
-- 特殊字符为 ( ) . % + - * ? [ ] ^ $
function split(str,sep)
	local ret = {}
	local pos = 0
	while true do
		local pp = string.find(str,sep,pos+1)
		if pp == nil then
			table.insert(ret,string.sub(str,pos+1))
			break
		else
			table.insert(ret,string.sub(str,pos+1,pp-1))
			pos = pp
		end
	end
	return ret
end

local function conv2funcStr(s, input)
	if not string.find(s,"|") then return s end
	if s:sub(1,1) == "|" then s = s:sub(2) end
	local segs = split(s, "|")
	local funcStr = input or ""
	for i, seg in ipairs(segs) do
		local nullInfo, _ = string.find(seg,"%(.+%)") -- 存在内容 (0)
		local ps, _ = string.find(seg,"%(.*%)") -- 存在括号 ()
		local patten = ""
		local len = -2
		if not ps then
			seg = seg .. "()"
		end

		if funcStr == "" then
			funcStr = seg
		else
			seg = seg:sub(1, len) .. (nullInfo and ",%s)" or "%s)")
			funcStr = string.format(seg, funcStr)
		end
	end
	return funcStr
end


-- 简单检测格式
function checkFormula(formula)
	if not formula then
		return true
	end
	if type(formula) == "table" then
		for k,v in pairs(formula) do
			local flag, err = checkFormula(v)
			if not flag then
				return flag, err
			end
		end
		return true

	elseif type(formula) == "string" then
		-- formula = string.gsub(formula,"%%","/100")

		local func = loadstring("return "..conv2funcStr(formula))
		-- print("!!!!!!!!!!!!!", formula, func)
		if func then
			-- func()
			return true
		else
			return false, formula
		end
	end
	return true
end

--返回一公式得到的结果
-- 将函数缓存在cfg里，不要也行
function makeFunc(cfg, funcName, funcStr, env, k, errRet)
	if funcStr == nil then return nil end
	local num = tonumber(funcStr)
	if num ~= nil then  --如果是常量就直接返回
	 	return num
	end
	local err = 0
	if type(funcStr) == "table" then --如果是table就直接返回(补充了table里面也有字符串的情况，啊~)
		local tb = {}
		for i,v in ipairs(funcStr) do
			local ret = v
			if type(v) ~= 'number' then
				local ret = loadstring("return ".. v)
				-- local func = assert(loadstring("return ".. v))
				if ret then
					cfg[funcName] = ret
				else
					err = err + 1
					table.insert(errRet, string.formt("makeFunc1 error id: %s\t%s str: %s", k, funcName, funcStr))
					cfg[funcName] = function() return "" end
				end
				setfenv(func, env)
				ret = func()
				setfenv(func, {})  --把env清掉
			end
			table.insert(tb, ret)
		end
		return tb
	end
	if cfg[funcName] == nil then
		local ret = loadstring("return ".. funcStr)
		if ret then
			cfg[funcName] = ret
		else
			err = err + 1
			table.insert(errRet, string.format("makeFunc2 error id: %s\t%s str: %s", k, funcName, funcStr))
			cfg[funcName] = function() return "" end
		end
	end
	setfenv(cfg[funcName], env)
	local ret = cfg[funcName]()
	setfenv(cfg[funcName], {})  --把env清掉

	return ret, err
end

--返回字符串中带公式计算后得到的整个字符串
-- local cc = {rr = "$math.floor(1111/skillLevel)$haha$skillLevel*2$fgd"}
-- print(makeStrFunc(cc,"rr",{skillLevel = 3,math = math}))
function makeStrFunc(cfg, cfgField, env, k)
	local str = cfg[cfgField]
	if str == nil then return nil end
	local err = 0
	local len = string.len(str)
	local ret = ""
	local pos1 , pos2 = 0 , 0
	local funcId = 1
	local errRet = {}
	while true do
		pos1 = string.find(str,'%$',pos2+1)
		if pos1 == nil then
			ret = ret .. string.sub(str,pos2+1,len)
			break
		end
		if pos1 > 0 then
			ret = ret ..string.sub(str,pos2+1,pos1-1)
		end
		pos2 = string.find(str,'%$',pos1+1)
		if pos2 == nil then
			ret = ret .. string.sub(str,pos1+1,len)
			break
		end
		local funcName = string.format("%s_func_%d",cfgField,funcId)
		funcId = funcId + 1
		if string.sub(str,pos1+1,pos2-1) == "%+" then
			err = err + 1
			table.insert(errRet, string.format("has %+: %s", str))
			res = ""
		else
			local foma, count = makeFunc(cfg, funcName, string.sub(str,pos1+1,pos2-1), env, k, errRet)
			err = err + (count or 0)
			if foma == nil then
				err = err + 1
				table.insert(errRet, string.format("foma is nil:%s\t%s\t%s\t%s", cfgField, funcName, string.sub(str,pos1+1,pos2-1), k))
				res = ""
			else
				ret = ret .. foma
			end
		end
	end
	return ret, err, errRet
end


function isInTableList(T,val)
	if T == nil or type(T) ~= 'table' then return false end
	for k,v in ipairs(T) do
		if v == val then return true end
	end
	return false
end