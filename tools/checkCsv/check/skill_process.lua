-- 检查技能过程id问题

local function main()
	print("\n***** check csv.skill_process error Id begin *****")
	local count = 0
	local totalCount = 0
	local eventHash = {}
	for k, v in orderCsvPairs(csv.effect_event) do
		eventHash[v.eventID] = k
	end

	print("\n1.检查 csv.skill_process 表的 effectEventID 是否存在")
	local eventInProcess = {} -- 使用过的 skillProcess hash
	for k,v in orderCsvPairs(csv.skill_process) do
		if v.effectEventID then
			local id = v.effectEventID
			eventInProcess[id] = true
			if v.noCheckCsv ~= true then
				if not csv.effect_event[id] then
					count = count + 1
					printErr("csv.skill_process id = ", k, " not exist effectEventID: ", id)
				else
					local others = csv.effect_event[id].otherEventIDs
					if others then
						for _,otherID in ipairs(others) do
							if not eventHash[otherID] then
								count = count + 1
								printErr("csv.skill_process id = ", k, " not exist otherEventIDs: ", id)
							else
								eventInProcess[eventHash[otherID]] = true
							end

						end
					end
				end
			end
		end
	end
	totalCount = totalCount + count
	print("error:", count)

	print("\n2.检查 csv.effect_event 表的 id 是否出现在 skill_process 表中")
	count = 0
	for k,v in orderCsvPairs(csv.effect_event) do
		if not eventInProcess[k] and v.noCheckCsv ~= true then
			count = count + 1
			printWarn("csv.effect_event id = ", k, " not used in csv.skill_process")
		end
	end
	print("error:", count)

	print("\n3.检查 csv.effect_event 表的伤害分段和治疗分段之和是否 = 1")
	count = 0
	for k,v in orderCsvPairs(csv.effect_event) do
		if v.noCheckCsv ~= true then
			local hpSeg = v.hpSeg
			if hpSeg then
				local hpCount = 0
				for k2,v2 in ipairs(hpSeg) do
					hpCount = hpCount + v2
				end
				if math.abs(hpCount - 1) > 1e-5 then
					count = count + 1
					printErr("csv.effect_event id = ", k, "hpSeg sum error = ",hpCount,"diff = ",hpCount - 1)
				end
			end
			local damageSeg = v.damageSeg
			if damageSeg then
				local dmgCount = 0
				for k2,v2 in ipairs(damageSeg) do
					dmgCount = dmgCount + v2
				end
				if math.abs(dmgCount - 1) > 1e-5 then
					count = count + 1
					printErr("csv.effect_event id = ", k, "damageSeg sum error = ",dmgCount,"diff = ",dmgCount - 1)
				end
			end
		end
	end
	totalCount = totalCount + count
	print("error:", count)

	print(string.format("----- check csv.skill_process error Id end  (totalCount:%d) -----", totalCount))
end

return main