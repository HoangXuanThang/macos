local CharacterGainSpriteView = class("CharacterGainSpriteView", cc.load("mvc").ViewBase)
CharacterGainSpriteView.RESOURCE_FILENAME = "character_gain_sprite.json"
CharacterGainSpriteView.RESOURCE_BINDING = {
	["txt"] = "txt",
	["pos"] = "pos",
	["effect"] = "effect",
	["btnBegin.textNote"] = {
		binds = {
			event = "effect",
			data = {outline = {color = ui.NEWCOLORS.OUTLINE.YELLOW, size = 4}},
		},
	},
	["btnBegin"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onBegin")},
		},
	}
}

function CharacterGainSpriteView:onCreate(id, cb)
	self.cb = cb

	audio.playEffectWithWeekBGM("card_gain.mp3")
	local title = widget.addAnimationByKey(self.effect, "effect/gongxihuode.skel", "titleEft", "effect")
		title:xy(0, 0)

	title:setSpriteEventHandler(function(event, eventArgs)
		title:play("effect_loop")
	end, sp.EventType.ANIMATION_COMPLETE)

	local unit = csv.unit[csv.cards[id].unitID]
	local unitRes =   string.gsub(unit.unitRes, ".skel", "_ui.skel")
	local spine = widget.addAnimationByKey(self.pos, unitRes, "effect", "standby_loop")
	spine:xy(self.pos:size().width/2, 0)
		:scale(unit.scaleU*0.7)
	spine:setSkin(unit.skin)
	self.txt:text(string.format(gLanguageCsv.congratulationGetCard, csv.cards[id].name))
end

function CharacterGainSpriteView:onBegin()
	self.cb()
end

return CharacterGainSpriteView
