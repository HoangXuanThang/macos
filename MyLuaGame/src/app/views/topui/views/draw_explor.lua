-- @desc: 通用默认 topui

local config = require("app.views.topui.config")
local TopuiBase = require("app.views.topui.base")
local TopuiDrawExplorView = class("TopuiDrawExplorView", TopuiBase)

TopuiDrawExplorView.RESOURCE_FILENAME = "topui_drawlimit_exp.json"
TopuiDrawExplorView.RESOURCE_BINDING = maptools.extend({
	config.title,
    config.diamond,
	config.drawLimitExp,
})

function TopuiDrawExplorView:onCreate(params)
	TopuiBase.onCreate(self, {"title"}, params)
end

return TopuiDrawExplorView