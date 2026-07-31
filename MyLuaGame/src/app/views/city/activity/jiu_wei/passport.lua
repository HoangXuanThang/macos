local ViewBase = cc.load("mvc").ViewBase
local ActivityJiuWeiPassportView = class("ActivityJiuWeiPassportView", ViewBase)

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

ActivityJiuWeiPassportView.RESOURCE_FILENAME = "activity_jiuwei_passport.json"
ActivityJiuWeiPassportView.RESOURCE_BINDING = {
	["bg"] = "bg",
	["title.exp"] = {
		varname = "exp",
		binds = {
			event = "effect",
			data = { outline = { color = ui.NEWCOLORS.OUTLINE.BLACK, size = 4 } },
		},
	},
	["center.item"] = "item",
	["center.item.btnGet.txt"] = {
		binds = {
			event = "effect",
			data = { outline = { color = ui.NEWCOLORS.OUTLINE.YELLOW, size = 4 } },
		},
	},
	["center.item.num"] = {
		binds = {
			event = "effect",
			data = { outline = { color = ui.NEWCOLORS.OUTLINE.BLACK, size = 4 } },
		},
	},
	["center.item.desc"] = {
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

					childs.num:text("Lv." .. awardCfg.level .. "(招募" .. v.expNum .. "次)")

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
					childs.num:visible(not (v.normalAwardState == 1 or v.eliteAwardState == 1))
					bind.touch(list, childs.btnGet, { methods = { ended = functools.partial(list.clickCell, k, v) } })
				end,
			},
			handlers = {
				clickCell = bindHelper.self("onBtnGetClick"),
			}
		}
	},
	["btnBuy"] = {
		varname = "btnBuy",
		binds = {
			event = "touch",
			methods = { ended = bindHelper.self("onBuyClick") }
		},
	},
	["btnBuy.price"] = {
		binds = {
			event = "effect",
			data = { outline = { color = ui.NEWCOLORS.OUTLINE.BLACK, size = 4 } },
		},
	},
	["btnGetAll"] = {
		varname = "btnGetAll",
		binds = {
			event = "touch",
			methods = { ended = bindHelper.self("onGetAllClick") }
		},
	},
	["btnGetAll.txt"] = {
		binds = {
			event = "effect",
			data = { outline = { color = ui.NEWCOLORS.OUTLINE.BLACK, size = 4 } },
		},
	},
	["awardPanel.item"] = "itemToken",
	["awardPanel.sublist"] = "subTokenlist",
	["awardPanel.awrdList"] = {
		binds = {
			event = "extend",
			class = "tableview",
			props = {
				data = bindHelper.self("itemDatas2"),
				item = bindHelper.self("subTokenlist"),
				cell = bindHelper.self("itemToken"),
				columnSize = 3,
				xMargin = 10,
				onCell = function(list, node, k, v)
					bind.extend(list, node, {
						class = "icon_key",
						props = {
							data = {
								key = v.key,
								num = v.num,
							},
							onNode = function(node)
								node:scale(0.8)
							end,
						},
					})
				end,
			},
		},
	},
}

function ActivityJiuWeiPassportView:onCreate(activityId)
	self.activityId = activityId

	self:initModel()

	local yyCfg = csv.yunying.yyhuodong[self.activityId]
	gGameUI.topuiManager:createView("jiuwei", self, { onClose = self:createHandler("onClose") })
		:init({ title = yyCfg.name })

	self.awardDatas = idlers.new({})
	self.buyElite = idler.new(false)
	idlereasy.when(self.buyElite, function(_, isBuy)
		uiEasy.setBtnShader(self.btnBuy, nil, isBuy and 2 or 1)
		if isBuy then
			self.btnBuy:get("price"):text(gLanguageCsv.hasBuy)
		end
	end)
	self.currentPassportLv = 0
	self.clientBuyTimes = idler.new(true)
	idlereasy.any({ self.yyhuodongs, self.clientBuyTimes }, function(_, yyhuodongs)
		local passport = yyhuodongs[self.activityId]
		self.currentPassportLv = passport.info.level
		self.buyElite:set(passport.info.elite_buy > 0) -- 是否购买高级通行证
		-- 根据活动id获取当前活动id对应表内容
		local awardDatas = {}                    -- 奖励表
		local expNum = 0
		for k, v in orderCsvPairs(csv.yunying.playpassport_award) do
			if v.huodongID == yyCfg.huodongID then
				local normalAwardState = passport.stamps[k]
				local eliteAwardState = passport.stamps1[k]

				table.insert(awardDatas, {
					csvId = k,
					normalAwardState = normalAwardState,
					eliteAwardState = eliteAwardState,
					expNum = expNum
				})
				expNum = v.needExp + expNum
			end
		end

		self.awardDatas:update(awardDatas)

		self.exp:text("招募次数:" .. passport.info.exp)
	end)

	self:updateAwardPanel(yyCfg)
end

function ActivityJiuWeiPassportView:initModel()
	self.yyhuodongs = gGameModel.role:getIdler("yyhuodongs")

	self.itemDatas2 = idlers.newWithMap({})
end

-- 奖励
function ActivityJiuWeiPassportView:updateAwardPanel(yyCfg)
	local rechargeCfg = csv.yunying.playpassport_recharge
	for k, v in csvMapPairs(rechargeCfg) do
		if v.huodongID == yyCfg.huodongID then
			self.passportCsvId = k
		end
	end

	if self.buyElite:read() then
		self.btnBuy:get("price"):text(gLanguageCsv.hasBuy)
	else
		self.btnBuy:get("price"):text(string.format(gLanguageCsv.symbolMoney,
			csv.recharges[rechargeCfg[self.passportCsvId].rechargeID].rmbDisplay))
	end


	local level = self.yyhuodongs:read()[self.activityId].info.level

	local itemDatas2 = {}
	local isHave = false
	for k, v in csvPairs(csv.yunying.playpassport_award) do
		if v.huodongID == yyCfg.huodongID then
			for key, val in csvMapPairs(v.eliteAward) do
				for key1, val1 in ipairs(itemDatas2) do
					if val1.key == key then
						val1.num = val1.num + val
						isHave = true
						break
					end
				end
				if isHave == false then
					table.insert(itemDatas2, { key = key, num = val })
				else
					isHave = false
				end
			end
		end
	end

	self.itemDatas2:update(itemDatas2)
end

function ActivityJiuWeiPassportView:onBtnGetClick(_, k, v)
	gGameApp:requestServer("/game/yy/award/get", function(tb)
		gGameUI:showGainDisplay(tb)
	end, self.activityId, v.csvId)
end

function ActivityJiuWeiPassportView:onGetAllClick()
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

function ActivityJiuWeiPassportView:onBtnBuyCb()
	self.clientBuyTimes:notify()
end

function ActivityJiuWeiPassportView:onBuyClick(list, v)
	gGameUI:stackUI("city.activity.jiu_wei.passport_buy", nil, nil, self.activityId,
		self:createHandler("onBtnBuyCb"))
end

return ActivityJiuWeiPassportView
