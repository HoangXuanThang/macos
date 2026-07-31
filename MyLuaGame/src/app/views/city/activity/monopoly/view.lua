
local YY_TYPE = game.YYHUODONG_TYPE_ENUM_TABLE

-- npc人物状态
local NPC_STATE = {
	stand = "stand",
	run = "run",
}

local MONOPOLY_Dice = game.ITEM_TICKET.monopolyItem  -- 骰子
-- 人物移动事件间隔
local MOVE_TIME = 0.6
local MOVE_SPEED = 3

local ViewBase = cc.load("mvc").ViewBase
local ActivityMonopolyWalkView = class("ActivityMonopolyWalkView", ViewBase)

ActivityMonopolyWalkView.RESOURCE_FILENAME = "treasure_walk.json"
ActivityMonopolyWalkView.RESOURCE_BINDING = {
    ["bg"] = "bg",
    ["touchPanel"] = "touchPanel",
    ["item"] = "item",
    ["mapPanel"] = "mapPanel",
    ["mapPanel.npcPanel"] = "npcPanel",
    ["mapPanel.geziPanel"] = "geziPanel",

    ["center"] = "center",
    ["center.dice1"] = "dice1",
    ["center.dice1.btn"] = {
        varname = "btnDice1",
        binds = {
			event = "touch",
			methods = {ended = bindHelper.defer(function(view)
				return view:onDiceClick(1)
			end)}
		},
    },
    ["center.dice10"] = "dice10",
    ["center.dice10.btn"] = {
        varname = "btnDice10",
        binds = {
			event = "touch",
			methods = {ended = bindHelper.defer(function(view)
				return view:onDiceClick(5)
			end)}
		},
    },
	["center.skip"] = {
		varname = "btnSkip",
		binds = {
			event = "click",
			method = bindHelper.self("onSelectSkip")
		},
	},
	["center.cycle"] = "cycle",


    ["right"] = "right",
    ["right.btnTask"] = {
        varname = "btnTask",
        binds = {
            {
                event = "touch",
                methods = {
                    ended = bindHelper.self("onTaskClick")
                }
            },
            {
				event = "extend",
				class = "red_hint",
				props = {
					specialTag = "monopolyWalkTask",
					listenData = {
                        activityId = bindHelper.self("activityId"),
                    },
					-- onNode = function(node)
					-- 	node:xy(140, 150)
					-- end,
				},
			},
        }
    },
    ["right.btnExchange"] = {
        varname = "btnExchange",
        binds = {
            {
                event = "touch",
                methods = {
                    ended = bindHelper.self("onExchangeClick")
                }
            },
            {
				event = "extend",
				class = "red_hint",
				props = {
					specialTag = "redHintDaily",
					listenData = {
						sign = game.DAILY_REDHINT.monomolyEx
					},
					-- onNode = function(node)
					-- 	node:xy(140, 150)
					-- end,
				},
			},
        }
    },
    ["right.btnGift"] = {
        varname = "btnGift",
        binds = {
            {
                event = "touch",
                methods = {
                    ended = bindHelper.self("onGiftClick")
                }
            },
            {
				event = "extend",
				class = "red_hint",
				props = {
					specialTag = "redHintDaily",
					listenData = {
						sign = game.DAILY_REDHINT.monomolyGift
					},
					-- onNode = function(node)
					-- 	node:xy(140, 150)
					-- end,
				},
			},
        }
    },
	["itemAward"] = "itemAward",
    ["right.list"] = {
        varname = "awardList",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("boxAwards"),
				item = bindHelper.self("itemAward"),
				totalCycle = bindHelper.self("totalCycle"),
                margin = 10,
                paddings = { up = 0, down = 0, left = 0, right = 70 },
                dataOrderCmp = function(a, b)
					return a.csvId < b.csvId
				end,
				onItem = function(list, node, k, v)
                    
                    local childs = node:multiget("icon", "num", "click", "got", "count")
					local taskCfg = csv.yunying.grid_walk_tasks[v.csvId]
					childs.num:text(taskCfg.desc)
					text.addEffect(childs.num, {color = ui.COLORS.NORMAL.WHITE, outline = {color = ui.NEWCOLORS.OUTLINE.BLACK, size = 4}})
					text.addEffect(childs.count, {color = ui.COLORS.NORMAL.WHITE, outline = {color = ui.NEWCOLORS.OUTLINE.BLACK, size = 4}})

					idlereasy.any({list.totalCycle, v.state}, function(_, totalCycle, state)
						local isEffect = false
						if totalCycle >= v.taskParam then
							isEffect = true
						end

						local award = dataEasy.getItemData(v.award)
						local itemID, num = next(v.award)
						childs.count:text(mathEasy.getShortNumber(num))

						bind.extend(list, childs.icon, {
							class = "icon_key",
							props = {
								data = {key = itemID},
								simpleShow = true,
								grayState = state == 0 and 2 or 0,
								onNode = function(panel)
									panel:scale(1)
								end,
							}
						})

						childs.got:visible(false)
						if state == 0 then
							childs.got:visible(true)
						end
						
						childs.click:setTouchEnabled(false)
						node:removeChildByName("effect")
						if state == 1 and isEffect then
							childs.click:setTouchEnabled(state == 1)
							widget.addAnimationByKey(node, "effect/jiedianjiangli.skel", "effect", "effect_loop", 1)
                                    :xy(110, 130)
                                    :scale(0.5)

							
							bind.click(list, childs.click, { method = functools.partial(list.itemClick, v.csvId, v) })
						end
					end)
				end,
			},
			handlers = {
				itemClick = bindHelper.self("onBoxAwardClick"),
			},
		},
	},

    ["left"] = "left",
    ["left.timeBg"] = "timeBg",
    ["left.timeBg.timeLabel"] = {
		event = "effect",
		data = {outline = {color = ui.NEWCOLORS.OUTLINE.BLACK, size = 3}}
	},
    ["left.timeBg.time"] = {
		event = "effect",
		data = {outline = {color = ui.NEWCOLORS.OUTLINE.BLACK, size = 3}}
	},
	["showDicePanel"] = "showDicePanel",
}

function ActivityMonopolyWalkView:onCreate(activityId)
    self.activityId = activityId -- 活动ID号

    local yyCfg = csv.yunying.yyhuodong[activityId]
    gGameUI.topuiManager:createView("monopoly", self, { onClose = self:createHandler("onClose") })
		:init({ title = yyCfg.name, subTitle = "MONOPOLY" })

	local state = userDefault.getForeverLocalKey("monopolySkip", false)
	self.btnSkip:get("btn"):setSelectedState(state)
	
	self.huodongID = yyCfg.huodongID
	self:initModel()
    self:initMap()
	self:initNpc()
	self:initQuanWard()
	
	idlereasy.any({self.monopolyWalk}, function(_, monopolyWalk)
		local cycleNum = monopolyWalk.cycle
		self.totalCycle:set(monopolyWalk.cycle)

		self.cycle:get("txt"):text(cycleNum)
    end)

	idlereasy.any({self.yyhuodongs}, function(_, yyhuodongs)
		local yydata = yyhuodongs[self.activityId] or {}
		local boxSate = yydata.stamps or {}
		
		for k, v in self.boxAwards:pairs() do
            local state = boxSate[k] or 1
            self.boxAwards:atproxy(k).state:set(state or 1)
        end
	end)

    -- time
    local timeLabel = self.timeBg:get("timeLabel")
    local uiTime = self.timeBg:get("time")
	local countdown = self.endTime:read()[activityId] - time.getTime()
	self:setCountdown(countdown, uiTime)
end


function ActivityMonopolyWalkView:initModel()
	self.yyhuodongs = gGameModel.role:getIdler("yyhuodongs")
    self.endTime = gGameModel.role:getIdler("yy_endtime")
	
	self.monopolyWalk = gGameModel.role:getIdler("monopoly")

	self.totalCycle = idler.new(0)
    

    self.nowIndex = idler.new(self.monopolyWalk:read().pos)
	self.boxAwards = idlers.newWithMap({})

    self.npcNowState = NPC_STATE.stand
end

function ActivityMonopolyWalkView:createNpcSpine(node)
	node:removeChildByName("spine")
	local unitCsv = csv.unit[762]
	local npc = widget.addAnimationByKey(node, unitCsv.unitRes, "spine", "standby_loop", 1)
		:xy(node:width()/2, 70)
		:scale(0.6)
	return npc
end

function ActivityMonopolyWalkView:initNpc()
	self:createNpcSpine(self.npcPanel)
	local pos = self.mapDates[self.nowIndex:read()].pos
	self.npcPanel:xy(pos.x, pos.y)
end

function ActivityMonopolyWalkView:updateNpcState(state)
	if state == NPC_STATE.run then
		if self.npcNowState == NPC_STATE.stand then
			self.npcPanel:get("spine"):play("run_loop")
			self.npcNowState = NPC_STATE.run
		end
	elseif state == NPC_STATE.stand then
		if self.npcNowState == NPC_STATE.run then
			self.npcPanel:get("spine"):play("standby_loop")
			self.npcNowState = NPC_STATE.stand
		end
	end
end

function ActivityMonopolyWalkView:initMap()
	self.mapDates = {}
    for k, val in csvPairs(csv.yunying.grid_walk_map) do
		if val.huodongID == self.huodongID then
			self:createGezi(val.index,val)
		end
	end
end

function ActivityMonopolyWalkView:createGezi(index, mapCfg)
	local cloneItem = self.item
	local pos = mapCfg.pos
	
	local item = cloneItem:clone():show()
	local childs = item:multiget("start", "better", "normal", "icon", "num")
	itertools.invoke(childs, "hide")
	
	item:addTo(self.geziPanel, 1, "gezi"..mapCfg.index)
	item:xy(pos.x, pos.y)

	if index ==  1 then
		childs.start:show()
	elseif mapCfg.awards then
		local itemID, num = next(mapCfg.awards)
		if mapCfg.texiao[1] == 1 then
			childs.better:show()
		else
			childs.normal:show()
		end
		childs.num:text(mathEasy.getShortNumber(num))
		text.addEffect(childs.num, {color = ui.COLORS.NORMAL.WHITE, outline = {color = ui.NEWCOLORS.OUTLINE.BLACK, size = 4}})
		childs.num:show()
		childs.icon:show()
		bind.extend(self, childs.icon, {
			class = "icon_key",
			props = {
				data = {key = itemID, num = 0},
				simpleShow = true,
				onNode = function(panel)
					panel:scale(0.7)
				end,
			},
		})
	end

	self.mapDates[mapCfg.index] = {
		item = item,
		index = mapCfg.index,
		pos = pos,
	}

	return item
end

function ActivityMonopolyWalkView:npcMove(index, cb)
	self:updateNpcState(NPC_STATE.run)
	local endPos = self.mapDates[index].pos

	local nowX = self.npcPanel:x()
	local nowY = self.npcPanel:y()
	local scale = endPos.x - nowX > 0 and 0.6 or nil
	scale = endPos.x - nowX < 0 and -0.6 or scale
	if scale then
		self.npcPanel:get("spine"):scaleX(scale)
	end
	
	self.npcPanel:runAction(cc.Sequence:create(
		cc.MoveTo:create(MOVE_TIME, cc.p(endPos.x, endPos.y)),
		cc.CallFunc:create(function()
			-- local endScale = 1.2 
			-- if scale ~= endScale then
			-- 	self.npcPanel:get("spine"):scaleX(endScale)
			-- end
			
			if cb then
				cb()
			end
		end))
	)
end

function ActivityMonopolyWalkView:setCountdown(countdown, node)
	self:enableSchedule():unSchedule(1)
	countdown = math.max(countdown, 0)
	if countdown == 0 then
		self.timeEnd = true
		node:text(gLanguageCsv.activityOver)
		return
	end
	self.timeEnd = false
	bind.extend(self, node, {
		class = 'cutdown_label',
		props = {
			time = countdown,
			tag = 1,
			strFunc = function(t)
				return t.str
			end,
			endFunc = function()
				countdown = self.endTime:read()[self.activityId] - time.getTime()
				performWithDelay(self, function()
					self:setCountdown(countdown, node)
				end, 1)
			end
		}
	})
end

function ActivityMonopolyWalkView:initQuanWard()
    local awards = {}
    for k, v in orderCsvPairs(csv.yunying.grid_walk_tasks) do
        if v.huodongID == self.huodongID and v.taskType == 0 then
            awards[k] = {
                csvId = k,
                state = idler.new(1),
                award = v.award,
                taskParam = v.taskParam,
            }
        end
    end

    self.boxAwards:update(awards)
end

function ActivityMonopolyWalkView:onGiftClick()
    -- 礼包
    local activityId = dataEasy.getActivityIdInYYOPEN(YY_TYPE.directBuyGift, game.DIRECT_GIFT.MONOPOLY_GIFT)
    if activityId then
        gGameUI:stackUI("city.activity.monopoly.gift", nil, {blackLayer = true}, activityId)
    end
end

function ActivityMonopolyWalkView:onTaskClick()
    -- 任务
    gGameUI:stackUI("city.activity.monopoly.task", nil, nil, self.activityId)
end

function ActivityMonopolyWalkView:onExchangeClick()
    -- 兑换
    local activityId = dataEasy.getActivityIdInYYOPEN(YY_TYPE.itemExchange, game.EXCHANGE_IND.IDX_MONOPOLY)
    if activityId then
        gGameUI:stackUI("city.activity.monopoly.exchange", nil, {blackLayer = true}, activityId)
    end
end

function ActivityMonopolyWalkView:isEnoughToDraw(isTen)
	local myNum = dataEasy.getNumByKey(game.ITEM_TICKET.lotterySkinItem)

    if isTen then
		return myNum >= 10
	else
		return myNum >= 1
	end
end


function ActivityMonopolyWalkView:onDiceClick(num)
	local myNum = dataEasy.getNumByKey(MONOPOLY_Dice)
	
    if myNum < num then
        gGameUI:showTip(gLanguageCsv.gridWalkNoDice)
    else
        self:sendItemuse(MONOPOLY_Dice, num)
    end
end

--
function ActivityMonopolyWalkView:updateSteps(cb)
	
	self.touchPanel:show()
	local action = self.monopolyWalk:read().action
	local function step1()
		if self.leftStepsNum == 0 then
			self:updateNpcState(NPC_STATE.stand)
			self.touchPanel:hide()
			cb()
			return
		end
		local nowIndex = self.nowIndex:read()
		
		nowIndex = nowIndex + 1
		if nowIndex > 30 then nowIndex = 1 end

		self.nowIndex:set(nowIndex)
		self.leftStepsNum = self.leftStepsNum - 1
		
		self:npcMove(nowIndex, step1)
	end
	self.leftStepsNum = action.die_rolled
    local function showDices()
		self.showDicePanel:show()
		
		local step = self.showDicePanel:get("step")
		step:text(self.leftStepsNum)
		adapt.oneLinePos(self.showDicePanel:get("txt1"), {step, self.showDicePanel:get("txt2")}, cc.p(10, 0))
		performWithDelay(self, function()
			self.showDicePanel:hide()
			step1()
		end, 2)
	end
	self:createDiceSpine(action.die_used, action.die_rolled, showDices)
	
end

function ActivityMonopolyWalkView:createDiceSpine(id, index, cb)
	if index > 6 then
		cb()
		return
	end
	local effectName = "effect_2_"..index
	local effect = widget.addAnimationByKey(self, "gridwalk/touzi.skel", "dice", effectName, 99)
	effect:scale(1.8)
	effect:xy(self.mapPanel:width()/2, self.mapPanel:height()/2)
	effect:setSpriteEventHandler(function(event, eventArgs)
		performWithDelay(self, function()
			cb()
			effect:removeSelf()
		end, 0)
	end, sp.EventType.ANIMATION_COMPLETE)
end

-- 使用骰子
function ActivityMonopolyWalkView:sendItemuse(itemID, count)
	if self.timeEnd then
		gGameUI:showTip(gLanguageCsv.activityOver)
		return
	end

	gGameApp:requestServer("/game/yy/monopoly/itemuse", function(tb)
		local view = tb.view
		local state = userDefault.getForeverLocalKey("monopolySkip", false)
		if state then
			display.director:getScheduler():setTimeScale(MOVE_SPEED)
		end
		print("=== monopoly itemuse view ===")
		dump(view)
		self:updateSteps(function()
			display.director:getScheduler():setTimeScale(1)
			gGameUI:showGainDisplay(tb)
		end)
	end, self.activityId, itemID , count)
end

-- 宝箱领取
function ActivityMonopolyWalkView:onBoxAwardClick(_, id, v)
    local yyId = self.activityId
    local boxState = self.boxAwards:atproxy(id).state

    if self.totalCycle:read() < v.taskParam then
        -- 次数不足
        gGameUI:showBoxDetail({
            data = csv.yunying.grid_walk_tasks[id].award,
            content = string.format(gLanguageCsv.accumulatedAward, csv.yunying.grid_walk_tasks[id].taskParam),
            state = 1,
        })
        return
    end

	if boxState and boxState:read() == 1 then
		gGameApp:requestServer("/game/yy/award/get", function(cb)
			gGameUI:showGainDisplay(csv.yunying.grid_walk_tasks[id].award, {
				raw = false,
				cb = function()
					-- self.downPanel:get("item" .. (idx + 1)):get("result"):visible(false)
					-- self:initAward()
				end
			})
		end, yyId, id)
	end
end

-- 显示规则文本
function ActivityMonopolyWalkView:onShowRule()
	gGameUI:stackUI("common.rule", nil, nil, self:createHandler("getRuleContext"))
end

function ActivityMonopolyWalkView:getRuleContext(view)
	local c = adaptContext
	local context = {
		c.clone(view.title, function(item)
			item:get("text"):text(gLanguageCsv.themeskinrule)
		end),
		c.noteText(129236, 129240),
	}
	return context
end

-- 跳过
function ActivityMonopolyWalkView:onSelectSkip()
	local state = userDefault.getForeverLocalKey("monopolySkip", false)
	self.btnSkip:get("btn"):setSelectedState(not state)
	userDefault.setForeverLocalKey("monopolySkip", not state)
end

function ActivityMonopolyWalkView:onClose()
	display.director:getScheduler():setTimeScale(1)
	ViewBase.onClose(self)
end
return ActivityMonopolyWalkView