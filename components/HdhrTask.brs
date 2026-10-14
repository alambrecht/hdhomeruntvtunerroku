sub init()
    m.top.functionName = "load"
end sub

sub load()
    result = { baseUrl: m.top.baseUrl, channels: [], error: "" }

    if result.baseUrl = "" then
        url = discoverBaseUrl()
        if url = invalid then
            result.error = "Couldn't find an HDHomeRun automatically. Enter its IP address."
            m.top.result = result
            return
        end if
        result.baseUrl = url
    end if

    lineup = invalid
    body = httpGet(result.baseUrl + "/lineup.json")
    if body <> invalid then lineup = ParseJson(body)
    if type(lineup) <> "roArray" then
        reason = m.httpError
        if reason = "" then reason = "not a channel lineup"
        result.error = "Couldn't load channels from " + result.baseUrl + " (" + reason + ")"
        m.top.result = result
        return
    end if

    result.channels = toChannels(lineup, mpeg2Handling(result.baseUrl))
    m.top.result = result
end sub

' Ask SiliconDust's cloud which HDHomeRun tuners are on this LAN. Returns e.g. "http://192.168.1.50".
function discoverBaseUrl() as Dynamic
    body = httpGet("https://api.hdhomerun.com/discover")
    if body = invalid then return invalid
    devices = ParseJson(body)
    if type(devices) <> "roArray" then return invalid
    for each d in devices
        ' Tuners have a lineup; the DVR storage entry doesn't.
        if type(d) = "roAssociativeArray" then
            if d.DoesExist("LineupURL") and asString(d.BaseURL) <> "" then return normalizeUrl(d.BaseURL)
        end if
    end for
    return invalid
end function

' Most Roku players can't decode MPEG-2, the video codec of most ATSC 1.0 channels.
' An HDHomeRun EXTEND (model HDTC-*) can transcode those channels to H.264; other models can't.
function mpeg2Handling(baseUrl as String) as Object
    if CreateObject("roDeviceInfo").CanDecodeVideo({ codec: "mpeg2" }).result then return { suffix: "", warning: "" }

    model = ""
    body = httpGet(baseUrl + "/discover.json")
    if body <> invalid then
        info = ParseJson(body)
        if type(info) = "roAssociativeArray" then model = asString(info.ModelNumber)
    end if
    if Left(model, 4) = "HDTC" then return { suffix: "?transcode=heavy", warning: "" }
    return { suffix: "", warning: "This Roku can't decode MPEG-2 video." }
end function

' ATSC 1.0 channels only: ATSC 3.0 (AC-4 audio) and DRM channels are skipped.
function toChannels(lineup as Object, mpeg2 as Object) as Object
    channels = []
    for each c in lineup
        if type(c) = "roAssociativeArray" then
            if not isOne(c.ATSC3) and not isOne(c.DRM) and asString(c.URL) <> "" then
                ch = {
                    number: asString(c.GuideNumber),
                    name: asString(c.GuideName),
                    url: c.URL,
                    hd: isOne(c.HD),
                    warning: ""
                }
                if asString(c.VideoCodec) = "MPEG2" then
                    ch.url = ch.url + mpeg2.suffix
                    ch.warning = mpeg2.warning
                end if
                channels.Push(ch)
            end if
        end if
    end for
    return channels
end function

' Returns the response body, or invalid with the reason in m.httpError. Gives up after 5 s.
function httpGet(url as String) as Dynamic
    m.httpError = ""
    port = CreateObject("roMessagePort")
    xfer = CreateObject("roUrlTransfer")
    xfer.SetMessagePort(port)
    xfer.SetUrl(url)
    if LCase(Left(url, 6)) = "https:" then
        xfer.SetCertificatesFile("common:/certs/ca-bundle.crt")
        xfer.InitClientCertificates()
    end if

    if not xfer.AsyncGetToString() then
        m.httpError = "request failed"
        return invalid
    end if

    msg = Wait(5000, port)
    if type(msg) <> "roUrlEvent" then
        xfer.AsyncCancel()
        m.httpError = "timed out"
        return invalid
    end if

    code = msg.GetResponseCode()
    if code >= 200 and code < 300 then return msg.GetString()
    if code > 0 then
        m.httpError = "HTTP " + code.ToStr() + " from " + url
    else
        m.httpError = msg.GetFailureReason()
    end if
    return invalid
end function
