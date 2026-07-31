
-- 排行奖励

local ActivityThroneRankDlg = class("ActivityThroneRankDlg", Dialog)

ActivityThroneRankDlg.RESOURCE_FILENAME = "activity_throne_rank.json"
ActivityThroneRankDlg.RESOURCE_BINDING = {
    ["topPanel.btnClose"] = {
		binds = {
			event = "touch",
			methods = { ended = bindHelper.self("onClose") }
		},
	},
	["rewardPanel.rewardItem"] = "rewardItem", --  奖励列表
	["rewardPanel.list"] = {
		varname = "rewardList",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("awardData"),
				item = bindHelper.self("rewardItem"),
				itemAction = { isAction = true },
				onItem = function(list, node, k, v)
					local childs = node:multiget("imgBg", "rankIcon", "itemList")
					local rankMax = v.rankEnd
					if rankMax <= 3 then
						childs.imgBg:texture("city/pvp/craft/dialog_icon/iten_"..rankMax..".png")
						childs.rankIcon:texture("city/pvp/craft/img_xz"..rankMax..".png")
					else
						local left = v.rankStart + 1
						local right = rankMax
						local str = left <  right and (left.."-"..right) or right

						-- 图片字创建
						bind.extend(list, node, {
							class = "text_atlas",
							props = {
								data = str,
								pathName = "craft",
								isEqualDist = false,
								align = "center",
								onNode = function(node)
									node:xy(childs.rankIcon:x(), childs.rankIcon:y())
								end,
							}
						})
						childs.rankIcon:hide()
					end

					-- 奖励列表，通用接口
					uiEasy.createItemsToList(list, childs.itemList, v.award, {margin = 11, scale = 0.8})

					-- 奖励列表，通用接口
					uiEasy.createItemsToList(list, childs.itemList, v.award, { margin = 11, scale = 0.8 })
				end,
				-- asyncPreload = 10,
			},
		},
	},
}


function ActivityThroneRankDlg:onCreate(activityId)
    self.activityId = activityId -- 活动ID号

	local yyCfg = csv.yunying.yyhuodong[activityId]
	local huodongID = yyCfg.huodongID
	local tb = {}
	local rankStart = 0
	for id, cfg in orderCsvPairs(csv.yunying.limitboxrankaward) do
		if cfg.huodongID == huodongID then
			table.insert(tb, {
				point = cfg.pointLeast,
				award = cfg.award,
				rankStart = rankStart,
				rankEnd = cfg.rank,
			})
			rankStart = cfg.rank
		end
	end
	-- table.sort(tb, function(a, b)
	-- 	return a.rankEnd < b.rankEnd
	-- end)

	self.awardData = idlers.newWithMap(tb)

    Dialog.onCreate(self, {blackType = 1})
end


return ActivityThroneRankDlg