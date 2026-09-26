
local M = {}

function M.Mount(env)
    env = env or {}
    local Config      = assert(env.Config, "[CooldownBypass] env.Config is required")
    local Fn          = assert(env.Fn, "[CooldownBypass] env.Fn is required")
    assert(env.UI and env.UI.KillerTab, "[CooldownBypass] env.UI.KillerTab is required")
    local UI          = env.UI
    local LocalPlayer = env.LocalPlayer or game:GetService("Players").LocalPlayer
    local fast_tick = env.fast_tick or tick

function Fn.StartCooldownBypass()
    if not Config.State.CorruptHandlerFunc then
        for _, v in pairs(getgc(true)) do
            if type(v) == "function" and islclosure(v) then
                local constants = debug.getconstants(v)
                if table.find(constants, "corrupt") and table.find(constants, "Immobile") then
                    Config.State.CorruptHandlerFunc = v
                    break
                end
            end
        end
    end
    if not Config.State.CorruptHandlerFunc then
        warn("corruptHandler function not found in memory.")
        return
    end
    if Config.Connections.CooldownBypass then
        Config.Connections.CooldownBypass:Disconnect()
    end
    Config.Connections.CooldownBypass = Config.FakeConnection(Config.HeartbeatTasks, "CooldownBypass", function()
        if not Config.Killer.BypassCooldown then return end
        local now = fast_tick()
        if now - Config.Timers.lastCooldownBypass < 0.5 then return end
        Config.Timers.lastCooldownBypass = now
        if Config.State.CorruptHandlerFunc then
            local upvalues = debug.getupvalues(Config.State.CorruptHandlerFunc)
            for idx, val in pairs(upvalues) do
                if type(val) == "boolean" then
                    if val == false then
                        debug.setupvalue(Config.State.CorruptHandlerFunc, idx, true)
                    end
                end
            end
        end
    end)
end

UI.KillerTab:AddToggle("BypassCooldown", { Text = "NoCooldown(Abyss)",
    Default = false,
    Callback = function(state)
        Config.Killer.BypassCooldown = state
        if state then
            Fn.StartCooldownBypass()
        end
    end }):AddKeyPicker("BypassCooldown_Keybind", { Default = "None", Mode = "Toggle", SyncToggleState = true })

    M.Unload = function()
        if Config.Connections.CooldownBypass then
            Fn._destroyConn("CooldownBypass", Config.Connections.CooldownBypass)
            Config.Connections.CooldownBypass = nil
        end
    end
    return M
end

return M
