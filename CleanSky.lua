
local M = {}

function M.Mount(env)
    env = env or {}
    local Config = assert(env.Config, "[CleanSky] env.Config is required")
    local Fn     = assert(env.Fn, "[CleanSky] env.Fn is required")
    assert(env.UI and env.UI.VisualBox, "[CleanSky] env.UI.VisualBox is required")
    local UI     = env.UI
    local Lighting = assert(env.Lighting, "[CleanSky] env.Lighting is required")

Fn.hideSkyOrClouds = function(v)
    if not v or v.Parent == nil then return end
    if v:IsA("Sky") then
        if Config.DisabledSkies[v] == nil then
            Config.DisabledSkies[v] = v.Parent
        end
        pcall(function() v.Parent = nil end)
    elseif v:IsA("Clouds") then
        if Config.DisabledClouds[v] == nil then
            Config.DisabledClouds[v] = v.Parent
        end
        pcall(function() v.Parent = nil end)
    end
end
local function getVisualCleanupContainers()
    local list = { Lighting }
    local map = workspace:FindFirstChild("Map")
    if map then table.insert(list, map) end
    local terrain = workspace:FindFirstChildOfClass("Terrain")
    if terrain then table.insert(list, terrain) end
    return list
end
function Fn.applyOptimization(force)
    if not (force or Config.LastOptimizationState.CleanSky ~= Config.Visual.CleanSky) then
        return
    end
    Config.LastOptimizationState.CleanSky = Config.Visual.CleanSky
    if Config.Visual.CleanSky then
        for _, container in ipairs(getVisualCleanupContainers()) do
            pcall(function()
                for _, v in pairs(container:GetDescendants()) do
                    Fn.hideSkyOrClouds(v)
                end
            end)
        end
    else
        for sky, parent in pairs(Config.DisabledSkies) do
            if sky and parent then
                pcall(function() sky.Parent = parent end)
            end
        end
        for k in pairs(Config.DisabledSkies) do Config.DisabledSkies[k] = nil end
        for clouds, parent in pairs(Config.DisabledClouds) do
            if clouds and parent then
                pcall(function() clouds.Parent = parent end)
            end
        end
        for k in pairs(Config.DisabledClouds) do Config.DisabledClouds[k] = nil end
    end
end

UI.VisualBox:AddToggle("CleanSky", { Text = "Clean Sky", Default = false,
    Callback = function(v) Config.Visual.CleanSky = v; Fn.applyOptimization() end }):AddKeyPicker("CleanSky_Keybind", { Default = "None", Mode = "Toggle", SyncToggleState = true })

    M.Unload = function()

    end
    return M
end

return M
