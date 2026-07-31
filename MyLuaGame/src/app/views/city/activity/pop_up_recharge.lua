local RechargePopupView = class("RechargePopupView", Dialog)

RechargePopupView.RESOURCE_FILENAME = "activity_pop_up_recharge.json"
RechargePopupView.RESOURCE_STYLES = {
    blackLayer = true,
    clickClose = true,
}

RechargePopupView.RESOURCE_BINDING = {
    ["btnClose"] = {
        binds = {
            event = "touch",
            methods = { ended = bindHelper.self("onClose") }
        }
    },
    ["title"] = "title",
    ["payment_panel"] = "paymentPanel",
   
}

for i = 1, 8 do
    RechargePopupView.RESOURCE_BINDING["btn_package" .. i] = {
        varname = "btn_package" .. i,
        binds = {
            event = "touch",
            methods = { ended = bindHelper.self("onPackageClick") }
        }
    }
end


function RechargePopupView:onCreate()
    self.title:text(nil)
    
    self.rechargeDatas = {
        { id = "gold_1_usd", price = "0.99$", coins = 0.99 },
        { id = "gold_2_usd", price = "1.99$", coins = 1.99},
        { id = "gold_3_usd", price = "2.99$", coins = 2.99},
        { id = "gold_5_usd", price = "4.99$", coins = 49.99 },
        { id = "gold_10_usd", price = "9.99$", coins = 9.99},
        { id = "gold_20_usd", price = "19.99$", coins = 19.99},
        { id = "gold_50_usd", price = "49.99$", coins = 49.99},
        { id = "gold_100_usd", price = "99.99$", coins = 99.99},
    }
    
    for i = 1, 8 do
        local panel = self["btn_package" .. i]
        local labelPrice = panel:get("label_price")
        local labelCoins = panel:get("label_coins")
    
        labelPrice:text(self.rechargeDatas[i].price)
        labelCoins:text(" = " .. self.rechargeDatas[i].coins)
    
        labelPrice:setTextColor(cc.c4b(255, 255, 255, 255))
        labelCoins:setTextColor(cc.c4b(255, 255, 255, 255))

        if labelPrice.enableOutline then
            labelPrice:enableOutline(cc.c4b(0, 0, 0, 255), 2)
        end
        if labelCoins.enableOutline then
            labelCoins:enableOutline(cc.c4b(0, 0, 0, 255), 2)
        end
    end

    for i = 1, 8 do
        local panel = self["btn_package" .. i]
        if panel then
            local btn = panel:get("btn" .. i)
            if btn then
                btn:addTouchEventListener(function(sender, eventType)
                    if eventType == ccui.TouchEventType.ended then
                        self:openPaymentMethodUI(self.rechargeDatas[i])
                    end
                end)
            else
                print("Không tìm thấy button trong panel: " .. panelName)
            end
        else
            print("Không tìm thấy panel: " .. panelName)
        end
    end
    

    Dialog.onCreate(self, { blackType = 1 })
end


function RechargePopupView:openPaymentMethodUI(packageData)
    local success, err = pcall(function()
        if gGameUI:findStackUI("city.activity.payment_method") then
            print("payment_method đã có trong stack, không mở lại")
            return
        end
        -- Push UI
        local view = gGameUI:stackUI("city.activity.payment_method", nil, { blackType = 1 })
        if view and view.initWithParams then
            view:initWithParams(packageData)
        end
    end)

    if not success then
        print("Lỗi khi mở payment_method UI:", err)
    end
end

function RechargePopupView:onPackageClick(node)
    local btnName = node:getName()  
    local idx = tonumber(string.match(btnName, "%d+"))

    local data = self.rechargeDatas[idx]
    if data then
        print(string.format("Click package id = %s: %s - %d coins", data.id, data.price, data.coins))
        --self:openPaymentMethodUI(data)
        ---Xử lý thanh toán GG pay luôn tại đây---
        sdk.purchase("","","",data.id,function(code, info)
            if code == 0 then
            end
        end)
    else
        print("Không tìm thấy dữ liệu cho gói:", btnName)
    end
end
--com.manga.sea.android
return RechargePopupView