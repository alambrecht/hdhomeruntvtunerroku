' Up / fast-forward = next channel, down / rewind = previous, OK = show or hide the
' channel banner, Back = channel list.

sub init()
    m.video = m.top.findNode("video")
    m.banner = m.top.findNode("banner")
    m.bannerBg = m.top.findNode("bannerBg")
    m.title = m.top.findNode("title")
    m.detail = m.top.findNode("detail")
    m.tuneTimer = m.top.findNode("tuneTimer")
    m.hideTimer = m.top.findNode("hideTimer")

    m.tuneTimer.observeField("fire", "tune")
    m.hideTimer.observeField("fire", "onHideTimer")
    m.video.observeField("state", "onVideoState")

    m.error = ""
    m.tuning = false
    m.overlayVisible = false
end sub

sub onActiveChange()
    if m.top.active then
        onIndexChange()
    else
        m.tuneTimer.control = "stop"
        m.hideTimer.control = "stop"
        m.video.control = "stop" ' closes the HTTP stream, which frees the tuner
        m.overlayVisible = false
        m.banner.visible = false
    end if
end sub

sub onIndexChange()
    if not m.top.active then return
    m.error = ""
    m.tuning = true
    m.overlayVisible = true
    m.hideTimer.control = "stop"
    m.tuneTimer.control = "stop"
    m.tuneTimer.control = "start"
    updateBanner()
end sub

sub tune()
    ch = currentChannel()
    if ch = invalid then return
    content = CreateObject("roSGNode", "ContentNode")
    content.url = ch.url
    content.title = ch.name
    content.streamFormat = "ts"
    content.live = true
    m.video.control = "stop"
    m.video.content = content
    m.video.control = "play"
end sub

sub onVideoState()
    state = m.video.state
    if state = "playing" then
        ' Hide the banner 3 s after the picture first appears.
        if m.tuning then m.hideTimer.control = "start"
        m.tuning = false
    else if state = "error" then
        m.error = "Playback error: " + m.video.errorMsg
        if m.video.errorCode = -1 or Instr(1, m.video.errorStr, "503") > 0 then m.error = m.error + " (all tuners busy?)"
        m.tuning = false
        m.overlayVisible = true
    else if state = "finished" then
        m.error = "The stream ended."
        m.tuning = false
        m.overlayVisible = true
    end if
    updateBanner()
end sub

sub onHideTimer()
    if m.error = "" then m.overlayVisible = false
    updateBanner()
end sub

sub updateBanner()
    ch = currentChannel()
    if ch = invalid then return
    m.title.text = ch.number + "  " + ch.name

    detail = m.error
    if detail = "" then detail = ch.warning
    if detail <> "" then
        m.detail.color = "0xFFB4ABFF"
    else if m.tuning then
        detail = "Tuning…"
        m.detail.color = "0xE8EEF5FF"
    end if
    m.detail.text = detail

    height = 100
    if detail <> "" then height = 180
    m.bannerBg.height = height
    m.banner.translation = [96, 1080 - 96 - height]
    m.banner.visible = m.overlayVisible
end sub

function currentChannel() as Dynamic
    channels = m.top.channels
    index = m.top.index
    if channels = invalid or index < 0 or index >= channels.Count() then return invalid
    return channels[index]
end function

sub stepChannel(delta as Integer)
    count = m.top.channels.Count()
    if count = 0 then return
    m.top.index = (m.top.index + delta + count) mod count
end sub

function onKeyEvent(key as String, press as Boolean) as Boolean
    if not press then return false

    if key = "up" or key = "fastforward" then
        stepChannel(1)
    else if key = "down" or key = "rewind" then
        stepChannel(-1)
    else if key = "OK" then
        m.overlayVisible = not m.overlayVisible
        m.hideTimer.control = "stop"
        updateBanner()
    else if key = "back" then
        m.top.exitRequested = true
    else if key = "left" or key = "right" then
        ' Nothing to move to; keep focus on the player.
    else
        return false
    end if
    return true
end function
