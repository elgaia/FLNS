
local M = {}

function M.Mount(env)
    env = env or {}
    local Config      = assert(env.Config, "[EmotePlayer] env.Config is required")
    local Fn          = assert(env.Fn, "[EmotePlayer] env.Fn is required")
    assert(env.UI and env.UI.EmoteBox, "[EmotePlayer] env.UI.EmoteBox is required")
    local UI          = env.UI
    local LocalPlayer = env.LocalPlayer or game:GetService("Players").LocalPlayer


function Fn.stopEmote()
    if Config.State.CurrentEmoteTrack then
        Config.State.CurrentEmoteTrack:Stop()
        Config.State.CurrentEmoteTrack:Destroy()
        Config.State.CurrentEmoteTrack = nil
    end
    if Config.State.CurrentEmoteSound then
        Config.State.CurrentEmoteSound:Stop()
        Config.State.CurrentEmoteSound:Destroy()
        Config.State.CurrentEmoteSound = nil
    end
end
function Fn.playEmote(name)
    Fn.stopEmote()
    local data = Config.EmoteData[name]
    if not data then return end
    local char = LocalPlayer.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hum or not hrp then return end
    local animator = hum:FindFirstChildOfClass("Animator") or Instance.new("Animator", hum)
    if data.anim then
        local anim = Instance.new("Animation")
        anim.AnimationId = data.anim
        Config.State.CurrentEmoteTrack = animator:LoadAnimation(anim)
        Config.State.CurrentEmoteTrack.Priority = Enum.AnimationPriority.Action
        Config.State.CurrentEmoteTrack:Play()
    end
    if data.sound and data.sound ~= "" and data.sound ~= "rbxassetid://0" then
        Config.State.CurrentEmoteSound = Instance.new("Sound")
        Config.State.CurrentEmoteSound.SoundId = data.sound
        Config.State.CurrentEmoteSound.Volume = 1
        Config.State.CurrentEmoteSound.Looped = true
        Config.State.CurrentEmoteSound.Parent = hrp
        Config.State.CurrentEmoteSound:Play()
    end
end

function Fn.createEmoteButton()
    if Config.EmoteButton.GuiInstance then Config.EmoteButton.GuiInstance:Destroy() end
    local gui, btn, stroke = Fn.createGameButton({
        Name       = "EmoteButtonGui",
        ButtonType = "ImageButton",
        Size       = UDim2.new(0, 50, 0, 50),
        Position   = UDim2.new(0.60, 0, 0.75, 0),
        Image      = "rbxassetid://96917710911699",
        OnClick = function(stroke)
            Fn.playEmote(Config.EmoteButton.Selected)
            stroke.Color = Color3.fromRGB(90, 120, 210)
            task.delay(0.3, function() stroke.Color = Color3.fromRGB(255, 255, 255) end)
        end,
    })
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0, 80, 0, 20)
    label.Position = UDim2.new(0.5, -40, -0.6, 0)
    label.BackgroundTransparency = 1
    label.Text = Config.EmoteButton.Selected
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.TextStrokeTransparency = 0.5
    label.Font = Enum.Font.GothamBold
    label.TextSize = 11
    label.Parent = btn
    Config.EmoteButton.GuiInstance = gui
    Config.EmoteButton.LabelRef    = label
end
function Fn.removeEmoteButton()
    if Config.EmoteButton.GuiInstance then Config.EmoteButton.GuiInstance:Destroy(); Config.EmoteButton.GuiInstance = nil; Config.EmoteButton.LabelRef = nil end
end

UI.EmoteBox:AddDropdown("SelectEmote", { Values = Config.EmoteButton.List, Default = 1, Multi = false, Text = "Select Emote",
    Callback = function(v)
        Config.EmoteButton.Selected = v
        if Config.EmoteButton.LabelRef then Config.EmoteButton.LabelRef.Text = v end
    end })
UI.EmoteBox:AddButton({ Text = "Play Emote", Func = function() Fn.playEmote(Config.EmoteButton.Selected) end })
UI.EmoteBox:AddButton({ Text = "Stop Emote", Func = function() Fn.stopEmote() end })
UI.EmoteBox:AddToggle("ShowEmoteButton", { Text = "Show Emote Button", Default = false,
    Callback = function(v)
        Config.EmoteButton.Show = v
        if v then Fn.createEmoteButton() else Fn.removeEmoteButton() end
    end }):AddKeyPicker("ShowEmoteButton_Keybind", { Default = "None", Mode = "Toggle", SyncToggleState = true })

    M.Unload = function()
        pcall(function()
            Fn.stopEmote()
            Fn.removeEmoteButton()
        end)
    end
    return M
end

return M
