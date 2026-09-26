
local M = {}

function M.Mount(env)
    env = env or {}
    local Config      = assert(env.Config, "[NoCooldownHidden] env.Config is required")
    local Fn          = assert(env.Fn, "[NoCooldownHidden] env.Fn is required")
    assert(env.UI and env.UI.KillerTab, "[NoCooldownHidden] env.UI.KillerTab is required")
    local UI          = env.UI
    local LocalPlayer = env.LocalPlayer or game:GetService("Players").LocalPlayer
    local fast_tick = env.fast_tick or tick

function Fn.StopNoCooldownHidden()
    Config.Killer.NoCooldownHidden = false
    if Config.Threads.NoCooldownHidden then
        Config.Threads.NoCooldownHidden = nil
    end
end
function Fn.StartNoCooldownHidden()
    local S = Config.State
    if S.unloaded then return end
    if Config.Threads.NoCooldownHidden then return end
    if not (getgc and debug and debug.getupvalues and debug.setupvalue) then
        warn("[NoCooldownHidden] Executor tidak mendukung getgc/debug. Fitur tidak bisa aktif.")
        return
    end
    local leapFn, m2Fn = Fn._findHiddenCooldownFuncs()
    if not leapFn and not m2Fn then
        warn("[NoCooldownHidden] Function tryActivate/playM2Animation belum ditemukan. Aktifkan ulang setelah karakter killer dimuat.")
    else
        print("[NoCooldownHidden] Function ditemukan, bypass aktif.")
    end
    Config.Threads.NoCooldownHidden = task.spawn(function()
        local lastScan = 0
        while task.wait(0.1) do
            if S.unloaded or not Config.Killer.NoCooldownHidden then
                break
            end
            local now = fast_tick()
            if (not leapFn and not m2Fn) and (now - lastScan) >= 2 then
                lastScan = now
                leapFn, m2Fn = Fn._findHiddenCooldownFuncs()
                if leapFn or m2Fn then
                    print("[NoCooldownHidden] Function ditemukan saat rescan, bypass aktif.")
                end
            end
            if leapFn then
                pcall(function()
                    local upvalues = debug.getupvalues(leapFn)
                    for i, value in pairs(upvalues) do
                        if type(value) == "boolean" and value == true then
                            pcall(debug.setupvalue, leapFn, i, false)
                        end
                    end
                end)
            end
            if m2Fn then
                pcall(function()
                    local upvalues = debug.getupvalues(m2Fn)
                    for i, value in pairs(upvalues) do
                        if type(value) == "boolean" and value == true then
                            pcall(debug.setupvalue, m2Fn, i, false)
                        end
                    end
                end)
            end
        end
        Config.Threads.NoCooldownHidden = nil
    end)
end

UI.KillerTab:AddToggle("NoCooldownHidden", { Text = "No Cooldown Hidden",
    Default = false,
    Callback = function(state)
        Config.Killer.NoCooldownHidden = state
        if state then
            Fn.safeCall("NoCooldownHidden Start", function() Fn.StartNoCooldownHidden() end)
        else
            Fn.StopNoCooldownHidden()
        end
    end }):AddKeyPicker("NoCooldownHidden_Keybind", { Default = "None", Mode = "Toggle", SyncToggleState = true })

    M.Unload = function()
        pcall(function() Fn.StopNoCooldownHidden() end)
    end
    return M
end

return M
