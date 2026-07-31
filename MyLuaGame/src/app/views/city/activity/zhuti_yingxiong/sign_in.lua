local Activity = require "app.views.city.activity.view"

local YY_TYPE = game.YYHUODONG_TYPE_ENUM_TABLE

local ActivityZhutiYingxiongSignIn = class("ActivityZhutiYingxiongSignIn", cc.load("mvc").ViewBase)

ActivityZhutiYingxiongSignIn.RESOURCE_FILENAME = "activity_zhuti_yingxiong_signin.json"
ActivityZhutiYingxiongSignIn.RESOURCE_BINDING = {
	["item"] = "item",
	["item.txtDi"] = {
		binds = {
			event = "effect",
			data = { outline = { color = ui.NEWCOLORS.OUTLINE.BLACK, size = 4 } },
		},
	},
	["item.day"] = {
		binds = {
			event = "effect",
			data = { outline = { color = ui.NEWCOLORS.OUTLINE.BLACK, size = 4 } },
		},
	},
	["item.txtTian"] = {
		binds = {
			event = "effect",
			data = { outline = { color = ui.NEWCOLORS.OUTLINE.BLACK, size = 4 } },
		},
	},
	["item.btnGet.txt"] = {
		binds = {
			{
				event = "effect",
				data = { outline = { color = ui.NEWCOLORS.OUTLINE.YELLOW, size = 4 } }
			},
		}
	},

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
					local childs = node:multiget("bg", "txtDi", "txtTian", "day", "item", "btnGet")
					childs.day:text(v.day)

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

					if v.state == 1 then
						-- 可领取
						uiEasy.setBtnShader(childs.btnGet, false, 1)
						bind.touch(list, childs.btnGet, { methods = { ended = functools.partial(list.clickCell, k, v) } })
					else
						uiEasy.setBtnShader(childs.btnGet, false, 2)
						if v.state == 0 then
							-- 已领取
							childs.btnGet:get("txt"):text(gLanguageCsv.received)
							cache.setShader(childs.bg, false, "hsl_gray")
						else
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

function ActivityZhutiYingxiongSignIn:onCreate(activityId)
	self.activityId = idler.new(activityId)

	local yyCfg = csv.yunying.yyhuodong[activityId]

	self:initModel()

	gGameUI.topuiManager:createView("zhuti_yingxiong", self, { onClose = self:createHandler("onClose") })
		:init({ title = yyCfg.name })

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

function ActivityZhutiYingxiongSignIn:initTheme(theme)

end

function ActivityZhutiYingxiongSignIn:initModel()
	self.yyhuodongs = gGameModel.role:getIdler("yyhuodongs")
end

function ActivityZhutiYingxiongSignIn:onItemClick(_, k, v)
	gGameApp:requestServer("/game/yy/award/get", function(tb)
		gGameUI:showGainDisplay(tb)
	end, self.activityId:read(), v.id)
end

return ActivityZhutiYingxiongSignIn
