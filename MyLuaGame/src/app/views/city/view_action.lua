-- 主城 - 玩法养成功能子模块

local CityView = {}

local DispatchTaskView = require("app.views.city.adventure.dispatch_task.view")

-- 定时器tag集合，防止重复
local SCHEDULE_TAG = {
	-- sceneSet = 1,
	-- cityMan = 2,
	-- mysteryShop = 3,
	-- onlineGift = 4,
	-- limitBuyGift = 5,
	dispatchTaskRefresh = 5,
}

local function getActionBtnsData()
	return {
		{
			key = "shop",
			icon = "city/new_main/shangdian.png",
			name = gLanguageCsv.shop,
			viewName = "city.shop",
			styles = { full = true },
			func = function(cb)
				gGameApp:requestServer("/game/fixshop/get", function()
					cb()
				end)
			end,
		}, {
		key = "drawCard",
		icon = "city/new_main/chouka.png",
		name = gLanguageCsv.drawCard,
		viewName = "city.drawcard.view",
		styles = { full = true },
		redHint = {
			class = "red_hint",
			props = {
				specialTag = {
					"drawcardDiamondFree",
					"drawcardGoldFree",
					"drawcardEquipFree",
				},
			}
		}
	}, {
		key = "bag",
		icon = "city/new_main/beibao.png",
		name = gLanguageCsv.bag,
		viewName = "city.bag",
		styles = { full = true },
	}, {
		key = "task",
		icon = "city/new_main/renwu.png",
		name = gLanguageCsv.task,
		actionExpandName = "task",
		offx = 255,
		styles = { full = true },
		viewName = "city.task",
		redHint = {
			class = "red_hint",
			props = {
				specialTag = {
					"cityTaskDaily",
					"cityTaskMain",
					"achievementTask",
					"achievementBox",
				},
			}
		}
	}, {
		key = "cardBag",
		icon = "city/new_main/yingxiong.png",
		name = gLanguageCsv.card,
		viewName = "city.card.bag",
		styles = { full = true },
		redHint = {
			class = "red_hint",
			props = {
				specialTag = {
					"bottomFragment",
					"totalCard",
				},
			}
		}
	}, {
		key = "team",
		icon = "city/new_main/biandui.png",
		name = gLanguageCsv.formation,
		viewName = "city.card.embattle.base",
		styles = { full = true },
	}, {
		key = "develop",
		icon = "city/new_main/yangcheng.png",
		name = gLanguageCsv.develop,
		actionExpandName = "develop",
		offx = -111,
		styles = { full = true },
		redHint = {
			class = "red_hint",
			props = {
				specialTag = {
					"cityTalent",
					"cityTrainer",
					"explorerTotal",
					"explorerFind",
				},
			}
		}
	},
	}
end


local function getDevelopBtnsData()
	return {
		{
			key = "title_book",
			unlockKey = "title",
			icon = "city/main/icon_chp@.png",
			name = gLanguageCsv.titleBook,
			viewName = "city.develop.title_book.view",
		},
		{
			key = "trainer",
			unlockKey = "trainer",
			icon = "city/main/icon_mxzz.png",
			name = gLanguageCsv.training,
			viewName = "city.develop.trainer.view",
			styles = { full = true },
			redHint = {
				class = "red_hint",
				props = {
					specialTag = "cityTrainer",
					onNode = function(node)
						node:xy(152, 152)
					end,
				}
			}
		},
		{
			key = "talent",
			unlockKey = "talent",
			icon = "city/main/icon_tf@.png",
			bg = "city/panel_icon2.png",
			name = gLanguageCsv.talent,
			viewName = "city.develop.talent.view",
			styles = { full = true },
			redHint = {
				class = "red_hint",
				props = {
					specialTag = "cityTalent",
					onNode = function(node)
						node:xy(152, 152)
					end,
				}
			}
		},
		{
			key = "explore",
			icon = "city/main/icon_txq.png",
			name = gLanguageCsv.explorer,
			unlockKey = "explorer",
			viewName = "city.develop.explorer.view",
			styles = { full = true },
			redHint = {
				class = "red_hint",
				props = {
					specialTag = {
						"explorerTotal",
						"explorerFind",
					},
					onNode = function(node)
						node:xy(152, 152)
					end,
				}
			}
		},
		{
			key = 'gem',
			unlockKey = 'gem',
			icon = 'city/card/gem/icon_fsxq1.png',
			name = gLanguageCsv.gemTitle,
			viewName = "city.card.gem.view",
			redHint = {
				class = "red_hint",
				props = {
					specialTag = "cityGemFreeExtract",
					onNode = function(node)
						node:xy(152, 152)
					end,
				}
			}
		},
		{
			key = 'mega',
			unlockKey = 'mega',
			icon = 'city/card/mega/icon_rk_cjh.png',
			name = gLanguageCsv.megaTitle,
			styles = { full = true },
			viewName = "city.card.mega.view",
			redHint = {
				class = "red_hint",
				props = {
					specialTag = "cardMega",
					onNode = function(node)
						node:xy(152, 152)
					end,
				}
			}
		},
		{
			key = 'gymBadge',
			unlockKey = 'badge',
			icon = 'city/develop/gym_badge/icon_hz.png',
			name = gLanguageCsv.badgeTitle,
			viewName = "city.develop.gym_badge.view",
			styles = { full = true },
		},
		{
			key = 'chip',
			unlockKey = 'chip',
			icon = 'city/card/chip/icon_chip.png',
			name = gLanguageCsv.chip,
			viewName = "city.card.chip.bag",
			styles = { full = true },
			redHint = {
				class = "red_hint",
				props = {
					specialTag = "cityChipFreeExtract",
					onNode = function(node)
						node:xy(152, 152)
					end,
				}
			}
		},
	}
end

local function getTaskBtnsData()
	return {
		{
			key = "task",
			icon = "city/main/icon_rw.png",
			name = gLanguageCsv.task,
			viewName = "city.task",
			styles = { full = true },
			redHint = {
				class = "red_hint",
				props = {
					specialTag = {
						"cityTaskDaily",
						"cityTaskMain",
					},
				}
			}
		},
		{
			key = "achievement",
			unlockKey = "achievement",
			icon = "city/main/icon_cj@.png",
			name = gLanguageCsv.achievement,
			viewName = "city.achievement",
			styles = { full = true },
			redHint = {
				class = "red_hint",
				props = {
					specialTag = {
						"achievementTask",
						"achievementBox",
					},
				}
			}
		},
	}
end

function CityView:updateActionBtnsDatas()
	local t = {}
	for k, v in ipairs(getActionBtnsData()) do
		local show = true
		if v.unlockKey then
			show = dataEasy.isShow(v.unlockKey)
		end

		if show then
			table.insert(t, v)
		end
	end
	self.actionBtns:update(t)
end

function CityView:setActionBtnsDatasIdler()
	local sign = false
	for k, v in ipairs(getActionBtnsData()) do
		if v.unlockKey then
			dataEasy.getListenShow(v.unlockKey, function(isShow)
				if sign then
					self:updateActionBtnsDatas()
				end
			end)
		end
	end
	sign = true
	self:updateActionBtnsDatas()
end

function CityView:initActionData()
	self.actionBtns = idlers.newWithMap({})
	self.developBtns = idlertable.new({})

	local developKeys = {
		"title",
		"trainer",
		"talent",
		"explorer",
		"achievement",
		'gem',
		'mega',
		"badge",
		"chip",
	}
	local developShowListen = {}
	for _, v in ipairs(developKeys) do
		table.insert(developShowListen, dataEasy.getListenShow(v))
	end

	self:setActionBtnsDatasIdler()

	idlereasy.any(arraytools.merge({ { self.actionExpandName }, developShowListen }), function(_, actionExpandName, ...)
		local params = { ... }
		local isShow = {}
		for k, v in ipairs(developKeys) do
			isShow[v] = params[k]
		end
		for _, v in self.developBtns:pairs() do
			if v.unlockRes then
				v.unlockRes:destroy()
			end
		end
		local developBtns
		if actionExpandName == "task" then
			developBtns = getTaskBtnsData()
		else
			developBtns = getDevelopBtnsData()
		end

		for i = #developBtns, 1, -1 do
			local v = developBtns[i]
			if v.unlockKey then
				if not isShow[v.unlockKey] then
					table.remove(developBtns, i)
				end
			end
		end
		local columnSize = math.max(4, math.ceil(#developBtns / 2))
		self.developList.columnSize = columnSize
		local listHigh, tmp = math.modf(#developBtns / columnSize)
		self.developBg:size(175 * (#developBtns < columnSize and #developBtns or columnSize) + 25,
			197 * (tmp == 0 and listHigh or listHigh + 1))
		self.developList:size(200 * columnSize, 180 * (tmp == 0 and listHigh or listHigh + 1))
		self.listItem:size(200 * columnSize, 180)
		self.developBg:y(117 + 103 * (tmp == 0 and listHigh - 1 or listHigh))
		self.developList:xy(self.developBg:x() - self.developBg:size().width / 2 + 15,
			self.developBg:y() + 10 + 90 * (tmp == 0 and listHigh or listHigh + 1))
		self.developBtns:set(developBtns)

		-- 若只有任务开放，则任务非扩展形式
		for i, v in self.actionBtns:ipairs() do
			local data = v:proxy()
			if data.key == "task" then
				if not isShow.achievement then
					data.actionExpandName = nil
				else
					data.actionExpandName = "task"
				end
				break
			end
		end
	end)

	dataEasy.getListenUnlock(gUnlockCsv.dispatchTask, function(isUnlock)
		if isUnlock == true then
			DispatchTaskView.setRefreshTime(self, nil, {
				tag = SCHEDULE_TAG.dispatchTaskRefresh,
				cb = function()
					local dispatchTasksRedHintRefrseh = gGameModel.forever_dispatch:getIdlerOrigin(
						"dispatchTasksRedHintRefrseh")
					dispatchTasksRedHintRefrseh:modify(function(val)
						return true, not val
					end)
				end
			})
		end
	end)
end

return function(cls)
	for k, v in pairs(CityView) do
		cls[k] = v
	end
end
