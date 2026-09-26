
local M = {}

function M.Mount(env)
    env = env or {}
    local Config = assert(env.Config, "[NoScreenEffects] env.Config is required")
    local Fn     = assert(env.Fn, "[NoScreenEffects] env.Fn is required")
    assert(env.UI and env.UI.VisualBox, "[NoScreenEffects] env.UI.VisualBox is required")
    local UI     = env.UI
    local Lighting = assert(env.Lighting, "[NoScreenEffects] env.Lighting is required")


function Fn.applyNoScreenEffects()
    if Config.LastVisualState.NoScreenEffects == Config.Visual.NoScreenEffects then return end
    Config.LastVisualState.NoScreenEffects = Config.Visual.NoScreenEffects
    if Config.Visual.NoScreenEffects then
        for _, v in pairs(Lighting:GetChildren()) do
            for _, t in pairs(Config.ScreenEffectTypes) do
                if v:IsA(t) then Config.DisabledEffects[v] = v.Enabled; v.Enabled = false end
            end
        end
    else
        for obj, s in pairs(Config.DisabledEffects) do
            if obj and obj.Parent then obj.Enabled = s end
        end
        for k in pairs(Config.DisabledEffects) do Config.DisabledEffects[k] = nil end
    end
end

UI.VisualBox:AddToggle("NoScreenEffects", { Text = "No Screen Effects", Default = false,
    Callback = function(v) Config.Visual.NoScreenEffects = v; Fn.applyNoScreenEffects() end }):AddKeyPicker("NoScreenEffects_Keybind", { Default = "None", Mode = "Toggle", SyncToggleState = true })

    M.Unload = function()

    end
    return M
end

return M
