
local M = {}

function M.Mount(env)
    env = env or {}
    local Config      = assert(env.Config, "[InstantEscape] env.Config is required")
    local Fn          = assert(env.Fn, "[InstantEscape] env.Fn is required")
    assert(env.UI and env.UI.AbilityTab, "[InstantEscape] env.UI.AbilityTab is required")
    local UI          = env.UI
    local LocalPlayer = env.LocalPlayer or game:GetService("Players").LocalPlayer

function Fn.teleportToFinishLine()
    local root = Fn.getRoot()
    if not root then return end
    local found = Config.State._finishLineCache
    if not found or not found.Parent then
        Config.State._finishLineCache = nil
        found = nil
        for _, obj in ipairs(workspace:GetDescendants()) do
            if string.lower(obj.Name) == "fininshline" and obj:IsA("BasePart") then
                found = obj
                Config.State._finishLineCache = obj
                break
            end
        end
    end
    if not found then warn("fininshline not found"); return end
    root.CFrame = found.CFrame + Vector3.new(0, 5, 0)
end

UI.AbilityTab:AddDivider()
UI.AbilityTab:AddButton({ Text = "Instant Escape", Func = function() Fn.teleportToFinishLine() end })

    M.Unload = function()
    end
    return M
end

return M
