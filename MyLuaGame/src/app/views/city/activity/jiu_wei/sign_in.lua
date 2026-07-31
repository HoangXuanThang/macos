local Activity = require "app.views.city.activity.view"

local ActivityJiuWeiSignIn = class("ActivityJiuWeiSignIn", cc.load("mvc").ViewBase)

ActivityJiuWeiSignIn.RESOURCE_FILENAME = "activity_jiuwei_signin.json"
ActivityJiuWeiSignIn.RESOURCE_BINDING = {
	["item"] = "item",
	["item.day"] = {
		binds = {
			event = "effect",
			data = { outline = { color = ui.NEWCOLORS.OUTLINE.BLACK, size = 4 } },
		},
	},
	["item.btnSignIn.txt"] = {
		binds = {
			event = "effect",
			data = { outline = { color = ui.NEWCOLORS.OUTLINE.YELLOW, size = 4 } },
		},
	},

	["item.btnGot.txt"] = {
		binds = {
			event = "effect",
			data = { outline = { color = ui.NEWCOLORS.OUTLINE.YELLOW, size = 4 } },
		},
	},
	["item.noGot.txt"] = {
		binds = {
			event = "effect",
			data = { outline = { color = ui.NEWCOLORS.OUTLINE.YELLOW, size = 4 } },
		},
	},

	["list"] = {
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("loginwealDatas"),
				item = bindHelper.self("item"),
				-- curTheme = bindHelper.self("curTheme"),
				itemAction = { isAction = true },
				margin = 10,
				onItem = function(list, node, k, v)
					local childs = node:multiget("bg", "day", "item", "btnSignIn", "btnGot", "noGot")
					local days = { "1", "2", "3", "4", "5", "6", "7" }
					childs.day:text("Day " .. days[v.day])
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
								panel:scale(0.9)
								local bound = panel:box()
								panel:alignCenter(bound)
							end
						},
					})
					uiEasy.setBtnShader(childs.btnSignIn, false, 1)
					uiEasy.setBtnShader(childs.btnGot, false, 2)
					uiEasy.setBtnShader(childs.noGot, false, 2)
					itertools.invoke({ childs.btnSignIn, childs.btnGot, childs.noGot }, "hide")
					if v.state == 1 then
						childs.btnSignIn:show()
						-- 可领取
						bind.click(list, childs.btnSignIn, { method = functools.partial(list.clickCell, k, v) })
					else
						if v.state == 0 then
							-- 已领取
							childs.btnGot:show()
						else
							childs.noGot:show()
							-- 不可领取
						end
					end
				end,
			},
			handlers = {
				clickCell = bindHelper.self("onItemClick"),
			}
		}
	},
	["timeBg"] = "timeBg",
}

function ActivityJiuWeiSignIn:onCreate(activityId)
	self.activityId = idler.new(activityId)

	local yyCfg = csv.yunying.yyhuodong[activityId]

	self:initModel()

	gGameUI.topuiManager:createView("jiuwei", self, { onClose = self:createHandler("onClose") })
		:init({ title = yyCfg.name })

	-- self.curTheme = yyCfg.clientParam.theme

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

	local uiIcon = self.timeBg:get("icon")
	local uiTime = self.timeBg:get("time")
	Activity.setCountdown(self, self.activityId:read(), nil, uiTime, {
		labelChangeCb = function()
			adapt.oneLineCenterPos(cc.p(210, 30), { uiIcon, uiTime }, cc.p(10, 0))
		end,
		tag = "signIn" .. self.activityId:read()
	})
end

function ActivityJiuWeiSignIn:initTheme(theme)

end

function ActivityJiuWeiSignIn:initModel()
	self.yyhuodongs = gGameModel.role:getIdler("yyhuodongs")
end

function ActivityJiuWeiSignIn:onItemClick(_, k, v)
	gGameApp:requestServer("/game/yy/award/get", function(tb)
		gGameUI:showGainDisplay(tb)
	end, self.activityId:read(), v.id)
end

return ActivityJiuWeiSignIn
