-- @desc: 公告

local SHOW_TYPE = {
	PAGE = 1,
	DROP_DOWN = 2,
}

local LoginPlacardView = {}
LoginPlacardView.__index = LoginPlacardView

LoginPlacardView.RESOURCE_FILENAME = "login_placard.json"
LoginPlacardView.RESOURCE_BINDING = {
	["leftPanel.item"] = "leftItem",
	["leftPanel.leftList"] = {
		varname = "leftList",
	},
	["rightList"] = "contentList",
	["rightContentList"] = "rightContentList",
	["bottomPanel.icon"] = {
		varname = "checkStatus",
	},
	["bottomPanel.tip"] = {
		varname = "bottomTip",
	},
	["topBg"] = "topBg",
	["titleItem"] = "titleItem",
	["contentItem"] = "contentItem",
	["leftPanel"] = "leftPanel",
}

local function showLoginPlacard(notice)
	local loginPlacardView = {}
	setmetatable(loginPlacardView, LoginPlacardView)

	local node = ccs.GUIReader:getInstance():widgetFromJsonFile(loginPlacardView.RESOURCE_FILENAME)
	loginPlacardView.node = node
	for key, name in pairs(loginPlacardView.RESOURCE_BINDING) do
		if type(name) == "table" then
			if name.varname then
				loginPlacardView[name.varname] = nodetools.get(node, key)
			end
		else
			loginPlacardView[name] = nodetools.get(node, key)
		end
	end

	loginPlacardView.leftList:setScrollBarEnabled(false)
	nodetools.get(node, "leftPanel.item"):setVisible(false)
	nodetools.get(node, "topBg"):setVisible(false)
	nodetools.get(node, "titleItem"):setVisible(false)
	nodetools.get(node, "contentItem"):setVisible(false)

	nodetools.get(node, "bottomPanel.btnKnow"):onClick(function()
		loginPlacardView:onClose()
	end)
	loginPlacardView.checkStatus:onClick(function()
		loginPlacardView:onCheckBox()
	end)
	loginPlacardView.bottomTip:onClick(function()
		loginPlacardView:onCheckBox()
	end)

	loginPlacardView:onCreate(notice)

	loginPlacardView.bottomTip:setString(Language.notRemindMe)
	nodetools.get(node, "bottomPanel.btnKnow.txt"):setString(Language.ok)
	nodetools.get(node,"bottomPanel.icon"):setPositionX(660)
	nodetools.get(node,"bottomPanel.tip"):setPositionX(700)

	return loginPlacardView
end

local function addTabListClipping(list, parent, params)
	params = params or {}
	local mask = params.mask or "common/box/mask_tab.png"
	list:retain()
	list:removeFromParent()
	local size = list:getContentSize()
	local rect = params.rect or cc.rect(59, 1, 1, 1)
	local maskS = ccui.Scale9Sprite:create()
	local offsetX = params.offsetX or 0
	local offsetY = params.offsetY or 0
	maskS:initWithFile(rect, mask)
	maskS:setContentSize(size)
	maskS:setAnchorPoint(cc.p(0, 0))
	maskS:setPosition(cc.p(list:getPositionX()+offsetX, list:getPositionY()+offsetY))
	local clippingNode = cc.ClippingNode:create(maskS)
	clippingNode:setAlphaThreshold(0.1)
	clippingNode:addChild(list)
	parent:addChild(clippingNode, list:getLocalZOrder())
	list:release()
end

function LoginPlacardView:onCreate(notice)
	self.bottomTip:setTouchEnabled(true)
		--重新组装一遍数据
	local data = {
		[1] = {
			styleType = SHOW_TYPE.DROP_DOWN,
			name = Language.placardActivity,
			content = notice.activity,
		},
		[2] = {
			styleType = SHOW_TYPE.PAGE,
			name = Language.placardUpdate,
			content = notice.update,
		}
	}
	self.content = self.node

	self.contentList:setScrollBarEnabled(false)
	self.rightContentList:setScrollBarEnabled(false)
	self.data = data
	self.banner = notice.banner
	self:initData()
	self:onChooseArea(self.leftList, 1, self.areaList[1])

	addTabListClipping(self.leftList, self.leftPanel)
end

function LoginPlacardView:onClose()
	self.node:removeFromParent()
end

function LoginPlacardView:onItem(list, k, v)
	local node = v.item
	local normal = node:getChildByName("normal")
	local selected = node:getChildByName("selected")
	local panel
	if v.select then
		normal:setVisible(false)
		panel = selected
		panel:setVisible(true)
		text.addEffect(panel:getChildByName("txt"), {glow = {color = ui.COLORS.GLOW.WHITE}})
	else
		selected:setVisible(false)
		panel = normal
		panel:setVisible(true)
	end
	panel:getChildByName("txt"):setString(v.name)
	node:onClick(function()
		self:onChooseArea(list, k, v)
	end)
end

function LoginPlacardView:onChooseArea(list, key, val, event)
	if self.showTab then
		self.areaList[self.showTab].select = false
		self:onItem(list, self.showTab, self.areaList[self.showTab])
	end
	self.showTab = key
	self.areaList[self.showTab].select = true
	self:onItem(list, self.showTab, val)
	self:showContent(self.data[key])
end

function LoginPlacardView:onChooseImg(list, key, val, event)
	print("click choose placard img!")
end

function LoginPlacardView:onCheckBox()
	self.checkStatusVisible = not self.checkStatusVisible
	local currTime = os.date("%Y%m%d", os.time())
	userDefault.setForeverLocalKey("placardStatusDay", {[currTime] = self.checkStatusVisible}, {rawKey = true})
	self.checkStatus:loadTexture(self.checkStatusVisible and "common/icon/radio_selected.png" or "common/icon/radio_normal.png")
end

function LoginPlacardView:initData()
	local currTime = os.date("%Y%m%d", os.time())
	local data = userDefault.getForeverLocalKey("placardStatusDay", {}, {rawKey = true, rawData = true})
	-- nil 首次登录为勾选状态
	self.checkStatusVisible = data[currTime] ~= false
	userDefault.setForeverLocalKey("placardStatusDay", {[currTime] = self.checkStatusVisible}, {rawKey = true})
	self.checkStatus:loadTexture(self.checkStatusVisible and "common/icon/radio_selected.png" or "common/icon/radio_normal.png")
	self:topInit()

	self.selected = 2
	local areaList = {}
	-- 公告条数
	local count = #self.data
	for i = 1, count do
		local value = {
			iconRes = self.selected == i and "common/box/tab_s.png" or "common/box/tab_n.png",
			name = self.data[i].name,
			effects = {
				['color'] = ui.COLORS.NORMAL.WHITE,
				['outline'] = self.selected == i and {color = ui.COLORS.OUTLINE.ORANGE} or {color = ui.COLORS.OUTLINE.DEFAULT},
			}
		}
		local item = self.leftItem:clone()
		item:show()
		value.item = item
		self.leftList:pushBackCustomItem(item)
		table.insert(areaList, value)
		self:onItem(self.leftList, i, value)
	end
	self.areaList = areaList
	self.leftListCount = count

	-- 先显示第一个内容
	self:showContent(self.data[self.selected])
end

function LoginPlacardView:topInit()
	local iconRes = self.banner
	local realSize = self.topBg:getContentSize()
	local size = self.topBg:getBoundingBox()
	local topBgPosx, topBgPosy = self.topBg:getPosition()
	local rect = cc.rect(29, 42, 1, 1)
	local sp = ccui.ImageView:create("login/img_banner_01@.png")
	sp:setScale(2)
	sp:setPosition(cc.p(size.width/2, size.height/2))
	local priorSp = sp:clone()
	priorSp:setPositionX(- size.width/2)
	local nextSp = sp:clone()
	nextSp:setPositionX(1.5*size.width)

	local mask = ccui.Scale9Sprite:create()
	mask:initWithFile(rect, "login/box_mask_banner.png")
	mask:setContentSize(realSize.width * 2, realSize.height * 2)
	mask:setPosition(cc.p(size.width/2, size.height/2))
	local clipNode = cc.ClippingNode:create(mask)
	clipNode:setAlphaThreshold(0.01)
	clipNode:addChild(sp)
	clipNode:addChild(priorSp)
	clipNode:addChild(nextSp)
	clipNode:setPosition(cc.p(topBgPosx - size.width/2, topBgPosy - size.height/2))
	self.content:addChild(clipNode, self.topBg:getLocalZOrder() + 1)

	local index = 0
	local _playAction = function(dt, nextIndex)
		index = nextIndex and index + nextIndex or index + 1
		index = index > #iconRes and 1 or index
		index = index < 1 and #iconRes or index
		sp:loadTexture(iconRes[index])
		local pIndex = index > 1 and index - 1 or #iconRes
		priorSp:loadTexture(iconRes[pIndex])
		local nIndex = index < #iconRes and index + 1 or 1
		nextSp:loadTexture(iconRes[nIndex])
	end
	_playAction()

	local dt = 3
	-- 间隔dt时间更换一次图片
	self.node:runAction(cc.RepeatForever:create(cc.Sequence:create(cc.DelayTime:create(dt), cc.CallFunc:create(_playAction))))

	local time = 0
	local function timeAdd(dt)
		time = time + dt
	end
	local spx = sp:getPositionX()
	local priorSpx = priorSp:getPositionX()
	local nextSpx = nextSp:getPositionX()
	-- 如果移动的位置超过某个值的时候就切换下一张图片
	local offsetX = 0
	local beganPosX = 0
	sp:setTouchEnabled(true)
	sp:addTouchEventListener(function(sender, eventType)
		-- 在文件开始的时候记录下图片的位置，一般也只需要移动y就可以了
		if eventType == ccui.TouchEventType.began then
			local beganPos = sender:getTouchBeganPosition()
			self.node:stopAllActions()
			time = 0
			self.node:runAction(cc.RepeatForever:create(cc.Sequence:create(cc.DelayTime:create(0.1), cc.CallFunc:create(function()
				timeAdd(0.1)
			end))))
			beganPosX = beganPos.x
		elseif eventType == ccui.TouchEventType.moved then
			local movedPos = sender:getTouchMovePosition()
			offsetX = beganPosX - movedPos.x
			sp:setPositionX(spx - offsetX)
			priorSp:setPositionX(priorSpx - offsetX)
			nextSp:setPositionX(nextSpx - offsetX)
		elseif eventType == ccui.TouchEventType.ended or eventType == ccui.TouchEventType.canceled then
			-- 下一张图片
			self.node:stopAllActions()
			if offsetX >= size.width/2 or offsetX / time > 3000 then
				_playAction(dt, 1)
			-- 上一张图片
			elseif offsetX <= -size.width/2 or offsetX / time <= -3000 then
				_playAction(dt, -1)
				-- print(offsetX, "上一张图片")

			-- 保持本张图片不变
			-- else
			-- 	print(offsetX, "保持不变", spx, beganPosX, offsetX)
			end
			priorSp:setPositionX(priorSpx)
			nextSp:setPositionX(nextSpx)
			sp:setPositionX(spx)

			self.node:runAction(cc.RepeatForever:create(cc.Sequence:create(cc.DelayTime:create(dt), cc.CallFunc:create(_playAction))))
		end
	end)
end

-- 设置content内容, 分两种显示格式: 整页式 和 下拉式, 样式类型设置到data数据中,记录传入时补充上
function LoginPlacardView:showContent(data)
	data = data or {}
	local styleType = data.styleType
	self.contentList:setVisible(styleType == SHOW_TYPE.PAGE)
	self.rightContentList:setVisible(styleType ~= SHOW_TYPE.PAGE)
	if styleType == SHOW_TYPE.PAGE then 		-- 整页式
		self:setStyle1List(data.content)
	else						-- 下拉式
		if not self.initState then
			self:setStyle2List(data.content)
		end
	end
end

function LoginPlacardView:setStyle1List(contents)
	if not contents then return end
	local list = self.contentList
	list:removeAllChildren()
	local listWidth = list:getContentSize().width*0.8	-- 这种样式下, 显示的文字与右边缘之间留有一点空间
	local item = self.titleItem
	list:setItemsMargin(30)
	for _, content in ipairs(contents) do
		local cloneItem = item:clone()		-- 标题
		cloneItem:getChildByName("title"):setString(content.title)
		list:pushBackCustomItem(cloneItem)
		cloneItem:setVisible(true)
		-- 内容
		local richtext = rich.createWithWidth("            #C0x55504D#" .. content.content, 40, deltaSize, listWidth)
		list:pushBackCustomItem(richtext)
	end
end

function LoginPlacardView:setStyle2List(contents)
	if not contents then return end
	self.initState = true
	local list = self.rightContentList
	list:removeAllChildren()
	list:setItemsMargin(10)
	local item = self.contentItem
	local originalSize = item:getContentSize()
	local kuangWidth = item:getChildByName("downList"):getContentSize().width		--下拉区域的框宽度
	list.curItem = nil

	--
	local newSetting = {}
	local cloneOneItem
	local clickFunc

	-- clone and 设置信息
	cloneOneItem = function(idx)
		idx = idx or (list.curItem and list.curItem.idx)
		if not idx then return end
		local id = contents[idx].id
		local cloneItem = item:clone()
		cloneItem:setLocalZOrder(idx)
		cloneItem:getChildByName("title"):setString(contents[idx].titlebar)
		cloneItem.idx = idx
		cloneItem:getChildByName("tag"):setVisible(not newSetting[id])
		cloneItem.isDropDown = false
		cloneItem:getChildByName("bg"):onClick(function()
			clickFunc(cloneItem)
		end)
		return cloneItem
	end

	-- 点击
	clickFunc = function(clickedItem)
		-- 创建带有下拉的
		local idx = clickedItem.idx
		local id = contents[idx].id
		newSetting[id] = true
		userDefault.setForeverLocalKey("placardNews", {[id] = true}, {rawKey = true})

		local newItem = cloneOneItem(idx)	-- 创建一个带有常规显示内容item
		local kuangHeight = 100				-- 下拉框的高度, 需要根据text内容来变化
		if not clickedItem.isDropDown then	-- 给item增加下拉的内容显示
			-- 设置下拉后显示的内容
			local kuang = newItem:getChildByName("downList")
			local function addItem(v)
				local item = self.titleItem:clone()
				item:getChildByName("title"):setString(v.title)
				item:setAnchorPoint(cc.p(0, 1))
				kuangHeight = kuangHeight + item:getContentSize().height + 30
				item:setVisible(true)
				local richtext = rich.createWithWidth("#C0x55504D#" .. v.content, 40, deltaSize, kuangWidth - 40)	-- richText 内容(目前暂时只设置了文本的)
				local textSize = richtext:getContentSize()
				richtext:setAnchorPoint(cc.p(0, 1))
				kuangHeight = kuangHeight + textSize.height --+30*2+30*2 + 40
				richtext:setPosition(cc.p(15, kuangHeight - 120))
				item:setPosition(cc.p(10, kuangHeight - 40))
				kuang:addChild(richtext)
				kuang:addChild(item)
			end

			local strs = contents[idx].content
			local flag = false
			for i = #strs, 1, -1 do
				-- 先找有没有指定渠道的内容
				local v = strs[i]
				if v.channel == APP_CHANNEL then
					addItem(v)
					flag = true
				end
			end
			-- 没有指定渠道的内容，则显示渠道为空的内容
			if not flag then
				for i = #strs, 1, -1 do
					local v = strs[i]
					if not v.channel then
						addItem(v)
					end
				end
			end
			kuang:setContentSize(cc.size(kuangWidth - 40, kuangHeight))
			kuang:setVisible(true)
			newItem.isDropDown = true
			newItem:getChildByName("btn"):setRotation(180)
		end
		-- 创建一个容器放置 newItem
		local layout =  ccui.Layout:create()
		local newHeight = originalSize.height + (kuangHeight > 0 and kuangHeight - 100 or 0)		-- 需要减去上面压住的30像素
		layout:setContentSize(cc.size(originalSize.width, newHeight))
		layout:setAnchorPoint(cc.p(0.5, 0.5))
		layout:addChild(newItem)
		newItem:setPosition(cc.p(newItem:getContentSize().width/2, newHeight - 44))
		newItem:setVisible(true)
		-- 先删除, 再添加(这个顺序从0开始的)
		list:removeItem(idx-1)
		list:insertCustomItem(layout, idx-1)

		list.curItem = newItem

		list:jumpToItem(idx-1, cc.p(0,1), cc.p(0,1))
	end
	list.total = #contents
	-- 初次加item
	local setting = userDefault.getForeverLocalKey("placardNews", {}, {rawKey = true})
	for i, content in ipairs(contents) do
		newSetting[content.id] = setting[content.id]
		local cloneItem = cloneOneItem(i)
		cloneItem:setTouchEnabled(true)
		cloneItem:setVisible(true)
		list:pushBackCustomItem(cloneItem)
		if i == 1 then
			clickFunc(cloneItem)
		end
	end
	userDefault.setForeverLocalKey("placardNews", newSetting, {new = true, rawKey = true})
end

return showLoginPlacard