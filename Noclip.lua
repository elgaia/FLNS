
local M = {}

function M.Mount(env)
    env = env or {}
    local Config      = assert(env.Config, "[Noclip] env.Config is required")
    local Fn          = assert(env.Fn, "[Noclip] env.Fn is required")
    assert(env.UI and env.UI.MovementBox, "[Noclip] env.UI.MovementBox is required")
    local UI          = env.UI
    local LocalPlayer = env.LocalPlayer or game:GetService("Players").LocalPlayer
    local RunService  = assert(env.RunService, "[Noclip] env.RunService is required")

function Fn.setNoclip(enabled)
    if Config.Noclip.Connection then
        pcall(function() Config.Noclip.Connection:Disconnect() end)
        Config.Noclip.Connection = nil
    end
    if enabled then
        Config.Noclip.Enabled = true
        task.wait(0.1)
        Config.Noclip.Parts = {}
        Config.Noclip._cachedChar = nil
        Config.Noclip._cachedParts = {}
        local function rebuildCache(char)
            Config.Noclip._cachedChar = char
            Config.Noclip._cachedParts = {}
            if not char then return end
            for _, child in ipairs(char:GetDescendants()) do
                if child:IsA("BasePart") then
                    table.insert(Config.Noclip._cachedParts, child)
                end
            end
        end
        rebuildCache(LocalPlayer.Character)
        local charConn
        charConn = LocalPlayer.CharacterAdded:Connect(function(newChar)
            task.wait(0.3)
            rebuildCache(newChar)
        end)
        Config.Noclip._charConn = charConn
        Config.Noclip.Connection = RunService.Stepped:Connect(function()
            local char = LocalPlayer.Character
            if not char then return end
            if char ~= Config.Noclip._cachedChar then
                rebuildCache(char)
            end
            local parts = Config.Noclip._cachedParts
            for i = 1, #parts do
                local child = parts[i]
                if child and child.Parent and child.CanCollide == true then
                    local ignore = false
                    if Config.Noclip.IgnoreNames and Config.Noclip.IgnoreNames[child.Name] then
                        ignore = true
                    end
                    if not ignore then
                        child.CanCollide = false
                        Config.Noclip.Parts[child] = true
                    end
                end
            end
        end)
    else
        Config.Noclip.Enabled = false
        task.wait(0.1)
        if Config.Noclip._charConn then
            pcall(function() Config.Noclip._charConn:Disconnect() end)
            Config.Noclip._charConn = nil
        end
        for child, _ in pairs(Config.Noclip.Parts) do
            if typeof(child) == "Instance" and child:IsA("BasePart") and child.Parent then
                child.CanCollide = true
            end
        end
        Config.Noclip.Parts = {}
        Config.Noclip._cachedParts = {}
        Config.Noclip._cachedChar = nil
    end
end

do
    local toggle = UI.MovementBox:AddToggle("NoclipToggle", { Text = "Noclip",
        Default = false,
        Callback = function(v)
            Fn.setNoclip(v)
            Fn.updateToggleIconVisual("Noclip")
        end }):AddKeyPicker("NoclipToggle_Keybind", { Default = "None", Mode = "Toggle", SyncToggleState = true })
end

    M.Unload = function()
        pcall(function()
            if Config.Noclip.Enabled or Config.Noclip.Connection then
                Fn.setNoclip(false)
            end
        end)
    end
    return M
end

return M
