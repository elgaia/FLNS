local M = {}

function M.Mount(env)
    env = env or {}
    local Config      = assert(env.Config, "[AutoFleeKiller] env.Config is required")
    local Fn          = assert(env.Fn, "[AutoFleeKiller] env.Fn is required")
    assert(env.UI and env.UI.AbilityTab, "[AutoFleeKiller] env.UI.AbilityTab is required")
    local UI          = env.UI
    local LocalPlayer = env.LocalPlayer or game:GetService("Players").LocalPlayer
    local fast_tick = env.fast_tick or tick

Config.Threads.Flee = task.spawn(function()
    while not Config.State.unloaded do
        task.wait(0.2)
        if not Config.Auto.Flee.Enabled then continue end
        local root = Fn.getRoot()
        if not root then continue end
        local killerRoot, distance = Fn.GetNearestKiller()
        if killerRoot and distance <= Config.Auto.Flee.DetectDistance
        and fast_tick() - Config.State.LastFlee > Config.Auto.Flee.Cooldown then
            local point = Fn.GetFarthestGeneratorPoint(killerRoot)
            if point then
                Config.State.LastFlee = fast_tick()
                root.CFrame = point.CFrame + Vector3.new(0, 5, 0)
            end
        end
    end
end)
--------------------------- UI builder ------------------------------
do
    local toggle = UI.AbilityTab:AddToggle("AutoFleeKiller", { Text = "Auto Flee Killer",
        Default = false,
        Callback = function(v) Config.Auto.Flee.Enabled = v end }):AddKeyPicker("AutoFleeKiller_Keybind", { Default = "None", Mode = "Toggle", SyncToggleState = true })
end

    M.Unload = function()
        if Config.Threads and Config.Threads.Flee then
            pcall(function() task.cancel(Config.Threads.Flee) end)
            Config.Threads.Flee = nil
        end
    end
    return M
end

return M
