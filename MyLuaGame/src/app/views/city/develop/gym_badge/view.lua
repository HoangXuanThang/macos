-- @Date:   2020-08-3
-- @Desc: 徽章界面
local ViewBase = cc.load("mvc").ViewBase
local gymBadgeView = class("gymBadgeView", ViewBase)

local posTable = {
	[1] ={cc.p(464, 924), cc.p(716, 924), cc.p(716, 1176), cc.p(464, 1176)},
	[2] ={cc.p(729, 714), cc.p(981, 714), cc.p(981, 966), cc.p(729, 966)},
	[3] ={cc.p(945, 455), cc.p(1197, 455), cc.p(1197, 707), cc.p(945, 707)},
	[4] ={cc.p(734, 196), cc.p(986, 196), cc.p(986, 448), cc.p(734, 448)},
	[5] ={cc.p(478, -23), cc.p(730, -23), cc.p(730, 229), cc.p(478, 229)},
	[6] ={cc.p(214, 203), cc.p(466, 203), cc.p(466, 455), cc.p(214, 455)},
	[7] ={cc.p(7, 459), cc.p(259, 459), cc.p(259, 711), cc.p(7, 711)},
	[8] ={cc.p(221, 713), cc.p(473, 713), cc.p(473, 965), cc.p(221, 965)},
	
}

local effectTable = {
	[4] = {effectName  = "huo_effect", loopName = "huo_loop", x = 603, y = 632, scale = 2, point = cc.p(0.5, 0.5)},
	[5] = {effectName  = "long_effect", loopName = "long_loop", x = 599, y = 632, scale = 2, point = cc.p(0.5, 0.5)},
	[2] = {effectName  = "shui_effect", loopName = "shui_loop", x = 599, y = 632, scale = 2, point = cc.p(0.5, 0.5)},
	[1] = {effectName  = "yan_effect", loopName = "yan_loop", x = 599, y = 632, scale = 2, point = cc.p(0.5, 0.5)},
	[3] = {effectName  = "cao_effect", loopName = "cao_loop", x = 599, y = 632, scale = 2, point = cc.p(0.5, 0.5)},
	[6] = {effectName  = "e_effect", loopName = "e_loop", x = 597, y = 630, scale = 2, point = cc.p(0.5, 0.5)},
	[8] = {effectName  = "yao_effect", loopName = "yao_loop", x = 599, y = 632, scale = 2, point = cc.p(0.5, 0.5)},
	[7] = {effectName  = "du_effect", loopName = "du_loop", x = 597, y = 629, scale = 2, point = cc.p(0, 0)},
}

gymBadgeView.RESOURCE_FILENAME = "gym_badge.json"
gymBadgeView.RESOURCE_BINDING = {
	["centerPanel"] = "centerPanel",
	-- ["centerPanel.bgBtn"] = "badge",
	["bg"] = "bg",
	["rule"] = "rule",
	["centerPanel.bg"] = "badge",
	["gymBtn"] = {
		varname = "gymBtn",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onGym")}
		},
	},
	["rule"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onShowRule")}
		},
	},
	["rule.text"] = {
		binds = {
			event = "effect",
			data = {outline={color = ui.NEWCOLORS.OUTLINE.BLACK, size = 4}},
		}
	},
	["gymBtn.text"] = {
		binds = {
			event = "effect",
			data = {outline={color = ui.NEWCOLORS.OUTLINE.YELLOW, size = 4}},
		}
	},
}

function gymBadgeView:onCreate()
	self:initModel()
	adapt.centerWithScreen("left", "right", nil, {
		{self.rule, "pos", "left"},
		{self.gymBtn, "pos", "right"},
	})
	--是否在当前界面
	self.isView = idler.new(true)
	gGameUI.topuiManager:createView("default", self, {onClose = self:createHandler("onClose")})
		:init({title = gLanguageCsv.badgeTitle, subTitle = "GYMBADGE"})
	for i = 1, 8 do
		self.centerPanel:get("name"..i):setColor(cc.c3b(128, 128, 128))
	end
	--之前徽章开启状态
	self.lastBadge = userDefault.getForeverLocalKey("gymBadge", {})
	userDefault.setForeverLocalKey("gymBadge")
	-- 现在徽章开启的状态
	self.nowBadge = {}
	--徽章开启的状态
	local hasData = false
	idlereasy.any({self.badges, self.isView}, function(_, badges, isView)
		for k, v in orderCsvPairs(csv.gym_badge.badge) do
			if v.preBadgeID then
				local preBadgeData = badges and badges[v.preBadgeID] or {}

				if v.preBadgeType == 1 then
					local awake = preBadgeData.awake or 0
					if awake >= v.preLevel then
						self.nowBadge[k] = 1
					end
				else
					local index = csv.gym_badge.badge[v.preBadgeID].talentIDs[6]
					local talents = badges[v.preBadgeID] and badges[v.preBadgeID].talents
					local talent = talents and talents[index] or 0
					if talent >= v.preLevel then
						self.nowBadge[k] = 1
					end
				end
			else
				--没有前置
				self.nowBadge[k] = 1
				if badges[k] then
					hasData = true
				end
			end
		end
	end)
	if hasData then
		self.lastBadge = clone(self.nowBadge)
	end

	self:playLoopEff()
	idlereasy.when(self.isView, function(_, isView)
		if isView then
			self:playEffect()
		end
	end)
	self.centerPanel:onTouch(functools.partial(self.showBadge, self))
end

function gymBadgeView:initModel()
	self.badges = gGameModel.role:getIdler("badges")
end

function gymBadgeView:onGym()
	jumpEasy.jumpTo("gymChallenge")
end

function gymBadgeView:showBadge(event)
	local pos = event.target:convertToNodeSpace(event)
	if event.name == "began" then
		self.touchIndex = dataEasy.checkInRect(posTable, pos)
		if self.touchIndex then
			if self.centerPanel:getChildByName("spine"..self.touchIndex) then
				self.centerPanel:getChildByName("spine"..self.touchIndex):scale(2.3)
			else
				self.centerPanel:get("name"..self.touchIndex):scale(0.9)
			end
		end
	elseif (event.name == "ended" or event.name == "cancelled") then
		if self.touchIndex == nil then
			return
		end
		if self.centerPanel:getChildByName("spine"..self.touchIndex) then
			self.centerPanel:getChildByName("spine"..self.touchIndex):scale(2.5)
		else
			self.centerPanel:get("name"..self.touchIndex):scale(1)
		end
		if self.touchIndex == dataEasy.checkInRect(posTable, pos) then
			if self.nowBadge[self.touchIndex] == 1 then
				self.isView:set(false)
				gGameUI:stackUI("city.develop.gym_badge.talent", nil, {full = true}, {badgeNumb = self.touchIndex, isView = self.isView})
			else
				self:showUnlockTips(self.touchIndex)
			end
		end
	end
end

function gymBadgeView:showUnlockTips(badgeNumb)
	local csvBadge = csv.gym_badge.badge
	local preBadgeID = csvBadge[badgeNumb].preBadgeID
	local preBadgeType = csvBadge[badgeNumb].preBadgeType
	if preBadgeType == 1 then
		gGameUI:showTip(string.format(gLanguageCsv.noOpenPleaseToGymView1, csvBadge[preBadgeID].name,csvBadge[badgeNumb].preLevel))
	else
		gGameUI:showTip(string.format(gLanguageCsv.noOpenPleaseToGymView2, csvBadge[preBadgeID].name,csvBadge[badgeNumb].preLevel))
	end
end

-- 显示规则文本
function gymBadgeView:onShowRule()
	gGameUI:stackUI("common.rule", nil, nil, self:createHandler("getRuleContext"), {width = 1000})
end

function gymBadgeView:getRuleContext(view)
	local c = adaptContext
	local context = {
		c.clone(view.title, function(item)
			item:get("text"):text(gLanguageCsv.badgeExplain)
		end),
		c.noteText(111001, 111011),
	}
	return context
end
-- 播放解锁动画
function gymBadgeView:playEffect()
	-- 动画过程中限制进入徽章升级界面(音效问题)，点击加速播放
	if not self.maskPanel then
		self.maskPanel = ccui.Layout:create()
			:size(display.sizeInView)
			:x(-display.uiOrigin.x)
			:addTo(self, 99999, "maskPanel")
		self.maskPanel:setTouchEnabled(true)
		self.maskPanel:onClick(function()
			self:stopAllActions()
			self:handlerShowItem(0.1)
		end)
	end
	self.maskPanel:show()
	self.aniIndex = 1
	self.aniData = {}
	for k, v in  ipairs(csv.gym_badge.badge) do
		if self.lastBadge[k] ~= 1 and self.nowBadge[k] == 1 then
			table.insert(self.aniData, {id = k})
		end
	end
	self:handlerShowItem(2)
	userDefault.setForeverLocalKey("gymBadge", self.nowBadge)
end

function gymBadgeView:handlerShowItem(aniDelay)
	local index = self.aniIndex
	local data = self.aniData[index]
	if not data then
		self.maskPanel:hide()
		return
	end
	local delay = index == 1 and 0.1 or aniDelay
	performWithDelay(self, function()
		local k = data.id
		self.lastBadge[k] = 1
		local x, y = self.centerPanel:get("name"..k):xy()
		local spine = widget.addAnimationByKey(self.centerPanel, "daoguanhuizhang/dghz.skel", "spine"..k, effectTable[k].effectName, 100)
			:xy(x,y)
			:scale(2.5)
		spine:setSpriteEventHandler(function(event, eventArgs)
			spine:setSpriteEventHandler(nil, sp.EventType.ANIMATION_COMPLETE)
			spine:play(effectTable[k].loopName)
			self.centerPanel:get("name"..k):hide()
		end, sp.EventType.ANIMATION_COMPLETE)

		self.aniIndex = self.aniIndex + 1
		self:handlerShowItem(aniDelay)
	end, delay)
end

--播放已解锁循环动画
function gymBadgeView:playLoopEff()
	for k, v in  ipairs(csv.gym_badge.badge) do
		if self.lastBadge[k] == 1 then
			local x, y = self.centerPanel:get("name"..k):xy()
			local spine = widget.addAnimationByKey(self.centerPanel, "daoguanhuizhang/dghz.skel", "spine"..k, effectTable[k].loopName, 100)
				:xy(x,y)
				:scale(2.5)
			self.centerPanel:get("name"..k):hide()
		end
	end
end

function gymBadgeView:onCleanup()
	if self.maskPanel then
		self.maskPanel:removeFromParent()
		self.maskPanel = nil
	end
	ViewBase.onCleanup(self)
end

return gymBadgeView