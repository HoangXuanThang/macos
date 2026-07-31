--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2017 TianJi Information Technology Inc.
--
-- lp
--

local lp_vn = {}

-- 1.如果用户是第一次登录，则系统将进入登录界面。
-- 2.如果用户已经登录过则系统将根据前一次的设置信息判断是否自动登录:若自动登录则系统 将进行自动登录;若不是自动登录则系统将进入登录界面。
-- 3.用户可以选择输入已有的用户名和密码进行登录，也可以进入注册界面重新注册新账号，登 录及注册界面的具体功能和操作可以进入登录和注册界面查看。
function lp_vn.login(cb)
	sdk.callPlatformFunc("login", "", function(info)
		if info == "error" then
			cb(-1, info)
		elseif info == "cancel" then
			cb(-1, info)
		else
			if APP_CHANNEL =="lp_vn" then
				
				local datas = json.decode(info)
				local username = datas['display_name']
				local role = datas['role']
				if role and role == "ROLE_TEST" then
					IS_DEV_ACCOUNT = true
				end
				if username and (username == "test1" or username == "ggtest" or username == "appletest") then
					IS_DEV_ACCOUNT = true
				end


				-- if device.platform == "ios" then
				-- 	IS_DEV_ACCOUNT = true
				-- end
			end
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

function lp_vn.switch(cb)
	print("Lua lp_en.switchAccount")
	sdk.callPlatformFunc("switchAccount", "", function(info)
		print("logout switchAccount = ", info)
		
		if info ~=nil then
			local datas = json.decode(info)
			if datas ~=nil and datas["code"] =="1" then
				cb(1,"ok")
			else
				cb(0, "ok")
			end
		else
			cb(0, "ok")
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
function lp_vn.commitRoleInfo(ctype, cb)
	print("Lua lp_vn.commitRoleInfo")
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
function lp_vn.trackEvent(ctype, data)
	print("Lua lp_vn.trackEvent")
	if type(data) ~= "table" then
		data = {data = data}
	end
	data.ctype = ctype
	data.event = eventMap[ctype] or ""
	sdk.callPlatformFunc("trackEvent", json.encode(data), function(info)
		print("trackEvent ret = ", info)
	end)
end

function lp_vn.logout(cb)
	print("Lua lp_vn.logout")
	sdk.callPlatformFunc("logout", "game", function(info)
		print("logout ret = ", info)
		-- 有回调就是成功
		cb(0, "ok")
	end)
end

-- 1. 由于app store应用内支付功能的限制，越狱设备在进行应用内购买时无法支付成功， SDK将消除loading并返回支付失败。
-- 2. 网游支付务必以服务端支付结果为准。
-- 3. 母包包含自有渠道支付与appStore支付，支付方式按照包名，版本号，商品ID动态配置


-- BundleID: com.de.dgf iOS
-- 内购商品名称	内购商品ID	   台币
-- 66 钻石       mcdbz01        33
-- 140 钻石      mcdbz02        70
-- 200 钻石      mcdbz03        100
-- 260 钻石      mcdbz04        130
-- 340 钻石      mcdbz05        170
-- 580           mcdbz06       290
-- 860           mcdbz07       430
-- 980           mcdbz08       490
-- 1340          mcdbz09       670
-- 1740          mcdbz10       870
-- 1980          mcdbz11       990
-- 3380          mcdbz12       1690
-- 6580          mcdbz13       3290 

local defaultPrefix = {"com.de.dgf", 3}

local productPrefixTagMap = {
	lp_vn = {"vnkdjx_money_",1},
	com_de_dgf = {"mcdbz",1100}
}

-- !!! 需要自己解决多次充值请求问题
-- sdk后续没有界面，是在等待苹果系统支付界面
-- 回调也是在支付成功或者失败后返回
-- 即使请求超时也会有回调，但是网络不好，可能苹果系统拉起支付比较慢
-- 为了不阻断用户操作，并没有锁死UI
function lp_vn.pay(cpOrderId, extInfo, amount, rechargeId, productDesc, cb)
	local roleInfo = gGameModel.role
	local accountId = stringz.bintohex(gGameModel.role:read("account_id"))
	local userName = gGameModel.account:read("name")
	local realamount = 0

	if rechargeId == 1 then
		realamount = 100000
	elseif rechargeId == 2 then
		realamount = 200000
	elseif rechargeId == 3 then
		realamount = 5000000
	elseif rechargeId == 4 then
		realamount = 2000000
	elseif rechargeId == 5 then
		realamount = 1000000
	elseif rechargeId == 6 then
		realamount = 500000
	elseif rechargeId == 7 then
		realamount = 200000
	elseif rechargeId == 8 then
		realamount = 100000
	elseif rechargeId == 9 then
		realamount = 50000
	elseif rechargeId == 10 then
		realamount = 20000
	elseif rechargeId == 11 then
		realamount = 10000
	elseif rechargeId == 102 then
		realamount = 10000
	elseif rechargeId == 103 then
		realamount = 20000
	elseif rechargeId == 104 then
		realamount = 30000
	elseif rechargeId == 105 then
		realamount = 40000
	elseif rechargeId == 106 then
		realamount = 50000
	elseif rechargeId == 107 then
		realamount = 100000
	elseif rechargeId == 108 then
		realamount = 150000
	elseif rechargeId == 109 then
		realamount = 200000
	elseif rechargeId == 110 then
		realamount = 250000
	elseif rechargeId == 111 then
		realamount = 300000
	elseif rechargeId == 112 then
		realamount = 500000
	elseif rechargeId == 113 then
		realamount = 1000000
	end

	local tmp = {
		count = 1,
		accountId = accountId,
		userName = userName,
		currency = "vnd",
		roleId = stringz.bintohex(roleInfo:read("id")),
		roleName = roleInfo:read("name"),
		roleLevel = _roleLevel,
		area = gGameApp.serverInfo.name,
		area_id = tostring(roleInfo:read("area")),
		rmb = amount,
		amount = amount,
		extInfo = extInfo,
		
		param = extInfo,

		productName = productDesc,

		rechargeId = rechargeId,

		cpOrderId = cpOrderId,

		money = realamount,
	}
	sdk.callPlatformFunc("pay", json.encode(tmp), function(info)
		print("pay ret = ", info)

		if info ~=nil then
			local datas = json.decode(info)
			if datas ~=nil then
				if datas["code"] =="0" then
					cb(0, "ok")
					do return end
				 end
				 if datas["code"] =="-1" then
					gGameUI:showTip("Không đủ số dư trong tài khoản, vui lòng nạp thêm để tiếp tục")
					cb(-1, "error")
				 end

				if datas["code"] =="-2" then
					gGameUI:showTip("Thông tin chưa được cập nhật, vui lòng thoát game và đăng nhập lại")
					cb(-1, "error")
				end
			else
				gGameUI:showTip("Lỗi không xác định, vui lòng liên hệ admin")
				cb(-1, "error")
			end
		else
			gGameUI:showTip("Lỗi không xác định, vui lòng liên hệ admin")
			cb(-1, "error")
		end
	end)
	

	-- local params = string.format("accountId=%s&orderStatus=1&orderId=%s&money=%d&amount=%d&param=%s&username=%s&serverid=%d&uid=%d&order=%d",
	-- 	accountId, cpOrderId,realamount, realamount, extInfo, username, gGameModel.role:read("area"), gGameModel.role:read("uid"), rechargeId)
	-- gGameApp.net:sendHttpRequest("POST", PY_CFG, params, cc.XMLHTTPREQUEST_RESPONSE_STRING,
	-- 	function(xhr)
	-- 		if xhr.status == 200 then
	-- 			local obj = json.decode(xhr.response)
	-- 			print("sendHttpRequest", obj)
	-- 			if obj.code == 200 then
	-- 				gGameUI:showTip("Giao dịch thành công!")
	-- 				cb(0)
	-- 			elseif obj.code == 201 then
	-- 				gGameUI:showTip("Không đủ số dư trong tài khoản, vui lòng nạp thêm để tiếp tục")
	-- 				cb(-1)
	-- 			else
	-- 				gGameUI:showTip("Giao dịch thất bại, vui lòng thử lại 0!")
	-- 				cb(-1)
	-- 			end
	-- 		else
	-- 			gGameUI:showTip("Giao dịch thất bại, vui lòng thử lại 1!")
	-- 			cb(-1)
	-- 		end
	-- 	end
	-- )
end

return lp_vn


