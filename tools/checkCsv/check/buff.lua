-- 检查buff是否使用

local function main()
	print("\n***** check csv.buff not used Id begin *****")
	local hash = {}
	local csvBuff = csv.buff
	for kk,vv in orderCsvPairs(csv.unit) do
		if vv.buffId then
			for kkk,vvv in pairs(vv.buffId) do
				hash[vvv] = true
				if vv.noCheckCsv ~= true then
					if not csvBuff[vvv] then
						printErr("csv.unit id = ", kk, "not exist buffId :", vvv)
					end
				end
			end
		end
	end

	for kk,vv in orderCsvPairs(csv.skill_process) do
		if vv.buffList then
			for kkk,vvv in pairs(vv.buffList) do
				hash[vvv] = true
				if vv.noCheckCsv ~= true then
					if not csvBuff[vvv] then
						printErr("csv.skill_process id = ", kk, "not exist buffList :", vvv)
					end
				end
			end
		end
	end

	local tmp = {}
	for k,v in orderCsvPairs(csvBuff) do
		if not hash[k] and v.noCheckCsv ~= true then
			table.insert(tmp, k)
		end
	end
	if #tmp > 0 then
		printInfo("csv.buff Id not used = ", table.concat(tmp, ", "))
	end

	print("----- check csv.buff end -----")
end

return main