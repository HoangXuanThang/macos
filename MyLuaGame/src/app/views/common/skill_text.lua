-- @date: 2020-8-28

local SkillTextView = class("TextView", Dialog)
SkillTextView.RESOURCE_FILENAME = "common_text.json"
SkillTextView.RESOURCE_BINDING = {
	["baseNode"] = "baseNode",
	["baseNode.bg"] = "bg",
}

function SkillTextView:onCreate(params)
	local skillCsv = csv.skill[params.skillId]
	local list, height = beauty.textScroll({
		size = cc.size(600, 300),
		strs = "#C0x5B545B#" ..
			eval.doMixedFormula(skillCsv.describe, { skillLevel = params.skillLevel or 1, math = math }, nil),
		isRich = true,
		fontSize = 40,
	})
	list:addTo(self.bg, 2, "em")
	list:x(40)

	Dialog.onCreate(self, { blackType = 1 })
end

return SkillTextView
