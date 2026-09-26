
local M = {}

function M.Mount(env)
    env = env or {}
    local Config      = assert(env.Config, "[FakePerfectLanding] env.Config is required")
    local Fn          = assert(env.Fn, "[FakePerfectLanding] env.Fn is required")
    assert(env.UI and env.UI.AbilityTab, "[FakePerfectLanding] env.UI.AbilityTab is required")
    local UI          = env.UI
    local LocalPlayer = env.LocalPlayer or game:GetService("Players").LocalPlayer
    local fast_tick = env.fast_tick or tick
------------------------------- fitur ---------------------------------
function Fn.applySpeedBoost()
    if Config.Connections.SpeedBoost then
        Config.Connections.SpeedBoost:Disconnect()
        Config.Connections.SpeedBoost = nil
    end
    if not Config.Movement.SpeedBoost.Enabled and not Config.Movement.FakePerfectLanding.Enabled then return end
    local cfg = Config.Movement.SpeedBoost
    cfg.HeartbeatRate = 0.15
    cfg.LastApply = 0
    Config.Connections.SpeedBoost = Config.FakeConnection(Config.HeartbeatTasks, "SpeedBoost", function()
        if not Config.Movement.SpeedBoost.Enabled and not Config.Movement.FakePerfectLanding.Enabled then return end
        local now = fast_tick()
        if now - cfg.LastApply < cfg.HeartbeatRate then return end
        cfg.LastApply = now
        local char = LocalPlayer.Character
        if not char or not char.Parent then return end
        local currentSpeed = char:GetAttribute("speedboost") or 1
        if currentSpeed ~= cfg.LastEnforcedSpeed then
            Config.State.GameIntendedSpeed = currentSpeed
        end
        local isApplyingBoost = false
        local totalBoostToAdd = 0
        if Config.Movement.SpeedBoost.Enabled then
            totalBoostToAdd = totalBoostToAdd + (cfg.Multiplier - 1.0)
            isApplyingBoost = true
        end
        if Config.Movement.FakePerfectLanding.Enabled and now < Config.State.TempSpeedBoostEnd then
            totalBoostToAdd = totalBoostToAdd + (Config.Movement.FakePerfectLanding.Value - 1.0)
            isApplyingBoost = true
        end
        if not isApplyingBoost then
            if cfg.LastEnforcedSpeed ~= nil then
                Fn.safeCall("SpeedBoost Cleanup", function()
                    local intended = Config.State.GameIntendedSpeed or 1
                    char:SetAttribute("speedboost", intended)
                    cfg.LastEnforcedSpeed = nil
                end)
            end
            return
        end
        local target = 1.0 + totalBoostToAdd
        target = math.round(target * 100) / 100
        if currentSpeed ~= target then
            Fn.safeCall("SpeedBoost Apply", function()
                char:SetAttribute("speedboost", target)
                cfg.LastEnforcedSpeed = target
            end)
        end
    end)
end
function Fn.disableSpeedBoost()
    if Config.Movement.SpeedBoost.Enabled or Config.Movement.FakePerfectLanding.Enabled then
        Fn.applySpeedBoost()
        return
    end
    if Config.Connections.SpeedBoost then
        Config.Connections.SpeedBoost:Disconnect()
        Config.Connections.SpeedBoost = nil
    end
    local char = LocalPlayer.Character
    if char and Config.Movement.SpeedBoost.LastEnforcedSpeed ~= nil then
        Fn.safeCall("SpeedBoost Disable", function()
            local intended = Config.State.GameIntendedSpeed or 1
            char:SetAttribute("speedboost", intended)
            Config.Movement.SpeedBoost.LastEnforcedSpeed = nil
        end)
    end
end
--------------------------- UI builder ------------------------------
UI.AbilityTab:AddToggle("FakePerfectLandingToggle", { Text = "Fake Perfect Landing",
    Default = false,
    Callback = function(v)
        Config.Movement.FakePerfectLanding.Enabled = v
        if v then Fn.applySpeedBoost() else Fn.disableSpeedBoost() end
    end }):AddKeyPicker("FakePerfectLandingToggle_Keybind", { Default = "None", Mode = "Toggle", SyncToggleState = true })
UI.AbilityTab:AddSlider("FakePerfectLandingSlider", { Text = "Landing Boost Value",
    Default = 1.40, Min = 1.0, Max = 5.0, Rounding = 2,
    Callback = function(v)
        Config.Movement.FakePerfectLanding.Value = v
    end })

    M.Unload = function()
        if Config.Connections.SpeedBoost then
            pcall(function() Config.Connections.SpeedBoost:Disconnect() end)
            Config.Connections.SpeedBoost = nil
        end
        local char = LocalPlayer.Character
        if char then
            pcall(function() char:SetAttribute("speedboost", 1) end)
        end
    end
    return M
end

return M
