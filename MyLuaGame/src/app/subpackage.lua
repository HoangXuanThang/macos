--
-- 分包 下载

--
local SubPackDownload = class("SubPackage")

local writablePath = cc.FileUtils:getInstance():getWritablePath()

-- local FILE_LIST = {
--     "video_a_2", "video_b_2",

--     "video_3", "video_b_3", "video_c_3",

--     "video_a_4", "video_b_4", "video_c_4",

--     "video_5", "video_b_5",
--     "video_6", "video_b_6", "video_c_6",
--     "video_7", "video_b_7",

--     "video_a_8", "video_b_8", "video_c_8"
-- }

-- 下载状态
local DOWNLOAD = {
    ST_WAIT = 0,            -- 等待下载
    ST_DOWN_NEXT = 1,       -- 下一循环

    ST_DOWNLOAD = 10,       -- 下载
    ST_DOWN_FAILED = 11,    -- 下载失败
    ST_DOWN_COMPLETED = 12, -- 下载完成

    ST_DECRYPT = 20,        -- 解密
    ST_DE_FAILED = 21,      -- 解密失败
    ST_DE_COMPLETED = 22,   -- 解密完成

    ST_COMPLETED = 30,      -- 完成
}
-- 下载检查顺序
local DOWNLOAD_STATUS = { DOWNLOAD.ST_WAIT, DOWNLOAD.ST_DOWN_NEXT }

function SubPackDownload:ctor(game)
    self.fileInfo = {}

    self.subPackUrl = nil
    -- self.subPackUrl = "http://192.168.3.40/subpackage/pkm/video/"
    -- self.subPackUrl = "http://192.168.2.12/video/xiaowu/"

    self.downInfo = nil

    self.downloading = false -- 是否需要下载

    self.needClear = false

    self.downloader = nil

    self.downloadProgress = 0

    self.downCallback = nil

    self:init()
end

function SubPackDownload:setSubpackUrl()
    if APP_CHANNEL == "none" or APP_CHANNEL == "luo" then
        self.subPackUrl = "http://127.0.0.1/v/"
        return
    end

    sdk.getSDKCfg(function(info)
        local sdkCfg = json.decode(info)
        local cdn_domain = sdkCfg.cdn_domain
        self.subPackUrl = cdn_domain .. "/subpackage/dld/video/"
        log.download("suPackUrl " .. self.subPackUrl)
    end)
end

function SubPackDownload:init()
    self.fileInfo = {}
    self:setSubpackUrl()

    self.tarPackPath = writablePath .. "package/video/house/"
    self.tempPackPath = writablePath .. "package/_temp/"

    local videoList = {}
    for k, v in csvPairs(csv.banlvxiaowu) do
        for i = 1, csvSize(v.videoattr), 1 do
            if v.id == 1 and i == 1 then
                -- body
            else
                table.insert(videoList, "house/" .. v.id .. "_" .. i .. ".mp4")
            end
        end
    end

    local needSearch = false
    for i, v in ipairs(videoList) do
        local basename = string.match(v, "([^/]+)%.%w+$")
        local targetFile = self.tarPackPath .. basename .. ".mp4"
        local tempFile = self.tempPackPath .. basename

        local fileInfo = {
            name = v,
            file = basename,
            filename = basename .. ".mp4",
            status = DOWNLOAD.ST_WAIT,
            times = 0,
            progress = 50,
        }

        table.insert(self.fileInfo, fileInfo)
        if not cc.FileUtils:getInstance():isFileExist(targetFile) then
            -- 查看是否有下载缓存，清除
            printInfo("not found file clear temp", v)
            if cc.FileUtils:getInstance():isFileExist(tempFile) then
                cc.FileUtils:getInstance():removeFile(tempFile)
            end
        else
            printInfo("exists file ", v)
            fileInfo.status = DOWNLOAD.ST_COMPLETED
            needSearch = true
        end
    end

    if needSearch then
        cc.FileUtils:getInstance():addSearchResolutionsOrder("package/video/")
    else
        cc.FileUtils:getInstance():createDirectory(self.tarPackPath)
        cc.FileUtils:getInstance():createDirectory(self.tempPackPath)
        cc.FileUtils:getInstance():addSearchResolutionsOrder("package/video/")
    end
end

-- @desc 开始下载
function SubPackDownload:startDownload()
    if self.downloading then
        return
    end

    self.downInfo = nil
    self.downCallback = nil

    for i, status in ipairs(DOWNLOAD_STATUS) do
        for ii, info in ipairs(self.fileInfo) do
            if (not self.downInfo) and info.status == status then
                self.downInfo = info
                break
            end
        end
        if self.downInfo then
            break
        end
    end

    if self.downInfo then
        self.downInfo.status = DOWNLOAD.ST_WAIT
        self.downloading = true
    end

    if not self.downInfo then
        cc.FileUtils:getInstance():removeDirectory(self.tempPackPath)
        if self.downloader then
            self.downloader:__gc()
            self.downloader = nil
        end
    end
end

-- @desc 检查是否需要下载
function SubPackDownload:checkNeedDownload(filename)
    if (not self.fileInfo) then
        return false
    end

    for i, v in ipairs(self.fileInfo) do
        if v.name == filename then
            return v.status ~= DOWNLOAD.ST_COMPLETED
        end
    end

    -- 下载完成 false-不需要下载
    return false
end

-- @desc 下载指定文件
function SubPackDownload:downloadOneFile(filename, callback)
    if (not self.fileInfo) then
        return false
    end

    self.downInfo = nil
    for i, v in ipairs(self.fileInfo) do
        if v.name == filename then
            self.downInfo = v
            break;
        end
    end

    if (not self.downInfo) or self.downloading then
        return false
    end

    if self.downInfo.status == DOWNLOAD.ST_COMPLETED then
        if callback then
            callback(true)
        end
        return true
    end

    self.downCallback = callback


    self.downInfo.status = DOWNLOAD.ST_WAIT

    self.downloadProgress = 0
    self.downloading = true

    return true
end

-- @desc 下载
function SubPackDownload:downloadFile(filename, fileUrl, tempFile)
    self.needClear = true
    if not self.downloader then
        self.downloader = cc.Downloader:new({
            countOfMaxProcessingTasks = 2,
        })

        self.downloader:setOnFileTaskSuccess(function(task)
            self:onSuccess(filename)
        end)

        self.downloader:setOnTaskProgress(function(task, received, totalReceived, expected)
            self.downloadProgress = math.floor(totalReceived / expected * 100)

            if self.downInfo then
                self.downInfo.progress = self.downloadProgress
            end
        end)

        self.downloader:setOnTaskError(function(task, errCode, errStr)
            log.download("download failed code " .. errCode)
            log.download("download failed str " .. errStr)
            self:onFailedError(filename)
        end)
    end
    self.downInfo.status = DOWNLOAD.ST_DOWNLOAD

    self.downInfo.progress = 0
    log.download("fileUrl " .. fileUrl)
    log.download("tempFile " .. tempFile)
    self.downloader:createDownloadFileTask(fileUrl, tempFile)
end

-- @desc 下载成功
function SubPackDownload:onSuccess(filename)
    log.download("download succ " .. filename)
    self.downInfo.status = DOWNLOAD.ST_DOWN_COMPLETED
    self.downInfo.times = 0
end

-- @desc 下载失败
function SubPackDownload:onFailedError()
    self.downInfo.status = DOWNLOAD.ST_DOWN_FAILED
end

-- @desc 解密文件
function SubPackDownload:doDecryptFile(srcFile, dstFile)
    self.downInfo.status = DOWNLOAD.ST_DECRYPT
    local success = cc.FileUtils:getInstance():decryptFile(srcFile, dstFile, "789738f1acd6ff3f74986b27adab383961b890ad")
    if success then
        log.download("download succ do decrypt success")
        self.downInfo.status = DOWNLOAD.ST_DE_COMPLETED
        self.downInfo.times = 0
        return true
    else
        self.downInfo.status = DOWNLOAD.ST_DE_FAILED
        -- log.download("download succ do decrypt failed")
    end
    return false
end

-- @desc 下载进度
function SubPackDownload:getDownprogress()
    return self.downloadProgress
end

-- @desc 获取下载文件进度 -1 完成
function SubPackDownload:getFileProgress(filename)
    if self.fileInfo and self.fileInfo[filename] then
        local amount = 0
        local total = #self.fileInfo
        for i, v in ipairs(self.fileInfo) do
            if v.name == filename then
                if v.status == DOWNLOAD.ST_DOWNLOAD then
                    return v.progress
                end
                -- 下载完成
                if v.status == DOWNLOAD.ST_COMPLETED then
                    return -1
                end
            end

            if v.status == DOWNLOAD.ST_COMPLETED then
                amount = amount + 1
            end
        end

        return math.floor(amount / total * 100)
    end

    return -1
end

-- @desc update
function SubPackDownload:onUpdate(delta)
    --
    if not self.downloading then
        return
    end

    -- 没有要下载文件
    if not self.downInfo then
        return
    end

    local tempFile = self.tempPackPath .. self.downInfo.file
    local dstFile = self.tarPackPath .. self.downInfo.filename
    if self.downInfo.status == DOWNLOAD.ST_WAIT then
        -- 开始下载
        if not self.subPackUrl then
            self:setSubpackUrl()
        else
            local fileUrl = self.subPackUrl .. self.downInfo.file
            log.download("download file " .. fileUrl)
            if cc.FileUtils:getInstance():isFileExist(dstFile) then
                cc.FileUtils:getInstance():removeFile(dstFile)
            end

            self:downloadFile(self.downInfo.filename, fileUrl, dstFile)
        end
    elseif self.downInfo.status == DOWNLOAD.ST_DOWNLOAD then
        -- 下载进度
        -- if self.downInfo.progress < 90 then
        --     self.downInfo.progress = self.downInfo.progress + 0.1
        -- end
    elseif self.downInfo.status == DOWNLOAD.ST_DOWN_FAILED then
        -- 下载失败 -----> 重新尝试下载
        log.download("download failed: " .. self.downInfo.name)
        if self.downInfo.times < 3 then
            self.downInfo.times = self.downInfo.times + 1
            self.downInfo.status = DOWNLOAD.ST_WAIT
        else
            self.downInfo.status = DOWNLOAD.ST_DOWN_NEXT
        end
    elseif self.downInfo.status == DOWNLOAD.ST_DOWN_COMPLETED then
        log.download("success: " .. self.downInfo.name)
        printInfo("success: " .. self.downInfo.name)
        -- 完成
        self.downInfo.status = DOWNLOAD.ST_COMPLETED
        -- 移除 下载文件
        -- cc.FileUtils:getInstance():removeFile(tempFile)

        -- 开始新的下载
        self.downloading = false
        if self.downCallback then
            self.downCallback(true)
        end
        -- self:startDownload()
    elseif self.downInfo.status == DOWNLOAD.ST_DOWN_NEXT then
        -- 下次再下 清楚无效下载文件
        log.download("download failed next ")
        cc.FileUtils:getInstance():removeFile(dstFile)

        -- 开始新的下载
        self.downloading = false
        if self.downCallback then
            self.downCallback(false)
        end
        --  self:startDownload()
    end
end

return SubPackDownload
