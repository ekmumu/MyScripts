-- ==========================================
-- MUMU RIVALS - 瞬間鎖頭 + 暴力整合版
-- ==========================================

local Settings = {
    ESP = true,
    Aimbot = true,
    SnapMode = true,     -- true = 瞬間鎖死 / false = 平滑吸附
    Prediction = 0.165,  -- 預判
    FOV = 180,           -- 偵測範圍
    TeamCheck = false
}

local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- [[ UI 唯一性檢查 ]]
local SafeGui = (gethui and gethui()) or CoreGui
if SafeGui:FindFirstChild("MUMU_Snap") then SafeGui.MUMU_Snap:Destroy() end

local ScreenGui = Instance.new("ScreenGui", SafeGui)
ScreenGui.Name = "MUMU_Snap"

-- [[ FOV 圈圈 ]]
local FOVCircle = Drawing.new("Circle")
FOVCircle.Thickness = 1
FOVCircle.Color = Color3.fromRGB(255, 0, 0)
FOVCircle.Transparency = 0.8
FOVCircle.Visible = true

-- [[ UI 主視窗 ]]
local Main = Instance.new("Frame", ScreenGui)
Main.Size = UDim2.fromOffset(280, 380)
Main.Position = UDim2.fromScale(0.5, 0.5)
Main.AnchorPoint = Vector2.new(0.5, 0.5)
Main.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 10)
local Stroke = Instance.new("UIStroke", Main)
Stroke.Color = Color3.fromRGB(255, 0, 0)
Stroke.Thickness = 2

local Title = Instance.new("TextLabel", Main)
Title.Size = UDim2.new(1, 0, 0, 50)
Title.Text = "⚡ MUMU RIVALS | SNAP"
Title.TextColor3 = Color3.new(1, 1, 1)
Title.TextSize = 18
Title.Font = Enum.Font.GothamBlack
Title.BackgroundTransparency = 1

local Container = Instance.new("Frame", Main)
Container.Size = UDim2.new(0.9, 0, 0.7, 0)
Container.Position = UDim2.fromScale(0.05, 0.15)
Container.BackgroundTransparency = 1
local Layout = Instance.new("UIListLayout", Container)
Layout.Padding = UDim.new(0, 8)

-- [[ 切換開關產生器 ]]
local function AddToggle(name, default, callback)
    local state = default
    local btn = Instance.new("TextButton", Container)
    btn.Size = UDim2.new(1, 0, 0, 40)
    btn.BackgroundColor3 = state and Color3.fromRGB(200, 0, 0) or Color3.fromRGB(30, 30, 30)
    btn.Text = name .. ": " .. (state and "ON" or "OFF")
    btn.TextColor3 = Color3.new(1, 1, 1)
    btn.Font = Enum.Font.GothamBold
    Instance.new("UICorner", btn)
    
    btn.MouseButton1Click:Connect(function()
        state = not state
        btn.BackgroundColor3 = state and Color3.fromRGB(200, 0, 0) or Color3.fromRGB(30, 30, 30)
        btn.Text = name .. ": " .. (state and "ON" or "OFF")
        callback(state)
    end)
end

AddToggle("ESP 透視", Settings.ESP, function(v) Settings.ESP = v end)
AddToggle("Aimbot 鎖頭", Settings.Aimbot, function(v) Settings.Aimbot = v end)
AddToggle("Snap Mode (直接鎖死)", Settings.SnapMode, function(v) Settings.SnapMode = v end)
AddToggle("Team Check 隊友過濾", Settings.TeamCheck, function(v) Settings.TeamCheck = v end)

-- [[ 核心邏輯 ]]
local function GetTarget()
    local target = nil
    local dist = Settings.FOV
    local mousePos = UserInputService:GetMouseLocation()

    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("Head") then
            if Settings.TeamCheck and p.Team == LocalPlayer.Team then continue end
            local hum = p.Character:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health > 0 then
                local pos, onScreen = Camera:WorldToViewportPoint(p.Character.Head.Position)
                if onScreen then
                    local mag = (Vector2.new(pos.X, pos.Y) - mousePos).Magnitude
                    if mag < dist then
                        dist = mag
                        target = p.Character
                    end
                end
            end
        end
    end
    return target
end

-- 循環執行
RunService.RenderStepped:Connect(function()
    FOVCircle.Position = UserInputService:GetMouseLocation()
    FOVCircle.Radius = Settings.FOV
    
    -- ESP 處理
    if Settings.ESP then
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character then
                if not p.Character:FindFirstChild("MUMU_Highlight") then
                    local h = Instance.new("Highlight", p.Character)
                    h.Name = "MUMU_Highlight"
                    h.FillColor = Color3.new(1, 0, 0)
                    h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                end
            end
        end
    end

    -- 鎖頭處理
    if Settings.Aimbot and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
        local target = GetTarget()
        if target then
            local headPos = target.Head.Position + (target.HumanoidRootPart.Velocity * Settings.Prediction)
            
            if Settings.SnapMode then
                -- 【瞬間跳轉模式】直接改 CFrame
                Camera.CFrame = CFrame.lookAt(Camera.CFrame.Position, headPos)
            else
                -- 【平滑吸附模式】Lerp 移動
                Camera.CFrame = Camera.CFrame:Lerp(CFrame.lookAt(Camera.CFrame.Position, headPos), 0.1)
            end
        end
    end
end)

-- J 鍵隱藏
UserInputService.InputBegan:Connect(function(i, g)
    if not g and i.KeyCode == Enum.KeyCode.J then 
        Main.Visible = not Main.Visible 
        FOVCircle.Visible = Main.Visible
    end
end)

-- 簡單拖曳
local d, ds, sp
Main.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then d = true ds = i.Position sp = Main.Position end end)
UserInputService.InputChanged:Connect(function(i) if d and i.UserInputType == Enum.UserInputType.MouseMovement then local delta = i.Position - ds Main.Position = UDim2.new(sp.X.Scale, sp.X.Offset + delta.X, sp.Y.Scale, sp.Y.Offset + delta.Y) end end)
UserInputService.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then d = false end end)
