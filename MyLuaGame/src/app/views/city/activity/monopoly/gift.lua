

-- 可购买，刷新中，售罄
local STATE_TYPE = {
	canbuy = 1,
	refresh = 2,
	sellout = 3,
}

local ActivityMonopolyWalkGift = class("ActivityMonopolyWalkGift", cc.load("mvc").ViewBase)

ActivityMonopolyWalkGift.RESOURCE_FILENAME = "treasure_gift.json"
ActivityMonopolyWalkGift.RESOURCE_BINDING = {
    ["bg"] = "bg",
    ["item"] = "item",
	["item.title"] = {
		binds = {
			{
				event = "effect",
				data = {outline = {color = ui.NEWCOLORS.OUTLINE.BLACK, size = 4}}
			},
		}
	},
	["item.times"] = {
		binds = {
			{
				event = "effect",
				data = {outline = {color = ui.NEWCOLORS.OUTLINE.BLACK, size = 4}}
			},
		}
	},
	["item.bottomPanel.price"] = {
		binds = {
			{
				event = "effect",
				data = {outline = {color = ui.NEWCOLORS.OUTLINE.BLACK, size = 4}}
			},
		}
	},
	["sublist"] = "sublist",
	["list"] = {
		varname = "list",
		binds = {
			event = "extend",
			class = "tableview",
			props = {
				data = bindHelper.self("datas"),
				item = bindHelper.self("sublist"),
				cell = bindHelper.self("item"),
				columnSize = 4,
				xMargin = 16,
				yMargin = 10,
				itemAction = {isAction = true},
				dataOrderCmp = function(a, b)
					if a.state ~= b.state then
						return a.state < b.state
					end
					if a.sort ~= b.sort then
						return a.sort < b.sort
					end
					return a.csvId < b.csvId
				end,
				onCell = function(list, node, k, v)
					local cfg = v.cfg
					local childs = node:multiget("times", "mask", "list", "icon", "item", "bottomPanel", "bg")

					childs.icon:texture(cfg.icon):scale(1.8)
					
					local hint = gLanguageCsv.directBuyGiftOnetimeBuy
					if v.status == 1 then
						hint = gLanguageCsv.directBuyGiftWeek
					elseif v.status == 2 then
						hint = gLanguageCsv.directBuyGiftMonth
					end
					childs.times:text(string.format(hint, v.leftTimes, cfg.limit))
					
					childs.list:removeAllChildren()
					childs.list:setScrollBarEnabled(false)
					childs.list:setItemsMargin(5)
					childs.list:setGravity(ccui.ListViewGravity.bottom)
					
					local len = csvSize(cfg.item)
					local dx = len == 1 and childs.item:size().width/2 or 0
					for _, itemData in ipairs(dataEasy.getItemData(cfg.item)) do
						local item = childs.item:clone():show()
						local size = item:size()
						bind.extend(list, item, {
							class = "icon_key",
							props = {
								data = itemData,
								onNode = function(node)
									node:xy(size.width/2 + dx, size.height/2)
										:scale(0.65)
								end,
							},
						})
						childs.list:pushBackCustomItem(item)
					end

					childs.list:adaptTouchEnabled()
						:setItemAlignCenter()

					local price = childs.bottomPanel:get("price")
					local rmbIcon = childs.bottomPanel:get("rmb")
					node:setTouchEnabled(false)
					rmbIcon:visible(false)

					if v.rmb then
						price:text(v.rmb)
						if type(v.rmb) ~= "string" then
							rmbIcon:visible(true)
							adapt.oneLineCenterPos(cc.p(200, 50), { rmbIcon, price }, cc.p(0, 0))
						end
					elseif v.price then
						price:text(string.format(gLanguageCsv.symbolMoney, v.price))
					end

					local isInfo = (v.rmb and type(v.rmb) == "string") and true or false
					if v.state == STATE_TYPE.canbuy then
						childs.mask:hide()
						node:setTouchEnabled(true)
						bind.touch(list, node, {clicksafe = true, methods = {ended = functools.partial(list.clickCell, k, v)}})
					else
						childs.mask:show()
						isInfo = false
						-- cache.setShader(node, false, "hsl_gray")

						if v.state == STATE_TYPE.sellout then
							childs.mask:get("label"):text(gLanguageCsv.sellout)
						else
							childs.mask:get("label"):text(gLanguageCsv.nextDayRefresh5)
						end
					end
					
					list:setRenderHint(0)
				end,
				onAfterBuild = function (list)
				end,
			},
			handlers = {
				clickCell = bindHelper.self("onBuyClick"),
			},
		},
	},
}

function ActivityMonopolyWalkGift:onCreate(activityId)
	gGameModel.currday_dispatch:getIdlerOrigin("redHintDaily")
		:modify(function(data)
			data[game.DAILY_REDHINT.monomolyGift] = true
		end, true)

	local yyCfg = csv.yunying.yyhuodong[activityId]

	gGameUI.topuiManager:createView("monopoly", self, { onClose = self:createHandler("onClose") })
		:init({ title = yyCfg.name, subTitle = "MONOPOLY" })

    self:initModel()

	self.datas = idlers.new()
	self.activityId = idler.new(activityId)
	
	self.clientBuyTimes = idler.new(true)
	idlereasy.any({self.yyhuodongs, self.clientBuyTimes, self.activityId}, function(_, yyhuodongs, clientBuyTimes, activityId)
		local huodongID = csv.yunying.yyhuodong[activityId].huodongID
		local yydata = yyhuodongs[activityId] or {}
		local stamps = yydata.stamps or {}
		local datas = {}
		for k, v in csvPairs(csv.yunying.directbuygift) do
			if v.huodongID == huodongID and self.level >= v.levelLimit then
				local state = STATE_TYPE.canbuy
				local buyTimes = stamps[k] or 0
				buyTimes = dataEasy.getPayClientBuyTimes("directBuyData", activityId, k, buyTimes)
				local leftTimes = math.max(0, v.limit - buyTimes)
				local status = v.status
				if leftTimes == 0 then
					if v.refresh then
						state = STATE_TYPE.refresh
					else
						state = STATE_TYPE.sellout
					end
				end
				--# 判断是免费还是钻石和钱
				local rmb, price
				if v.rmbCost == 0 then
					rmb = gLanguageCsv.freeToReceive
				elseif v.rmbCost >= 1 then
					rmb = v.rmbCost
				else
					price = csv.recharges[v.rechargeID].rmbDisplay
				end
				table.insert(datas, {csvId = k, cfg = v, state = state, buyTimes = buyTimes, leftTimes = leftTimes, price = price, rmb = rmb, status = status, sort = v.sort})
			end
		end

		if not self.isTabChange then
			dataEasy.tryCallFunc(self.list, "updatePreloadCenterIndex")
		else
			self.isTabChange = false
		end
		self.datas:update(datas)
	end)
end

function ActivityMonopolyWalkGift:initModel()
	self.yyhuodongs = gGameModel.role:getIdler("yyhuodongs")
	self.level = gGameModel.role:read("level")
end

function ActivityMonopolyWalkGift:onBuyClick(list, k, v)
	local activityId = self.activityId:read()
	if not v.rmb then
		gGameApp:payDirect(self, {rechargeId = v.cfg.rechargeID, yyID = activityId, csvID = v.csvId, name = v.cfg.name, buyTimes = v.buyTimes}, self.clientBuyTimes)
			:serverCb(function()
				local cfg = csv.yunying.directbuygift[v.csvId]
				gGameUI:showGainDisplay(cfg.item, {raw = false})
			end)
			:doit()
	else
		gGameApp:requestServer("/game/yy/award/get", function(tb)
			self.clientBuyTimes:notify()
			local cfg = csv.yunying.directbuygift[v.csvId]
			gGameUI:showGainDisplay(cfg.item, {raw = false})
		end, activityId, v.csvId)
	end
end

return ActivityMonopolyWalkGift