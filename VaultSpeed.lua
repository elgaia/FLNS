
local M = {}

function M.Mount(env)
    env = env or {}
    local Config      = assert(env.Config, "[VaultSpeed] env.Config is required")
    local Fn          = assert(env.Fn, "[VaultSpeed] env.Fn is required")
    assert(env.UI and env.UI.AbilityTab, "[VaultSpeed] env.UI.AbilityTab is required")
    local UI          = env.UI
    local LocalPlayer = env.LocalPlayer or game:GetService("Players").LocalPlayer
    local fast_tick = env.fast_tick or tick

function Fn.applyVault()
    if Config.Connections.Vault then
        Config.Connections.Vault:Disconnect()
        Config.Connections.Vault = nil
    end
    if not Config.Movement.Vault.Enabled then return end
    local cfg = Config.Movement.Vault
    cfg.HeartbeatRate = 0.15
    cfg.LastApply = 0
    Config.Connections.Vault = Config.FakeConnection(Config.HeartbeatTasks, "Vault", function()
        if not cfg.Enabled then return end
        local now = fast_tick()
        if now - cfg.LastApply < cfg.HeartbeatRate then return end
        cfg.LastApply = now
        local char = LocalPlayer.Character
        if not char or not char.Parent then return end
        local target      = cfg.Speed
        local hasVaultSpeed = char:GetAttribute("vaultspeed") ~= nil
        local hasSwift      = char:GetAttribute("swift") ~= nil
        Fn.safeCall("VaultSpeed Apply", function()
            if hasSwift and not hasVaultSpeed then
                if char:GetAttribute("swift") ~= target then char:SetAttribute("swift", target) end
            elseif hasVaultSpeed and not hasSwift then
                if char:GetAttribute("vaultspeed") ~= target then char:SetAttribute("vaultspeed", target) end
            else
                if char:GetAttribute("vaultspeed") ~= target then char:SetAttribute("vaultspeed", target) end
                if char:GetAttribute("swift") ~= target then char:SetAttribute("swift", target) end
            end
        end)
    end)
end
function Fn.disableVault()
    if Config.Connections.Vault then
        Config.Connections.Vault:Disconnect()
        Config.Connections.Vault = nil
    end
    local char = LocalPlayer.Character
    if char then
        Fn.safeCall("VaultSpeed Disable", function()
            if char:GetAttribute("vaultspeed") ~= nil then
                char:SetAttribute("vaultspeed", 1)
            end
            if char:GetAttribute("swift") ~= nil then
                char:SetAttribute("swift", 1)
            end
        end)
    end
end

UI.AbilityTab:AddToggle("FastVault", { Text = "Vault Speed", Default = false,
    Callback = function(v)
        Config.Movement.Vault.Enabled = v
        if v then
            Fn.applyVault()
        else
            Fn.disableVault()
        end
    end }):AddKeyPicker("FastVault_Keybind", { Default = "None", Mode = "Toggle", SyncToggleState = true })
UI.AbilityTab:AddSlider("VaultSpeed", { Text = "Vault Speed", Default = 1, Min = 1, Max = 3, Rounding = 2,
    Callback = function(v) Config.Movement.Vault.Speed = v end })

    M.Unload = function()
        pcall(function() Fn.disableVault() end)
    end
    return M
end

return M
