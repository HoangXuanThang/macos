-- @desc: 商店pvp topui

local config = require("app.views.topui.config")
local TopuiBase = require("app.views.topui.base")
local TopuiHeldView = class("TopuiHeldView", TopuiBase)

TopuiHeldView.RESOURCE_FILENAME = "topui_held.json"
TopuiHeldView.RESOURCE_BINDING = maptools.extend({
	config.title,
	config.gold,
	config.diamond,
	config.heldShop,
})

function TopuiHeldView:onCreate(params)
	TopuiBase.onCreate(self, { "title" }, params)
end

return TopuiHeldView
