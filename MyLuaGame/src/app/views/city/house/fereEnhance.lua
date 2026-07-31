local FereEnhance = class("FereEnhance", Dialog)

FereEnhance.RESOURCE_FILENAME = "fere_enhance.json"
FereEnhance.RESOURCE_BINDING = {
    ["panel.title.btnClose"] = {
        varname = "btnClose",
        binds = {
            event = "touch",
            methods = {
                ended = bindHelper.self("onClose")
            }
        }
    },
    ["cardNode"] = "cardNode",
    ["centerPanel.subList"] = "subList",
    ["centerPanel.cardItem"] = "cardItem",
    ["centerPanel.cardList"] = {
        varname = "cardList",
        binds = {
            event = "extend",
            class = "tableview",
            props = {
                columnSize = 6,
                data = bindHelper.self("cardInfoList"),
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
                    local index = (list:getIdx(k).row - 1) * list.itemSize + k
                    bind.extend(list, cell, {
                        class = "card_icon",
                        props = {
                            unitId = v.unitId,
                            advance = v.advance,
                            star = v.star,
                            rarity = v.rarity,
                            selected = v.selected,
                            levelProps = {
                                data = v.level
                            },
                            params = {
                                starScale = 0.85,
                                starInterval = 13
                            }
                        }
                    })
                    bind.touch(list, cell, {
                        methods = {
                            ended = functools.partial(list.itemClick, index)
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
    ["centerPanel.textNode"] = {
        varname = "content",
        binds = {
            event = "effect",
            data = {
                outline = {
                    color = ui.COLORS.NORMAL.WHITE
                }
            }
        }
    },
    ["btnCancel"] = {
        varname = "btnCancel",
        binds = {
            event = "touch",
            methods = {
                ended = bindHelper.self("onClose")
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

function FereEnhance:onItemClick(tableview, index)
    self.selectedIndex:set(index)
end

function FereEnhance:onClickOK()
    local cardInfo = self.cardInfoList:atproxy(self.selectedIndex:read())
    if cardInfo then
        gGameApp:requestServerCustom("/game/lover/bless/card")
            :params(self.fereId, cardInfo.dbid)
            :doit(function(tb)
                Dialog.onClose(self)
                gGameUI:showTip(gLanguageCsv.zhufuok)
            end)
    end
end

function FereEnhance:initCardInfoList()
    self.battleCards = gGameModel.role:getIdler("battle_cards")
    self.cards = gGameModel.role:getIdler("cards")
    self.houseLovers = gGameModel.role:getIdler("house_lovers")
    self.cardInfoList = idlers.new()
    idlereasy.any({ self.cards, self.battleCards, self.houseLovers }, function(obj, cards, battleCards, houseLovers)
        local battleCardsList = itertools.map(itertools.ivalues(battleCards), function(k, v)
            return v, k
        end)
        local enhancedList = itertools.map(itertools.ivalues(houseLovers), function(k, v)
            return v.card or "", k
        end)

        local cardInfoList = {}
        for _, dbid in pairs(cards) do
            if not enhancedList[dbid] then
                local card = gGameModel.cards:find(dbid)
                if card then
                    local cardData = card:read("card_id", "skin_id", "fighting_point", "level", "star", "advance")
                    local cardCsv = csv.cards[cardData.card_id]
                    local unitId = dataEasy.getUnitId(cardData.card_id, cardData.skin_id)
                    local unitCsv = csv.unit[unitId]
                    local cardInfo = {
                        id = cardData.card_id,
                        markId = cardCsv.cardMarkID,
                        unitId = unitId,
                        rarity = unitCsv.rarity,
                        fight = cardData.fighting_point,
                        level = cardData.level,
                        star = cardData.star,
                        dbid = dbid,
                        advance = cardData.advance,
                        battle = battleCardsList[dbid] and 1 or 2,
                    }
                    table.insert(cardInfoList, cardInfo)
                end
            end
        end
        table.sort(cardInfoList, function(a, b)
            if a.battle == b.battle then
                if a.fight == b.fight then
                    return a.markId < b.markId
                else
                    return a.fight > b.fight
                end
            else
                return a.battle < b.battle
            end
        end)
        self.cardInfoList:update(cardInfoList)
    end)
end

function FereEnhance:initSelect()
    self.selectedIndex = idler.new(1)
    idlereasy.when(self.selectedIndex, function(obj, curIndex, oldIndex)
        if self.cardInfoList:atproxy(oldIndex) then
            self.cardInfoList:atproxy(oldIndex).selected = false
        end
        if self.cardInfoList:atproxy(curIndex) then
            self.cardInfoList:atproxy(curIndex).selected = true
            local cardInfo = self.cardInfoList:atproxy(curIndex)
            bind.extend(self, self.cardNode, {
                class = "card_icon",
                props = {
                    unitId = cardInfo.unitId,
                    advance = cardInfo.advance,
                    star = cardInfo.star,
                    rarity = cardInfo.rarity,
                    selected = cardInfo.selected,
                    levelProps = {
                        data = cardInfo.level
                    },
                    params = {
                        starScale = 0.85,
                        starInterval = 13
                    }
                }
            })
        end
    end)
end

function FereEnhance:initEnhanceEffect()
    local unlocks = {}

    local cloths = gGameModel.role:getIdler("house_lovers"):read()[self.fereId]["cloth"]
    for i = 1, #dataEasy.getRawTable(cloths), 1 do
        table.insert(unlocks, cloths[i])
    end
    local videos = gGameModel.role:getIdler("house_lovers"):read()[self.fereId]["video"]
    for i = 1, #dataEasy.getRawTable(videos), 1 do
        table.insert(unlocks, videos[i])
    end

    local attrValue = 5
    for i = 1, #unlocks, 1 do
        local unlock = unlocks[i]
        if unlock == 0xfffffff then
            attrValue = attrValue + 2
        end
    end

    local fereCsv = csv.banlvxiaowu[self.fereId]
    local attr = dataEasy.getAttrTypeValue(fereCsv.attrType, fereCsv.attrNum)
    self.content:text(string.format(gLanguageCsv.zhufushuxing, attr .. "+" .. attrValue .. "%"))
end

function FereEnhance:onCreate(fereId)
    self.fereId = fereId
    self:initCardInfoList()
    self:initSelect()
    self:initEnhanceEffect()
    Dialog.onCreate(self)
end

return FereEnhance
