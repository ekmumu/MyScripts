-- ==========================================
-- MUMU RIVALS - 修正 J 鍵與拖曳功能
-- ==========================================

local Settings = {
    ESP = true,
    SmoothAim = true,    
    SnapLock = true,     
    SilentAim = true,    
    FOV = 200,
    MaxDistance = 300,
    SmoothValue = 0.08,  
    Prediction = 0.15,
    WallCheck = true
}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- [[ UI 建立 ]]
local SafeGui = (gethui and gethui()) or game:GetService("CoreGui")
if SafeGui:FindFirstChild("MUMU_REFIX") then SafeGui.MUMU_REFIX:Destroy() end
local ScreenGui = Instance.new("ScreenGui", SafeGui)
ScreenGui.Name = "MUMU_REFIX"

local Main = Instance.new("Frame", ScreenGui)
Main.Size = UDim2.fromOffset(380, 520)
Main.Position = UDim2.fromScale(0.5, 0.4) -- 初始位置偏上一點
Main.AnchorPoint = Vector2.new(0.5, 0.5)
Main.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
Main.Active = true -- 必須開啟以支援拖曳
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 15)
local Stroke = Instance.new("UIStroke", Main)
Stroke.Thickness = 4
Stroke.Color = Color3.fromRGB(255, 50, 50)

local Title = Instance.new("TextLabel", Main)
Title.Size = UDim2.new(1, 0, 0, 70)
Title.Text = "⚡ MUMU ULTRA V7.1"
Title.TextSize = 30
Title.Font = Enum.Font.GothamBlack
Title.TextColor3 = Color3.new(1, 1, 1)
Title.BackgroundTransparency = 1

local Container = Instance.new("Frame", Main)
Container.Size = UDim2.new(0.9, 0, 0.8, 0)
Container.Position = UDim2.fromScale(0.05, 0.15)
Container.BackgroundTransparency = 1
Instance.new("UIListLayout", Container).Padding = UDim.new(0, 10)

-- [[ 1. 補回：流暢拖曳腳本 ]]
local dragging, dragInput, dragStart, startPos
local function update(input)
    local delta = input.Position - dragStart
    Main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
end

Main.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = Main.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then dragging = false end
        end)
    end
end)

Main.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement then dragInput = input end
end)

UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then update(input) end
end)

-- [[ 2. 補回：J 鍵隱藏功能 ]]
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if not gameProcessed and input.KeyCode == Enum.KeyCode.J then
        Main.Visible = not Main.Visible
    end
end)

-- [[ 按鈕生成器 ]]
local function AddToggle(name, default, callback)
    local state = default
    local btn = Instance.new("TextButton", Container)
    btn.Size = UDim2.new(1, 0, 0, 55)
    btn.BackgroundColor3 = state and Color3.fromRGB(255, 50, 50) or Color3.fromRGB(40, 40, 40)
    btn.Text = "  " .. name .. ": " .. (state and "ON" or "OFF")
    btn.TextSize = 22 -- 確保字體超大
    btn.Font = Enum.Font.GothamBold
    btn.TextColor3 = Color3.new(1, 1, 1)
    btn.TextXAlignment = Enum.TextXAlignment.Left
    Instance.new("UICorner", btn)
    
    btn.MouseButton1Click:Connect(function()
        state = not state
        btn.BackgroundColor3 = state and Color3.fromRGB(255, 50, 50) or Color3.fromRGB(40, 40, 40)
        btn.Text = "  " .. name .. ": " .. (state and "ON" or "OFF")
        callback(state)
    end)
end

AddToggle("ESP 框框透視", Settings.ESP, function(v) Settings.ESP = v end)
AddToggle("右鍵絲滑瞄準", Settings.SmoothAim, function(v) Settings.SmoothAim = v end)
AddToggle("射擊瞬間鎖頭", Settings.SnapLock, function(v) Settings.SnapLock = v end)
AddToggle("子彈轉彎吸附", Settings.SilentAim, function(v) Settings.SilentAim = v end)
AddToggle("隔牆檢查", Settings.WallCheck, function(v) Settings.WallCheck = v end)

-- [[ 核心邏輯 (Silent Aim & Aimbot) ]]
local function GetTarget()
    local target, maxDist = nil, Settings.FOV
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("Head") and p.Character.Humanoid.Health > 0 then
            local dist = (LocalPlayer.Character.HumanoidRootPart.Position - p.Character.HumanoidRootPart.Position).Magnitude
            if dist > Settings.MaxDistance then continue end
            local pos, onScreen = Camera:WorldToViewportPoint(p.Character.Head.Position)
            if onScreen then
                local mDist = (Vector2.new(pos.X, pos.Y) - UserInputService:GetMouseLocation()).Magnitude
                if mDist < maxDist then target = p.Character maxDist = mDist end
            end
        end
    end
    return target
end

-- 子彈轉彎攔截
local oldNamecall
oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
    local args = {...}
    local method = getnamecallmethod()
    if Settings.SilentAim and method == "Raycast" and not checkcaller() then
        local t = GetTarget()
        if t then args[2] = (t.Head.Position - args[1]).Unit * 1000 return oldNamecall(self, unpack(args)) end
    end
    return oldNamecall(self, ...)
end)

-- 每一幀更新
RunService.RenderStepped:Connect(function()
    -- ESP
    if Settings.ESP then
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character and not p.Character:FindFirstChild("MUMU_H") then
                Instance.new("Highlight", p.Character).Name = "MUMU_H"
            end
        end
    end

    -- 瞄準
    if UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
        local t = GetTarget()
        if t then
            local targetPos = t.Head.Position + (t.HumanoidRootPart.Velocity * Settings.Prediction)
            local isFiring = UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)
            local strength = (isFiring and Settings.SnapLock) and 1.0 or (Settings.SmoothAim and Settings.SmoothValue or 0)
            
            if strength > 0 then
                Camera.CFrame = Camera.CFrame:Lerp(CFrame.lookAt(Camera.CFrame.Position, targetPos), strength)
                LocalPlayer.Character.HumanoidRootPart.CFrame = LocalPlayer.Character.HumanoidRootPart.CFrame:Lerp(CFrame.new(LocalPlayer.Character.HumanoidRootPart.Position, Vector3.new(targetPos.X, LocalPlayer.Character.HumanoidRootPart.Position.Y, targetPos.Z)), strength)
            end
        end
    end
end)
