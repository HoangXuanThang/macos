local ActivityCustomizeSprite = class("ActivityCustomizeSprite", Dialog)

ActivityCustomizeSprite.RESOURCE_FILENAME = "activity_customize_sprite.json"
ActivityCustomizeSprite.RESOURCE_BINDING = {
    ["panel.title.btnClose"] = {
        varname = "btnClose",
        binds = {
            event = "touch",
            methods = {
                ended = bindHelper.self("onClose")
            }
        }
    },
    ["centerPanel.subList"] = "subList",
    ["centerPanel.cardItem"] = "cardItem",
    ["centerPanel.cardList"] = {
        varname = "cardList",
        binds = {
            event = "extend",
            class = "tableview",
            props = {
                columnSize = 6,
                data = bindHelper.self("cardInfos"),
                item = bindHelper.self("subList"),
                cell = bindHelper.self("cardItem"),
                dataOrderCmpGen = bindHelper.self("onSortCardList", true),
                itemAction = {
                    isAction = true,
                    alwaysShow = true,
                    actionTime = 0.5,
                    duration = 0.3
                },
                onCell = function(list, cell, k, v)
                    local t = list:getIdx(k)
                    bind.extend(list, cell, {
                        class = "card_icon",
                        props = {
                            unitId = v.unitId,
                            rarity = v.rarity,
                            selected = v.isSel,
                            params = {
                                starScale = 0.85,
                                starInterval = 13
                            }
                        }
                    })
                    bind.touch(list, cell, {
                        methods = {
                            ended = functools.partial(list.itemClick, cell, t, v)
                        }
                    })
                end,

                asyncPreload = 18,
                leftPadding = 20,
                topPadding = 20,
                xMargin = 20
            },
            handlers = {
                itemClick = bindHelper.self("onItemClick")
            }
        }
    },
    ["btnCancel"] = {
        varname = "btnCancel",
        binds = {
            event = "touch",
            methods = {
                ended = bindHelper.self("onCancel")
            }
        }
    },
    ["btnOK"] = {
        varname = "btnOK",
        binds = {
            event = "touch",
            methods = {
                ended = bindHelper.self("onClickOK")
            }
        }
    }
}


function ActivityCustomizeSprite:onClickOK()
    self:addCallbackOnExit(self._okcb)

    local selectDbId = self.selectDbId:read()
    if not selectDbId or selectDbId == 0 then
        gGameUI:showTip(gLanguageCsv.propertyChoiceFirst)
        return
    end
    if self.callback then
        self.callback(selectDbId)
        Dialog.onClose(self)
    end
end

function ActivityCustomizeSprite:onCancel()
    self:addCallbackOnExit(self._cancelcb)
    self:onClose()
end

function ActivityCustomizeSprite:onItemClick(list, item, t, v)
    self.selectDbId:set(v.id)
    local params = { key = "card", num = v.id }
    gGameUI:showItemDetail(item, params)
end

function ActivityCustomizeSprite:onCreate(cards, cb)
    self:initModel()

    self.callback = cb

    self.selectDbId = idler.new(0)

    self.cardInfos = idlers.new({}) -- 卡牌数据

    local tmpCardDatas = {}
    for k, card_id in pairs(cards) do
        local cardCsv = csv.cards[card_id]
        if cardCsv then
            local unitCsv = csv.unit[cardCsv.unitID]
            tmpCardDatas[card_id] = {
                id = card_id,
                markId = cardCsv.cardMarkID,
                name = cardCsv.name,
                unitId = cardCsv.unitID,
                num = 1,
                rarity = unitCsv.rarity,
            }
        end
    end
    self.cardInfos:update(tmpCardDatas, function(v)
        return v.id
    end)

    self.selectDbId:addListener(handler(self, "onSelectDbIdChanged"))

    Dialog.onCreate(self, { blackType = 1 })
end

function ActivityCustomizeSprite:onSelectDbIdChanged(val, oldval)
    if self.cardInfos:atproxy(oldval) then
        self.cardInfos:atproxy(oldval).isSel = false
    end
    if self.cardInfos:atproxy(val) then
        self.cardInfos:atproxy(val).isSel = true
    end
end

function ActivityCustomizeSprite:initModel()
    -- self.fate_card_ids = gGameModel.role:getIdler("fate_card_ids") -- 卡牌
end

return ActivityCustomizeSprite
