
local M = {}

function M.Mount(env)
    env = env or {}
    local Config      = assert(env.Config, "[Flowstate] env.Config is required")
    local Fn          = assert(env.Fn, "[Flowstate] env.Fn is required")
    assert(env.UI and env.UI.AbilityTab, "[Flowstate] env.UI.AbilityTab is required")
    local UI          = env.UI
    local LocalPlayer = env.LocalPlayer or game:GetService("Players").LocalPlayer

------------------------------- fitur ---------------------------------
function Fn.startFlowstate()
    if Config.Flowstate.WatcherActive then return end
    Config.Flowstate.WatcherActive = true
    task.spawn(function()
        while Config.Flowstate.Enabled do
            local char = LocalPlayer.Character
            if char then
                local current = char:GetAttribute("Flowstate")
                if current ~= true then
                    pcall(function()
                        char:SetAttribute("Flowstate", true)
                    end)
                end
            end
            task.wait(0.1)
        end
        Config.Flowstate.WatcherActive = false
    end)
end
function Fn.stopFlowstate()
    local char = LocalPlayer.Character
    if char then
        pcall(function()
            char:SetAttribute("Flowstate", false)
        end)
    end
end
--------------------------- UI builder ------------------------------
do
    local toggle = UI.AbilityTab:AddToggle("FlowstateToggle", { Text = "Flowstate",
        Default = false,
        Callback = function(v)
            Config.Flowstate.Enabled = v
            if v then Fn.startFlowstate() else Fn.stopFlowstate() end
            Fn.updateToggleIconVisual("Flowstate")
        end }):AddKeyPicker("FlowstateToggle_Keybind", { Default = "None", Mode = "Toggle", SyncToggleState = true })
end

    M.Unload = function()
        pcall(function() Fn.stopFlowstate() end)
    end
    return M
end

return M
