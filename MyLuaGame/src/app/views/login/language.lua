local validLangs = {
    ["vn"] = true,
    ["en"] = true,
    ["th"] = true,
    ["in"] = true,  -- "in" là từ khóa nên cần dùng ["in"]
    ["ma"] = true,
}
local function exitGame()
	cc.Director:getInstance():getScheduler():scheduleScriptFunc(function()
		cc.Director:getInstance():endToLua()
	end, 0, false)
	
end
local function onChooseLanguage(lang)
	print("lang choose", lang)
	if not validLangs[lang] then
		gGameUI:showTip("Please choose a valid language")
		userDefault.setForeverLocalKey("local_language", "en", {rawKey = true})
		return
	end
	if "ma" == lang then
		lang = "ma"
	end
	userDefault.setForeverLocalKey("local_language", lang, {rawKey = true})
	cc.UserDefault:getInstance():flush()
	
	gGameUI:showDialog({
		title = gLanguageCsv.tips,
		content = "Please restart the game to apply the new language.",
		dialogParams = {clickClose = false},
		cb = exitGame,
		closeCb = exitGame,
		delayTime = 3,
		isRich = true,
		btnType = 2,
		
	})



end

local ChangeLanguageView = class("ChangeLanguageView", Dialog)

ChangeLanguageView.RESOURCE_FILENAME = "change_language.json"
ChangeLanguageView.RESOURCE_BINDING = {
	["bg"] = "bg",
	["closeBtn"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onClose")},
		},
	},
	["titleTxt"] = "titleTxt",

	["langVNBtn"] = {
		varname = "langVNBtn",
		binds = {
			event = "touch",
			methods = {
				ended = function(node, event)
					onChooseLanguage("vn")
				end
			}
		},
	},
	["langVNBtn.text"] = {
		varname = "langVNText",
		binds = {
			event = "effect",
			data = {outline = {color = ui.NEWCOLORS.OUTLINE.RED}},
		},
	},



	["langENBtn"] = {
		varname = "langENBtn",
		binds = {
			event = "touch",
			methods = {
				ended = function(node, event)
					onChooseLanguage("en")
				end
			}
		},
	},
	["langENBtn.text"] = {
		varname = "langENText",
		binds = {
			event = "effect",
			data = {outline = {color = ui.NEWCOLORS.OUTLINE.RED}},
		},
	},


	["langTHBtn"] = {
		varname = "langTHBtn",
		binds = {
			event = "touch",
			methods = {
				ended = function(node, event)
					onChooseLanguage("th")
				end
			}
		},
	},
	["langTHBtn.text"] = {
		varname = "langTHText",
		binds = {
			event = "effect",
			data = {outline = {color = ui.NEWCOLORS.OUTLINE.RED}},
		},
	},

	["langINBtn"] = {
		varname = "langINBtn",
		binds = {
			event = "touch",
			methods = {
				ended = function(node, event)
					onChooseLanguage("in")
				end
			}
		},
	},
	["langINBtn.text"] = {
		varname = "langINText",
		binds = {
			event = "effect",
			data = {outline = {color = ui.NEWCOLORS.OUTLINE.RED}},
		},
	},
	["langMABtn"] = {
		varname = "langMABtn",
		binds = {
			event = "touch",
			methods = {
				ended = function(node, event)
					onChooseLanguage("ma")
				end
			}
		},
	},
	["langMABtn.text"] = {
		varname = "langMAText",
		binds = {
			event = "effect",
			data = {outline = {color = ui.NEWCOLORS.OUTLINE.RED}},
		},
	},
}

-- params.maxFontCount 显示最长中文个数，对应的长度限制
function ChangeLanguageView:onCreate(params)
	self.titleTxt:text(gLanguageCsv.changeLanguageTitle)
	self.titleTxt:setTextColor(ui.COLORS.WHITE)
	
	self:InitButton()
end
function ChangeLanguageView:InitButton()
	self.langVNText:text("Việt Nam")
	self.langVNText:setTextColor(ui.COLORS.WHITE)

	self.langENText:text("English")
	self.langENText:setTextColor(ui.COLORS.WHITE)

	self.langTHText:text("ไทย")
	self.langTHText:setTextColor(ui.COLORS.WHITE)

	self.langINText:text("Bahasa Indonesia")
	self.langINText:setTextColor(ui.COLORS.WHITE)

	self.langMAText:text("Bahasa Melayu")
	self.langMAText:setTextColor(ui.COLORS.WHITE)

end


function ChangeLanguageView:createSupportLabel(parent, text, fontSize, onClick)
	local lbl = label.create(text, {
		fontPath = "font/youmi1.ttf",
		fontSize = fontSize,
		color = ui.COLORS.NORMAL.WHITE,
		pos = cc.p(parent:getContentSize().width/2, -20),
		effect = {outline = {color = ui.COLORS.OUTLINE.DEFAULT}},
	}):addTo(parent)
	bind.touch(self, parent, {methods = {ended = onClick}})
	return lbl
end
return ChangeLanguageView
