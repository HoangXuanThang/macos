local ViewBase = cc.load("mvc").ViewBase
local FereUnlock = class("FereCollection", ViewBase)

FereUnlock.RESOURCE_FILENAME = "fere_unlock.json"
FereUnlock.RESOURCE_BINDING = {
    ["dot"] = "dot",
    ["dotsPanel"] = "dotsPanel",
    ["pageview"] = {
        varname = "pageview",
        binds = {
            event = "extend",
            class = "pageview",
            props = {
                data = bindHelper.self("unlocks"),
                item = bindHelper.self("item"),
                onItem = function(list, node, page, v)
                    node:name("item" .. page)
                    local resPath = "house/" .. v.fereId .. "/" .. v.type .. "/" .. page .. "/"
                    local panel = node:getChildByName("panel")
                    local btn_video = node:getChildByName("btn_video")
                    btn_video:setVisible(false)
                    local bg = panel:getChildByName("bg")
                    local isLock = true
                    for index = 1, 28, 1 do
                        local chip = panel:getChildByName("chip_" .. index)
                        chip:texture(resPath .. index .. ".png")
                        if bit.band(v.unlock, bit.lshift(1, (index - 1))) == 0 then
                            chip:visible(true):setTouchEnabled(true)
                            bind.touch(list, chip,
                                {
                                    scaletype = 0,
                                    sound = 3,
                                    methods = { ended = functools.partial(list.onClickChip, page, index, chip) }
                                })
                            isLock = false
                            if v.fereId == 1 and index == 19 and page == 1 and v.type == "video" then
                                widget.addAnimation(chip, "effect/shouyindao.skel", "effect_loop")
                                    :alignCenter(chip:size())
                                    :scale(0.5)
                            end
                        else
                            chip:visible(false):setTouchEnabled(false)
                        end
                    end
                    bg:texture(resPath .. "bg.jpg")
                    if isLock then
                        if v.type == "cloth" then
                            local spine = panel:getChildByName("spine")
                            if not spine then
                                local ainRes = "spine/xiaowu/spine" .. v.fereId .. "_2_" .. page .. ".skel"
                                widget.addAnimation(bg, ainRes, "default", 1, true)
                            end
                        else
                            btn_video:setVisible(true)
                            bind.touch(list, btn_video,
                                {
                                    methods = { ended = functools.partial(list.onClickVideo, page) }
                                })
                        end
                    end
                end,
            },
            handlers = {
                onClickChip = bindHelper.self("onClickChip"),
                onClickVideo = bindHelper.self("onClickVideo"),
            },
        },
    },
}

function FereUnlock:initData()
    self.unlocks = idlers.new()
    local unlockData = {}
    local totalPage = 0
    if self.chipType == "cloth" then
        totalPage = csvSize(csv.banlvxiaowu[self.fereId].clothattr)
    elseif self.chipType == "video" then
        totalPage = csvSize(csv.banlvxiaowu[self.fereId].videoattr)
    end
    for i = 1, totalPage, 1 do
        table.insert(unlockData, { fereId = self.fereId, type = self.chipType, unlock = 0 })
    end
    self.unlocks:update(unlockData)

    self.houseLovers = gGameModel.role:getIdler("house_lovers")
    idlereasy.when(self.houseLovers, function(obj, houseLovers)
        for k, v in pairs(houseLovers) do
            if k == self.fereId then
                if v and v[self.chipType] then
                    dump(v[self.chipType])
                    for page, value in pairs(v[self.chipType]) do
                        self.unlocks:atproxy(page).unlock = value
                    end
                end
            end
        end
    end)
end

function FereUnlock:initPageView()
    local dots = {}
    local totalPage = 0
    if self.chipType == "cloth" then
        totalPage = csvSize(csv.banlvxiaowu[self.fereId].clothattr)
    elseif self.chipType == "video" then
        totalPage = csvSize(csv.banlvxiaowu[self.fereId].videoattr)
    end
    if totalPage > 1 then
        for i = 1, totalPage, 1 do
            local dot = self.dot:clone():addTo(self.dotsPanel):xy(0, 0)
            dots[i] = dot
        end
        adapt.oneLineCenterPos(cc.p(0, 0), dots, cc.p(50, 0))
        self.curPage = idler.new(0)
        idlereasy.when(self.curPage, function(obj, curPage)
            for i = 1, #dots, 1 do
                local dot = dots[i]:getChildByName("dot")
                dot:setVisible(i == curPage + 1)
            end
        end)
        self.pageview:onScroll(function(event)
            if event.name == "AUTOSCROLL_ENDED" then
                self.curPage:set(self.pageview:getCurPageIndex())
            end
        end)
    end
    self.pageview:x((display.sizeInView.width - self.pageview:size().width) / 2)
    self.item = cache.createWidget("fere_chips_28.json"):addTo(self.pageview:getParent()):y(10000)
end

function FereUnlock:onCreate(params)
    self.clickEffect = nil
    gGameUI.topuiManager:createView("fere_house", self, {
        onClose = self:createHandler("onClose")
    }):init({
        title = gLanguageCsv.xiaowu,
        subTitle = ""
    })

    self.fereId = params.fereId
    self.chipType = params.type
    self:initData()
    self:initPageView()
end

function FereUnlock:onClickChip(list, page, index, chip)
    if self.chipType == "cloth" then
        local clothCost = csv.banlvxiaowu[self.fereId].clothCost
        for id, num in csvPairs(clothCost) do
            if dataEasy.getNumByKey(id) < num then
                gGameUI:showTip(gLanguageCsv.inadequateProps)
                return
            end
        end
        gGameApp:requestServer("/game/lover/cloth/unlock", nil, self.fereId, page, index)
    elseif self.chipType == "video" then
        local videoCost = csv.banlvxiaowu[self.fereId].videoCost
        for id, num in csvPairs(videoCost) do
            if dataEasy.getNumByKey(id) < num then
                gGameUI:showTip(gLanguageCsv.inadequateProps)
                return
            end
        end
        gGameApp:requestServer("/game/lover/video/unlock", nil, self.fereId, page, index)
    end
    if chip then
        widget.addAnimationByKey(chip:getParent(), "effect/dianji.json", self.chipType .. "_" .. page .. "_" .. index,
            "default", 10):x(chip:x()):y(chip:y())
    end
end

function FereUnlock:onClickVideo(list, page)
    local resPath = "house/" .. self.fereId .. "_" .. page .. ".mp4"
    local needDown = gGameApp.subPack:checkNeedDownload(resPath)
    if needDown then
        gGameUI:stackUI("city.house.fereDown", nil, nil, resPath)
    else
        if device.platform == "ios" then
            gGameUI:playVideo(resPath)
        else
            gGameUI:stackUI("city.house.fereVideo", nil, {
                full = true
            }, resPath)
        end
    end
end

return FereUnlock
