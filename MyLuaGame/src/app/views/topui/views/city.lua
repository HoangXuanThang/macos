-- @desc: 主城专用 topui

local config = require("app.views.topui.config")
local TopuiBase = require("app.views.topui.base")
local TopuiCityView = class("TopuiCityView", TopuiBase)

TopuiCityView.RESOURCE_FILENAME = "topui_city.json"
TopuiCityView.RESOURCE_BINDING = maptools.extend({
	config.skinCard,
	config.gold,
	config.diamond,
	config.stamina,
})

function TopuiCityView:onCreate()
    TopuiBase.onCreate(self, {"stamina"})
    self.skinCardBalance = gGameModel.skinCardBalance
    local node = self:getResourceNode()
    local panels = {
        node:get("rightTopPanel.skinCardPanel"),
        node:get("rightTopPanel.goldPanel"),
        node:get("rightTopPanel.diamondPanel"),
        node:get("rightTopPanel.staminaPanel"),
    }
    local spacing = 400
    local startX = -display.width + 2650

    for i, panel in ipairs(panels) do
        if panel then
            print(">>> PANEL:", panel:getName())
            panel:setPositionX(startX + spacing * (i - 1))
        else
            print(">>> PANEL MISSING AT INDEX", i)
        end
    end
    --gGameUI.cityTopView = self

    -- -- Gọi lần đầu sau delay
    local platform_post = 3
    if device.platform == "android" then
        platform_post = 1
    elseif device.platform == "ios" then
        platform_post = 2
    end
    local data = {
        username = cc.UserDefault:getInstance():getStringForKey("username", ""),
        device = platform_post,
        token = cc.UserDefault:getInstance():getStringForKey("accessToken", ""),
    }

    print(" Gửi packet get-user-info qua backend")

    gGameApp:requestServerCustom("/game/get-user-info")
        :params(data)
        :onErrCall(function(err)
            print("Lỗi backend (KHÔNG show popup):", err.err)
        end)
        :doit(function(tb, err)
        if not err then
            local money = 0
            if tb and tb.view and tb.view.data and tb.view.data.money then
                print("Get money info success:", tb.view.data.money)
                money = tonumber(tb.view.data.money) or 0
            else
                print("Get money info failed: data nil hoặc thiếu field money")
            end
            gGameModel.skinCardBalance:set(money)
        else
            print("Get money Lỗi:", err)
        end
    end)

    gGameApp:requestServerCustom("/game/update-device-info")
        :params(data)
        :slient() 
        :onErrCall(function(err)
            print("Lỗi backend (KHÔNG show popup):", err.err)
        end)
        :doit(function(tb, err)
        if not err then
            print("update device success:", dump(tb.view))
        else
            print("Update device Lỗi:", err)
        end
    end, data)


end

return TopuiCityView
