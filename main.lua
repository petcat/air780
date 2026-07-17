PROJECT = 'Air780_SMS'
VERSION = '0.6.66'

log.setLevel(2)
log.style(1)

_G.sys     = require 'sys'
_G.sysplus = require 'sysplus'
_G.config  = require 'config'
_G.led     = require 'led'

local model     = require 'model'
local sim       = require 'sim'
local params    = require 'params'
local subscribe = require 'subscribe'

if wdt then
    wdt.init(9000)
    sys.timerLoopStart(wdt.feed, 3000)
end

if errDump then errDump.config(false) end

pm.force(pm.NONE)

mobile.config(mobile.CONF_STATICCONFIG, 1)
mobile.config(mobile.CONF_QUALITYFIRST, 2)
mobile.ipv6(config.network.IPv6 == 1)
mobile.syncTime(true) -- 开启自动时间同步，保障 HTTPS SSL 校验通过
mobile.setAuto(10000, 30000, 5)

local network = { onl = false, dis = 0 }

function isMobile(num)
    return num and #num == 11 and num:match('^1[3-9]')
end

local http_opt = config.notify.http.options

-- 修复 HTTP 请求语法及状态码判定
sys.subscribe('http_notify', function(method, url, headers, body, n)
    if n > http_opt.retry then return end
    sys.taskInit(function()
        local _, _, _, ipv6 = socket.localIP()
        local code, resp_headers, res = http.request(method, url, headers, body, {
            timeout = http_opt.timeout * 1000,
            ipv6    = (ipv6 ~= nil)
        })

        if code >= 200 and code < 300 then
            log.info('HTTP', '推送成功', code, res)
        else
            log.warn('HTTP', '推送失败，准备重试', code, n)
            sys.wait(3000)
            sys.publish('http_notify', method, url, headers, body, n + 1)
        end
    end)
end)

local ctrl, http_chl = {}, {}
for _, v in ipairs(config.system.ctrl) do ctrl[v] = true end
for k, v in pairs(config.notify.http.channel) do
    if v.enable == 1 then table.insert(http_chl, k) end
end

sys.subscribe('notify_build', function(type, from, content)
    sys.publish('sms_build_' .. type, from, content)
    if #http_chl < 1 then return end

    sys.taskInit(function()
        local num = (type == 'msg') and model.bsp() or sim.num()
        for _, value in ipairs(http_chl) do
            local fn = params[value]
            if fn then
                local method, url, headers, body = fn(type, from, num, content)
                if method and headers then
                    headers['User-Agent'] = 'Mozilla/5.0 (LuatOS; Air780)'
                    sys.publish('http_notify', method, url, headers, body, 1)
                end
            end
        end
    end)
end)

-- 安全判空格式化辅助
local function safe(v) return tostring(v or '未知') end

sys.subscribe('IP_READY', function(...)
    if not network.onl then
        network.onl = true
        for i, ns in ipairs(config.network.dns) do socket.setDNS(nil, i, ns) end
    end

    if config.system.power.notify ~= 1 then return end
    config.system.power.notify = 0

    local content = string.format(
        "%s 设备开机通知\r\n温度: %s ℃\r\n电压: %s V\r\nIMEI: %s\r\n手机号: %s\r\n运营商: %s\r\nPLMN: %s\r\nIMSI: %s\r\nICCID: %s\r\n信号: %s dBm",
        safe(model.bsp()), safe(model.temp()), safe(model.vbat()), safe(model.imei()), 
        safe(sim.num()), safe(sim.com()), safe(sim.plmn()), safe(mobile.imsi()), safe(mobile.iccid()), safe(mobile.rsrp())
    )
    sys.publish('notify_build', 'msg', '', content)
end)

sys.subscribe('SMS_INC', function(from, txt)
    sys.publish('notify_build', 'sms', from, txt)
end)

-- 呼叫处理模块
if cc then
    local call = { incoming = false, count = 0 }
    sys.subscribe('CC_IND', function(status)
        local cfg  = config.call.accept
        local from = cc.lastNum() or '未知号码'

        if status == 'READY' then cc.init(0)
        elseif status == 'ANSWER_CALL_DONE' then cc.hangUp()
        elseif status == 'DISCONNECTED' or status == 'HANGUP_CALL_DONE' then call = { incoming = false, count = 0 }
        elseif status == 'INCOMINGCALL' then
            if not call.incoming then sys.publish('notify_build', 'call', from, '') end
            call.incoming = true
            call.count = call.count + 1
            if call.count == 3 and ((isMobile(from) and cfg.M == 1) or cfg.L == 1) then
                cc.accept()
            end
        end
    end)
end

-- 保活短信定时任务
local ka = config.task and config.task.keep_alive
if ka and ka.enable == 1 and isMobile(ka.number) then
    sys.taskInit(function()
        fskv.init()
        while not mobile.status() do sys.wait(1000) end -- 轮询网络就绪状态，规避 waitUntil 死锁

        sys.timerLoopStart(function()
            local target_hours = ka.days * 24
            local run_hours = (fskv.get('ka_hours') or 0) + 1

            if run_hours >= target_hours then
                log.info('保活任务', '达到发送天数，执行短信保活', ka.number)
                sys.publish('sms_send', ka.number, ka.content)
                fskv.set('ka_hours', 0)
            else
                fskv.set('ka_hours', run_hours)
            end
        end, 3600000)
    end)
end

sys.run()
