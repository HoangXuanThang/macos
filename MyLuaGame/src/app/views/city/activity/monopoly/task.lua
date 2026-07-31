

local GET_TYPE = {
	GOTTEN = 0, 	--已领取
	CAN_GOTTEN = 1, --可领取
	CAN_NOT_GOTTEN = 2, --未完成
}

local ActivityMonopolyWalkTask = class("ActivityMonopolyWalkTask", cc.load("mvc").ViewBase)

ActivityMonopolyWalkTask.RESOURCE_FILENAME = "treasure_task.json"
ActivityMonopolyWalkTask.RESOURCE_BINDING = {
    ["bg"] = "bg",
    ["item"] = "item",
	["list"] = {
		varname = "list",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("taskData"),
				item = bindHelper.self("item"),
				itemAction = {isAction = true},
				dataOrderCmpGen = bindHelper.self("onSortCards", true),
				onItem = function(list, node, k, v)
					local childs = node:multiget("title", "desc", "btnGot", "num", "btnReceive", "itemsList", "btnGoto")
					if next(v.award) ~= nil then
						uiEasy.createItemsToList(list, childs.itemsList, v.award, {scale = 0.7, margin = 20})
					end
					childs.title:text(v.title)
					childs.desc:text(v.desc)
					local had = v.val or 0
					had = math.min(had, v.taskParam)
					local txtStr = had.."/"..v.taskParam
					adapt.setTextScaleWithWidth(childs.num, txtStr, 100)
					
					childs.btnReceive:visible(v.get == GET_TYPE.CAN_GOTTEN)
					childs.btnGot:visible(v.get == GET_TYPE.GOTTEN)
					childs.btnGoto:visible((not v.get or v.get == GET_TYPE.CAN_NOT_GOTTEN) and v.goTo ~= "")

					uiEasy.setBtnShader(childs.btnReceive, childs.btnReceive:get("txt"), v.get == GET_TYPE.CAN_GOTTEN and 1 or 2)

					text.addEffect(childs.btnReceive:get("txt"), {color = ui.COLORS.NORMAL.WHITE, outline = {color = ui.NEWCOLORS.OUTLINE.YELLOW, size = 4}})
					text.addEffect(childs.btnGoto:get("txt"), {color = ui.COLORS.NORMAL.WHITE, outline = {color = ui.NEWCOLORS.OUTLINE.BLUE, size = 4}})

					bind.touch(list, childs.btnReceive, {methods = {ended = functools.partial(list.clickCell, v.csvId)}})
					bind.touch(list, childs.btnGoto, {methods = {ended = functools.partial(list.clickGotoCell, v.goTo)}})
				end,
			},
			handlers = {
				clickCell = bindHelper.self("onGetBtn"),
				clickGotoCell = bindHelper.self("onGotoBtn"),
			},
		},
	},
	["time"] = "time",
}

function ActivityMonopolyWalkTask:onCreate(activityId)
	self.yyID = activityId
	
	local yyCfg = csv.yunying.yyhuodong[activityId]

    self:initModel()
	
	-- local title = TitleRes[cfg.type]
	gGameUI.topuiManager:createView("monopoly", self, { onClose = self:createHandler("onClose") })
		:init({ title = yyCfg.name, subTitle = "MONOPOLY" })
	
	idlereasy.any({self.yyhuodongs}, function(_, yyhuodongs)
		local yydata = yyhuodongs[self.yyID] or {}
		self.yydata = yydata
		self:initTask()
	end)
end

function ActivityMonopolyWalkTask:initTask()
	local data1 = {}
	local btnAllGetState = false
	local yyCfg = csv.yunying.yyhuodong[self.yyID]
	local huodongID = yyCfg.huodongID
	local stamps = self.yydata.stamps or {}
	local valsums = self.yydata.valsums or {}
	for i, v in csvPairs(csv.yunying.grid_walk_tasks) do
		if v.huodongID == huodongID then
			local data = table.shallowcopy(v)
			data.csvId = i
			data.get = stamps[i]
			data.val = valsums[i]
			if data.get == 1 then
				btnAllGetState = true
			end
			if v.taskType > 0 then
				table.insert(data1, data)
			end
		end
	end
	
	self.taskData:update(data1)
	-- uiEasy.setBtnShader(self.btnOneKey,self.btnOneKey:get("txt"), btnAllGetState)
end

function ActivityMonopolyWalkTask:onSortCards(list)
	return function(a, b)
		local va = a.get or 0.5
		local vb = b.get or 0.5
		if va ~= vb then
			return va > vb
		end
		return a.csvId < b.csvId
	end
end

function ActivityMonopolyWalkTask:initModel()
	self.yyhuodongs = gGameModel.role:getIdler("yyhuodongs")

	self.taskData = idlers.newWithMap({})
end

function ActivityMonopolyWalkTask:onGetBtn(list, csvId)
	gGameApp:requestServer("/game/yy/award/get", function(tb)
		gGameUI:showGainDisplay(tb)
	end, self.yyID, csvId)
end

-- function ActivityMonopolyWalkTask:onOneKey()
-- 	gGameApp:requestServer("/game/yy/award/get/onekey",function (tb)
-- 		gGameUI:showGainDisplay(tb)
-- 		self.callBack()
-- 	end, self.yyID)
-- end

function ActivityMonopolyWalkTask:onGotoBtn(llist, goTo)
	jumpEasy.jumpTo(goTo)
end

return ActivityMonopolyWalkTask