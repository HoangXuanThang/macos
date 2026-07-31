-- 检查场景配置是否存在

local function main()
	print("\n***** check csv.monster_scenes monsters id not exist begin *****")
	local gMonsterCsv = {}
	for k,v in orderCsvPairs(csv.monster_scenes) do
		if gMonsterCsv[v.scene_id] == nil then gMonsterCsv[v.scene_id] = 0 end
		local roundOK = false
		for _, id in ipairs(v.monsters) do
			if id ~= 0 then
				if not csv.unit[id] then
					printWarn(string.format("csv.monster_scenes id (%d) monsters id (%d) not exist in csv.unit", k, id))
				else
					roundOK = true
				end
			end
		end
		if roundOK and (gMonsterCsv[v.scene_id] + 1) == v.round then
			gMonsterCsv[v.scene_id] = v.round
		end
	end
	print("----- check csv.monster_scenes monsters id not exist end -----")

	print("\n***** check csv.scene_conf sceneCount is ok begin *****")
	for k,v in orderCsvPairs(csv.scene_conf) do
		if not gMonsterCsv[k] then
			printWarn(string.format("csv.scene_conf id (%d) not in csv.monster_scenes", k))
		elseif k ~= 5000 and k > 100 and v.sceneCount ~= gMonsterCsv[k] then
			printWarn(string.format("csv.scene_conf id (%d) sceneCount (%d) not equal csv.monster_scenes round (%d)", k, v.sceneCount, gMonsterCsv[k]))
		end
	end
	print("----- check csv.scene_conf sceneCount is ok end -----")
end

return main