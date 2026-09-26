local M = {}

function M.Mount(env)
    env = env or {}
    local Config      = assert(env.Config, "[AntiFallDamage] env.Config is required")
    local Fn          = assert(env.Fn, "[AntiFallDamage] env.Fn is required")
    assert(env.UI and env.UI.AbilityTab, "[AntiFallDamage] env.UI.AbilityTab is required")
    local UI          = env.UI
    local LocalPlayer = env.LocalPlayer or game:GetService("Players").LocalPlayer
    local ReplicatedStorage = env.ReplicatedStorage or game:GetService("ReplicatedStorage")
    local fast_tick         = env.fast_tick or tick
    
function Fn.SetupAntiFallDamage()
    Fn.safeCall("AntiFallSetup", function()
        local r = ReplicatedStorage:FindFirstChild("Remotes")
        if not r then return end
        local m = r:FindFirstChild("Mechanics")
        local fallEvent = m and m:FindFirstChild("Fall")
        if not (fallEvent and fallEvent:IsA("RemoteEvent")) then return end
        local ok, mt = pcall(function() return getrawmetatable(game) end)
        if ok and mt and setreadonly then
            Fn.safeCall("AntiFallHook", function()
                setreadonly(mt, false)
                local old = mt.__namecall
                mt.__namecall = newcclosure(function(self, ...)
                    if not checkcaller() and self == fallEvent then
                        local method = getnamecallmethod()
                        if method == "FireServer" then
                            if Config.Movement.FakePerfectLanding.Enabled then
                                Config.State.TempSpeedBoostEnd = fast_tick() + 3
                            end
                            if Config.Killer.Mods.AntiFall then
                                return nil
                            end
                        end
                    end
                    return old(self, ...)
                end)
                setreadonly(mt, true)
            end)
        end
    end)
end
Fn.SetupAntiFallDamage()
--------------------------- UI builder ------------------------------
UI.AbilityTab:AddToggle("AntiFallDamage", { Text = "Anti Fall Damage",
    Default = false,
    Callback = function(Value)
        Config.Killer.Mods.AntiFall = Value
    end }):AddKeyPicker("AntiFallDamage_Keybind", { Default = "None", Mode = "Toggle", SyncToggleState = true })

    M.Unload = function()
        -- hook menjadi pass-through saat flag dimatikan
        Config.Killer.Mods.AntiFall = false
    end
    return M
end

return M
