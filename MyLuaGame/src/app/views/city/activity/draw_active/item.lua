

local ActivityThemeSpItemView = class("ActivityThemeSpItemView", cc.load("mvc").ViewBase)

ActivityThemeSpItemView.RESOURCE_FILENAME = "activity_theme_sp_item.json"
ActivityThemeSpItemView.RESOURCE_BINDING = {
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

function ActivityThemeSpItemView:onCreate(activityId)
    self.activityId = activityId

    self:initModel()
    self:updateHero()

    idlereasy.any({ self.yyhuodongs }, function(_, yyhuodongs)
        local yydata = yyhuodongs[activityId] or {}
        local info = yydata.info or {}
        local limit_count = info.limit_counter_1 or 0
        local num = math.max(csv.yunying.yyhuodong[activityId].paramMap.number - limit_count, 0)
        self.myDrawNum:set(num)
    end)


end

function ActivityThemeSpItemView:initModel()
    self.yyhuodongs = gGameModel.role:getIdler("yyhuodongs")

    self.myDrawNum = idler.new(0)
end

function ActivityThemeSpItemView:updateHero()
    local yyCfg = csv.yunying.yyhuodong[self.activityId]
    local type, clientParam, paramMap = yyCfg.type, yyCfg.clientParam, yyCfg.paramMap
    
    local expCsv = csv.held_item.items[clientParam.spineID]
    if not expCsv then
        return
    end

    self.name:get("txt"):text(expCsv.name)
    -- adapt.setAutoText(self.name:get("txt"), unitCsv.name, 200)

    bind.extend(self, self.item, {
        class = "icon_key",
        props = {
            data = {
                key = clientParam.spineID,
            },
            onNode = function(node)
                node:scale(1.5)
                -- node:xy(size.width/2, size.height/2 + 75)
            end,
        },
    })
    
end

function ActivityThemeSpItemView:onDrawOneClick()
    local yyId = self.activityId
    gGameApp:requestServer("/game/lottery/yy/draw", function(tb)
        audio.pauseMusic()
        audio.playEffectWithWeekBGM("drawcard_one.mp3")
        local ret, spe, isFull, _, extra = dataEasy.getRawTable(tb)
        local items = dataEasy.getItems(ret, spe)
        local params = {
            items = items,
            extra = extra,
            drawType = "theme_sp_item",
            times = 1,
            yyId = yyId,
            cb = function(tb)
            end,
        }

        gGameUI:stackUI("city.drawcard.result", nil, nil, params)
    end, yyId, "limit_helditem_rmb1")
end

function ActivityThemeSpItemView:onDrawTenClick()
    -- 十抽
    local yyId = self.activityId
    gGameApp:requestServer("/game/lottery/yy/draw", function(tb)
        audio.pauseMusic()
        audio.playEffectWithWeekBGM("drawcard_one.mp3")
        local ret, spe, isFull, _, extra = dataEasy.getRawTable(tb)
        local items = dataEasy.getItems(ret, spe)
        local params = {
            items = items,
            extra = extra,
            drawType = "theme_sp_item",
            times = 10,
            yyId = yyId,
            cb = function(tb)
            end,
        }

        gGameUI:stackUI("city.drawcard.result", nil, nil, params)
    end, yyId, "limit_helditem_rmb10")
end


return ActivityThemeSpItemView