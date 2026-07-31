-- @date 2020-12-22
-- @desc 跨服资源战主界面

local ViewBase = cc.load("mvc").ViewBase
local CrossTower = class("CrossTower", ViewBase)

local RANKCOLOR = {
	[1] = {
		color = cc.c3b(255, 214, 50),
		outline = cc.c3b(225, 140, 18),
	},
	[2] = {
		color = cc.c3b(78, 197, 253),
		outline = cc.c3b(97, 143, 179),
	},
	[3] = {
		color = cc.c3b(255, 176, 137),
		outline = cc.c3b(214, 135, 103),
	}
}

local function setBuffCountdown(view, countdown, uiTime, params)
	local tag = params.tag or 1
	view:enableSchedule():unSchedule(tag)

	countdown = math.max(countdown, 0)
	if countdown == 0 then return end

	bind.extend(view, uiTime, {
		class = 'cutdown_label',
		props = {
			time = countdown,
			tag = tag,
			strFunc = function(t)
				return t.str
			end,
			callFunc = function()
			end,
			endFunc = function()
				local endTime = params.cfg.buffTime * 60 + params.info.time
				local countdown = endTime - time.getTime()
				if countdown > 0 then
					performWithDelay(view, function()
						setBuffCountdown(view, countdown, uiTime, params)
					end, 1)
				else
					view:enableSchedule():unSchedule(tag)
				end
			end
		}
	})
end

CrossTower.RESOURCE_FILENAME = "cross_tower.json"
CrossTower.RESOURCE_BINDING = {
	["bg"] = "bg",

	--right_waitPanel
	["rightPanel.waitPanel"] = "right_waitPanel",
	["rightPanel.waitPanel.serverList"] = {
		varname = "serverList",
		binds = {
			event = "extend",
			class = "tableview",
			props = {
				data = bindHelper.self("servers"),
				item = bindHelper.self("serverSubList"),
				cell = bindHelper.self("serverItem"),
				columnSize = 4,
				onCell = function(list, node, k, v)
					node:get("textServer"):text(string.format(gLanguageCsv.brackets, getServerArea(v, nil, true)))
				end,
			},
		},
	},
	["rightPanel.waitPanel.noMatchServer"] = {
		varname = "noMatchServer",
		binds = {
			event = "effect",
			data = { outline = { color = ui.COLORS.BLACK } },
		},
	},
	["rightPanel.waitPanel.item"] = "serverItem",
	["rightPanel.waitPanel.subList"] = "serverSubList",


	["rightPanel.waitPanel.textNote"] = {
		binds = {
			event = "effect",
			data = { outline = { color = ui.COLORS.BLACK } },
		},
	},
	["rightPanel.waitPanel.textTime"] = {
		varname = "textTime",
		binds = {
			event = "effect",
			data = { outline = { color = ui.COLORS.BLACK } },
		},
	},

	--right_overPanel
	["rightPanel.overPanel"] = "right_overPanel",
	["rightPanel.overPanel.item"] = "over_listview_item",
	["rightPanel.overPanel.listview"] = {
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("serversData"),
				item = bindHelper.self("over_listview_item"),
				itemAction = { isAction = true },
				onItem = function(list, node, k, v)
					node:get("no"):text(k)
					if k < 4 then
						text.addEffect(node:get("no"),
							{ color = RANKCOLOR[k].color, outline = { color = RANKCOLOR[k].outline } })
					end
					node:get("zone"):text(string.format("%s %s", getServerArea(v.servKey, nil, true),
						getServerName(v.servKey, true)))
					node:get("score"):text(v.score)
					node:get("selfBg"):visible(isCurServerContainMerge(v.servKey))
				end,
			},
		},
	},

	--right_towerPanel
	["rightPanel.towerPanel"] = "right_towerPanel",
	["rightPanel.towerPanel.btn_top"] = {
		binds = {
			event = "touch",
			methods = { ended = bindHelper.self("onTopClick") },
		},
	},
	["rightPanel.towerPanel.btn_mine"] = {
		binds = {
			event = "touch",
			methods = { ended = bindHelper.self("onMineClick") },
		},
	},
	["rightPanel.towerPanel.btn_bottom"] = {
		binds = {
			event = "touch",
			methods = { ended = bindHelper.self("onBottomClick") },
		},
	},
	["rightPanel.towerPanel.restLabel"] = {
		binds = {
			event = "effect",
			data = { outline = { color = cc.c3b(54, 50, 54), size = 3 } },
		},
	},
	["rightPanel.towerPanel.biddingCount"] = {
		varname = "biddingCount",
		binds = {
			event = "effect",
			data = { outline = { color = cc.c3b(54, 50, 54) } },
		},
	},
	["rightPanel.towerPanel.biddingLabel"] = {
		varname = "biddingLabel",
		binds = {
			event = "effect",
			data = { outline = { color = cc.c3b(54, 50, 54) } },
		},
	},
	["rightPanel.towerPanel.btnAdd"] = {
		varname = "btnAdd",
		binds = {
			event = "touch",
			methods = { ended = bindHelper.self("onAddClick") },
		},
	},
	["rightPanel.towerPanel.bossItem"] = "bossItem",
	["rightPanel.towerPanel.bossItem.btnChallenge"] = {
		varname = "btnChallenge",
		binds = {
			event = "touch",
			methods = { ended = bindHelper.self("onBossClick") },
		},
	},
	["rightPanel.towerPanel.bossItem.time"] = {
		varname = "bossTime",
		binds = {
			event = "effect",
			data = { outline = { color = cc.c3b(47, 43, 47), size = 4 } },
		},
	},


	-- btnPanel
	["rightPanel.btnPanel.blessing"] = {
		varname = "blessing",
		binds = {
			event = "touch",
			methods = { ended = bindHelper.self("onBlessingClick") },
		},
	},
	["rightPanel.btnPanel.blessing.name"] = {
		binds = {
			event = "effect",
			data = { outline = { color = ui.COLORS.OUTLINE.DEFAULT } },
		},
	},
	["rightPanel.btnPanel.rule"] = {
		varname = "rulePanel",
		binds = {
			event = "touch",
			methods = { ended = bindHelper.self("onRuleClick") },
		},
	},
	["rightPanel.btnPanel.rule.name"] = {
		binds = {
			event = "effect",
			data = { outline = { color = ui.COLORS.OUTLINE.DEFAULT } },
		},
	},
	["rightPanel.btnPanel.defend"] = {
		varname = "defend",
		binds = {
			event = "touch",
			methods = { ended = bindHelper.self("onDefendArrayClick") },
		},
	},
	["rightPanel.btnPanel.defend.name"] = {
		binds = {
			event = "effect",
			data = { outline = { color = ui.COLORS.OUTLINE.DEFAULT } },
		},
	},
	["rightPanel.btnPanel.rank"] = {
		binds = {
			event = "touch",
			methods = { ended = bindHelper.self("onRankClick") },
		},
	},
	["rightPanel.btnPanel.rank.name"] = {
		binds = {
			event = "effect",
			data = { outline = { color = ui.COLORS.OUTLINE.DEFAULT } },
		},
	},
	["rightPanel.btnPanel.record"] = {
		binds = {
			event = "touch",
			methods = { ended = bindHelper.self("onRecordClick") },
		},
	},
	["rightPanel.btnPanel.record.name"] = {
		binds = {
			event = "effect",
			data = { outline = { color = ui.COLORS.OUTLINE.DEFAULT } },
		},
	},
	["rightPanel.btnPanel.shop"] = {
		binds = {
			event = "touch",
			methods = { ended = bindHelper.self("onShopClick") },
		},
	},
	["rightPanel.btnPanel.shop.name"] = {
		binds = {
			event = "effect",
			data = { outline = { color = ui.COLORS.OUTLINE.DEFAULT } },
		},
	},


	--waitPanel
	["waitPanel"] = "waitPanel",

	--towerPanel
	["towerPanel"] = "towerPanel",
	["towerPanel.towerList"] = {
		varname = "towerList",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data               = bindHelper.self("towerData"),
				item               = bindHelper.self("floor"),
				preloadCenterIndex = bindHelper.self("myRank"),
			}
		},
	},
	["towerPanel.top"] = "top",
	["towerPanel.middle"] = "middle",
	["towerPanel.bottom"] = "bottom",
	["towerPanel.floor"] = "floor",
	["towerPanel.btnServerRank"] = {
		binds = {
			event = "touch",
			methods = { ended = bindHelper.self("onServerRankClick") },
		},
	},
	["towerPanel.btnServerRank.label"] = {
		binds = {
			event = "effect",
			data = { outline = { color = ui.COLORS.OUTLINE.DEFAULT } },
		},
	},
	["towerPanel.buffItem"] = "buffItem",
	["towerPanel.buffList"] = {
		varname = "buffList",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("buffDatas"),
				item = bindHelper.self("buffItem"),
				onItem = function(list, node, k, v)
					local icon = node:get("icon")
					local time = node:get("time")
					icon:texture(v.cfg.buffIcon)
					text.addEffect(time, { outline = { color = cc.c3b(52, 5, 11) } })
					bind.touch(list, node, { methods = { ended = functools.partial(list.buffClickCell, k, v, node) } })
					setBuffCountdown(list, v.time, time, { tag = v.info.csv_id, info = v.info, cfg = v.cfg })
				end,
			},
			handlers = {
				buffClickCell = bindHelper.self("onBuffClick"),
			},
		}
	},

	--overPanel
	["overPanel"] = "overPanel",
}

function CrossTower:onCreate()
	self.isFirst = true
	gGameUI.topuiManager:createView("cross_mine", self, { onClose = self:createHandler("onClose") })
		:init({ title = gLanguageCsv.crossMine, subTitle = "", sign = true })
	self:initModel()

	idlereasy.when(self.round, function(_, round)
		self.waitPanel:hide()
		self.towerPanel:hide()
		self.overPanel:hide()
		self.right_waitPanel:hide()
		self.right_towerPanel:hide()
		self.right_overPanel:hide()
		self.blessing:hide()
		self.defend:hide()
		if round == "closed" then
			local state = self:getCloseState()
			if state == "result" then
				self.overPanel:show()
				self.right_overPanel:show()
				self:initOverPanel()
			else
				self.waitPanel:show()
				self.right_waitPanel:show()
				self:initWaitPanel(state)
			end
		elseif round == "start" or round == "over" then
			self.towerPanel:show()
			self.right_towerPanel:show()
			self.blessing:show()
			self.defend:show()
			self:updateStartOrOverTime(round)
			self:initTowerPanel()
		end
	end)

	idlereasy.any({ self.robTimes, self.robBuyTimes }, function(_, robTimes, robBuyTimes) -- 竞标次数
		local maxFree = csv.cross.mine.base[1].robFreeTimes
		local canBidding = maxFree + robBuyTimes - robTimes
		canBidding = math.max(canBidding, 0)
		self.leftTimes = canBidding
		local biddingTxt = string.format("%d/%d", canBidding, maxFree)
		local biddingColor = cc.c3b(118, 204, 54)
		if canBidding == 0 then
			biddingColor = cc.c3b(255, 252, 237)
			self.btnAdd:show()
		else
			self.btnAdd:hide()
		end
		self.biddingCount:text(biddingTxt)
		self.biddingCount:color(biddingColor)
	end)

	idlereasy.when(self.boss, function(_, boss)
		if not boss then return end
		local bossDatas = {}
		for id, info in pairs(boss) do
			table.insert(bossDatas, { bossID = id, info = info })
		end
		table.sort(bossDatas, function(a, b)
			return a.info.open_time > b.info.open_time
		end)
		self.bossItem:hide()
		if #bossDatas == 0 then
			return
		end
		local cfg = csv.cross.mine.boss[bossDatas[1].info.csv_id]
		local endTime = cfg.duration * 60 + bossDatas[1].info.open_time

		local countDownTime = endTime - time.getTime()
		if countDownTime <= 0 then
			return
		end
		self.bossItem:show()

		self:enableSchedule():unSchedule(88)
		bind.extend(self, self.bossTime, {
			class = 'cutdown_label',
			props = {
				time = countDownTime,
				tag = 88,
				strFunc = function(t)
					return t.str
				end
			}
		})
	end)

	idlereasy.when(self.killBoss, function(_, killBoss)
		if not killBoss then return end
		local datas = {}
		for bossID, info in pairs(killBoss) do
			local cfg = csv.cross.mine.boss[info.csv_id]
			local endTime = cfg.buffTime * 60 + info.time
			local countTime = endTime - time.getTime()
			if countTime > 0 then
				table.insert(datas, { bossID = bossID, info = info, cfg = cfg, time = countTime })
			end
		end
		self.buffDatas:update(datas)
	end)
end

function CrossTower:initModel()
	self.round = gGameModel.cross_mine:getIdler("round")
	self.startDate = gGameModel.cross_mine:getIdler("date")
	self.serverPoints = gGameModel.cross_mine:getIdler("serverPoints")
	self.servers = idlers.newWithMap({})
	self.serversData = idlers.new()
	self.csvID = gGameModel.cross_mine:read("csvID")
	self.streetShowType = idler.new(self.saveShowStreet or 99)
	self.downPanelPosX = idler.new(self.saveDownPanelPosX or nil)

	self.boss = gGameModel.cross_mine:getIdler("boss")
	self.killBoss = gGameModel.cross_mine:getIdler("killBoss")

	local dailyRecord = gGameModel.daily_record
	self.refreshTimes = dailyRecord:getIdler("cross_mine_enemy_refresh_times") -- 跨服矿战换一批次数
	self.robTimes = dailyRecord:getIdler("cross_mine_rob_times")            -- 已抢夺次数
	self.robBuyTimes = dailyRecord:getIdler("cross_mine_rob_buy_times")     -- 抢夺购买次数

	self.buffDatas = idlers.new()

	self.towerData = {}
	self.myRank = (gGameModel.cross_mine:read("role") or {}).rank or 1000
	self.leftTimes = 0
end

function CrossTower:updateBg(percent)
	self.bg:y(-4800 * (100 - percent) / 100)
end

function CrossTower:initOverPanel()
	self:updateBg(0)
	local datas = {}
	for k, val in pairs(self.serverPoints:read()) do
		table.insert(datas, { servKey = k, score = val })
	end
	table.sort(datas, function(a, b)
		return a.score > b.score
	end)
	self.serversData:update(datas)
	-- 刷新最高3个人
	local rankTable = {}
	for k, val in pairs(gGameModel.cross_mine:read("top10")) do
		table.insert(rankTable, val)
	end
	table.sort(rankTable, function(a, b)
		return a.rank < b.rank
	end)

	for i = 1, 3 do
		local pos = self.overPanel:getChildByName("pos" .. i)
		local infoBg = pos:getChildByName("infoBg")
		local power = infoBg:getChildByName("power")
		local name = infoBg:getChildByName("name")
		local vip = infoBg:getChildByName("vip")
		local levelAndServer = infoBg:getChildByName("levelAndServer")
		local roleParent = pos:getChildByName("roleParent")
		local data = rankTable[i]
		if data then
			name:text(data.name)
			levelAndServer:text(string.format("Lv.%d [%s]", data.level, getServerArea(data.game_key)))
			power:text(data.fighting_point)
			if data.vip > 0 then
				vip:texture(ui.VIP_ICON[data.vip]):show()
			else
				vip:visible(false)
			end
			adapt.oneLineCenterPos(cc.p(280, 145), { name, vip }, cc.p(20, 0))
			local unit = dataEasy.getUnitCsv(333, data.show_skin_id)
			widget.addAnimation(roleParent, unit.unitRes, "standby_loop", 1)
				:scale(unit.scaleU * 0.45)
			pos:setTouchEnabled(true)
			bind.touch(self, pos, {
				methods = {
					ended = function()
						if data.role_db_id then
							gGameApp:requestServer("/game/cross/mine/role/info", function(tb)
								gGameUI:stackUI("city.pvp.cross_mine.personal_info", nil,
									{ clickClose = true, blackLayer = true }, tb.view)
							end, data.record_db_id, data.game_key, data.rank)
						end
					end
				},
				scaletype = 0,
			})
		end
	end
end

function CrossTower:updateFloor(floor)
	local floorItem = self.towerList:getItem(floor - 1)
	local item = floorItem:getChildByName("item")
	if item then
		local data = self.towerData[floor]
		local info = item:getChildByName("info")
		if info then
			info:visible(true)
			info:getChildByName("serverName"):text(string.format(gLanguageCsv.brackets,
				getServerArea(data.game_key, true)))
			info:getChildByName("name"):text(data.name)
			info:getChildByName("icon"):getChildByName("power"):text(data.fighting_point)
		end
		local btn_state = item:getChildByName("btn_state")
		if btn_state then
			if floor < self.myRank then
				btn_state:setTouchEnabled(true)
				bind.touch(self, btn_state, {
					methods = {
						ended = function()
							self:onFightClick(data)
						end
					}
				})
			end
		end
		item:setTouchEnabled(true)
		bind.touch(self, item, {
			methods = {
				ended = function()
					if data.role_db_id then
						gGameApp:requestServer("/game/cross/mine/role/info", function(tb)
							gGameUI:stackUI("city.pvp.cross_mine.personal_info", nil,
								{ clickClose = true, blackLayer = true }, tb.view)
						end, data.record_db_id, data.game_key, data.rank)
					end
				end
			},
			scaletype = 0,
		})
		local roleSpinePanel = item:getChildByName("roleSpinePanel")
		local skinID =  nil
		if floor <= 5 then
			skinID = tonumber("10" .. floor)
		end
		if roleSpinePanel then
			if skinID then
				local unit = dataEasy.getUnitCsv(skinID, skinID)
				widget.addAnimation(roleSpinePanel, unit.unitRes, "standby_loop", 1)
					:scale(unit.scaleU * 0.35)
			else
				local unit = dataEasy.getUnitCsv(333, data.show_skin_id)
				widget.addAnimation(roleSpinePanel, unit.unitRes, "standby_loop", 1)
					:scale(unit.scaleU * 0.35)
			end
		end
	end
end

function CrossTower:initFloor(floor)
	if floor < 1 or floor > 1000 then return end
	local floorItem = self.towerList:getItem(floor - 1)
	local item = floorItem:getChildByName("item")
	if item then
		return
	end

	if floor == 1 then
		item = self.top:clone()
	elseif floor == 1000 then
		item = self.bottom:clone()
	else
		item = self.middle:clone()
		if floor <= 10 then
			local floorBg = item:getChildByName("floorBg"):texture("city/pvp/cross_mine/tower/floorBg.png")
			floorBg:y(floorBg:y() + 16)
		end
	end
	local rank = item:getChildByName("rank")
	if rank then
		rank:text("Rank " .. floor)
		text.addEffect(rank, { outline = { color = ui.COLORS.BLACK, size = 2 } })
	end
	floorItem:addChild(item)
	item:setName("item")
	item:xy(1000, 370)
end

function CrossTower:updateBtnState(index)
	local floor = index + 1
	local floorItem = self.towerList:getItem(index)
	if floorItem then
		local item = floorItem:getChildByName("item")
		if item then
			local data = self.towerData[floor]
			local btn_state = item:getChildByName("btn_state")
			if btn_state then
				if not data.role_db_id then
					btn_state:visible(true)
				else
					if data.role_db_id == gGameModel.role:read("id") then
						btn_state:visible(true)
						btn_state:texture("city/pvp/cross_mine/tower/state2.png")
					else
						if floor < self.myRank then
							btn_state:visible(true)
							btn_state:texture("city/pvp/cross_mine/tower/state1.png")
						end
					end
				end
			end
		end
	end
end

function CrossTower:updateTowerByIndex(index)
	local floor = index + 1
	local floorData = self.towerData[floor]
	if floorData and floorData.inited == false then
		for i = floor - 5, floor + 5, 1 do
			if self.towerData[i] and self.towerData[i].inited == false then
				self.towerData[i].inited = true
				self:initFloor(i)
			end
		end
		self:initFloor(floor - 6) --上面补一个
		self:initFloor(floor + 6) -- 下面补一个
		local startIndex = floor - 5 - 1
		local count = 11
		if startIndex < 0 then
			count = startIndex + 11
			startIndex = 0
		end
		self.towerList:stopAutoScroll()
		gGameApp:requestServer("/game/cross/mine/rank", function(tb)
			for k, v in pairs(tb.view.rank.ranks) do
				local floorData = self.towerData[v.rank]
				if floorData and not floorData.role_db_id then
					for kk, vv in pairs(v) do
						floorData[kk] = vv
					end
					if v.rank == self.myRank then
						self:updateFloor(v.rank)
					else
						table.insert(self.dirtyFloors, v.rank)
					end
				end
			end
			for ii = startIndex, startIndex + count - 1 do
				self:updateBtnState(ii)
			end
		end, "role", startIndex, count)
	end
end

function CrossTower:initTowerPanel()
	self.dirtyFloors = {}
	self.towerData = {}
	for i = 1, 1000 do
		table.insert(self.towerData, { rank = i, inited = false })
	end

	self.lastCenterItemIndex = -1
	self.towerList:onScroll(function(event)
		performWithDelay(self, function()
			self:updateBg(self.towerList:getScrolledPercentVertical())
			local currentItem = self.towerList:getCenterItemInCurrentView()
			if currentItem then
				local index = self.towerList:getIndex(currentItem)
				if index ~= self.lastCenterItemIndex then
					self:updateTowerByIndex(index)
				end
				self.lastCenterItemIndex = index
			end
		end, 0)
	end)
	self:enableSchedule()
	self:unSchedule("updateFloor")
	self:schedule(function()
		local rank = table.remove(self.dirtyFloors, 1)
		if rank then
			self:updateFloor(rank)
			return
		end
	end, 0, 0, "updateFloor")
end

function CrossTower:initWaitPanel(state)
	self:updateBg(100)
	if self.date then
		local startDate = time.getNumTimestamp(self.date)
		local t1 = time.getDate(startDate)
		local strStartTime = string.formatex(gLanguageCsv.timeMonthDay, { month = t1.month, day = t1.day }) ..
			dataEasy.getTimeStrByKey("crossMine", "mineStart")

		local endTime = time.getNumTimestamp(self.date) + 2 * 24 * 60 * 60
		local t2 = time.getDate(endTime)
		local strEndTime = string.formatex(gLanguageCsv.timeMonthDay, { month = t2.month, day = t2.day }) ..
			dataEasy.getTimeStrByKey("crossMine", "mineEnd")
		self.textTime:text(strStartTime .. "--" .. strEndTime)
		self.noMatchServer:visible(not state)
		self.serverList:visible(not not state)
	end
end

function CrossTower:getCloseState()
	local id = dataEasy.getCrossServiceData("crossmine")
	if id then
		local cfg = csv.cross.service[id]
		self.date = cfg.date
		local startTime = time.getNumTimestamp(cfg.date, 5) - 1 * 24 * 3600 -- 下一场比赛开始前一天
		local endTime = time.getNumTimestamp(cfg.date, dataEasy.getTimeStrByKey("crossMine", "mineStart", true))
		-- 到点服务器状态还没变的，继续显示匹配服 2 天开赛中
		if time.getTime() >= startTime and time.getTime() < endTime + 24 * 3600 then
			self.servers:update(getMergeServers(cfg.servers))
			self:countStates("closed", endTime - time.getTime())
			self.csvID = id
			return "wait"
		end
	end
	if self.serverPoints:read() and itertools.size(self.serverPoints:read()) > 0 then
		return "result"
	else
		return nil
	end
end

function CrossTower:countStates(states, time)
	local round = self.round:read()
	if round ~= states then
		return
	end
	if self.isFirst then
		self.isFirst = false
		if time <= 0 then
			gGameApp:requestServer("/game/cross/mine/main", functools.handler(self, "countStates", states, 10))
			return
		end
	end
	if time < 0 then
		time = 10
	end
	performWithDelay(self, function()
		gGameApp:requestServer("/game/cross/mine/main", functools.handler(self, "countStates", states, 10))
	end, time)
end

--祝福
function CrossTower:onBlessingClick()
	gGameUI:stackUI("city.pvp.cross_mine.wish")
end

--规则
function CrossTower:onRuleClick()
	if not self.rulePanel:get("ruleItem") then
		ccui.Layout:create():hide():addTo(self.rulePanel, 1, "ruleItem")
	end
	gGameUI:stackUI("common.rule", nil, nil, self:createHandler("getRuleContext"), { width = 1500 })
end

function CrossTower:getRuleContext(view)
	local c = adaptContext
	local context = {
		c.clone(view.title, function(item)
			item:get("text"):text(gLanguageCsv.rules)
		end),
		c.noteText(154),
		c.noteText(113001, 113019),
		c.noteText(155),
		c.noteText(113020, 113039),
		c.noteText(156),
		c.noteText(113040, 113059),
		c.noteText(157),
		c.noteText(113080, 113099),
	}
	if self.round:read() == "closed" then
		table.insert(context, 2, gLanguageCsv.crossMineRoleRankCloseTips)
		return context
	end
	local role = gGameModel.cross_mine:read("role")
	local version = gGameModel.cross_mine:read("version")
	if role and role.rank then
		local endH, endM = dataEasy.getTimeStrByKey("crossMine", "mineStart", true) -- 获取开始时间
		local myRank = role.rank
		table.insert(context, 2, string.format(gLanguageCsv.crossMineRoleRankTips, myRank))
		table.insert(context, 3, c.clone(view.awardItem, function(item)
			-- local version = csv.cross.service[self.csvID].version
			local childs = item:multiget("text", "list")
			childs.text:text("")
			local rank = 0
			for k, v in orderCsvPairs(csv.cross.mine.role_award) do
				if v.version == version then
					if myRank > rank and myRank <= v.rankMax then
						local award = v.dayAward
						-- 判断天数，最后一天显示
						local lastDayBeginTime = time.getNumTimestamp(self.startDate:read(), endH, endM) +
							2 * 24 * 60 * 60
						if time.getTime() > lastDayBeginTime then
							award = v.endAward
						end
						uiEasy.createItemsToList(view, childs.list, award)
						break
					end
					rank = v.rankMax
				end
			end
		end))
	end
	return context
end

-- 布阵
function CrossTower:onDefendArrayClick()
	if self.round:read() == "start" or self.round:read() == "over" then
		gGameUI:stackUI("city.pvp.cross_mine.embattle", nil, { full = true })
	else
		gGameUI:showTip(gLanguageCsv.crossMineNotStart)
	end
end

-- 排行榜
function CrossTower:onRankClick()
	if self.round:read() == "start" or self.round:read() == "over" or self:getCloseState() == "result" then
		gGameApp:requestServer("/game/cross/mine/rank", function(tb)
			local fightDatas = tb.view
			gGameApp:requestServer("/game/cross/mine/rank", function(tb)
				gGameUI:stackUI("city.pvp.cross_mine.rank", nil, nil, fightDatas, tb.view)
			end, "feed", 0, 11)
		end, "role", 0, 11)
	else
		gGameUI:showTip(gLanguageCsv.crossArenaNoRank)
	end
end

-- 回放
function CrossTower:onRecordClick()
	if self.round:read() == "start" or self.round:read() == "over" or self:getCloseState() == "result" then
		gGameUI:stackUI("city.pvp.cross_mine.combat_record", nil, nil,
			{ blessingCb = self:createHandler("blessingCallBack") })
	else
		gGameUI:showTip(gLanguageCsv.crossMineNotStart)
	end
end

-- 商店
function CrossTower:onShopClick()
	if not gGameUI:goBackInStackUI("city.shop") then
		gGameApp:requestServer("/game/fixshop/get", function(tb)
			gGameUI:stackUI("city.shop", nil, { full = true }, game.SHOP_INIT.CROSS_MINE_SHOP)
		end)
	end
end

function CrossTower:onServerClick()
	gGameApp:requestServer("/game/cross/mine/main", function()
		gGameUI:stackUI("city.pvp.cross_mine.server_rank", nil, { full = true })
	end)
end

function CrossTower:updateStartOrOverTime(round)
	if round == "start" then
		local endTime = time.getNumTimestamp(time.getTodayStrInClock(0),
			dataEasy.getTimeStrByKey("crossMine", "mineEnd", true))
		local cutdown = endTime - time.getTime()
		self:countStates("start", cutdown)
	elseif round == "over" then
		local endTime = time.getNumTimestamp(time.getTodayStrInClock(0),
			dataEasy.getTimeStrByKey("crossMine", "mineStart", true))
		local nowTime = time.getTime()
		if nowTime > time.getNumTimestamp(time.getTodayStrInClock(0), dataEasy.getTimeStrByKey("crossMine", "mineEnd", true)) then
			endTime = time.getNumTimestamp(time.getTodayStrInClock(0) + 1,
				dataEasy.getTimeStrByKey("crossMine", "mineStart", true))
		end
		local cutdown = endTime - nowTime
		self:countStates("over", cutdown)
	end
end

function CrossTower:onCleanup()
	self.saveShowStreet = self.streetShowType:read()
	self.saveDownPanelPosX = self.downPanelPosX:read()
	ViewBase.onCleanup(self)
end

function CrossTower:blessingCallBack(data, enemy, isRevenge)
	gGameUI:stackUI("city.pvp.cross_mine.lineup_adjust", nil, { full = true }, data,
		{ fightCb = self:createHandler("startFighting", enemy, isRevenge), isRevenge = isRevenge })
end

--battleCards 当前阵容
function CrossTower:startFighting(vData, isRevenge, view, battleCards)
	local role = gGameModel.cross_mine:read("role")
	local myRank = role.rank
	-- 防止schedule中有网络请求行为
	self:disableSchedule()
	local battleType = "rob"
	if isRevenge then
		battleType = "revenge"
	end
	battleEntrance.battleRequest("/game/cross/mine/battle/start", battleType, myRank, vData.rank,
		vData.roleID, vData.recordID)
		:onStartOK(function(data)
			if view then
				view:onCloseSelf()
				view = nil
			end
		end)
		:onResult(function(data, results)
			local waveReusult = clone(results.waveResult)
			if results.result == "win" then
				table.insert(waveReusult, 1)
			else
				table.insert(waveReusult, 2)
			end
			data.waveReusult = waveReusult
		end)
		:run()
		:show()
end

--btn click
function CrossTower:onTopClick()
	self.towerList:jumpToTop()
end

function CrossTower:onMineClick()
	self.towerList:scrollToPercentVertical((self.myRank - 1) / 1000 * 100, 0, false)
end

function CrossTower:onBottomClick()
	self.towerList:jumpToBottom()
end

-- buff详情
function CrossTower:onBuffClick(list, k, v, node)
	local pos = node:parent():convertToWorldSpace(cc.p(0, 0))
	local params = { data = v.cfg, pos = { pos.x, pos.y + 200 } }
	gGameUI:createView("city.pvp.cross_mine.buff_info", self.towerPanel:parent():parent()):init(params):z(100)
end

function CrossTower:onServerRankClick()
	gGameApp:requestServer("/game/cross/mine/main", function()
		gGameUI:createView("city.pvp.cross_mine.server_rank", self.towerPanel:parent()):init():z(100)
	end)
end

function CrossTower:onBossClick()
	local bossDatas = {}
	local boss = self.boss:read()
	for id, info in pairs(boss) do
		table.insert(bossDatas, { bossID = id, info = info })
	end
	table.sort(bossDatas, function(a, b)
		return a.info.open_time > b.info.open_time
	end)
	if bossDatas[1] and bossDatas[1].bossID then
		gGameUI:stackUI("city.pvp.cross_mine.boss_challenge", nil, { clickClose = true, blackLayer = true },
			bossDatas[1].bossID)
	end
end

function CrossTower:onAddClick(callBack)
	local times = math.min(itertools.size(gCostCsv.cross_mine_rob_buy_cost), self.robBuyTimes:read() + 1)
	local curCost = gCostCsv.cross_mine_rob_buy_cost[times]
	local params = {
		cb = function()
			gGameApp:requestServer("/cross/mine/times/buy", function()
				if type(callBack) == "function" then
					callBack()
				end
			end, "rob")
		end,
		isRich = true,
		btnType = 2,
		content = string.format(gLanguageCsv.richCostDiamond, curCost) .. gLanguageCsv.pvpBiddingBuyTimes,
		dialogParams = { clickClose = false },
	}
	gGameUI:showDialog(params)
end

function CrossTower:onFightClick(data)
	if self.round:read() == "over" then
		gGameUI:showTip(gLanguageCsv.crossMineTruce)
		return
	end
	gGameApp:requestServer("/game/cross/mine/role/info", function(tb)
		local info = tb.view
		local endHour, endmin = dataEasy.getTimeStrByKey("crossMine", "mineEnd", true)
		local endTime = time.getNumTimestamp(gGameModel.cross_mine:read("date"), endHour, endmin) + 2 * 24 * 3600
		if endTime - time.getTime() > gCommonConfigCsv.crossMineDisablenBattleProtectBeforeOver * 60 then
			if info.role_be_roded.time and #info.role_be_roded.time > 0 and info.role_be_roded.time[#info.role_be_roded.time] + 5 * 60 > time.getTime() then -- 被挑战5分钟内不允许被挑战
				gGameUI:showTip(string.format(gLanguageCsv.crossMineProtected, info.role_name))
				return
			end
		end
		local enemy = {
			roleID = data.role_db_id,
			recordID = data.record_db_id,
			rank = info.rank
		}
		if self.leftTimes > 0 then
			self:blessingCallBack(info, enemy)
		else
			self:onAddClick(function() self:blessingCallBack(info, enemy) end)
		end
	end, data.record_db_id, data.game_key, data.rank, "rob")
end

return CrossTower
