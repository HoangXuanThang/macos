-- 弹窗引导礼包

local ActivityGuideGift = class("ActivityGuideGift", Dialog)

ActivityGuideGift.RESOURCE_FILENAME = "activity_guide_gift.json"
ActivityGuideGift.RESOURCE_BINDING = {
	["btnClose"] = {
		varname = "btnClose",
		binds = {
			event = "touch",
			methods = {
				ended = bindHelper.self("onClose")
			}
		}
	},
	["buyBtn"] = {
		varname = "btnBuy",
		binds = {
			event = "touch",
			methods = { ended = bindHelper.self("onBuyClick") }
		},
	},
	["list"] = "list",
	["PanelBtn"] = "privilegePanel",
	["labTime"] = "textTime",
	["PanelBtn.leftBtn"] = {
		varname = "btnLeft",
		binds = {
			event = "touch",
			methods = { ended = bindHelper.self("onPrivilegeLeftBtnClick") }
		},
	},
	["PanelBtn.rightBtn"] = {
		varname = "btnRight",
		binds = {
			event = "touch",
			methods = { ended = bindHelper.self("onPrivilegeRightBtnClick") }
		},
	},
	["PanelPrice"] = "PanelPrice",
	["PanelPrice.checkBox1"] = {
		varname = "checkBox1",
		binds = {
			event = "touch",
			methods = {
				ended = bindHelper.defer(function(view)
					view:onSelTargetPos(1)
				end)
			}
		},
	},
	["PanelPrice.checkBox2"] = {
		varname = "checkBox2",
		binds = {
			event = "touch",
			methods = {
				ended = bindHelper.defer(function(view)
					view:onSelTargetPos(2)
				end)
			}
		},
	},
	["PanelPrice.checkBox3"] = {
		varname = "checkBox3",
		binds = {
			event = "touch",
			methods = {
				ended = bindHelper.defer(function(view)
					view:onSelTargetPos(3)
				end)
			}
		},
	},
	["leftPanel"] = {
		binds = {
			event = "click",
			method = bindHelper.self("onCheckBox")
		},
	},
	["leftPanel.checkBox"] = "checkBox",
}

function ActivityGuideGift:onCreate(params)
	self.activityId = 13
	self:enableSchedule()

	local params = params or {}

	self:initModel()

	local state = userDefault.getCurrDayKey("guideGiftState", "false")
	self.state = idler.new(state == "true" and true or false)
	idlereasy.when(self.state, function (_, state)
		self.checkBox:setSelectedState(state)
	end)

	self.clientBuyTimes = idler.new(true)

	-- 筛选出礼包
	self.allGiftItemIDs = idlers.newWithMap({})
	self.maxPageCount = idler.new(0)

	self.allGiftDatas = {}
	local cfg
	local nowTime = time.getTime()
	for id, data in pairs(self.guideGifts:read()) do
		cfg = csv.yunying.guidegift[id]
		local canAdd = true
		if params.targetItemID and params.targetItemID ~= cfg.itemID then
			-- 只显示指定礼包
			canAdd = false
		end

		if canAdd then
			if not self.allGiftDatas[cfg.itemID] then
				self.allGiftDatas[cfg.itemID] = {}
			end
			self.allGiftDatas[cfg.itemID][cfg.sort] = {
				giftID = id,
				endTime = data.expired_date,
				flag = data.flag or 0,
				cfg = cfg,
			}
		end
	end

	-- 去除过期和已购买的

	for itemID, datas in pairs(self.allGiftDatas) do
		local delected = true
		for sort, data in pairs(datas) do
			if data.endTime > nowTime then
				-- 未过期
				if data.flag == 0 then
					-- 有未购买
					delected = false
					break
				end
			end
		end
		if delected then
			self.allGiftDatas[itemID] = nil
		end
	end

	local allItemIDs = itertools.keys(self.allGiftDatas)

	itertools.sort(allItemIDs, function(aid, bid)
		local aData = self.allGiftDatas[aid][1]
		local bData = self.allGiftDatas[bid][1]
		return aData.endTime < bData.endTime
	end)

	self.allGiftItemIDs:update(allItemIDs)
	self.maxPageCount:set(table.length((allItemIDs)))

	self.showTab = idler.new(1)
	self.privilegeIndex = idler.new(1)
	self.showGiftItemID = idler.new(0)

	idlereasy.any({ self.privilegeIndex, self.maxPageCount }, function(_, privilegeIndex, maxPageCount)
		privilegeIndex = cc.clampf(privilegeIndex, 1, maxPageCount)
		self.privilegePanel:get("leftBtn"):visible(privilegeIndex > 1)
		self.privilegePanel:get("rightBtn"):visible(privilegeIndex < maxPageCount)

		self:showPrivilegePage(privilegeIndex)
	end)

	idlereasy.any({ self.guideGifts, self.clientBuyTimes }, function(_, guideGifts)
		self:updateGiftData(self.showGiftData)
	end)

	idlereasy.any({ self.showTab, self.showGiftItemID }, function(_, showTab, showGiftItemID)
		self:updateGiftData(self.allGiftDatas[showGiftItemID][showTab])
	end)

	idlereasy.when(self.showTab, function(_, tab)
		self.checkBox1:get("selected"):visible(tab == 1)
		self.checkBox2:get("selected"):visible(tab == 2)
		self.checkBox3:get("selected"):visible(tab == 3)
	end)

	Dialog.onCreate(self, { blackType = 1 })
end

function ActivityGuideGift:initModel()
	self.guideGifts = gGameModel.role:getIdler("guide_gifts")
end

function ActivityGuideGift:onPrivilegeLeftBtnClick()
	self.privilegeIndex:modify(function(val)
		return true, val - 1
	end)
end

function ActivityGuideGift:onPrivilegeRightBtnClick()
	self.privilegeIndex:modify(function(val)
		return true, val + 1
	end)
end

-- 礼包信息
function ActivityGuideGift:showPrivilegePage(page)
	local itemID = self.allGiftItemIDs:at(page):read()
	local giftDatas = self.allGiftDatas[itemID]

	for i = 1, 3 do
		local cfg = giftDatas[i].cfg
		local price = csv.recharges[cfg.rechargeID].rmbDisplay

		local checkBox = self.PanelPrice:get("checkBox" .. i)
		checkBox:get("txt"):text(price)
		checkBox:get("selected"):get("txt"):text(price)
	end

	self.showTab:set(1)
	self.showGiftItemID:set(itemID)
end

function ActivityGuideGift:onSelTargetPos(tab)
	self.showTab:set(tab)
end

function ActivityGuideGift:updateGiftData(data)
	if not data then
		return
	end
	self.showGiftData = data

	uiEasy.createItemsToList(self, self.list, data.cfg.item, {
		onAfterBuild = function()
			self.list:setItemAlignCenter()
		end,
		scale = 0.7
	})

	local giftInfo = self.guideGifts:read()[data.giftID]
	local nowTime = time.getTime()

	local label = self.btnBuy:get("label")

	if giftInfo.flag then
		-- 已购买
		label:text(gLanguageCsv.hasBuy)
		text.addEffect(label,
			{ color = ui.COLORS.NORMAL.WHITE, outline = { color = ui.NEWCOLORS.OUTLINE.YELLOW, size = 4 } })
		uiEasy.setBtnShader(self.btnBuy, nil, 2)
	else
		if giftInfo.expired_date < nowTime then
			-- 已过期
			label:text(gLanguageCsv.giftOutOfDate)
			text.addEffect(label,
				{ color = ui.COLORS.NORMAL.WHITE, outline = { color = ui.NEWCOLORS.OUTLINE.YELLOW, size = 4 } })
			uiEasy.setBtnShader(self.btnBuy, nil, 2)
		else
			local price = csv.recharges[data.cfg.rechargeID].rmbDisplay
			label:text(string.format(gLanguageCsv.symbolMoney, price))
			text.addEffect(label,
				{ color = ui.COLORS.NORMAL.WHITE, outline = { color = ui.NEWCOLORS.OUTLINE.YELLOW, size = 4 } })
			uiEasy.setBtnShader(self.btnBuy, nil, 1)
		end
	end


	if giftInfo.expired_date < nowTime then
		-- 已过期
		self.textTime:text(gLanguageCsv.dailyBuyPast)
	else
		local endTime = giftInfo.expired_date
		local function setLabel()
			local remainTime = time.getCutDown(endTime - time.getTime())
			self.textTime:text(gLanguageCsv.exclusiveRestrictionClose .. remainTime.str)

			if endTime - time.getTime() <= 0 then
				self.textTime:text(gLanguageCsv.dailyBuyPast)

				label:text(gLanguageCsv.giftOutOfDate)
				self.btnBuy:setTouchEnabled(false)
				self:unSchedule(1)
				return false
			end
			return true
		end
		self:unSchedule(1)
		self:schedule(function(dt)
			if not setLabel() then
				return false
			end
		end, 1, 0, 1)
	end
end

function ActivityGuideGift:onBuyClick()
	local activityId = self.activityId

	local giftData = self.showGiftData

	gGameApp:payDirect(self,
		{ rechargeId = giftData.cfg.rechargeID, yyID = activityId, csvID = giftData.giftID, name = giftData.cfg.name, buyTimes = 0 },
		self.clientBuyTimes)
		:serverCb(function(v)
			gGameUI:showGainDisplay(giftData.cfg.item, { raw = false })
		end)
		:doit()
end

function ActivityGuideGift:onCheckBox()
	if not self.checkBox:isSelected() then
		gGameUI:showDialog({title = gLanguageCsv.tips, content = gLanguageCsv.guideGiftTips, btnType = 2, cb = function ()
			userDefault.setCurrDayKey("guideGiftState", "true")
			self.state:modify(function(val)
				return true, not val
			end)
		end})
	else
		userDefault.setCurrDayKey("guideGiftState", "false")
		self.state:modify(function(val)
			return true, not val
		end)
	end
	
end

return ActivityGuideGift
