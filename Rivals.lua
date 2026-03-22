-- ==========================================
-- MUMU RIVALS - 絕對中心固定介面 + 死鎖追蹤
-- ==========================================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

local Settings = {
    ESP = true,
    Aimbot = true,
    Prediction = 0.13, -- 最適合 Rivals 的跑動預判值
    FOV = 250
}

-- [[ 1. UI 建立: 絕對固定在正中心 ]]
local SafeGui = (gethui and gethui()) or game:GetService("CoreGui")
if SafeGui:FindFirstChild("MUMU_FIXED_CENTER") then
    SafeGui.MUMU_FIXED_CENTER:Destroy()
end

local ScreenGui = Instance.new("ScreenGui", SafeGui)
ScreenGui.Name = "MUMU_FIXED_CENTER"
ScreenGui.ResetOnSpawn = false

local Main = Instance.new("Frame", ScreenGui)
Main.Size = UDim2.fromOffset(300, 380)
Main.Position = UDim2.fromScale(0.5, 0.5) -- 絕對正中心
Main.AnchorPoint = Vector2.new(0.5, 0.5)  -- 錨點在中心
Main.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
-- ⚠️ 移除所有拖曳腳本，確保它絕對不會飄走 ⚠️
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 10)
Instance.new("UIStroke", Main).Thickness = 3
Instance.new("UIStroke", Main).Color = Color3.fromRGB(255, 0, 0)

local Title = Instance.new("TextLabel", Main)
Title.Size = UDim2.new(1, 0, 0, 70)
Title.Text = "⚡ MUMU CORE"
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

-- [ 按鈕生成器 ]
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

AddToggle("ESP (透視)", "ESP")
AddToggle("死鎖追蹤 (右鍵)", "Aimbot")

local Hint = Instance.new("TextLabel", Main)
Hint.Size = UDim2.new(1, 0, 0, 30)
Hint.Position = UDim2.new(0, 0, 1, -40)
Hint.Text = "按 [J] 鍵顯示/隱藏選單"
Hint.TextColor3 = Color3.fromRGB(150, 150, 150)
Hint.TextSize = 16
Hint.Font = Enum.Font.Gotham
Hint.BackgroundTransparency = 1

-- [[ 2. J鍵開關邏輯 ]]
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if not gameProcessed and input.KeyCode == Enum.KeyCode.J then
        Main.Visible = not Main.Visible
    end
end)

-- [[ 3. 核心邏輯: 死鎖追蹤 ]]
local LockedTarget = nil

local function GetTarget()
    local target, maxDist = nil, Settings.FOV
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("Head") and p.Character:FindFirstChild("Humanoid") and p.Character.Humanoid.Health > 0 then
            local pos, onScreen = Camera:WorldToViewportPoint(p.Character.Head.Position)
            if onScreen then
                local dist = (Vector2.new(pos.X, pos.Y) - UserInputService:GetMouseLocation()).Magnitude
                if dist < maxDist then 
                    maxDist = dist 
                    target = p.Character 
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
            if p ~= LocalPlayer and p.Character then
                local h = p.Character:FindFirstChild("MUMU_Highlight") or Instance.new("Highlight", p.Character)
                h.Name = "MUMU_Highlight"
                h.FillColor = Color3.new(1, 0, 0)
                h.OutlineColor = Color3.new(1, 1, 1)
            end
        end
    end

    -- Aimbot (死鎖追蹤)
    if Settings.Aimbot and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
        -- 如果沒有目標，就抓一個最近的
        if not LockedTarget then
            LockedTarget = GetTarget()
        end
        
        -- 如果目標存在且活著
        if LockedTarget and LockedTarget:FindFirstChild("Head") and LockedTarget:FindFirstChild("Humanoid") and LockedTarget.Humanoid.Health > 0 then
            -- 計算他下一秒會跑去哪裡 (預判)
            local targetPos = LockedTarget.Head.Position + (LockedTarget.HumanoidRootPart.Velocity * Settings.Prediction)
            
            -- ⚡ 關鍵修復：完全鎖死相機視角，不干預身體。這樣你的槍口就能完美指過去了。
            Camera.CFrame = CFrame.lookAt(Camera.CFrame.Position, targetPos)
        else
            -- 目標死了或不見了，清空重新找
            LockedTarget = nil
        end
    else
        -- 放開右鍵，立刻解除鎖定
        LockedTarget = nil
    end
end)
