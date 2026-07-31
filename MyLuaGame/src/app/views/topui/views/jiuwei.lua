-- @desc: 通用默认 topui

local config = require("app.views.topui.config")
local TopuiBase = require("app.views.topui.base")
local TopuiJiuWeiView = class("TopuiJiuWeiView", TopuiBase)

TopuiJiuWeiView.RESOURCE_FILENAME = "topui_jiuwei.json"
TopuiJiuWeiView.RESOURCE_BINDING = maptools.extend({
	config.title,
	config.diamond,
	config.jiuWei,
})

function TopuiJiuWeiView:onCreate(params)
	TopuiBase.onCreate(self, { "title" }, params)
end

return TopuiJiuWeiView
