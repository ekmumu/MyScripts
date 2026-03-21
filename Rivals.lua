-- ==========================================
-- MUMU RIVALS - 僅留透視與強制鎖頭
-- ==========================================

local Settings = {
    ESP = true,
    Aimbot = true,
    FOV = 200,           -- 鎖頭範圍
    Prediction = 0.16,   -- 預判移動
    TeamCheck = false    -- 建議先設 false 確保能鎖到人
}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- [[ 超大字體極簡 UI ]]
local SafeGui = (gethui and gethui()) or game:GetService("CoreGui")
if SafeGui:FindFirstChild("MUMU_Core") then SafeGui.MUMU_Core:Destroy() end
local ScreenGui = Instance.new("ScreenGui", SafeGui)
ScreenGui.Name = "MUMU_Core"

local Main = Instance.new("Frame", ScreenGui)
Main.Size = UDim2.fromOffset(300, 300)
Main.Position = UDim2.fromScale(0.5, 0.5)
Main.AnchorPoint = Vector2.new(0.5, 0.5)
Main.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 15)
local Stroke = Instance.new("UIStroke", Main)
Stroke.Thickness = 4
Stroke.Color = Color3.fromRGB(255, 0, 0)

local Title = Instance.new("TextLabel", Main)
Title.Size = UDim2.new(1, 0, 0, 80)
Title.Text = "⚡ MUMU CORE"
Title.TextSize = 35 -- 超大標題
Title.Font = Enum.Font.GothamBlack
Title.TextColor3 = Color3.new(1, 1, 1)
Title.BackgroundTransparency = 1

local Container = Instance.new("Frame", Main)
Container.Size = UDim2.new(0.9, 0, 0.6, 0)
Container.Position = UDim2.fromScale(0.05, 0.25)
Container.BackgroundTransparency = 1
local Layout = Instance.new("UIListLayout", Container)
Layout.Padding = UDim.new(0, 20)

-- [[ 按鈕生成 ]]
local function AddToggle(name, default, callback)
    local state = default
    local btn = Instance.new("TextButton", Container)
    btn.Size = UDim2.new(1, 0, 0, 65)
    btn.BackgroundColor3 = state and Color3.fromRGB(200, 0, 0) or Color3.fromRGB(40, 40, 40)
    btn.Text = name .. ": " .. (state and "ON" or "OFF")
    btn.TextSize = 22 -- 超大按鈕文字
    btn.Font = Enum.Font.GothamBold
    btn.TextColor3 = Color3.new(1, 1, 1)
    Instance.new("UICorner", btn)
    
    btn.MouseButton1Click:Connect(function()
        state = not state
        btn.BackgroundColor3 = state and Color3.fromRGB(200, 0, 0) or Color3.fromRGB(40, 40, 40)
        btn.Text = name .. ": " .. (state and "ON" or "OFF")
        callback(state)
    end)
end

AddToggle("ESP 透視", Settings.ESP, function(v) Settings.ESP = v end)
AddToggle("AIM 鎖頭 (右鍵)", Settings.Aimbot, function(v) Settings.Aimbot = v end)

-- [[ 核心功能邏輯 ]]

-- 1. 穩定透視
RunService.Heartbeat:Connect(function()
    if Settings.ESP then
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character then
                local h = p.Character:FindFirstChild("MUMU_Highlight")
                if not h then
                    h = Instance.new("Highlight", p.Character)
                    h.Name = "MUMU_Highlight"
                    h.FillColor = Color3.new(1, 0, 0)
                    h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                end
            end
        end
    end
end)

-- 2. 強制鎖頭 (修復視角覆寫)
local function GetTarget()
    local target = nil
    local maxDist = Settings.FOV
    local mousePos = UserInputService:GetMouseLocation()

    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("Head") then
            if Settings.TeamCheck and p.Team == LocalPlayer.Team then continue end
            local hum = p.Character:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health > 0 then
                local pos, onScreen = Camera:WorldToViewportPoint(p.Character.Head.Position)
                if onScreen then
                    local dist = (Vector2.new(pos.X, pos.Y) - mousePos).Magnitude
                    if dist < maxDist then
                        maxDist = dist
                        target = p.Character
                    end
                end
            end
        end
    end
    return target
end

RunService.RenderStepped:Connect(function()
    if Settings.Aimbot and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
        local target = GetTarget()
        if target and target:FindFirstChild("Head") then
            -- 預判計算
            local targetPos = target.Head.Position + (target.HumanoidRootPart.Velocity * Settings.Prediction)
            -- 瞬間鎖定 (CFrame 直接賦值，不使用 Lerp 以確保強度)
            Camera.CFrame = CFrame.lookAt(Camera.CFrame.Position, targetPos)
        end
    end
end)

-- J 鍵隱藏
UserInputService.InputBegan:Connect(function(i, g)
    if not g and i.KeyCode == Enum.KeyCode.J then Main.Visible = not Main.Visible end
end)
