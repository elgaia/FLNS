
local M = {}

function M.Mount(env)
    env = env or {}
    local Config = assert(env.Config, "[ThirdPerson] env.Config is required")
    local Fn     = assert(env.Fn, "[ThirdPerson] env.Fn is required")
    assert(env.UI and env.UI.ZoomBox, "[ThirdPerson] env.UI.ZoomBox is required")
    local UI     = env.UI
    local LocalPlayer = assert(env.LocalPlayer, "[ThirdPerson] env.LocalPlayer is required")

local _V3_UP_0 = Vector3.new(0, 0, 0)

function Fn.UpdateThirdPerson()
    local cam = workspace.CurrentCamera
    if not cam then return end
    local isKiller = LocalPlayer.Team and LocalPlayer.Team.Name == "Killer"
    local shouldBeActive = Config.Killer.ThirdPerson and isKiller
    if shouldBeActive then
        if not Config.Killer.ThirdPersonWasActive then
            Config.Killer.OriginalCameraType = cam.CameraType
        end
        if cam.CameraType ~= Enum.CameraType.Custom then
            cam.CameraType = Enum.CameraType.Custom
        end
        local char = LocalPlayer.Character
        local hum = Config.Killer._cachedHum
        if not (hum and hum.Parent and hum.Parent == char) then
            hum = char and char:FindFirstChildOfClass("Humanoid")
            Config.Killer._cachedHum = hum
        end
        if hum and hum.CameraOffset ~= Config.Killer._ThirdPersonOffset then
            hum.CameraOffset = Config.Killer._ThirdPersonOffset
        end
        Config.Killer.ThirdPersonWasActive = true
    elseif Config.Killer.ThirdPersonWasActive then
        if Config.Killer.OriginalCameraType then
            cam.CameraType = Config.Killer.OriginalCameraType
            Config.Killer.OriginalCameraType = nil
        end
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum and hum.CameraOffset ~= _V3_UP_0 then
            hum.CameraOffset = _V3_UP_0
        end
        Config.Killer._cachedHum = nil
        Config.Killer.ThirdPersonWasActive = false
    end
end

UI.ZoomBox:AddToggle("ThirdPersonToggle", { Text = "Third Person View",
    Default = false,
    Callback = function(v)
        Config.Killer.ThirdPerson = v
        if not v then
            Fn.UpdateThirdPerson()
        end
    end }):AddKeyPicker("ThirdPersonToggle_Keybind", { Default = "None", Mode = "Toggle", SyncToggleState = true })

    M.Unload = function()

    end
    return M
end

return M
