-- ==========================================
-- MUMU RIVALS - 視角與槍口同步版 (修復槍口不跟隨)
-- ==========================================

local Settings = {
    ESP = true,
    Aimbot = true,
    FOV = 180,           
    Prediction = 0.14,    
    Smoothness = 0.1,    -- 稍微調高一點，讓槍口轉得夠快
    TeamCheck = false
}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- [[ 超大字體 UI ]]
local SafeGui = (gethui and gethui()) or game:GetService("CoreGui")
if SafeGui:FindFirstChild("MUMU_Sync") then SafeGui.MUMU_Sync:Destroy() end
local ScreenGui = Instance.new("ScreenGui", SafeGui)
ScreenGui.Name = "MUMU_Sync"
local Main = Instance.new("Frame", ScreenGui)
Main.Size = UDim2.fromOffset(300, 300)
Main.Position = UDim2.fromScale(0.5, 0.5)
Main.AnchorPoint = Vector2.new(0.5, 0.5)
Main.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
Instance.new("UICorner", Main)
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
AddToggle("AIM 鎖頭 (同步)", Settings.Aimbot, function(v) Settings.Aimbot = v end)

-- [[ 核心修復邏輯 ]]

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

    -- 鎖頭 (同步視角與身體)
    if Settings.Aimbot and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
        local target = GetTarget()
        if target and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            local targetPos = target.Head.Position + (target.HumanoidRootPart.Velocity * Settings.Prediction)
            
            -- 1. 鎖相機 (眼睛看過去)
            local lookAt = CFrame.lookAt(Camera.CFrame.Position, targetPos)
            Camera.CFrame = Camera.CFrame:Lerp(lookAt, Settings.Smoothness)
            
            -- 2. 鎖身體 (槍口指過去) - 這是關鍵！
            -- 只旋轉 Y 軸（左右），不旋轉 X 軸，防止角色身體倒立
            local hrp = LocalPlayer.Character.HumanoidRootPart
            local newBodyLook = CFrame.new(hrp.Position, Vector3.new(targetPos.X, hrp.Position.Y, targetPos.Z))
            hrp.CFrame = hrp.CFrame:Lerp(newBodyLook, Settings.Smoothness)
        end
    end
end)

UserInputService.InputBegan:Connect(function(i, g)
    if not g and i.KeyCode == Enum.KeyCode.J then Main.Visible = not Main.Visible end
end)
