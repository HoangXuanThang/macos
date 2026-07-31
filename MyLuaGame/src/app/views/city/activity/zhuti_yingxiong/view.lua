-- 主题英雄

local YY_TYPE = game.YYHUODONG_TYPE_ENUM_TABLE

local Activity = require "app.views.city.activity.view"

local ActivityZhutiYingxiongView = class("ActivityZhutiYingxiongView", cc.load("mvc").ViewBase)

ActivityZhutiYingxiongView.RESOURCE_FILENAME = "activity_zhuti_yingxiong_draw.json"
ActivityZhutiYingxiongView.RESOURCE_BINDING = {
    ["bg"] = "bg",
    -- left
    ["left"] = "left",
    ["right"] = "right",
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
                    specialTag = "activityZhutiYingxiongSignIn",
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
                    specialTag = "playPassportZhutiYingxiong",
                    onNode = function(node)
                        node:xy(170, 170)
                    end,
                },
            },
        }
    },
    ["left.btnShop"] = {
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
                    specialTag = "activityZhutiYingxiongShop",
                    onNode = function(node)
                        node:xy(170, 170)
                    end,
                },
            },
        }
    },
    ["left.btnRule"] = {
        varname = "btnRule",
        binds = {
            {
                event = "touch",
                methods = {
                    ended = bindHelper.self("onShowRule")
                }
            },
        }
    },
    -- center
    ["center"] = "center",
    ["center.countBg"] = "countBg",
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
                    panel:xy(150, 40)
                end,
            }
        }
    },
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

    -- right
    ["right.timeBg"] = "timeBg",
    ["awardPanel.numBg.num"] = {
        binds = {
            event = "text",
            idler = bindHelper.self("totalDrawNum"),
        },
    },
    ["awardPanel.numBg.txt"] = {
        binds = {
            event = "effect",
            data = { outline = { color = ui.NEWCOLORS.OUTLINE.BLACK, size = 4 } },
        },
    },
    ["awardPanel.bar"] = "bar",
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
    ["awardPanel.item"] = "item",
    ["awardPanel.item.count"] = {
        binds = {
            event = "effect",
            data = { outline = { color = ui.NEWCOLORS.OUTLINE.BLACK, size = 2 } },
        },
    },
    ["awardPanel.item.num"] = {
        binds = {
            event = "effect",
            data = { outline = { color = ui.NEWCOLORS.OUTLINE.BLACK, size = 2 } },
        },
    },
    ["awardPanel.list"] = {
        varname = "awardList",
        binds = {
            event = "extend",
            class = "listview",
            props = {
                data = bindHelper.self("boxAwards"),
                item = bindHelper.self("item"),
                totalDrawNum = bindHelper.self("totalDrawNum"),
                paddings = { up = 0, down = 0, left = 0, right = 70 },
                dataOrderCmp = function(a, b)
                    return a.id < b.id
                end,
                onItem = function(list, node, k, v)
                    node:get("num"):text(v.endCount)
                    local bgRes = "activity/zhuti_yingxiong/ztyx_floor2.png"
                    if v.index == 3 or v.index == 6 then
                        bgRes = "activity/zhuti_yingxiong/ztyx_floor3.png"
                    elseif v.index == 10 then
                        bgRes = "activity/zhuti_yingxiong/ztyx_floor4.png"
                    end
                    node:get("bg"):texture(bgRes)
                    local award = dataEasy.getItemData(v.award)
                    local customIcon = nil
                    if v.index == 10 then
                        customIcon = "activity/zhuti_yingxiong/ztyx_icon6.png"
                    elseif v.index == 6 then
                        customIcon = "activity/zhuti_yingxiong/ztyx_icon5.png"
                    end
                    node:get("count"):text("x" .. award[1].num)
                    node:get("count"):visible(award[1].num > 1)
                    bind.extend(list, node:get("icon"), {
                        class = "icon_key",
                        props = {
                            data = award[1],
                            simpleShow = true,
                            showNum = false,
                            showLogo = false,
                            showExclusive = false,
                            customIcon = customIcon,
                            grayState = v.state == 0 and 2 or 0,
                            onNode = function(panel)
                                panel:scale(0.5)
                            end,
                        }
                    })

                    node:get("click"):visible(false)
                    bind.click(list, node:get("click"), { method = functools.partial(list.itemClick, k, v) })

                    idlereasy.any({ list.totalDrawNum }, function(_, drawNum)
                        node:get("effectPanel"):removeChildByName("effect")
                        node:get("click"):visible(false)
                        if drawNum >= v.endCount and v.state == 1 then
                            widget.addAnimationByKey(node:get("effectPanel"), "effect/jiedianjiangli.skel", "effect",
                                "effect_loop", 0)
                                :xy(0, -30)
                                :scale(0.3)
                            node:get("click"):visible(true)
                        end
                    end)
                end,
            },
            handlers = {
                itemClick = bindHelper.self("onBoxAwardClick"),
                itemShow = bindHelper.self("onBoxShow"),
            },
        },
    },
    ["nodSkel"] = "nodSkel",
}

function ActivityZhutiYingxiongView:getAwards(boxSate)
    local awards = {}
    local index = 1
    for k, v in orderCsvPairs(csv.draw_count) do
        if v.huodongID == self.activityId then
            awards[k] = {
                id = k,
                index = index,
                state = boxSate[k] or 1,
                award = v.award,
                endCount = v.count,
            }
            index = index + 1
        end
    end
    
    return awards
end

function ActivityZhutiYingxiongView:onCreate(activityId)
    adapt.dockWithScreen(self.left, "left", nil, true)
    adapt.dockWithScreen(self.right, "right", nil, true)
    self.activityId = activityId -- 活动ID号
    self.exploreActivityId = dataEasy.getActivityIdInYYOPEN(YY_TYPE.dispatch)

    local cfg = csv.yunying.yyhuodong[activityId]
    gGameUI.topuiManager:createView("zhuti_yingxiong", self, { onClose = self:createHandler("onClose") })
        :init({ title = cfg.name })

    self:initModel()

    self.myDrawNum = idler.new(0)
    self.totalDrawNum = idler.new(0)
    self.maxNum = 100

    self:initInfoData(cfg.clientParam, cfg.paramMap)
    self.boxAwards = idlers.newWithMap({})
    local boxSate = self.getDiamondAwardState:read()[game.DRAW_BOX_TYPE.THEME_HERO] or {}
    self.boxAwards:update(self:getAwards(boxSate))

    idlereasy.any({ self.yyhuodongs }, function(_, yyhuodongs)
        local yydata = yyhuodongs[activityId] or {}
        local info = yydata.info or {}
        local limit_count = info.limit_counter_1 or 0
        local limit_counter_all = info.limit_counter_all or limit_count
        
        self.totalDrawNum:set(limit_counter_all)
        self.bar:setPercent(limit_counter_all / 1000 * 100)

        self.myDrawNum:set(math.max(self.maxNum - limit_count, 0))
    end)

    idlereasy.any({ self.getDiamondAwardState }, function(_, awardState)
        local boxSate = awardState[game.DRAW_BOX_TYPE.ZHUTI_YINGXIONG] or {}
        self.boxAwards:update(self:getAwards(boxSate))
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

function ActivityZhutiYingxiongView:initModel()
    self.yyhuodongs = gGameModel.role:getIdler("yyhuodongs")
    self.getDiamondAwardState = gGameModel.role:getIdler("draw_sum_box") --钻石宝箱领取状态(1可领取，2已领取)
end

-- 消耗
function ActivityZhutiYingxiongView:initInfoData(clientParam, paramMap)
    self.draw1:get("costBg.num"):text(paramMap.draw1)
    self.draw10:get("costBg.num"):text(paramMap.draw10)

    self.maxNum = paramMap.number

    self.unitID = clientParam.unitID
    local unitCsv = csv.unit[clientParam.unitID]
    widget.addAnimation(self.nodSkel, unitCsv.showOpen, "default", 5, true)
end

-- 签到
function ActivityZhutiYingxiongView:onSignInClick()
    local activityId = dataEasy.getActivityIdInYYOPEN(YY_TYPE.LoginGift, game.SIGNIN_TYPE.T_ZHUTI_YINGXIONG)
    if activityId then
        gGameUI:stackUI("city.activity.zhuti_yingxiong.sign_in", nil, { blackLayer = true }, activityId)
    end
end

-- 战令
function ActivityZhutiYingxiongView:onPassportClick()
    local activityId = dataEasy.getActivityIdInYYOPEN(YY_TYPE.playPassport, game.PASSPORT_IDX.T_ZHUTI_YINGXIONG)
    if activityId then
        gGameUI:stackUI("city.activity.zhuti_yingxiong.passport", nil, { full = true }, activityId)
    end
end

function ActivityZhutiYingxiongView:onShopClick()
    -- 商店
    local activityId = dataEasy.getActivityIdInYYOPEN(YY_TYPE.directBuyGift, game.DIRECT_GIFT.ZHUTI_YINGXIONG_SHOP)
    if activityId then
        gGameUI:stackUI("city.activity.zhuti_yingxiong.shop", nil, { blackLayer = true }, activityId)
    end
end

function ActivityZhutiYingxiongView:onAwardClick()
    -- 奖励预览
    gGameUI:stackUI("city.drawcard.preview", nil, { blackLayer = true, clickClose = true }, "limit_sprite",
        self.activityId)
end

-- 显示规则文本
function ActivityZhutiYingxiongView:onShowRule()
    gGameUI:stackUI("common.rule", nil, nil, self:createHandler("getRuleContext"))
end

function ActivityZhutiYingxiongView:getRuleContext(view)
    local c = adaptContext
    local context = {
        c.clone(view.title, function(item)
            item:get("text"):text(gLanguageCsv.themeherorule)
        end),
        c.noteText(129251, 129254),
    }
    return context
end

function ActivityZhutiYingxiongView:isEnoughToDraw(isTen)
    local myNum = dataEasy.getNumByKey(game.ITEM_TICKET.lotteryZhuTiYingXiongItem)

    if isTen then
        return myNum >= 10
    else
        return myNum >= 1
    end
end

function ActivityZhutiYingxiongView:onDrawOneClick()
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
            drawType = "zhuti_yingxiong",
            times = 1,
            yyId = yyId,
            cb = function(tb)
            end,
        }

        gGameUI:stackUI("city.drawcard.result", nil, nil, params)
    end, yyId, "limit_card_rmb1")
end

function ActivityZhutiYingxiongView:onDrawTenClick()
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
            drawType = "zhuti_yingxiong",
            times = 10,
            yyId = yyId,
            cb = function(tb)
            end,
        }

        gGameUI:stackUI("city.drawcard.result", nil, nil, params)
    end, yyId, "limit_card_rmb10")
end

-- 宝箱领取
function ActivityZhutiYingxiongView:onBoxAwardClick(_, id, v)
    local yyId = self.activityId
    local boxState = self.boxAwards:atproxy(id).state

    if self.totalDrawNum:read() < v.endCount then
        -- 次数不足
        gGameUI:showBoxDetail({
            data = csv.draw_count[id].award,
            content = string.format(gLanguageCsv.accumulatedAward, csv.draw_count[id].count - (self.preCount or 0)),
            state = 1,
        })
        return
    end

    if boxState == 1 then
        gGameApp:requestServer("/game/lottery/yy/draw/box/get", function(cb)
            gGameUI:showGainDisplay(csv.draw_count[id].award, {
                raw = false,
                cb = function()
                    -- self.downPanel:get("item" .. (idx + 1)):get("result"):visible(false)
                    -- self:initAward()
                end
            })
        end, yyId, id)
    end
end

function ActivityZhutiYingxiongView:onExchangeClick()
    -- 兑换
    -- local activityId = dataEasy.getActivityIdInYYOPEN(YY_TYPE.itemExchange, game.EXCHANGE_IND.IDX_THEME_HERO)
    -- if activityId then
    --     gGameUI:stackUI("city.activity.theme_hero.exchange", nil, { blackLayer = true }, activityId)
    -- end
end

function ActivityZhutiYingxiongView:onBoxShow(list, panel, data)
    local params = { key = data.key, num = data.num }
    gGameUI:showItemDetail(panel, params)
end

return ActivityZhutiYingxiongView
