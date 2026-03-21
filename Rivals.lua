-- ==========================================
-- MUMU RIVALS - UI 穩定性終極修復版
-- ==========================================

local Settings = {
    ESP = true,
    Aimbot = true,
    Smoothness = 0.1,
    Prediction = 0.15,
    FOV = 250
}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()
local Camera = workspace.CurrentCamera

-- [[ UI 強制重建 ]]
local SafeGui = (gethui and gethui()) or game:GetService("CoreGui")
if SafeGui:FindFirstChild("MUMU_FIXED") then SafeGui.MUMU_FIXED:Destroy() end

local ScreenGui = Instance.new("ScreenGui", SafeGui)
ScreenGui.Name = "MUMU_FIXED"
ScreenGui.IgnoreGuiInset = true -- 忽略上方黑條偏移

local Main = Instance.new("Frame", ScreenGui)
Main.Size = UDim2.fromOffset(320, 420)
Main.Position = UDim2.new(0.5, -160, 0.5, -210) -- 居中
Main.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
Main.BorderSizePixel = 0
Main.Active = true
Main.Draggable = false -- 關閉原生，改用下方手寫

local Corner = Instance.new("UICorner", Main)
Corner.CornerRadius = UDim.new(0, 15)

local Stroke = Instance.new("UIStroke", Main)
Stroke.Thickness = 4
Stroke.Color = Color3.fromRGB(255, 0, 0)

local Title = Instance.new("TextLabel", Main)
Title.Size = UDim2.new(1, 0, 0, 80)
Title.Text = "⚡ MUMU V9"
Title.TextSize = 35
Title.Font = Enum.Font.GothamBlack
Title.TextColor3 = Color3.new(1, 1, 1)
Title.BackgroundTransparency = 1

local Container = Instance.new("Frame", Main)
Container.Size = UDim2.new(0.9, 0, 0.7, 0)
Container.Position = UDim2.fromScale(0.05, 0.22)
Container.BackgroundTransparency = 1
local Layout = Instance.new("UIListLayout", Container)
Layout.Padding = UDim.new(0, 15)

-- [[ 1. 強制拖拽腳本 (不依賴屬性) ]]
local Dragging = false
local DragInput, DragStart, StartPos

Main.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        Dragging = true
        DragStart = input.Position
        StartPos = Main.Position
    end
end)

game:GetService("UserInputService").InputChanged:Connect(function(input)
    if Dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local Delta = input.Position - DragStart
        Main.Position = UDim2.new(StartPos.X.Scale, StartPos.X.Offset + Delta.X, StartPos.Y.Scale, StartPos.Y.Offset + Delta.Y)
    end
end)

game:GetService("UserInputService").InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        Dragging = false
    end
end)

-- [[ 2. 強制 J 鍵開關 (最直接方式) ]]
Mouse.KeyDown:Connect(function(key)
    if key:lower() == "j" then
        Main.Visible = not Main.Visible
    end
end)

-- [[ 3. 按鈕與功能 ]]
local function AddToggle(name, settingKey)
    local btn = Instance.new("TextButton", Container)
    btn.Size = UDim2.new(1, 0, 0, 65)
    btn.BackgroundColor3 = Settings[settingKey] and Color3.fromRGB(200, 0, 0) or Color3.fromRGB(45, 45, 45)
    btn.Text = name .. ": " .. (Settings[settingKey] and "ON" or "OFF")
    btn.TextSize = 22
    btn.Font = Enum.Font.GothamBold
    btn.TextColor3 = Color3.new(1, 1, 1)
    Instance.new("UICorner", btn)
    
    btn.MouseButton1Click:Connect(function()
        Settings[settingKey] = not Settings[settingKey]
        btn.Text = name .. ": " .. (Settings[settingKey] and "ON" or "OFF")
        btn.BackgroundColor3 = Settings[settingKey] and Color3.fromRGB(200, 0, 0) or Color3.fromRGB(45, 45, 45)
    end)
end

AddToggle("ESP (透視)", "ESP")
AddToggle("暴力鎖頭", "Aimbot")

-- [[ 4. 暴力鎖定邏輯 ]]
local function GetClosest()
    local target, maxDist = nil, Settings.FOV
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("Head") and p.Character.Humanoid.Health > 0 then
            local pos, onScreen = Camera:WorldToViewportPoint(p.Character.Head.Position)
            if onScreen then
                local dist = (Vector2.new(pos.X, pos.Y) - Vector2.new(Mouse.X, Mouse.Y)).Magnitude
                if dist < maxDist then maxDist = dist target = p.Character end
            end
        end
    end
    return target
end

RunService.RenderStepped:Connect(function()
    -- ESP
    if Settings.ESP then
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character then
                local h = p.Character:FindFirstChild("MUMU_Highlight") or Instance.new("Highlight", p.Character)
                h.Name = "MUMU_Highlight"
                h.FillColor = Color3.new(1, 0, 0)
                h.FillTransparency = 0.5
            end
        end
    end

    -- 鎖頭
    if Settings.Aimbot and game:GetService("UserInputService"):IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
        local t = GetClosest()
        if t and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            local targetPos = t.Head.Position + (t.HumanoidRootPart.Velocity * Settings.Prediction)
            local isFiring = game:GetService("UserInputService"):IsMouseButtonPressed(Enum.UserInputType.MouseButton1)
            local strength = isFiring and 0.85 or Settings.Smoothness
            
            -- 同步相機
            Camera.CFrame = Camera.CFrame:Lerp(CFrame.lookAt(Camera.CFrame.Position, targetPos), strength)
            -- 同步身體
            local hrp = LocalPlayer.Character.HumanoidRootPart
            hrp.CFrame = hrp.CFrame:Lerp(CFrame.new(hrp.Position, Vector3.new(targetPos.X, hrp.Position.Y, targetPos.Z)), strength)
        end
    end
end)
