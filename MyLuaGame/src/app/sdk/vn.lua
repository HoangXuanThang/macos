--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2017 TianJi Information Technology Inc.
--
-- vn
--

local vn = {}

-- 1.如果用户是第一次登录，则系统将进入登录界面。
-- 2.如果用户已经登录过则系统将根据前一次的设置信息判断是否自动登录:若自动登录则系统 将进行自动登录;若不是自动登录则系统将进入登录界面。
-- 3.用户可以选择输入已有的用户名和密码进行登录，也可以进入注册界面重新注册新账号，登 录及注册界面的具体功能和操作可以进入登录和注册界面查看。
function vn.login(cb)
	sdk.callPlatformFunc("login", "", function(info)
		print("login ret = ", info)
		sdk.loginInfo = info
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
	[8] = "ChangeName",
}
function vn.commitRoleInfo(ctype, cb)
	local tmp = {
		ctype = ctype,
		area = gGameApp.serverInfo.name,
		level = tostring(gGameModel.role:read("level")),
		area_id = tostring(gGameModel.role:read("area")),
		user_name = gGameModel.role:read("name"),
		user_id = tostring(gGameModel.role:read("uid")),
		vip = tostring(gGameModel.role:read("vip_level")),
		created_time = tostring(gGameModel.role:read("created_time")),
		upload_type = roleInfoMap[ctype],
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

local eventMap = {
	[1] = "EVENTS_START_LOADING",
	[2] = "EVENTS_FINISHED_LOADING",
}
function vn.trackEvent(ctype, data)
	-- if type(data) ~= "table" then
	-- 	data = {data = data}
	-- end
	-- data.ctype = ctype
	-- data.event = eventMap[ctype] or ""
	-- sdk.callPlatformFunc("trackEvent", json.encode(data), function(info)
	-- 	print("trackEvent ret = ", info)
	-- end)
end

function vn.logout(cb)
	print("注销被调用===========================")
	sdk.callPlatformFunc("logout", "game", function(info)
		print("logout ret = ", info)
		-- 有回调就是成功
		cb(0, "ok")
	end)
end


-- !!! 需要自己解决多次充值请求问题
-- sdk后续没有界面，是在等待苹果系统支付界面
-- 回调也是在支付成功或者失败后返回
-- 即使请求超时也会有回调，但是网络不好，可能苹果系统拉起支付比较慢
-- 为了不阻断用户操作，并没有锁死UI
function vn.pay(cpOrderId, extInfo, amount, rechargeId, productDesc, cb)
	-- 体验服
	if "tiyan_test" == APP_TAG then
		cb(-1, "error")
		return
	end

	local roleInfo = gGameModel.role

	-- 相同channel不同包，根据tag来判断productID
	local productID = rechargeId

	local tmp = {
		-- roleId = stringz.bintohex(roleInfo:read("id")),
		roleId = tostring(roleInfo:read("uid")),
		roleName = roleInfo:read("name"),
		roleLevel = tostring(roleInfo:read("level")),
		area = gGameApp.serverInfo.name,
		area_id = tostring(roleInfo:read("area")),
		vip = tostring(gGameModel.role:read("vip_level")),
		rmb = amount/10,
		amount = amount,
		count = 1,
		extInfo = extInfo,
		productDesc = desc,
		currency = "cny", -- 人民币：cny
		productName = productDesc,
		-- productID = "com.gavegame.applepaytest.6", -- TEST:
		productID = productID,
		cpOrderId = cpOrderId,
	}
	--dump(json.encode(tmp))
	sdk.callPlatformFunc("pay", json.encode(tmp), function(info)
		print("pay ret = ", info)
		if info == "ok" then
			cb(0, info)
		else
			cb(-1, "error")
		end
	end)
end

-- 1.检查账号类型接口返回失败的情况下，请重新调用接口3次，接口间隔建议为1分钟，如果3次请求都返回失败，则认为是游客账号
-- 2.实名认证接口，在未弹出实名认证界面的情况下返回 失败回调，请重新调用接口3次，接口间隔建议为1分钟，如果3次请求都返回失败，则认为未实名
-- 3.建议游戏也需要控制相关时长功能的限制开关

local SkipIdentityTag = {
	android_17849_20200218 = true,
	android_10054_20191230 = true,
	android_10054 = true,
}

-- 防沉迷，身份信息，成年/未成年
-- @return nil未实名，int年龄
function vn.queryIdentity(cb, count)
	print("queryIdentity===============================")
	-- if SkipIdentityTag[APP_TAG] or device.platform ~= "android" then
	-- 	return cb(nil)
	-- end

	-- count = (count or 0) + 1
	-- if count > 3 then
	-- 	return cb(0)
	-- end

	-- -- TODO: 旧包没有相关接口不会报错，但逻辑上需要处理成已注册用户

	-- sdk.callPlatformFunc("queryIdentity", "", function(age)
	-- 	print("queryIdentity ret = ", age)
	-- 	if age == "error" then
	-- 		performWithDelay(gGameUI.scene, function()
	-- 			vn.queryIdentity(cb, count)
	-- 		end, 60)
	-- 	elseif age == "closed" then
	-- 		cb(nil)
	-- 	else
	-- 		cb(tonumber(age))
	-- 	end
	-- end)
end

-- 防沉迷，用户类型, 游客/非游客
-- 实名注册后就是非游客
-- @return userType == 0 游客，userType == 1 非游客
function vn.queryUserType(cb, count)
	print("queryUserType======================")
	-- if SkipIdentityTag[APP_TAG] or device.platform ~= "android" then
	-- 	return cb(nil)
	-- end

	-- count = (count or 0) + 1
	-- if count > 3 then
	-- 	return cb(0)
	-- end

	-- sdk.callPlatformFunc("queryUserType", "", function(typ)
	-- 	print("queryUserType ret = ", typ)
	-- 	if typ == "error" then
	-- 		performWithDelay(gGameUI.scene, function()
	-- 			vn.queryUserType(cb, count)
	-- 		end, 60)
	-- 	elseif typ == "closed" then
	-- 		cb(nil)
	-- 	else
	-- 		-- TODO: 游客转注册用户
	-- 		cb(tonumber(typ))
	-- 	end
	-- end)
end

function vn.openCustomerService()
	print("openCustomerService========================")
	-- sdk.callPlatformFunc("openCustomerService", "", function(info)
	-- 	print("openCustomerService ret = ", info)
	-- end)
end

function vn.openPrivacyProtocols()
	print("openPrivacyProtocols======================")
	-- sdk.callPlatformFunc("openPrivacyProtocols","",function(info)
	-- 	print("openPrivacyProtocols ret = ",info)
	-- end)
end

function vn.openPermissionSetting()
	print("openPermissionSetting==========================")
	-- sdk.callPlatformFunc("openPermissionSetting","",function(info)
	-- 	print("openPermissionSetting ret = ",info)
	-- end)
end

return vn


