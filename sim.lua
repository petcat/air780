local sim, id = {}, mobile.simid()
local coms = { ['46000']='中国移动', ['46001']='中国联通', ['46004']='中国移动', ['46008']='中国移动', ['46011']='中国电信', ['46015']='中国广电' }

function sim.plmn()
    local imsi = mobile.imsi()
    return imsi and imsi:sub(1, 5)
end

function sim.com()
    local iccid = mobile.iccid(id)
    local cfg = config.sim[iccid]
    if cfg and cfg.com then return cfg.com end
    local plmn = sim.plmn()
    return plmn and coms[plmn] or '未知'
end

function sim.num()
    local iccid = mobile.iccid(id)
    local cfg = config.sim[iccid]
    return (cfg and cfg.num) or mobile.number(id) or mobile.number() or ''
end

return sim
