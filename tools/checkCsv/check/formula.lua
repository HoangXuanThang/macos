local ignoreList = {
}

-- 检查公式格式问题
local function main()
	print("\n***** check formula begin *****")

	local count = 0
	for k,v in ipairs(formula) do -- 遍历检查列表
		local cfg = loadstring("return csv."..v.csvName)() -- 获得配表
		for kk,vv in orderCsvPairs(cfg) do -- 遍历配表
			_gg = vv
			local value = loadstring("return _gg."..v.colName)() -- 获取检查列的值
			local flag, err = checkFormula(value)
			if flag == false then
				if not ignoreList[err] then
					count = count + 1
					printErr(v.csvName..".csv", v.colName, "line = ", kk, err)
				end
			end
		end
	end

	for k,v in ipairs(formulaDesc) do -- 遍历检查列表
		local cfg = loadstring("return csv."..v.csvName)() -- 获得配表
		for kk,vv in orderCsvPairs(cfg) do -- 遍历配表
			local flag, err, errRet = makeStrFunc(vv, v.colName, {skillLevel=1, math = math}, k)
			if err and err > 0 then
				if not ignoreList[err] then
					count = count + err
					printErr(v.csvName..".csv", v.colName, "line = ", kk, err, "\n" .. table.concat(errRet, "\n"))
				end
			end
		end
	end

	print(string.format("----- check formula end (totalCount:%d) -----\n", count))
end

return main
