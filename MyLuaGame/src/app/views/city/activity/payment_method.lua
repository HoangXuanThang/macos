local RechargeMethodView = class("RechargeMethodView", Dialog)

RechargeMethodView.RESOURCE_FILENAME = "activity_payment_method_popup.json"
RechargeMethodView.RESOURCE_STYLES = {
    blackLayer = true,
    clickClose = true,
}

RechargeMethodView.RESOURCE_BINDING = {
    ["btnClose"] = {
        binds = {
            event = "touch",
            methods = { ended = bindHelper.self("onClose") }
        }
    },
    ["title"] = "title",
    ["payment_panel"] = "paymentPanel",
}

-- Thêm 2 button method
for i = 1, 2 do
    RechargeMethodView.RESOURCE_BINDING["btn_method" .. i] = {
        varname = "btn_method" .. i,
        binds = {
            event = "touch",
            methods = { ended = bindHelper.self("onMethodClick") }
        }
    }
end

function RechargeMethodView:onCreate()

    self.methodDatas = {
        { id = 1, method = "Google Pay" },
        { id = 2, method = "Other Pay" },
    }

    for i, data in ipairs(self.methodDatas) do
        local panel = self["btn_method" .. i]
        if panel then
            local label = panel:get("label_method")
            if label then
                label:text(data.method)
            end
        end
    end

    self.title:text("Choose a recharge method")

    Dialog.onCreate(self, { blackType = 1 })
end

function RechargeMethodView:initWithParams(packageData)
    self.packageData = packageData

    if self.title and packageData and packageData.price then
        self.title:text("Choose a recharge method for package: " .. packageData.price)
    else
        self.title:text("Choose a recharge method")
    end
end


function RechargeMethodView:onMethodClick(node)
    local btnName = node:getName()
    local idx = tonumber(string.match(btnName, "%d+"))
    print("self.packageData", self.packageData)
    local method = self.methodDatas[idx]
    if method and self.packageData then
        print(string.format("Đã chọn: %s cho gói %s (%d coin)",
            method.method, self.packageData.price, self.packageData.coins))
        -- Gọi xử lý thanh toán thật ở đây
        -- todo----
    end
end


return RechargeMethodView
