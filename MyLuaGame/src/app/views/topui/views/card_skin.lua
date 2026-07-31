local config = require("app.views.topui.config")
local TopuiBase = require("app.views.topui.base")
local TopuiCardSkinView = class("TopuiCardSkinView", TopuiBase)

TopuiCardSkinView.RESOURCE_FILENAME = "topui_card_skin.json"
TopuiCardSkinView.RESOURCE_BINDING = maptools.extend({
	config.skinCard,
	config.title,
	config.gold,
	config.diamond,
})

function TopuiCardSkinView:onCreate(params)
	TopuiBase.onCreate(self, {"title"}, params)
end

return TopuiCardSkinView