-- 圣诞

local ITEM_SCALE = {1.5, 1, 1.2, 0.8}

local function playAnim(node)
	 
    -- 上下飘动动画
	local moveOff = math.random(15, 30)
    local moveUp = cc.MoveBy:create(2, cc.p(0, moveOff))  -- 向上移动20单位，持续2秒
    local moveDown = cc.MoveBy:create(2, cc.p(0, -moveOff)) -- 向下移动20单位，持续2秒
    local moveSequence = cc.Sequence:create(moveUp, moveDown)
    local moveForever = cc.RepeatForever:create(moveSequence)
    
    -- 微弱呼吸动画
    local scaleUp = cc.ScaleBy:create(1.5, 1.05) -- 放大5%，持续1.5秒
    local scaleDown = cc.ScaleBy:create(1.5, 1 / 1.05) -- 缩小回原始大小
    local scaleSequence = cc.Sequence:create(scaleUp, scaleDown)
    local scaleForever = cc.RepeatForever:create(scaleSequence)
    
    -- 将动画添加到精灵
    node:runAction(moveForever)
    node:runAction(scaleForever)
end

local YY_TYPE = game.YYHUODONG_TYPE_ENUM_TABLE

local ActivityView = require "app.views.city.activity.view"

local ActivityChristmasWishView = class("ActivityChristmasWishView", cc.load("mvc").ViewBase)

ActivityChristmasWishView.RESOURCE_FILENAME = "activity_christmas.json"
ActivityChristmasWishView.RESOURCE_BINDING = {
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
					specialTag = "activityChristmasWishGift",
					onNode = function(node)
						node:xy(170, 170)
					end,
				},
			},
           
        }
    },
    ["left.btnAward"] = {
        varname = "btnAward",
        binds = {
            {
                event = "touch",
                methods = {
                    ended = bindHelper.self("onAwardClick")
                }
            },
            {
				event = "extend",
				class = "red_hint",
				props = {
                    specialTag = "activityDrawBoxAward",
					listenData = {
                        activityId = bindHelper.self("activityId"),
                        drawBoxType = game.DRAW_BOX_TYPE.CHRISTMAS
                    },
					onNode = function(node)
						node:xy(170, 170)
					end,
				},
			},
        }
    },

    -- center
    ["center"] = "center",
    ["center.draw1"] = "draw1",
    ["center.draw1.btn"] = {
        binds = {
            event = "touch",
            methods = {
                ended = bindHelper.self("onDrawOneClick")
            }
        }
    },
    ["center.draw10"] = "draw10",
    ["center.draw10.btn"] = {
        binds = {
            event = "touch",
            methods = {
                ended = bindHelper.self("onDrawTenClick")
            }
        }
    },

    -- right
    ["right.timeBg"] = "timeBg",
    ["right.btnPreAward"] = {
        binds = {
            event = "touch",
            methods = {
                ended = bindHelper.self("onPreAwardClick")
            }
        }
    }
}

function ActivityChristmasWishView:onCreate(activityId)
    self.activityId = activityId -- 活动ID号

    local cfg = csv.yunying.yyhuodong[activityId]
    gGameUI.topuiManager:createView("christmas", self, { onClose = self:createHandler("onClose") })
		:init({ title = cfg.name })

    self:initModel()

    self:initInfoData(cfg.clientParam, cfg.paramMap)

    local uiIcon = self.timeBg:get("icon")
    local uiTime = self.timeBg:get("time")
    ActivityView.setCountdown(self, self.activityId, nil, uiTime, {labelChangeCb = function()
        adapt.oneLineCenterPos(cc.p(210, 30), {uiIcon, uiTime }, cc.p(10, 0))
    end, tag = "view" .. self.activityId})
end

function ActivityChristmasWishView:initModel()
	self.yyhuodongs = gGameModel.role:getIdler("yyhuodongs")
end

function ActivityChristmasWishView:initInfoData(clientParam, paramMap)
    self.draw1:get("costBg.num"):text(paramMap.DRAW1)
    self.draw10:get("costBg.num"):text(paramMap.DRAW10)

    for i = 1, 4 do
        local node = self.center:get("pao" .. i)
        local itemId = clientParam.items[i]
        bind.extend(self, node:get("icon"), {
            class = "icon_key",
            props = {
                data = {key = itemId},
                simpleShow = true,
                onNode = function(panel)
                    panel:scale(ITEM_SCALE[i])
                end
            },
        })
        playAnim(node)
    end

    -- self:initTheme(clientParam.theme)
end

-- function ActivityChristmasWishView:initTheme(theme)
--     self.bg:texture(string.format("activity/theme_hero/%s/chouYX_bg1.jpg", theme))
-- end

function ActivityChristmasWishView:isEnoughToDraw(isTen)

	local myNum = dataEasy.getNumByKey(game.ITEM_TICKET.christmasItem)

    if isTen then
		return myNum >= 10
	else
		return myNum >= 1
	end
end

function ActivityChristmasWishView:onDrawOneClick()
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
            drawType = "christmas_item",
            times = 1,
            yyId = yyId,
            cb = function(tb)
            end,
        }

        gGameUI:stackUI("city.drawcard.result", nil, nil, params)
        
    end, yyId, "christmas_wish_rmb1")
end

function ActivityChristmasWishView:onDrawTenClick()
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
            drawType = "christmas_item",
            times = 10,
            yyId = yyId,
            cb = function(tb)
            end,
        }

        gGameUI:stackUI("city.drawcard.result", nil, nil, params)
        
    end, yyId, "christmas_wish_rmb10")
end


function ActivityChristmasWishView:onGiftClick()
    -- 商店
    local activityId = dataEasy.getActivityIdInYYOPEN(YY_TYPE.directBuyGift, game.DIRECT_GIFT.CHRISTMAS)
    if activityId then
        gGameUI:stackUI("city.activity.christmas.gift", nil, nil, activityId)
    end
end

function ActivityChristmasWishView:onAwardClick()
    gGameUI:stackUI("city.activity.christmas.award", nil, nil, self.activityId)
end

function ActivityChristmasWishView:onPreAwardClick()
    -- 奖励预览
    gGameUI:stackUI("city.drawcard.preview", nil, { blackLayer = true, clickClose = true }, "limit_sprite",	self.activityId)
end

return ActivityChristmasWishView
