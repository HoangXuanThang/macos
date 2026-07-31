-- ConfigAPI: HTTP API calls for user info and money
local ConfigAPI = {}

-- Lazy load crypto chỉ khi cần (trong sendUserInfo)
-- Note: crypto module không tồn tại, chỉ load khi thực sự cần
local function getCrypto()
    local ok, crypto = pcall(require, "crypto")
    if not ok then
        print("WARNING: crypto module not found, signature will not work")
        return nil
    end
    return crypto
end

-- Local function để tạo signature (không phải global)
local function createSignature(username, device, timestamp, CLIENT_KEY)
    local crypto = getCrypto()
    if not crypto then
        -- Fallback: return empty signature if crypto not available
        print("WARNING: Cannot create signature, crypto module not available")
        return ""
    end
    local raw = string.format("username=%s&device=%s&timestamp=%s&key=%s", username, device, timestamp, CLIENT_KEY)
    local sign = crypto.digest("sha256", raw)
    return sign
end

function ConfigAPI.getUserInfo(cb)
    local token = cc.UserDefault:getInstance():getStringForKey("accessToken", "")
    local username = cc.UserDefault:getInstance():getStringForKey("username", "")
    
    -- Build URL with username as query parameter if token is empty
    local url = GET_INFORMATION_CONFIG
    if token == "" and username ~= "" then
        url = url .. "?username=" .. username
    end
    
    local xhr = cc.XMLHttpRequest:new()
    xhr.responseType = cc.XMLHTTPREQUEST_RESPONSE_STRING
    xhr:open("GET", url)
    xhr.timeout = 10
    xhr:setRequestHeader("Content-Type", "application/json")
    if token ~= "" then
        xhr:setRequestHeader("Authorization", "Bearer " .. token)
    end
    xhr:setRequestHeader("Accept", "application/json")

    xhr:registerScriptHandler(function()
        print("XHR readyState:", xhr.readyState)
        print("XHR status:", xhr.status)
        print("XHR response:", xhr.response)

        if xhr.readyState ~= 4 then
            return
        end
        
        if xhr.status == 200 then
            local response = json.decode(xhr.response)
            if response and response.data then
                if cb then cb(true, response) end
            else
                if cb then cb(false, { message = "Không có data" }) end
            end
        else
            if cb then cb(false, { message = "HTTP status " .. xhr.status, response = xhr.response }) end
        end
    end)

    xhr:send()
end

-- Lấy số dư money trực tiếp từ HTTP API (bỏ qua game server)
function ConfigAPI.getUserMoney(cb)
    local username = cc.UserDefault:getInstance():getStringForKey("username", "")
    
    -- Nếu username rỗng, dùng "nghia" làm default
    if username == "" then
        username = "nghia"
        print("Username is empty, using default: nghia")
    end
    
    -- Gọi API get-user-info.php trực tiếp
    local url = GET_USER_MONEY_API .. "?username=" .. username
    
    local xhr = cc.XMLHttpRequest:new()
    xhr.responseType = cc.XMLHTTPREQUEST_RESPONSE_STRING
    xhr:open("GET", url)
    xhr.timeout = 10
    xhr:setRequestHeader("Content-Type", "application/json")
    xhr:setRequestHeader("Accept", "application/json")

    xhr:registerScriptHandler(function()
        if xhr.readyState ~= 4 then
            return
        end
        
        if xhr.status == 200 then
            local response = json.decode(xhr.response)
            if response and response.ret and response.view and response.view.data and response.view.data.money then
                local money = tonumber(response.view.data.money) or 0
                print("getUserMoney success:", money)
                if cb then cb(true, { money = money, data = response.view.data }) end
            else
                print("getUserMoney: Invalid response format")
                if cb then cb(false, { message = "Invalid response format", response = response }) end
            end
        else
            print("getUserMoney error: HTTP", xhr.status)
            if cb then cb(false, { message = "HTTP status " .. xhr.status, response = xhr.response }) end
        end
    end)

    xhr:send()
end

-- Trừ tiền từ balance sau khi mua
function ConfigAPI.deductBalance(username, amount, cb)
    if username == "" then
        username = "nghia"
        print("Username is empty in deductBalance, using default: nghia")
    end
    
    if amount <= 0 then
        if cb then cb(false, { message = "Invalid amount" }) end
        return
    end
    
    -- Gọi API deduct-balance.php
    local url = DEDUCT_BALANCE_API .. "?username=" .. username .. "&amount=" .. amount
    
    local xhr = cc.XMLHttpRequest:new()
    xhr.responseType = cc.XMLHTTPREQUEST_RESPONSE_STRING
    xhr:open("POST", url)
    xhr.timeout = 10
    xhr:setRequestHeader("Content-Type", "application/json")
    xhr:setRequestHeader("Accept", "application/json")

    xhr:registerScriptHandler(function()
        if xhr.readyState ~= 4 then
            return
        end
        
        print("deductBalance XHR status:", xhr.status)
        print("deductBalance XHR response:", xhr.response)
        
        if xhr.status == 200 then
            if not xhr.response or xhr.response == "" then
                print("deductBalance: Empty response")
                if cb then cb(false, { message = "Empty response" }) end
                return
            end
            
            local ok, response = pcall(json.decode, xhr.response)
            if not ok then
                print("deductBalance: JSON decode error:", response)
                if cb then cb(false, { message = "JSON decode error: " .. tostring(response) }) end
                return
            end
            
            if response and response.ret and response.view and response.view.data then
                local newBalance = tonumber(response.view.data.money) or 0
                print("deductBalance success: deducted", amount, ", new balance:", newBalance)
                if cb then cb(true, { money = newBalance, data = response.view.data }) end
            else
                print("deductBalance: Invalid response format")
                if cb then cb(false, { message = "Invalid response format", response = response }) end
            end
        else
            print("deductBalance error: HTTP", xhr.status)
            local errMsg = "HTTP status " .. xhr.status
            local response = nil
            if xhr.response and xhr.response ~= "" then
                local ok, decoded = pcall(json.decode, xhr.response)
                if ok and decoded then
                    response = decoded
                    if decoded.err then
                        errMsg = decoded.err
                    end
                end
            end
            if cb then cb(false, { message = errMsg, response = response }) end
        end
    end)

    xhr:send()
end

function ConfigAPI.sendUserInfo(cb)
    local platform_post = 3
    if device.platform == "android" then
        platform_post = 1
    elseif device.platform == "ios" then
        platform_post = 2
    end

    local username = cc.UserDefault:getInstance():getStringForKey("username", "")
    local token = cc.UserDefault:getInstance():getStringForKey("accessToken", "")
    local timestamp = os.time()
    local CLIENT_KEY = "thienlongthanma-4mcode"  -- CLIENT_KEY từ config.php

    local signature = createSignature(username, platform_post, timestamp, CLIENT_KEY)

    -- Param dạng form-urlencoded
    local params = string.format("username=%s&device=%s&timestamp=%s&signature=%s",
        username, platform_post, timestamp, signature)

    local headers = {
        ["Content-Type"] = "application/x-www-form-urlencoded",
        ["Authorization"] = "Bearer " .. token,
        ["Accept"] = "application/json",
    }

    gGameApp.net:sendHttpRequest("POST", globals.SEND_INFORMATION_CONFIG, params, cc.XMLHTTPREQUEST_RESPONSE_STRING, function(xhr)
        print("POST XHR status:", xhr.status)
        print("POST XHR response:", xhr.response)

        if xhr.status == 200 then
            local response = json.decode(xhr.response)
            if cb then cb(true, response) end
        else
            if cb then cb(false, { message = "HTTP status " .. xhr.status, response = xhr.response }) end
        end
    end, headers)
end

-- Đăng nhập với username và password
function ConfigAPI.login(username, password, cb)
    if username == "" or password == "" then
        if cb then cb(false, { message = "Vui lòng nhập đầy đủ thông tin" }) end
        return
    end
    
    local url = LOGIN_API
    local params = json.encode({
        username = username,
        password = password
    })
    
    local xhr = cc.XMLHttpRequest:new()
    xhr.responseType = cc.XMLHTTPREQUEST_RESPONSE_STRING
    xhr:open("POST", url)
    xhr.timeout = 10
    xhr:setRequestHeader("Content-Type", "application/json")
    xhr:setRequestHeader("Accept", "application/json")

    xhr:registerScriptHandler(function()
        if xhr.readyState ~= 4 then
            return
        end
        
        if xhr.status == 200 then
            local ok, response = pcall(json.decode, xhr.response)
            if ok and response and response.status == "success" then
                print("Login success:", response.message)
                -- Lưu token và username
                if response.data and response.data.token then
                    cc.UserDefault:getInstance():setStringForKey("accessToken", response.data.token)
                end
                cc.UserDefault:getInstance():setStringForKey("username", username)
                cc.UserDefault:getInstance():flush()
                
                if cb then cb(true, response.data) end
            else
                local errMsg = "Đăng nhập thất bại"
                if ok and response and response.message then
                    errMsg = response.message
                end
                print("Login failed:", errMsg)
                if cb then cb(false, { message = errMsg, response = response }) end
            end
        else
            local errMsg = "HTTP status " .. xhr.status
            local response = nil
            if xhr.response and xhr.response ~= "" then
                local ok, decoded = pcall(json.decode, xhr.response)
                if ok and decoded then
                    response = decoded
                    if decoded.message then
                        errMsg = decoded.message
                    end
                end
            end
            print("Login error:", errMsg)
            if cb then cb(false, { message = errMsg, response = response }) end
        end
    end)

    xhr:send(params)
end

-- Đăng ký tài khoản mới
function ConfigAPI.register(username, password, email, cb)
    if username == "" or password == "" then
        if cb then cb(false, { message = "Vui lòng nhập đầy đủ thông tin" }) end
        return
    end
    
    local url = REGISTER_API
    local params = json.encode({
        username = username,
        password = password,
        email = email or ""
    })
    
    local xhr = cc.XMLHttpRequest:new()
    xhr.responseType = cc.XMLHTTPREQUEST_RESPONSE_STRING
    xhr:open("POST", url)
    xhr.timeout = 10
    xhr:setRequestHeader("Content-Type", "application/json")
    xhr:setRequestHeader("Accept", "application/json")

    xhr:registerScriptHandler(function()
        if xhr.readyState ~= 4 then
            return
        end
        
        if xhr.status == 200 then
            local ok, response = pcall(json.decode, xhr.response)
            if ok and response and response.status == "success" then
                print("Register success:", response.message)
                if cb then cb(true, response.data) end
            else
                local errMsg = "Đăng ký thất bại"
                if ok and response and response.message then
                    errMsg = response.message
                end
                print("Register failed:", errMsg)
                if cb then cb(false, { message = errMsg, response = response }) end
            end
        else
            local errMsg = "HTTP status " .. xhr.status
            local response = nil
            if xhr.response and xhr.response ~= "" then
                local ok, decoded = pcall(json.decode, xhr.response)
                if ok and decoded then
                    response = decoded
                    if decoded.message then
                        errMsg = decoded.message
                    end
                end
            end
            print("Register error:", errMsg)
            if cb then cb(false, { message = errMsg, response = response }) end
        end
    end)

    xhr:send(params)
end

return ConfigAPI