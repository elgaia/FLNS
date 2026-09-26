
local M = {}

function M.Mount(env)
    env = env or {}
    local Config = assert(env.Config, "[CameraFOV] env.Config is required")
    local Fn     = assert(env.Fn, "[CameraFOV] env.Fn is required")
    assert(env.UI and env.UI.ZoomBox, "[CameraFOV] env.UI.ZoomBox is required")
    local UI     = env.UI

function Fn.applyCameraFOV()
    if Config.Connections.FOVHook then
        Config.Connections.FOVHook:Disconnect()
        Config.Connections.FOVHook = nil
    end
    if Config.Connections.CamHook then
        Config.Connections.CamHook:Disconnect()
        Config.Connections.CamHook = nil
    end
    local function updateFOV()
        local cam = workspace.CurrentCamera
        if not cam then return end
        local targetFOV = Config.CameraZoom.FOVEnabled and Config.CameraZoom.FOV or Config.CameraZoom.DefaultFOV
        if cam.FieldOfView ~= targetFOV then
            cam.FieldOfView = targetFOV
        end
    end
    local function setupCamHook()
        local cam = workspace.CurrentCamera
        if not cam then return end
        if Config.Connections.FOVHook then
            Config.Connections.FOVHook:Disconnect()
            Config.Connections.FOVHook = nil
        end
        if Config.CameraZoom.FOVEnabled then
            local function enforceFOV()
                if cam.FieldOfView ~= Config.CameraZoom.FOV then
                    cam.FieldOfView = Config.CameraZoom.FOV
                end
            end
            enforceFOV()
            Config.Connections.FOVHook = cam:GetPropertyChangedSignal("FieldOfView"):Connect(enforceFOV)
        else
            updateFOV()
        end
    end
    setupCamHook()
    Config.Connections.CamHook = workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(setupCamHook)
end

UI.ZoomBox:AddToggle("CustomFOV", { Text = "Custom FOV", Default = false,
    Callback = function(v) Config.CameraZoom.FOVEnabled = v; Fn.applyCameraFOV() end }):AddKeyPicker("CustomFOV_Keybind", { Default = "None", Mode = "Toggle", SyncToggleState = true })
UI.ZoomBox:AddSlider("CameraFOV", { Text = "Camera FOV", Default = 70, Min = 40, Max = 120, Rounding = 0,
    Callback = function(v)
        Config.CameraZoom.FOV = v
        if Config.CameraZoom.FOVEnabled then Fn.applyCameraFOV() end
    end })

    M.Unload = function()
    end
    return M
end

return M
