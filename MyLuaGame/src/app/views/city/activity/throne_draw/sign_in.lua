

local ActivityThroneSignIn = class("ActivityThroneSignIn", cc.load("mvc").ViewBase)

ActivityThroneSignIn.RESOURCE_FILENAME = "activity_throne_signin.json"
ActivityThroneSignIn.RESOURCE_BINDING = {
	["item"] = "item",
	
	["list"] = {
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("loginwealDatas"),
				item = bindHelper.self("item"),
				itemAction = { isAction = true },
				margin = 10,
				onItem = function(list, node, k, v)
					local childs = node:multiget("bg", "txtDi", "txtTian", "day", "item", "btnGet", "received")
					childs.day:text(dataEasy.getNumeral(v.day))

					local key, num = next(v.award)
					bind.extend(list, childs.item, {
						class = "icon_key",
						props = {
							data = {
								key = key,
								num = num,
							},
							grayState = v.state == 0 and 2 or 0,
							onNode = function(panel)
								local bound = panel:box()
								panel:alignCenter(bound)
							end
						},
					})

					childs.received:hide()
					childs.btnGet:show()
					cache.setShader(childs.bg, false, "normal")
					if v.state == 1 then
						-- 可领取
						uiEasy.setBtnShader(childs.btnGet, childs.btnGet:get("txt"), 1)
						bind.touch(list, childs.btnGet, {methods = {ended = functools.partial(list.clickCell, k, v)}})
					else
						uiEasy.setBtnShader(childs.btnGet, childs.btnGet:get("txt"), 2)
						if v.state == 0 then
							-- 已领取
							childs.btnGet:hide()
							childs.received:show()
							cache.setShader(childs.bg, false, "hsl_gray")

							uiEasy.setTextShader(childs.txtDi, 2)
							uiEasy.setTextShader(childs.day, 2)
							uiEasy.setTextShader(childs.txtTian, 2)
						else
							-- 不可领取
							-- cache.setShader(childs.bg, false, "normal")
						end
					end

					
				end,
			},
			handlers = {
				clickCell = bindHelper.self("onItemClick"),
			}
		}
	},
}

function ActivityThroneSignIn:onCreate(activityId)
	self.activityId = idler.new(activityId)

	local yyCfg = csv.yunying.yyhuodong[activityId]

    self:initModel()
	
	gGameUI.topuiManager:createView("throne", self, { onClose = self:createHandler("onClose") })
		:init({ title = yyCfg.name, subTitle = "STAR UPGRADE" })

	self.curTheme = yyCfg.clientParam.theme

	-- 每日奖励数据
	self.loginwealDatas = idlers.newWithMap({})

	self.clientBuyTimes = idler.new(true)
	idlereasy.any({self.yyhuodongs, self.clientBuyTimes, self.activityId}, function(_, yyhuodongs, clientBuyTimes, activityId)
		local yydata = yyhuodongs[activityId] or {}
		local stamps = yydata.stamps or {}

		local loginwealData = {}
		for k, v in csvPairs(csv.yunying.loginweal) do
			if v.huodongID == yyCfg.huodongID then
				loginwealData[v.daySum] = {award = v.award, id = k, day = v.daySum, state = stamps[k] or 2}
			end
		end
		self.loginwealDatas:update(loginwealData)
	end)

end

function ActivityThroneSignIn:initModel()
	self.yyhuodongs = gGameModel.role:getIdler("yyhuodongs")
end

function ActivityThroneSignIn:onItemClick(_, k, v)
	gGameApp:requestServer("/game/yy/award/get", function(tb)
		gGameUI:showGainDisplay(tb)
	end, self.activityId:read(), v.id)
end

return ActivityThroneSignIn