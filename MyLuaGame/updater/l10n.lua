local languagePlist = cc.FileUtils:getInstance():getValueMapFromFile('res/language.plist')
--globals.LOCAL_LANGUAGE = languagePlist.localization or 'th'
globals.LOCAL_LANGUAGE = 'vn'

-- 多语言登录外网 updater 界面语言显示
local targetPlatform = cc.Application:getInstance():getTargetPlatform()
if cc.PLATFORM_OS_WINDOWS == targetPlatform then
	require "src.app.defines.dev_defines"
	if dev.ONLINE_VERSION_LANGUAGE then
		local language = dev.ONLINE_VERSION_LANGUAGE
		if string.sub(language, 1, 1) == "_" then
			language = string.sub(language, 2)
			LOCAL_LANGUAGE = language
		end
	end
end

print('LOCAL_LANGUAGE', LOCAL_LANGUAGE)

globals.LanguageTexts = {
	cn = {
		notice = "公告",
		checkUpdate = '检查更新中...',
		downloading = '正在下载安装中... 文件数量:%6d / %6d  文件大小:%7dK / %7dK',
		downloadingM = '正在下载安装中... 文件数量: %d / %d  文件大小: %.2fM / %.2fM',
		noConnected = '无法连接',
		reConnect = '请重新连接',
		unzipFailed = '解压失败',
		oldApp = '版本过旧\n需要重新下载最新的客户端',
		loginUpdating = '登录服务器正在更新中，请稍等',
		umcompress = '正在解压中，请稍等',
		wifiTip = '资源较大，请在wifi环境下下载资源 土豪请随意',
		tips = '提 示',
		boxTextTip = '下次不再弹出提示',
		sure = '确 定',
		notRemindMe = '今日不再提醒',
		ok = '我知道了',
	},
	vn = {
		notice = "Thông báo",
		checkUpdate = 'Đang kiểm tra cập nhật...',
		downloading = 'Đang tải và cài đặt... Số lượng tệp: %6d / %6d  Kích thước tệp: %7dK / %7dK',
		downloadingM = 'Đang tải và cài đặt... Số lượng tệp: %d / %d  Kích thước tệp: %.2fM / %.2fM',
		noConnected = 'Không thể kết nối',
		reConnect = 'Vui lòng kết nối lại',
		unzipFailed = 'Giải nén thất bại',
		oldApp = 'Phiên bản đã quá cũ\nCần tải xuống phiên bản mới nhất của ứng dụng',
		loginUpdating = 'Máy chủ đăng nhập đang cập nhật, vui lòng chờ',
		umcompress = 'Đang giải nén, vui lòng chờ',
		wifiTip = 'Dung lượng lớn, vui lòng tải xuống trong môi trường wifi. Đại gia có thể bỏ qua',
		tips = 'Gợi ý',
		boxTextTip = 'Không hiện gợi ý lần sau',
		sure = 'Xác nhận',
		notRemindMe = 'Hôm nay không nhắc lại',
		ok = 'Tôi đã biết',
	},
	tw = {
		notice = "公告",
		checkUpdate = '检查更新中...',
		downloading = '正在下载安装中... 文件数量:%6d / %6d  文件大小:%7dK / %7dK',
		downloadingM = '正在下载安装中... 文件数量: %d / %d  文件大小: %.2fM / %.2fM',
		noConnected = '无法连接',
		reConnect = '請重新連接',
		unzipFailed = '解压失败',
		oldApp = '版本过旧\n需要重新下载最新的客户端',
		loginUpdating = '登录服务器正在更新中，请稍等',
		umcompress = '正在解壓中，請稍等',
		wifiTip = '資源較大，請在wifi環境下下載資源 土豪請隨意',
		tips = '提 示',
		boxTextTip = '下次不再彈出提示',
		sure = '確 定',
		notRemindMe = '今日不再提醒',
		ok = '我知道了',
	},
	en = {
		notice = "Notice",
		checkUpdate = 'Checking update...',
		downloading = 'Downloading... file:%6d / %6d  size:%7dK / %7dK',
		downloadingM = 'Downloading... file:%d / %d  size:%.2fM / %.2fM',
		noConnected = 'No network',
		reConnect = 'Please retry connect',
		unzipFailed = 'Uncompress failed',
		oldApp = 'Old client version\nPlease download new client',
		loginUpdating = 'Server updateing, please wait a moment',
		umcompress = 'Extracting, please wait a moment',
		wifiTip = 'Your network not in WIFI, are you confirm to update?',
		tips = 'Tips',
		boxTextTip = 'Don\'t prompt again',
		sure = 'Sure',
		placardActivity = 'Event',
		placardUpdate = 'Reminder',
		notRemindMe = 'Don\'t remind me again today',
		ok = 'Ok',
	},
	th = {
		notice = "ประกาศ",
		checkUpdate = "กำลังตรวจสอบการอัปเดต...",
		downloading = "กำลังดาวน์โหลด... ไฟล์:%6d / %6d  ขนาด:%7dK / %7dK",
		downloadingM = "กำลังดาวน์โหลด... ไฟล์:%d / %d  ขนาด:%.2fM / %.2fM",
		noConnected = "ไม่มีเครือข่าย",
		reConnect = "โปรดลองเชื่อมต่ออีกครั้ง",
		unzipFailed = "การคลายไฟล์ล้มเหลว",
		oldApp = "เวอร์ชันไคลเอนต์เก่า\nกรุณาดาวน์โหลดไคลเอนต์ใหม่",
		loginUpdating = "เซิร์ฟเวอร์กำลังอัปเดต กรุณารอสักครู่",
		umcompress = "กำลังแตกไฟล์ กรุณารอสักครู่",
		wifiTip = "คุณไม่ได้เชื่อมต่อ Wi-Fi คุณต้องการอัปเดตหรือไม่?",
		tips = "เคล็ดลับ",
		boxTextTip = "ไม่ต้องแสดงอีกครั้ง",
		sure = "ตกลง",
		placardActivity = "กิจกรรม",
		placardUpdate = "การแจ้งเตือน",
		notRemindMe = "ไม่ต้องเตือนอีกในวันนี้",
		ok = "โอเค",
	},
	ma = {
		notice = "Notis",
		checkUpdate = "Sedang menyemak kemas kini...",
		downloading = "Sedang memuat turun... fail:%6d / %6d  saiz:%7dK / %7dK",
		downloadingM = "Sedang memuat turun... fail:%d / %d  saiz:%.2fM / %.2fM",
		noConnected = "Tiada rangkaian",
		reConnect = "Sila cuba sambung semula",
		unzipFailed = "Gagal mengekstrak fail",
		oldApp = "Versi klien lama\nSila muat turun klien baru",
		loginUpdating = "Pelayan sedang dikemas kini, sila tunggu sebentar",
		umcompress = "Sedang mengekstrak, sila tunggu sebentar",
		wifiTip = "Rangkaian anda bukan Wi-Fi, adakah anda pasti mahu mengemas kini?",
		tips = "Petua",
		boxTextTip = "Jangan ingatkan lagi",
		sure = "Pasti",
		placardActivity = "Acara",
		placardUpdate = "Peringatan",
		notRemindMe = "Jangan ingatkan saya lagi hari ini",
		ok = "Ok",
	},
	["in"] = {
		notice = "Pemberitahuan",
		checkUpdate = "Memeriksa pembaruan...",
		downloading = "Mengunduh... file:%6d / %6d  ukuran:%7dK / %7dK",
		downloadingM = "Mengunduh... file:%d / %d  ukuran:%.2fM / %.2fM",
		noConnected = "Tidak ada jaringan",
		reConnect = "Silakan coba sambungkan lagi",
		unzipFailed = "Gagal mengekstrak",
		oldApp = "Versi klien lama\nSilakan unduh klien baru",
		loginUpdating = "Server sedang diperbarui, harap tunggu sebentar",
		umcompress = "Sedang mengekstrak, harap tunggu sebentar",
		wifiTip = "Jaringan Anda bukan Wi-Fi, apakah Anda yakin ingin memperbarui?",
		tips = "Tips",
		boxTextTip = "Jangan tampilkan lagi",
		sure = "Yakin",
		placardActivity = "Acara",
		placardUpdate = "Pengingat",
		notRemindMe = "Jangan ingatkan saya lagi hari ini",
		ok = "Ok",
	}
}

globals.Language = LanguageTexts[LOCAL_LANGUAGE]
if Language == nil then
	globals.Language = LanguageTexts.cn
end
globals.Language = setmetatable(Language, {
	__index = function()
		return "text_placeholder"
	end
})
--默认东八区时间
globals.UNIVERSAL_TIMEDELTA = 8 * 3600
if LOCAL_LANGUAGE == 'en' then
	--西五区时间
	UNIVERSAL_TIMEDELTA = 8 * 3600
elseif LOCAL_LANGUAGE == 'vn' then
	--东七区时间
	UNIVERSAL_TIMEDELTA = 7 * 3600
elseif LOCAL_LANGUAGE == 'kr' then
	--东九区时间
	UNIVERSAL_TIMEDELTA = 9 * 3600
end
