--
-- @desc 通用设置道具项
--
local helper = require "easy.bind.helper"

local stageIcon = class("supremacyStageIcon", cc.load("mvc").ViewBase)
stageIcon.defaultProps = {
	score = nil,
	showStateName = true,
	showScore = false,
	fontSize = 40,
	onNode = nil,
}

function stageIcon:initExtend()
	if self.panel then
		self.panel:removeFromParent()
	end
	self.panel = ccui.Layout:create():alignCenter(self:size()):addTo(self):anchorPoint(0.5, 0.5)
	helper.callOrWhen(self.score, function(score)
		local stageData = dataEasy.getSupremacyStageByRank(score)
		if stageData then
			ccui.ImageView:create(stageData.icon):addTo(self.panel):scale(0.5):y(20)
			if self.showStateName then
				local str = stageData.stageName
				if self.showScore then
					str = str .. " " .. stageData.score
				end
				local title = label.create(str, { fontPath = "font/youmi.ttf", fontSize = self.fontSize })
					:y(-60)
					:addTo(self.panel)
				text.addEffect(title,
					{ color = ui.COLORS.NORMAL.WHITE, outline = { color = ui.NEWCOLORS.OUTLINE.BLACK, size = 3 } })
			end
		end
	end)
	if self.onNode then
		self.onNode(self.panel)
	end
	return self
end

return stageIcon
