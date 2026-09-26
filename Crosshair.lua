--[[
========================================================================
  FLNS - Crosshair Module  (standalone)
  Fitur tab      : Aimbot
  Diekstrak dari : FLNS.VD.MAIN.patched.v9.lua
  Dimuat oleh    : loadstring(game:HttpGet(MODULE_REPO .. "Crosshair.lua"))()

  API:
    M.Mount(env)
        env (wajib) : Config, Fn, UI (berisi UI.CrosshairBox)
    M.Unload()
        Menghapus semua objek Drawing crosshair.
========================================================================
]]
local M = {}

function M.Mount(env)
    env = env or {}
    local Config = assert(env.Config, "[Crosshair] env.Config is required")
    local Fn     = assert(env.Fn, "[Crosshair] env.Fn is required")
    assert(env.UI and env.UI.CrosshairBox, "[Crosshair] env.UI.CrosshairBox is required")
    local UI     = env.UI

function Fn.clearCrosshair()
    for _, v in pairs(Config.CrosshairDrawings) do if v.Remove then v:Remove() end end
    for k in pairs(Config.CrosshairDrawings) do Config.CrosshairDrawings[k] = nil end
end
function Fn.drawCrosshair()
    if not Config.Crosshair.Enabled then
        for _, v in pairs(Config.CrosshairDrawings) do if v then v.Visible = false end end
        return
    end
    if not (Drawing and Drawing.new) then return end
    if Config.State.LastCrosshairStyle ~= Config.Crosshair.Style then
        Fn.clearCrosshair(); Config.State.created = false
        Config.State.LastCrosshairStyle = Config.Crosshair.Style
    end
    local cam = workspace.CurrentCamera
    local center = Vector2.new(
        cam.ViewportSize.X / 2 + Config.Crosshair.OffsetX,
        cam.ViewportSize.Y / 2 + Config.Crosshair.OffsetY
    )
    if not Config.State.created then
        Config.State.created = true
        if Config.Crosshair.Style == "Plus" then
            for i = 1, 4 do
                local line = Drawing.new("Line"); line.Visible = true; line.Transparency = 1; line.ZIndex = 999
                table.insert(Config.CrosshairDrawings, line)
            end
        elseif Config.Crosshair.Style == "Dot" then
            local dot = Drawing.new("Circle"); dot.Filled = true; dot.Visible = true; dot.Transparency = 1; dot.ZIndex = 999
            table.insert(Config.CrosshairDrawings, dot)
        elseif Config.Crosshair.Style == "Circle" then
            local circle = Drawing.new("Circle"); circle.Filled = false; circle.Visible = true; circle.Transparency = 1; circle.ZIndex = 999
            table.insert(Config.CrosshairDrawings, circle)
        end
    end
    for _, v in pairs(Config.CrosshairDrawings) do
        if v then
            v.Visible = true
            v.Transparency = 1
            v.ZIndex = 999
        end
    end
    if Config.Crosshair.Style == "Plus" then
        for _, line in pairs(Config.CrosshairDrawings) do line.Color = Config.Crosshair.Color; line.Thickness = Config.Crosshair.Thickness end
        Config.CrosshairDrawings[1].From = center + Vector2.new(-Config.Crosshair.Size, 0); Config.CrosshairDrawings[1].To = center + Vector2.new(-2, 0)
        Config.CrosshairDrawings[2].From = center + Vector2.new(Config.Crosshair.Size, 0); Config.CrosshairDrawings[2].To = center + Vector2.new(2, 0)
        Config.CrosshairDrawings[3].From = center + Vector2.new(0, -Config.Crosshair.Size); Config.CrosshairDrawings[3].To = center + Vector2.new(0, -2)
        Config.CrosshairDrawings[4].From = center + Vector2.new(0, Config.Crosshair.Size); Config.CrosshairDrawings[4].To = center + Vector2.new(0, 2)
    elseif Config.Crosshair.Style == "Dot" then
        local dot = Config.CrosshairDrawings[1]
        dot.Position = center; dot.Radius = Config.Crosshair.Size / 2; dot.Color = Config.Crosshair.Color
    elseif Config.Crosshair.Style == "Circle" then
        local circle = Config.CrosshairDrawings[1]
        circle.Position = center; circle.Radius = Config.Crosshair.Size
        circle.Color = Config.Crosshair.Color; circle.Thickness = Config.Crosshair.Thickness
    end
end

UI.CrosshairBox:AddToggle("CrosshairEnabled", { Text = "Enable Crosshair", Default = false,
    Callback = function(v) Config.Crosshair.Enabled = v end }):AddKeyPicker("CrosshairEnabled_Keybind", { Default = "None", Mode = "Toggle", SyncToggleState = true }):AddColorPicker("CrosshairColor", { Default = Color3.fromRGB(255,255,255), Title = "Crosshair Color", Transparency = 0,
    Callback = function(color) Config.Crosshair.Color = color end })
UI.CrosshairBox:AddDropdown("Style", { Values = {"Plus", "Dot", "Circle"}, Default = 1, Multi = false, Text = "Style",
    Callback = function(v) Config.Crosshair.Style = v end })
UI.CrosshairBox:AddSlider("CrosshairSize", { Text = "Size", Default = 8, Min = 1, Max = 100, Rounding = 1, Compact = false,
    Callback = function(v) Config.Crosshair.Size = v end })
UI.CrosshairBox:AddSlider("CrosshairThickness", { Text = "Thickness", Default = 2, Min = 1, Max = 10, Rounding = 1, Compact = false,
    Callback = function(v) Config.Crosshair.Thickness = v end })
UI.CrosshairBox:AddSlider("CrosshairPosX", { Text = "Offset X", Default = 0, Min = -500, Max = 500, Rounding = 1, Compact = false,
    Callback = function(v) Config.Crosshair.OffsetX = v end })
UI.CrosshairBox:AddSlider("CrosshairPosY", { Text = "Offset Y", Default = 0, Min = -500, Max = 500, Rounding = 1, Compact = false,
    Callback = function(v) Config.Crosshair.OffsetY = v end })

    M.Unload = function()
        pcall(function() Fn.clearCrosshair() end)
    end
    return M
end

return M
