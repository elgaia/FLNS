
local M = {}

function M.Mount(env)
    env = env or {}
    local Config      = assert(env.Config, "[GodMode] env.Config is required")
    local Fn          = assert(env.Fn, "[GodMode] env.Fn is required")
    assert(env.UI and env.UI.AbilityTab, "[GodMode] env.UI.AbilityTab is required")
    local UI          = env.UI
    local LocalPlayer = env.LocalPlayer or game:GetService("Players").LocalPlayer

function Fn.applyGodMode()
    if not Config.Killer.Mods.GodMode then return end
    local char = LocalPlayer.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    if hum.Health < hum.MaxHealth then
        Fn.safeCall("GodMode Health", function() hum.Health = hum.MaxHealth end)
    end
    local s = hum:GetState()
    if s == Enum.HumanoidStateType.Dead
    or s == Enum.HumanoidStateType.FallingDown
    or s == Enum.HumanoidStateType.Ragdoll then
        Fn.safeCall("GodMode State", function() hum:ChangeState(Enum.HumanoidStateType.Running) end)
    end
end

UI.AbilityTab:AddToggle("GodMode", { Text = "Anti KnockDown", Default = false,
    Callback = function(v) Config.Killer.Mods.GodMode = v end }):AddKeyPicker("GodMode_Keybind", { Default = "None", Mode = "Toggle", SyncToggleState = true })

    M.Unload = function()
    end
    return M
end

return M
