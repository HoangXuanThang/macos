-- 检查抽取随机库 item 配置是否正确

local ItemMaxID = 10000

local function main()
	print("\n***** check csv.draw_items_lib item id not exist begin *****")
	for k,v in orderCsvPairs(csv.draw_items_lib) do
		for column, _ in pairs(v) do
			if string.find(column, 'weightList') then
				-- weightList_en
				local lang = split(column, '_')[2] or ''
				if lang ~= '' then lang = '_'..lang end
				for _, item in ipairs(v[column]) do
					-- <id, weight, num>
					if item and type(item[1]) == 'number' and item[1] <= ItemMaxID and not csv.items[item[1]] then
						printErr(string.format("csv.draw_items_lib id %d weightList%s item id %d not exist in csv.items", k, lang, item[1]))
					end
				end
			end
		end
	end
	print("----- check csv.draw_items_lib item id not exist end -----")
end

return main
