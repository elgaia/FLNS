
local M = {}

function M.Mount(env)
    env = env or {}
    local Config      = assert(env.Config, "[AutoPalletDrop] env.Config is required")
    local Fn          = assert(env.Fn, "[AutoPalletDrop] env.Fn is required")
    assert(env.UI and env.UI.AbilityTab, "[AutoPalletDrop] env.UI.AbilityTab is required")
    local UI          = env.UI
    local LocalPlayer = env.LocalPlayer or game:GetService("Players").LocalPlayer
    local Players           = env.Players or game:GetService("Players")
    local ReplicatedStorage = env.ReplicatedStorage or game:GetService("ReplicatedStorage")
    local fast_tick         = env.fast_tick or tick
function Fn.HandleAutoPallet()
    if not Config.Auto.PalletDrop then return end
    local plr = Players.LocalPlayer
    if not (plr.Team and plr.Team.Name == "Survivors") then return end
    local now = fast_tick()
    if now - Config.Timers.lastPalletScan < 0.2 then return end
    Config.Timers.lastPalletScan = now
    if now - Config.Timers.lastPalletDrop < 2.5 then return end
    local root = Fn.getRoot()
    if not root then return end
    local hum = plr.Character:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 then return end
    local killerRoot, killerDist = Fn.GetNearestKiller()
    if not killerRoot or killerDist > Config.Auto.PalletDropDist then return end
    local remotes = ReplicatedStorage:FindFirstChild("Remotes")
    local palletFold = remotes and remotes:FindFirstChild("Pallet")
    local dropEvent = palletFold and palletFold:FindFirstChild("PalletDropEvent")
    if not dropEvent then return end
    local bestPallet = nil
    local bestDist = 8
    local function findPalletPointSlide(model)
        local slide = model:FindFirstChild("PalletPointSlide")
        if slide then return slide end
        for _, child in ipairs(model:GetDescendants()) do
            if child.Name == "PalletPointSlide" then return child end
        end
        return model:FindFirstChild("PalletPoint")
    end
    for pal, _ in pairs(Config.ESPCache.Pallets) do
        if not pal or Config.State.UsedPallets[pal] then continue end
        local refPart = pal:FindFirstChild("PalletPoint") or pal:FindFirstChild("PalletPointSlide")
        if not refPart then continue end
        local ok, pos = pcall(function() return refPart.Position end)
        if not ok or not pos then continue end
        local d = (root.Position - pos).Magnitude
        if d < bestDist then
            bestDist = d
            bestPallet = pal
        end
    end
    if bestPallet then
        local fireTarget = findPalletPointSlide(bestPallet)
        if fireTarget then
            Fn.safeCall("AutoPallet", function() dropEvent:FireServer(fireTarget) end)
            Config.State.UsedPallets[bestPallet] = true
            Config.Timers.lastPalletDrop = now
        end
    end
end

UI.AbilityTab:AddToggle("AutoPalletDrop", { Text = "Auto Drop Pallet", Default = false,
    Callback = function(v) Config.Auto.PalletDrop = v end }):AddKeyPicker("AutoPalletDrop_Keybind", { Default = "None", Mode = "Toggle", SyncToggleState = true })

    M.Unload = function()
    end
    return M
end

return M
