
local M = {}

function M.Mount(env)
    env = env or {}
    local Config      = assert(env.Config, "[M2Aimlock] env.Config is required")
    local Fn          = assert(env.Fn, "[M2Aimlock] env.Fn is required")
    assert(env.UI and env.UI.KillerTab, "[M2Aimlock] env.UI.KillerTab is required")
    local UI          = env.UI
    local LocalPlayer = env.LocalPlayer or game:GetService("Players").LocalPlayer
    local UserInputService = env.UserInputService or game:GetService("UserInputService")
    local Remotes = env.Remotes
    local fast_tick = env.fast_tick or tick

function Fn._findHiddenM2Func()
    local _leapFn, m2Fn = Fn._findHiddenCooldownFuncs()
    return m2Fn
end
function Fn.isM2AimlockTargetValid(char, root)
    if not char or not char.Parent then return false end
    local cfg = Config.Killer.M2Aimlock
    local hum = char:FindFirstChildOfClass("Humanoid")
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hum or not hrp then return false end
    if hum.Health <= 0 then return false end
    if cfg.IgnoreDowned ~= false and Fn.checkDowned(char) then return false end
    if char:GetAttribute("IsCarried") then return false end
    if root and root.Parent then
        local range = cfg.Range or 250
        if (hrp.Position - root.Position).Magnitude > range then return false end
    end
    return true
end
function Fn._m2AimlockApplyTarget(char)
    local cfg = Config.Killer.M2Aimlock
    local partName = cfg.TargetPart or "HumanoidRootPart"
    local part = char:FindFirstChild(partName) or char:FindFirstChild("HumanoidRootPart")
    if not part then return false end
    cfg._targetChar = char
    cfg._targetPart = part
    return true
end
function Fn._getM2AimlockTarget()
    local root = Fn.getRoot()
    if not root then return nil end
    local cfg = Config.Killer.M2Aimlock
    local range = cfg.Range or 250
    local closest, shortest = nil, math.huge
    for _, plr in ipairs(Config.ESPCache.PlayerList) do
        if plr ~= LocalPlayer and plr.Character and plr.Team and plr.Team.Name == "Survivors" then
            local char = plr.Character
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if hrp and Fn.isM2AimlockTargetValid(char, root) then
                local d = (hrp.Position - root.Position).Magnitude
                if d < shortest and d <= range then
                    shortest = d; closest = char
                end
            end
        end
    end
    return closest, shortest
end
function Fn._destroyM2AimlockGyro()
    local cfg = Config.Killer.M2Aimlock
    if cfg._gyro then
        pcall(function() cfg._gyro:Destroy() end)
        cfg._gyro = nil
    end
end
function Fn._m2AimlockStartLock()
    local cfg = Config.Killer.M2Aimlock
    cfg._active = true
    cfg._releaseAt = fast_tick() + (cfg.LockDuration or 2.5)
    cfg._nextValidateAt = 0
    if cfg.RotateChar then
        Fn._destroyM2AimlockGyro()
        local root = Fn.getRoot()
        if root and root.Parent then
            local gyro = Instance.new("BodyGyro")
            gyro.Name = "FLNS_M2AimlockGyro"
            gyro.MaxTorque = Vector3.new(0, math.huge, 0)
            gyro.P = 90000
            gyro.D = 400
            gyro.CFrame = root.CFrame
            gyro.Parent = root
            cfg._gyro = gyro
        end
    end
end
function Fn._m2AimlockStopLock()
    local cfg = Config.Killer.M2Aimlock
    cfg._active = false
    cfg._targetChar = nil
    cfg._targetPart = nil
    cfg._releaseAt = 0
    cfg._nextValidateAt = 0
    Fn._destroyM2AimlockGyro()
end
function Fn._triggerM2Aimlock()
    local cfg = Config.Killer.M2Aimlock
    if not cfg._m2Fn then
        cfg._m2Fn = Fn._findHiddenM2Func()
    end
    if not cfg._m2Fn then
        return
    end
    if cfg._active then
        local newTarget = Fn._getM2AimlockTarget()
        if newTarget then
            Fn._m2AimlockApplyTarget(newTarget)
        elseif cfg._targetChar and not Fn.isM2AimlockTargetValid(cfg._targetChar, Fn.getRoot()) then
            Fn._m2AimlockStopLock()
        end
        return
    end
    local targetChar, dist = Fn._getM2AimlockTarget()
    if not targetChar then
        return
    end
    if not Fn._m2AimlockApplyTarget(targetChar) then return end
    cfg._lastTriggerAt = fast_tick()
    Fn._m2AimlockStartLock()
end
function Fn.StartM2Aimlock()
    local cfg = Config.Killer.M2Aimlock
    if Config.Connections.M2AimlockInputBegan and Config.Connections.M2AimlockRender then
        return
    end
    if not cfg._prepareConn then
        local ok, preparem2 = pcall(function()
            return Remotes:WaitForChild("Killers", 3)
                :WaitForChild("Hidden", 3)
                :WaitForChild("preparem2", 3)
        end)
        if ok and preparem2 then
            cfg._prepareConn = preparem2.Event:Connect(function()
                if not cfg.Enabled then return end
                if cfg._active then return end
                Fn.safeCall("M2Aimlock preparem2 fallback", function()
                    Fn._triggerM2Aimlock()
                end)
            end)
        end
    end
    if not Config.Connections.M2AimlockInputBegan then
        Config.Connections.M2AimlockInputBegan = UserInputService.InputBegan:Connect(function(input, gpe)
            if gpe then return end
            if not cfg.Enabled then return end
            if input.UserInputType ~= Enum.UserInputType.MouseButton2 then return end
            if not Fn.isKillerTeam() then return end
            local now = fast_tick()
            if now - (cfg._lastTriggerAt or 0) < 0.15 then return end
            Fn.safeCall("M2Aimlock Trigger", function()
                Fn._triggerM2Aimlock()
            end)
        end)
    end
    if not Config.Connections.M2AimlockRender then
        Config.Connections.M2AimlockRender = Config.FakeConnection(
            Config.RenderSteppedTasks, "M2AimlockRender", function(dt)
                dt = dt or (1 / 60)
                if not cfg.Enabled then
                    if cfg._active then Fn._m2AimlockStopLock() end
                    return
                end
                if not cfg._active then return end
                local now = fast_tick()
                if now >= cfg._releaseAt then
                    Fn._m2AimlockStopLock()
                    return
                end
                if now >= (cfg._nextValidateAt or 0) then
                    cfg._nextValidateAt = now + 0.1
                    if not Fn.isM2AimlockTargetValid(cfg._targetChar, Fn.getRoot()) then
                        local switched = false
                        if cfg.SwitchOnDowned ~= false then
                            local newTarget = Fn._getM2AimlockTarget()
                            if newTarget then
                                switched = Fn._m2AimlockApplyTarget(newTarget)
                            end
                        end
                        if not switched then
                            Fn._m2AimlockStopLock()
                            return
                        end
                    end
                end
                local cam = workspace.CurrentCamera
                if not cam then return end
                local targetPart = cfg._targetPart
                if not targetPart or not targetPart.Parent then
                    local targetChar = cfg._targetChar
                    if targetChar and targetChar.Parent then
                        local partName = cfg.TargetPart or "HumanoidRootPart"
                        targetPart = targetChar:FindFirstChild(partName)
                                    or targetChar:FindFirstChild("HumanoidRootPart")
                        cfg._targetPart = targetPart
                    end
                end
                if not targetPart then
                    Fn._m2AimlockStopLock()
                    return
                end
                local targetPos = targetPart.Position
                local camPos = cam.CFrame.Position
                local desiredCFrame
                if (targetPos - camPos).Magnitude > 0.01 then
                    desiredCFrame = CFrame.lookAt(camPos, targetPos)
                else
                    desiredCFrame = cam.CFrame
                end
                local rawStrength = cfg.LockStrength or 1
                local alpha = (rawStrength >= 1) and 1
                            or (1 - math.exp(-rawStrength * 15 * dt))
                cam.CFrame = cam.CFrame:Lerp(desiredCFrame, alpha)
                if cfg.RotateChar and cfg._gyro and cfg._gyro.Parent then
                    local root = Fn.getRoot()
                    if root and root.Parent then
                        local hrpPos = root.Position
                        local flatTarget = Vector3.new(targetPos.X, hrpPos.Y, targetPos.Z)
                        local dir = flatTarget - hrpPos
                        if dir.Magnitude > 0.01 then
                            cfg._gyro.CFrame = CFrame.lookAt(hrpPos, hrpPos + dir)
                        end
                    end
                end
            end)
    end
end
function Fn.StopM2Aimlock()
    local cfg = Config.Killer.M2Aimlock
    Fn._m2AimlockStopLock()
    cfg._m2Fn = nil
    if cfg._prepareConn then
        pcall(function() cfg._prepareConn:Disconnect() end)
        cfg._prepareConn = nil
    end
    if Config.Connections.M2AimlockInputBegan then
        pcall(function() Config.Connections.M2AimlockInputBegan:Disconnect() end)
        Config.Connections.M2AimlockInputBegan = nil
    end
    if Config.Connections.M2AimlockRender then
        Fn._destroyConn("M2AimlockRender", Config.Connections.M2AimlockRender)
        Config.Connections.M2AimlockRender = nil
    end
end

do
    UI.KillerTab:AddToggle("M2Aimlock", { Text = "Aimlock M2 Hidden",
        Default = false,
        Callback = function(state)
            Config.Killer.M2Aimlock.Enabled = state
            if state then
                Fn.safeCall("M2Aimlock Start", function() Fn.StartM2Aimlock() end)
            else
                Fn.StopM2Aimlock()
            end
        end }):AddKeyPicker("M2Aimlock_Keybind", { Default = "None", Mode = "Toggle", SyncToggleState = true })
end

    M.Unload = function()
        pcall(function() Fn.StopM2Aimlock() end)
    end
    return M
end

return M
