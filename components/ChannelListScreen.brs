sub init()
    m.list = m.top.findNode("list")
    m.button = m.top.findNode("settings")
    m.empty = m.top.findNode("empty")
    m.list.observeField("itemSelected", "onItemSelected")
    m.button.observeField("buttonSelected", "onButtonSelected")
    m.top.observeField("focusedChild", "onFocusedChild")
end sub

sub onChannelsChange()
    content = CreateObject("roSGNode", "ContentNode")
    for each ch in m.top.channels
        item = content.CreateChild("ContentNode")
        item.title = ch.name
        item.AddFields({ number: ch.number, hd: ch.hd })
    end for
    m.list.content = content

    isEmpty = content.GetChildCount() = 0
    m.empty.visible = isEmpty
    m.list.visible = not isEmpty
end sub

sub onFocusIndexChange()
    if m.list.content = invalid then return
    count = m.list.content.GetChildCount()
    if count = 0 then return
    index = m.top.focusIndex
    if index < 0 then index = 0
    if index >= count then index = count - 1
    m.list.jumpToItem = index
end sub

' When the screen itself gets focus, pass it to the list (or to the button if there are no channels).
sub onFocusedChild()
    if not m.top.hasFocus() then return
    if m.empty.visible then
        m.button.setFocus(true)
    else
        m.list.setFocus(true)
    end if
end sub

sub onItemSelected()
    m.top.picked = m.list.itemSelected
end sub

sub onButtonSelected()
    m.top.settingsRequested = true
end sub

' Up (from the top row) or right goes to the button; down or left goes back to the list.
' The * button opens the tuner address dialog from anywhere on this screen.
function onKeyEvent(key as String, press as Boolean) as Boolean
    if not press then return false

    if (key = "up" or key = "right") and m.list.hasFocus() then
        m.button.setFocus(true)
        return true
    else if (key = "down" or key = "left") and m.button.hasFocus() and not m.empty.visible then
        m.list.setFocus(true)
        return true
    else if key = "options" then
        m.top.settingsRequested = true
        return true
    end if
    return false
end function
