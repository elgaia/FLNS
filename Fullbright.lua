
local M = {}

function M.Mount(env)
    env = env or {}
    local Config = assert(env.Config, "[Fullbright] env.Config is required")
    local Fn     = assert(env.Fn, "[Fullbright] env.Fn is required")
    assert(env.UI and env.UI.VisualBox, "[Fullbright] env.UI.VisualBox is required")
    local UI     = env.UI

UI.VisualBox:AddToggle("Fullbright", { Text = "Fullbright", Default = false,
    Callback = function(v) Config.Visual.Fullbright = v; Fn.applyVisual() end }):AddKeyPicker("Fullbright_Keybind", { Default = "None", Mode = "Toggle", SyncToggleState = true })

    M.Unload = function()

    end
    return M
end

return M
