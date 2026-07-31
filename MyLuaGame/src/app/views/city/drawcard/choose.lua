local ViewBase = cc.load("mvc").ViewBase
local CardChoose1In2 = class("CardChoose1In2", ViewBase)

CardChoose1In2.RESOURCE_FILENAME = "drawcard_2choose1.json"
CardChoose1In2.RESOURCE_BINDING = {
	['left.btn'] = {
		binds = {
			event = 'touch',
			methods = { ended = bindHelper.self('clickLeft') }
		}
	},
	['left.card'] = {
		varname = 'card1',
		binds = {
			event = 'touch',
			methods = { ended = bindHelper.self('clickLeft') }
		}
	},
	["left.btn.textNote"] = {
		binds = {
			{
				event = "effect",
				data = { outline = { color = ui.NEWCOLORS.OUTLINE.YELLOW, size = 4 } }
			},

		},
	},
	["right.btn.textNote"] = {
		binds = {
			{
				event = "effect",
				data = { outline = { color = ui.NEWCOLORS.OUTLINE.YELLOW, size = 4 } }
			},

		},
	},
	['right.btn'] = {
		binds = {
			event = 'touch',
			methods = { ended = bindHelper.self('clickRight') }
		}
	},
	['right.card'] = {
		varname = 'card2',
		binds = {
			event = 'touch',
			methods = { ended = bindHelper.self('clickRight') }
		}
	}
}

function CardChoose1In2:onCreate(id, cb)
	self.id = id
	self.cb = cb
	local cfg = dataEasy.getCfgByKey(id)
	self.cardId = {}
	for i = 1, 2 do
		local k = "choose" .. i
		local v = cfg.specialArgsMap[k]
		local card = csv.cards[v.card.id]
		local unit = csv.unit[card.unitID]
		self.cardId[i] = v.card.id
		if unit.showOpen then
			local photoSprite = widget.addAnimation(self['card' .. i], unit.showOpen, "default", 5, true)
			if string.find(unit.showOpen, ".png") then

			else
				photoSprite:xy(0, 220):scale(0.5)
			end
		end
	end
end

function CardChoose1In2:clickLeft()
	local str = string.format(gLanguageCsv.confirmSelectSprite, csv.cards[self.cardId[1]].name)
	gGameUI:showDialog({
		title = gLanguageCsv.spaceTips,
		content = str,
		isRich = true,
		btnType = 2,
		cb = function()
			gGameApp:requestServer("/game/role/gift/choose", function(tb)
				self.choosed_dbid = tb.view.carddbIDs[1][1]
				self:onClose()
			end, self.id, 1, "choose1", true)
		end
	})
end

function CardChoose1In2:clickRight()
	local str = string.format(gLanguageCsv.confirmSelectSprite, csv.cards[self.cardId[2]].name)
	gGameUI:showDialog({
		title = gLanguageCsv.spaceTips,
		content = str,
		isRich = true,
		btnType = 2,
		cb = function()
			gGameApp:requestServer("/game/role/gift/choose", function(tb)
				self.choosed_dbid = tb.view.carddbIDs[1][1]
				self:onClose()
			end, self.id, 1, 'choose2', true)
		end
	})
end

function CardChoose1In2:onClose()
	if self.cb then
		self:addCallbackOnExit(functools.partial(self.cb, self.choosed_dbid))
	end
	ViewBase.onClose(self)
end

return CardChoose1In2
