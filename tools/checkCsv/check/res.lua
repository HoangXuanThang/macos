-- 检查资源是否存在

local function checkExistRes(resPath)
	if not resPath or resPath == "" then
		return true
	end
	local originPath = resPath
	-- 处理 zhanjitianshishou_skill2.json[bs -1 1]
	if string.find(resPath, "%]$") then
		local pos = string.find(resPath,"%[")
		resPath = string.sub(resPath, 1, pos - 1)
	end
	if string.find(resPath, "%.skel$") then
		resPath = "spine/" .. resPath
	elseif string.find(resPath, "%.mp3$") then
		resPath = "sound/" .. resPath
	elseif string.find(resPath, "%.mp4$") then
		resPath = "video/" .. resPath
	elseif string.find(resPath, "%.plist$") then
		resPath = "spine/" .. resPath
	elseif string.find(resPath, "^big_hero") then
		resPath = resPath
	else
		resPath = "resources/" .. resPath
	end
	-- 没有后缀的资源，默认为图片来查找是否存在
	if not string.find(resPath, "%.") then
		resPath = resPath .. ".png"
	end
	file, err = io.open(GAME01_PATH .. "/res/"..resPath)
	if err then
		return false, ">>>>>>>>>>>>>>>  " .. originPath .. "\n" .. err
	else
		io.close(file)
		return true
	end
end

local function main()
	print("\n***** check not exist res begin *****")
	local count = 0
	for k,v in pairs(resPaths) do
		local cfg = loadstring("return csv."..v.csvName)() -- 获得配表
		for kk,vv in orderCsvPairs(cfg) do -- 遍历配表
			globalValue = vv
			local value = loadstring("return globalValue."..v.colName)() -- 获取检查列的值
			if value and v.colName2 then
				value = value[v.colName2]
			end
			if type(value) ~= "table" then -- 转化为table,因为某些列是配置多个公式，统一为多个公式的情况
				value = {value}
			end
			for kkk,vvv in pairs(value) do -- 遍历公式列表
				local flag, errRet = checkExistRes(vvv)
				if not flag then
					count = count + 1
					printWarn(v.csvName..".csv", "id = ", kk, "key = ", v.colName, v.colName2 and v.colName2 or "", "\n" .. errRet)
				end
			end
		end
	end
	print(string.format("----- check not exist res end (totalCount:%d) -----\n", count))
end

return main
