
local M = {}

function M.Mount(env)
    env = env or {}
    local Config      = assert(env.Config, "[KillAll] env.Config is required")
    local Fn          = assert(env.Fn, "[KillAll] env.Fn is required")
    assert(env.UI and env.UI.KillerTab, "[KillAll] env.UI.KillerTab is required")
    local UI          = env.UI
    local LocalPlayer = env.LocalPlayer or game:GetService("Players").LocalPlayer
    local Players = env.Players or game:GetService("Players")
    local AttackEvent = env.AttackEvent

function Fn.GetNearestAliveSurvivor()
    local root = Fn.getRoot()
    if not root then return nil end
    local closest, shortest = nil, math.huge
    for _, plr in ipairs(Config.ESPCache.PlayerList) do
        if plr ~= LocalPlayer and plr.Character
        and plr.Team and plr.Team.Name == "Survivors" then
            local hum = plr.Character:FindFirstChildOfClass("Humanoid")
            local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
            if hum and hrp and hum.Health > 30 and not Fn.checkDowned(plr.Character) then
                local d = (hrp.Position - root.Position).Magnitude
                if d < shortest then shortest = d; closest = plr.Character end
            end
        end
    end
    return closest
end
function Fn.HandleKillAll()
    if not Config.Killer.KillAll then return end
    local root = Fn.getRoot()
    if root then
        local needRetarget = false
        if not Config.State.KillerTarget then
            needRetarget = true
        else
            local targetPlayer = Players:GetPlayerFromCharacter(Config.State.KillerTarget)
            if not (targetPlayer and targetPlayer.Team and targetPlayer.Team.Name == "Survivors") then
                needRetarget = true
            elseif Fn.checkDowned(Config.State.KillerTarget) then
                needRetarget = true
            end
        end
        if needRetarget then
            Config.State.KillerTarget = Fn.GetNearestAliveSurvivor()
        end
        local target = Config.State.KillerTarget
        if target and not Fn.checkDowned(target) then
            local targetHRP = target:FindFirstChild("HumanoidRootPart")
            local targetHum = target:FindFirstChildOfClass("Humanoid")
            if targetHRP and targetHum and targetHum.Health > 0 then
                local velocity = targetHRP.AssemblyLinearVelocity
                local predict  = velocity * 0.15
                local targetPos = targetHRP.Position + predict
                local behind    = targetHRP.CFrame.LookVector * -3
                root.CFrame = CFrame.new(targetPos + behind, targetPos)
                Fn.safeCall("KillAll Attack", function() AttackEvent:FireServer(false) end)
            end
        end
    end
end

UI.KillerTab:AddToggle("KillAll", { Text = "Auto Kill All", Default = false,
    Callback = function(v) Config.Killer.KillAll = v end }):AddKeyPicker("KillAll_Keybind", { Default = "None", Mode = "Toggle", SyncToggleState = true })

    M.Unload = function()
        Config.State.KillerTarget = nil
    end
    return M
end

return M
