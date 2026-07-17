local model = {}

function model.temp()
    adc.open(adc.CH_CPU)
    local _, v = adc.read(adc.CH_CPU)
    adc.close(adc.CH_CPU)
    return v and string.format('%.2f', v / 1000) or '0'
end

function model.vbat()
    adc.open(adc.CH_VBAT)
    local _, v = adc.read(adc.CH_VBAT)
    adc.close(adc.CH_VBAT)
    return v and string.format('%.2f', v / 1000) or '0'
end

model.os    = function() return rtos.firmware() end
model.bsp   = function() return rtos.bsp() end
model.hw    = function() return 'v1.0' end
model.chip  = function() return 'EC618' end
model.build = function() return rtos.buildDate() end
model.sn    = function() return mobile.sn() or '' end
model.imei  = function() return mobile.imei() or '' end

return model
