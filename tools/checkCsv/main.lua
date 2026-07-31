require "list"
require "check.defines"

local insert = table.insert
local sort = table.sort

function split(str,sep)
	local ret = {}
	local pos = 0
	while true do
		local pp = string.find(str,sep,pos+1)
		if pp == nil then
			insert(ret,string.sub(str,pos+1))
			break
		else
			insert(ret,string.sub(str,pos+1,pp-1))
			pos = pp
		end
	end
	return ret
end

function orderPairs(t, cmp)
	local order = {}
	for k,_ in pairs(t) do
		insert(order, k)
	end
	sort(order, cmp)
	local i = 0
	return function()
		i = i + 1
		local idx = order[i]
		return idx, t[idx]
	end
end

function ucfirst(input)
	return string.upper(string.sub(input, 1, 1)) .. string.sub(input, 2)
end

local htmlData = {info = {}, warn = {}, error = {}}
local curMethod = ""

function printInfo(...)
	print('[INFO]', ...)
	insert(htmlData.info, {curMethod = curMethod, log = table.concat({...}, " ")})
end

function printWarn(...)
	print('[WARN]', ...)
	insert(htmlData.warn, {curMethod = curMethod, log = table.concat({...}, " ")})
end

function printErr(...)
	print('[ERROR]', ...)
	print()
	insert(htmlData.error, {curMethod = curMethod, log = table.concat({...}, " ")})
end

-- htmlTextTemplate: title, date, summaryInfo, infoCount, warnCount, errorCount, results
-- htmlTextResultTemplate: key, result(upper key), method, desc, log
local function writeHtmlData(params)
	local htmlName = "checkCsvReport.html"
	local htmlFile = io.open(htmlName, "w+")
	local resultsT = {}
	local testAllCount = 0
	for key, data in pairs(htmlData) do
		testAllCount = testAllCount + #data
		for _, v in ipairs(data) do
			insert(resultsT, string.format(htmlTextResultTemplate, key, ucfirst(key), v.curMethod[1], v.curMethod[3], v.log))
		end
	end
	htmlFile:write(string.format(htmlTextTemplate, htmlName, os.date("%y年%m月%d日-%H:%M:%S"), string.format("%s tests ran in %s seconds.<br/>%s", testAllCount, params.time, params.info), #htmlData.info, #htmlData.warn, #htmlData.error, table.concat(resultsT)))
	htmlFile:close()
end

local function parsArgs()
	local ret = {args = {}}
	local key
	for _, v in pairs(_G.arg) do
		if v:sub(1, 1) == "-" then
			key = v
		else
			if key then
				ret[key] = v
				key = nil
			else
				insert(ret.args, v)
			end
		end
	end
	return ret
end

local function main()
	local infoT = {}
	insert(infoT, '------------------')
	insert(infoT, os.execute('cd'))
	local cmdArgs = parsArgs()
	insert(infoT, '------------------')

	_G.GAME01_PATH = "../../client/game01_new"
	if cmdArgs['-d'] then
		package.path = cmdArgs['-d'] .. "/?.lua;" .. package.path
		insert(infoT, package.path)
		_G.GAME01_PATH = cmdArgs['-d'] .. "/.."
	else
		package.path = package.path .. ";../../client/game01_new/src/?.lua"
		insert(infoT, package.path)
	end
	print(table.concat(infoT, "\n"))

	globals = globals or _G
	device = {platform = "windows"}
	lua_type = type
	ANTI_AGENT = true
	require "util.functools"
	require "util.csv"
	require "util.helper"
	require "easy.table"
	require "util.lazy_require"
	require "config.csv"
	insert(infoT, 3, dumps(cmdArgs))

	local tic = os.clock()

	checkFun = {}
	for k, v in ipairs(checkMethod) do
		v[3] = k .. ". " .. v[3]
		insert(infoT, table.concat(v, "&nbsp;&nbsp;&nbsp;&nbsp;"))
		checkFun[v[1]] = require("check." .. v[1])
	end

	if not cmdArgs.args[1] or cmdArgs.args[1] == "all" or cmdArgs.args[1] == "0" then
		for _,v in ipairs(checkMethod) do
			curMethod = v
			checkFun[v[1]]()
		end
	else
		local checkMethodKey = {}
		for k,v in ipairs(checkMethod) do
			checkMethodKey[tostring(k)] = k
			checkMethodKey[v[1]] = k
		end
		for _,v in pairs(cmdArgs.args) do
			if checkMethodKey[v] then
				curMethod = checkMethod[checkMethodKey[v]]
				print("\n" .. checkMethod[checkMethodKey[v]][3])
				checkFun[checkMethod[checkMethodKey[v]][1]]()
			end
		end
	end
	local toc = os.clock()
	writeHtmlData({time = toc-tic, info = table.concat(infoT, "<br/>")})
end

main()