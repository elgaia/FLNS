
local M = {}

function M.Mount(env)
    env = env or {}
    local Config      = assert(env.Config, "[BlockVaults] env.Config is required")
    local Fn          = assert(env.Fn, "[BlockVaults] env.Fn is required")
    assert(env.UI and env.UI.KillerTab, "[BlockVaults] env.UI.KillerTab is required")
    local UI          = env.UI
    local LocalPlayer = env.LocalPlayer or game:GetService("Players").LocalPlayer
    local ReplicatedStorage = env.ReplicatedStorage or game:GetService("ReplicatedStorage")

function Fn.HandleBlockVaults()
    if not Config.Killer.BlockVaults then return end
    local isKiller = LocalPlayer.Team and LocalPlayer.Team.Name == "Killer"
    if not isKiller then return end
    local remotes = ReplicatedStorage:FindFirstChild("Remotes")
    local vaultEvent = remotes and remotes:FindFirstChild("Window") and remotes.Window:FindFirstChild("VaultEvent")
    if not vaultEvent then return end
    local memo = Config.State._vaultFireOK
    if memo == nil then
        memo = setmetatable({}, { __mode = "k" })
        Config.State._vaultFireOK = memo
    end
    local function collectAndFire(container)
        for _, part in ipairs(container:GetDescendants()) do
            if part:IsA("BasePart") and not memo[part] then
                local ok = Fn.safeCall("BlockVaults", function() vaultEvent:FireServer(part, true) end)
                if ok then
                    memo[part] = true
                end
            end
        end
    end
    local map = workspace:FindFirstChild("Map")
    local vaultsFolder = map and map:FindFirstChild("Vaults")
    if vaultsFolder then
        for _, vault in ipairs(vaultsFolder:GetChildren()) do
            collectAndFire(vault)
        end
    else
        for window in pairs(Config.ESPCache.Windows) do
            if window and window.Parent then
                collectAndFire(window)
            end
        end
    end
end

UI.KillerTab:AddToggle("BlockAllVaults", { Text = "Block All Vaults",
    Default = false,
    Callback = function(v)
        Config.Killer.BlockVaults = v
        if not v and Config.State._vaultFireOK then
            Config.State._vaultFireOK = nil
        end
    end }):AddKeyPicker("BlockAllVaults_Keybind", { Default = "None", Mode = "Toggle", SyncToggleState = true })

    M.Unload = function()
        Config.State._vaultFireOK = nil
    end
    return M
end

return M
