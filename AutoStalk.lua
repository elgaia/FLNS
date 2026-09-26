
local M = {}

function M.Mount(env)
    env = env or {}
    local Config      = assert(env.Config, "[AutoStalk] env.Config is required")
    local Fn          = assert(env.Fn, "[AutoStalk] env.Fn is required")
    assert(env.UI and env.UI.KillerTab, "[AutoStalk] env.UI.KillerTab is required")
    local UI          = env.UI
    local LocalPlayer = env.LocalPlayer or game:GetService("Players").LocalPlayer
    local Remotes = env.Remotes
    local fast_tick = env.fast_tick or tick

local STALK_KILLER_IDS = {
    ["Stalker"] = true,
}
function Fn.getStalkRemote()
    local S = Config.Killer.Stalk
    local now = fast_tick()
    if S._remote and S._remote.Parent and (now - S._remoteAt) < 5 then
        return S._remote
    end
    S._remoteAt = now
    local killers = Remotes:FindFirstChild("Killers", true)
    local stalker = killers and killers:FindFirstChild("Stalker", true)
    local evt     = stalker and stalker:FindFirstChild("StartStalking")
    S._remote = (evt and evt:IsA("RemoteEvent")) and evt or nil
    return S._remote
end
function Fn.isStalkCapable()
    if not Fn.isKillerTeam() then return false end
    local S = Config.Killer.Stalk
    local now = fast_tick()
    if (now - S._killerAt) >= 3 then
        S._killerAt = now
        local name = Fn.GetKillerName(LocalPlayer, LocalPlayer.Character)
        S._killerOk = (name ~= nil and STALK_KILLER_IDS[name] == true)
    end
    return S._killerOk
end
function Fn.isStalkTargetValid(plr, root)
    if plr == nil or plr.Parent == nil then return false end
    if plr == LocalPlayer then return false end
    if not (plr.Team and plr.Team.Name == "Survivors") then return false end
    local char = plr.Character
    if not char or not char.Parent then return false end
    if Fn.checkDowned(char) then return false end
    local hum = char:FindFirstChildOfClass("Humanoid")
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hum or not hrp then return false end
    if hum.Health <= Config.Killer.Stalk.MinHealth then return false end
    if not root then return false end
    if (hrp.Position - root.Position).Magnitude > Config.Killer.Stalk.StalkRange then return false end
    if Config.Killer.Stalk.RequireLineOfSight and not Fn.isVisible(hrp) then return false end
    return true
end
function Fn.getClosestSurvivorForStalk()
    local root = Fn.getRoot()
    if not root then return nil end
    local closest, shortest = nil, math.huge
    for _, plr in ipairs(Config.ESPCache.PlayerList) do
        if Fn.isStalkTargetValid(plr, root) then
            local hrp = plr.Character.HumanoidRootPart
            local dist = (hrp.Position - root.Position).Magnitude
            if dist < shortest then shortest = dist; closest = plr end
        end
    end
    return closest
end
function Fn.startAutoStalk()
    if Config.Connections.Stalk then return end
    local S = Config.Killer.Stalk
    S.Target, S._remote, S._remoteAt, S._killerAt = nil, nil, 0, 0
    Config.Connections.Stalk = Config.FakeConnection(Config.HeartbeatTasks, "Stalk", function()
        if not S.Enabled then return end
        if not Fn.isStalkCapable() then
            if S.Target then S.Target = nil end
            return
        end
        local now = fast_tick()
        if now - Config.State.LastStalkFire < S.Cooldown then return end
        local root = Fn.getRoot()
        if not root then return end
        if not Fn.isStalkTargetValid(S.Target, root) then
            S.Target = Fn.getClosestSurvivorForStalk()
        end
        local target = S.Target
        if not target then return end
        local stalkEvent = Fn.getStalkRemote()
        if not stalkEvent then return end
        local ok = Fn.safeCall("AutoStalk", function()
            stalkEvent:FireServer(target)
        end)
        if ok then
            Config.State.LastStalkFire = now
        else
            Config.State.LastStalkFire = now - S.Cooldown + 0.5
            if not stalkEvent.Parent then S._remote = nil end
        end
    end)
end
function Fn.stopAutoStalk()
    if Config.Connections.Stalk then
        Config.Connections.Stalk:Disconnect()
        Config.Connections.Stalk = nil
    end
    Config.Killer.Stalk.Target = nil
end

UI.KillerTab:AddToggle("AutoStalk", { Text = "Auto Stalk (myers)", Default = false,
    Callback = function(v)
        Config.Killer.Stalk.Enabled = v
        if v then Fn.startAutoStalk() else Fn.stopAutoStalk() end
    end }):AddKeyPicker("AutoStalk_Keybind", { Default = "None", Mode = "Toggle", SyncToggleState = true })

    M.Unload = function()
        pcall(function() Fn.stopAutoStalk() end)
    end
    return M
end

return M
