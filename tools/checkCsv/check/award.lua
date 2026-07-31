-- 检查奖励类dict字典配置是否合理

local validStringKey = {
	gold = 'number',
	exp = 'number',
	role_exp = 'number',
	stamina = 'number',
	rmb = 'number',
	recharge_rmb = 'number',
	coin1 = 'number',
	coin2 = 'number',
	coin3 = 'number',
	coin4 = 'number',
	coin5 = 'number',
	coin6 = 'number',
	coin7 = 'number',
	coin8 = 'number',
	coin9 = 'number',
	coin10 = 'number',
	coin11 = 'number',
	coin12 = 'number',
	coin13 = 'number',
	coin14 = 'number',
	yycoin = 'number',
	talent_point = 'number',
	explore_point = 'number',
	equip_awake_frag = 'number',
	vip_exp = 'number',
	cards = 'table',
	card = 'table',
}

local function id2csv(id)
	if id <= 10000 then
		return csv.items, "csv.items"
	elseif id <= 20000 then
		return csv.equips, "csv.equips"
	elseif id <= 30000 then
		return csv.fragments, "csv.fragments"
	elseif id <= 40000 then
		return csv.held_item.items, "csv.held_item.items"
	elseif id <= 50000 then
		return csv.gem.gem, "csv.gem.gem"
	end
end

local function check(t)
	local ret = {}
	for k, v in csvMapPairs(t) do
		local flag = true
		if type(k) == 'number' then
			flag = type(v) == 'number'
			local config, name = id2csv(k)
			if config == nil or config[k] == nil then
				flag = false
				table.insert(ret, string.format("no such id(%s) in %s", k, name))
			end
		else
			if type(v) ~= validStringKey[k] then
				flag = false
			else
				if k == "cards" then
					-- x+csv.cards[x].star*10000
					for _, cardID in ipairs(v) do
						local old = cardID
						cardID = cardID % 10000
						if csv.cards[cardID] == nil then
							flag = false
							table.insert(ret, string.format("%s no such cardId(%s) in csv.cards", old, cardID))
						end
					end
				end
			end
		end
		-- must be int
		if flag and type(v) == 'number' then
			flag = math.ceil(v) == v
		end

		if not flag then
			table.insert(ret, string.format("wrong %s = %s", k, v))
			return false, k, v, ret
		end
	end
	return true
end

local function main()
	print("\n***** check award begin *****")
	for _, info in ipairs(awardPaths) do
		print("-- check", info.csvName, info.colName)
		local config = loadstring("return csv." .. info.csvName)()
		if not config then
			printWarn("csv." .. info.csvName .. " not exist")
		else
			for k, v in csvMapPairs(config) do
				local column = v[info.colName]
				local flag, kk, vv, ret = check(column)
				if not flag then
					printErr(string.format("%s[%d].%s\n%s", info.csvName, k, info.colName, table.concat(ret, "\n")))
				end
			end
		end
	end
	print("----- check award end -----")
end

return main
