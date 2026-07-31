
-- 主题英雄

local YY_TYPE = game.YYHUODONG_TYPE_ENUM_TABLE

local MOVE_TIME = 0.6
local MOVE_SPEED = 3
local SPINE_SCALE = 1.2

-- npc人物状态
local NPC_STATE = {
	stand = "stand",
	run = "run",
}

local THEME_PATH = "activity/throne_draw"
local THEME_UI_DATA = {
    {"bg", "bg.jpg"},
    {"center.item.left.bg", "img_taizi.png"},
    {"center.item.left.lu", "img_lu.png"},
    {"center.item.left.box", "img_box.png"},
    {"center.item.right.bg", "img_taizi.png"},
    {"center.item.right.lu", "img_lu.png"},
    {"center.item.right.box", "img_box.png"},
}

local function createNpcSpine(node)
	node:removeChildByName("spine")
    local unitCsv = csv.unit[762]
	local spineRes = unitCsv.unitRes
	local npc = widget.addAnimationByKey(node, spineRes, "spine", "standby_loop", 1)
		:xy(node:width()/2, 0)
		:scale(SPINE_SCALE)
	return npc
end

local function UpdateRankItem(node, rank, name, count, serverKey)
    local childs = node:multiget("rank", "name", "num")
    childs.num:text(count)

    local serverKey = string.format(gLanguageCsv.brackets, getServerArea(serverKey, true))
    local str = serverKey .. name

    adapt.setTextScaleWithWidth(childs.name, str, 300)
    if rank == 0 then
        childs.rank:get("icon"):hide()
        childs.rank:get("txt"):text(gLanguageCsv.noRank)
    else
        if rank <= 3 then
            childs.rank:get("icon"):show()
            childs.rank:get("icon"):texture("activity/throne_draw/jitai_icon" .. rank ..".png")
            childs.rank:get("txt"):hide()
        else
            childs.rank:get("icon"):hide()
            childs.rank:get("txt"):show()
            childs.rank:get("txt"):text(rank)
        end
    end
end

local ActivityThroneDrawView = class("ActivityThroneDrawView", cc.load("mvc").ViewBase)

ActivityThroneDrawView.RESOURCE_FILENAME = "activity_throne.json"
ActivityThroneDrawView.RESOURCE_BINDING = {
    ["bg"] = "bg",
    ["touchPanel"] = "touchPanel",
    -- left
    ["left"] = "left",
    ["left.timeBg"] = "timeBg",
    ["left.down.btnExchange"] = {
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
						sign = game.DAILY_REDHINT.throneExchange
					},
					-- onNode = function(node)
					-- 	node:xy(140, 150)
					-- end,
				},
			},
        }
    },
    ["left.down.btnSignin"] = {
        varname = "btnSignin",
        binds = {
            {
                event = "touch",
                methods = {
                    ended = bindHelper.self("onSigninClick")
                }
            },
            {
				event = "extend",
				class = "red_hint",
				props = {
					specialTag = "activityThroneSignIn",
					onNode = function(node)
						-- node:xy(170, 170)
					end,
				},
			},
        }
    },
    ["left.down.btnPassport"] = {
        varname = "btnPassport",
        binds = {
            {
                event = "touch",
                methods = {
                    ended = bindHelper.self("onPassportClick")
                }
            },
            {
				event = "extend",
				class = "red_hint",
				props = {
					specialTag = "playPassportThrone",
					onNode = function(node)
						-- node:xy(170, 170)
					end,
				},
			},
        }
    },
    
    ["left.down.btnShop"] = {
        varname = "btnShop",
        binds = {
            {
                event = "touch",
                methods = {
                    ended = bindHelper.self("onShopClick")
                }
            },
            {
				event = "extend",
				class = "red_hint",
				props = {
					specialTag = "redHintDaily",
					listenData = {
						sign = game.DAILY_REDHINT.throneShop
					},
					-- onNode = function(node)
					-- 	node:xy(140, 150)
					-- end,
				},
			},
        }
    },
    
    ["left.btnRule"] = {
        varname = "btnRule",
        binds = {
            event = "touch",
            methods = {
                ended = bindHelper.self("onShowRule")
            }
        }
    },
    ["left.rank.myRank"] = "itemRank",
    ["left.rank.list"] = {
        varname = "rankList",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("showRankData"),
				item = bindHelper.self("itemRank"),
				scrollState = bindHelper.self("scrollState"),
				itemAction = { isAction = true },
				onBeforeBuild = function(list)
					list.scrollState:set(false)
				end,
				onAfterBuild = function(list)
					list.scrollState:set(true)
				end,
				onItem = function(list, node, k, v)
					local children = node:multiget("bg", "rank", "name", "num")
                    children.bg:visible(k % 2 == 0)

                    UpdateRankItem(node, v.rank, v.name, v.total_times, v.server_key)
                    -- adapt.setTextScaleWithWidth(children.name, "", 300)
				end,
			},
		},
    },
    ["left.rank.textBg"] = "textTip",
    ["left.rank.btnRefresh"] = {
        binds = {
			event = "touch",
            clicksafe = true,
			methods = { ended = bindHelper.self("updateRank") }
		},
    },
    
    -- center
    ["center"] = "center",
    ["center.item"] = "item",
    ["center.list"] = "throneList",
    
   
    -- right
    ["right.down.draw1"] = "draw1",
    ["right.down.draw1.btn"] = {
        binds = {
			event = "touch",
			methods = {ended = bindHelper.defer(function(view)
				return view:onDrawClick(1)
			end)}
		},
    },
    ["right.down.draw10"] = "draw10",
    ["right.down.draw10.btn"] = {
        binds = {
            event = "touch",
            methods = {ended = bindHelper.defer(function(view)
				return view:onDrawClick(10)
			end)}
        }
    },
    ["right.skip"] = {
		varname = "btnSkip",
		binds = {
			event = "click",
			method = bindHelper.self("onSelectSkip")
		},
	},
    ["right.skip.txt"] = {
		binds = {
			event = "effect",
			data = { outline = { color = ui.NEWCOLORS.OUTLINE.BLACK, size = 4 } },
		},
	},
    ["right.rankAward"] = {
        varname = "rankAward",
        binds = {
            event = "touch",
            methods = {
                ended = bindHelper.self("onShowRank")
            }
        }
    },
    ["right.rankAward.list"] = "rankAwardList",

}


function ActivityThroneDrawView:onCreate(activityId)
    self.activityId = activityId -- 活动ID号

    local yyCfg = csv.yunying.yyhuodong[activityId]
    gGameUI.topuiManager:createView("throne", self, { onClose = self:createHandler("onClose") })
		:init({ title = yyCfg.name, subTitle = "THRONE" })

	self:initModel()
    uiEasy.replaceTheme(self, activityId, THEME_PATH, THEME_UI_DATA)

	self:initRankAward(yyCfg)

    self.boxItemID = yyCfg.paramMap.boxid

    self.isFirst = false
    idlereasy.any({self.yyhuodongs}, function(_,yyhuodongs)
		local yydata = yyhuodongs[activityId] or {}
		local info = yydata.info or {}
        local total_times = info.total_times or 0
        if not self.isFirst then
            self.isFirst = true
            self.nowIndex:set(total_times)
            self:updateData()
        end
        self:updateMyRank(total_times, gGameApp.serverInfo.key)
    end)

    local state = userDefault.getForeverLocalKey("throneSkip", false)
	self.btnSkip:get("btn"):setSelectedState(state)

    self:resetTimeLabel()
  
    self:updateRank()

    self.richText = rich.createWithWidth(gLanguageCsv.throneRule, 38, nil, 600)
    self.richText:addTo(self.textTip)
        :anchorPoint(0, 0.5)
        :xy(100, self.textTip:size().height / 2)
end

function ActivityThroneDrawView:initModel()
	self.yyhuodongs = gGameModel.role:getIdler("yyhuodongs")
    self.nowIndex = idler.new(0)

    self.npcNowState = NPC_STATE.stand
    self.scrollState = idler.new(true)
    self.showRankData = idlers.newWithMap({})

    self.myRank = 0
end


-- 重置剩余时间等
-- @params showDay 是否显示天数 1 显示 2 不显示：天数转化成小时显示
function ActivityThroneDrawView:resetTimeLabel()
	local activityId = self.activityId
	-- 没有 text 表示在页面内显示
	-- cn 活动结束时间是 周一5点； kr 活动结束时间点会出现 周日 23:59:59
	-- 抽卡结束时间活动开始的第三天的21:30
	local yyCfg = csv.yunying.yyhuodong[activityId]
	local getHuodongEndTime = time.getNumTimestamp(yyCfg.beginDate, 21, 30) + 6 * 24 * 60 * 60
	self.getHuodongEndTime = getHuodongEndTime

	local timeT = getHuodongEndTime - time.getTime()
    local timeLabel = self.timeBg:get("timeLabel")
    local uiTime = self.timeBg:get("time")
    text.addEffect(uiTime, { outline = { color = ui.NEWCOLORS.OUTLINE.BLACK, size = 3 } })
    text.addEffect(timeLabel, { outline = { color = ui.NEWCOLORS.OUTLINE.BLACK, size = 3 } })

	local showDay = 1 -- 默认显示天数
	local function setLabel()
		timeT = getHuodongEndTime - time.getTime()
		if timeT <= 0 then
			uiTime:text(gLanguageCsv.activityOver)
			adapt.oneLineCenterPos(cc.p(240, 30), {timeLabel, uiTime }, cc.p(10, 0))
			return false
		end
		local str = ""
		if showDay == 2 then
			str = time.getCutDown(timeT).clock_str
		else
			str = time.getCutDown(timeT).str
		end
		uiTime:text(str)
		adapt.oneLineCenterPos(cc.p(240, 30), {timeLabel, uiTime }, cc.p(10, 0))
		return true
	end

	setLabel()
	if timeT > 0 then
		local scheduleTag = activityId -- 定时器tag
		-- 移除上次的刷新定时器
		self:enableSchedule():unSchedule(scheduleTag)
		self:schedule(function()
			if not setLabel() then
				-- 活动结束时获得最新数据刷新界面
				self:updateRank()
				return false
			end
		end, 1, 1, scheduleTag) -- 1秒钟刷新一次
	end
end

function ActivityThroneDrawView:updateRank()
    if self.repetitionClick then
        return
    end
    self.repetitionClick = true

    gGameApp:requestServer("/game/yy/throne/ranking", function(tb)
        self.servers = tb.view.servers or {}
        local rankInfos = tb.view.rankInfos
        if rankInfos then
            self:updateRankInfo(rankInfos)
            self.repetitionClick = false
        end
        local myinfo = tb.view.myinfo
        if myinfo then
            self.myRank = myinfo.rank
            self:updateMyRank(myinfo.total_times, myinfo.server_key)
        end
	end, self.activityId)
end

-- 更新排行榜
function ActivityThroneDrawView:updateRankInfo(rankInfos)
    local rankData = {}
    for k, v in ipairs(rankInfos) do
        table.insert(rankData, {
            rank = v.rank,
            name = v.name,
            total_times = v.total_times,
            server_key = v.server_key
        }) 
        
    end
    self.showRankData:update(rankData)
end

-- 排行奖励 第一名
function ActivityThroneDrawView:initRankAward(yyCfg)
    local huodongID = yyCfg.huodongID
	for id, cfg in csvPairs(csv.yunying.limitboxrankaward) do
		if cfg.huodongID == huodongID and cfg.rank == 1 then
            uiEasy.createItemsToList(self, self.rankAwardList, cfg.award, {margin = 6, scale = 0.7, onAfterBuild = function()
                self.rankAwardList:setItemAlignCenter()
            end})
			break
		end
	end
end

function ActivityThroneDrawView:updateData()
    local startId = self.nowIndex:read()
    
    self.throneDatas = {}
    self.throneList:removeAllChildren()

    for i = 20, 1, -1 do
        local id = startId + i - 1
        self:createStep(i, id, i == 1)
    end

    -- self.throneList:refreshView()
    -- self.throneList:setShowCenterIndex(2)
    -- self.throneList:jumpToTop()
    self.throneList:jumpToBottom()
    self.throneList:setScrollBarEnabled(false)
    -- self.throneList:setCurSelectedIndex(20)
    
end

function ActivityThroneDrawView:createStep(idx, id, isCurr)
    local item = self.item:clone():show()
	self.throneList:pushBackCustomItem(item)

    local childs = item:multiget("left", "right")
    itertools.invoke({childs.left, childs.right}, "hide")
    local panel, x
    if 1 == id%2 then
        panel = childs.left:show()
        x = 700 - 385
    else
        panel = childs.right:show()
        x = 700 + 385
    end
    panel:get("num"):text(id)
    local boxItem = panel:get("box")

    local spinePos = item:get("pos")
    spinePos:x(x)
    if isCurr then
        createNpcSpine(spinePos)
        self.curPanel = item
        self.npcPanel = spinePos
    end
    bind.click(self, boxItem, {method = function()
        local params = {key = self.boxItemID}
        gGameUI:showItemDetail(boxItem, params)
    end})
    -- local x, y = spinePos:xy()
    -- local pos = self:convertToWorldSpace(cc.p(x,y))
    -- pos = self.left:convertToNodeSpace(pos)

    self.throneDatas[idx] = {
        id = id,
        item = item,
        pos = {
           x = x,
           y = 120 
        }
    }
end

function ActivityThroneDrawView:updateNpcState(state)
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

function ActivityThroneDrawView:npcMove(index, cb)
	self:updateNpcState(NPC_STATE.run)
	local item = self.throneDatas[index].item
	local pos = self.throneDatas[index].pos
    local pos = item:convertToWorldSpace(cc.p(pos.x, pos.y))
    -- printInfo("x: %d y: %d", pos.x, pos.y)
    local endPos = self.curPanel:convertToNodeSpace(pos)
    -- printInfo("e x: %d y: %d", endPos.x, endPos.y)
    -- local endPos = {x = 358, y = 500 + 100}
    
	local nowX = self.npcPanel:x()
	local nowY = self.npcPanel:y()
	local scale = endPos.x - nowX > 0 and 1.5 or nil
	scale = endPos.x - nowX < 0 and -1.5 or scale
	if scale then
		self.npcPanel:get("spine"):scaleX(scale)
	end
	
	self.npcPanel:runAction(cc.Sequence:create(
		cc.MoveTo:create(MOVE_TIME, cc.p(endPos.x, endPos.y)),
		cc.CallFunc:create(function()
			local endScale = SPINE_SCALE
			if scale ~= endScale then
				self.npcPanel:get("spine"):scaleX(endScale)
			end
            
			if cb then
				cb()
			end
		end)))
	-- self:onUpdateListPercentVertical(index)
end


function ActivityThroneDrawView:updateSteps(moveStep, callBack)
	self.touchPanel:show()
	
    local toIdx = 1
	local function step1()
		if self.leftStepsNum == 0 then
			self:updateNpcState(NPC_STATE.stand)
			self.touchPanel:hide()
            callBack()
			return
		end
		local nowIndex = self.nowIndex:read()
		nowIndex = nowIndex + 1
		self.nowIndex:set(nowIndex)
		self.leftStepsNum = self.leftStepsNum - 1
		
        toIdx = toIdx + 1
		self:npcMove(toIdx, step1)
	end

	self.leftStepsNum = moveStep
    self:onUpdateListPercentVertical(moveStep)
    step1()
	
end

function ActivityThroneDrawView:onUpdateListPercentVertical(index, isJump)
    local percents = {
        [1] = 6,
        [10] = 60,
    }
    -- local percent = math.max(math.min(index/18 * 100, 100), 0)
    local percent = percents[index]
    self.throneList:scrollToPercentVertical(100 - percent, MOVE_TIME*index + 0.5, false)
	-- local endPosY = self.mapDates[index].pos[2]
	-- local height = 1440
	-- local percent = (math.max(height + 600 - endPosY, 0)) / height*100
	-- local percent = math.max(math.min(percent, 100), 0)
	-- if isJump then
	-- 	self.throneList:jumpToPercentVertical(percent)
	-- else
	-- 	self.throneList:scrollToPercentVertical(percent, MOVE_TIME, false)
	-- end
end

function ActivityThroneDrawView:updateMyRank(count, serverKey)
    UpdateRankItem(self.itemRank, self.myRank, gGameModel.role:read("name"), count, serverKey)
end

function ActivityThroneDrawView:isEnoughToDraw(isTen)

	local myNum = dataEasy.getNumByKey(game.ITEM_TICKET.throneDrawItem)

    if isTen then
		return myNum >= 10
	else
		return myNum >= 1
	end
end

function ActivityThroneDrawView:onDrawClick(num)
    -- 单抽
    local onceEnough = self:isEnoughToDraw(num == 10)
    if not onceEnough then
        gGameUI:showTip(gLanguageCsv.drawItemNotEnough)
        return
    end
 
    gGameApp:requestServer("/game/yy/throne/itemuse", function(tb)
        local view = tb.view
		local state = userDefault.getForeverLocalKey("throneSkip", false)
		if state then
			display.director:getScheduler():setTimeScale(MOVE_SPEED)
		end
		self:updateSteps(num, function()
			display.director:getScheduler():setTimeScale(1)
            self:updateData()
			gGameUI:showGainDisplay(tb)
		end)

        self:updateRank()
    end, self.activityId, game.ITEM_TICKET.throneDrawItem, num)
end

-- 战令
function ActivityThroneDrawView:onPassportClick()
    local activityId = dataEasy.getActivityIdInYYOPEN(YY_TYPE.playPassport, game.PASSPORT_IDX.T_THRONE_DRAW)
    if activityId then
        gGameUI:stackUI("city.activity.throne_draw.passport", nil, {full = true}, activityId)
    end
end

function ActivityThroneDrawView:onShopClick()
     -- 商店
     local activityId = dataEasy.getActivityIdInYYOPEN(YY_TYPE.directBuyGift, game.DIRECT_GIFT.THRONE_DRAW)
     if activityId then
         gGameUI:stackUI("city.activity.throne_draw.shop", nil, {blackLayer = true}, activityId)
     end
   
end

function ActivityThroneDrawView:onExchangeClick()
    -- 兑换
    local activityId = dataEasy.getActivityIdInYYOPEN(YY_TYPE.itemExchange, game.EXCHANGE_IND.THRONE_DRAW)
    if activityId then
        gGameUI:stackUI("city.activity.throne_draw.exchange", nil, {blackLayer = true}, activityId)
    end
end

function ActivityThroneDrawView:onSigninClick()
    -- 签到
    local activityId = dataEasy.getActivityIdInYYOPEN(YY_TYPE.LoginGift, game.SIGNIN_TYPE.T_THRONE_DRAW)
    if activityId then
        gGameUI:stackUI("city.activity.throne_draw.sign_in", nil, {blackLayer = true}, activityId)
    end
end

function ActivityThroneDrawView:onShowRank()
    -- 排行榜
    gGameUI:stackUI("city.activity.throne_draw.rank", nil, nil, self.activityId)
end

-- 显示规则文本
function ActivityThroneDrawView:onShowRule()
	gGameUI:stackUI("common.rule", nil, nil, self:createHandler("getRuleContext"))
end

-- 跳过
function ActivityThroneDrawView:onSelectSkip()
	local state = userDefault.getForeverLocalKey("throneSkip", false)
	self.btnSkip:get("btn"):setSelectedState(not state)
	userDefault.setForeverLocalKey("throneSkip", not state)
end

function ActivityThroneDrawView:getRuleContext(view)
	local c = adaptContext
	local context = {
		c.clone(view.title, function(item)
			item:get("text"):text(gLanguageCsv.themeherorule)
		end),
		c.noteText(129291, 129294),
	}
    if self.servers then
        local t = arraytools.map(getMergeServers(self.servers), function(k, v)
            return string.format(gLanguageCsv.brackets, getServerArea(v, nil, true))
        end)
        table.insert(context, 2, "#C0xFFFFFF#" .. gLanguageCsv.currentServers .. table.concat(t, ","))
    end

	return context
end

return ActivityThroneDrawView