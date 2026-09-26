
local M = {}

function M.Mount(env)
    env = env or {}
    local Config      = assert(env.Config, "[AntiBlind] env.Config is required")
    local Fn          = assert(env.Fn, "[AntiBlind] env.Fn is required")
    assert(env.UI and env.UI.KillerTab, "[AntiBlind] env.UI.KillerTab is required")
    local UI          = env.UI
    local LocalPlayer = env.LocalPlayer or game:GetService("Players").LocalPlayer
    local GotBlindedRemote = env.GotBlindedRemote

function Fn.HandleAntiBlind(self)
    if not Config.Killer.AntiBlind then return false end
    if not GotBlindedRemote then return false end
    if self ~= GotBlindedRemote then return false end
    local isKiller = LocalPlayer.Team and LocalPlayer.Team.Name == "Killer"
    return isKiller == true
end

UI.KillerTab:AddToggle("AntiBlindToggle", { Text = "Anti Blind (Flashlight)",
    Default = false,
    Callback = function(v)
        Config.Killer.AntiBlind = v
    end }):AddKeyPicker("AntiBlindToggle_Keybind", { Default = "None", Mode = "Toggle", SyncToggleState = true })

    M.Unload = function()
    end
    return M
end

return M
