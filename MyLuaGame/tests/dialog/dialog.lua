local MyDialog = class("MyDialog", Dialog)

MyDialog.RESOURCE_FILENAME = "BB_CS_SY_Layer.json"
MyDialog.RESOURCE_BINDING = {
	["btn"] = "btn",
	["bg"] = "bg",
	["close"] = {
		varname = "btnClose",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onClose")},
		},
	},
}

function MyDialog:onPlayBegin()
	self.btn:setVisible(false)
	self.btnClose:setVisible(false)
end

function MyDialog:onPlayEnd()
	self.btn:setVisible(true)
	self.btnClose:setVisible(true)
end

function MyDialog:onCreate()
	Dialog.onCreate(self, {hasBlack = true, clearFast = false})
end

return MyDialog