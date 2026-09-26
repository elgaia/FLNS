
local M = {}

function M.Mount(env)
    env = env or {}
    local Config = assert(env.Config, "[ClockAmbient] env.Config is required")
    local Fn     = assert(env.Fn, "[ClockAmbient] env.Fn is required")
    assert(env.UI and env.UI.TimeBox, "[ClockAmbient] env.UI.TimeBox is required")
    local UI     = env.UI

UI.TimeBox:AddSlider("ClockTime", { Text = "Clock Time", Default = 14, Min = 0, Max = 24, Rounding = 0,
    Callback = function(v) Config.Visual.ClockTime = v; Config.Visual.Ambient = true; Fn.applyVisual() end })
UI.TimeBox:AddSlider("Brightness", { Text = "Brightness", Default = 2, Min = 0, Max = 5, Rounding = 1,
    Callback = function(v) Config.Visual.Brightness = v; Config.Visual.Ambient = true; Fn.applyVisual() end })

    M.Unload = function()
    end
    return M
end

return M
