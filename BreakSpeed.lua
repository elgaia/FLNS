
local M = {}

function M.Mount(env)
    env = env or {}
    local Config      = assert(env.Config, "[BreakSpeed] env.Config is required")
    local Fn          = assert(env.Fn, "[BreakSpeed] env.Fn is required")
    assert(env.UI and env.UI.KillerTab, "[BreakSpeed] env.UI.KillerTab is required")
    local UI          = env.UI
    local LocalPlayer = env.LocalPlayer or game:GetService("Players").LocalPlayer

function Fn.enforceAttributes()
    local char = LocalPlayer.Character
    if not char then return end
    if Config.Killer.BreakSpeedEnabled then
        if char:GetAttribute("breakspeed") ~= Config.Killer.BreakSpeed then
            char:SetAttribute("breakspeed", Config.Killer.BreakSpeed)
        end
    else
        if char:GetAttribute("breakspeed") ~= nil then
            char:SetAttribute("breakspeed", nil)
        end
    end
end

UI.KillerTab:AddToggle("BreakSpeedToggle", { Text = "Enable Break Speed",
    Default = false,
    Callback = function(v)
        Config.Killer.BreakSpeedEnabled = v
    end }):AddKeyPicker("BreakSpeedToggle_Keybind", { Default = "None", Mode = "Toggle", SyncToggleState = true })
UI.KillerTab:AddSlider("BreakSpeedSlider", { Text = "Break Pallet & Gen Speed",
    Default = 0,
    Min = 0,
    Max = 5,
    Rounding = 2,
    Callback = function(v)
        Config.Killer.BreakSpeed = v
    end })

    M.Unload = function()
        pcall(function()
            local char = LocalPlayer.Character
            if char and char:GetAttribute("breakspeed") ~= nil then
                char:SetAttribute("breakspeed", nil)
            end
        end)
    end
    return M
end

return M
