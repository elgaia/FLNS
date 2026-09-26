
local M = {}

function M.Mount(env)
    env = env or {}
    local Config      = assert(env.Config, "[MaskedPower] env.Config is required")
    local Fn          = assert(env.Fn, "[MaskedPower] env.Fn is required")
    assert(env.UI and env.UI.KillerTab, "[MaskedPower] env.UI.KillerTab is required")
    local UI          = env.UI
    local LocalPlayer = env.LocalPlayer or game:GetService("Players").LocalPlayer
    local ReplicatedStorage = env.ReplicatedStorage or game:GetService("ReplicatedStorage")
    local Remotes = env.Remotes

UI.KillerTab:AddDivider()
UI.KillerTab:AddDropdown("MaskedPowerSelect", { Text = "Select Power", Values = Config.Masked.Powers, Default = 1, Multi = false,
    Callback = function(val) Config.Masked.CurrentPower = val end })
UI.KillerTab:AddButton({ Text = "Activate Power", Func = function()
    local Event = ReplicatedStorage:FindFirstChild("Remotes", true)
        and ReplicatedStorage.Remotes:FindFirstChild("Killers", true)
        and ReplicatedStorage.Remotes.Killers:FindFirstChild("Masked", true)
        and ReplicatedStorage.Remotes.Killers.Masked:FindFirstChild("Activatepower")
    if Event then Event:FireServer(Config.Masked.CurrentPower) end
end })
UI.KillerTab:AddButton({ Text = "Deactivate Power", Func = function()
    Fn.safeCall("Deactivate Power", function()
        Remotes.Masked:WaitForChild("PowerEvent"):FireServer(false, "Cancel")
    end)
end })

    M.Unload = function()
    end
    return M
end

return M
