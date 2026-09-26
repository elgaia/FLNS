
local M = {}

function M.Mount(env)
    env = env or {}
    local Config = assert(env.Config, "[CleanTexture] env.Config is required")
    local Fn     = assert(env.Fn, "[CleanTexture] env.Fn is required")
    assert(env.UI and env.UI.VisualBox, "[CleanTexture] env.UI.VisualBox is required")
    local UI     = env.UI
    local Lighting = assert(env.Lighting, "[CleanTexture] env.Lighting is required")

Fn.hideSurfaceAppearance = function(v)
    if not v or v.Parent == nil then return end
    if v:IsA("SurfaceAppearance") then
        if Config.DisabledTextures[v] == nil then
            Config.DisabledTextures[v] = v.Parent
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
function Fn.applyCleanTexture(force)
    if not (force or Config.LastOptimizationState.CleanTexture ~= Config.Visual.CleanTexture) then
        return
    end
    Config.LastOptimizationState.CleanTexture = Config.Visual.CleanTexture
    if Config.Visual.CleanTexture then
        for _, container in ipairs(getVisualCleanupContainers()) do
            pcall(function()
                for _, v in pairs(container:GetDescendants()) do
                    Fn.hideSurfaceAppearance(v)
                end
            end)
        end
    else
        for sa, parent in pairs(Config.DisabledTextures) do
            if sa and parent then
                pcall(function() sa.Parent = parent end)
            end
        end
        for k in pairs(Config.DisabledTextures) do Config.DisabledTextures[k] = nil end
    end
end

UI.VisualBox:AddToggle("CleanTexture", { Text = "Clean Texture", Default = false,
    Callback = function(v) Config.Visual.CleanTexture = v; Fn.applyCleanTexture() end }):AddKeyPicker("CleanTexture_Keybind", { Default = "None", Mode = "Toggle", SyncToggleState = true })

    M.Unload = function()

    end
    return M
end

return M
