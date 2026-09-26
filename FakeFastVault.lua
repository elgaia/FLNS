local M = {}

function M.Mount(env)
    env = env or {}
    local Config      = assert(env.Config, "[FakeFastVault] env.Config is required")
    local Fn          = assert(env.Fn, "[FakeFastVault] env.Fn is required")
    assert(env.UI and env.UI.AbilityTab, "[FakeFastVault] env.UI.AbilityTab is required")
    local UI          = env.UI
    local LocalPlayer = env.LocalPlayer or game:GetService("Players").LocalPlayer


function Fn.applyFakeFastVault()
    if Config.Connections.FakeFastVaultChar then
        Config.Connections.FakeFastVaultChar:Disconnect()
        Config.Connections.FakeFastVaultChar = nil
    end
    if Config.Connections.FakeFastVault then
        Config.Connections.FakeFastVault:Disconnect()
        Config.Connections.FakeFastVault = nil
    end
    if not Config.Movement.FakeFastVault.Enabled then return end
    local WALK_ID   = Config.FakeFastVault.WALK_VAULT_ID
    local RUN_ID    = Config.FakeFastVault.RUN_VAULT_ID
    local SPEED     = Config.FakeFastVault.SPEED
    local RESET_DLY = Config.FakeFastVault.ResetDelay or 2
    local function normalizeAnimId(rawId)
        if type(rawId) ~= "string" then return nil end
        if rawId:sub(1, 13) == "rbxassetid://" then return rawId end
        local id = rawId:match("%d+")
        if id then return "rbxassetid://" .. id end
        return rawId
    end
    local function swapToRunningVault(animator, char, track)
        Fn.safeCall("FakeFastVault Swap", function()
            if char and char.Parent and char:GetAttribute("vaultspeed") ~= SPEED then
                char:SetAttribute("vaultspeed", SPEED)
            end
            pcall(function() track:Stop(0) end)
            local runAnim = Instance.new("Animation")
            runAnim.AnimationId = RUN_ID
            local runTrack = animator:LoadAnimation(runAnim)
            runTrack:Play()
            task.delay(RESET_DLY, function()
                if char and char.Parent
                   and Config.Movement.FakeFastVault.Enabled
                   and char:GetAttribute("vaultspeed") == SPEED then
                    char:SetAttribute("vaultspeed", 1)
                end
            end)
        end)
    end
    local function hookAnimator(animator, char)
        if not animator or not char or not char.Parent then return end
        if Config.Connections.FakeFastVault then
            Config.Connections.FakeFastVault:Disconnect()
        end
        Config.Connections.FakeFastVault = animator.AnimationPlayed:Connect(function(track)
            if not Config.Movement.FakeFastVault.Enabled then return end
            local anim = track and track.Animation
            if not anim then return end
            local fullId = normalizeAnimId(anim.AnimationId)
            if fullId ~= WALK_ID then return end
            swapToRunningVault(animator, char, track)
        end)
    end
    local function hookCharacter(char)
        if not char then return end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hum then
            task.spawn(function()
                local h = char:WaitForChild("Humanoid", 5)
                if h then hookCharacter(char) end
            end)
            return
        end
        local animator = hum:FindFirstChildOfClass("Animator")
        if not animator then
            task.spawn(function()
                local h = char:WaitForChild("Humanoid", 5)
                if h then
                    local an = h:FindFirstChildOfClass("Animator")
                    if an then hookAnimator(an, char) end
                end
            end)
            return
        end
        hookAnimator(animator, char)
    end
    local char = LocalPlayer.Character
    if char then hookCharacter(char) end
    Config.Connections.FakeFastVaultChar = LocalPlayer.CharacterAdded:Connect(function(newChar)
        task.wait(0.5)
        hookCharacter(newChar)
    end)
end
function Fn.disableFakeFastVault()
    if Config.Connections.FakeFastVault then
        Config.Connections.FakeFastVault:Disconnect()
        Config.Connections.FakeFastVault = nil
    end
    if Config.Connections.FakeFastVaultChar then
        Config.Connections.FakeFastVaultChar:Disconnect()
        Config.Connections.FakeFastVaultChar = nil
    end
    local char = LocalPlayer.Character
    if char then
        Fn.safeCall("FakeFastVault Reset", function()
            if char:GetAttribute("vaultspeed") == Config.FakeFastVault.SPEED then
                char:SetAttribute("vaultspeed", 1)
            end
        end)
    end
end
--------------------------- UI builder ------------------------------
UI.AbilityTab:AddToggle("FakeFastVault", { Text = "Fake Fast Vault", Default = false,
    Callback = function(v)
        Config.Movement.FakeFastVault.Enabled = v
        if v then
            Fn.applyFakeFastVault()
        else
            Fn.disableFakeFastVault()
        end
    end }):AddKeyPicker("FakeFastVault_Keybind", { Default = "None", Mode = "Toggle", SyncToggleState = true })

    M.Unload = function()
        pcall(function() Fn.disableFakeFastVault() end)
    end
    return M
end

return M
