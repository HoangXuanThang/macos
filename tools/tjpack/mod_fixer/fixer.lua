--
-- 此文件通过脚本编译成lua字节码文件, 以png文件名和res目录下来迷惑
-- res\img\helper\*.png
--
-- 另外通过io接口, 直接检查patch合法性
--


local function log(...)
	-- print(...)
end

local fixEnKofiEntryID

local function fix_en_kofi()
	-- check kfoi file
	local ret, err = pcall(function()
		require("kofi")
	end)
	if err and string.find(err, "not found") == nil then
		display.director:endToLua()
	end

	-- check gKofiParams
	if not fixEnKofiEntryID then
		local cnt = 1
		fixEnKofiEntryID = display.director:getScheduler():scheduleScriptFunc(function()
			if globals["gKofiParams"] ~= nil then
				display.director:endToLua()
			end

			if gGameUI.scene:getChildByName("kofi") ~= nil then
				display.director:endToLua()
			end

			cnt = cnt + 1
			if cnt > 10 then
				display.director:getScheduler():unscheduleScriptEntry(fixEnKofiEntryID)
			end
		end, 5, false)
	end
end


local function read_patch(patch)
	local wpath = cc.FileUtils:getInstance():getWritablePath()
	local plistpath = string.format("%spatch/%s/res/version.plist", wpath, patch)
	local diffpath = string.format("%spatch/%s/version.diff", wpath, patch)

	-- diffpath
	local f, err = io.open(diffpath, "r")
	if err or f == nil then
		return err or "not_open"
	end

	local str = f:read('*a')
	f:close()
	if #str == 0 then
		return "empty"
	end

	-- "patch":72,
	local ps, pe = string.find(str, '"patch":%d+,')
	if ps == nil then
		return "not_found"
	end
	local patchstr = string.sub(str, ps+8, pe-1)

	-- plistpath
	f, err = io.open(plistpath, "r")
	if err or f == nil then
		return err or "not_open"
	end

	str = f:read('*a')
	f:close()
	if #str == 0 then
		return "empty"
	end

	-- <key>patch</key>
	-- <string>87</string>
	ps, pe = string.find(str, '<key>patch</key>.+</string>')
	if ps == nil then
		return "not_found"
	end
	local arr = string.split(string.sub(str, ps, pe), "\n")
	-- <string>87</string>
	local patchstr2 = arr[2]
	if patchstr2 == nil then
		return "not_found"
	end
	patchstr2 = string.trim(patchstr2)
	ps = string.find('/')
	if ps == nil then
		return "not_found"
	end
	patchstr2 = string.sub(patchstr2, 9, ps-2)


	if patchstr ~= patchstr2 then
		return "mismatch"
	end
	return tonumber(patchstr)
end

-- userDefault->setIntegerForKey(keyWithHash(KEY_OF_VERSION), localPatch);
-- <string name="96773f3f45bb6396332b079593367c71">87</string>
local function revert_back_patch()
	cc.UserDefault:getInstance():deleteValueForKey("96773f3f45bb6396332b079593367c71")
end

-- only in win and android
local function fix_patch()
	if device.platform ~= "windows" and device.platform ~= "andorid" then
		return
	end

	if LOCAL_LANGUAGE ~= "en" then
		return
	end

	if PATCH_MIN_VERSION == PATCH_VERSION then
		return
	end

	local patch = read_patch(PATCH_VERSION)
	log('fixer: patch', patch)
	if PATCH_VERSION ~= patch then
		log('!!! patch error', PATCH_VERSION, patch)

		revert_back_patch()
		display.director:endToLua()
	end
end

log('!!! i am fixer')
log('fixer: PATCH_MIN_VERSION', PATCH_MIN_VERSION)
log('fixer: PATCH_VERSION', PATCH_VERSION)

fix_en_kofi()
fix_patch()
