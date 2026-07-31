local ViewBase = cc.load("mvc").ViewBase
local ActivityZhutiYingxiongPassportView = class("ActivityZhutiYingxiongPassportView", ViewBase)

-- 绑定icon_key通用方法
local function onBindIcon(parent, node, data, isEffect)
	if not data then
		node:hide()
		return
	end
	node:show()
	bind.extend(parent, node, {
		class = "icon_key",
		props = {
			data = data,
			onNode = function(panel)
				panel:scale(0.9)
				local img = node:get("img")
				if img then
					img:visible(data.state == 0)
				else
					img = ccui.ImageView:create("common/ui/icon_select.png")
						:addTo(node, 1000, "img")
						:xy(100, 100)
						:visible(data.state == 0)
				end
			end
		},
	})

	local sprite = node:getChildByName("wupinshanguang")
	if sprite then
		sprite:removeFromParent()
	end
	if isEffect then
		widget.addAnimationByKey(node, "wupinshanguang/saoguang.skel", "wupinshanguang", "effect_loop", 999)
			:xy(node:size().width / 2, node:size().height / 2)
			:scale(0.7)
	end
end

ActivityZhutiYingxiongPassportView.RESOURCE_FILENAME = "activity_zhuti_yingxiong_passport.json"
ActivityZhutiYingxiongPassportView.RESOURCE_BINDING = {
	["bg"] = "bg",
	["title.richText"] = "proDescs",
	["center.item"] = "item",
	["center.item.num"] = {
		binds = {
			event = "effect",
			data = { outline = { color = ui.NEWCOLORS.OUTLINE.BLACK, size = 4 } },
		},
	},
	["center.item.btnGet.txt"] = {
		binds = {
			event = "effect",
			data = { outline = { color = ui.NEWCOLORS.OUTLINE.BLACK, size = 4 } },
		},
	},
	["center.list"] = {
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("awardDatas"),
				item = bindHelper.self("item"),
				currentPassportLv = bindHelper.self("currentPassportLv"),
				buyElite = bindHelper.self("buyElite"),
				itemAction = { isAction = true },
				asyncPreload = 10,
				onItem = function(list, node, k, v)
					local childs = node:multiget("num", "btnGet", "maskNor", "maskElite")
					childs.btnGet:hide()
					local awardCfg = csv.yunying.playpassport_award[v.csvId]

					local isSpecial = awardCfg.specialAward == 1
					if k == 1 then
						childs.num:text("Free")
					else
						childs.num:text((awardCfg.level + 2) .. " star")
					end

					-- 普通奖励
					local normal = {}
					for id, count in csvMapPairs(awardCfg.normalAward) do
						table.insert(normal, { key = id, num = count, state = v.normalAwardState })
					end

					local elite = {}
					for id, count in csvMapPairs(awardCfg.eliteAward) do
						table.insert(elite, { key = id, num = count, state = v.eliteAwardState })
					end

					onBindIcon(list, node:get("item0"), normal[1], isSpecial)
					onBindIcon(list, node:get("item1"), elite[1], isSpecial)
					onBindIcon(list, node:get("item2"), elite[2], isSpecial)

					childs.maskNor:visible(list.currentPassportLv < awardCfg.level)
					childs.maskElite:visible(list.currentPassportLv < awardCfg.level or not list.buyElite:read())

					childs.btnGet:visible(v.normalAwardState == 1 or v.eliteAwardState == 1) --判断是否有奖励可领取，分为普通奖励和进阶奖励，1可领取，0已领取

					bind.touch(list, childs.btnGet, { methods = { ended = functools.partial(list.clickCell, k, v) } })
				end,
			},
			handlers = {
				clickCell = bindHelper.self("onBtnGetClick"),
			}
		}
	},
	["center.btnBuy"] = {
		varname = "btnBuy",
		binds = {
			event = "touch",
			methods = { ended = bindHelper.self("onBuyClick") }
		},
	},
	["center.btnBuy.txt"] = {
		varname = "price",
		binds = {
			event = "effect",
			data = { outline = { color = ui.NEWCOLORS.OUTLINE.BLACK, size = 4 } },
		},
	},
	["titlePanel.title1"] = {
		binds = {
			event = "effect",
			data = { outline = { color = ui.NEWCOLORS.OUTLINE.BLACK, size = 4 } },
		},
	},
	["titlePanel.title2"] = {
		binds = {
			event = "effect",
			data = { outline = { color = ui.NEWCOLORS.OUTLINE.BLACK, size = 4 } },
		},
	},
	["center.btnGetAll"] = {
		varname = "btnGetAll",
		binds = {
			event = "touch",
			methods = { ended = bindHelper.self("onGetAllClick") }
		},
	},
	["center.btnGetAll.txt"] = {
		binds = {
			event = "effect",
			data = { outline = { color = ui.NEWCOLORS.OUTLINE.BLACK, size = 4 } },
		},
	},


}

function ActivityZhutiYingxiongPassportView:onCreate(activityId)
	self.activityId = activityId

	self:initModel()

	local yyCfg = csv.yunying.yyhuodong[self.activityId]
	gGameUI.topuiManager:createView("zhuti_yingxiong", self, { onClose = self:createHandler("onClose") })
		:init({ title = yyCfg.name })

	self.awardDatas = idlers.new({})
	self.buyElite = idler.new(false)
	idlereasy.when(self.buyElite, function(_, isBuy)
		self.btnBuy:visible(not isBuy)
	end)
	local rechargeCfg = csv.yunying.playpassport_recharge
	for k, v in csvMapPairs(rechargeCfg) do
		if v.huodongID == yyCfg.huodongID then
			self.csvId = k
		end
	end
	local price = csv.recharges[rechargeCfg[self.csvId].rechargeID]["rmbDisplay_"..LOCAL_LANGUAGE] or csv.recharges[rechargeCfg[self.csvId].rechargeID].rmbDisplay
	self.price:text(string.format(gLanguageCsv.symbolMoney, price))
	self.currentPassportLv = 0
	self.clientBuyTimes = idler.new(true)
	idlereasy.any({ self.yyhuodongs, self.clientBuyTimes }, function(_, yyhuodongs)
		local passport = yyhuodongs[self.activityId]
		self.currentPassportLv = passport.info.level
		self.buyElite:set(passport.info.elite_buy > 0) -- 是否购买高级通行证
		-- 根据活动id获取当前活动id对应表内容
		local awardDatas = {}                    -- 奖励表
		for k, v in orderCsvPairs(csv.yunying.playpassport_award) do
			if v.huodongID == yyCfg.huodongID then
				local normalAwardState = passport.stamps[k]
				local eliteAwardState = passport.stamps1[k]

				table.insert(awardDatas, {
					csvId = k,
					normalAwardState = normalAwardState,
					eliteAwardState = eliteAwardState,

				})
			end
		end

		self.awardDatas:update(awardDatas)

		self.proDescs:removeChildByName("emm")
		rich.createByStr(
			"#L00100010##LOC0x000000#" ..
			"Current star: " .. ((self.currentPassportLv + 2 >= 4) and (self.currentPassportLv + 2) or
				0), 44)
			:xy(0, 40)
			:anchorPoint(0, 0.5)
			:addTo(self.proDescs, 5, "emm")
	end)
end

function ActivityZhutiYingxiongPassportView:initModel()
	self.yyhuodongs = gGameModel.role:getIdler("yyhuodongs")
end

function ActivityZhutiYingxiongPassportView:onBuyClick()
	gGameUI:stackUI("city.activity.zhuti_yingxiong.passport_buy", nil, nil, self.activityId,
		self:createHandler("onBtnBuyCb"))
end

function ActivityZhutiYingxiongPassportView:onBtnBuyCb()
	self.clientBuyTimes:notify()
end

function ActivityZhutiYingxiongPassportView:onBtnGetClick(_, k, v)
	gGameApp:requestServer("/game/yy/award/get", function(tb)
		gGameUI:showGainDisplay(tb)
	end, self.activityId, v.csvId)
end

function ActivityZhutiYingxiongPassportView:onGetAllClick()
	local isHaveRewardGet = false
	local passport = self.yyhuodongs:read()[self.activityId]
	for _, state in pairs(passport.stamps) do
		if state == 1 then
			isHaveRewardGet = true
			break
		end
	end
	for _, state in pairs(passport.stamps1) do
		if state == 1 then
			isHaveRewardGet = true
			break
		end
	end
	if not isHaveRewardGet then
		gGameUI:showTip(gLanguageCsv.noRewardGet)
		return
	end
	gGameApp:requestServer("/game/yy/award/get/onekey", function(tb)
		gGameUI:showGainDisplay(tb)
	end, self.activityId)
end

return ActivityZhutiYingxiongPassportView
