local led = { net = nil, evt = 0 }
local cfg = config.system.led

gpio.setup(cfg.event.gpio, 0)
gpio.setup(cfg.network.gpio, 1)

function led.network(x)
    x = x == 1 and 1 or 0
    if led.net ~= x then
        led.net = x
        gpio.set(cfg.network.gpio, x)
    end
end

function led.event()
    if led.evt ~= 0 then return end
    sys.taskInit(function()
        led.evt = 1
        for _ = 1, cfg.event.total * 2 do
            gpio.toggle(cfg.event.gpio)
            sys.wait(cfg.event.wait)
        end
        gpio.set(cfg.event.gpio, 0)
        led.evt = 0
    end)
end

return led
