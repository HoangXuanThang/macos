-- @date 2021-11-09
-- @desc 世界锦标赛主界面

local ViewBase = cc.load("mvc").ViewBase
local CrossSupremacy = class("CrossSupremacy", ViewBase)

local REFRESH_TIME = {
	-327600,
	-136800,
	36000,
	277200,
	640800,
	882000,
	1245600,
	1486800,
	1850400,
	2091600
}

CrossSupremacy.RESOURCE_FILENAME = "cross_supremacy.json"
CrossSupremacy.RESOURCE_BINDING = {
	["serverPanel"] = "serverPanel",
	["noServerPanel"] = "noServerPanel",
	["serverPanel.textOpenTime"] = {
		varname = "textOpenTime",
		binds = {
			event = "effect",
			data = { outline = { color = ui.NEWCOLORS.OUTLINE.BLACK } },
		},
	},
	-- 底部按钮
	["downPanel.history"] = {
		binds = {
			{
				event = "touch",
				methods = { ended = bindHelper.self("onHistoryClick") }
			},
		}
	},
	["downPanel.history.name"] = {
		binds = {
			event = "effect",
			data = { outline = { color = ui.COLORS.OUTLINE.DEFAULT } },
		},
	},
	["downPanel.rule"] = {
		varname = "rulePanel",
		binds = {
			event = "touch",
			methods = { ended = bindHelper.self("onRuleClick") }
		},
	},
	["downPanel.rule.name"] = {
		binds = {
			event = "effect",
			data = { outline = { color = ui.COLORS.OUTLINE.DEFAULT } },
		},
	},
	["downPanel.embattle"] = {
		binds = {
			event = "touch",
			methods = { ended = bindHelper.self("onEmbattleClick") }
		},
	},
	["downPanel.embattle.name"] = {
		binds = {
			event = "effect",
			data = { outline = { color = ui.COLORS.OUTLINE.DEFAULT } },
		},
	},
	["downPanel.award"] = {
		binds = {
			{
				event = "touch",
				methods = { ended = bindHelper.self("onAwardClick") }
			},
		},
	},
	["downPanel.award.name"] = {
		binds = {
			event = "effect",
			data = { outline = { color = ui.COLORS.OUTLINE.DEFAULT } },
		},
	},
	["downPanel.report"] = {
		binds = {
			event = "touch",
			methods = { ended = bindHelper.self("onReportClick") }
		},
	},
	["downPanel.report.name"] = {
		binds = {
			event = "effect",
			data = { outline = { color = ui.COLORS.OUTLINE.DEFAULT } },
		},
	},
	["downPanel.shop"] = {
		binds = {
			event = "touch",
			methods = { ended = bindHelper.self("onShopClick") }
		},
	},
	["downPanel.shop.name"] = {
		binds = {
			event = "effect",
			data = { outline = { color = ui.COLORS.OUTLINE.DEFAULT } },
		},
	},
	["downPanel"] = "downPanel",
}

function CrossSupremacy:onCreate(data)
	self.topIUI = gGameUI.topuiManager:createView("cross_supremacy", self, { onClose = self:createHandler("onClose") })
		:init({ title = gLanguageCsv.crossSupremacyName, subTitle = "", sign = true })

	self:enableSchedule()

	self.data = data
	self:initModel()
	self.subView = {}
	self.subViewFunc = {
		main = function(...)
			local pNode = self:getResourceNode()
			return gGameUI:createView("city.pvp.cross_supremacy.main", pNode):init(...)
		end,
		selectEnemy = function(...)
			return gGameUI:createView("city.pvp.cross_supremacy.select_enemy", self):init(...)
		end,
		over = function(...)
			return gGameUI:createView("city.pvp.cross_supremacy.over", self):init(...)
		end,
	}
	idlereasy.any({ self.round, self.enemies }, function(_, round, enemies)
		local viewName = nil

		if round == "start" then
			self.serverPanel:hide()
			self.noServerPanel:hide()

			if itertools.size(enemies) > 0 then
				viewName = "selectEnemy"
				self.topIUI:getResourceNode():get("rightTopPanel"):hide()
				self.downPanel:hide()
			else
				viewName = "main"
				self.topIUI:getResourceNode():get("rightTopPanel"):show()
				self.downPanel:show()
			end
		elseif round == "over" then
			self.serverPanel:hide()
			self.noServerPanel:hide()

			viewName = "main"
			self.topIUI:getResourceNode():get("rightTopPanel"):show()
			self.downPanel:show()
		elseif round == "closed" or round == "init" then
			self.topIUI:getResourceNode():get("rightTopPanel"):show()
			self.downPanel:show()
			local state = self:getCloseState()
			if state == "showService" then
				self.serverPanel:show()
				self:initServerPanel()
			elseif state == "showRank" then
				viewName = "over"
				self.serverPanel:hide()
				self.topIUI:getResourceNode():get("rightTopPanel"):show()
				self.serverPanel:hide()
				self.noServerPanel:hide()
				self.downPanel:show()
			else
				self.serverPanel:hide()
				self.noServerPanel:show()
			end
		end
		self:showSubView(viewName, self.data)

		if self.crossSupremacyCsvId and csv.cross.service[self.crossSupremacyCsvId] then
			local date = csv.cross.service[self.crossSupremacyCsvId].date
			local time1 = time.getNumTimestamp(date, 0)
			local nextRefreshTime = 0

			for i, v in ipairs(REFRESH_TIME) do
				if time.getTime() < v + time1 then
					nextRefreshTime = v + time1

					break
				end
			end

			if nextRefreshTime ~= 0 and time.getTime() < nextRefreshTime then
				self:unSchedule(100)
				self:schedule(function()
					if time.getTime() > nextRefreshTime + 10 then
						gGameApp:requestServer("/game/cross/supremacy/main", functools.handler(self, "countToStart", 10))

						return false
					end
				end, 1, 0, 100)
			end
		end
	end)
end

function CrossSupremacy:getCloseState()
	local id = dataEasy.getSupremacyServiceData()
	if id then
		local cfg = csv.cross.service[id]
		self.date = cfg.date
		--下一场比赛的前2天晚上5点到开赛早上5点展示区服信息
		local startTime = time.getNumTimestamp(cfg.date, 5) - 2 * 24 * 3600
		local endTime = time.getNumTimestamp(cfg.date, 10)
		if time.getTime() >= startTime and time.getTime() < endTime then
			self:countToStart(endTime - time.getTime())
			self.crossSupremacyCsvId = id
			return "showService"
		end
	end
	if self.lastRank and itertools.size(self.lastRank:read()) > 0 then
		return "showRank"
	end
	return "showNoService"
end

function CrossSupremacy:countToStart(endTime)
	local round = self.round:read()
	if round ~= "closed" then
		return
	end
	if endTime < 0 then
		endTime = 10
	end
	performWithDelay(self, function()
		gGameApp:requestServer("/game/cross/supremacy/main", functools.handler(self, "countToStart", 10))
	end, endTime)
end

function CrossSupremacy:initServerPanel()
	local startDate = time.getNumTimestamp(self.date)
	local t1 = time.getDate(startDate)
	local strStartTime = string.formatex(gLanguageCsv.timeMonthDay, { month = t1.month, day = t1.day }) .. "10:00"
	local str = gLanguageCsv.crossSupremacyOpenTime
	self.textOpenTime:text(string.format(str, self.historyNum + 1, t1.year, strStartTime))
end

function CrossSupremacy:initModel()
	self.round = gGameModel.cross_supremacy:getIdler("round")
	self.historyNum = gGameModel.cross_supremacy:read("historyNum") or 0
	self.lastRank = gGameModel.cross_supremacy:getIdler("lastRank")
	self.crossSupremacyCsvId = gGameModel.cross_supremacy:read("csvID")
	self.enemies = gGameModel.cross_supremacy:getIdler("enemies")
end

function CrossSupremacy:showSubView(viewName, ...)
	if self.subView.name ~= viewName then
		if self.subView.view then
			self.subView.view:onClose()
		end
		if viewName == nil then
			self.subView = {}
		else
			self.subView = {
				name = viewName,
				view = self.subViewFunc[viewName](self, ...)
			}
		end
	end
end

--段位奖励
function CrossSupremacy:onAwardClick()
	if self.round:read() == "closed" and not self:getCloseState() then
		gGameUI:showTip(gLanguageCsv.crossCraftFirstPrepare)
	else
		gGameUI:stackUI("city.pvp.cross_supremacy.award", nil, nil, self.crossSupremacyCsvId)
	end
end

--规则
function CrossSupremacy:onRuleClick()
	gGameUI:stackUI("common.rule", nil, nil, self:createHandler("getRuleContext"), { width = 1500 })
end

function CrossSupremacy:getRuleContext(view)
	local c = adaptContext
	local context = {
		c.clone(view.title, function(item)
			item:get("text"):text(gLanguageCsv.rules)
		end),
		c.noteText(125901, 126000)
	}
	return context
end

-- 防守阵容
function CrossSupremacy:onEmbattleClick()
	if self.round:read() == "start" or self.round:read() == "over" then
		local date = csv.cross.service[self.crossSupremacyCsvId].date

		if userDefault.getForeverLocalKey("crossSupremacyDate", 0) == date then
			gGameUI:stackUI("city.pvp.cross_supremacy.embattle", nil, {
				full = true
			})
		else
			gGameUI:stackUI("city.pvp.cross_supremacy.embattle", nil, {
				full = true
			}, true)
			userDefault.setForeverLocalKey("crossSupremacyDate", date)
		end
	else
		gGameUI:showTip(gLanguageCsv.crossSupremacyNotOpen)
	end
end

-- 回放
function CrossSupremacy:onReportClick()
	if self.round:read() ~= "start" then
		gGameUI:showTip(gLanguageCsv.crossSupremacyNotOpen)
	else
		gGameUI:stackUI("city.pvp.cross_supremacy.combat_record")
	end
end

-- 纪念室
function CrossSupremacy:onHistoryClick()
	local history = self.historyNum
	if history <= 0 then
		gGameUI:showTip(gLanguageCsv.crossSupremacyHaveNotCompSeason)
	else
		gGameApp:requestServer("/game/cross/supremacy/rank", function(tb)
			gGameUI:stackUI("city.pvp.cross_supremacy.history", nil, nil, tb.view, history)
		end, 0, gCommonConfigCsv.memorialCount, history)
	end
end

-- 商店
function CrossSupremacy:onShopClick()
	if not gGameUI:goBackInStackUI("city.shop") then
		gGameApp:requestServer("/game/fixshop/get", function(tb)
			gGameUI:stackUI("city.shop", nil, { full = true }, game.SHOP_INIT.CROSS_SUPREMACY_SHOP)
		end)
	end
end

return CrossSupremacy
