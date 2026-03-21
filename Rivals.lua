-- ==========================================
-- Z3US RIVALS - 最終整合版 (ESP + Aimbot)
-- ==========================================

local Settings = {
    Autoload = true,    -- ESP 開關
    Aimbot = true,      -- 鎖頭開關
    Silentload = false,
    ScriptUrl = "https://raw.githubusercontent.com/ekmumu/MyScripts/refs/heads/main/Rivals.lua" 
}

local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- 確保 UI 唯一性
local SafeGui = (gethui and gethui()) or CoreGui
if SafeGui:FindFirstChild("Z3US_Rivals") then SafeGui.Z3US_Rivals:Destroy() end

local ScreenGui = Instance.new("ScreenGui", SafeGui)
ScreenGui.Name = "Z3US_Rivals"

-- [[ UI 建立 ]]
local Main = Instance.new("Frame", ScreenGui)
Main.Size = UDim2.fromOffset(320, 420) -- 稍微拉長一點放按鈕
Main.Position = UDim2.fromScale(0.5, 0.5)
Main.AnchorPoint = Vector2.new(0.5, 0.5)
Main.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
Main.BorderSizePixel = 0
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
CloseBtn.MouseButton1Click:Connect(function() ScreenGui:Destroy() end)

local Content = Instance.new("Frame", Main)
Content.Size = UDim2.new(0.9, 0, 0.75, 0)
Content.Position = UDim2.fromScale(0.05, 0.16)
Content.BackgroundTransparency = 1
local Layout = Instance.new("UIListLayout", Content)
Layout.Padding = UDim.new(0, 10)
Layout.HorizontalAlignment = Enum.HorizontalAlignment.Center

-- [[ 按鈕產生器 ]]
local function CreateToggle(text, defaultValue, callback)
    local Enabled = defaultValue
    local Btn = Instance.new("TextButton", Content)
    Btn.Size = UDim2.new(1, 0, 0, 40)
    Btn.BackgroundColor3 = Enabled and Color3.fromRGB(100, 120, 255) or Color3.fromRGB(35, 35, 40)
    Btn.Text = "  " .. text .. ": " .. (Enabled and "ON" or "OFF")
    Btn.TextColor3 = Color3.new(1, 1, 1)
    Btn.Font = Enum.Font.GothamSemibold
    Btn.TextSize = 14
    Instance.new("UICorner", Btn).CornerRadius = UDim.new(0, 8)
    
    Btn.MouseButton1Click:Connect(function()
        Enabled = not Enabled
        Btn.BackgroundColor3 = Enabled and Color3.fromRGB(100, 120, 255) or Color3.fromRGB(35, 35, 40)
        Btn.Text = "  " .. text .. ": " .. (Enabled and "ON" or "OFF")
        callback(Enabled)
    end)
end

CreateToggle("ESP (透視)", Settings.Autoload, function(v) Settings.Autoload = v end)
CreateToggle("Aimbot (鎖頭)", Settings.Aimbot, function(v) Settings.Aimbot = v end)

local LoadBtn = Instance.new("TextButton", Content)
LoadBtn.Size = UDim2.new(1, 0, 0, 50)
LoadBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
LoadBtn.Text = "LOAD ALL FUNCTIONS"
LoadBtn.TextColor3 = Color3.new(1, 1, 1)
LoadBtn.Font = Enum.Font.GothamBlack
Instance.new("UICorner", LoadBtn).CornerRadius = UDim.new(0, 8)

-- [[ 功能 1: ESP 透視 ]]
local function Start_ESP()
    local function Apply(p)
        if p == LocalPlayer then return end
        p.CharacterAdded:Connect(function(c)
            local h = Instance.new("Highlight", c)
            h.FillColor = Color3.fromRGB(255, 80, 80)
            h.OutlineColor = Color3.new(1, 1, 1)
            h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        end)
    end
    for _, p in pairs(Players:GetPlayers()) do Apply(p) end
    Players.PlayerAdded:Connect(Apply)
end

-- [[ 功能 2: Aimbot 鎖頭核心 ]]
local function Start_Aimbot()
    local Smoothness = 0.15 -- 數值越小越順，數值大鎖越死
    
    local function GetClosestPlayer()
        local Target = nil
        local MaxDist = math.huge
        
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("Head") then
                -- 簡單判斷血量 (如有需要可加入)
                local Pos, OnScreen = Camera:WorldToViewportPoint(p.Character.Head.Position)
                if OnScreen then
                    local Dist = (Vector2.new(Pos.X, Pos.Y) - UserInputService:GetMouseLocation()).Magnitude
                    if Dist < MaxDist then
                        MaxDist = Dist
                        Target = p.Character.Head
                    end
                end
            end
        end
        return Target
    end

    RunService.RenderStepped:Connect(function()
        if Settings.Aimbot and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then -- 按住右鍵鎖頭
            local Target = GetClosestPlayer()
            if Target then
                Camera.CFrame = Camera.CFrame:Lerp(CFrame.new(Camera.CFrame.Position, Target.Position), Smoothness)
            end
        end
    end)
end

-- [[ 核心加載 ]]
LoadBtn.MouseButton1Click:Connect(function()
    LoadBtn.Text = "Loading..."
    if Settings.Autoload then Start_ESP() end
    if Settings.Aimbot then Start_Aimbot() end
    
    pcall(function() loadstring(game:HttpGet(Settings.ScriptUrl))() end)
    
    LoadBtn.Text = "✅ SUCCESS"
    task.wait(1)
    ScreenGui:Destroy()
end)

-- 拖曳功能
local dragging, dragStart, startPos
Main.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true dragStart = i.Position startPos = Main.Position end end)
UserInputService.InputChanged:Connect(function(i) if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then local d = i.Position - dragStart Main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y) end end)
UserInputService.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end end)
