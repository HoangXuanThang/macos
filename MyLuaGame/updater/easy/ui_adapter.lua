--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2017 TianJi Information Technology Inc.
--
-- 主要是进行多语言版本的UI工程适配
--

local type = type

local config = nil
local configCn = nil

local internalFuncMap

function globals.setContentSizeOfAnchor(node, targetSize)
	local anchor = node:getAnchorPoint()
	local size = node:getContentSize()
	local p = {}
	for _, child in pairs(node:getChildren()) do
		local x, y = child:getPosition()
		x = x - size.width * anchor.x
		y = y - size.height * anchor.y
		p[child] = cc.p(x, y)
	end
	node:setContentSize(targetSize)
	for _, child in pairs(node:getChildren()) do
		local x, y = p[child].x, p[child].y
		x = x + targetSize.width * anchor.x
		y = y + targetSize.height * anchor.y
		child:setPosition(x, y)
	end
end

-- @param node: cocos2dx node
-- @param res: resource path for key match
-- @param reverse: nil(初始化设置)，true(适配回置)，false(配置重置)
function globals.adaptUI(node, res, reverse)
	-- 全屏画布，适配全面屏
	local size = node:getContentSize()
	if size.width == CC_DESIGN_RESOLUTION.width and size.height == CC_DESIGN_RESOLUTION.height then
		setContentSizeOfAnchor(node, display.sizeInView)
	end

	if config == nil then
		local path = "app.defines.adapter." .. LOCAL_LANGUAGE
		xpcall(function() config = require(path) end, function()
			printWarn('not exist ' .. path)
			config = {}
		end)
		configCn = require("app.defines.adapter.cn")
	end

	-- 文本内容适配
	local uiConfig = config[res] or configCn[res]
	if uiConfig then
		for op, t in pairs(uiConfig) do
			local memo = {}
			local f = internalFuncMap[op]
			for _, params in ipairs(t) do
				if reverse == nil then
					f(node, params, memo)
				else
					if op == "dockWithScreen" then
						local curParams = clone(params)
						curParams[5] = reverse
						f(node, curParams, memo)
					end
				end
			end
		end
	end
end

local function _getMemo(memo, key)
	if memo == nil then
		return
	end
	if memo[key] then
		return memo[key][1]
	end
end

local function _setMemo(memo, key, node)
	if memo == nil then
		return node
	end
	if node ~= nil then
		if memo[key] then
			return node, memo[key][2]
		end
		local nextMemo = {}
		memo[key] = {node, nextMemo}
		return node, nextMemo
	end
end

-- node:get('a.b.c')
-- node:get(112)
local function _getChild(node, key, memo)
	if type(key) == 'number' then
		local nextNode = _getMemo(memo, key)
		if nextNode == nil then
			nextNode = node:getChildByTag(key)
		end
		node, memo = _setMemo(memo, key, nextNode)
	else
		for k in key:gmatch("([^.]+)") do
			local ik = tonumber(k)
			local nextNode = _getMemo(memo, ik or k)
			if nextNode == nil then
				if ik then
					nextNode = node:getChildByTag(ik)
				else
					nextNode = node:getChildByName(k)
				end
			end
			node, memo = _setMemo(memo, ik or k, nextNode)
			if node == nil then return end
		end
	end
	return node, memo
end

--@return 可能是cdx或者{cdx1, cdx2, ...}
local function _getChilds(node, keys, memo)
	local ret
	if type(keys) == "string" then
		return _getChild(node, keys, memo)
	else
		ret = {}
		for _, name in ipairs(keys) do
			local w = _getChild(node, name, memo)
			if w == nil then
				error('can not found child [' .. name .. '], check ui adapter config!')
			end
			table.insert(ret, w)
		end
		return ret
	end
end

--@desc 获取widget 的相关信息
local function _getWidgetInfo(widget)
	local size = widget:getContentSize()
	local x, y = widget:getPosition()
	local scaleX = widget:getScaleX()
	local scaleY = widget:getScaleY()
	local anchorPoint = widget:getAnchorPoint()
	return cc.size(size.width * scaleX, size.height * scaleY), cc.p(x,y), anchorPoint
end

-- 对齐适配
--@desc 函数不处理旋转控件
--@param widget1: cdx 中心控件为基准
--@param widgets: cdx1 or {cdx1, cdx2, ...}
--@param align: left widget1, cdx1, cdx2, ...
--				right ..., cdx2, cdx1, widget1
local function _oneLinePos(widget1, widgets, space, align)
	space = space or cc.p(0,0)
	align = align or "left"
	if not itertools.isarray(space) then
		space = {space}
	end

	local showCount = 0
	if widget1:isVisible() then
		showCount = 1
	end
	local size1, p1, anchor1 = _getWidgetInfo(widget1)

	if type(widgets) ~= "table" then
		widgets = {widgets}
	end
	for _, widget2 in ipairs(widgets) do
		if widget2:isVisible() then
			showCount = showCount + 1
			local size2, p2, anchor2 = _getWidgetInfo(widget2)
			if showCount == 1 then
				local targetX
				if align == "left" then
					targetX = p1.x - anchor1.x * size1.width + anchor2.x * size2.width
				else
					targetX = p1.x + (1 - anchor1.x) * size1.width - (1 - anchor2.x) * size2.width
				end
				widget2:setPosition(cc.p(p1.x, p2.y))
			else
				local targetX
				local curSpace = space[showCount - 1] or space[#space]
				if align == "left" then
					targetX = p1.x + curSpace.x + (1 - anchor1.x) * size1.width + anchor2.x * size2.width
				else
					targetX = p1.x - curSpace.x - anchor1.x * size1.width - (1 - anchor2.x) * size2.width
				end
				local targetY = p2.y + curSpace.y
				widget2:setPosition(cc.p(targetX, targetY))
			end
			-- next
			size1, p1, anchor1 = _getWidgetInfo(widget2)
		end
	end
end

-- 居中对齐
local function _oneLineCenter(widget1, lefts, rights, space)
	_oneLinePos(widget1, lefts, space, "right")
	_oneLinePos(widget1, rights, space, "left")
end

-- 根据给定位置居中对齐
local function _oneLineCenterPos(centerPos, widgets, space)
	space = space or cc.p(0,0)
	if type(widgets) ~= "table" then
		widgets = {widgets}
	end
	local newWidgets = {}
	for _, widget in ipairs(widgets) do
		if widget:isVisible() then
			table.insert(newWidgets, widget)
		end
	end
	widgets = newWidgets

	local len = (#widgets - 1) * space.x
	for _, widget in ipairs(widgets) do
		local size = _getWidgetInfo(widget)
		len = len + size.width
	end

	local x, y = centerPos.x - len / 2, centerPos.y
	for _, widget in ipairs(widgets) do
		local size, p, anchor = _getWidgetInfo(widget)
		widget:setPosition(cc.p(x + anchor.x * size.width, y))
		x = x + size.width + space.x
		y = y + space.y
	end
end

-- 屏幕边缘适配
-- @param checkNotchScreen nil:全面屏默认按有刘海屏的处理，true:则根据刘海屏进行处理(如战斗中心先手进度), false:不进行额外处理(如topui贴边)
local function _dockWithScreen(widget, xAlign, yAlign, checkNotchScreen, reverse)
	local flag = reverse == true and -1 or 1
	local dx, dy = 0, 0
	local function getDiffX()
		if checkNotchScreen == false or display.sizeInPixels.width < display.sizeInPixels.height * 2 then
			return 0
		end
		if yAlign == "up" or yAlign == "down" then
			if checkNotchScreen then
				return display.notchSceenSafeArea
			else
				return display.fullScreenSafeArea
			end
		else
			if checkNotchScreen then
				return display.notchSceenDiffX
			else
				return display.fullScreenDiffX
			end
		end
	end
	if xAlign == "left" then
		dx = -display.uiOriginMax.x + getDiffX()

	elseif xAlign == "right" then
		dx = display.uiOriginMax.x - getDiffX()
	end
	dx = dx * flag
	if widget then
		widget:setPositionX(widget:getPositionX() + dx)
	end

	if yAlign == "down" then
		dy = display.uiOriginMax.y
	end
	dy = dy * flag
	if widget then
		widget:setPositionY(widget:getPositionY() + dy)
	end
	return dx, dy
end

-- 中心适配，参数获得左右适配的方式
-- 扩展方式: 1、扩展多少偏移多少; 2、扩展量够整个item才扩展(是否有 itemWidth 控制)；3、进行计算适量缩放(预留)
-- @param params: {itemWidth, itemWidthExtra}
-- @param sets: {
-- 	{node1, "width"}, -- node1 自动扩展 size.width
-- 	{node2, "pos", "left"}, -- node2 位置左适配偏移
-- }
local function _centerWithScreen(xLeft, xRight, params, sets)
	params = params or {}
	sets = sets or {}
	local width = 0 -- 宽度变化量
	local left = 0 -- 左侧变化量
	local right = 0 -- 右侧变化量
	if xLeft then
		if type(xLeft) ~= "table" then
			xLeft = {xLeft}
		end
		left = _dockWithScreen(nil, unpack(xLeft, 1, table.maxn(xLeft)))
		width = width - left
	end
	if xRight then
		if type(xRight) ~= "table" then
			xRight = {xRight}
		end
		right = _dockWithScreen(nil, unpack(xRight, 1, table.maxn(xRight)))
		width = width + right
	end
	-- printInfo("centerWithScreen width(%s), left(%s), right(%s)", width, left, right)

	local count = 0 -- 若有 params.itemWidth (可额外左右偏移params.itemWidthExtra)，获得能增加的整数个
	if params.itemWidth then
		count = math.floor((width + 2 * (params.itemWidthExtra or 0)) / params.itemWidth)
		local newWidth = params.itemWidth * count
		local halfDiffWidth = (width - newWidth)/2
		left = left + halfDiffWidth
		right = right - halfDiffWidth
		width =  newWidth
		-- printInfo("centerWithScreen width(%s), left(%s), right(%s), itemWidthExtra(%s), itemWidth(%s), count(%s)"
		-- 	width, left, right, params.itemWidthExtra, params.itemWidth, count))
	end

	for _, set in ipairs(sets) do
		local widget, method, param = unpack(set)
		if method == "width" then
			local dw = width
			if type(param) == "function" then
				-- 自定义调整宽度
				dw = param(width)
			end
			if dw ~= 0 then
				local scale = widget:scale()
				local size = widget:size()
				widget:size(size.width + dw / scale, size.height)
			end

		elseif method == "pos" then
			local dx = 0
			if type(param) == "function" then
				-- 自定义调整位置
				dx = param(left, right)

			elseif param == "left" then
				dx = left

			elseif param == "right" then
				dx = right

			elseif param == "center" then
				dx = (left + right) / 2
			end
			if dx ~= 0 then
				widget:x(widget:x() + dx)
			end
		end
	end
	return width, count
end

-- setVisible等适配
-- 如果params就是table, 需要再加层{}，如：{"xx", "position", {cc.p(0, 0)}},
local function _set(widget, func, params)
	if type(params) ~= "table" then
		params = {params}
	end
	func = "set" .. string.caption(func)
	if widget[func] then
		widget[func](widget, unpack(params))
	else
		printInfo("ui adapter _set(%s) not exist!", func)
	end
end

--@desc aux for adaptUI
--@param params: {widget1, ...}
local function _auxAdaptWidgetParamsFunc(func)
	return function (parent, params, memo)
		local name1 = params[1]
		local widget1 = _getChild(parent, name1, memo)
		if widget1 == nil then
			local str = name1 .. " is nil"
			error('can not found child, check ui adapter config!\n' .. str)
		end
		-- unpack not same between lua and luajit
		-- luajit unpack until the param was nil
		func(widget1, unpack(params, 2, table.maxn(params)))
	end
end

--@desc aux for adaptUI
--@param params: {widget1, widget2, ...}
local function _auxAdapt2WidgetParamsFunc(func)
	return function (parent, params, memo)
		local name1, name2 = params[1], params[2]
		local widget1 = _getChild(parent, name1, memo)
		local widget2 = _getChilds(parent, name2, memo)
		if widget1 == nil or widget2 == nil then
			local str = (widget1 == nil and name1 or name2) .. " is nil"
			error('can not found child, check ui adapter config!\n' .. str)
		end
		func(widget1, widget2, unpack(params, 3))
	end
end

--@desc aux for adaptUI
--@param params: {widget1, widget2, widget3, ...}
local function _auxAdapt3WidgetParamsFunc(func)
	return function (parent, params, memo)
		local name1, name2, name3 = params[1], params[2], params[3]
		local widget1 = _getChild(parent, name1, memo)
		local widget2 = _getChilds(parent, name2, memo)
		local widget3 = _getChilds(parent, name3, memo)
		if widget1 == nil or widget2 == nil or widget3 == nil then
			local str = (widget1 == nil and name1 or (widget2 == nil and name2 or name3)) .. " is nil"
			error('can not found child, check ui adapter config!\n' .. str)
		end
		func(widget1, widget2, widget3, unpack(params, 4))
	end
end

--@desc aux for adaptUI
--@param params: {centerPos, widgets, ...}
local function _auxAdapt4WidgetParamsFunc(func)
	return function (parent, params, memo)
		local pos, name = params[1], params[2]
		local widget = _getChilds(parent, name, memo)
		if widget == nil then
			error('can not found child, check ui adapter config!\n' .. name .. " is nil")
		end
		func(pos, widget, unpack(params, 3))
	end
end

internalFuncMap = {
	oneLinePos = _auxAdapt2WidgetParamsFunc(_oneLinePos),
	oneLineCenter = _auxAdapt3WidgetParamsFunc(_oneLineCenter),
	oneLineCenterPos = _auxAdapt4WidgetParamsFunc(_oneLineCenterPos),
	dockWithScreen = _auxAdaptWidgetParamsFunc(_dockWithScreen),
	set = _auxAdaptWidgetParamsFunc(_set)
}

------------
-- adapt导出

local adapt = {
	oneLinePos = _oneLinePos,
	oneLineCenter = _oneLineCenter,
	oneLineCenterPos = _oneLineCenterPos,
	dockWithScreen = _dockWithScreen,
	centerWithScreen = _centerWithScreen,
}

------------
-- adaptContext导出
local adaptContext = {}


function adaptContext.clone(node, cb)
	return {node=node, cb=cb}
end

function adaptContext.noteText(startID, endID)
	return {startID=startID, endID=(endID or startID), csv=true}
end

function adaptContext.func(func, ...)
	return {func=func, params={...}}
end

function adaptContext.oneLinePos(name, other, space, align)
	return {adapt=internalFuncMap.oneLinePos, params={name, other, space, align}}
end

function adaptContext.oneLineCenter(name, lefts, rights, space)
	return {adapt=internalFuncMap.oneLineCenter, params={name, lefts, rights, space}}
end

function adaptContext.oneLineCenterPos(centerPos, others, space)
	return {adapt=internalFuncMap.oneLineCenterPos, params={centerPos, others, space}}
end

-- 将当前listView换成widget
--@desc 辅助函数，不支持链式调用
local easyEnterFuncMap = {
	oneLinePos = adaptContext.oneLinePos,
	oneLineCenter = adaptContext.oneLineCenter,
	oneLineCenterPos = adaptContext.oneLineCenterPos,
}
function adaptContext.easyEnter(name)
	return setmetatable({}, {
		__index = function (t, fname)
			local f = easyEnterFuncMap[fname]
			return function (t, ...)
				local context = f(...)
				return {enter=name, context=context}
			end
		end
	})
end

--@desc 填充规则面板，使用限制
--@param contextTable: {context,...}
--		context = {noteStartID, noteEndID}
--				= funciton
--				= {ccui.Layout, tagName or function}
--@param asyncCount: nil为一次性全部加载本函数内加载，>0值协程加载
function adaptContext.setToList(view, listView, contextTable, asyncCount, asyncOver, asyncPreloadOver)
	listView:removeAllChildren()
	local fixedWidth = listView:getContentSize().width

	local function contextHandle(curView, curMemo, context, eachCB)
		if curView == nil then
			error('curView was nil, check ui adapter context!')
		end

		local cType = type(context)
		if cType == "string" then
			local richText = rich.createWithWidth("#C0x5B545B#" .. context, nil, nil, fixedWidth)
			curView:pushBackCustomItem(richText)

		elseif cType == "function" then
			context()

		elseif cType == "table" then
			-- noteText
			if context.csv then
				for i = context.startID, context.endID do
					if csv.note[i] and csv.note[i].fmt then
						local richText = rich.createWithWidth("#C0x5B545B#" .. csv.note[i]["fmt_"..LOCAL_LANGUAGE] or csv.note[i].fmt, nil, nil, fixedWidth)
						curView:pushBackCustomItem(richText)
						eachCB()
					end
				end

			-- clone
			elseif context.node then
				local item = context.node:clone()
				item:setVisible(true)
				curView:pushBackCustomItem(item)
				if context.cb then
					context.cb(item)
				end

			-- func
			elseif context.func then
				context.func(unpack(context.params))

			-- oneLinePos
			-- oneLineCenter
			-- oneLineCenterPos
			elseif context.adapt then
				context.adapt(curView, context.params, curMemo)

			-- easyEnter
			elseif context.enter then
				local nextView, nextMemo = _getChild(curView, context.enter, curMemo)
				contextHandle(nextView, nextMemo, context.context, eachCB)
			end
		end
	end

	local function asyncFunc()
		local function yield()
			if asyncCount ~= nil then
				coroutine.yield()
			end
		end

		for _, v in ipairs(contextTable) do
			contextHandle(listView, {}, v, yield)
			yield()
		end
	end
	view:enableAsyncload()
	view:asyncFor(asyncFunc, asyncOver, asyncCount, asyncPreloadOver)
end

globals.adapt = adapt
globals.adaptContext = adaptContext
