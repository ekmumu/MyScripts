-- ==========================================
-- MUMU RIVALS - 視角身體同步 + 拖曳 UI 版
-- ==========================================

local Settings = {
    ESP = true,
    Aimbot = true,
    FOV = 180,           
    Prediction = 0.14,    
    Smoothness = 0.1,    
    TeamCheck = false
}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- [[ 超大字體 UI 建立 ]]
local SafeGui = (gethui and gethui()) or game:GetService("CoreGui")
if SafeGui:FindFirstChild("MUMU_Draggable") then SafeGui.MUMU_Draggable:Destroy() end

local ScreenGui = Instance.new("ScreenGui", SafeGui)
ScreenGui.Name = "MUMU_Draggable"
ScreenGui.ResetOnSpawn = false

local Main = Instance.new("Frame", ScreenGui)
Main.Size = UDim2.fromOffset(300, 300)
Main.Position = UDim2.fromScale(0.5, 0.5)
Main.AnchorPoint = Vector2.new(0.5, 0.5)
Main.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
Main.Active = true -- 必須開啟才能拖曳
Main.Draggable = false -- 我們用自定義腳本替代原生拖曳，更穩
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 15)
Instance.new("UIStroke", Main).Thickness = 4

local Title = Instance.new("TextLabel", Main)
Title.Size = UDim2.new(1, 0, 0, 80)
Title.Text = "⚡ MUMU SYNC"
Title.TextSize = 35
Title.Font = Enum.Font.GothamBlack
Title.TextColor3 = Color3.new(1, 1, 1)
Title.BackgroundTransparency = 1

local Container = Instance.new("Frame", Main)
Container.Size = UDim2.new(0.9, 0, 0.6, 0)
Container.Position = UDim2.fromScale(0.05, 0.25)
Container.BackgroundTransparency = 1
Instance.new("UIListLayout", Container).Padding = UDim.new(0, 20)

-- [[ 1. 絲滑拖曳邏輯 ]]
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

-- [[ 2. 功能切換 ]]
local function AddToggle(name, default, callback)
    local state = default
    local btn = Instance.new("TextButton", Container)
    btn.Size = UDim2.new(1, 0, 0, 65)
    btn.BackgroundColor3 = state and Color3.fromRGB(200, 0, 0) or Color3.fromRGB(40, 40, 40)
    btn.Text = name .. ": " .. (state and "ON" or "OFF")
    btn.TextSize = 22
    btn.TextColor3 = Color3.new(1, 1, 1)
    btn.Font = Enum.Font.GothamBold
    Instance.new("UICorner", btn)
    btn.MouseButton1Click:Connect(function()
        state = not state
        btn.BackgroundColor3 = state and Color3.fromRGB(200, 0, 0) or Color3.fromRGB(40, 40, 40)
        btn.Text = name .. ": " .. (state and "ON" or "OFF")
        callback(state)
    end)
end

AddToggle("ESP 透視", Settings.ESP, function(v) Settings.ESP = v end)
AddToggle("AIM 同步鎖頭", Settings.Aimbot, function(v) Settings.Aimbot = v end)

-- [[ 3. 核心鎖頭與同步 ]]
local function GetTarget()
    local target, maxDist = nil, Settings.FOV
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("Head") then
            if Settings.TeamCheck and p.Team == LocalPlayer.Team then continue end
            local hum = p.Character:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health > 0 then
                local pos, onScreen = Camera:WorldToViewportPoint(p.Character.Head.Position)
                if onScreen then
                    local dist = (Vector2.new(pos.X, pos.Y) - UserInputService:GetMouseLocation()).Magnitude
                    if dist < maxDist then maxDist = dist target = p.Character end
                end
            end
        end
    end
    return target
end

RunService.RenderStepped:Connect(function()
    -- ESP
    if Settings.ESP then
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character and not p.Character:FindFirstChild("MUMU_H") then
                Instance.new("Highlight", p.Character).Name = "MUMU_H"
            end
        end
    end

    -- 鎖頭 (同步相機與身體)
    if Settings.Aimbot and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
        local target = GetTarget()
        if target and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            local targetPos = target.Head.Position + (target.HumanoidRootPart.Velocity * Settings.Prediction)
            
            -- 鎖相機
            Camera.CFrame = Camera.CFrame:Lerp(CFrame.lookAt(Camera.CFrame.Position, targetPos), Settings.Smoothness)
            
            -- 鎖身體 (讓槍口指過去)
            local hrp = LocalPlayer.Character.HumanoidRootPart
            local newBodyLook = CFrame.new(hrp.Position, Vector3.new(targetPos.X, hrp.Position.Y, targetPos.Z))
            hrp.CFrame = hrp.CFrame:Lerp(newBodyLook, Settings.Smoothness)
        end
    end
end)

-- J 鍵顯示/隱藏
UserInputService.InputBegan:Connect(function(i, g)
    if not g and i.KeyCode == Enum.KeyCode.J then Main.Visible = not Main.Visible end
end)
