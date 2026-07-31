-- @desc: 神兵注灵

local ICON_SCALE = {
	[1] = 1,
	[2] = 1.5,
}

local abilityStrengthenTools = require "app.views.city.card.ability.tools"

local ExploreAbilityView = class("ExploreAbilityView", Dialog)

ExploreAbilityView.RESOURCE_FILENAME = "explore_ability.json"
ExploreAbilityView.RESOURCE_BINDING = {
	["frame.btnClose"] = {
		binds = {
			event = "touch",
			methods = { ended = bindHelper.self("onClose") }
		},
	},
	["title.txt"] = {
		binds = {
			event = "effect",
			data = ui.TITLE_STYLE_1
		},
	},
	["abilityPanel"] = "abilityPanel",
	["item"] = "item",
	["itemSkill"] = "itemSkill",
	["barBg"] = "barBg",
	["bar"] = "bar",


	["panel"] = "panel",
	["panel.photo"] = "photo",

	["panel.attrPanel"] = "attrPanel",
	["panel.attrPanel.name"] = "name",
	["panel.attrPanel.skillDesc"] = "skillDesc",
	["panel.attrPanel.sublist"] = "sublist",
	["panel.attrPanel.itemAttr"] = "itemAttr",
	["panel.attrPanel.list"] = {
		binds = {
			event = "extend",
			class = "tableview",
			props = {
				data = bindHelper.self("attrData"),
				item = bindHelper.self("sublist"),
				cell = bindHelper.self("itemAttr"),
				columnSize = 2,
				-- margin = 50,
				xMargin = 20,
				yMargin = 10,
				itemAction = { isAction = true },
				dataOrderCmp = function(a, b)
					-- if a.sortValue ~= b.sortValue then
					-- 	return a.sortValue < b.sortValue
					-- end
					-- return a.csvId < b.csvId
					return a.key < b.key
				end,
				onCell = function(list, node, k, v)
					local str, val = dataEasy.getAttrTypeValue(v.key, v.val)
					node:get("txt"):text(str)
					node:get("val"):text("" .. val)
				end,
			}
		},
	},
}

function ExploreAbilityView:onCreate(dbHandler)
	self.data = dbHandler()

	self:initModel()
	self.selectPos = idler.new(0)

	local cfgCsv = self.data.cfg

	self.explorerId = idler.new(cfgCsv.id)
	self.attrData = idlertable.new({})

	self.name:text(cfgCsv.name)
	text.addEffect(self.name, { color = ui.COLORS.QUALITY[cfgCsv.quality] })
	self:onUpdateAbilityPanel(cfgCsv.id)

	local spine = widget.addAnimationByKey(self.photo, cfgCsv.res, "explorer", "animation", 2, true)
	spine:scale(2)

	self.oldLv = {}
	idlereasy.any({ self.explorerId, self.explorers }, function(_, explorerId, explorers)
		local abilities = explorers[explorerId].abilities or {}
		local cfg = gExplorerAbilityCsv[explorerId]
		local attrData = {}
		local skillId, skillLv = 0, 0
		for i = 1, table.maxn(cfg) do
			local level = abilities[i] or 0
			local v = cfg[i]
			if v then
				if v.effectType == 2 then
					skillId = v.skillID
					skillLv = level
				else
					if not attrData[v.attrType1] then
						attrData[v.attrType1] = {
							key = v.attrType1,
							val = v.attrNum1[level] or "0%"
						}
					else
						attrData[v.attrType1].val = dataEasy.attrAddition(attrData[v.attrType1].val, v.attrNum1[level])
					end
				end
				local item = self.abilityPanel:get("item" .. i)
				if item then
					item:get("select"):visible(self.selectPos:read() == i)

					if v.iconGray == "" then
						cache.setShader(item:get("icon"), false, (level == 0) and "hsl_gray_white" or "normal")
					else
						item:get("icon"):texture((level == 0) and v.iconGray or v.icon)
					end
					-- cache.setShader(item:get("iconBg"), false, level == 0 and "hsl_gray_white" or "normal")
					item:get("textLv"):text(level .. "/" .. v.levelMax)

					if not self.oldLv[i] then
						self.oldLv[i] = {}
					end
					--连线
					for k, prePos in orderCsvPairs(v.preID) do
						local preLv = abilities[prePos] or 0
						--播放激活动画
						local isActive = false
						if self.oldLv[i][prePos] == 0 and preLv > 1 then
							isActive = true
						end
						self:setAngleByPos(item, v.id, prePos, isActive)
						self.oldLv[i][prePos] = preLv
					end
				end
			end
		end

		self.attrData:set(attrData)

		self:onUpdateSkillDes(skillId, skillLv)
	end)


	self.selectPos:addListener(function(val, oldval)
		local oldItem = self.abilityPanel:get("item" .. oldval)
		if oldItem then
			oldItem:get("select"):hide()
		end
		local selectItem = self.abilityPanel:get("item" .. val)
		if selectItem then
			selectItem:get("select"):show()
			abilityStrengthenTools.setEffect({
				parent = selectItem:get("select"),
				spinePath = "figure/touxiang.json",
				effectName = "effect_xuanzhong",
				scale = selectItem:get("select"):scale() * 2
			})
		end
	end)
	Dialog.onCreate(self, { blackType = 1 })
end

function ExploreAbilityView:initModel()
	self.explorers = gGameModel.role:getIdler("explorers")
end

function ExploreAbilityView:onUpdateSkillDes(skillId, skillLevel)
	local skillCfg = csv.skill[skillId]
	local desc = string.format("#C0x5b545b#%s",
		eval.doMixedFormula(skillCfg.describe, { skillLevel = skillLevel or 1, math = math }, nil) or "no desc")

	self.skillDesc:removeAllChildren()
	local skillContent = rich.createWithWidth(desc, 40, nil, 680)
		:anchorPoint(0, 1)
		:xy(0, 160)
		:addTo(self.skillDesc, 1, "emm")
		:z(2)
	-- self.skillDesc:scale(0.9)
	-- body
end

function ExploreAbilityView:onUpdateAbilityPanel(abilitySeqID)
	self.abilityPanel:removeAllChildren()
	--特性索引ID
	local cfg = gExplorerAbilityCsv[abilitySeqID]
	local size = self.abilityPanel:size()
	-- local midPos = cc.p(size.width/2, size.height/2)
	local midPos = cc.p(0, 0)
	-- 底图资源
	local baseSrc = ""
	local maxZorder = table.maxn(cfg) + 10
	for i = 1, table.maxn(cfg) do
		local v = cfg[i]
		if v then
			local item = self.item:clone():show()
			item:xy(midPos.x + v.pos.x, midPos.y + v.pos.y)
				:name("item" .. i)
				:addTo(self.abilityPanel, maxZorder - i)

			bind.touch(self, item, {
				-- longtouch = 0.2,
				scaletype = 0,
				methods = {
					ended = bindHelper.defer(function(view)
						return view:onItemClick(i, v.id)
					end)
				}
			})

			item:get("icon"):texture(v.icon)
			item:get("iconBg"):scale(ICON_SCALE[v.effectType] * 1.4)
			item:get("select"):scale(ICON_SCALE[v.effectType] * 0.4 * 1.4)
			-- 连线
			for _, prePos in orderCsvPairs(v.preID) do
				self:setAngleByPos(item, v.id, prePos, false)
			end
		end
	end
end

--设置连线的位置夹角
function ExploreAbilityView:setAngleByPos(item, nowID, prePos, isActive)
	local nowCsv = csv.explorer.ability[nowID]
	local preCsv = gExplorerAbilityCsv[nowCsv.seqID][prePos]
	local x = preCsv.pos.x - nowCsv.pos.x
	local y = preCsv.pos.y - nowCsv.pos.y
	local itemSize = item:size()
	local offsetX, offsetY = itemSize.width / 2, itemSize.height / 2
	local abilities = self.explorers:read()[nowCsv.seqID].abilities or {}
	local preLv = abilities[prePos] or 0
	--距离
	local s = math.sqrt(math.pow(x, 2) + math.pow(y, 2))
	--角度
	local r = math.atan2(x, y) * 180 / math.pi
	r = r > 0 and r - 270 or r + 90
	local barBg = item:get("barBg" .. prePos)
	local height = self.barBg:size().height
	if not barBg then
		barBg = self.barBg:clone():show()
			:xy(offsetX + x / 2, offsetY + y / 2)
			:name("barBg" .. prePos)
			:setRotation(r)
			:size(s, height)
			:addTo(item, 1)
	end
	local bar = item:get("bar" .. prePos)
	if not bar then
		bar = self.bar:clone():show()
			:setCapInsets(cc.rect(30, 0, 1, 1))
			:xy(offsetX + x / 2, offsetY + y / 2)
			:name("bar" .. prePos)
			:setRotation(r)
			:size(s, height)
			:addTo(item, 2)
	end
	local precent = (preLv == 0 or isActive) and 10 or 100
	if bar:getPercent() == 10 or bar:getPercent() == 100 then
		bar:setPercent(precent)
	end
	if isActive then
		transition.executeParallel(item:get("bar" .. prePos))
			:progressTo(0.8, 100)
	end
end

--显示强化面板
function ExploreAbilityView:onItemClick(i, id)
	self.selectPos:set(i, true)

	gGameUI:stackUI("city.develop.explorer.ability.strengthen", nil, nil,
		{
			expID = self.explorerId:read(),
			id = id,
		},
		self:createHandler("onClosePanel")
	)
end

function ExploreAbilityView:onClosePanel()
	self.selectPos:set(0)
end

return ExploreAbilityView
