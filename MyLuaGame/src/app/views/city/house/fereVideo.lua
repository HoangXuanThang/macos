-- 伴侣 视频
local ViewBase = cc.load("mvc").ViewBase
local FereVideoView = class("FereVideoView", ViewBase)

FereVideoView.RESOURCE_FILENAME = "fere_video.json"
FereVideoView.RESOURCE_BINDING = {
    ["panel_video"] = "panelVideo",
    ["btnClose"] = {
        binds = {
            event = "touch",
            methods = {
                ended = bindHelper.self("onClose")
            }
        }
    },
    ["bottom.slider"] = "slider",

}

function FereVideoView:onCreate(path, cb)

    self.slider:setPercent(0)
    self.cb = cb
    local targetPlatform = cc.Application:getInstance():getTargetPlatform()

    local videoFullPath = cc.FileUtils:getInstance():fullPathForFilename(path)
    printInfo("video start PLAY: %s", path)
    printInfo(videoFullPath)
    if #videoFullPath == 0 then
        local writablePath = cc.FileUtils:getInstance():getWritablePath()
        videoFullPath = writablePath .. "package/video/" .. path
        printInfo("writablePath: %s", videoFullPath)
    end

    if #videoFullPath == 0 then
        printWarn("video path not exit %s", path)
        performWithDelay(self, function()
            self:onClose()
        end, 1)
        return
    end

    gGameUI.isPlayVideo = true
    local videoPlayer = nil
    if device.platform ~= "android" and device.platform ~= "ios" then
        videoPlayer = ccui.Layout:create() -- test for window
    else
        local viewSize = display.sizeInView
        videoPlayer = ccexp.VideoPlayer:create():size(self.panelVideo:size()):anchorPoint(0.5, 0.5):xy(display.size.width / 2,
            display.size.height / 2):addTo(self.panelVideo, 1)

        videoPlayer:setFullScreenEnabled(false)
    end
    self.videoPlayer = videoPlayer

    self.videoMax = 60;

    local function onVideoClose()
        gGameUI.isPlayVideo = false
        videoPlayer:runAction(cc.CallFunc:create(function()
			videoPlayer:removeFromParent()
		end))
        self:onClose()
    end

    self.isSeekTo = false
    self.slider:addEventListener(function(ref, eventType)
        if eventType == ccui.SliderEventType.percentChanged then -- 0
            local percent = ref:getPercent()
            local num = math.ceil(self.videoMax * percent * 0.01)
            printInfo("seekTo " .. num)
            self.videoPlayer:seekTo(num)
        elseif eventType == ccui.SliderEventType.slideBallDown then
            self.isSeekTo = true
        elseif eventType == ccui.SliderEventType.slideBallUp or eventType == ccui.SliderEventType.slideBallCancel then
            self.isSeekTo = false
        end
    end)

    local eventListener = function(sener, eventType)
        if eventType == ccexp.VideoPlayerEvent.PLAYING then
            printInfo("video PLAYING")
            audio.pauseMusic()
        elseif eventType == ccexp.VideoPlayerEvent.PAUSED then
            printInfo("video PAUSED")
        elseif eventType == ccexp.VideoPlayerEvent.STOPPED then
            printInfo("video STOPPED")
        elseif eventType == ccexp.VideoPlayerEvent.COMPLETED then
            printInfo("video COMPLETED")
            onVideoClose()
            printInfo("video COMPLETED over")
        end
    end

    if device.platform ~= "android" and device.platform ~= "ios" then
        videoPlayer:addTouchEventListener(eventListener)
        self.slider:hide()
        local tipsText = "不支持 " .. device.platform .. ",请在 android / ios 尝试 播放视频"
        local frameNumNode = cc.Label:createWithTTF(tipsText, ui.FONT_PATH, 30):align(cc.p(0.5, 0.5),
            display.size.width / 2, display.size.height / 2):addTo(self.panelVideo, 10, "num")
        text.addEffect(frameNumNode, {
            outline = {
                color = ui.COLORS.OUTLINE.DEFAULT,
                size = 3
            }
        })
    else
        videoPlayer:addEventListener(eventListener)

        videoPlayer:setFileName(videoFullPath)
        videoPlayer:play()

        self:enableSchedule():schedule(function()
            if self.videoPlayer then
                if self.isSeekTo then
                    return
                end

                local currTime = self.videoPlayer:getCurrentTime()
                local duration = self.videoPlayer:getDuration()
                self.videoMax = duration
                self.slider:setPercent(math.ceil(currTime / duration * 100))
            end
        end, 1)
    end

end

function FereVideoView:onClose()
    gGameUI.isPlayVideo = false
    audio.resumeMusic()
    if self.cb then
        self.cb()
    end
    ViewBase.onClose(self)
end

return FereVideoView
