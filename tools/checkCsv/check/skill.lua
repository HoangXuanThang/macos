-- 检查技能id问题

local format = string.format

local function main()
	print("\n***** check csv.skill error Id begin *****")
	local count = 0
	local totalCount = 0
	local skill = csv.skill
	local skill_process = csv.skill_process
	print("\n1.检查 unit 表和 cards 表等配表中 的 skillId 是否存在")
	local checkMap = {
		[1] = {
			key = "cards",
			cfg = csv.cards,
			name = "skillList",
		},
		[2] = {
			key = "cards",
			cfg = csv.cards,
			name = "skinSkillMap",
		},
		[3] = {
			key = "unit",
			cfg = csv.unit,
			name = "skillList",
		},
		[4] = {
			key = "unit",
			cfg = csv.unit,
			name = "passiveSkillList",
		},
		[5] = {
			key = "card_star_skill",
			cfg = csv.card_star_skill,
			name = "starSkillList",
		},
		[6] = {
			key = "held_item.effect",
			cfg = csv.held_item.effect,
			name = "skillID",
			type = "num",
		},
		[7] = {
			key = "explorer.explorer_effect",
			cfg = csv.explorer.explorer_effect,
			name = "skillID",
			type = "num",
		},
		[8] = {
			key = "card_ability",
			cfg = csv.card_ability,
			name = "skillID",
			type = "num",
		},
		[9] = {
			key = "role_figure",
			cfg = csv.role_figure,
			name = "skills",
		},
		[10] = {
			key = "gym.talent_buff",
			cfg = csv.gym.talent_buff,
			name = "skillID",
			type = "num",
		},
		[11] = {
			key = "brave_challenge.badge",
			cfg = csv.brave_challenge.badge,
			name = "skillIDs",
		},
		[12] = {
			key = "random_tower.buffs",
			cfg = csv.random_tower.buffs,
			name = "passiveSkill",
			type = "num",
		},
	}
	local hashSkill = {} -- 使用过的 skill hash
	for _, checkData in orderCsvPairs(checkMap) do
		if checkData.type == "num" then
			for k,v in orderCsvPairs(checkData.cfg) do
				local skillId = v[checkData.name]
				if skillId and skillId ~= 0 then
					hashSkill[skillId] = true
					if v.noCheckCsv ~= true then
						if not skill[skillId] then
							count = count + 1
							printErr(format("csv.%s %s id(%s), not exist skill id(%s)", checkData.key, checkData.name, k, skillId))
						end
					end
				end
			end
		else
			for k,v in orderCsvPairs(checkData.cfg) do
				local skillIds = {}
				local skillList = v[checkData.name]
				for _,vv in csvMapPairs(skillList) do
					if type(vv) == "number" then
						hashSkill[vv] = true
						if not skill[vv] then
							table.insert(skillIds, vv)
						end
					else
						for _, vvv in pairs(vv) do
							hashSkill[vvv] = true
							if not skill[vvv] then
								table.insert(skillIds, vvv)
							end
						end
					end
				end
				if v.noCheckCsv ~= true then
					if #skillIds > 0 then
						count = count + 1
						printErr(format("csv.%s %s id(%s), not exist skill id(%s)", checkData.key, checkData.name, k, table.concat(skillIds, ", ")))
					end
				end
			end
		end
	end
	totalCount = totalCount + count
	print("error:", count)

	print("\n2.检查 skill 表的 id 是否出现在 unit 表和 cards 表等配表中")
	count = 0
	for k,v in orderCsvPairs(skill) do
		if not hashSkill[k] and v.noCheckCsv ~= true then
			count = count + 1
			printErr("csv.skill id = ", k, " not used in csv.cards or csv.unit or other csv")
		end
	end
	totalCount = totalCount + count
	print("error:", count)

	print("\n3.检查 skill 表中的 skillProcess Id 是否存在")
	count = 0
	local hashSkillProcess = {} -- 使用过的 skillProcess hash
	for k,v in orderCsvPairs(skill) do
		if v.skillProcess then
			local ids = {}
			for kk,vv in ipairs(v.skillProcess) do
				hashSkillProcess[vv] = true
				if v.noCheckCsv ~= true then
					if not skill_process[vv] then
						table.insert(ids, vv)
					end
				end
			end
			if #ids > 0 then
				count = count + 1
				printErr("csv.skill id = ", k, " not exist skillProcess Id: ", table.concat(ids, ", "))
			end
		end
	end
	totalCount = totalCount + count
	print("error:", count)

	print("\n4.检查 skill_process 表的 id 是否出现的在 skill 表中")
	count = 0
	for k,v in orderCsvPairs(skill_process) do
		if not hashSkillProcess[k] and v.noCheckCsv ~= true then
			count = count + 1
			printWarn("csv.skill_process id = ", k, " not used in csv.skill")
		end
	end
	totalCount = totalCount + count
	print("error:", count)

	print(string.format("----- check csv.skill error Id end  (totalCount:%d) -----", totalCount))
end

return main