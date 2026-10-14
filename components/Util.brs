' "192.168.1.50" -> "http://192.168.1.50"
function normalizeUrl(input as String) as String
    url = input.Trim()
    while Right(url, 1) = "/"
        url = Left(url, Len(url) - 1)
    end while
    lower = LCase(url)
    if Left(lower, 7) = "http://" or Left(lower, 8) = "https://" then return url
    return "http://" + url
end function

' JSON string value, or "" if it's missing or not a string.
function asString(v as Dynamic) as String
    t = type(v)
    if t = "String" or t = "roString" then return v
    return ""
end function

' True for a JSON value of 1 (lineup.json flags such as "HD": 1).
function isOne(v as Dynamic) as Boolean
    t = type(v)
    if t = "Integer" or t = "roInteger" or t = "LongInteger" or t = "roLongInteger" then return v = 1
    return false
end function
