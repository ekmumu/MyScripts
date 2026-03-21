-- ==========================================
-- Z3US RIVALS - 專屬優化載入器 (功能修復版)
-- ==========================================

local Settings = {
    ESP = true,
    Aimbot = true,
    FOV = 200,           -- 鎖頭範圍大小
    Smoothness = 0.1,    -- 鎖頭平滑度 (越小越快)
    TeamCheck = false,   -- 強制設為 false 以確保測試時功能正常
    ScriptUrl = "https://raw.githubusercontent.com/ekmumu/MyScripts/refs/heads/main/Rivals.lua" 
}

local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- 確保使用最安全的 UI 容器
local SafeGui = (gethui and gethui()) or CoreGui
if SafeGui:FindFirstChild("Z3US_Rivals") then 
    SafeGui.Z3US_Rivals:Destroy() 
end

local ScreenGui = Instance.new("ScreenGui", SafeGui)
ScreenGui.Name = "Z3US_Rivals"
ScreenGui.ResetOnSpawn = false

-- [[ UI 建立 ]]
local Main = Instance.new("Frame", ScreenGui)
Main.Size = UDim2.fromOffset(320, 360)
Main.Position = UDim2.fromScale(0.5, 0.5)
Main.AnchorPoint = Vector2.new(0.5, 0.5)
Main.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
Main.BorderSizePixel = 0
Main.Visible = true
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 12)

local Stroke = Instance.new("UIStroke", Main)
Stroke.Color = Color3.fromRGB(100, 120, 255)
Stroke.Thickness = 1.5

local Title = Instance.new("TextLabel", Main)
Title.Size = UDim2.new(1, 0, 0, 50)
Title.BackgroundTransparency = 1
Title.Text = "⚡ Z3US | RIVALS"
Title.TextColor3 = Color3.new(1, 1, 1)
Title.TextSize = 20
Title.Font = Enum.Font.GothamBold

local CloseBtn = Instance.new("TextButton", Main)
CloseBtn.Size = UDim2.fromOffset(40, 40)
CloseBtn.Position = UDim2.new(1, -45, 0, 5)
CloseBtn.BackgroundTransparency = 1
CloseBtn.Text = "✕"
CloseBtn.TextColor3 = Color3.fromRGB(150, 150, 150)
CloseBtn.TextSize = 18
CloseBtn.Font = Enum.Font.GothamBold

local Content = Instance.new("Frame", Main)
Content.Size = UDim2.new(0.9, 0, 0.75, 0)
Content.Position = UDim2.fromScale(0.05, 0.16)
Content.BackgroundTransparency = 1

local Layout = Instance.new("UIListLayout", Content)
Layout.Padding = UDim.new(0, 12)
Layout.HorizontalAlignment = Enum.HorizontalAlignment.Center

local function TweenColor(obj, targetColor, duration)
    TweenService:Create(obj, TweenInfo.new(duration or 0.2), {BackgroundColor3 = targetColor}):Play()
end

local function CreateToggle(text, defaultValue, callback)
    local Enabled = defaultValue
    local Btn = Instance.new("TextButton", Content)
    Btn.Size = UDim2.new(1, 0, 0, 45)
    Btn.BackgroundColor3 = Enabled and Color3.fromRGB(100, 120, 255) or Color3.fromRGB(35, 35, 40)
    Btn.Text = "  " .. text .. ": " .. (Enabled and "ON" or "OFF")
    Btn.TextColor3 = Color3.new(1, 1, 1)
    Btn.Font = Enum.Font.GothamSemibold
    Btn.TextSize = 15
    Instance.new("UICorner", Btn).CornerRadius = UDim.new(0, 8)
    
    Btn.MouseButton1Click:Connect(function()
        Enabled = not Enabled
        TweenColor(Btn, Enabled and Color3.fromRGB(100, 120, 255) or Color3.fromRGB(35, 35, 40), 0.2)
        Btn.Text = "  " .. text .. ": " .. (Enabled and "ON" or "OFF")
        callback(Enabled)
    end)
end

CreateToggle("ESP (方框透視)", Settings.ESP, function(v) Settings.ESP = v end)
CreateToggle("Aimbot (右鍵鎖頭)", Settings.Aimbot, function(v) Settings.Aimbot = v end)

local LoadBtn = Instance.new("TextButton", Content)
LoadBtn.Size = UDim2.new(1, 0, 0, 55)
LoadBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
LoadBtn.Text = "LOAD SCRIPT"
LoadBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
LoadBtn.Font = Enum.Font.GothamBlack
LoadBtn.TextSize = 16
Instance.new("UICorner", LoadBtn).CornerRadius = UDim.new(0, 8)

-- ==========================================
-- 修復版功能引擎
-- ==========================================

-- 1. 穩定方框 ESP (使用 Drawing API，不會被遊戲刪除)
local function Start_ESP()
    local function CreateBox(player)
        local Box = Drawing.new("Square")
        Box.Visible = false
        Box.Color = Color3.fromRGB(255, 50, 50)
        Box.Thickness = 2
        Box.Transparency = 1
        Box.Filled = false

        RunService.RenderStepped:Connect(function()
            if Settings.ESP and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                local Root = player.Character.HumanoidRootPart
                local Pos, OnScreen = Camera:WorldToViewportPoint(Root.Position)

                if OnScreen then
                    local SizeY = (Camera:WorldToViewportPoint(Root.Position + Vector3.new(0, 3, 0)).Y - Camera:WorldToViewportPoint(Root.Position + Vector3.new(0, -3.5, 0)).Y)
                    Box.Size = Vector2.new(SizeY / 1.5, SizeY)
                    Box.Position = Vector2.new(Pos.X - Box.Size.X / 2, Pos.Y - Box.Size.Y / 2)
                    Box.Visible = true
                else
                    Box.Visible = false
                end
            else
                Box.Visible = false
            end
            if not player.Parent then Box:Remove() end
        end)
    end
    for _, p in pairs(Players:GetPlayers()) do if p ~= LocalPlayer then CreateBox(p) end end
    Players.PlayerAdded:Connect(function(p) if p ~= LocalPlayer then CreateBox(p) end end)
end

-- 2. 強化鎖頭 (優化目標選擇)
local function Start_Aimbot()
    RunService.RenderStepped:Connect(function()
        if Settings.Aimbot and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
            local Closest = nil
            local MaxDist = Settings.FOV
            local MousePos = UserInputService:GetMouseLocation()

            for _, p in pairs(Players:GetPlayers()) do
                if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("Head") then
                    -- 檢查血量
                    local hum = p.Character:FindFirstChildOfClass("Humanoid")
                    if hum and hum.Health > 0 then
                        local Pos, OnScreen = Camera:WorldToViewportPoint(p.Character.Head.Position)
                        if OnScreen then
                            local Dist = (Vector2.new(Pos.X, Pos.Y) - MousePos).Magnitude
                            if Dist < MaxDist then
                                MaxDist = Dist
                                Closest = p.Character.Head
                            end
                        end
                    end
                end
            end

            if Closest then
                local LookAt = CFrame.new(Camera.CFrame.Position, Closest.Position)
                Camera.CFrame = Camera.CFrame:Lerp(LookAt, Settings.Smoothness)
            end
        end
    end)
end

-- ==========================================
-- 核心事件
-- ==========================================

LoadBtn.MouseButton1Click:Connect(function()
    LoadBtn.Text = "Loading..."
    Start_ESP()
    Start_Aimbot()
    task.spawn(function()
        pcall(function() loadstring(game:HttpGet(Settings.ScriptUrl))() end)
        LoadBtn.Text = "✅ READY [Press J]"
        task.wait(1)
        Main.Visible = false 
    end)
end)

UserInputService.InputBegan:Connect(function(input, gp)
    if not gp and input.KeyCode == Enum.KeyCode.J then
        Main.Visible = not Main.Visible
    end
end)

CloseBtn.MouseButton1Click:Connect(function() Main.Visible = false end)

-- 拖曳功能 (簡化)
local d, ds, sp
Main.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then d = true ds = i.Position sp = Main.Position end end)
UserInputService.InputChanged:Connect(function(i) if d and i.UserInputType == Enum.UserInputType.MouseMovement then local delta = i.Position - ds Main.Position = UDim2.new(sp.X.Scale, sp.X.Offset + delta.X, sp.Y.Scale, sp.Y.Offset + delta.Y) end end)
UserInputService.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then d = false end end)
