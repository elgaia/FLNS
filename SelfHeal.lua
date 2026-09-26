local M = {}

function M.Mount(env)
    env = env or {}
    local Config      = assert(env.Config, "[SelfHeal] env.Config is required")
    local Fn          = assert(env.Fn, "[SelfHeal] env.Fn is required")
    assert(env.UI and env.UI.AbilityTab, "[SelfHeal] env.UI.AbilityTab is required")
    local UI          = env.UI
    local LocalPlayer = env.LocalPlayer or game:GetService("Players").LocalPlayer
    local Remotes = assert(env.Remotes, "[SelfHeal] env.Remotes is required")

local function suppressHealingAnimation()
    if Config.State._selfHealAnimListener then return end
    local character = LocalPlayer.Character
    if not character then return end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end
    local animator = humanoid:FindFirstChildOfClass("Animator")
    if not animator then return end

    Config.State._selfHealAnimListener = animator.AnimationPlayed:Connect(function(activeTrack)
        if activeTrack.Animation and activeTrack.Animation.AnimationId:find("95836365038528") then
            activeTrack:Stop(0)
        end
    end)
end

local function restoreHealingAnimation()
    if Config.State._selfHealAnimListener then
        pcall(function() Config.State._selfHealAnimListener:Disconnect() end)
        Config.State._selfHealAnimListener = nil
    end
end

function Fn.startSelfHeal()
    Config.Auto.SelfHeal.Enabled = true
    suppressHealingAnimation()
    if Config.State._selfHealStarted then return end
    Config.State._selfHealStarted = true

    task.spawn(function()
        while not Config.State.unloaded do
            task.wait(3)
            if Config.Auto.SelfHeal.Enabled and not Config.State.unloaded then
                local team = LocalPlayer.Team
                if team and team.Name ~= "Killer" then
                    local character = LocalPlayer.Character
                    if character then
                        local interactState = character:FindFirstChild("CheckInterractable")
                        local rootPart = character:FindFirstChild("HumanoidRootPart")
                        local humanoid = character:FindFirstChildOfClass("Humanoid")

                        local isBusy = false
                        if interactState then
                            if interactState:GetAttribute("isVaulting")
                            or interactState:GetAttribute("isRepairing")
                            or interactState:GetAttribute("isUnhooking")
                            or interactState:GetAttribute("isHealing")
                            or interactState:GetAttribute("isSliding") then
                                isBusy = true
                            end
                        end

                        if not isBusy and rootPart and humanoid and humanoid.Health < humanoid.MaxHealth then
                            pcall(function()
                                local healingFolder = Remotes:FindFirstChild("Healing")
                                if healingFolder and healingFolder:FindFirstChild("HealEvent") then
                                    healingFolder.HealEvent:FireServer(rootPart, true)
                                end
                            end)
                        end
                    end
                end
            end
        end
    end)

    Config.State._selfHealCharRemoving = LocalPlayer.CharacterRemoving:Connect(function()
        restoreHealingAnimation()
    end)
    Config.State._selfHealCharAdded = LocalPlayer.CharacterAdded:Connect(function()
        task.wait(5)
        if Config.Auto.SelfHeal.Enabled and not Config.State.unloaded then
            suppressHealingAnimation()
        end
    end)
end

function Fn.stopSelfHeal()
    Config.Auto.SelfHeal.Enabled = false
    restoreHealingAnimation()
end

function Fn.teardownSelfHeal()
    Fn.stopSelfHeal()
    if Config.State._selfHealCharAdded then
        pcall(function() Config.State._selfHealCharAdded:Disconnect() end)
        Config.State._selfHealCharAdded = nil
    end
    if Config.State._selfHealCharRemoving then
        pcall(function() Config.State._selfHealCharRemoving:Disconnect() end)
        Config.State._selfHealCharRemoving = nil
    end
    Config.State._selfHealStarted = nil
end
--------------------------- UI builder ------------------------------
UI.AbilityTab:AddToggle("SelfHealToggle", { Text = "Self Heal (Auto)",
    Default = false,
    Callback = function(v)
        if v then Fn.startSelfHeal() else Fn.stopSelfHeal() end
    end }):AddKeyPicker("SelfHealToggle_Keybind", { Default = "None", Mode = "Toggle", SyncToggleState = true })

    M.Unload = function()
        pcall(function() Fn.teardownSelfHeal() end)
    end
    return M
end

return M
