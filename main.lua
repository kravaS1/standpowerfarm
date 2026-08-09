loadstring([==[
local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()
WindUI:SetParent(gethui() or game:GetService("CoreGui"))
WindUI:SetNotificationLower(true)

local STATE = STATE or {
    alive = function() return true end,
    onCleanup = function() end,
}

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RS = game:GetService("ReplicatedStorage")

local RemotesFolder = RS:WaitForChild("RemotesFolder")
local ClaimPowerGain = RemotesFolder:WaitForChild("ClaimPowerGain")
local GetAllData = RemotesFolder:WaitForChild("GetAllData")
local Rebirth = RemotesFolder:WaitForChild("Rebirth")

local function getReq(n)
    n = math.max(0, math.floor(n or 0))
    if n <= 0 then return 0 end
    return math.min((n - 1) * 25, 300)
end

local claimDelay = 0.5
local farming = false
local autoRebirth = true
local autoWins = false
local winsPause = 30

local function getData()
    return GetAllData:InvokeServer() or {}
end

local function farmLoop()
    while STATE.alive() and farming do
        pcall(function() ClaimPowerGain:FireServer() end)
        task.wait(claimDelay)
    end
end

local function winsLoop()
    local plates = {}
    local keepIdx = { [1] = true, [2] = true, [3] = true, [4] = true, [13] = true, [14] = true, [21] = true, [22] = true }
    local n = 0
    for _, x in ipairs(workspace:WaitForChild("Wins"):GetChildren()) do
        if x.Name == "Win" then
            n = n + 1
            if keepIdx[n] then
                for _, c in ipairs(x:GetDescendants()) do
                    if c:IsA("BasePart") and c:FindFirstChildOfClass("TouchTransmitter") then
                        table.insert(plates, c)
                    end
                end
            end
        end
    end
    while STATE.alive() and autoWins do
        for i, plate in ipairs(plates) do
            if not (STATE.alive() and autoWins) then break end
            pcall(function()
                local hr = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                if hr then
                    hr.CFrame = CFrame.new(plate.Position + Vector3.new(0, 3, 0))
                end
            end)
            task.wait(winsPause / #plates)
        end
    end
end

local function rebirthLoop()
    while STATE.alive() and autoRebirth do
        pcall(function()
            local data = getData()
            local rebirth = data.Rebirth or 0
            local level = data.Level or 1
            local req = getReq(rebirth + 1)
            if level >= req then
                local ok = Rebirth:InvokeServer()
                if ok then
                    WindUI:Notify({ Title = "Rebirth", Content = "Rebirth " .. tostring(rebirth + 1) .. " completed!", Duration = 3, Icon = "flame" })
                end
            end
        end)
        task.wait(2)
    end
end

local Window = WindUI:CreateWindow({
    Title = "Stand Power Farm",
    Icon = "zap",
    Author = "kravat",
    Folder = "StandPowerFarm",
    Size = UDim2.fromOffset(520, 400),
    Theme = "Dark",
    ToggleKey = Enum.KeyCode.V,
})
Window:SetToggleKey(Enum.KeyCode.V)

local Tab = Window:Tab({ Title = "Farm", Icon = "zap" })

local status = Tab:Toggle({ Title = "Status", Desc = "Power: 0 | Level: 1 | Rebirth: 0", Value = false, Locked = true })
local farmToggle = Tab:Toggle({
    Title = "Auto-Farm",
    Type = "Checkbox",
    Desc = "Claim power continuously",
    Value = false,
    Callback = function(state)
        farming = state
        if state then
            task.spawn(farmLoop)
            WindUI:Notify({ Title = "Auto-Farm", Content = "Started", Duration = 2, Icon = "zap" })
        end
    end,
})
local rebirthToggle = Tab:Toggle({
    Title = "Auto-Rebirth",
    Type = "Checkbox",
    Desc = "Rebirth when level requirement met",
    Value = true,
    Callback = function(state)
        autoRebirth = state
        if state then task.spawn(rebirthLoop) end
    end,
})
local delaySlider = Tab:Slider({
    Title = "Claim Interval (ms)",
    Desc = "Server accepts ~1 claim per 500ms",
    Value = { Min = 300, Max = 2000, Default = 500 },
    Step = 50,
    Callback = function(v)
        claimDelay = v / 1000
    end,
})
local winsToggle = Tab:Toggle({
    Title = "Auto-Wins",
    Type = "Checkbox",
    Desc = "Visit all Win plates on a loop",
    Value = false,
    Callback = function(state)
        autoWins = state
        if state then
            task.spawn(winsLoop)
            WindUI:Notify({ Title = "Auto-Wins", Content = "Started", Duration = 2, Icon = "trophy" })
        end
    end,
})
local winsSlider = Tab:Slider({
    Title = "Wins Loop Duration (s)",
    Desc = "Time for one full plate loop",
    Value = { Min = 15, Max = 120, Default = 30 },
    Step = 5,
    Callback = function(v)
        winsPause = v
    end,
})

task.spawn(function()
    local ok, err = pcall(rebirthLoop)
    if not ok then warn("rebirthLoop: " .. tostring(err)) end
end)

task.spawn(function()
    while STATE.alive() do
        pcall(function()
            local d = getData()
            status:SetDesc("Power: " .. tostring(d.Power or 0) .. " | Level: " .. tostring(d.Level or 1) .. " | Rebirth: " .. tostring(d.Rebirth or 0))
        end)
        task.wait(1)
    end
end)

STATE.onCleanup(function()
    farming = false
    autoRebirth = false
    autoWins = false
end)
]==])()
