--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2017 TianJi Information Technology Inc.
--
-- 应用相关全局变量
--

--
-- languagePlist
--

-- 地区码参考
-- http://www.lingoes.cn/zh/translator/langcode.htm
-- 简化定义参考csv_language.py
local languagePlist = cc.FileUtils:getInstance():getValueMapFromFile('res/version.plist')
-- globals.LOCAL_LANGUAGE = languagePlist.localization or 'en'
globals.LOCAL_LANGUAGE = 'vn'

printInfo('LOCAL_LANGUAGE %s', LOCAL_LANGUAGE)

globals.IS_SEA = true

globals.SEND_INFORMATION_CONFIG = "http://163.223.12.142/api/v1/game-session/update.php"

globals.GET_INFORMATION_CONFIG = "http://163.223.12.142/api/v1/users/user-info.php"

-- API để lấy số dư money trực tiếp (bỏ qua game server)
globals.GET_USER_MONEY_API = "http://163.223.12.142/api/v1/game/get-user-info.php"

-- API để trừ tiền sau khi mua
globals.DEDUCT_BALANCE_API = "http://163.223.12.142/api/v1/game/deduct-balance.php"

-- API đăng nhập và đăng ký
globals.LOGIN_API = "http://163.223.12.142/api/v1/auth/login.php"
globals.REGISTER_API = "http://163.223.12.142/api/v1/auth/register.php"

local languageLoaded = userDefault.getForeverLocalKey("local_language", nil, {rawKey = true})
if languageLoaded then
	-- 语言设置过了，直接使用
	LOCAL_LANGUAGE = languageLoaded
	printInfo('LOCAL_LANGUAGE load1 %s', LOCAL_LANGUAGE)
end
printInfo('LOCAL_LANGUAGE load2 %s', LOCAL_LANGUAGE)
--
-- versionPlist
--
local plistRes = 'res/version.plist'
local versionLanguage = {
	trial = "cn",
	test = "cn",
}
if dev.ONLINE_VERSION_LANGUAGE then
	local name = dev.ONLINE_VERSION_LANGUAGE
	if string.sub(name, 1, 1) == "_" then
		name = string.sub(name, 2)
		LOCAL_LANGUAGE = versionLanguage[name] or name
		printInfo('LOCAL_LANGUAGE change %s', LOCAL_LANGUAGE)
	end
	plistRes = string.format("config_%s.plist", name)
end
-- globals.FOR_SHENHE = string.lower(versionPlist.forShenhe or "") == "true"

--默认东八区时间
--默认东八区时间
globals.UNIVERSAL_TIMEDELTA = 8 * 3600
if LOCAL_LANGUAGE == 'en' then
	--西五区时间
	UNIVERSAL_TIMEDELTA = 8 * 3600
elseif LOCAL_LANGUAGE == 'vn'  then
	--东七区时间
	UNIVERSAL_TIMEDELTA = 7 * 3600
elseif LOCAL_LANGUAGE == 'th'  then
	--东七区时间
	UNIVERSAL_TIMEDELTA = 7 * 3600
elseif LOCAL_LANGUAGE == 'in'  then
	--东七区时间
	UNIVERSAL_TIMEDELTA = 7 * 3600
elseif LOCAL_LANGUAGE == 'ma' then
	--东九区时间
	UNIVERSAL_TIMEDELTA = 7 * 3600
end
printInfo('UNIVERSAL_TIMEDELTA %d hours', UNIVERSAL_TIMEDELTA / 3600)

local versionPlist = cc.FileUtils:getInstance():getValueMapFromFile(plistRes)
-- "http://192.168.1.125/game01/version_fake.conf" 控制读取服务器列表的url
globals.VERSION_CONF_URL = versionPlist.versionUrl
-- "http://um-game.com/game01/serv.conf" --控制读取服务器列表的url
globals.SERVER_CONF_URL = versionPlist.serverUrl
globals.NOTICE_CONF_URL = versionPlist.noticeUrl
-- "http://192.168.1.96:1104"
globals.REPORT_CONF_URL = versionPlist.reportUrl
globals.FEED_BACK_URL = versionPlist.feedBackUrl
globals.SUPPORT_URL = "https://www.facebook.com/vodainhangia"
globals.JUMP_SHOP_URL = "#" -- kr
globals.DISCORD_URL = "#"   -- en
globals.DISABLE_WORD_CHECK_URL = versionPlist.disableWordCheckUrl

globals.PAYMENT_URL = versionPlist.paymentUrl

globals.LOGIN_SERVRE_HOSTS_TABLE = {versionPlist.loginServer}
globals.FACEBOOK_URL = "https://www.facebook.com/vodainhangia"
globals.GROUP_URL = "https://www.facebook.com/groups/vodainhangia"
globals.ZALO_URL = "https://zalo.me/g/cdjxzt685"
printInfo('versionPlist.versionUrl %s', versionPlist.versionUrl)


for i = 2, 10 do
	if versionPlist[string.format("loginServer%d",i)] then
		table.insert(LOGIN_SERVRE_HOSTS_TABLE, versionPlist[string.format("loginServer%d",i)])
	end
end

if next(LOGIN_SERVRE_HOSTS_TABLE) then
	globals.IPV6_TEST_HOST = string.gmatch(LOGIN_SERVRE_HOSTS_TABLE[1], '([-a-z0-9A-Z.]+):(%d+)')()
end

if ymdump then
	-- 获取最新plist中的reportUrl
	ymdump.setUserInfo("url", REPORT_CONF_URL)
	printInfo('REPORT_CONF_URL %s', REPORT_CONF_URL)
end

--userdefault里保存的app版本 只对前三位维护
globals.APP_VERSION = versionPlist.app_version
printInfo('APP_VERSION %s', APP_VERSION)

--
-- channelPlist
--
local channelPlist = cc.FileUtils:getInstance():getValueMapFromFile('res/version.plist')
globals.APP_CHANNEL = channelPlist.channel
globals.APP_TAG = channelPlist.tag
globals.APP_CURRENCY = channelPlist.currency
globals.APP_FEATURE = channelPlist.feature or ""
globals.IS_DEV_ACCOUNT = false
printInfo('APP_CHANNEL %s', APP_CHANNEL)
printInfo('APP_TAG %s', APP_TAG)
printInfo('LOCAL_LANGUAGE loaded %s', LOCAL_LANGUAGE)

-- if globals.APP_TAG == "com_weixiongguo" then
-- 	-- en 包14 做特殊处理
-- 	globals.SUPPORT_URL = "#99999"
-- elseif globals.APP_TAG == 'com_huan_xinli' then
-- 	-- en 包26 做特殊处理
-- 	globals.SUPPORT_URL = "#88888"
-- end

--
-- .fake
--
globals.FAKE_APP = cc.FileUtils:getInstance():isFileExist('fake') or cc.FileUtils:getInstance():isFileExist('.fake')
printInfo('FAKE_APP %s', FAKE_APP)


--
-- dev.DEBUG_MODE
--
if APP_CHANNEL == "none" or APP_CHANNEL == "luo" then
	dev.DEBUG_MODE = true
end

-- 服务器信息全局缓存
globals.SERVERS_INFO = {}

-- 区服前缀显示
globals.SERVER_MAP = {
	-- dev
	dev = {
		name = "S",
		order = 1,
	},
	shenhe = {
		name = "审核",
		order = 2,
	},
	beta = {
		name = "beta",
		order = 3,
	},
	-- cn
	cn = {
		name = "S",
		order = 100,
	},
	cn_qd = {
		name = "渠道",
		order = 101,
	},
	cn_ht = {
		name = "双平台",
		order = 102,
	},
	cn_ly1 = {
		name = "联运",
		order = 103,
	},
	-- kr
	kr = {
		name = "S",
		order = 100,
	},
	vn = {
		name = "S",
		order = 100,
	},
}
