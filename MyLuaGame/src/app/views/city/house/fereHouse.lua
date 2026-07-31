local ViewBase = cc.load("mvc").ViewBase
local FereHouse = class("FereHouse", ViewBase)

FereHouse.RESOURCE_FILENAME = "fere_house.json"
FereHouse.RESOURCE_BINDING = {
    ["bg"] = "bg",
    ["leftPanel"] = "leftPanel",
    ["leftPanel.item"] = "item",
    ["leftPanel.nameImg"] = "nameImg",
    ["leftPanel.list"] = {
        varname = "list",
        binds = {
            event = "extend",
            class = "listview",
            props = {
                data = bindHelper.self("fereRolesData"),
                item = bindHelper.self("item"),
                padding = 10,
                itemAction = { isAction = true, alwaysShow = true },
                onItem = function(list, node, k, v)
                    local head = node:get("head")
                    if v.id == -1 then
                        head:texture("house/new.png")
                        cache.setShader(head, false, "hsl_gray")
                        local selected = node:get("selected")
                        selected:setVisible(false)
                    else
                        node:name("item" .. k)
                        local selected = node:get("selected")
                        selected:setVisible(v.selected)
                        local headPath = "house/" .. v.id .. "/icon_head.png"
                        head:texture(headPath)
                        if v.own then
                            cache.setShader(head, false, "normal")
                        else
                            cache.setShader(head, false, "hsl_gray")
                        end
                        bind.touch(list, head, { methods = { ended = functools.partial(list.clickHead, v.id) } })
                    end
                end
            },
            handlers = {
                clickHead = bindHelper.self("onClickHead"),
            },
        }
    },
    ["rightPanel.btn_cloth"] = {
        binds = {
            event = "touch",
            methods = {
                ended = bindHelper.self("onClickCloth")
            }
        }
    },
    ["rightPanel.btn_ani"] = {
        binds = {
            event = "touch",
            methods = {
                ended = bindHelper.self("onClickAni")
            }
        }
    },

    ["rightPanel.btn_enhance"] = {
        binds = {
            event = "touch",
            methods = {
                ended = bindHelper.self("onClickEnhance")
            }
        }
    },
    ["rightPanel.cardPanel"] = "cardPanel",
}

function FereHouse:onClickCloth()
    if self:checkOwn(self.selectedFereId:read()) then
        gGameUI:stackUI("city.house.fereUnlock", nil, {
            full = true
        }, { fereId = self.selectedFereId:read(), type = "cloth" })
    end
end

function FereHouse:onClickAni()
    if self:checkOwn(self.selectedFereId:read()) then
        gGameUI:stackUI("city.house.fereUnlock", nil, {
            full = true
        }, { fereId = self.selectedFereId:read(), type = "video" })
    end
end

function FereHouse:onClickEnhance()
    if self:checkOwn(self.selectedFereId:read()) then
        gGameUI:showTip("enhance")
        gGameUI:stackUI("city.house.fereEnhance", nil, nil, self.selectedFereId:read())
    end
end

function FereHouse:checkOwn(id)
    local size = self.fereRolesData:size()
    for index = 1, size do
        if self.fereRolesData:atproxy(index).id == id and self.fereRolesData:atproxy(index).own == true then
            return true
        end
    end
    gGameUI:showTip("Chưa có được") -- weihao test todo
    return false
end

function FereHouse:onClickHead(list, id)
    self.selectedFereId:set(id)
    self:checkOwn(id)
end

function FereHouse:initData()
    self.selectedFereId = idler.new(6)
    self.fereRolesData = idlers.new()
    local rolesData = {}
    -- for k, v in csvPairs(csv.banlvxiaowu) do
    --     table.insert(rolesData, { id = v.id, own = false, sort = v.sort })
    -- end
    -- table.sort(rolesData, function(a, b) return a.sort < b.sort end)
    table.insert(rolesData, { id = -1 })
    self.fereRolesData:update(rolesData)
    self.houseLovers = gGameModel.role:getIdler("house_lovers")
end

function FereHouse:initEnhanceCard()
    self.cardPanel:removeAllChildren()
    -- performWithDelay(self, function()
    --     for fereId, roleData in pairs(self.houseLovers:read()) do
    --         if fereId == self.selectedFereId:read() then
    --             local card = gGameModel.cards:find(roleData.card)
    --             if card then
    --                 local card_id = card:read("card_id")
    --                 local cardCfg = csv.cards[card_id]
    --                 if cardCfg then
    --                     local unitCfg = csv.unit[cardCfg.unitID]

    --                     widget.addAnimation(self.cardPanel, unitCfg.unitRes, "standby_loop", 2)
    --                         :xy(0, 0)
    --                         :scale(unitCfg.scaleU * 0.4)
    --                         :setSkin(unitCfg.skin)
    --                 end

    --                 local label = cc.Label:createWithTTF(gLanguageCsv.zhuguzhong, ui.FONT_PATH, 30)
    --                     :align(cc.p(0.5, 0.5), 0, -25)
    --                     :addTo(self.cardPanel, 3, "num")
    --                 text.addEffect(label,
    --                     {
    --                         color = ui.COLORS.NORMAL.WHITE,
    --                         outline = {
    --                             color = ui.COLORS.OUTLINE.DEFAULT,
    --                             size = 3
    --                         }
    --                     })
    --             end
    --         end
    --     end
    -- end, 0)
end

function FereHouse:onIdler()
    -- idlereasy.when(self.houseLovers, function(obj, houseLovers)
    --     for fereId, _ in pairs(houseLovers) do
    --         local size = self.fereRolesData:size()
    --         for index = 1, size do
    --             if self.fereRolesData:atproxy(index).id == fereId then
    --                 self.fereRolesData:atproxy(index).own = true
    --             end
    --         end
    --     end
    --     self:initEnhanceCard()
    -- end)

    idlereasy.when(self.selectedFereId, function(obj, curId, oldId)
        local size = self.fereRolesData:size()
        for index = 1, size do
            if self.fereRolesData:atproxy(index).id == curId then
                self.fereRolesData:atproxy(index).selected = true
            end
            if self.fereRolesData:atproxy(index).id == oldId then
                self.fereRolesData:atproxy(index).selected = false
            end
        end

        performWithDelay(self, function()
            self.nameImg:texture("house/" .. curId .. "/name.png")
            if self.spine then
                self.spine:removeFromParent()
                self.spine = nil
            end
            local spinePath = "spine/xiaowu/spine" .. curId .. "_1_1.skel"
            self.spine = widget.addAnimation(self.bg, spinePath, "default", 1, true)
        end, 0)
        self:initEnhanceCard()
    end)
end

function FereHouse:onCreate()
    gGameUI.topuiManager:createView("fere_house", self, {
        onClose = self:createHandler("onClose")
    }):init({
        title = gLanguageCsv.xiaowu,
        subTitle = ""
    })
    self:getResourceNode():getChildByName("leftPanel"):getChildByName("nameImg"):hide()
    self:getResourceNode():getChildByName("rightPanel"):hide()

    self:initData()
    self:onIdler()
    audio.playMusic("xiaowu.mp3")
end

function FereHouse:onClose()
    local curMusicIdx = userDefault.getForeverLocalKey("musicIdx", 1)
    local cfg = csv.citysound[curMusicIdx]
    if cfg then
        audio.playMusic(cfg.path)
    else
        printWarn("music index not exist", curMusicIdx)
    end

    ViewBase.onClose(self)
end

return FereHouse
