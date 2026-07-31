--  官服
local base = {}

--- 服务器标记
function base.getServerKind()
    return string.upper(APP_CHANNEL)
end

function base.login(cb)
    sdk.callPlatformFunc("login", "", function(info)
        print("login ret = ", info)
        -- sdk.loginInfo = info
        if info == "error" then
            cb(-1, info)
        elseif info == "cancel" then
            cb(-1, info)
        else
            cb(0, info)
            -- 漂浮球退出监听
            sdk.callPlatformFunc("logout", "assist", function(info)
                print("logout in assist ret = ", info)
                -- 内部保证多次调用无误
                gGameApp:onBackLogin()
            end)
        end
    end)
end

local roleInfoMap = {
    [1] = "EnterServer",
    [2] = "LevelUp",
    [3] = "ExitGame",
    [4] = "CreateRole",
    [8] = "ChangeName"
}
function base.commitRoleInfo(ctype, cb)
    local tmp = {
        ctype = ctype,
        area = gGameApp.serverInfo.name,
        level = tostring(gGameModel.role:read("level")),
        area_id = tostring(gGameModel.role:read("area")),
        user_name = gGameModel.role:read("name"),
        user_id = tostring(gGameModel.role:read("uid")),
        vip = tostring(gGameModel.role:read("vip_level")),
        created_time = tostring(gGameModel.role:read("created_time")),
        upload_type = roleInfoMap[ctype]
    }
    if tmp.upload_type == nil then
        return cb(0, "ok")
    end

    sdk.callPlatformFunc("commitRoleInfo", json.encode(tmp), function(info)
        print("commitRoleInfo ret = ", info)
        -- 没有返回值，不管成功失败
        cb(0, "ok")
    end)
end

function base.openUrl(url)

    sdk.callPlatformFunc("openUrl",url, function(info)
    	print("openUrl ret = ", info)
    end)
end



local eventMap = {
    [1] = "EVENTS_START_LOADING",
    [2] = "EVENTS_FINISHED_LOADING"
}
function base.trackEvent(ctype, data)
    if type(data) ~= "table" then
    	data = {data = data}
    end
    data.ctype = ctype
    data.event = eventMap[ctype] or ""
    sdk.callPlatformFunc("trackEvent", json.encode(data), function(info)
    	print("trackEvent ret = ", info)
    end)
end

function base.logout(cb)
    sdk.callPlatformFunc("logout", "game", function(info)
        print("logout ret = ", info)
        -- 有回调就是成功
        cb(0, "ok")
    end)
end

local defaultPrefix = {"cn.base.", 3}

local productPrefixTagMap = {}

-- !!! 需要自己解决多次充值请求问题
-- sdk后续没有界面，是在等待苹果系统支付界面
-- 回调也是在支付成功或者失败后返回
-- 即使请求超时也会有回调，但是网络不好，可能苹果系统拉起支付比较慢
-- 为了不阻断用户操作，并没有锁死UI
--[[
	"orderno": "20203254511312121",
    "money": "600",
    "prop_id": "600",
    "prop_name": "道具1",
    "prop_price": "600",
    "prop_quantity": "1",
    "prop_desc": "abc",
    "attach": "20203254511312121",
    "notify_url": "http://18.162.207.154/GCS/payCallback.php",
    "sign": "D04E2B9210AC29C2875F2AE045A0A069"
]]
function base.pay(cpOrderId, extInfo, amount, rechargeId, productDesc, notify_url, sign, cb)

    local roleInfo = gGameModel.role

    -- 相同channel不同包，根据tag来判断productID
    -- local prefix, startID = unpack(productPrefixTagMap[APP_TAG] or defaultPrefix)
    local productID = rechargeId

    -- local desc = productDesc
    -- -- productDescription字段的传值，礼包的描述修改为gift，钻石的描述修改为gem
    -- -- 我们通过这个值来区分是钻石还是礼包，因为现在商品id复用，需要用其他参数来区分
    -- -- 只针对ios的com.lzl.jxjjb的包就行
    -- if specialProductTagMap[APP_TAG] ~= nil then
    -- 	if rechargeId >= 3 and rechargeId <= 10 then
    -- 		desc = 'gem'
    -- 	else
    -- 		desc = 'gift'
    -- 	end
    -- end

    local tmp = {
        -- roleId = stringz.bintohex(roleInfo:read("id")),
        roleId = tostring(roleInfo:read("uid")),
        roleName = roleInfo:read("name"),
        roleLevel = tostring(roleInfo:read("level")),
        vip_level = tostring(roleInfo:read("vip_level")),
        area = gGameApp.serverInfo.name,
        area_id = tostring(roleInfo:read("area")),
        money = tostring(amount),

        extInfo = extInfo,
        currency = "cny", -- 人民币：cny
        prop_id = tostring(productID),
        prop_name = productDesc,
        prop_price = tostring(amount),
        prop_quantity = "1",
        prop_desc = productDesc,

        orderno = cpOrderId,
        notify_url = notify_url,
        sign = sign,
    }
    sdk.callPlatformFunc("pay", json.encode(tmp), function(info)
        print("pay ret = ", info)
        if info == "ok" then
            cb(0, info)
        else
            cb(-1, info)
        end
    end)
end

-- @desc 打开客服
function base.openCustomerService()
	sdk.callPlatformFunc("openCustomerService", "", function(info)
		print("openCustomerService ret = ", info)
	end)
end

-- @desc 打开官网
function base.openOfficialService()
	sdk.callPlatformFunc("openOfficialService", "", function(info)
		print("openOfficialService ret = ", info)
	end)
end

return base
