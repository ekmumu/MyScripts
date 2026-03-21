-- ==========================================
-- MUMU RIVALS - 子彈吸附 (Hitbox) + 鎖頭修復版
-- ==========================================

local Settings = {
    ESP = true,
    Aimbot = true,
    Magnet = true,       -- 子彈吸附 (放大頭部)
    MagnetSize = 10,     -- 吸附範圍 (數值越大越誇張)
    Prediction = 0.165,
    FOV = 200,
    TeamCheck = false
}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- [[ UI 唯一性與大字體介面 ]]
local SafeGui = (gethui and gethui()) or game:GetService("CoreGui")
if SafeGui:FindFirstChild("MUMU_Magnet") then SafeGui.MUMU_Magnet:Destroy() end
local ScreenGui = Instance.new("ScreenGui", SafeGui)
ScreenGui.Name = "MUMU_Magnet"

local Main = Instance.new("Frame", ScreenGui)
Main.Size = UDim2.fromOffset(360, 500)
Main.Position = UDim2.fromScale(0.5, 0.5)
Main.AnchorPoint = Vector2.new(0.5, 0.5)
Main.BackgroundColor3 = Color3.fromRGB(15, 0, 0)
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 15)
Instance.new("UIStroke", Main).Thickness = 4

local Title = Instance.new("TextLabel", Main)
Title.Size = UDim2.new(1, 0, 0, 80)
Title.Text = "🔥 MUMU ULTIMATE"
Title.TextColor3 = Color3.new(1, 1, 1)
Title.TextSize = 32
Title.Font = Enum.Font.GothamBlack
Title.BackgroundTransparency = 1

local Container = Instance.new("Frame", Main)
Container.Size = UDim2.new(0.9, 0, 0.7, 0)
Container.Position = UDim2.fromScale(0.05, 0.2)
Container.BackgroundTransparency = 1
Instance.new("UIListLayout", Container).Padding = UDim.new(0, 15)

-- [[ 按鈕產生器 ]]
local function AddToggle(name, default, callback)
    local state = default
    local btn = Instance.new("TextButton", Container)
    btn.Size = UDim2.new(1, 0, 0, 60)
    btn.BackgroundColor3 = state and Color3.fromRGB(255, 0, 0) or Color3.fromRGB(40, 40, 40)
    btn.Text = name .. ": " .. (state and "ON" or "OFF")
    btn.TextColor3 = Color3.new(1, 1, 1)
    btn.TextSize = 20
    btn.Font = Enum.Font.GothamBold
    Instance.new("UICorner", btn)
    
    btn.MouseButton1Click:Connect(function()
        state = not state
        btn.BackgroundColor3 = state and Color3.fromRGB(255, 0, 0) or Color3.fromRGB(40, 40, 40)
        btn.Text = name .. ": " .. (state and "ON" or "OFF")
        callback(state)
    end)
end

AddToggle("ESP 透視 (紅框)", Settings.ESP, function(v) Settings.ESP = v end)
AddToggle("子彈吸附 (放大頭部)", Settings.Magnet, function(v) Settings.Magnet = v end)
AddToggle("暴力鎖頭 (右鍵)", Settings.Aimbot, function(v) Settings.Aimbot = v end)
AddToggle("隊友過濾", Settings.TeamCheck, function(v) Settings.TeamCheck = v end)

-- [[ 核心邏輯 ]]

-- 1. 子彈吸附 (Hitbox Expander)
task.spawn(function()
    while task.wait(0.5) do
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("Head") then
                local head = p.Character.Head
                if Settings.Magnet then
                    head.Size = Vector3.new(Settings.MagnetSize, Settings.MagnetSize, Settings.MagnetSize)
                    head.Transparency = 0.5 -- 讓大頭變半透明，比較不擋視線
                    head.CanCollide = false -- 防止撞到大頭
                else
                    head.Size = Vector3.new(1.2, 1.2, 1.2) -- 恢復原狀
                    head.Transparency = 0
                end
            end
        end
    end
end)

-- 2. 鎖頭功能 (修復後的視角控制)
local function GetTarget()
    local target = nil
    local dist = Settings.FOV
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("Head") then
            if Settings.TeamCheck and p.Team == LocalPlayer.Team then continue end
            local pos, onScreen = Camera:WorldToViewportPoint(p.Character.Head.Position)
            if onScreen then
                local mag = (Vector2.new(pos.X, pos.Y) - UserInputService:GetMouseLocation()).Magnitude
                if mag < dist then dist = mag target = p.Character end
            end
        end
    end
    return target
end

RunService.RenderStepped:Connect(function()
    -- ESP 更新
    if Settings.ESP then
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character and not p.Character:FindFirstChild("MUMU_ESP") then
                Instance.new("Highlight", p.Character).Name = "MUMU_ESP"
            end
        end
    end

    -- 鎖頭更新 (修復版)
    if Settings.Aimbot and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
        local t = GetTarget()
        if t then
            local pPos = t.Head.Position + (t.HumanoidRootPart.Velocity * Settings.Prediction)
            -- 使用更穩定的 CFrame 更新方式
            Camera.CFrame = CFrame.new(Camera.CFrame.Position, pPos)
        end
    end
end)

-- J 鍵隱藏
UserInputService.InputBegan:Connect(function(i, g)
    if not g and i.KeyCode == Enum.KeyCode.J then Main.Visible = not Main.Visible end
end)

-- 拖曳功能
local d, ds, sp
Main.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then d = true ds = i.Position sp = Main.Position end end)
UserInputService.InputChanged:Connect(function(i) if d and i.UserInputType == Enum.UserInputType.MouseMovement then local delta = i.Position - ds Main.Position = UDim2.new(sp.X.Scale, sp.X.Offset + delta.X, sp.Y.Scale, sp.Y.Offset + delta.Y) end end)
UserInputService.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then d = false end end)
