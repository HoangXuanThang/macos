local config = require("app.views.topui.config")
local TopuiBase = require("app.views.topui.base")
local TopuiFereHouse = class("TopuiFereHouse", TopuiBase)

TopuiFereHouse.RESOURCE_FILENAME = "topui_fere_house.json"
TopuiFereHouse.RESOURCE_BINDING = maptools.extend({
    config.title,
    config.fereClothClip,
    config.fereVideoClip,
})

function TopuiFereHouse:onCreate(params)
    TopuiBase.onCreate(self, { "title" }, params)
end

return TopuiFereHouse
