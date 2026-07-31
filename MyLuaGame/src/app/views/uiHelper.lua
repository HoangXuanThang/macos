local uiHelper = {}

function uiHelper.autoFitFont(label, maxWidth, minFontSize)
	minFontSize = minFontSize or 12
	local fontSize = label:getFontSize()
	while fontSize >= minFontSize do
		label:setFontSize(fontSize)
		if label:getContentSize().width <= maxWidth then
			break
		end
		fontSize = fontSize - 1
	end
end

return uiHelper
