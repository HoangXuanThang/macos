-- 视频下载
local ViewBase = cc.load("mvc").ViewBase
local FereDownView = class("FereDownView", ViewBase)

FereDownView.RESOURCE_FILENAME = "fere_down.json"
FereDownView.RESOURCE_BINDING = {
    ["center"] = "centerPanel",
    ["center.barDesc"] = {
        varname = "barDesc",
        binds = {
            event = "effect",
            data = {
                outline = {
                    color = ui.COLORS.NORMAL.WHITE
                }
            }
        }
    },
    ["center.bar"] = "panelDownBar",
}

FereDownView.RESOURCE_STYLES = {
    blackLayer = true,
    backGlass = true,
}

function FereDownView:onCreate(path, cb)
    self:enableSchedule()

    self.callback = cb

    local loadingIcon = self.centerPanel:getChildByName("loadingIcon")
    local z = loadingIcon:getLocalZOrder()
    self.centerPanel:removeChildByName("loadingIcon")
    local runingEffect = sp.SkeletonAnimation:create("loading/loading_dog.skel", "loading/loading_dog.atlas")
    runingEffect:setAnimation(0, "effect_loop", true)
    runingEffect:setVisible(false)
    runingEffect:setName("loadingIcon")
    runingEffect:setAnchorPoint(cc.p(1, 0))
    runingEffect:setScale(1.6)
    self.centerPanel:add(runingEffect, z)


    self.panelDownBar:setPercent(0)

    self.centerPanel:unscheduleUpdate()
    self.centerPanel:scheduleUpdate(function()
        local percent = gGameApp.subPack:getDownprogress()
        self.panelDownBar:setPercent(percent)

        local loadingSpr = self.centerPanel:getChildByName("loadingIcon")
        loadingSpr:setVisible(true)
        local percentX = percent / 100 * self.panelDownBar:getContentSize().width + 480
        loadingSpr:setPosition(percentX, 720)
        if percent >= 100 then
            self.centerPanel:unscheduleUpdate()
        end
    end)

    gGameApp.subPack:downloadOneFile(path, function()
        performWithDelay(self, function()
            self:onClose()
            if device.platform == "ios" then
                gGameUI:playVideo(path)
            else
                gGameUI:stackUI("city.house.fereVideo", nil, {
                    full = true
                }, path)
            end
        end, 1)
    end)
end

return FereDownView
