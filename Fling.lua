
local M = {}

function M.Mount(env)
    env = env or {}
    local Config         = assert(env.Config, "[Fling] env.Config is required")
    local Fn             = assert(env.Fn, "[Fling] env.Fn is required")
    assert(env.UI and env.UI.FlingBox, "[Fling] env.UI.FlingBox is required")
    local UI             = env.UI
    local LocalPlayer    = env.LocalPlayer or game:GetService("Players").LocalPlayer
    local Players        = assert(env.Players, "[Fling] env.Players is required")
    local fast_tick      = env.fast_tick or tick
    local getRoot        = assert(env.getRoot, "[Fling] env.getRoot is required")
    local formatUsername = assert(env.formatUsername, "[Fling] env.formatUsername is required")
    local getPlayer      = assert(env.getPlayer, "[Fling] env.getPlayer is required")
    local breakVelocity  = assert(env.breakVelocity, "[Fling] env.breakVelocity is required")
    local Options        = env.Options or {}

local Fling_PlayerLabels = {}
local function flingBuildPlayerList()
    local labels = {}
    Fling_PlayerLabels = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            local label = formatUsername(p)
            if Fling_PlayerLabels[label] then
                label = label .. " (" .. p.Name .. ")"
            end
            Fling_PlayerLabels[label] = p
            table.insert(labels, label)
        end
    end
    table.sort(labels)
    if #labels == 0 then
        table.insert(labels, "(no players)")
    end
    return labels
end
local function flingResolveTarget(query)
    if typeof(query) == "Instance" then
        if query.Parent == Players and query ~= LocalPlayer then return query end
        return nil
    end
    if type(query) ~= "string" or query == "" then return nil end
    local direct = Fling_PlayerLabels[query]
    if direct and direct.Parent == Players then return direct end
    local matches = getPlayer(query, LocalPlayer)
    if matches[1] then return matches[1] end
    local byName = Players:FindFirstChild(query)
    if byName and byName ~= LocalPlayer then return byName end
    return nil
end
local _Fling_BreakCFrame = function(cf)
    if typeof(cf) ~= "CFrame" then return cf end
    return CFrame.new(0, 1e9, 0)
end
local _Fling_ApplyToArgs = function(args)
    if not args then return args end
    for i = 1, 5 do
        if typeof(args[i]) == "CFrame" then
            args[i] = _Fling_BreakCFrame(args[i])
        end
    end
    return args
end

function Fn._flingSequence(target, opts)
    opts = opts or {}
    local char = LocalPlayer.Character
    local root = char and getRoot(char)
    if not root then
        return false
    end
    local originalCFrame = root.CFrame
    Fn.CharLook_EnsureHook()
    local attempts    = math.max(1, tonumber(Config.Fling.Attempts) or 3)
    local pulseTime   = math.max(0.05, tonumber(Config.Fling.PulseTime) or 0.3)
    local successDist = math.max(1, tonumber(Config.Fling.SuccessDist) or 8)
    local success = false
    for attempt = 1, attempts do
        if Config.State.unloaded then break end
        local tChar = target.Character
        local tRoot = tChar and getRoot(tChar)
        if not tRoot then break end
        local targetStart = tRoot.Position
        local spin = 0
        Config.Fling.Enabled = true
        local deadline = fast_tick() + pulseTime
        while fast_tick() < deadline and not Config.State.unloaded do
            local tr = target.Character and getRoot(target.Character)
            if not tr then break end
            local myRoot = getRoot(LocalPlayer.Character)
            if not myRoot then break end
            spin = spin + 0.9
            myRoot.CFrame = tr.CFrame * CFrame.Angles(0, spin, 0)
            task.wait()
        end
        Config.Fling.Enabled = false
        task.wait(0.08)
        local tCharAfter = target.Character
        local tRootAfter = tCharAfter and getRoot(tCharAfter)
        if not tRootAfter then
            success = true
        else
            local moved = (tRootAfter.Position - targetStart).Magnitude
            local vel  = tRootAfter.AssemblyLinearVelocity.Magnitude
            local hum  = tCharAfter:FindFirstChildOfClass("Humanoid")
            if moved >= successDist or vel >= 75 or (hum and hum.Health <= 0) then
                success = true
            end
        end
        if success then break end
    end
    local finalRoot = getRoot(LocalPlayer.Character)
    if finalRoot then
        finalRoot.CFrame = originalCFrame
        finalRoot.AssemblyLinearVelocity = Vector3.zero
        finalRoot.AssemblyAngularVelocity = Vector3.zero
        breakVelocity()
    end
    Config.Fling.Enabled = false
    return success
end
function Fn.flingPlayer(target)
    if Config.Fling.Busy then
        return
    end
    local resolved = flingResolveTarget(target)
    if not resolved then
        return
    end
    local tChar = resolved.Character
    if not (tChar and getRoot(tChar)) then
        return
    end
    Config.Fling.Busy = true
    task.spawn(function()
        Fn._flingSequence(resolved)
        Config.Fling.Busy = false
    end)
end
function Fn.flingSelected()
    local label = Config.Fling.TargetLabel
    if not label or label == "" then
        return
    end
    Fn.flingPlayer(label)
end
function Fn.flingNearest()
    if Config.Fling.Busy then
        return
    end
    local myChar = LocalPlayer.Character
    local myRoot = myChar and getRoot(myChar)
    if not myRoot then
        return
    end
    local best, bestDist = nil, math.huge
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            local pRoot = p.Character and getRoot(p.Character)
            if pRoot then
                local d = (pRoot.Position - myRoot.Position).Magnitude
                if d < bestDist then
                    best, bestDist = p, d
                end
            end
        end
    end
    if not best then
        return
    end
    Fn.flingPlayer(best)
end
function Fn.flingAll()
    if Config.Fling.Busy then
        return
    end
    local targets = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            table.insert(targets, p)
        end
    end
    if #targets == 0 then
        return
    end
    Config.Fling.Busy = true
    task.spawn(function()
        local okCount, failCount, skipped = 0, 0, 0
        for i, p in ipairs(targets) do
            if Config.State.unloaded then break end
            if p.Parent ~= Players or not (p.Character and getRoot(p.Character)) then
                skipped = skipped + 1
            else
                local ok = Fn._flingSequence(p, { silent = true })
                if ok then okCount = okCount + 1 else failCount = failCount + 1 end
                task.wait(math.max(0, tonumber(Config.Fling.Cooldown) or 0.3))
            end
        end
        Config.Fling.Busy = false
    end)
end
function Fn.refreshFlingTargets()
    if Config.State.unloaded then return end
    pcall(function()
        local dropdown = Options.FlingTarget
        if not dropdown then return end
        local labels = flingBuildPlayerList()
        dropdown:SetValues(labels)
        local current = Config.Fling.TargetLabel
        if current and Fling_PlayerLabels[current] then
            pcall(function() dropdown:SetValue(current) end)
            Config.Fling.Target = Fling_PlayerLabels[current]
        else
            local v = dropdown.Value
            if v and Fling_PlayerLabels[v] then
                Config.Fling.TargetLabel = v
                Config.Fling.Target = Fling_PlayerLabels[v]
            else
                Config.Fling.TargetLabel = ""
                Config.Fling.Target = nil
            end
        end
    end)
end

Fn.Fling_ApplyToArgs = _Fling_ApplyToArgs

UI.FlingBox:AddDropdown("FlingTarget", {
    Text = "Target Player",
    Values = flingBuildPlayerList(),
    Default = nil,
    Multi = false,
    Searchable = true,
    Callback = function(v)
        Config.Fling.TargetLabel = v or ""
        Config.Fling.Target = (v and Fling_PlayerLabels[v]) or nil
    end
})
UI.FlingBox:AddButton({ Text = "Fling Selected Target", Func = function()
    Fn.flingSelected()
end })
UI.FlingBox:AddButton({ Text = "Fling Nearest Player", Func = function()
    Fn.flingNearest()
end })
UI.FlingBox:AddButton({ Text = "Fling All Players", Func = function()
    Fn.flingAll()
end })
UI.FlingBox:AddDivider()
UI.FlingBox:AddSlider("FlingPulseTime", { Text = "Fling Duration (s)",
    Default = 0.3, Min = 0.05, Max = 1, Rounding = 2,
    Callback = function(v) Config.Fling.PulseTime = v end })
UI.FlingBox:AddSlider("FlingAttempts", { Text = "Retry Attempts",
    Default = 3, Min = 1, Max = 5, Rounding = 0,
    Callback = function(v) Config.Fling.Attempts = v end })
UI.FlingBox:AddSlider("FlingSuccessDist", { Text = "Success Distance (studs)",
    Default = 8, Min = 3, Max = 50, Rounding = 0,
    Callback = function(v) Config.Fling.SuccessDist = v end })
Config.Connections.FlingPlayerAdded = Players.PlayerAdded:Connect(function()
    task.defer(function() Fn.refreshFlingTargets() end)
end)
Config.Connections.FlingPlayerRemoving = Players.PlayerRemoving:Connect(function(p)
    if Config.Fling.Target == p then
        Config.Fling.Target = nil
        Config.Fling.TargetLabel = ""
    end
    task.defer(function() Fn.refreshFlingTargets() end)
end)
task.delay(1, function() Fn.refreshFlingTargets() end)

    M.Unload = function()
        pcall(function()
            Config.Fling.Enabled = false
            Config.Fling.Busy = false
            if Config.Connections then
                if Config.Connections.FlingPlayerAdded then
                    pcall(function() Config.Connections.FlingPlayerAdded:Disconnect() end)
                    Config.Connections.FlingPlayerAdded = nil
                end
                if Config.Connections.FlingPlayerRemoving then
                    pcall(function() Config.Connections.FlingPlayerRemoving:Disconnect() end)
                    Config.Connections.FlingPlayerRemoving = nil
                end
            end
        end)
    end
    return M
end

return M
