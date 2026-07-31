local YY_TYPE = game.YYHUODONG_TYPE_ENUM_TABLE

local Activity = require "app.views.city.activity.view"

local ActivityThemeSkinView = class("ActivityThemeSkinView", cc.load("mvc").ViewBase)

ActivityThemeSkinView.RESOURCE_FILENAME = "activity_theme_skin_draw.json"
ActivityThemeSkinView.RESOURCE_BINDING = {
    ["bg"] = "bg",
    ["left.btnSignIn"] = {
        varname = "btnSignIn",
        binds = {
            {
                event = "touch",
                methods = {
                    ended = bindHelper.self("onSignInClick")
                }
            },
            {
                event = "extend",
                class = "red_hint",
                props = {
                    specialTag = "activityThemeSkinSignIn",
                    onNode = function(node)
                        node:xy(140, 150)
                    end,
                },
            },
        }
    },
    ["left.btnGift"] = {
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
                    specialTag = "activityThemeSkinGift",
                    onNode = function(node)
                        node:xy(140, 150)
                    end,
                },
            },
        }
    },
    ["left.btnGive"] = {
        varname = "btnGive",
        binds = {
            {
                event = "touch",
                methods = {
                    ended = bindHelper.self("onGiveClick")
                }
            },
            {
                event = "extend",
                class = "red_hint",
                props = {
                    specialTag = "activityThemeSkinGive",
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
                    specialTag = "activityThemeSkinExchange",
                    onNode = function(node)
                        node:xy(140, 150)
                    end,
                },
            },
        }
    },

    ["left.btnRule"] = {
        binds = {
            event = "touch",
            methods = { ended = bindHelper.self("onShowRule") }
        },
    },

    --
    ["draw1"] = "draw1",
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

    --
    ["right.btnAward"] = {
        binds = {
            event = "touch",
            methods = {
                ended = bindHelper.self("onAwardClick")
            }
        }
    },
    ["right.btnAward.textNote"] = {
        binds = {
            event = "effect",
            data = ui.BTN_STYLE_1
        }
    },
    ["right.nameBg"] = "nameBg",
    ["right.btnRule"] = {
        binds = {
            event = "touch",
            methods = { ended = bindHelper.self("onShowRule") }
        },
    },

    ["nodSkel"] = "nodSkel",
    ["countTips"] = "countTips",
    ["time"] = "time",

}

function ActivityThemeSkinView:onCreate(activityId)
    local cfg = csv.yunying.yyhuodong[activityId]
    gGameUI.topuiManager:createView("theme_skin", self, { onClose = self:createHandler("onClose") })
        :init({ title = cfg.name, subTitle = "STAR UPGRADE" })

    self:initModel()

    self.activityId = idler.new(activityId) -- 活动ID号

    self:initInfoData(cfg.clientParam, cfg.paramMap)
    self.myDrawNum = idler.new(0)


    idlereasy.any({ self.yyhuodongs }, function(_, yyhuodongs)
        local yydata = yyhuodongs[activityId] or {}
        local info = yydata.info or {}
        local limit_count = info.limit_counter_1 or 0
        self.countTips:get("num"):text(math.max(csv.yunying.yyhuodong[activityId].paramMap.number - limit_count, 0))
        adapt.oneLineCenterPos(cc.p(320, 60),
            { self.countTips:get("num"), self.countTips:get("txt1"), self.countTips:get("icon"), self.countTips:get(
                "txt2") }, cc.p(4, 0))
    end)
    local uiIcon = self.time:get("icon")
    local uiTime = self.time:get("time")
    Activity.setCountdown(self, self.activityId:read(), nil, uiTime, {
        labelChangeCb = function()
            adapt.oneLineCenterPos(cc.p(180, 30), { uiIcon, uiTime }, cc.p(20, 0))
        end,
        tag = "theme_skin_view" .. self.activityId:read()
    })
end

function ActivityThemeSkinView:initModel()
    self.yyhuodongs = gGameModel.role:getIdler("yyhuodongs")
end

-- 消耗
function ActivityThemeSkinView:initInfoData(clientParam, paramMap)
    self.draw1:get("costBg.num"):text(paramMap.SKIN1)
    self.draw10:get("costBg.num"):text(paramMap.SKIN10)

    self.unitID = clientParam.unitID
    local unitCsv = csv.unit[clientParam.unitID]
    local spine = widget.addAnimationByKey(self.nodSkel, unitCsv.showOpen, unitCsv.showOpen, "default", 1, true)
    spine:xy(clientParam.x, clientParam.y):scale(clientParam.scale)

    adapt.setAutoText(self.nameBg:get("txt"), unitCsv.name, 200)
end

function ActivityThemeSkinView:onSignInClick()
    -- 签到
    local activityId = dataEasy.getActivityIdInYYOPEN(YY_TYPE.LoginGift, 7)
    if activityId then
        gGameUI:stackUI("city.activity.theme_skin.sign_in", nil, { blackLayer = true }, activityId)
    end
end

function ActivityThemeSkinView:onGiftClick()
    -- 礼包
    local activityId = dataEasy.getActivityIdInYYOPEN(YY_TYPE.directBuyGift, game.DIRECT_GIFT.THEME_SKIN_GIFT)
    if activityId then
        gGameUI:stackUI("city.activity.theme_skin.gift", nil, { blackLayer = true }, activityId)
    end
end

function ActivityThemeSkinView:onGiveClick()
    -- 赠礼
    local activityId = dataEasy.getActivityIdInYYOPEN(YY_TYPE.directBuyGift, game.DIRECT_GIFT.THEME_SKIN_GIVE)
    if activityId then
        gGameUI:stackUI("city.activity.theme_skin.give", nil, nil, activityId)
    end
end

function ActivityThemeSkinView:onExchangeClick()
    -- 兑换
    local activityId = dataEasy.getActivityIdInYYOPEN(YY_TYPE.itemExchange, 2)
    if activityId then
        gGameUI:stackUI("city.activity.theme_skin.exchange", nil, { blackLayer = true }, activityId)
    end
end

function ActivityThemeSkinView:isEnoughToDraw(isTen)
    local myNum = dataEasy.getNumByKey(game.ITEM_TICKET.lotterySkinItem)

    if isTen then
        return myNum >= 10
    else
        return myNum >= 1
    end
end

function ActivityThemeSkinView:onDrawOneClick()
    -- 单抽
    local onceEnough = self:isEnoughToDraw(false)
    if not onceEnough then
        gGameUI:showTip(gLanguageCsv.drawItemNotEnough)
        return
    end
    local yyId = self.activityId:read()
    gGameApp:requestServer("/game/lottery/yy/draw", function(tb)
        audio.pauseMusic()
        audio.playEffectWithWeekBGM("drawcard_one.mp3")
        local ret, spe, isFull, _, extra = dataEasy.getRawTable(tb)
        local items = dataEasy.getItems(ret, spe)
        local params = {
            items = items,
            extra = extra,
            drawType = "theme_skin",
            times = 1,
            yyId = yyId,
            cb = function(tb)
            end,
        }

        gGameUI:stackUI("city.drawcard.result", nil, nil, params)
    end, yyId, "limit_card_rmb1")
end

function ActivityThemeSkinView:onDrawTenClick()
    -- 十抽
    local tenEnough = self:isEnoughToDraw(true)
    if not tenEnough then
        gGameUI:showTip(gLanguageCsv.drawItemNotEnough)
        return
    end
    local yyId = self.activityId:read()
    gGameApp:requestServer("/game/lottery/yy/draw", function(tb)
        audio.pauseMusic()
        audio.playEffectWithWeekBGM("drawcard_one.mp3")
        local ret, spe, isFull, _, extra = dataEasy.getRawTable(tb)
        local items = dataEasy.getItems(ret, spe)
        local params = {
            items = items,
            extra = extra,
            drawType = "theme_skin",
            times = 10,
            yyId = yyId,
            cb = function(tb)
            end,
        }

        gGameUI:stackUI("city.drawcard.result", nil, nil, params)
    end, yyId, "limit_card_rmb10")
end

function ActivityThemeSkinView:onAwardClick()
    -- 奖励预览
    gGameUI:stackUI("city.drawcard.preview", nil, { blackLayer = true, clickClose = true }, "limit_sprite",
        self.activityId:read())
end

-- 显示规则文本
function ActivityThemeSkinView:onShowRule()
    gGameUI:stackUI("common.rule", nil, nil, self:createHandler("getRuleContext"))
end

function ActivityThemeSkinView:getRuleContext(view)
    local c = adaptContext
    local context = {
        c.clone(view.title, function(item)
            item:get("text"):text(gLanguageCsv.themeskinrule)
        end),
        c.noteText(129236, 129240),
    }
    return context
end

return ActivityThemeSkinView
