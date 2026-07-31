-- @desc: 通用默认 topui

local config = require("app.views.topui.config")
local TopuiBase = require("app.views.topui.base")
local TopuiDrawHelditemView = class("TopuiDrawHelditemView", TopuiBase)

TopuiDrawHelditemView.RESOURCE_FILENAME = "topui_drawlimit_helditem.json"
TopuiDrawHelditemView.RESOURCE_BINDING = maptools.extend({
	config.title,
    config.diamond,
	config.drawLimitHelditem,
})

function TopuiDrawHelditemView:onCreate(params)
	TopuiBase.onCreate(self, {"title"}, params)
end

return TopuiDrawHelditemView