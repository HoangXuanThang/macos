--@date 2019-4-8 16:57:41
--@desc 技能界面详情

local SkillDetailView = class("SkillDetailView", Dialog)

SkillDetailView.RESOURCE_FILENAME = "common_skill_detail.json"
SkillDetailView.RESOURCE_BINDING = {
	["imgBg"] = "imgBg",
	["panel"] = "panel",
	["panel.imgType"] = "imgType",
	["panel.imgIcon"] = "imgIcon",
	["panel.imgIcon_m"] = "imgIcon_m",
	["panel.textName"] = "skillName",
	["panel.textNoteType"] = "attackType",
	["panel.textLevel"] = "skillLv",
	["panel.textNote"] = "skillType",
	["panel.textSkillPower"] = "textSkillPower",
	["panel.textNum"] = "powerNum",
	["list"] = "list",
}

-- @params {skillId, skillLevel, cardId, star, skillIcon, ignoreStar, hideSkillLevel, isZawake}
function SkillDetailView:onCreate(params, typ)
	params.skillLevel = params.skillLevel or 1
	local skillCsv = csv.skill[params.skillId]
	if params.hideSkillLevel then
		self.skillLv:hide()
	else
		self.skillLv:text("Lv." .. params.skillLevel)
	end

	itertools.invoke({ self.textSkillPower, self.powerNum }, "hide")
	-- if skillCsv.skillType == battle.SkillType.NormalSkill then
	-- 技能威力先隐藏
	-- local skillPower = eval.doMixedFormula(tostring(skillCsv.skillPower),{skillLevel = params.skillLevel,math = math},nil)
	-- self.powerNum:text(skillPower)
	-- adapt.oneLinePos(self.textSkillPower, self.powerNum, cc.p(10, 0), "left")
	-- end

	uiEasy.setSkillInfoToItems({
		name = self.skillName,
		icon = self.imgIcon,
		type1 = self.imgType,
		type2 = self.skillType,
		target = self.attackType,
	}, skillCsv)
	if params.skillIcon then
		self.imgIcon:texture(params.skillIcon)
	end
	if params.isZawake then
		self.imgIcon_m:visible(false)
		ccui.ImageView:create("city/drawcard/draw/txt_up.png")
			:scale(0.8)
			:align(cc.p(1, 1), 145, 40)
			:addTo(self.imgIcon, 1, "zawakeUp")
		local zawakeEffectID = csv.skill[params.skillId].zawakeEffect[1]
		local skillName = csv.skill[zawakeEffectID]["skillName_"..LOCAL_LANGUAGE] or csv.skill[zawakeEffectID].skillName
		self.skillName:text(skillName.. self.skillName:text())
	else
		self.imgIcon_m:visible(false)
	end

	local desc = skillCsv["describe_"..LOCAL_LANGUAGE] or skillCsv.describe
	if params.isZawake and skillCsv.zawakeEffect[1] and skillCsv.zawakeEffect[2] ~= 1 then
		desc = skillCsv["zawakeEffectDesc_"..LOCAL_LANGUAGE] or skillCsv.zawakeEffectDesc
	end
	local starStr = params.ignoreStar and "" or uiEasy.getStarSkillDesc(params, typ)

	desc = string.gsub(desc, "#C0x5B545B#", "#C0xFFFFFF#")
	local list, height = beauty.textScroll({
		list = self.list,
		strs = "#C0xFFFFFF#" .. eval.doMixedFormula(desc, { skillLevel = params.skillLevel, math = math }, nil) ..
			starStr,
		isRich = true,
		fontSize = 40,
	})
	local diffHeight = cc.clampf(height, 250, 750) - 250
	self.imgBg:size(self.imgBg:size().width, self.imgBg:size().height + diffHeight)
	self.panel:y(self.panel:y() + diffHeight / 2)
	list:size(list:size().width, 250 + diffHeight)
	list:y(list:y() - diffHeight / 2)

	Dialog.onCreate(self, { noBlackLayer = true, clickClose = false })
end

return SkillDetailView
