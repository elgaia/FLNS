
local M = {}

function M.Mount(env)
    env = env or {}
    local Config = assert(env.Config, "[SpeedBoost] env.Config is required")
    local Fn     = assert(env.Fn, "[SpeedBoost] env.Fn is required")
    assert(env.UI and env.UI.MovementBox, "[SpeedBoost] env.UI.MovementBox is required")
    local UI     = env.UI

do
    local SpeedBoostToggle = UI.MovementBox:AddToggle("SpeedBoostToggle", { Text = "Speed Boost",
        Default = false,
        Callback = function(v)
            Config.Movement.SpeedBoost.Enabled = v
            if v then
                Fn.applySpeedBoost()
            else
                Fn.disableSpeedBoost()
            end
            Fn.updateToggleIconVisual("SpeedBoost")
        end }):AddKeyPicker("SpeedBoostToggle_Keybind", { Default = "None", Mode = "Toggle", SyncToggleState = true })
end
UI.MovementBox:AddSlider("SpeedBoostMultiplier", { Text = "Boost Multiplier",
    Default = 1.1, Min = 1.0, Max = 3.0, Rounding = 2,
    Callback = function(v)
        Config.Movement.SpeedBoost.Multiplier = v
        if Config.Movement.SpeedBoost.Enabled then
            Fn.applySpeedBoost()
        end
    end })

    M.Unload = function()

    end
    return M
end

return M
