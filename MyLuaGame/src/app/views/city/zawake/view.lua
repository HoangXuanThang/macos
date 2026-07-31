local zawakeTools = require "app.views.city.zawake.tools"

local ViewBase = cc.load("mvc").ViewBase
local ZawakeView = class("ZawakeView", ViewBase)

ZawakeView.RESOURCE_FILENAME = "zawake.json"
ZawakeView.RESOURCE_BINDING = {
	["left.title.icon"] = "titleIcon",
	["left.title.level"] = "titleLevel",
	["left.txt"] = "lefttTitle",
	["left.attrItem"] = "attrItem",
	["left.costItem"] = "costItem",
	["left.skillEffectItem"] = "skillEffectItem",
	["left.listView"] = "listView",
	["left.costList"] = "costList",
	["left.bottom.btn_awake"] = {
		varname = "btn_awake",
		binds = {
			event = "touch",
			methods = { ended = bindHelper.self("onAwake") }
		}
	},
	["left.bottom.btn_awake.txt"] = {
		binds = {
			event = "effect",
			data = { outline = { color = ui.NEWCOLORS.OUTLINE.YELLOW, size = 4 } }
		},
	},
	["left.bottom.tips"] = "tips",
	["left.bottom.awaked"] = "awaked",
	["left.bottom.btn_chongzhi"] = {
		binds = {
			event = "touch",
			methods = { ended = bindHelper.self("onChongZhi") }
		}
	},
	["left.bottom.btn_chongzhi.txt"] = {
		binds = {
			event = "effect",
			data = { outline = { color = ui.NEWCOLORS.OUTLINE.BLACK, size = 2 } }
		},
	},
	["left.bottom.btn_yulan"] = {
		binds = {
			event = "touch",
			methods = { ended = bindHelper.self("onYuLan") }
		}
	},
	["left.bottom.btn_yulan.txt"] = {
		binds = {
			event = "effect",
			data = { outline = { color = ui.NEWCOLORS.OUTLINE.BLACK, size = 2 } }
		},
	},
	["left.bottom.btn_mingge_zhili"] = {
		binds = {
			event = "touch",
			methods = { ended = bindHelper.self("onMingGeZhiLi") }
		}
	},
	["left.bottom.btn_mingge_zhili.txt"] = {
		binds = {
			event = "effect",
			data = { outline = { color = ui.NEWCOLORS.OUTLINE.BLACK, size = 2 } }
		},
	},
	["right.item"] = "item",
	["right.list"] = {
		varname = "menuList",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("tabDatas"),
				item = bindHelper.self("item"),
				onItem = function(list, node, stage, v)
					local item = node:get("item")
					if node:getParent() then
						local y = node:getParent():convertToWorldSpace(cc.p(node:x(), node:y())).y
						y = y - 680
						local x = math.sqrt(780 * 780 - y * y)
						item:x(x - 500)
					end

					node:get("item.selected"):visible(v.selected == true)
					node:get("item.normal"):visible(v.selected ~= true)
					node:get("item.selected"):texture("city/ming_ge/tab_" .. stage .. ".png")
					if v.isUnlock then
						node:get("item.normal.icon"):texture("city/ming_ge/tab_" .. stage .. "_2.png")
					else
						node:get("item.normal.icon"):texture("city/ming_ge/tab_" .. stage .. "_3.png")
					end
					bind.touch(list, item, { methods = { ended = functools.partial(list.clikMenuItem, stage) } })
				end
			},
			handlers = {
				clikMenuItem = bindHelper.self("clikMenuItem"),
			},
		}
	},
	["right.change.head"] = "head",
	["right.change.btn_change"] = {
		binds = {
			event = "touch",
			methods = { ended = bindHelper.self("onChange") }
		}
	},
	["right.change.btn_change.txt"] = {
		binds = {
			event = "effect",
			data = { outline = { color = ui.NEWCOLORS.OUTLINE.YELLOW, size = 4 } }
		},
	},
	["center"] = "center",
}

function ZawakeView:clikMenuItem(list, stage)
	local stageCfg = zawakeTools.getStagesCfg(self.zawakeID:read(), stage)
	local isUnlock, labelDatas = zawakeTools.isUnlockByStage(stageCfg, self.zawakeID:read())
	if not isUnlock then
		gGameUI:stackUI("city.zawake.unlock_tips", nil, nil, { labelDatas = labelDatas, stageID = stage })
		return
	end
	self.stage:set(stage, true)
end

function ZawakeView:onCreate(params)
	self.listView:setScrollBarEnabled(false)
	local params = params or {}
	self.params = params
	gGameUI.topuiManager:createView("default", self, { onClose = self:createHandler("onClose") })
		:init({ title = gLanguageCsv.zawake, subTitle = "ZAWAKE" })

	self:initData()
	self:initModel(params)
	self:initIdler(params)
	self:onIdler()
	self:initTabDatas()
	self:initCenter()

	self.menuList:onScroll(function(event)
		for k, node in pairs(self.menuList:getItems()) do
			performWithDelay(self, function()
				if node and node:getParent() then
					local y = node:getParent():convertToWorldSpace(cc.p(node:x(), node:y())).y
					y = y - 680
					local x = math.sqrt(780 * 780 - y * y)
					node:get("item"):x(x - 500)
				end
			end, 0)
		end
	end)
end

function ZawakeView:initData()
	self.centerView = nil
	self.lastSelectLevel = nil
	self.config = nil
end

function ZawakeView:initModel(params)
	local zawakeID = params.zawakeID or zawakeTools.getFightPointMaxCard()
	self.zawakeID = idler.new(zawakeID)
	self.zawake = gGameModel.role:getIdler("zawake")
	self.items = gGameModel.role:getIdler("items")
	self.frags = gGameModel.role:getIdler("frags")
	self.zfrags = gGameModel.role:getIdler("zfrags")
	self.gold = gGameModel.role:getIdler("gold")
end

function ZawakeView:initTabDatas()
	local tabDatas = {}
	local stage = 1
	for i = 1, 8 do
		local stageCfg = zawakeTools.getStagesCfg(self.zawakeID:read(), i)
		local isUnlock = zawakeTools.isUnlockByStage(stageCfg, self.zawakeID:read())
		local menu = {}
		menu.isUnlock = isUnlock
		if isUnlock == true then
			stage = i
		end
		tabDatas[i] = menu
	end
	tabDatas[stage].selected = true
	self.tabDatas:update(tabDatas)
	self.stage:set(stage, true)
end

function ZawakeView:initIdler(params)
	self.tabDatas = idlers.new({})
	self.stage = idler.new(1)
	self.level = idler.new(0)
	self.selectLevel = idler.new(0)
	self.stage:addListener(function(curStage, oldStage)
		if self.tabDatas:atproxy(oldStage) then
			self.tabDatas:atproxy(oldStage).selected = false
		end
		if self.tabDatas:atproxy(curStage) then
			self.tabDatas:atproxy(curStage).selected = true
		end
		local stage = self.zawake:read()[self.zawakeID:read()] or {}
		local level = stage[self.stage:read()] or 0
		self.level:set(level)
		self:updateCenter(curStage)
		self.lastSelectLevel = nil
		self.selectLevel:set(math.min(level + 1, 8), true)
		if curStage < 8 and level == 8 then
			local stageCfg = zawakeTools.getStagesCfg(self.zawakeID:read(), curStage + 1)
			local isUnlock = zawakeTools.isUnlockByStage(stageCfg, self.zawakeID:read())
			if self.tabDatas:atproxy(curStage + 1) then
				self.tabDatas:atproxy(curStage + 1).isUnlock = isUnlock
			end
		end
	end)
end

function ZawakeView:onIdler()
	idlereasy.when(self.zawakeID, function(_, zawakeID)
		self:initTabDatas()
		local cardData = zawakeTools.getCardByZawakeID(zawakeID)
		local unitCsv = csv.unit[cardData.cfg.unitID]
		bind.extend(self, self.head, {
			class = "card_icon",
			props = {
				unitId = cardData.cfg.unitID,
				rarity = unitCsv.rarity,
				onNode = function(panel)
					panel:xy(-98, -108)
				end,
			}
		})
	end)
	idlereasy.when(self.selectLevel, function(_, selectLevel)
		self:updateLeft(selectLevel)
		local dot = self.centerView:get("d_" .. selectLevel)
		if dot then
			if dot.spine then
				dot.spine:play("mingge_xuanzhong", true)
			end
		end
		if self.lastSelectLevel then
			local lastDot = self.centerView:get("d_" .. self.lastSelectLevel)
			if lastDot then
				if lastDot.spine then
					if self.level:read() + 1 == self.lastSelectLevel then
						lastDot.spine:play("mingge_dangqian", true)
					else
						if self.level:read() < self.lastSelectLevel then
							lastDot.spine:play("mingge_weijihuo", true)
						else
							lastDot.spine:play("mingge_yijihuo", true)
						end
					end
				end
			end
		end
	end)
end

--命格属性
function ZawakeView:initAttrs()
	local title = self.lefttTitle:clone():text(gLanguageCsv.attribute)
	self.listView:pushBackCustomItem(title)
	for i = 1, 3 do
		local attrItem = self.attrItem:clone()
		for j = 1, 2 do
			local item = attrItem:get("item" .. j):visible(false)
			local index = (i - 1) * 2 + j
			local type = self.config["attrType" .. index]
			if type then
				item:visible(true)
				item:get("icon"):texture(ui.ATTR_LOGO[game.ATTRDEF_TABLE[type]])
				item:get("name"):text(getLanguageAttr(type))
				item:get("value"):text("+" .. dataEasy.getAttrValueString(type, self.config["attrNum" .. index]))
			else
				item:visible(false)
			end
		end
		self.listView:pushBackCustomItem(attrItem)
	end
end

-- 点亮消耗
function ZawakeView:initCost()
	if self.selectLevel:read() <= self.level:read() then
		return
	end
	local title = self.lefttTitle:clone():text(gLanguageCsv.consume)
	self.listView:pushBackCustomItem(title)
	local costList = self.costList:clone()
	self.listView:pushBackCustomItem(costList)
	idlereasy.any({ self.zfrags, self.items, self.frags, self.gold }, function()
		local data = {}
		for key, val in csvMapPairs(self.config.costItemMap) do
			table.insert(data,
				{ key = key, needVal = val, val = dataEasy.getNumByKey(key), showBtn = dataEasy.isZawakeFragment(key) })
		end
		table.sort(data, function(a, b)
			if a.showBtn ~= b.showBtn then
				return a.showBtn
			end
			return dataEasy.sortItemCmp(a, b)
		end)
		bind.extend(self, costList, {
			class = "listview",
			props = {
				data = data,
				item = bindHelper.self("costItem"),
				onItem = function(list, node, k, v)
					local childs = node:multiget("icon", "add", "btn_exchange")
					local showAddBtn = (v.val < v.needVal)
					childs.add:visible(showAddBtn)
					childs.btn_exchange:visible(v.showBtn)
					bind.extend(list, childs.icon, {
						class = "icon_key",
						props = {
							data = {
								key = v.key,
								num = v.val,
								targetNum = v.needVal,
							},
							noListener = true,
							grayState = showAddBtn and 1 or 0,					
							onNode = function(panel)
								bind.click(list, panel, {
									method = function()
										gGameUI:stackUI("common.gain_way", nil, nil, v.key, nil, v.needVal)
									end
								})
							end,
						},
					})
					bind.touch(list, childs.btn_exchange, {
						methods = {
							ended = function()
								gGameUI:stackUI("city.zawake.debris", nil, nil, { fragID = v.key, needNum = v.needVal })
							end
						}
					})
				end
			},
		})
	end):anonyOnly(self)
end

function ZawakeView:initLeftTitle()
	self.titleIcon:texture("city/ming_ge/tab_" .. self.stage:read() .. ".png")
	self.titleLevel:text(gLanguageCsv['symbolRome' .. self.selectLevel:read()])
end

function ZawakeView:initLeftBottom()
	self.btn_awake:visible(false)
	self.tips:visible(false)
	self.awaked:visible(false)
	if self.selectLevel:read() <= self.level:read() then --已点亮
		self.awaked:visible(true)
	else
		if self.selectLevel:read() == self.level:read() + 1 then --可点亮
			self.btn_awake:visible(true)
		else                                               --不可点亮条件
			self.tips:visible(true)
			self.tips:get("icon"):texture("city/ming_ge/tab_" .. self.stage:read() .. "_2.png")
			self.tips:get("txt3"):text(gLanguageCsv['symbolRome' .. self.selectLevel:read() - 1])
		end
	end
end

function ZawakeView:initSkillEffect()
	local skillCfgs = zawakeTools.getSkillCfg(self.zawakeID:read(), self.config.skillID)
	if skillCfgs then
		local title = self.lefttTitle:clone():text(gLanguageCsv.zawakeSkillEff)
		self.listView:pushBackCustomItem(title)
		for _, skillCfg in ipairs(skillCfgs) do
			local skillEffectItem = self.skillEffectItem:clone()
			self.listView:pushBackCustomItem(skillEffectItem)
			local skillChilds = skillEffectItem:multiget("skill", "name", "iconUp", "infoBtn")
			uiEasy.setSkillInfoToItems({
				name = skillChilds.name,
				icon = skillChilds.skill,
			}, skillCfg.cfg)
			skillChilds.name:text(csv.skill[self.config.skillID].skillName .. skillChilds.name:text())
			bind.touch(self, skillChilds.infoBtn, {
				methods = {
					ended = function()
						local view = gGameUI:stackUI("common.skill_detail", nil,
							{ clickClose = true, dispatchNodes = list }, {
								skillId = skillCfg.id,
								skillLevel = 1,
								cardId = skillCfg.cardId,
								star = 12,
								isZawake = true,
							})
						local panel = view:getResourceNode()
						local x, y = panel:xy()
						panel:xy(x + 1020, y)
					end
				}
			})
		end
	end
end

function ZawakeView:initExtraAttrs()
	if csvSize(self.config.extraAttrs) > 0 then
		local title = self.lefttTitle:clone()
		self.listView:pushBackCustomItem(title)
		if self.config.extraScene[1] == 0 then
			title:text(gLanguageCsv.zawakeExtraAttr)
		else
			title:text(gLanguageCsv.zawakeExtraScene)
		end

		local str = ""
		if self.config.extraScene[1] ~= 0 then
			local t = {}
			for _, id in ipairs(self.config.extraScene) do
				table.insert(t, gLanguageCsv[game.SCENE_TYPE_STRING_TABLE[id]])
			end
			str = table.concat(t, gLanguageCsv.symbolComma) .. "\n"
		end
		local t = {}
		for k, v in csvMapPairs(self.config.extraAttrs) do
			table.insert(t, getLanguageAttr(k) .. "+" .. dataEasy.getAttrValueString(k, v))
		end
		str = string.format("#C0xFFFFFF# %s %s", str, table.concat(t, "  "))
		local rich = rich.createWithWidth(str, 44, nil, 900)
		self.listView:pushBackCustomItem(rich)
	end
end

function ZawakeView:initActivate()
	local _, labelDatas = zawakeTools.getActiveCondition(self.zawakeID:read(), self.stage:read(), self.config)
	if itertools.isempty(labelDatas) then
		return
	end
	local title = self.lefttTitle:clone()
	self.listView:pushBackCustomItem(title)
	if self.config.skillID > 0 then
		title:text(gLanguageCsv.zawakeActivateSkillID)
	else
		title:text(gLanguageCsv.zawakeActivateScene)
	end

	for index, str in ipairs(labelDatas) do
		local rich = rich.createWithWidth(str, 44, nil, 920)
		self.listView:pushBackCustomItem(rich)
	end
end

function ZawakeView:updateLeft(selectLevel)
	self.listView:removeAllItems()
	self.config = zawakeTools.getLevelCfg(self.zawakeID:read(), self.stage:read(), selectLevel)
	if not self.config then
		return
	end
	self:initLeftTitle()
	self:initAttrs()
	self:initSkillEffect()
	self:initExtraAttrs()
	self:initActivate()
	self:initCost()
	self:initLeftBottom()
end

function ZawakeView:initCenter()
	for i = 1, 8 do
		local view = self.center:get("p_" .. i)
		for k = 1, 8 do
			local dot = view:get("d_" .. k)
			dot:setTouchEnabled(true)
			bind.touch(self, dot, {
				methods = {
					ended = function()
						self.clickDot(self, i, k)
					end
				}
			})
		end
	end
end

function ZawakeView:updateCenter(index)
	for i = 1, 8 do
		self.center:get("p_" .. i):visible(index == i)
	end
	self.centerView = self.center:get("p_" .. index)
	if self.centerView then
		for i = 1, 7 do
			local line = self.centerView:get("line" .. i)
			if i > self.level:read() then
				line:texture("city/ming_ge/line_1.png")
			else
				line:texture("city/ming_ge/line_2.png")
			end
		end

		for k = 1, 8 do
			local dot = self.centerView:get("d_" .. k)
			if not dot.spine then
				dot.spine = widget.addAnimationByKey(dot, "mingge/mingge_texiao.json", "d_" .. index .. "_" .. k,
					"mingge_weijihuo", 1,
					true):xy(50, 50)
			end
			if self.level:read() + 1 == k then
				dot.spine:play("mingge_dangqian", true)
			else
				if self.level:read() < k then
					dot.spine:play("mingge_weijihuo", true)
				else
					dot.spine:play("mingge_yijihuo", true)
				end
			end
		end
	end
end

function ZawakeView:clickDot(index1, index2)
	self.lastSelectLevel = self.selectLevel:read()
	self.selectLevel:set(index2)
end

function ZawakeView:onChongZhi()
	local zawake = self.zawake:read() or {}
	local stage = zawake[self.zawakeID:read()] or {}
	for stage, level in pairs(stage) do
		if level > 0 then
			gGameUI:stackUI("city.zawake.reset", nil, nil,
				{ zawakeID = self.zawakeID:read(), cb = self:createHandler("onChongZhiSuccess") })
			return
		end
	end
	gGameUI:showTip(gLanguageCsv.zawakeResetTips)
end

function ZawakeView:onChongZhiSuccess()
	self.stage:set(1, true)
end

function ZawakeView:onYuLan()
	local zawakeID = self.zawakeID:read()
	local zawake = self.zawake:read() or {}
	for stageID = 1, zawakeTools.MAXSTAGE do
		for lv = 1, zawakeTools.MAXLEVEL do
			local cfg = zawakeTools.getLevelCfg(zawakeID, stageID, lv)
			if cfg and cfg.skillID > 0 then
				local skillCfgs = zawakeTools.getSkillCfg(zawakeID, cfg.skillID)
				if skillCfgs then
					gGameUI:stackUI("city.zawake.preview", nil, nil, zawakeID)
					return
				end
			end
		end
	end
	gGameUI:showTip(gLanguageCsv.zawakeNoPreviewSkill)
end

function ZawakeView:onMingGeZhiLi()
	gGameUI:stackUI("city.zawake.force")
end

function ZawakeView:onAwake()
	if not zawakeTools.canAwake(self.zawakeID:read(), self.stage:read(), self.selectLevel:read()) then
		gGameUI:showTip(gLanguageCsv.zawakeItemsLess)
		return
	end
	local level = self.level:read()
	local nextLevel = math.min(level + 1, zawakeTools.MAXLEVEL)
	gGameApp:requestServer("/game/card/zawake/strength", function(tb)
		-- 觉醒成功界面
		local params = {
			zawakeID = self.zawakeID:read(),
			level = level,
			stageID = self.stage:read(),
			cfg = self.config,
		}
		gGameUI:stackUI("city.zawake.awake_success", nil, { blackLayer = true }, params)
		self.stage:set(self.stage:read(), true)
	end, self.zawakeID:read(), self.stage:read(), nextLevel)
end

function ZawakeView:onClose()
	local cb = self.params.cb
	if cb and self.params.zawakeID ~= self.zawakeID:read() then
		-- zawakeID 发生变动，对应精灵存在，选最高战力精灵
		local data = zawakeTools.getCardByZawakeID(self.zawakeID:read())
		if data.dbId then
			cb(data.dbId)
		end
	end
	gGameApp:requestServer("/game/card/zawake/quit")
	ViewBase.onClose(self)
end

function ZawakeView:onChange()
	gGameUI:stackUI("city.zawake.replace", nil, nil, { zawakeID = self.zawakeID })
end

return ZawakeView
