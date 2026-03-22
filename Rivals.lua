-- ==========================================
-- MUMU RIVALS - 懸浮按鈕防攔截版 (絕對可用)
-- ==========================================

local Settings = {
    ESP = true,
    Aimbot = true,
    Smoothness = 0.08,    -- 右鍵絲滑瞄準
    SnapStrength = 0.85,  -- 左鍵開火瞬鎖
    Prediction = 0.15,
    FOV = 250
}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- [[ 1. 強制 UI 建立 ]]
local SafeGui = (gethui and gethui()) or game:GetService("CoreGui")
if SafeGui:FindFirstChild("MUMU_ULTIMATE") then SafeGui.MUMU_ULTIMATE:Destroy() end

local ScreenGui = Instance.new("ScreenGui", SafeGui)
ScreenGui.Name = "MUMU_ULTIMATE"
ScreenGui.ResetOnSpawn = false

-- [[ 2. 懸浮開關按鈕 (解決 J 鍵失效) ]]
local ToggleBtn = Instance.new("TextButton", ScreenGui)
ToggleBtn.Size = UDim2.fromOffset(60, 60)
ToggleBtn.Position = UDim2.new(0, 20, 0.5, -30) -- 預設在螢幕左側中央
ToggleBtn.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
ToggleBtn.Text = "⚡\nMUMU"
ToggleBtn.TextColor3 = Color3.new(1, 1, 1)
ToggleBtn.Font = Enum.Font.GothamBlack
ToggleBtn.TextSize = 14
ToggleBtn.Active = true
ToggleBtn.Draggable = true -- 使用最原始的拖拽，保證可動
Instance.new("UICorner", ToggleBtn).CornerRadius = UDim.new(1, 0) -- 圓形按鈕
Instance.new("UIStroke", ToggleBtn).Thickness = 2

-- [[ 3. 主選單 UI ]]
local Main = Instance.new("Frame", ScreenGui)
Main.Size = UDim2.fromOffset(300, 380)
-- 讓主選單永遠跟著懸浮按鈕顯示
Main.Position = UDim2.new(0, 90, 0.5, -190) 
Main.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
Main.Visible = false -- 預設隱藏，點擊才出現
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 15)
local Stroke = Instance.new("UIStroke", Main)
Stroke.Thickness = 3
Stroke.Color = Color3.fromRGB(255, 0, 0)

local Title = Instance.new("TextLabel", Main)
Title.Size = UDim2.new(1, 0, 0, 70)
Title.Text = "⚡ MUMU MENU"
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

-- [[ 4. 按鈕生成器 ]]
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
AddToggle("雙模鎖頭 (右瞄左鎖)", "Aimbot")

-- [[ 懸浮按鈕點擊事件 ]]
local dragStartPos = nil
ToggleBtn.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragStartPos = ToggleBtn.Position
    end
end)

ToggleBtn.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        -- 如果按鈕沒有被拖動太多，就當作是「點擊」來開關選單
        if dragStartPos and (ToggleBtn.Position.X.Offset - dragStartPos.X.Offset) < 5 and (ToggleBtn.Position.Y.Offset - dragStartPos.Y.Offset) < 5 then
            Main.Visible = not Main.Visible
        end
        -- 更新主選單位置，讓它靠在按鈕旁邊
        Main.Position = UDim2.new(0, ToggleBtn.Position.X.Offset + 80, 0, ToggleBtn.Position.Y.Offset - 150)
    end
end)

-- 同時保留 ContextActionService 作為 J 鍵的最強備案
game:GetService("ContextActionService"):BindAction("ToggleMumu", function(actionName, state)
    if state == Enum.UserInputState.Begin then Main.Visible = not Main.Visible end
end, false, Enum.KeyCode.J)

-- [[ 5. 暴力雙模鎖頭邏輯 ]]
local function GetClosest()
    local target, maxDist = nil, Settings.FOV
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("Head") and p.Character:FindFirstChild("Humanoid") and p.Character.Humanoid.Health > 0 then
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

    -- 雙模鎖頭
    if Settings.Aimbot and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
        local t = GetClosest()
        if t and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            local targetPos = t.Head.Position + (t.HumanoidRootPart.Velocity * Settings.Prediction)
            
            -- 判斷左鍵是否按下 (動態強度)
            local isFiring = UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)
            local strength = isFiring and Settings.SnapStrength or Settings.Smoothness
            
            Camera.CFrame = Camera.CFrame:Lerp(CFrame.lookAt(Camera.CFrame.Position, targetPos), strength)
            
            local hrp = LocalPlayer.Character.HumanoidRootPart
            hrp.CFrame = hrp.CFrame:Lerp(CFrame.new(hrp.Position, Vector3.new(targetPos.X, hrp.Position.Y, targetPos.Z)), strength)
        end
    end
end)
