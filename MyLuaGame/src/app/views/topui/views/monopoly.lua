-- @desc: 通用默认 topui

local config = require("app.views.topui.config")
local TopuiBase = require("app.views.topui.base")
local TopuiThemeSkinView = class("TopuiThemeSkinView", TopuiBase)

TopuiThemeSkinView.RESOURCE_FILENAME = "topui_monopoly.json"
TopuiThemeSkinView.RESOURCE_BINDING = maptools.extend({
	config.title,
    config.diamond,
	config.monopoly,
})

function TopuiThemeSkinView:onCreate(params)
	TopuiBase.onCreate(self, {"title"}, params)
end

return TopuiThemeSkinView