
local M = {}

function M.Mount(env)
    env = env or {}
    local Config = assert(env.Config, "[NoCutscene] env.Config is required")
    local Fn     = assert(env.Fn, "[NoCutscene] env.Fn is required")
    assert(env.UI and env.UI.VisualBox, "[NoCutscene] env.UI.VisualBox is required")
    local UI     = env.UI
    local LocalPlayer      = assert(env.LocalPlayer, "[NoCutscene] env.LocalPlayer is required")
    local ReplicatedStorage = assert(env.ReplicatedStorage, "[NoCutscene] env.ReplicatedStorage is required")

function Fn.SetupNoCutsceneHook()
    if Config.NoCutsceneHooked then return end
    Config.NoCutsceneHooked = true
    pcall(function()
        local ok, mt = pcall(function() return getrawmetatable(game) end)
        if ok and mt and setreadonly then
            pcall(function()
                setreadonly(mt, false)
                local oldIndex = mt.__index
                local state = Config._NoCutsceneState
                if not state.fakeBindable then
                    state.fakeBindable = Instance.new("BindableEvent")
                end
                if not state.fakeRemote then
                    state.fakeRemote = Instance.new("RemoteEvent")
                end
                local fakeBindable = state.fakeBindable
                local fakeRemote   = state.fakeRemote
                mt.__index = newcclosure(function(t, k)
                    if k == "OnClientEvent" or k == "Event" then
                        if Config.NoCutscene and not checkcaller() and typeof(t) == "Instance" then
                            local name = t.Name
                            if name == "cutscene" and k == "Event" then
                                local parent = t.Parent
                                if parent and parent.Name == "Game" then
                                    return fakeBindable.Event
                                end
                            elseif (name == "cutsceneEnd" or name == "cutsceneEnd2" or name == "cutsceneEndwithownchar" or name == "endscreencutscene") then
                                local parent = t.Parent
                                if parent and parent.Name == "Game" then
                                    return fakeRemote.OnClientEvent
                                end
                            end
                        end
                    end
                    return oldIndex(t, k)
                end)
                setreadonly(mt, true)
            end)
        end
    end)
end
local function _showInstantResults()
    if not Config.NoCutscene then return end
    pcall(function()
        local cam = workspace.CurrentCamera
        if cam then
            cam.CameraType = Enum.CameraType.Custom
            cam.FieldOfView = 70
        end
        game:GetService("UserInputService").MouseIconEnabled = true
        pcall(function()
            local SoundService = game:GetService("SoundService")
            local chase = SoundService and SoundService:FindFirstChild("chase")
            if chase then chase.Volume = 0 end
        end)
        LocalPlayer:SetAttribute("isspectating", true)
        local pg = LocalPlayer:FindFirstChild("PlayerGui")
        if pg then
            local Results   = pg:FindFirstChild("Results")
            local EndScreen = pg:FindFirstChild("EndScreen")
            local Darkness  = pg:FindFirstChild("Darkness")
            if Results then Results.Enabled = true end
            if EndScreen then
                EndScreen.Enabled = true
                local blackout = EndScreen:FindFirstChild("blackout")
                if blackout then blackout.BackgroundTransparency = 1 end
            end
            if Darkness then
                Darkness.Enabled = true
                local frame2 = Darkness:FindFirstChild("Frame2")
                if frame2 then frame2.BackgroundTransparency = 1 end
            end
        end
    end)
end
function Fn.SetupNoCutsceneListeners()
    task.spawn(function()
        local gameFolder = ReplicatedStorage:WaitForChild("Remotes", 10)
        gameFolder = gameFolder and gameFolder:WaitForChild("Game", 10)
        if not gameFolder then return end
        local names = { "endscreencutscene", "cutsceneEnd", "cutsceneEnd2", "cutsceneEndwithownchar" }
        local state = Config._NoCutsceneState
        for _, n in ipairs(names) do
            local event = gameFolder:WaitForChild(n, 10)
            if event and event:IsA("RemoteEvent") then
                local conn = event.OnClientEvent:Connect(_showInstantResults)
                table.insert(state.conns, conn)
            end
        end
    end)
end

UI.VisualBox:AddToggle("NoCutscene", { Text = "Skip End Screen", Default = false,
    Callback = function(v) Config.NoCutscene = v end }):AddKeyPicker("NoCutscene_Keybind", { Default = "None", Mode = "Toggle", SyncToggleState = true })

    M.Unload = function()

    end
    return M
end

return M
