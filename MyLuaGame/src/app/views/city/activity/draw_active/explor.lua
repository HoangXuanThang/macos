local YY_TYPE = game.YYHUODONG_TYPE_ENUM_TABLE


local Activity = require "app.views.city.activity.view"

local ActivityDrawLimitExplorView = class("ActivityDrawLimitExplorView", cc.load("mvc").ViewBase)

ActivityDrawLimitExplorView.RESOURCE_FILENAME = "activity_draw_active_explor.json"
ActivityDrawLimitExplorView.RESOURCE_BINDING = {
    ["left.btnTask"] = {
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
					specialTag = "activityGeneralTask",
					listenData = {
						activityId = bindHelper.self("activityTaskId"),
					},
					onNode = function(node)
						node:xy(140, 150)
					end,
				}
			}
        }
    },
    ["left.btnShop"] = {
        varname = "btnShop",
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
                        sign = game.DAILY_REDHINT.drawExplorGift,
                    },
                    onNode = function(node)
                        node:xy(140, 150)
                    end,
                },
            },
        }
    },
   
    ["left.btnExchange"] = {
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
                        sign = game.DAILY_REDHINT.drawExplorEx,
                    },
                    onNode = function(node)
                        node:xy(140, 150)
                    end,
                },
            },
        }
    },

    ["right.btnRule"] = {
        binds = {
            event = "touch",
            methods = { ended = bindHelper.self("onShowRule") }
        },
    },
    ["right.btnPreview"] = {
        binds = {
            event = "touch",
            methods = { ended = bindHelper.self("onAwardClick") }
        },
    },
    ["right.time"] = "time",

    --
    ["draw1"] = "draw1",
    ["draw1.costBg"] = "costBg",
    ["draw1.freeBg"] = "freeBg",
    ["draw1.btn"] = {
        varname = "btnDraw1",
        binds = {
            event = "touch",
            methods = {
                ended = bindHelper.self("onDrawOneClick")
            }
        }
    },
    ["draw10"] = "draw10",
    ["draw10.btn"] = {
        varname = "btnDraw10",
        binds = {
            event = "touch",
            methods = {
                ended = bindHelper.self("onDrawTenClick")
            }
        }
    },

    ["name"] = "name",
    ["center"] = "center",
    ["center.countTip"] = "countTip",
    ["center.countTip.num"] = {
        binds = {
            event = "extend",
            class = "text_atlas",
            props = {
                data = bindHelper.self("myDrawNum"),
                align = "right",
                pathName = "zhtpf_num",
                isEqualDist = false,
                onNode = function(panel)
                    panel:xy(100, 40)
                end,
            }
        }
    },

    ["center.item"] = "item"

}

function ActivityDrawLimitExplorView:onCreate(activityId)
    local yyCfg = csv.yunying.yyhuodong[activityId]
    gGameUI.topuiManager:createView("draw_explor", self, { onClose = self:createHandler("onClose") })
        :init({ title = yyCfg.name, subTitle = "DRAW EXPLOR" })

    self.activityId = activityId
    self.activityTaskId = dataEasy.getActivityIdInYYOPEN(YY_TYPE.drawLimitTask, game.GENERAL_TASK_IND.DRAW_EXPLOR)
    self:initModel()

    self:initInfoData(yyCfg.clientParam, yyCfg.paramMap)

    idlereasy.any({ self.yyhuodongs }, function(_, yyhuodongs)
        local yydata = yyhuodongs[activityId] or {}
        local info = yydata.info or {}
        local freeCount = info.free_counter or 0
        local limit_count = info.limit_counter_1 or 0
        local num = math.max(csv.yunying.yyhuodong[activityId].paramMap.number - limit_count, 0)
        self.myDrawNum:set(num)
        self.freeCount:set(1 - freeCount)
        self:updateDrawItem()
    end)

    idlereasy.any({ self.rmb, self.items, self.freeCount}, self:createHandler("updateDrawItem"))

    -- local uiIcon = self.time:get("icon")
    local uiTime = self.time:get("time")
    Activity.setCountdown(self, activityId, nil, uiTime, {
        labelChangeCb = function()
            -- adapt.oneLineCenterPos(cc.p(180, 30), { uiIcon, uiTime }, cc.p(20, 0))
        end,
        tag = "activity_explor_view" .. activityId
    })
end

function ActivityDrawLimitExplorView:initModel()
    self.yyOpen = gGameModel.role:read("yy_open")
    self.yyhuodongs = gGameModel.role:getIdler("yyhuodongs")

    self.rmb = gGameModel.role:getIdler("rmb")
	self.items = gGameModel.role:getIdler("items")

    self.freeCount = idler.new(0)
    self.myDrawNum = idler.new(0)
    self.cost = {}

end

function ActivityDrawLimitExplorView:updateDrawItem()
    local isFree = self.freeCount:read() > 0
    local myNum = dataEasy.getNumByKey(game.ITEM_TICKET.drawLimitExpItem)
    itertools.invoke({self.freeBg, self.costBg}, "hide")
    if isFree then
        self.freeBg:show()
    else
        self.costBg:show()
    end

    -- local onePath = "common/icon/icon_diamond.png"
    -- local costOnece = self.cost[1]

    -- local tenPath = "common/icon/icon_diamond.png"
	-- local costTen = self.cost[2]
    -- if not isFree and myNum > 0 then
	-- 	onePath = dataEasy.getIconResByKey(game.ITEM_TICKET.drawLimitExpItem)
	-- 	costOnece = string.format("%s/%s", myNum, 1)
	-- end
	-- if myNum >= 10 then
	-- 	tenPath = dataEasy.getIconResByKey(game.ITEM_TICKET.drawLimitExpItem)
	-- 	costTen = string.format("%s/%s", myNum, 10)
	-- end

    -- Mặc định: dùng vé, không dùng RMB
    local onePath = dataEasy.getIconResByKey(game.ITEM_TICKET.drawLimitExpItem)
    local costOnece = string.format("%s/%s", myNum, 1)

    local tenPath = dataEasy.getIconResByKey(game.ITEM_TICKET.drawLimitExpItem)
    local costTen = string.format("%s/%s", myNum, 10)

    -- Nếu free thì hiện "Miễn phí"
    if isFree then
        costOnece = gLanguageCsv.free
    end


    self.draw1:get("costBg.icon"):texture(onePath)
    self.draw1:get("costBg.num"):text(costOnece)
    self.draw10:get("costBg.icon"):texture(tenPath)
    self.draw10:get("costBg.num"):text(costTen)
end

-- 消耗
function ActivityDrawLimitExplorView:initInfoData(clientParam, paramMap)
    self.cost[1] = paramMap.rmb1
    self.cost[2] = paramMap.rmb10

    local expCsv = csv.explorer.explorer[clientParam.explorerID]
    if not expCsv then
        return
    end
    self.name:get("txt"):text(expCsv.name)

    widget.addAnimationByKey(self.item, expCsv.res, "spine", "default", 1, true):scale(2.5)
end

function ActivityDrawLimitExplorView:onTaskClick()
    -- 任务
    local activityId = dataEasy.getActivityIdInYYOPEN(YY_TYPE.drawLimitTask, game.GENERAL_TASK_IND.DRAW_EXPLOR)
    if activityId then
        gGameUI:stackUI("city.activity.draw_active.task", nil, { blackLayer = true }, activityId)
    end
end

function ActivityDrawLimitExplorView:onGiftClick()
    -- 礼包
    local activityId = dataEasy.getActivityIdInYYOPEN(YY_TYPE.directBuyGift, game.DIRECT_GIFT.DRAW_EXPLOR)
    if activityId then
        gGameUI:stackUI("city.activity.draw_active.gift", nil, { blackLayer = true }, activityId, YY_TYPE.drawLimitExplor)
    end
end

function ActivityDrawLimitExplorView:onExchangeClick()
    -- 兑换
    local activityId = dataEasy.getActivityIdInYYOPEN(YY_TYPE.itemExchange, game.EXCHANGE_IND.DRAW_EXPLOR)
    if activityId then
        gGameUI:stackUI("city.activity.draw_active.exchange", nil, { blackLayer = true }, activityId, YY_TYPE.drawLimitExplor)
    end
end

function ActivityDrawLimitExplorView:isEnoughToDraw(isTen)
    local myNum = dataEasy.getNumByKey(game.ITEM_TICKET.drawLimitExpItem)

    if isTen then
        return myNum >= 10
    else
        return myNum >= 1
    end
end

function ActivityDrawLimitExplorView:onDrawOneClick()
    -- 单抽
    local isFree = self.freeCount:read() > 0
    local myNum = dataEasy.getNumByKey(game.ITEM_TICKET.drawLimitExpItem)

    if not isFree and myNum <= 0 then
        gGameUI:showTip(gLanguageCsv.drawItemNotEnough)
        return
    end

    local function requesetServer()
        local yyId = self.activityId
        gGameApp:requestServer("/game/lottery/yy/draw", function(tb)
            audio.pauseMusic()
            audio.playEffectWithWeekBGM("drawcard_one.mp3")
            local ret, spe, isFull, _, extra = dataEasy.getRawTable(tb)
            local items = dataEasy.getItems(ret, spe)
            local params = {
                items = items,
                extra = extra,
                drawType = "active_explor",
                times = 1,
                yyId = yyId,
                cb = function(tb)
                end,
            }

            gGameUI:stackUI("city.drawcard.result", nil, nil, params)
        end, yyId, isFree and "active_explorer_free1" or "active_explorer_rmb1")
    end

    if isFree or myNum > 0 then
        requesetServer()
    else
        dataEasy.sureUsingDiamonds(requesetServer, self.cost[1])
    end
end

function ActivityDrawLimitExplorView:onDrawTenClick()
    -- 十抽
    local bUseDiamond = false --是否消耗钻石抽卡
	-- if dataEasy.getNumByKey(game.ITEM_TICKET.drawLimitExpItem) < 10 then
	-- 	bUseDiamond = true
	-- end

    local myNum = dataEasy.getNumByKey(game.ITEM_TICKET.drawLimitExpItem)
    if myNum < 10 then
        gGameUI:showTip(gLanguageCsv.drawItemNotEnough)
        return
    end
    
    local function requesetServer()
        local yyId = self.activityId
        gGameApp:requestServer("/game/lottery/yy/draw", function(tb)
            audio.pauseMusic()
            audio.playEffectWithWeekBGM("drawcard_one.mp3")
            local ret, spe, isFull, _, extra = dataEasy.getRawTable(tb)
            local items = dataEasy.getItems(ret, spe)
            local params = {
                items = items,
                extra = extra,
                drawType = "active_explor",
                times = 10,
                yyId = yyId,
                cb = function(tb)
                end,
            }

            gGameUI:stackUI("city.drawcard.result", nil, nil, params)
        end, yyId, "active_explorer_rmb10")
    end

    if bUseDiamond then
		local cost =  self.cost[2]
		gGameUI:showDialog { content = string.format(gLanguageCsv.draw10CardTips, cost), cb = function()
			requesetServer()
		end, btnType = 2, clearFast = true, isRich = true }
	else
		requesetServer()
	end
end

function ActivityDrawLimitExplorView:onAwardClick()
    -- 奖励预览
    gGameUI:stackUI("city.drawcard.preview", nil, { blackLayer = true, clickClose = true }, "limit_sprite", self.activityId)
end

-- 显示规则文本
function ActivityDrawLimitExplorView:onShowRule()
    gGameUI:stackUI("common.rule", nil, nil, self:createHandler("getRuleContext"))
end

function ActivityDrawLimitExplorView:getRuleContext(view)
    local c = adaptContext
    local context = {
        c.clone(view.title, function(item)
            item:get("text"):text(gLanguageCsv.rules)
        end),
        c.noteText(129300, 129303),
    }
    return context
end

return ActivityDrawLimitExplorView
