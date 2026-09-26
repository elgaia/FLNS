local M = {}

function M.Mount(env)
    env = env or {}
    local Config      = assert(env.Config, "[AutoCrouch] env.Config is required")
    local Fn          = assert(env.Fn, "[AutoCrouch] env.Fn is required")
    assert(env.UI and env.UI.AbilityTab, "[AutoCrouch] env.UI.AbilityTab is required")
    local UI          = env.UI
    local LocalPlayer = env.LocalPlayer or game:GetService("Players").LocalPlayer
    local Players   = env.Players or game:GetService("Players")
    local fast_tick = env.fast_tick or tick

local function restoreCrouchAttributes()
    local orig = Config.State.AutoCrouchOriginals
    if not orig then return end
    Config.State.AutoCrouchOriginals = nil
    Config.State._autoCrouchSpeedLast = 0
    if not orig.char or not orig.char.Parent then return end
    pcall(function()
        orig.char:SetAttribute("Crouching", orig.Crouching)
        orig.char:SetAttribute("Crouchingserver", orig.CrouchingServer)
        orig.char:SetAttribute("IsRunning", orig.IsRunning)
        if orig.WalkSpeed then
            local hum = orig.char:FindFirstChildOfClass("Humanoid")
            if hum then hum.WalkSpeed = orig.WalkSpeed end
        end
    end)
end
local function TriggerCrouchStop()
    if not Config.State.AutoCrouchActive then return end
    restoreCrouchAttributes()
    Config.State.AutoCrouchActive = false
    Config.State.AutoCrouchKiller = nil
end
local function TriggerCrouchStart()
    if Config.State.AutoCrouchActive then return end
    local char = LocalPlayer.Character
    if not char then return end
    Config.State.AutoCrouchActive = true
    local hum = char:FindFirstChildOfClass("Humanoid")
    Config.State.AutoCrouchOriginals = {
        char = char,
        Crouching = char:GetAttribute("Crouching"),
        CrouchingServer = char:GetAttribute("Crouchingserver"),
        IsRunning = char:GetAttribute("IsRunning"),
        WalkSpeed = hum and hum.WalkSpeed or nil,
    }
    pcall(function()
        char:SetAttribute("Crouching", true)
        char:SetAttribute("Crouchingserver", true)
        char:SetAttribute("IsRunning", false)
        if hum then
            hum.WalkSpeed = Config.Auto.AutoCrouch.WalkSpeed or 6
        end
    end)
end
local function hookKillerForAutoCrouch(p, char)
    if not p or not char then return end
    if p == LocalPlayer then return end
    if not p.Team or p.Team.Name ~= "Killer" then return end
    local cache = Config.State._autoCrouchAnims
    if not cache then return end
    if cache[char] then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then
        task.spawn(function()
            local h = char:WaitForChild("Humanoid", 5)
            if not h or Config.State.unloaded then return end
            if not Config.Auto.AutoCrouch.Enabled then return end
            hookKillerForAutoCrouch(p, char)
        end)
        return
    end
    local animator = hum:FindFirstChildOfClass("Animator")
    if not animator then
        task.spawn(function()
            local a = hum:WaitForChild("Animator", 5)
            if not a or Config.State.unloaded then return end
            if not Config.Auto.AutoCrouch.Enabled then return end
            hookKillerForAutoCrouch(p, char)
        end)
        return
    end
    local entry = { tracks = {} }
    entry.conn = animator.AnimationPlayed:Connect(function(track)
        local anim = track.Animation
        if not anim then return end
        if not (p.Team and p.Team.Name == "Killer") then return end
        local targetId = Config.Auto.AutoCrouch.AnimId
        if anim.AnimationId ~= targetId then return end
        if not Config.Auto.AutoCrouch.Enabled then return end
        if not Fn.isSurvivorTeam() then return end
        if Fn.isDowned(LocalPlayer.Character) then return end
        local myRoot = Fn.getRoot()
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not myRoot or not hrp then return end
        local dist = (hrp.Position - myRoot.Position).Magnitude
        local detectDist = Config.Auto.AutoCrouch.DetectDistance or 15
        if dist > detectDist then return end
        TriggerCrouchStart()
        Config.State.AutoCrouchKiller = p
        if entry.tracks[track] then return end
        local stopConn
        stopConn = track.Stopped:Connect(function()
            if stopConn then
                pcall(function() stopConn:Disconnect() end)
                stopConn = nil
            end
            entry.tracks[track] = nil
            TriggerCrouchStop()
        end)
        entry.tracks[track] = stopConn
    end)
    cache[char] = entry
    entry.ancestryConn = char.AncestryChanged:Connect(function(_, parent)
        if parent then return end
        if Config.State.AutoCrouchKiller == p then
            Fn.safeCall("AutoCrouch Restore", function() TriggerCrouchStop() end)
        end
        if entry.conn then
            pcall(function() entry.conn:Disconnect() end)
            entry.conn = nil
        end
        if entry.ancestryConn then
            pcall(function() entry.ancestryConn:Disconnect() end)
            entry.ancestryConn = nil
        end
        for _, sc in pairs(entry.tracks) do
            pcall(function() sc:Disconnect() end)
        end
        entry.tracks = {}
        cache[char] = nil
    end)
end
function Fn.startAutoCrouch()
    if Config.State._autoCrouchPlayerAddedConn then return end
    Config.State._autoCrouchAnims     = Config.State._autoCrouchAnims     or {}
    Config.State._autoCrouchCharConns = Config.State._autoCrouchCharConns or {}
    for _, p in ipairs(Config.ESPCache.PlayerList) do
        if p ~= LocalPlayer then
            if p.Character then
                hookKillerForAutoCrouch(p, p.Character)
            end
            Config.State._autoCrouchCharConns[p] = p.CharacterAdded:Connect(function(newChar)
                task.spawn(function()
                    local hum = newChar:WaitForChild("Humanoid", 5)
                    if not hum or Config.State.unloaded then return end
                    if not Config.Auto.AutoCrouch.Enabled then return end
                    hookKillerForAutoCrouch(p, newChar)
                end)
            end)
        end
    end
    Config.State._autoCrouchPlayerAddedConn = Players.PlayerAdded:Connect(function(p)
        Config.State._autoCrouchCharConns[p] = p.CharacterAdded:Connect(function(newChar)
            task.spawn(function()
                local hum = newChar:WaitForChild("Humanoid", 5)
                if not hum or Config.State.unloaded then return end
                if not Config.Auto.AutoCrouch.Enabled then return end
                hookKillerForAutoCrouch(p, newChar)
            end)
        end)
        if p.Character then
            hookKillerForAutoCrouch(p, p.Character)
        end
    end)
end
function Fn.stopAutoCrouch()
    if not Config.State._autoCrouchPlayerAddedConn
        and not next(Config.State._autoCrouchCharConns or {})
        and not next(Config.State._autoCrouchAnims or {}) then
        TriggerCrouchStop()
        return
    end
    if Config.State._autoCrouchPlayerAddedConn then
        pcall(function() Config.State._autoCrouchPlayerAddedConn:Disconnect() end)
        Config.State._autoCrouchPlayerAddedConn = nil
    end
    for p, conn in pairs(Config.State._autoCrouchCharConns or {}) do
        pcall(function() conn:Disconnect() end)
        Config.State._autoCrouchCharConns[p] = nil
    end
    for char, entry in pairs(Config.State._autoCrouchAnims or {}) do
        if entry.conn then
            pcall(function() entry.conn:Disconnect() end)
        end
        if entry.ancestryConn then
            pcall(function() entry.ancestryConn:Disconnect() end)
        end
        for _, sc in pairs(entry.tracks or {}) do
            pcall(function() sc:Disconnect() end)
        end
        Config.State._autoCrouchAnims[char] = nil
    end
    TriggerCrouchStop()
end
Config.Connections.AutoCrouchSpeedEnforce = Config.FakeConnection(Config.HeartbeatTasks, "AutoCrouchSpeed", function()
    if not Config.State.AutoCrouchActive then return end
    if Config.State.unloaded then return end
    local orig = Config.State.AutoCrouchOriginals
    if not orig then return end
    local now = fast_tick()
    if now - (Config.State._autoCrouchSpeedLast or 0) < 0.1 then return end
    Config.State._autoCrouchSpeedLast = now
    local char = orig.char
    if not char or not char.Parent then return end
    if LocalPlayer.Character ~= char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    if orig.WalkSpeed == nil then orig.WalkSpeed = hum.WalkSpeed end
    local target = Config.Auto.AutoCrouch.WalkSpeed or 6
    if hum.WalkSpeed ~= target then
        hum.WalkSpeed = target
    end
end)

-- Export untuk handler CharacterRemoving di main
Fn.TriggerCrouchStop = TriggerCrouchStop
--------------------------- UI builder ------------------------------
UI.AbilityTab:AddToggle("AutoCrouchToggle", { Text = "Auto Crouch", Default = false,
    Callback = function(v)
        Config.Auto.AutoCrouch.Enabled = v
        if v then Fn.startAutoCrouch() else Fn.stopAutoCrouch() end
    end }):AddKeyPicker("AutoCrouchToggle_Keybind", { Default = "None", Mode = "Toggle", SyncToggleState = true })
UI.AbilityTab:AddSlider("AutoCrouchDist", {
    Text = "Detect Distance",
    Default = Config.Auto.AutoCrouch.DetectDistance,
    Min = 5, Max = 80, Rounding = 0,
    Callback = function(v) Config.Auto.AutoCrouch.DetectDistance = v end
})
UI.AbilityTab:AddSlider("AutoCrouchSpeed", {
    Text = "Crouch WalkSpeed",
    Default = Config.Auto.AutoCrouch.WalkSpeed,
    Min = 2, Max = 16, Rounding = 0,
    Callback = function(v) Config.Auto.AutoCrouch.WalkSpeed = v end
})

    M.Unload = function()
        pcall(function() Fn.stopAutoCrouch() end)
        if Config.Connections.AutoCrouchSpeedEnforce then
            pcall(function() Config.Connections.AutoCrouchSpeedEnforce:Disconnect() end)
            Config.Connections.AutoCrouchSpeedEnforce = nil
        end
    end
    return M
end

return M
