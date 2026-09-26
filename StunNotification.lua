
local M = {}

function M.Mount(env)
    env = env or {}
    local Config      = assert(env.Config, "[StunNotification] env.Config is required")
    local Fn          = assert(env.Fn, "[StunNotification] env.Fn is required")
    assert(env.UI and env.UI.AbilityTab, "[StunNotification] env.UI.AbilityTab is required")
    local UI          = env.UI
    local LocalPlayer = env.LocalPlayer or game:GetService("Players").LocalPlayer

function Fn.PlayStunMusic()
    if not Config.StunNotification._sound then
        local sound = Instance.new("Sound")
        sound.SoundId = Config.StunNotification.MusicId
        sound.Looped = true
        sound.Volume = 1
        sound.Parent = workspace
        Config.StunNotification._sound = sound
    end
    pcall(function() Config.StunNotification._sound:Play() end)
end
function Fn.StopStunMusic()
    if Config.StunNotification._sound then
        pcall(function() Config.StunNotification._sound:Stop() end)
    end
end
function Fn.DestroyStunMusic()
    if Config.StunNotification._sound then
        pcall(function() Config.StunNotification._sound:Destroy() end)
        Config.StunNotification._sound = nil
    end
end
function Fn.ShowStunSticker(char)
    if Config.StunNotification._billboard then
        Fn.HideStunSticker()
    end
    local head = char and char:FindFirstChild("Head")
    if not head then return end
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "StunSticker"
    billboard.Size = UDim2.new(0, 56, 0, 56)
    billboard.AlwaysOnTop = true
    billboard.LightInfluence = 0
    billboard.MaxDistance = 200
    billboard.Adornee = head
    billboard.StudsOffset = Vector3.new(0, 2.6, 0)
    billboard.Parent = char
    local imageLabel = Instance.new("ImageLabel")
    imageLabel.Size = UDim2.new(1, 0, 1, 0)
    imageLabel.BackgroundTransparency = 1
    imageLabel.Image = Config.StunNotification.StickerId
    imageLabel.ScaleType = Enum.ScaleType.Fit
    imageLabel.Parent = billboard
    Config.StunNotification._billboard = billboard
end
function Fn.HideStunSticker()
    if Config.StunNotification._billboard then
        pcall(function() Config.StunNotification._billboard:Destroy() end)
        Config.StunNotification._billboard = nil
    end
end
function Fn.UpdateStunNotification()
    if not Config.StunNotification.Enabled then
        if Config.StunNotification._wasStunned then
            Fn.StopStunMusic()
            Fn.HideStunSticker()
            Config.StunNotification._wasStunned = false
            Config.StunNotification._lastKillerChar = nil
        end
        return
    end
    local killerChar = nil
    local playerList = Config.ESPCache.PlayerList
    for i = 1, #playerList do
        local p = playerList[i]
        if p.Team and p.Team.Name == "Killer" and p.Character then
            killerChar = p.Character
            break
        end
    end
    if not killerChar then
        if Config.StunNotification._wasStunned then
            Fn.StopStunMusic()
            Fn.HideStunSticker()
            Config.StunNotification._wasStunned = false
            Config.StunNotification._lastKillerChar = nil
        end
        return
    end
    local isStunned = killerChar:GetAttribute("IsStunned") == true
    if isStunned and not Config.StunNotification._wasStunned then
        Fn.PlayStunMusic()
        Fn.ShowStunSticker(killerChar)
        Config.StunNotification._wasStunned = true
        Config.StunNotification._lastKillerChar = killerChar
    elseif not isStunned and Config.StunNotification._wasStunned then
        Fn.StopStunMusic()
        Fn.HideStunSticker()
        Config.StunNotification._wasStunned = false
        Config.StunNotification._lastKillerChar = nil
    elseif isStunned and Config.StunNotification._wasStunned then
        if Config.StunNotification._lastKillerChar ~= killerChar then
            Fn.HideStunSticker()
            Fn.ShowStunSticker(killerChar)
            Config.StunNotification._lastKillerChar = killerChar
        end
    end
end
function Fn.CleanupStunNotification()
    Fn.StopStunMusic()
    Fn.DestroyStunMusic()
    Fn.HideStunSticker()
    Config.StunNotification._wasStunned = false
    Config.StunNotification._lastKillerChar = nil
end

UI.AbilityTab:AddToggle("StunNotificationToggle", { Text = "Stun Notification",
    Default = false,
    Callback = function(v)
        Config.StunNotification.Enabled = v
        if not v then
            Fn.StopStunMusic()
            Fn.HideStunSticker()
            Config.StunNotification._wasStunned = false
            Config.StunNotification._lastKillerChar = nil
        end
    end }):AddKeyPicker("StunNotificationToggle_Keybind", { Default = "None", Mode = "Toggle", SyncToggleState = true })

    M.Unload = function()
        pcall(function() Fn.CleanupStunNotification() end)
    end
    return M
end

return M
