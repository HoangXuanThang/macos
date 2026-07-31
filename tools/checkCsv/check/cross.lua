-- 检查cross配置表是否正常

local tinsert = table.insert

local STATE_TYPE = {
	info = 1,
	warn = 2,
	error = 3,
}

local LANGUAGE_TYPE = {
	-- ["dev"] = 1,
	-- ["sg"] = 2,
	["cn"] = 3,
	["cn_qd"] = 4,
	["kr"] = 5,
	-- ["tw"] = 6,
	-- ["en"] = 7,
	-- ["th"] = 8,
	-- ["vn"] = 9,

}
-- 默认常规检测下一期的跨服组连续区间
local SERVICE_TYPE = {
	crosscraft = {
		order = 1,
		desc = "跨服石英，开启周期1周开2次",
		nextTimes = 2,
	},
	crossgym = {
		order = 2,
		desc = "道馆，开启周期1周，需要endDate",
		nextDay = 7,
		endDate = true,
	},
	crossmine = {
		order = 3,
		desc = "跨服资源战，开启周期1周",
		nextDay = 7,
	},
	crossfishing = {
		order = 4,
		desc = "钓鱼大赛，开启周期2周，配置或自动生成跨服组",
		nextDay = 14,
		autoServers = true,
	},
	crossunionqa = {
		order = 5,
		desc = "公会问答，开启周期2周，配置或自动生成跨服组，需要endDate",
		nextDay = 14,
		autoServers = true,
		endDate = true,
	},
	crossarena = {
		order = 6,
		desc = "跨服竞技场，开启周期3周",
		nextDay = 21,
	},
	onlinefight = {
		order = 7,
		desc = "对战竞技场，开启周期约2个月，需要endDate",
		endDate = true,
		endDateNextDay = 13,
	},
	-- 不定期
	skyscraper = {
		order = 101,
		desc = "叠高楼小游戏，不定期，自动生成跨服组，需要endDate",
		autoServers = true,
		endDate = true,
		unsurenessOpen = true,
	},
	huodongboss = {
		order = 102,
		desc = "万圣节boss，不定期，自动生成跨服组，需要endDate",
		autoServers = true,
		endDate = true,
		unsurenessOpen = true,
	},
	crossredpacket = {
		order = 103,
		desc = "春节跨服红包，不定期，自动生成跨服组，需要endDate",
		autoServers = true,
		endDate = true,
		unsurenessOpen = true,
	},
	bravechallengeranking = {
		order = 104,
		desc = "周年庆勇者挑战，不定期，自动生成跨服组，需要endDate",
		autoServers = true,
		endDate = true,
		unsurenessOpen = true,
	},
	horseraceranking = {
		order = 105,
		desc = "周年庆赛跑排行榜，不定期，自动生成跨服组，需要endDate",
		autoServers = true,
		endDate = true,
		unsurenessOpen = true,
	},
	crosshorse = {
		order = 106,
		desc = "周年庆赛跑全服一致<all>，不定期，需要endDate",
		allServers = true,
		-- autoServers = true,
		endDate = true,
		unsurenessOpen = true,
	},
}

-- 合服索引配置
-- 记录所有已合并的服务器直属的合并表ID, 可递归判定最终目的服务器合并表ID
-- {"game.cn.1" = 101, "gamemerge.cn.1" = 102} -- 有二次合服
local serverKeys = {}
-- 记录所有目的服务器，serverKeys中非destServerKey的key则为原始服务器
-- {"gamemerge.cn.1" = 101, "gamemerge.cn.2" = 102}
local destServerKey = {}
for k, v in orderCsvPairs(csv.server.merge) do
	if destServerKey[v.destServer] then
		error(string.format("csv.server.merge: (%s) can't exist in (%d) and (%d) at the same time", v.destServer, destServerKey[v.destServer], k))
	end
	destServerKey[v.destServer] = k
	for _, key in ipairs(v.servers) do
		if serverKeys[key] then
			error(string.format("csv.server.merge: (%s) can't exist in (%d) and (%d) at the same time", key, serverKeys[key], k))
		end
		serverKeys[key] = k
	end
end
local function getDestServerID(id)
	local destServer = csv.server.merge[id].destServer
	local newId = serverKeys[destServer]
	if not newId then
		return id
	end
	return getDestServerID(newId)
end
local function getServers(tb, id)
	local cfg = csv.server.merge[id]
	local destServer = cfg.destServer
	if tb[destServer] then
		return tb[destServer].servers
	end
	local t = {}
	for _, key in ipairs(cfg.servers) do
		local mergeId = destServerKey[key]
		if mergeId then
			local servers = getServers(tb, mergeId)
			for _,server in ipairs(servers) do
				tinsert(t, server)
			end
		else
			tinsert(t, key)
		end
	end
	tb[destServer] = {servers = t, id = cfg.serverID}
	return t
end
-- 源服务器对应的最终目的服务器合并表ID
-- {["game.cn.1"] = 102, ["game.cn.2"] = 102, ["game.cn.6"] = 102}
gServersMergeID = {}
-- 目的服务器对应的所有源服务器
-- {
-- 	["gamemerge.cn.1"] = {servers = {"game.cn.1", "game.cn.2"}, id = 1},
-- 	["gamemerge.cn.2"] = {servers = {"game.cn.1", "game.cn.2", "game.cn.6"}, id = 1}
-- }
gDestServer = {}
for k,v in orderCsvPairs(csv.server.merge) do
	local id = getDestServerID(k)
	for _, key in ipairs(v.servers) do
		if not destServerKey[key] then
			gServersMergeID[key] = id
		end
	end
	getServers(gDestServer, k)
end


local function checkCrossService(servers)
	local orginServersHash = {}
	local orginServers = {} -- 所有服务器
	local serversCount = {} -- 跨服组数分布
	local hasMergeServers = false
	local mergeServersCount = {} -- 跨服组数分布(合服算一个)
	local ret = {}
	local retState = STATE_TYPE.info
	local nowDate = tonumber(os.date("%Y%m%d", os.time()))

	local addServer = function (server, data)
		local t = split(server, '%.')
		local key = tonumber(t[#t])
		if not key then
			retState = math.max(retState, STATE_TYPE.error)
			tinsert(ret, string.format("[ERROR] server(%s) 异常配置 csvId(%s) %s %s", server, data.csvId, data.language, data.date))
			return
		end
		if orginServersHash[key] then
			retState = math.max(retState, STATE_TYPE.error)
			tinsert(ret, string.format("[ERROR] server(%s) 重复配置 csvId(%s) %s %s", server, data.csvId, data.language, data.date))
			return
		end
		orginServersHash[key] = true
		tinsert(orginServers, {server = server, key = key, language = data.language, date = data.date})
		serversCount[data.csvId] = serversCount[data.csvId] and (serversCount[data.csvId] + 1) or 1
	end

	for server, data in pairs(servers) do
		if serverKeys[server] or gServersMergeID[server] then
			-- 仅输出时间大于等于当前日期的
			if data.date >= nowDate then
				retState = math.max(retState, STATE_TYPE.warn)
				tinsert(ret, string.format("[WARN] server(%s) 已合服, 检查配置 csvId(%s) %s %s", server, data.csvId, data.language, data.date))
			end
		end
		if gDestServer[server] then
			hasMergeServers = true
			for _, v in ipairs(gDestServer[server].servers) do
				addServer(v, data)
			end
		else
			addServer(server, data)
		end
		mergeServersCount[data.csvId] = mergeServersCount[data.csvId] and (mergeServersCount[data.csvId] + 1) or 1
	end
	table.sort(orginServers, function(a, b)
		return a.key < b.key
	end)
	local first = orginServers[1]
	if not first then
		return "", retState, ret
	end

	-- 检查显示缺失服务器
	local t = {}
	local idx = 1
	for _, s in ipairs(orginServers) do
		if s.key > idx then
			if s.key == idx + 1 then
				tinsert(t, idx)
			else
				tinsert(t, idx .. "-" .. s.key - 1)
			end
			t[#t] = idx
		end
		idx = s.key + 1
	end
	if #t > 0 then
		retState = math.max(retState, STATE_TYPE.error)
		tinsert(ret, string.format("[ERROR] 缺失服务器组 %s %s：(%s)", first.language, first.date, table.concat(t, " ")))
	end
	local str = string.format("%s-%s", first.key, orginServers[#orginServers].key)

	local function getServersCount(serversCount)
		local count = {}
		for _, v in pairs(serversCount) do
			count[v] = count[v] and (count[v] + 1) or 1
		end
		local s1 = {}
		for servers, cnt in pairs(count) do
			table.insert(s1, {servers = servers, cnt = cnt})
		end
		table.sort(s1, function(a, b)
			if a.servers ~= b.servers then
				return a.servers < b.servers
			end
			return a.cnt < b.cnt
		end)
		local s2 = {}
		for _, v in ipairs(s1) do
			table.insert(s2, string.format("%d个服(%d组)", v.servers, v.cnt))
		end
		return s2
	end
	-- 跨服组分布
	local s = getServersCount(serversCount)
	str = str .. "\n\t跨服组分布: \t\t" .. table.concat(s, " | ")

	-- 跨服组数分布(合服算一个)
	if hasMergeServers then
		local s = getServersCount(mergeServersCount)
		str = str .. "\n\t跨服组分布(合服算一个): \t" .. table.concat(s, " | ")
	end
	return str, retState, ret
end

local function main()
	local nowDate = tonumber(os.date("%Y%m%d", os.time()))
	print("\n***** check cross begin *****")
	local services = {} -- ['mine'/'craft'/'arena'][cn][20171208] = {['gamemerge.1'] = 'cross.2'}
	local cross = {} -- 是否cross重复检测
	local ret = {}
	for id, v in orderCsvPairs(csv.cross.service) do
		-- 内网不处理
		local language = split(v.cross, "%.")[2] or v.cross
		if language == "" then
			tinsert(ret, string.format("cross(%s) 配置异常 csvId(%d)", v.cross, id))

		elseif language ~= "dev" then
			-- 配置或自动生成跨服组的不检测是否连续服务器
			services[v.service] = services[v.service] or {}
			services[v.service][language] = services[v.service][language] or {}
			services[v.service][language][v.date] = services[v.service][language][v.date] or {}

			cross[v.service] = cross[v.service] or {}
			cross[v.service][v.date] = cross[v.service][v.date] or {}
			if cross[v.service][v.date][v.cross] then
				tinsert(ret, string.format("cross(%s) 重复配置在 csvId(%d) 和 csvId(%d)", v.cross, id, cross[v.service][v.date][v.cross]))
			end
			cross[v.service][v.date][v.cross] = id

			if SERVICE_TYPE[v.service] and SERVICE_TYPE[v.service].endDate then
				if v.endDate < v.date then
					tinsert(ret, string.format("csvId(%d) %s endDate错误，小于开启日期 endDate(%s) < date(%s)", id, v.service, v.endDate, v.date))
				end
			end
			if SERVICE_TYPE[v.service] and SERVICE_TYPE[v.service].allServers then
				if #v.servers ~= 1 or v.servers[1] ~= 'all' then
					tinsert(ret, string.format("csvId(%d) %s servers错误，全服必须配置<all>", id, v.service))
				end
			else
				for _, server in ipairs(v.servers) do
					if services[v.service][language][v.date][server] then
						tinsert(ret, string.format("server(%s) 重复配置 services(%s) date(%s) 在 csvId(%d) 和 csvId(%d)", server, v.service, v.date, id, services[v.service][v.date][server].csvId))
					end
					services[v.service][language][v.date][server] = {service = v.service, date = v.date, endDate = v.endDate, language = language, cross = v.cross, csvId = id}
				end
			end
		end
	end
	if #ret > 0 then
		printErr(table.concat(ret, "\n"))
	end
	print()

	local t = os.date("!*t", os.time())
	t.day = t.day - 31
	local checkDate = tonumber(os.date("%Y%m%d", os.time(t)))

	local function servicesCmp(a, b)
		local ta = SERVICE_TYPE[a] and SERVICE_TYPE[a].order or 999
		local tb = SERVICE_TYPE[b] and SERVICE_TYPE[b].order or 999
		return ta < tb
	end
	local function languageCmp(a, b)
		local ta = LANGUAGE_TYPE[a] or 999
		local tb = LANGUAGE_TYPE[b] or 999
		return ta < tb
	end
	local starttime = os.clock()
	for service, serviceData in orderPairs(services, servicesCmp) do
		local ret = {}
		local retState = STATE_TYPE.info
		if SERVICE_TYPE[service] then
			tinsert(ret, SERVICE_TYPE[service].desc)
		end
		-- 显示下几期的预配置
		local nextTimes = SERVICE_TYPE[service] and SERVICE_TYPE[service].nextTimes or 1

		local unsurenessOpen = SERVICE_TYPE[service] and SERVICE_TYPE[service].unsurenessOpen
		tinsert(ret, string.format("*** check %s ***", service))
		-- 显示每个语言最近一期已开启的玩法和下一期将要开启的玩法检测
		for language, languageData in orderPairs(serviceData, languageCmp) do
			local datas = {{}}
			for date, info in orderPairs(languageData) do
				if service == "onlinefight" or date >= checkDate then
					local _, t = next(info)
					local endDate = t and t.endDate
					if date >= nowDate then
						datas[#datas + 1] = {date = date, endDate = endDate, info = info}
						-- if #datas > nextTimes then
						-- 	break
						-- end
					else
						datas[1] = {date = date, endDate = endDate, info = info}
					end
				end
			end
			local function getNextDate(idx)
				if SERVICE_TYPE[service] and SERVICE_TYPE[service].nextDay then
					local t = {
						year = math.floor(datas[idx].date/10000),
						month = math.floor((datas[idx].date%10000)/100),
						day = math.floor(datas[idx].date%100) + SERVICE_TYPE[service].nextDay,
						hour = 0,
						min = 0,
						sec = 0,
					}
					return tonumber(os.date("%Y%m%d", os.time(t)))
				end
				if SERVICE_TYPE[service] and SERVICE_TYPE[service].endDateNextDay and datas[idx].endDate then
					local t = {
						year = math.floor(datas[idx].endDate/10000),
						month = math.floor((datas[idx].endDate%10000)/100),
						day = math.floor(datas[idx].endDate%100) + SERVICE_TYPE[service].endDateNextDay,
						hour = 0,
						min = 0,
						sec = 0,
					}
					return tonumber(os.date("%Y%m%d", os.time(t)))
				end
			end
			local nextDate
			if next(datas[1]) then
				local info, infoRetState, infoRet = checkCrossService(datas[1].info)
				retState = math.max(retState, infoRetState)
				tinsert(ret, string.format("%s%s 已开启 %s %s", table.concat(infoRet, "\n") .. (#infoRet == 0 and "" or "\n"), language, datas[1].date, info))
				nextDate = getNextDate(1)
			end
			for i = 2, #datas do
				local data = datas[i]
				local info, infoRetState, infoRet = checkCrossService(data.info)
				retState = math.max(retState, infoRetState)
				tinsert(ret, string.format("%s%s 下一期 %s %s", table.concat(infoRet, "\n") .. (#infoRet == 0 and "" or "\n"), language, data.date, info))
				if nextDate and data.date ~= nextDate then
					retState = math.max(retState, STATE_TYPE.warn)
					tinsert(ret, string.format("[WARN] 预计开启日期(%s)与配置日期(%s)不一致，检查配置是否异常", nextDate, data.date))
				end
				nextDate = getNextDate(i)
			end
			if not unsurenessOpen and #datas < nextTimes + 1 then
				retState = math.max(retState, STATE_TYPE.warn)
				local pre = ""
				if SERVICE_TYPE[service] and SERVICE_TYPE[service].endDate and #datas > 0 and datas[#datas].endDate then
					pre = "上一期结束日期 " .. datas[#datas].endDate .. ", "
				end
				tinsert(ret, string.format("[WARN] %s %s下一期未配置%s", language, pre, nextDate and (", 预计配置开启日期 " .. nextDate) or ""))
			end
			tinsert(ret, " ")
		end
		print()
		if retState == STATE_TYPE.error then
			printErr(table.concat(ret, "\n"))
		elseif retState == STATE_TYPE.warn then
			printWarn(table.concat(ret, "\n"))
		else
			printInfo(table.concat(ret, "\n"))
		end
	end
	local endtime = os.clock()
	print(string.format( "cost time : %.4f",endtime - starttime))
	print("----- check cross end -----\n")
end

return main