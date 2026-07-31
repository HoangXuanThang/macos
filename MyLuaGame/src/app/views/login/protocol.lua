local desc = {
	title = "Thỏa thuận dịch vụ và Chính sách quyền riêng tư",
	info1 = "Vui lòng đọc kỹ và hiểu rõ từng điều khoản trong 'Thỏa thuận dịch vụ' và 'Chính sách quyền riêng tư', bao gồm nhưng không giới hạn: Để cung cấp cho bạn các dịch vụ như nhắn tin tức thời, chia sẻ nội dung, chúng tôi cần thu thập thông tin thiết bị, nhật ký thao tác và các thông tin cá nhân khác của bạn. Bạn có thể xem, thay đổi, xóa thông tin cá nhân và quản lý quyền cho phép trong mục 'Cài đặt'.",
	info2 = "Bạn có thể đọc",
	info3 = "<Chính sách quyền riêng tư và Thỏa thuận người dùng>",
	info6 = "Để biết thêm chi tiết. Nếu bạn đồng ý, hãy nhấn “Đồng ý” để bắt đầu sử dụng dịch vụ của chúng tôi.",
	url = "https://hyrx-cdn.xw888.net/statics/agree.html "
}

local ViewBase = cc.load("mvc").ViewBase
local LoginProtocolView = class("LoginProtocolView", Dialog)

LoginProtocolView.RESOURCE_FILENAME = "login_protocol.json"

LoginProtocolView.RESOURCE_BINDING = {
	["btnDel"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onBtnDel")},
		},
	},
	["btnDel.text"] = {
		binds = {
			event = "effect",
			data = {outline = {color = ui.NEWCOLORS.OUTLINE.YELLOW, size = 4}},
		},
	},
	["btnAgree"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onBtnAgree")},
		},
	},
	["btnAgree.text"] = {
		binds = {
			event = "effect",
			data = {outline = {color = ui.NEWCOLORS.OUTLINE.YELLOW, size = 4}},
		},
	},
	["labelTitle"] = "labelTitle"
}


function LoginProtocolView:onCreate()
	self.labelTitle:text(desc.title):setFontSize(60)
	local str = {
		string.format("#C0x57472E##F50#%s\n", desc.info1),
		string.format("#C0x57472E##F50#%s#C0x04B508##L00010100##LUL%s#%s#C0x57472E#%s", desc.info2,
			desc.url, desc.info3, desc.info6),
	}

	local richText = rich.createWithWidth(table.concat(str),40,nil,1150)
		:anchorPoint(cc.p(0, 1))
		:xy(706 + display.uiOrigin.x, 920)
	self:getResourceNode():addChild(richText, 1, "richText")

	Dialog.onCreate(self, {clickClose = false,clearFast = true})
end


function LoginProtocolView:onBtnDel()
	display.director:endToLua()
end

function LoginProtocolView:onBtnAgree()
	self:addCallbackOnExit(self.cb)
	userDefault.setForeverLocalKey("protocalStatusSign", true, {rawKey = true})
	Dialog.onClose(self)
end

return LoginProtocolView