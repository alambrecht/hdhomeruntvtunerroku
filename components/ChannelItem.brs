sub init()
    m.highlight = m.top.findNode("highlight")
    m.number = m.top.findNode("number")
    m.name = m.top.findNode("name")
    m.hd = m.top.findNode("hd")
end sub

sub onContentChange()
    content = m.top.itemContent
    if content = invalid then return
    m.number.text = content.number
    m.name.text = content.title
    m.hd.visible = content.hd
end sub

' The focused row stays faintly marked while focus is on the Tuner address button.
sub onFocusChange()
    opacity = m.top.focusPercent
    if not m.top.listHasFocus then opacity = opacity * 0.35
    m.highlight.opacity = opacity
end sub
