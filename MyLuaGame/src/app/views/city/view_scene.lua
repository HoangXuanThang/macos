-- 主城 - 界面精灵建筑子模块
local CityView = {}
-- 定时器tag集合，防止重复
local SCHEDULE_TAG = {
	sceneSet = 1,
	cityMan = 2,
	mysteryShop = 3,
}

local SCENE_Z_ORDER = {
	ORDER_BG = 1,
	ORDER_MYSTERY_SHOP_ENTRANCE = 2,
	ORDER_ROLE = 3,
	ORDER_FG = 10,
}

local SCENE_SPINE = {
	[1] = {
		res = "main_city/zhujiemian.skel",
		fgRes = "main_city/qianjing.skel",
		name = "defalult",
		scale = 1.8
	}
}

local function getSpineCfg(name)
	for _, v in ipairs(SCENE_SPINE) do
		if v.name == name then
			return v
		end
	end
	return getSpineCfg("defalult")
end

local function showSpriteArea(panel, type, color, opacity)
	do return end
	if device.platform == "windows" then
		panel:setBackGroundColorType(type)
		panel:setBackGroundColor(color)
		panel:setBackGroundColorOpacity(opacity)
	end
end

function CityView:initFereHouse()
	self.fereHouse = self.bgPanel:getChildByName("fereHouse")
	if self.fereHouse == nil then
		self.fereHouse = ccui.Layout:create():setTouchEnabled(true):addTo(self.bgPanel, 20, "fereHouse"):xy(380, 660)
		self.fereHouse:size(520, 500)

		showSpriteArea(self.fereHouse, 1, cc.c3b(200, 0, 0), 100)

		bind.click(self, self.fereHouse, {
			method = function()
				gGameUI:stackUI("city.house.fereHouse", nil, { full = true })
			end
		})
	end
end

function CityView:initSceneBgPanel(sceneName)
	self.bgPanel:setScrollBarEnabled(false)
	self.bgPanel:setInnerContainerSize(cc.size(4300, 1440))
	local innerSize = self.bgPanel:getInnerContainerSize()
	local sizeInViewRect = display.sizeInViewRect
	self.bgPanel:size(sizeInViewRect):x(sizeInViewRect.x)

	self.sceneConfig = getSpineCfg(sceneName)
	self.sceneBgSpine = widget.addAnimationByKey(self.bgPanel, self.sceneConfig.res, self.sceneConfig.name .. "_bg",
			"default",
			SCENE_Z_ORDER.ORDER_BG, true)
		:alignCenter(innerSize)
		:scale(self.sceneConfig.scale)
	self.sceneFgSpine = widget.addAnimationByKey(self.bgPanel, self.sceneConfig.fgRes, self.sceneConfig.name .. "fg",
			"default",
			SCENE_Z_ORDER.ORDER_FG, true)
		:alignCenter(innerSize)
		:scale(self.sceneConfig.scale)
end

function CityView:showRoleSpeak(parent, fereId, box)
	-- 不知道送的那个表的 2025年3月6日
	-- gGameApp:requestServer("/game/lover/award", function(tb)
	-- 	if tb and tb.view then
	-- 		gGameUI:showGainDisplay(tb)
	-- 	end
	-- end, fereId)
	local cfg = csv.banlvxiaowu[fereId]
	local content = {}
	for i = 1, 3 do
		local str = cfg["chattext" .. i]
		if not str or str == "" then
			break
		end
		table.insert(content, str)
	end
	local speakText = content[math.random(1, #content)]
	local width = 240
	local txt = rich.createWithWidth("#C0x5b545b#" .. speakText, 40, nil, width)
		:anchorPoint(0.5, 0)
		:xy(box.width / 2 + cfg.chtaTextConfig.x, box.height + 40 + cfg.chtaTextConfig.y)
		:addTo(parent, 3, "talkContent")
	local size = txt:size()
	local bg = ccui.Scale9Sprite:create()
	bg:initWithFile(cc.rect(75, 59, 1, 1), "city/gate/bg_dialog.png")
	bg:size(size.width + 60, size.height + 60)
		:anchorPoint(0.5, 0)
		:xy(box.width / 2 + cfg.chtaTextConfig.x, box.height + cfg.chtaTextConfig.y)
		:scaleX(cfg.chtaTextConfig.scale)
		:addTo(parent, 1, "talkBg")
	parent:setTouchEnabled(false)
	performWithDelay(parent, function()
		parent:removeChildByName("talkContent")
		parent:removeChildByName("talkBg")
		parent:setTouchEnabled(true)
	end, 2)
end

function CityView:initFereHouseRoles(houseLovers)
	for fereId, _ in pairs(houseLovers) do
		local fereRoleConfig = csv.banlvxiaowu[fereId].roleConfig
		local name = "fereHouse_" .. fereId
		local panel = self.bgPanel:getChildByName(name)
		if not panel then
			panel = ccui.Layout:create()
				:setTouchEnabled(true)
				:addTo(self.bgPanel, SCENE_Z_ORDER.ORDER_ROLE, name)
			local scale = self.sceneConfig.scale
			local res = "main_city/my_spine" .. fereId .. ".skel"
			local spine = widget.addAnimationByKey(panel, res, name, "default", 1, true):scale(scale)
			local box = spine:box()
			spine:xy(box.width / 2 * scale, box.height / 2 * scale - fereRoleConfig.offsety)
			panel:size(box.width * scale, box.height * scale)
				:xy(fereRoleConfig.x + box.width / 2 * (1 - scale),
					fereRoleConfig.y - box.height / 2 * scale + fereRoleConfig.offsety)
			showSpriteArea(panel, 1, cc.c3b(200, 0, 0), 100)
			bind.click(self, panel, {
				method = function()
					self:showRoleSpeak(panel, fereId, box)
				end
			})
		end
	end
end

function CityView:initSceneIdler()
	self.sceneName = idler.new("default")
	idlereasy.when(self.sceneName, function(_, sceneName)
		self:initSceneBgPanel(sceneName)
	end)
	-- self.houseLovers = gGameModel.role:getIdler("house_lovers")
	-- idlereasy.when(self.houseLovers, function(_, houseLovers)
	-- 	self:initFereHouseRoles(houseLovers)
	-- end)
	idlereasy.when(self.level, function(obj, level)
		self:dailyAssistantTip()
	end)
end

function CityView:initSceneData()
	self:initSceneIdler()
	self:initMysteryShop()
	self:initFereHouse()
end

function CityView:dailyAssistantTip()
	if not dataEasy.isShow("dailyAssistant") then
		return
	end
	local panel = self.bgPanel:getChildByName("dailyAssistantPanel")
	if panel == nil then
		panel = ccui.Layout:create():setTouchEnabled(true):addTo(self.bgPanel, 20, "dailyAssistantPanel"):xy(1150, 800)

		local scale = 1
		local aniRes = "richangzhushou/richangzhushou.json"
		local key = "richangzhushou"
		local action = "default"

		local spine = widget.addAnimationByKey(panel, aniRes, key, action, 1, true):scale(scale)
		local box = spine:box()
		spine:xy(box.width / 2, box.height / 2 + 20)
		panel:size(box.width * scale, box.height * scale)

		showSpriteArea(panel, 1, cc.c3b(200, 0, 0), 100)

		bind.click(self, panel, {
			method = function()
				jumpEasy.jumpTo("dailyAssistant")
			end
		})
		bind.extend(self, panel, {
			class = "red_hint",
			props = {
				specialTag = "dailyAssistant",
				onNode = function(node)
					node:xy(box.width - 10, box.height + 20)
					node:scale(0.8)
				end,
			}
		})

		local tipDatas = {}
		for i = 1, math.huge do
			local tip = gLanguageCsv["dailyAssistantShowTips" .. i]
			if tip == nil then
				break
			end
			table.insert(tipDatas, tip)
		end
		local offPos = { x = 250, y = 0 }
		local function showTip()
			local redHint = panel:getChildByName("_redHint_")
			if not redHint or (not redHint:visible()) then
				return
			end
			local idx = math.random(1, #tipDatas)
			-- 添加对话气泡
			local txt = rich.createByStr("#C0x5b545b#" .. tipDatas[idx], 40)
				:anchorPoint(0.5, 0)
				:xy(box.width / 2 + offPos.x, box.height + 40 + offPos.y)
				:addTo(panel, 3, "talkContent")
				:formatText()
			local size = txt:size()
			local bg = ccui.Scale9Sprite:create()
			bg:initWithFile(cc.rect(75, 59, 1, 1), "city/gate/bg_dialog.png")
			bg:size(size.width + 60, size.height + 60)
				:anchorPoint(0.5, 0)
				:xy(box.width / 2 + offPos.x, box.height + offPos.y)
				:scaleX(-1)
				:addTo(panel, 2, "talkBg")
			performWithDelay(panel, function()
				panel:removeChildByName("talkContent")
				panel:removeChildByName("talkBg")
			end, 2)
		end
		local animate = cc.Sequence:create(cc.DelayTime:create(8), cc.CallFunc:create(function()
			showTip()
		end))
		local action = cc.RepeatForever:create(animate)
		panel:runAction(action)
	end
	panel:visible(dataEasy.isShow("dailyAssistant"))
	self.dailyAssistantPanel = panel
end

function CityView:initMysteryShop()
	self:unSchedule(SCHEDULE_TAG.mysteryShop)
	self.mystery = self.bgPanel:getChildByName("steryShop")
	if not self.mystery then
		self.mystery = ccui.ImageView:create("city/shop/mystery_shop/entrance.png")
			:addTo(self.bgPanel, SCENE_Z_ORDER.ORDER_MYSTERY_SHOP_ENTRANCE, "steryShop")
			:setTouchEnabled(true)
			:scale(self.sceneConfig.scale)
			:xy(3955, 590):opacity(0)
		bind.click(self, self.mystery, {
			method = function()
				if self.mystery:getOpacity() == 255 then
					gGameApp:requestServer("/game/mystery/get", function()
						gGameUI:stackUI("city.mystery_shop.view", nil, { full = true })
					end)
				else
					gGameUI:showTip(gLanguageCsv.shenmishangdian)
				end
			end
		})
	end
	self:schedule(function()
		if self.mystery then
			if uiEasy.isOpenMystertShop() then
				self.mystery:opacity(255)
			else
				self.mystery:opacity(0)
			end
		end
	end, 1, 0, SCHEDULE_TAG.mysteryShop)
end

return function(cls)
	for k, v in pairs(CityView) do
		cls[k] = v
	end
end
