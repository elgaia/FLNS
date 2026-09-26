
local M = {}

function M.Mount(env)
    env = env or {}
    local Config = assert(env.Config, "[MaxZoom] env.Config is required")
    local Fn     = assert(env.Fn, "[MaxZoom] env.Fn is required")
    assert(env.UI and env.UI.ZoomBox, "[MaxZoom] env.UI.ZoomBox is required")
    local UI     = env.UI
    local LocalPlayer = assert(env.LocalPlayer, "[MaxZoom] env.LocalPlayer is required")

function Fn.applyMaxZoom()
    if Config.Connections.MaxZoomHook then
        Config.Connections.MaxZoomHook:Disconnect()
        Config.Connections.MaxZoomHook = nil
    end
    if Config.CameraZoom.MaxZoom then
        local function updateZoom()
            if not Config.CameraZoom.MaxZoom then return end
            local attrVal = LocalPlayer:GetAttribute("CameraMaxZoomDistance")
            local maxDist
            if type(attrVal) == "number" then
                maxDist = math.clamp(attrVal, Config.CameraZoom.MinDistance, Config.CameraZoom.MaxZoomMax)
            else
                maxDist = math.clamp(Config.CameraZoom.MaxDistance,
                                     Config.CameraZoom.MinDistance,
                                     Config.CameraZoom.MaxZoomMax)
            end
            if LocalPlayer.CameraMaxZoomDistance ~= maxDist then
                LocalPlayer.CameraMaxZoomDistance = maxDist
            end
            if LocalPlayer.CameraMinZoomDistance ~= Config.CameraZoom.MinDistance then
                LocalPlayer.CameraMinZoomDistance = Config.CameraZoom.MinDistance
            end
        end
        updateZoom()
        Config.Connections.MaxZoomHook = LocalPlayer:GetPropertyChangedSignal("CameraMaxZoomDistance"):Connect(updateZoom)
    else
        LocalPlayer.CameraMaxZoomDistance = 128
        LocalPlayer.CameraMinZoomDistance = 0.5
    end
end

UI.ZoomBox:AddToggle("MaxZoom", { Text = "Max Zoom", Default = false,
    Callback = function(v) Config.CameraZoom.MaxZoom = v; Fn.applyMaxZoom() end }):AddKeyPicker("MaxZoom_Keybind", { Default = "None", Mode = "Toggle", SyncToggleState = true })
UI.ZoomBox:AddSlider("MaxZoomDistance", { Text = "Max Zoom Distance", Default = 0.5, Min = 0.5, Max = 20, Rounding = 2,
    Callback = function(v)
        Config.CameraZoom.MaxDistance = v
        if Config.CameraZoom.MaxZoom then Fn.applyMaxZoom() end
    end })

    M.Unload = function()

    end
    return M
end

return M
