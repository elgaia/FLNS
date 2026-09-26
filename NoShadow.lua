
local M = {}

function M.Mount(env)
    env = env or {}
    local Config = assert(env.Config, "[NoShadow] env.Config is required")
    local Fn     = assert(env.Fn, "[NoShadow] env.Fn is required")
    assert(env.UI and env.UI.VisualBox, "[NoShadow] env.UI.VisualBox is required")
    local UI     = env.UI

UI.VisualBox:AddToggle("NoShadow", { Text = "No Shadow", Default = false,
    Callback = function(v) Config.Visual.NoShadow = v end }):AddKeyPicker("NoShadow_Keybind", { Default = "None", Mode = "Toggle", SyncToggleState = true })

    M.Unload = function()
    end
    return M
end

return M
