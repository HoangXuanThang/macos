-- @desc: 通用默认 topui

local config = require("app.views.topui.config")
local TopuiBase = require("app.views.topui.base")
local TopuiChirstmasView = class("TopuiChirstmasView", TopuiBase)

TopuiChirstmasView.RESOURCE_FILENAME = "topui_christmas.json"
TopuiChirstmasView.RESOURCE_BINDING = maptools.extend({
	config.title,
    config.diamond,
	config.christmas,
})

function TopuiChirstmasView:onCreate(params)
	TopuiBase.onCreate(self, {"title"}, params)
end

return TopuiChirstmasView