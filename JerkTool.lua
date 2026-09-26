
local M = {}

function M.Mount(env)
    env = env or {}
    local Config      = assert(env.Config, "[JerkTool] env.Config is required")
    local Fn          = assert(env.Fn, "[JerkTool] env.Fn is required")
    assert(env.UI and env.UI.FunBox, "[JerkTool] env.UI.FunBox is required")
    local UI          = env.UI
    local LocalPlayer = env.LocalPlayer or game:GetService("Players").LocalPlayer
    local r15         = assert(env.r15, "[JerkTool] env.r15 is required")

function Fn.giveJerkTool(speaker)
    speaker = speaker or LocalPlayer
    local char = speaker.Character
    if not char then return end
    local humanoid = char:FindFirstChildWhichIsA("Humanoid")
    local backpack = speaker:FindFirstChildWhichIsA("Backpack")
    if not humanoid or not backpack then return end
    Config.JerkTool._generation = (Config.JerkTool._generation or 0) + 1
    local myGen = Config.JerkTool._generation
    Config.JerkTool.Active = true
    if Config.JerkTool._charAddedConn then
        pcall(function() Config.JerkTool._charAddedConn:Disconnect() end)
        Config.JerkTool._charAddedConn = nil
    end
    local function cleanupExistingJerkTools(spk)
        local bp = spk:FindFirstChildWhichIsA("Backpack")
        local ch = spk.Character
        for _, cont in ipairs({bp, ch}) do
            if cont then
                for _, item in ipairs(cont:GetChildren()) do
                    if item:IsA("Tool") and (item.Name == "Jerk" or item.Name == "Jerk Off") then
                        pcall(function() item:Destroy() end)
                    end
                end
            end
        end
    end
    cleanupExistingJerkTools(speaker)
    local tool = Instance.new("Tool")
    tool.Name = "Jerk"
    tool.RequiresHandle = false
    tool.Parent = backpack
    local jorkin = false
    local track = nil
    local function stopTomfoolery()
        jorkin = false
        if track then
            pcall(function() track:Stop() end)
            track = nil
        end
    end
    tool.Equipped:Connect(function() jorkin = true end)
    tool.Unequipped:Connect(stopTomfoolery)
    humanoid.Died:Connect(stopTomfoolery)
    Config.JerkTool._charAddedConn = speaker.CharacterAdded:Connect(function(newChar)
        task.wait(0.5)
        if Config.JerkTool.Active and myGen == Config.JerkTool._generation then
            Fn.giveJerkTool(speaker)
        end
    end)
    Config.Threads.JerkToolLoop = task.spawn(function()
        while task.wait() do
            if not Config.JerkTool.Active or myGen ~= Config.JerkTool._generation then
                break
            end
            if not jorkin then continue end
            local ok, err = pcall(function()
                local isR15 = r15(speaker)
                if not isR15 and not track then
                    local anim = Instance.new("Animation")
                    anim.AnimationId = "rbxassetid://72042024"
                    track = humanoid:LoadAnimation(anim)
                elseif isR15 and not track then
                    local anim = Instance.new("Animation")
                    anim.AnimationId = "rbxassetid://698251653"
                    track = humanoid:LoadAnimation(anim)
                end
                if track then
                    track:Play()
                    track:AdjustSpeed(isR15 and 0.7 or 0.65)
                    track.TimePosition = 0.6
                end
            end)
            if not ok then
                warn("[Fallens] JerkTool anim error: " .. tostring(err))
                track = nil
                task.wait(0.3)
            end
            local isR15Now = r15(speaker)
            local threshold = isR15Now and 0.7 or 0.65
            while track and track.TimePosition < threshold do
                if not Config.JerkTool.Active or myGen ~= Config.JerkTool._generation then
                    pcall(function() track:Stop() end)
                    return
                end
                task.wait(0.1)
            end
            if track then
                pcall(function() track:Stop() end)
                track = nil
            end
        end
    end)
end
function Fn.stopJerkTool()
    Config.JerkTool._generation = (Config.JerkTool._generation or 0) + 1
    Config.JerkTool.Active = false
    if Config.JerkTool._charAddedConn then
        pcall(function() Config.JerkTool._charAddedConn:Disconnect() end)
        Config.JerkTool._charAddedConn = nil
    end
    if Config.Threads.JerkToolLoop then
        Fn._destroyConn("JerkToolLoop", Config.Threads.JerkToolLoop)
        Config.Threads.JerkToolLoop = nil
    end
    local backpack = LocalPlayer:FindFirstChildWhichIsA("Backpack")
    local char = LocalPlayer.Character
    for _, cont in ipairs({backpack, char}) do
        if cont then
            for _, item in ipairs(cont:GetChildren()) do
                if item:IsA("Tool") and (item.Name == "Jerk" or item.Name == "Jerk Off") then
                    pcall(function() item:Destroy() end)
                end
            end
        end
    end
end

UI.FunBox:AddButton({ Text = "Give Jerk Tool", Func = function() Fn.giveJerkTool(LocalPlayer) end })
UI.FunBox:AddButton({ Text = "Remove Jerk Tool", Func = function() Fn.stopJerkTool() end })
UI.FunBox:AddDivider()

    M.Unload = function()
        pcall(function()
            Fn.stopJerkTool()
        end)
    end
    return M
end

return M
