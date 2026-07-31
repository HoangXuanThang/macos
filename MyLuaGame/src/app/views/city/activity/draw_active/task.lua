local GET_TYPE = {
	GOTTEN = 0,      --已领取
	CAN_GOTTEN = 1,  --可领取
	CAN_NOT_GOTTEN = 2, --未完成
}
local ActitivyDispatchTask = class("ActitivyDispatchTask", Dialog)

ActitivyDispatchTask.RESOURCE_FILENAME = "activity_draw_active_task.json"
ActitivyDispatchTask.RESOURCE_BINDING = {
	["topPanel.btnClose"] = {
		binds = {
			event = "touch",
			methods = { ended = bindHelper.self("onClose") },
		},
	},

	["btnOneKeyGet"] = {
		varname = "btnOneKeyGet",
		binds = {
			event = "touch",
			methods = { ended = bindHelper.self("onOneKeyGetBtn") },
		},
	},

	["btnOneKeyGet.txt"] = {
		binds = {
			event = "effect",
			{ outline = { color = ui.NEWCOLORS.OUTLINE.YELLOW, size = 4 } }
		}
	},

	["rewardPanel1"] = "rewardPanel1",
	["rankItem"] = "rankItem",
	["rankItem.btnGet.text"] = {
		binds = {
			event = "effect",
			data = { glow = { color = ui.COLORS.GLOW.WHITE } }
		}
	},
	["rewardPanel1.list"] = {
		varname = "list",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				asyncPreload = 5,
				data = bindHelper.self("achvDatas1"),
				item = bindHelper.self("rankItem"),
				dataOrderCmpGen = bindHelper.self("onSortCards", true),
				itemAction = { isAction = true },
				onItem = function(list, node, k, v)
					local childs = node:multiget("achvDesc", "btnGet", "list", "got", "txt", "btnGoto")
					childs.achvDesc:text(v.desc)
					if next(v.award) ~= nil then
						uiEasy.createItemsToList(list, childs.list, v.award, { scale = 0.8 })
					end
					childs.list:setScrollBarEnabled(false)
					bind.touch(list, childs.btnGet, { methods = { ended = functools.partial(list.clickCell, v.csvId) } })
					bind.touch(list, childs.btnGoto,
						{ methods = { ended = functools.partial(list.clickGotoCell, v.goTo) } })
					-- 0已领取，1可领取 2 未完成
					childs.txt:text(v.progress .. "/" .. v.taskParam)
					if v.achType == 1 then
						childs.txt:hide()
						childs.btnGet:y(120)
					end
					if v.get == GET_TYPE.GOTTEN then
						childs.btnGoto:hide()
						childs.btnGet:get("txt"):text(gLanguageCsv.received)
						childs.txt:setTextColor(cc.c4b(98, 197, 88, 255))
					elseif v.get == GET_TYPE.CAN_GOTTEN then
						childs.btnGoto:hide()
						childs.btnGet:get("txt"):text(gLanguageCsv.spaceReceive)
						childs.txt:setTextColor(cc.c4b(98, 197, 88, 255))
					else
						childs.btnGoto:hide()
						childs.btnGet:get("txt"):text(gLanguageCsv.spaceReceive)
						childs.txt:setTextColor(cc.c4b(247, 115, 78, 255))
						if v.achType == 5 then
							if v.goTo == "" then
								childs.btnGet:show()
								childs.btnGoto:hide()
							else
								childs.btnGet:hide()
								childs.btnGoto:show()
							end
						end
					end
					uiEasy.setBtnShader(childs.btnGet, childs.btnGet:get("txt"), v.get)
					text.addEffect(childs.btnGet:get("txt"),
						{ outline = { color = ui.NEWCOLORS.OUTLINE.YELLOW, size = 4 } })
					text.addEffect(childs.btnGoto:get("txt"),
						{ outline = { color = ui.NEWCOLORS.OUTLINE.YELLOW, size = 4 } })
				end,
			},
			handlers = {
				clickCell = bindHelper.self("onGetBtn"),
				clickGotoCell = bindHelper.self("onGotoBtn"),
			},
		},
	},
}

function ActitivyDispatchTask:onCreate(id)
	self.activityId = id
	self.rewardPanel1:show()

	self:initModel()

	Dialog.onCreate(self, {blackType = 1})
end

function ActitivyDispatchTask:initModel()
	self.achvDatas1 = idlers.new()
	local tempDatas = {
		[1] = { name = gLanguageCsv.dispatchTaskType1, redHint = "dispatchTaskType", id = self.activityId, type = 1 },
		[2] = { name = gLanguageCsv.dispatchTaskType2, redHint = "dispatchTaskType", id = self.activityId, type = 2 },
		[3] = { name = gLanguageCsv.dispatchTaskType3, redHint = "dispatchTaskType", id = self.activityId, type = 3 },
		[4] = { name = gLanguageCsv.dispatchTaskType4, redHint = "dispatchTaskType", id = self.activityId, type = 4 },
		[5] = { name = gLanguageCsv.dispatchTaskType5, redHint = "dispatchTaskType", id = self.activityId, type = 5 },
	}
	local yyCfg = csv.yunying.yyhuodong[self.activityId]
	local huodongID = yyCfg.huodongID

	self.yyhuodongs = gGameModel.role:getIdler("yyhuodongs")
	idlereasy.when(self.yyhuodongs, function(_, yyhuodongs)
		local yydata = yyhuodongs[self.activityId] or {}
		local times = yydata.valsums or {}

		local datas = {}
		local onekeyEnabled = false
		for k, v in csvPairs(csv.yunying.generaltask) do
			if v.huodongID == huodongID then
				local data = table.shallowcopy(v)
				data.csvId = k
				local stamps = yydata.stamps or {}
				data.get = stamps[k]
				data.progress = times[k] or 0
				data.achType = v.type
				table.insert(datas, data)
				if data.get == GET_TYPE.CAN_GOTTEN then
					onekeyEnabled = true
				end
			end
		end
		uiEasy.setBtnShader(self.btnOneKeyGet, self.btnOneKeyGet:get("txt"), onekeyEnabled == false and 2 or 1)
		text.addEffect(self.btnOneKeyGet:get("txt"),
			{ outline = { color = ui.NEWCOLORS.OUTLINE.YELLOW, size = 4 } })

		self.achvDatas1:update(datas)

	end)
end

function ActitivyDispatchTask:onGetBtn(list, csvId)
	gGameApp:requestServer("/game/yy/award/get", function(tb)
		gGameUI:showGainDisplay(tb)
	end, self.activityId, csvId)
end

function ActitivyDispatchTask:onOneKeyGetBtn(list)
	gGameApp:requestServer("/game/yy/award/get/onekey", function(tb)
		gGameUI:showGainDisplay(tb)
	end, self.activityId)
end

function ActitivyDispatchTask:onGotoBtn(llist, goTo)
	jumpEasy.jumpTo(goTo)
end

function ActitivyDispatchTask:onSortCards(list)
	return function(a, b)
		local va = a.get or 0.5
		local vb = b.get or 0.5
		if va ~= vb then
			return va > vb
		end
		return a.csvId < b.csvId
	end
end

return ActitivyDispatchTask
