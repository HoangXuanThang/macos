local Activity = require "app.views.city.activity.view"
local ActivityThemeSkinSignIn = class("ActivityThemeSkinSignIn", cc.load("mvc").ViewBase)

ActivityThemeSkinSignIn.RESOURCE_FILENAME = "activity_theme_skin_signin.json"
ActivityThemeSkinSignIn.RESOURCE_BINDING = {
	["item"] = "item",

	["list"] = {
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("loginwealDatas"),
				item = bindHelper.self("item"),
				onItem = function(list, node, k, v)
					node:get("baseNode"):y(k % 2 == 0 and 550 or 700)
					local childs = node:get("baseNode"):multiget("bg", "txtDi", "txtTian", "day", "item", "btnGet",
						"received")
					childs.day:text((v.day))

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
					childs.btnGet:visible(false)
					childs.received:visible(false)
					if v.state == 1 then
						childs.btnGet:visible(true)
						uiEasy.setBtnShader(childs.btnGet, false, 1)
						bind.touch(list, childs.btnGet, { methods = { ended = functools.partial(list.clickCell, k, v) } })
					else
						uiEasy.setBtnShader(childs.btnGet, false, 2)

						if v.state == 0 then
							childs.received:visible(true)
							cache.setShader(childs.bg, false, "hsl_gray")
							uiEasy.setTextShader(childs.txtDi, 2)
							uiEasy.setTextShader(childs.day, 2)
							uiEasy.setTextShader(childs.txtTian, 2)
						else
							childs.btnGet:visible(true)
						end
					end
				end,
			},
			handlers = {
				clickCell = bindHelper.self("onItemClick"),
			}
		}
	},
	["time"] = "time",
}

function ActivityThemeSkinSignIn:onCreate(activityId)
	self.activityId = idler.new(activityId)

	local yyCfg = csv.yunying.yyhuodong[activityId]

	self:initModel()

	gGameUI.topuiManager:createView("theme_skin", self, { onClose = self:createHandler("onClose") })
		:init({ title = yyCfg.name, subTitle = "STAR UPGRADE" })

	-- 每日奖励数据
	self.loginwealDatas = idlers.newWithMap({})

	self.clientBuyTimes = idler.new(true)
	idlereasy.any({ self.yyhuodongs, self.clientBuyTimes, self.activityId },
		function(_, yyhuodongs, clientBuyTimes, activityId)
			local yydata = yyhuodongs[activityId] or {}
			local stamps = yydata.stamps or {}

			local loginwealData = {}
			for k, v in csvPairs(csv.yunying.loginweal) do
				if v.huodongID == yyCfg.huodongID then
					loginwealData[v.daySum] = { award = v.award, id = k, day = v.daySum, state = stamps[k] or 2 }
				end
			end
			self.loginwealDatas:update(loginwealData)
		end)
	local uiIcon = self.time:get("icon")
	local uiTime = self.time:get("time")
	Activity.setCountdown(self, self.activityId:read(), nil, uiTime, {
		labelChangeCb = function()
			adapt.oneLineCenterPos(cc.p(180, 30), { uiIcon, uiTime }, cc.p(20, 0))
		end,
		tag = "exchange" .. self.activityId:read()
	})
end

function ActivityThemeSkinSignIn:initTheme(theme)

end

function ActivityThemeSkinSignIn:initModel()
	self.yyhuodongs = gGameModel.role:getIdler("yyhuodongs")
end

function ActivityThemeSkinSignIn:onItemClick(_, k, v)
	gGameApp:requestServer("/game/yy/award/get", function(tb)
		gGameUI:showGainDisplay(tb)
	end, self.activityId:read(), v.id)
end

return ActivityThemeSkinSignIn
