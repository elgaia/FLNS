
local M = {}

function M.Mount(env)
    env = env or {}
    local Config      = assert(env.Config, "[GenBoost] env.Config is required")
    local Fn          = assert(env.Fn, "[GenBoost] env.Fn is required")
    assert(env.UI and env.UI.AbilityTab, "[GenBoost] env.UI.AbilityTab is required")
    local UI          = env.UI
    local LocalPlayer = env.LocalPlayer or game:GetService("Players").LocalPlayer
    local Remotes     = assert(env.Remotes, "[GenBoost] env.Remotes is required")
    local fast_tick   = env.fast_tick or tick

local CollectionService = game:GetService("CollectionService")
local function gbResolvePerfRemote()
    local perksFolder = Remotes:FindFirstChild("Perks")
    return perksFolder and perksFolder:FindFirstChild("perfectionistplanning")
end
local function gbResolveRepairAnimRemote()
    local generatorFolder = Remotes:FindFirstChild("Generator")
    return generatorFolder and generatorFolder:FindFirstChild("RepairAnim")
end
local gbListenerAttached = false
local function gbAttachListener()
    if gbListenerAttached or Config.State.unloaded then return end
    local RepairAnimRemote = gbResolveRepairAnimRemote()
    if not RepairAnimRemote then return end
    gbListenerAttached = true
    Config.Connections.GenBoostListener = RepairAnimRemote.OnClientEvent:Connect(function(plr, isRepairing, targetPart)
        if not Config.Auto.GenBoost.Enabled then return end
        if typeof(plr) == "Instance" and plr:IsA("Player") and plr ~= LocalPlayer then return end
        if isRepairing and targetPart and targetPart.Parent then
            local PerfPlanningRemote = gbResolvePerfRemote()
            if not PerfPlanningRemote then return end
            Fn.safeCall("GenBoost Apply", function()
                PerfPlanningRemote:FireServer("applyBoost", "fast")
            end)
            if fast_tick() > Config.Auto.GenBoost.LastBroadcast then
                Config.Auto.GenBoost.LastBroadcast = fast_tick() + 55
                local allGens = {}
                for _, gen in ipairs(CollectionService:GetTagged("Generator")) do
                    if gen:IsDescendantOf(workspace) then
                        local genModel = (gen:IsA("Model") and gen) or gen.Parent
                        table.insert(allGens, genModel)
                    end
                end
                Fn.safeCall("GenBoost Broadcast", function()
                    PerfPlanningRemote:FireServer("broadcast", allGens)
                end)
            end
        else
            local PerfPlanningRemote = gbResolvePerfRemote()
            if PerfPlanningRemote then
                Fn.safeCall("GenBoost Clear", function()
                    PerfPlanningRemote:FireServer("clearBoost")
                end)
            end
        end
    end)
end
gbAttachListener()
local gbRetryNext = 0
Config.Connections.GenBoostRetry = Config.FakeConnection(Config.HeartbeatTasks, "GenBoostRetry", function()
    if gbListenerAttached or Config.State.unloaded then return end
    local now = fast_tick()
    if now < gbRetryNext then return end
    gbRetryNext = now + 5
    gbAttachListener()
end)

function Fn.ClearGenBoost()
    local PerfPlanningRemote = gbResolvePerfRemote()
    if PerfPlanningRemote then
        PerfPlanningRemote:FireServer("clearBoost")
    end
end

UI.AbilityTab:AddToggle("GenBoostToggle", { Text = "Bypass PerksPerfectionist",
    Default = false,
    Callback = function(Value)
        Config.Auto.GenBoost.Enabled = Value
        if not Value then
            local perksFolder = Remotes:FindFirstChild("Perks")
            local perfRemote = perksFolder and perksFolder:FindFirstChild("perfectionistplanning")
            if perfRemote then
                Fn.safeCall("GenBoost Clear", function() perfRemote:FireServer("clearBoost") end)
            end
        end
    end }):AddKeyPicker("GenBoostToggle_Keybind", { Default = "None", Mode = "Toggle", SyncToggleState = true })

    M.Unload = function()
        if Config.Connections.GenBoostListener then
            pcall(function() Config.Connections.GenBoostListener:Disconnect() end)
            Config.Connections.GenBoostListener = nil
        end
        if Config.Connections.GenBoostRetry then
            pcall(function() Config.Connections.GenBoostRetry:Disconnect() end)
            Config.Connections.GenBoostRetry = nil
        end
    end
    return M
end

return M
