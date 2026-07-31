-- 主题英雄

local YY_TYPE = game.YYHUODONG_TYPE_ENUM_TABLE

local Activity = require "app.views.city.activity.view"

local ActivityJiuWeiView = class("ActivityJiuWeiView", cc.load("mvc").ViewBase)

ActivityJiuWeiView.RESOURCE_FILENAME = "activity_jiuwei.json"
ActivityJiuWeiView.RESOURCE_BINDING = {
    ["bg"] = "bg",
    -- left
    ["left"] = "left",
    ["left.btnAward"] = {
        binds = {
            event = "touch",
            methods = {
                ended = bindHelper.self("onAwardClick")
            }
        }
    },
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
                    specialTag = "activityJiuWeiSignIn",
                    onNode = function(node)
                        node:xy(170, 170)
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
                    specialTag = "activityJiuWeiGift",
                    onNode = function(node)
                        node:xy(170, 170)
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
                    specialTag = "activityJiuWeiExchange",
                    onNode = function(node)
                        node:xy(170, 170)
                    end,
                },
            },
        }
    },
    ["left.btnPassport"] = {
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
                    specialTag = "playPassportJiuWei",
                    onNode = function(node)
                        node:xy(170, 170)
                    end,
                },
            },
        }
    },

    -- center
    ["center"] = "center",
    ["center.countBg.num"] = {
        binds = {
            event = "extend",
            class = "text_atlas",
            props = {
                data = bindHelper.self("myDrawNum"),
                align = "right",
                pathName = "zhtpf_num",
                isEqualDist = false,
                onNode = function(panel)
                    panel:xy(100, 50)
                end,
            }
        }
    },
    ["center.nodSkel"] = "nodSkel",
    ["center.btnSkill1"] = {
        varname = "btnSkill1",
        binds = {
            event = "touch",
            methods = { ended = bindHelper.self("onShowSkill1") }
        },
    },
    ["center.btnSkill2"] = {
        varname = "btnSkill2",
        binds = {
            event = "touch",
            methods = { ended = bindHelper.self("onShowSkill2") }
        },
    },


    -- right
    ["right"] = "right",
    ["right.timeBg"] = "timeBg",
    ["right.draw1"] = "draw1",
    ["right.draw1.btn"] = {
        binds = {
            event = "touch",
            methods = {
                ended = bindHelper.self("onDrawOneClick")
            }
        }
    },
    ["right.draw10"] = "draw10",
    ["right.draw10.btn"] = {
        binds = {
            event = "touch",
            methods = {
                ended = bindHelper.self("onDrawTenClick")
            }
        }
    },
    ["right.btnRule"] = {
        binds = {
            event = "touch",
            methods = { ended = bindHelper.self("onShowRule") }
        },
    },

}


function ActivityJiuWeiView:onCreate(activityId)
    self.activityId = activityId -- 活动ID号
    if self.btnPassport then
        self.btnPassport:hide()
    end
    if self.btnExchange then
        local x, y = self.btnExchange:getPosition()
        self.btnExchange:setPosition(x, y + 200)
    end

    local cfg = csv.yunying.yyhuodong[activityId]
    gGameUI.topuiManager:createView("jiuwei", self, { onClose = self:createHandler("onClose") })
        :init({ title = cfg.name })

    self:initModel()

    self.myDrawNum = idler.new(0)
    self.totalDrawNum = idler.new(0)
    self.maxNum = 200


    self:initInfoData(cfg.clientParam, cfg.paramMap)

    idlereasy.any({ self.yyhuodongs }, function(_, yyhuodongs)
        local yydata = yyhuodongs[activityId] or {}
        local info = yydata.info or {}
        local limit_count = info.limit_counter_1 or 0
        local limit_counter_all = info.limit_counter_all or 0

        self.totalDrawNum:set(limit_counter_all)

        self.myDrawNum:set(math.max(self.maxNum - limit_count, 0))
    end)


    local uiIcon = self.timeBg:get("icon")
    local uiTime = self.timeBg:get("time")
    Activity.setCountdown(self, self.activityId, nil, uiTime, {
        labelChangeCb = function()
            adapt.oneLineCenterPos(cc.p(210, 30), { uiIcon, uiTime }, cc.p(10, 0))
        end,
        tag = "view" .. self.activityId
    })
end

function ActivityJiuWeiView:initModel()
    self.yyhuodongs = gGameModel.role:getIdler("yyhuodongs")
end

-- 消耗
function ActivityJiuWeiView:initInfoData(clientParam, paramMap)
    self.draw1:get("costBg.num"):text(paramMap.draw1)
    self.draw10:get("costBg.num"):text(paramMap.draw10)

    self.maxNum = paramMap.number or 100

    local expCsv = csv.explorer.explorer[clientParam.explorerID]
    if not expCsv then
        return
    end
    widget.addAnimationByKey(self.nodSkel, expCsv.res, "spine", "default", 1, true):scale(2.5)

    -- 技能
    self:onUpdateSkill(clientParam.explorerID)
end

-- 技能
function ActivityJiuWeiView:onUpdateSkill(expID)
    local abilityCsv = gExplorerAbilityCsv[expID]
    for i, v in ipairs(abilityCsv) do
        if v.effectType == 2 then
            self.abilitySkillID = v.skillID
            break
        end
    end

    local expCsv = csv.explorer.explorer[expID]
    local effectID = expCsv.effect[1]
    local effCsv = csv.explorer.explorer_effect[effectID]
    self.effectID = effCsv.skillID
end

function ActivityJiuWeiView:isEnoughToDraw(isTen)
    local myNum = dataEasy.getNumByKey(game.ITEM_TICKET.lotteryJiuWeiItem)

    if isTen then
        return myNum >= 10
    else
        return myNum >= 1
    end
end

function ActivityJiuWeiView:onDrawOneClick()
    -- 单抽
    local onceEnough = self:isEnoughToDraw(false)
    if not onceEnough then
        gGameUI:showTip(gLanguageCsv.drawItemNotEnough)
        return
    end
    local yyId = self.activityId
    gGameApp:requestServer("/game/lottery/yy/draw", function(tb)
        audio.pauseMusic()
        audio.playEffectWithWeekBGM("drawcard_one.mp3")
        local ret, spe, isFull, _, extra = dataEasy.getRawTable(tb)
        local items = dataEasy.getItems(ret, spe)
        local params = {
            items = items,
            extra = extra,
            drawType = "jiu_wei",
            times = 1,
            yyId = yyId,
            cb = function(tb)
            end,
        }

        gGameUI:stackUI("city.drawcard.result", nil, nil, params)
    end, yyId, "limit_explorer_rmb1")
end

function ActivityJiuWeiView:onDrawTenClick()
    -- 十抽
    local tenEnough = self:isEnoughToDraw(true)
    if not tenEnough then
        gGameUI:showTip(gLanguageCsv.drawItemNotEnough)
        return
    end
    local yyId = self.activityId
    gGameApp:requestServer("/game/lottery/yy/draw", function(tb)
        audio.pauseMusic()
        audio.playEffectWithWeekBGM("drawcard_one.mp3")
        local ret, spe, isFull, _, extra = dataEasy.getRawTable(tb)
        local items = dataEasy.getItems(ret, spe)
        local params = {
            items = items,
            extra = extra,
            drawType = "jiu_wei",
            times = 10,
            yyId = yyId,
            cb = function(tb)
            end,
        }

        gGameUI:stackUI("city.drawcard.result", nil, nil, params)
    end, yyId, "limit_explorer_rmb10")
end

function ActivityJiuWeiView:onSignInClick()
    -- 签到
    local activityId = dataEasy.getActivityIdInYYOPEN(YY_TYPE.LoginGift, game.SIGNIN_TYPE.T_JIU_WEI)
    if activityId then
        gGameUI:stackUI("city.activity.jiu_wei.sign_in", nil, { blackLayer = true }, activityId)
    end
end

function ActivityJiuWeiView:onGiftClick()
    -- 礼包
    local activityId = dataEasy.getActivityIdInYYOPEN(YY_TYPE.directBuyGift, game.DIRECT_GIFT.THEME_JIU_WEI_GIFT)
    if activityId then
        gGameUI:stackUI("city.activity.jiu_wei.gift", nil, { blackLayer = true }, activityId)
    end
end

function ActivityJiuWeiView:onPassportClick()
    local activityId = dataEasy.getActivityIdInYYOPEN(YY_TYPE.playPassport, game.PASSPORT_IDX.T_JIU_WEI)
    if activityId then
        gGameUI:stackUI("city.activity.jiu_wei.passport", nil, { full = true }, activityId)
    end
end

function ActivityJiuWeiView:onExchangeClick()
    -- 兑换
    local activityId = dataEasy.getActivityIdInYYOPEN(YY_TYPE.itemExchange, game.EXCHANGE_IND.IDX_JIU_WEI)
    if activityId then
        gGameUI:stackUI("city.activity.jiu_wei.exchange", nil, { blackLayer = true }, activityId)
    end
end

function ActivityJiuWeiView:onAwardClick()
    -- 奖励预览
    gGameUI:stackUI("city.drawcard.preview", nil, { blackLayer = true, clickClose = true }, "limit_sprite",
        self.activityId)
end

-- 显示规则文本
function ActivityJiuWeiView:onShowRule()
    gGameUI:stackUI("common.rule", nil, nil, self:createHandler("getRuleContext"))
end

function ActivityJiuWeiView:getRuleContext(view)
    local c = adaptContext
    local context = {
        c.clone(view.title, function(item)
            item:get("text"):text(gLanguageCsv.themeExpRule)
        end),
        c.noteText(129256, 129259),
    }
    return context
end

function ActivityJiuWeiView:onShowSkill1()
    gGameUI:stackUI("common.skill_text", nil, { dispatchNodes = self.btnSkill1, clickClose = true },
        { skillId = self.effectID, node = self.btnSkill1 })
end

function ActivityJiuWeiView:onShowSkill2()
    gGameUI:stackUI("common.skill_text", nil, { dispatchNodes = self.btnSkill2, clickClose = true },
        { skillId = self.abilitySkillID, node = self.btnSkill2 })
end

return ActivityJiuWeiView
