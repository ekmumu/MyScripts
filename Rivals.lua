-- ==========================================
-- MUMU RIVALS - 絕對瞬鎖版 (無任何平滑滑動)
-- ==========================================

local Settings = {
    ESP = true,
    Aimbot = true,
    Prediction = 0.16, -- 增加一點預判，打跑動敵人更準
    FOV = 250,
    MaxDistance = 300
}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- [[ 1. UI 與懸浮按鈕建立 ]]
local SafeGui = (gethui and gethui()) or game:GetService("CoreGui")
if SafeGui:FindFirstChild("MUMU_SNAP") then SafeGui.MUMU_SNAP:Destroy() end

local ScreenGui = Instance.new("ScreenGui", SafeGui)
ScreenGui.Name = "MUMU_SNAP"
ScreenGui.ResetOnSpawn = false

local ToggleBtn = Instance.new("TextButton", ScreenGui)
ToggleBtn.Size = UDim2.fromOffset(60, 60)
ToggleBtn.Position = UDim2.new(0, 20, 0.5, -30)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
ToggleBtn.Text = "⚡\nMUMU"
ToggleBtn.TextColor3 = Color3.new(1, 1, 1)
ToggleBtn.Font = Enum.Font.GothamBlack
ToggleBtn.TextSize = 14
ToggleBtn.Active = true
ToggleBtn.Draggable = true
Instance.new("UICorner", ToggleBtn).CornerRadius = UDim.new(1, 0)
Instance.new("UIStroke", ToggleBtn).Thickness = 2

local Main = Instance.new("Frame", ScreenGui)
Main.Size = UDim2.fromOffset(300, 380)
Main.Position = UDim2.new(0, 90, 0.5, -190) 
Main.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
Main.Visible = false
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 15)
Instance.new("UIStroke", Main).Thickness = 3
Instance.new("UIStroke", Main).Color = Color3.fromRGB(255, 0, 0)

local Title = Instance.new("TextLabel", Main)
Title.Size = UDim2.new(1, 0, 0, 70)
Title.Text = "⚡ MUMU SNAP"
Title.TextSize = 30
Title.Font = Enum.Font.GothamBlack
Title.TextColor3 = Color3.new(1, 1, 1)
Title.BackgroundTransparency = 1

local Container = Instance.new("Frame", Main)
Container.Size = UDim2.new(0.9, 0, 0.7, 0)
Container.Position = UDim2.fromScale(0.05, 0.2)
Container.BackgroundTransparency = 1
local Layout = Instance.new("UIListLayout", Container)
Layout.Padding = UDim.new(0, 15)

-- [[ 2. 按鈕生成器 ]]
local function AddToggle(name, settingKey)
    local btn = Instance.new("TextButton", Container)
    btn.Size = UDim2.new(1, 0, 0, 60)
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

AddToggle("ESP (紅色高亮)", "ESP")
AddToggle("絕對瞬鎖 (右鍵)", "Aimbot")

-- [[ 懸浮按鈕邏輯 ]]
local dragStartPos = nil
ToggleBtn.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragStartPos = ToggleBtn.Position
    end
end)
ToggleBtn.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        if dragStartPos and (math.abs(ToggleBtn.Position.X.Offset - dragStartPos.X.Offset) < 5) and (math.abs(ToggleBtn.Position.Y.Offset - dragStartPos.Y.Offset) < 5) then
            Main.Visible = not Main.Visible
        end
        Main.Position = UDim2.new(0, ToggleBtn.Position.X.Offset + 80, 0, ToggleBtn.Position.Y.Offset - 150)
    end
end)

-- [[ 3. 絕對瞬鎖核心邏輯 ]]
local function GetClosest()
    local target, maxDist = nil, Settings.FOV
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("Head") and p.Character:FindFirstChild("Humanoid") and p.Character.Humanoid.Health > 0 then
            
            local distFromPlayer = (LocalPlayer.Character.HumanoidRootPart.Position - p.Character.HumanoidRootPart.Position).Magnitude
            if distFromPlayer > Settings.MaxDistance then continue end

            local pos, onScreen = Camera:WorldToViewportPoint(p.Character.Head.Position)
            if onScreen then
                local dist = (Vector2.new(pos.X, pos.Y) - UserInputService:GetMouseLocation()).Magnitude
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
                h.OutlineColor = Color3.new(1, 1, 1)
            end
        end
    end

    -- ⚡ 絕對瞬鎖 (Absolute Snap)
    if Settings.Aimbot and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
        local t = GetClosest()
        if t and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            local targetPos = t.Head.Position + (t.HumanoidRootPart.Velocity * Settings.Prediction)
            
            -- 【關鍵修改】完全棄用 Lerp，直接強制賦予目標座標
            -- 1. 視角瞬移
            Camera.CFrame = CFrame.lookAt(Camera.CFrame.Position, targetPos)
            
            -- 2. 身體同步瞬移 (確保槍口指向)
            local hrp = LocalPlayer.Character.HumanoidRootPart
            hrp.CFrame = CFrame.new(hrp.Position, Vector3.new(targetPos.X, hrp.Position.Y, targetPos.Z))
        end
    end
end)
