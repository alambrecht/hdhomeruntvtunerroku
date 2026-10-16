' Loads the lineup (discovering the tuner on first launch), then switches between the
' channel list, the player and the tuner address dialog.

sub init()
    m.top.backgroundUri = ""
    m.top.backgroundColor = "0x000000FF"

    m.prefs = CreateObject("roRegistrySection", "hdhr")
    m.status = m.top.findNode("status")
    m.list = m.top.findNode("channelList")
    m.player = m.top.findNode("player")

    m.list.observeField("picked", "onPick")
    m.list.observeField("settingsRequested", "onSettingsRequested")
    m.player.observeField("exitRequested", "onPlayerExit")
    m.player.observeField("index", "onPlayerIndex")

    m.channels = invalid
    m.lastIndex = 0
    m.lastError = ""
    m.launched = false
    loadChannels()
end sub

function savedBaseUrl() as String
    if m.prefs.Exists("baseUrl") then return m.prefs.Read("baseUrl")
    return ""
end function

sub saveBaseUrl(url as String)
    m.prefs.Write("baseUrl", url)
    m.prefs.Flush()
end sub

sub loadChannels()
    m.channels = invalid
    m.loading = true
    m.list.visible = false
    showStatus("Loading channels…")

    m.task = CreateObject("roSGNode", "HdhrTask")
    m.task.baseUrl = savedBaseUrl()
    m.task.observeField("result", "onLoaded")
    m.task.control = "run"
end sub

sub onLoaded()
    result = m.task.result
    m.loading = false
    if result.baseUrl <> "" and result.baseUrl <> savedBaseUrl() then saveBaseUrl(result.baseUrl)

    signalLaunchComplete()

    if result.error <> "" then
        m.lastError = result.error
        showStatus(result.error + Chr(10) + Chr(10) + "Press OK to enter the tuner address.")
        showSetup(result.error)
        return
    end if

    m.channels = result.channels
    m.list.channels = m.channels
    m.player.channels = m.channels
    showList()
end sub

' Roku certification requires this beacon once the first interactive screen is up.
sub signalLaunchComplete()
    if m.launched then return
    m.launched = true
    m.top.signalBeacon("AppLaunchComplete")
end sub

sub showStatus(text as String)
    m.status.text = text
    m.status.visible = true
    m.top.setFocus(true)
end sub

sub showList()
    m.status.visible = false
    m.player.visible = false
    m.list.visible = true
    m.list.focusIndex = m.lastIndex
    m.list.setFocus(true)
end sub

sub onPick()
    m.lastIndex = m.list.picked
    m.list.visible = false
    m.player.visible = true
    m.player.index = m.lastIndex
    m.player.active = true
    m.player.setFocus(true)
end sub

sub onPlayerIndex()
    m.lastIndex = m.player.index
end sub

sub onPlayerExit()
    m.player.active = false
    showList()
end sub

sub onSettingsRequested()
    showSetup("")
end sub

sub showSetup(message as String)
    dialog = CreateObject("roSGNode", "StandardKeyboardDialog")
    dialog.title = "HDHomeRun IP address"
    if message <> "" then dialog.message = [message]
    dialog.text = savedBaseUrl().Replace("http://", "")
    dialog.buttons = ["Save", "Cancel"]
    dialog.observeField("buttonSelected", "onSetupButton")
    dialog.observeField("wasClosed", "onSetupClosed")
    m.top.dialog = dialog
end sub

sub onSetupButton()
    dialog = m.top.dialog
    if dialog.buttonSelected = 0 then
        ip = dialog.text.Trim()
        if ip = "" then return
        saveBaseUrl(normalizeUrl(ip))
        dialog.close = true
        loadChannels()
    else
        dialog.close = true
        onSetupClosed()
    end if
end sub

' Back or Cancel: return to the channel list, or to the error message if nothing has loaded.
sub onSetupClosed()
    if m.loading then return
    if m.channels = invalid then
        m.top.setFocus(true)
    else
        m.list.setFocus(true)
    end if
end sub

' Only reached while the status message has focus.
function onKeyEvent(key as String, press as Boolean) as Boolean
    if press and key = "OK" and m.status.visible and not m.loading then
        showSetup(m.lastError)
        return true
    end if
    return false
end function
