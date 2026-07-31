-- @Date:   2019-05-30
-- @Desc:
-- @Last Modified time: 2019-06-12

local YY_TYPE = game.YYHUODONG_TYPE_ENUM_TABLE
local STATE_TYPE = {
	canReceive = 1,
	noReach = 0,
	received = 2,
}

local ActivityWeeklyCardFR = class("ActivityWeeklyCardFR", Dialog)
ActivityWeeklyCardFR.RESOURCE_FILENAME = "activity_weekly_card_fr.json"
ActivityWeeklyCardFR.RESOURCE_BINDING = {
	["page1"] = "page1",
	["page2"] = "page2",
	["page3"] = "page3",
	["pageview"] = "pageview",
	["btnClose"] = {
		binds = {
			event = "touch",
			methods = { ended = bindHelper.self("onClose") }
		},
	},
	["page1.buyBtn"] = {
		binds = {
			event = "touch",
			methods = { ended = bindHelper.self("onBuy") }
		},
	},
	["page2.buyBtn"] = {
		binds = {
			event = "touch",
			methods = { ended = bindHelper.self("onBuy") }
		},
	},
	["page3.buyBtn"] = {
		binds = {
			event = "touch",
			methods = { ended = bindHelper.self("onBuy") }
		},
	},
	["page1.btnGet"] = {
		binds = {
			event = "touch",
			methods = { ended = bindHelper.self("onGetClick") }
		},
	},
	["page2.btnGet"] = {
		binds = {
			event = "touch",
			methods = { ended = bindHelper.self("onGetClick") }
		},
	},
	["page3.btnGet"] = {
		binds = {
			event = "touch",
			methods = { ended = bindHelper.self("onGetClick") }
		},
	},
	["dot0"] = "dot0",
	["dot1"] = "dot1",
	["dot2"] = "dot2",
	["btnLeft"] = {
		varname = "btnLeft",
		binds = {
			event = "touch",
			methods = { ended = bindHelper.self("onClickLeftIndex") }
		},
	},
	["btnRight"] = {
		varname = "btnRight",
		binds = {
			event = "touch",
			methods = { ended = bindHelper.self("onClickRightIndex") }
		},
	},
	["page1.mask"] = "mask1",
	["page2.mask"] = "mask2",
	["page3.mask"] = "mask3"
}

function ActivityWeeklyCardFR:onCreate()
	gGameModel.currday_dispatch:getIdlerOrigin("weeklyCardFR"):set(true)
	self.yyhuodongs = gGameModel.role:getIdler("yyhuodongs")

	self.clientBuyTimes = idler.new(true)
	local yyhuodongs = self.yyhuodongs:read()
	local activityIDs = {}
	for _, id in ipairs(gGameModel.role:read('yy_open')) do
		local huodong = yyhuodongs[id] or {}
		--print("yyhuodongs", dump(gGameModel.role:read("yyhuodongs")))
		--print("huodong", dump(yyhuodongs))
		local cfg = csv.yunying.yyhuodong[id]
		--print("cfg", dump(cfg))
		if cfg.independent == 1 and cfg.type == YY_TYPE.weeklyCardFR then
			local dayCardData = dataEasy.getFirstRechargeData(cfg.huodongID)
			local flag = 1
			if huodong.buy then
				local allGet = true
				for day, dayData in pairs(dayCardData) do
					if not huodong.stamps then
						allGet = false
						break
					end

					if huodong.stamps and huodong.stamps[dayData.id] ~= 0 then
						allGet = false
						break
					end
				end

				flag = allGet and 2 or 1
			end
			if flag ~= 2 then
				table.insert(activityIDs, { id = id, state = flag, sortWeight = cfg.sortWeight })
			end
		end
	end
	table.sort(activityIDs, function(a, b)
		if a.sortWeight ~= b.sortWeight then
			return a.sortWeight < b.sortWeight
		end
		return a.id < b.id
	end)
	self.page1:retain()
	self.page1:removeFromParent()
	self.page2:retain()
	self.page2:removeFromParent()
	self.page3:retain()
	self.page3:removeFromParent()
	self.activityIDs = activityIDs
	self.isInserPage = false
	self.pages = {}
	
	self.states = {
		idler.new(STATE_TYPE.noReach),
		idler.new(STATE_TYPE.noReach),
		idler.new(STATE_TYPE.noReach)
	}

	idlereasy.any({ self.yyhuodongs, self.clientBuyTimes }, function(_, val)
		for i, v in ipairs(self.activityIDs) do
			local cfg = csv.yunying.yyhuodong[v.id]
			local paramCfg = cfg.clientParam
			local page = self["page" .. paramCfg.page]
			if val[v.id] then
				if v.state ~= 2 then
					
					if not self.isInserPage then
						self.pageview:addPage(page)
						self.pages[i] = page
					end
					self:initPageData(i, page, v.id, cfg, val[v.id])
					page:show()
				else
					page:hide()
				end
			else
				printWarn("Huodong data nil, skip id:", v.id)
				page:hide()
			end
		end
		self.isInserPage = true
	end)
	self.curPage = idler.new(0)
	local container = self.pageview:getInnerContainer()
	local width = container:size().width
	local totalPage = #self.pageview:getPages()
	local dotList = { self.dot0, self.dot1, self.dot2 }
	for i, v in ipairs(dotList) do
		if i > totalPage then
			v:setVisible(false)
		end
	end
	self.isEnter = false
	self.pageview:onScroll(function(event)
		local x = container:getPositionX()
		local xPos = {}
		itertools.invoke({ self.mask1, self.mask2, self.mask3 }, "show")
		if event.name == "AUTOSCROLL_ENDED" then
			for i = 1, totalPage do
				local baseX = -width * (i - 1)
				if math.abs(x - baseX) <= 5 then
					self.isEnter = true
					itertools.invoke({ self.mask1, self.mask2, self.mask3 }, "hide")
					if self.curPage:read() ~= self.pageview:getCurPageIndex() then
						self.curPage:set(self.pageview:getCurPageIndex())
					end
					return
				end
			end
		end
		if self.isEnter or event.name == "AUTOSCROLL_BEGAN" then
			self.isEnter = false
			itertools.invoke({ self.mask1, self.mask2, self.mask3 }, "hide")
		end
	end)
	self.curPage:addListener(function(val, oldval, _)
		if totalPage > 1 then
			local oldDot = self["dot" .. oldval]
			local newDot = self["dot" .. val]
			itertools.invoke({ oldDot, oldval == val and self.dot1 or newDot }, "show")
			oldDot:texture("common/icon/logo_normal_fy.png")
			newDot:texture("common/icon/logo_highlight_fy.png")
		end
		self.btnRight:visible(val < totalPage - 1)
		self.btnLeft:visible(val > 0)
		self.pageview:scrollToPage(val)
	end)
	Dialog.onCreate(self, { blackType = 1 })
end

function ActivityWeeklyCardFR:initPageData(idx, page, actID, cfgCsv, huodong)
	local paramCfg = cfgCsv.clientParam
	local spineData = paramCfg.spineData
	local dayCardData = dataEasy.getFirstRechargeData(cfgCsv.huodongID)

	page:get("img_desc"):texture(paramCfg.resBg)

	-- spine
	local sprPhoto = page:get("sprPhoto")
	
	local unitCsv = csv.unit[spineData.unitID]

	sprPhoto:removeAllChildren()
	local spine = widget.addAnimation(sprPhoto, unitCsv.showOpen, "default", 1, true)
	spine:scale(spineData.scale)
	spine:xy(spineData.x + 600, spineData.y + 600)

	local canGet = false
	for day = 1, 3 do
		local panel = page:get("panel" .. day)
		self:initPanel(panel, day, dayCardData[day], huodong)

		if huodong.stamps and huodong.stamps[dayCardData[day].id] == 1 then
			canGet = true
		end
	end

	local rechargeId = cfgCsv.paramMap.recharge
	local payInfo = csv.recharges[rechargeId]
	
	local btnBuy = page:get("buyBtn")
	local btnGet = page:get("btnGet")

	itertools.invoke({ btnBuy, btnGet }, "hide")
	if huodong.buy then
		btnGet:show()
		local label = btnGet:get("label")
		self.states[idx]:set(STATE_TYPE.received)
		if canGet then
			label:text(gLanguageCsv.commonTextGet)
			cache.setShader(btnGet, false, "normal")
			text.addEffect(label, { color = ui.COLORS.NORMAL.WHITE, outline = { color = ui.NEWCOLORS.OUTLINE.YELLOW, size = 4 } })
			btnGet:setTouchEnabled(true)
		else
			label:text(gLanguageCsv.received)
			cache.setShader(btnGet, false, "hsl_gray")
			text.deleteAllEffect(label)
			btnGet:setTouchEnabled(false)
		end
	else
		local label = btnBuy:get("label")
		btnBuy:show()
		self.states[idx]:set(STATE_TYPE.noReach)
		label:text(string.format(gLanguageCsv.symbolMoney, payInfo.rmbDisplay))
		text.addEffect(label, { color = ui.COLORS.NORMAL.WHITE, outline = { color = ui.NEWCOLORS.OUTLINE.YELLOW, size = 4 } })
		-- adapt.setTextScaleWithWidth(label, nil, btnBuy:width() - 80)
	end
	
end

function ActivityWeeklyCardFR:initPanel(node, day, dayData, huodong)
	local childs = node:multiget("list", "mask")
	uiEasy.createItemsToList(self, childs.list, dayData.award, { scale = 0.9, margin = 10 })

	childs.mask:hide()
	node:removeChildByName("effect1")
	node:removeChildByName("effect2")
	node:removeChildByName("effect3")
	if huodong.buy then
		if huodong.stamps and huodong.stamps[dayData.id] == 0 then
			childs.mask:show()
		elseif huodong.stamps and huodong.stamps[dayData.id] == 1 then
			local effect1 = widget.addAnimationByKey(node, "wupinshanguang/saoguang.skel", "effect1", "effect_loop", 999)
			effect1:xy(130,500):scale(0.7)

			local effect2 = widget.addAnimationByKey(node, "wupinshanguang/saoguang.skel", "effect2", "effect_loop", 999)
			effect2:xy(130,312):scale(0.7)

			local effect3 = widget.addAnimationByKey(node, "wupinshanguang/saoguang.skel", "effect3", "effect_loop", 999)
			effect3:xy(130,122):scale(0.7)
		end
	end
end

function ActivityWeeklyCardFR:onIndex()
	self.curPage:set(self.curPage:read() == 0 and 1 or 0)
end

function ActivityWeeklyCardFR:onClickLeftIndex()
	local currPage = self.curPage:read() - 1
	if currPage < 0 then
		currPage = 2
	end
	self.curPage:set(currPage)
end

function ActivityWeeklyCardFR:onClickRightIndex()
	local currPage = self.curPage:read() + 1
	if currPage > 2 then
		currPage = 0
	end
	self.curPage:set(currPage)
end

-- 一键领取
function ActivityWeeklyCardFR:onGetClick()
	local index

	if itertools.size(self.pages) > 1 then
		index = self.pageview:getCurPageIndex() + 1
	else
		index = next(self.pages)
	end

	if not self.activityIDs[index] then
		return
	end

	local id = self.activityIDs[index].id

	gGameApp:requestServer("/game/yy/award/get/onekey", function(tb)
		gGameUI:showGainDisplay(tb)
	end, id)

end
-- 购买
function ActivityWeeklyCardFR:onBuy()
	local index
	local id

	if itertools.size(self.pages) > 1 then
		index = self.pageview:getCurPageIndex() + 1
	else
		index = next(self.pages)
	end

	if self.states[index]:read() ~= STATE_TYPE.received then
		id = self.activityIDs[index].id

		local cfg = csv.yunying.yyhuodong[id]
		local rechargeId = cfg.paramMap.recharge

		gGameApp:payDirect(self, {
				rechargeId = rechargeId,
				yyID = id,
				csvID = 0,
				name = cfg.name,
				buyTimes = 0
			}, self.clientBuyTimes)
			:serverCb(function(v)
				-- local cfg = csv.yunying.directbuygift[giftID]
				-- gGameUI:showGainDisplay(cfg.item, { raw = false })
			end)
			:doit()
	end

end

return ActivityWeeklyCardFR
