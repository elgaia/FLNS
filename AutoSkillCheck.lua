local M = {}

function M.Mount(env)
    env = env or {}
    local Config      = assert(env.Config, "[AutoSkillCheck] env.Config is required")
    local Fn          = assert(env.Fn, "[AutoSkillCheck] env.Fn is required")
    assert(env.UI and env.UI.AbilityTab, "[AutoSkillCheck] env.UI.AbilityTab is required")
    local UI          = env.UI
    local LocalPlayer = env.LocalPlayer or game:GetService("Players").LocalPlayer
    local PlayerGui          = assert(env.PlayerGui, "[AutoSkillCheck] env.PlayerGui is required")
    local UserInputService   = env.UserInputService or game:GetService("UserInputService")
    local VirtualInputManager = env.VirtualInputManager or game:GetService("VirtualInputManager")
    local fast_tick          = env.fast_tick or tick
    
function Fn.pressSpace()
    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Space, false, game)
    task.wait()
    VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Space, false, game)
end
function Fn.TriggerMobileButton()
    local b = Fn.getGuiByPath(Config.ActionPath)
    if b and b:IsA("GuiObject") then
        local p, s = b.AbsolutePosition, b.AbsoluteSize
        local i = game:GetService("GuiService"):GetGuiInset()
        local cx, cy = p.X + (s.X/2) + i.X, p.Y + (s.Y/2) + i.Y
        Fn.safeCall("MobileAction", function()
            VirtualInputManager:SendTouchEvent(Config.TouchID, 0, cx, cy)
            task.wait(0.01)
            VirtualInputManager:SendTouchEvent(Config.TouchID, 2, cx, cy)
        end)
    end
end
local function handleSkillCheckPrompt(prompt)
    local check = prompt:WaitForChild("Check", 5)
    if not check then
        local t0 = fast_tick()
        while not check and prompt.Parent and fast_tick() - t0 < 5 do
            task.wait(0.1)
            check = prompt:FindFirstChild("Check")
        end
        if not check then return end
    end
    local function onVisibilityChanged()
        if check.Visible and check.Parent and Config.Auto.SkillCheck then
            if Config.Connections.SkillHeartbeat and Config.State._skillHeartbeatCheck ~= check then
                Config.Connections.SkillHeartbeat:Disconnect()
                Config.Connections.SkillHeartbeat = nil
            end
            if not Config.Connections.SkillHeartbeat then
                Config.State._skillHeartbeatCheck = check
                Config.State._skillHeartbeatLine = check:FindFirstChild("Line")
                Config.State._skillHeartbeatGoal = check:FindFirstChild("Goal")
                Config.Connections.SkillHeartbeat = Config.FakeConnection(Config.RenderSteppedTasks, "SkillHeartbeat", function()
                    if Config.State.busy or not Config.Auto.SkillCheck then return end
                    if not check.Parent then
                        if Config.Connections.SkillHeartbeat then
                            Config.Connections.SkillHeartbeat:Disconnect()
                            Config.Connections.SkillHeartbeat = nil
                        end
                        Config.State._skillHeartbeatLine = nil
                        Config.State._skillHeartbeatGoal = nil
                        return
                    end
                    if not check.Visible then return end
                    local line = Config.State._skillHeartbeatLine
                    local goal = Config.State._skillHeartbeatGoal
                    if not (line and line.Parent) then
                        line = check:FindFirstChild("Line")
                        Config.State._skillHeartbeatLine = line
                    end
                    if not (goal and goal.Parent) then
                        goal = check:FindFirstChild("Goal")
                        Config.State._skillHeartbeatGoal = goal
                    end
                    if not line or not goal then return end
                    if Config.Auto.SkillCheckMode == "Instant" then
                        line.Rotation = goal.Rotation + 109
                        Config.State.busy = true
                        task.spawn(function()
                            if UserInputService.TouchEnabled then Fn.TriggerMobileButton() else Fn.pressSpace() end
                            task.wait(0.2)
                            Config.State.busy = false
                        end)
                    elseif Config.Auto.SkillCheckMode == "normal" then
                        local lr = line.Rotation % 360
                        local gr = goal.Rotation % 360
                        local startRange = (gr + 117) % 360
                        local endRange   = (gr + 130) % 360
                        local success = (startRange > endRange and (lr >= startRange or lr <= endRange))
                                     or (lr >= startRange and lr <= endRange)
                        if success then
                            Config.State.busy = true
                            task.spawn(function()
                                if UserInputService.TouchEnabled then Fn.TriggerMobileButton() else Fn.pressSpace() end
                                task.wait(0.05)
                                Config.State.busy = false
                            end)
                        end
                    else
                        local lr = line.Rotation % 360
                        local gr = goal.Rotation % 360
                        local startRange = (gr + 102) % 360
                        local endRange   = (gr + 116) % 360
                        local success = (startRange > endRange and (lr >= startRange or lr <= endRange))
                                     or (lr >= startRange and lr <= endRange)
                        if success then
                            Config.State.busy = true
                            task.spawn(function()
                                if UserInputService.TouchEnabled then Fn.TriggerMobileButton() else Fn.pressSpace() end
                                task.wait(0.05)
                                Config.State.busy = false
                            end)
                        end
                    end
                end)
            end
        else
            if Config.Connections.SkillHeartbeat then
                Config.Connections.SkillHeartbeat:Disconnect()
                Config.Connections.SkillHeartbeat = nil
            end
        end
    end
    check:GetPropertyChangedSignal("Visible"):Connect(onVisibilityChanged)
    onVisibilityChanged()
end
function Fn.startSkillCheck()
    if Config.State._skillCheckConn then return end
    local prompt = PlayerGui:FindFirstChild("SkillCheckPromptGui")
    if prompt then task.spawn(handleSkillCheckPrompt, prompt) end
    Config.State._skillCheckConn = PlayerGui.ChildAdded:Connect(function(child)
        if child.Name == "SkillCheckPromptGui" then
            task.spawn(handleSkillCheckPrompt, child)
        end
    end)
end
function Fn.stopSkillCheck()
    Config.Auto.SkillCheck = false
    if Config.Connections.SkillHeartbeat then
        Config.Connections.SkillHeartbeat:Disconnect()
        Config.Connections.SkillHeartbeat = nil
    end
    Config.State._skillHeartbeatCheck = nil
    if Config.State._skillCheckConn then
        Fn._destroyConn("SkillCheckConn", Config.State._skillCheckConn)
        Config.State._skillCheckConn = nil
    end
end
function Fn.applySkillCheckSpeed()
    if Config.Connections.SkillCheckSpeed then
        Config.Connections.SkillCheckSpeed:Disconnect()
        Config.Connections.SkillCheckSpeed = nil
    end
    if not Config.Movement.SkillCheckSpeed.Enabled then return end
    local char = LocalPlayer.Character
    if not char then return end
    local function updateSkillCheck()
        if not Config.Movement.SkillCheckSpeed.Enabled then return end
        local target = Config.Movement.SkillCheckSpeed.Speed
        if char:GetAttribute("skillcheckspeed") ~= target then
            Fn.safeCall("SkillCheckSpeed Apply", function()
                char:SetAttribute("skillcheckspeed", target)
            end)
        end
    end
    updateSkillCheck()
    Config.Connections.SkillCheckSpeed = char:GetAttributeChangedSignal("skillcheckspeed"):Connect(updateSkillCheck)
end
function Fn.disableSkillCheckSpeed()
    if Config.Connections.SkillCheckSpeed then
        Config.Connections.SkillCheckSpeed:Disconnect()
        Config.Connections.SkillCheckSpeed = nil
    end
    local char = LocalPlayer.Character
    if char then
        Fn.safeCall("SkillCheckSpeed Disable", function()
            char:SetAttribute("skillcheckspeed", 1)
        end)
    end
end
--------------------------- UI builder ------------------------------
UI.AbilityTab:AddToggle("Skill", { Text = "Auto Skill Check", Default = false,
    Callback = function(v)
        Config.Auto.SkillCheck = v
        if v then
            Fn.safeCall("SkillCheck Start", function() Fn.startSkillCheck() end)
        else
            Fn.safeCall("SkillCheck Stop", function() Fn.stopSkillCheck() end)
        end
    end }):AddKeyPicker("Skill_Keybind", { Default = "None", Mode = "Toggle", SyncToggleState = true })
UI.AbilityTab:AddDropdown("SkillCheckModeDropdown", { Values = {"perfect", "normal", "Instant"},
    Default = 1,
    Multi = false,
    Text = "Skill Check Mode",
    Callback = function(v)
        Config.Auto.SkillCheckMode = v
    end })
UI.AbilityTab:AddToggle("SkillCheckSpeedToggle", { Text = "Slow Skill Check", Default = false,
    Callback = function(v)
        Config.Movement.SkillCheckSpeed.Enabled = v
        if v then
            Fn.applySkillCheckSpeed()
        else
            Fn.disableSkillCheckSpeed()
        end
    end }):AddKeyPicker("SkillCheckSpeedToggle_Keybind", { Default = "None", Mode = "Toggle", SyncToggleState = true })
UI.AbilityTab:AddSlider("SkillCheckSpeedValue", { Text = "Skill Check Speed Value", Default = 1, Min = 1, Max = 3, Rounding = 2,
    Callback = function(v) Config.Movement.SkillCheckSpeed.Speed = v end })

    M.Unload = function()
        pcall(function()
            Fn.stopSkillCheck()
            Fn.disableSkillCheckSpeed()
        end)
    end
    return M
end

return M
