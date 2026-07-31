

local LANGUAGETAB = {en = '英文', tw = '繁体', vn = '越南', th = '泰文'}
local existLanguage = {}
local languageTab = {}

package.path = package.path ..';..\\..\\?.lua' -- path里面加入..的加载路径

for k,v in pairs(LANGUAGETAB) do
	local t = {}
	xpcall(function()
		local data = require ("../../client/application/src/app/defines/l10n/"..(k))
		if data then
			table.insert(existLanguage, k)
			table.insert(languageTab, data)
		end
	end, function(...) print('not exist '..k) end)
end

local file = io.open("temp.txt", "w")

local t = {"变量名", "cn"} -- 默认第一个是中文
for _,language in ipairs(existLanguage) do
	table.insert(t, language)
end
local str = table.concat(t, '\t') .. '\n'
file:write(str)

t = {"默认值"}
for i=1,#existLanguage + 1 do
	table.insert(t, "\"\"\"\"\"\"")
end
str = table.concat(t, '\t') .. '\n'
file:write(str)

t = {"ID", "中文"}
for _,v in ipairs(existLanguage) do
	table.insert(t, LANGUAGETAB[v])
end
str = table.concat(t, '\t') .. '\n'
file:write(str)

t = {"1"}
local count = 1
for k,v in pairs(languageTab[1] or {}) do
	table.insert(t, k) -- 这边默认第一个是cn
	table.insert(t, v)
	for i=2,#languageTab do
		local tab = languageTab[i]
		table.insert(t, tab[k] or "")
	end
	str = table.concat(t, '\t') .. '\n'
	file:write(str)
	count = count + 1
	t = {}
	table.insert(t, count)
end

file:close()