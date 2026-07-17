local params = {}
local chl = config.notify.http.channel

local function safeStr(str, default)
    return (str and str ~= '') and str or (default or '未知')
end

function params.wxpusher(t, f, n, msg)
    local c = chl.wxpusher
    if not c then return end
    f, n, msg = safeStr(f), safeStr(n), safeStr(msg)
    local sum = t == 'call' and ('📞 来电: '..f) or (t == 'sms' and ('📩 短信: '..f) or '⚙️ 系统通知')
    local con = t == 'call' and string.format('**📞 来电提醒**\n- **主叫**: %s\n- **被叫**: %s', f, n) 
             or (t == 'sms' and string.format('**📩 新短信通知**\n- **发件人**: %s\n- **收件人**: %s\n- **内容**:\n%s', f, n, msg) 
             or ('**⚙️ 系统通知**\n\n'..msg))
    return 'POST', c.url, {['Content-Type']='application/json; charset=utf-8'}, json.encode({appToken=c.appToken, summary=sum, content=con, contentType=3, uids=c.uids})
end

function params.ntfy(t, f, n, msg)
    local c = chl.ntfy
    if not c then return end
    f, n, msg = safeStr(f), safeStr(n), safeStr(msg)
    local title = t == 'call' and '📞 来电提醒' or (t == 'sms' and '📩 新短信通知' or '⚙️ 系统通知')
    local body  = t == 'call' and (f..' 致电 '..n) or (t == 'sms' and string.format('发件人: %s\n收件人: %s\n内容:\n%s', f, n, msg) or msg)
    return 'POST', c.url, {Title=title, Priority='high', Tags='warning', ['Content-Type']='text/plain; charset=utf-8'}, body
end

function params.bark(t, f, n, msg)
    local c = chl.bark
    if not c then return end
    f, n, msg = safeStr(f), safeStr(n), safeStr(msg)
    local p = t == 'call' and {title='📞 来电提醒', body=f..' 致电 '..n} 
           or (t == 'sms' and {title='📩 短信来自: '..f, body=msg} 
           or {title='⚙️ 系统通知', body=msg})
    return 'POST', c.url, {['Content-Type']='application/json; charset=utf-8'}, json.encode(p)
end

function params.gotify(t, f, n, msg)
    local c = chl.gotify
    if not c then return end
    f, n, msg = safeStr(f), safeStr(n), safeStr(msg)
    local title = t == 'call' and '📞 来电提醒' or (t == 'sms' and '📩 新短信通知' or '⚙️ 系统通知')
    local body  = t == 'call' and (f..' 致电 '..n) or (t == 'sms' and string.format('发件人: %s\n收件人: %s\n内容:\n%s', f, n, msg) or msg)
    return 'POST', c.url, {['Content-Type']='application/json; charset=utf-8'}, json.encode({title=title, message=body, priority=5})
end

return params
