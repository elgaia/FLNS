
local M = {}

function M.Mount(env)
    env = env or {}
    local Config      = assert(env.Config, "[Moonwalk] env.Config is required")
    local Fn          = assert(env.Fn, "[Moonwalk] env.Fn is required")
    assert(env.UI and env.UI.MovementBox, "[Moonwalk] env.UI.MovementBox is required")
    local UI          = env.UI
    local LocalPlayer = env.LocalPlayer or game:GetService("Players").LocalPlayer
    local fast_tick   = env.fast_tick or tick

function Fn.startMoonwalk()
    if Config.Connections.Moonwalk then Config.Connections.Moonwalk:Disconnect(); Config.Connections.Moonwalk = nil end
    local _MW_MOVE_FWD = Vector3.new(0, 0, 1)
    Config.Connections.Moonwalk = Config.FakeConnection(Config.RenderSteppedTasks, "Moonwalk", function()
        if not Config.Moonwalk.Enabled or Config.State.ParryActive or Config.State.AutoCrouchActive or Fn.isDowned() then return end
        local char = LocalPlayer.Character
        if not char or not char.Parent then return end
        local humanoid = char:FindFirstChildOfClass("Humanoid")
        local hrp = char:FindFirstChild("HumanoidRootPart")
        local cam = workspace.CurrentCamera
        if not humanoid or not hrp or not cam then return end
        if Config.Moonwalk.UseSlow and humanoid.WalkSpeed ~= Config.Moonwalk.SlowSpeed then
            humanoid.WalkSpeed = Config.Moonwalk.SlowSpeed
        end
        local look = cam.CFrame.LookVector
        local flatLook = Vector3.new(look.X, 0, look.Z)
        if flatLook.Magnitude > 0 then
            flatLook = flatLook.Unit
            local baseCF = CFrame.new(hrp.Position, hrp.Position + flatLook)
            local angle  = math.sin(fast_tick() * Config.Moonwalk.SpamSpeed) * Config.Moonwalk.Intensity
            hrp.CFrame   = baseCF * CFrame.Angles(0, math.rad(angle), 0)
            humanoid:Move(_MW_MOVE_FWD, true)
        end
    end)
end

function Fn.createMoonwalkButton()
    if Config.State.MoonwalkButton then Config.State.MoonwalkButton:Destroy() end
    local gui, btn, stroke = Fn.createGameButton({
        Name        = "MoonwalkGui",
        ButtonType  = "ImageButton",
        Size        = UDim2.new(0, 53, 0, 53),
        Position    = UDim2.new(0.67, 0, 0.77, 0),
        Image       = "rbxassetid://131126241643615",
        OnClick = function(stroke)
            Config.Moonwalk.Enabled = not Config.Moonwalk.Enabled
            local char = LocalPlayer.Character
            local hum  = char and char:FindFirstChildOfClass("Humanoid")
            if Config.Moonwalk.Enabled then
                stroke.Color = Color3.fromRGB(170, 0, 255)
                if not Config.Connections.Moonwalk then Fn.startMoonwalk() end
            else
                stroke.Color = Color3.fromRGB(255, 255, 255)
                if hum then hum.WalkSpeed = 16 end
            end
        end,
    })
    Config.State.MoonwalkButton = gui
end
function Fn.removeMoonwalkButton()
    if Config.State.MoonwalkButton then Config.State.MoonwalkButton:Destroy(); Config.State.MoonwalkButton = nil end
end

UI.MovementBox:AddToggle("MoonwalkButton", { Text = "MoonwalkButton", Default = false,
    Callback = function(v)
        Config.Moonwalk.ShowButton = v
        if v then Fn.createMoonwalkButton() else Fn.removeMoonwalkButton() end
    end }):AddKeyPicker("MoonwalkButton_Keybind", { Default = "None", Mode = "Toggle", SyncToggleState = true })
UI.MovementBox:AddLabel("Moonwalk (pc)"):AddKeyPicker("MoonwalkKey", { Mode = "Toggle", Callback = function(state)
        local isActive = (state == true)
        Config.Moonwalk.Enabled = isActive
        local char = LocalPlayer.Character
        local hum  = char and char:FindFirstChildOfClass("Humanoid")
        if isActive then
            Fn.startMoonwalk()
        else
            if Config.Connections.Moonwalk then Config.Connections.Moonwalk:Disconnect(); Config.Connections.Moonwalk = nil end
            if hum then hum.WalkSpeed = 16 end
        end
    end })
UI.MovementBox:AddSlider("MoonwalkSpamSpeed", { Text = "Spam Speed", Default = Config.Moonwalk.SpamSpeed, Min = 1, Max = 50, Rounding = 0,
    Callback = function(v) Config.Moonwalk.SpamSpeed = v end })
UI.MovementBox:AddSlider("MoonwalkIntensity", { Text = "Intensity", Default = Config.Moonwalk.Intensity, Min = 1, Max = 50, Rounding = 1,
    Callback = function(v) Config.Moonwalk.Intensity = v end })
UI.MovementBox:AddDivider()

    M.Unload = function()
        pcall(function()
            if Config.Connections and Config.Connections.Moonwalk then
                Config.Connections.Moonwalk:Disconnect()
                Config.Connections.Moonwalk = nil
            end
            Fn.removeMoonwalkButton()
            local char = LocalPlayer.Character
            local hum  = char and char:FindFirstChildOfClass("Humanoid")
            if hum then hum.WalkSpeed = 16 end
        end)
    end
    return M
end

return M
