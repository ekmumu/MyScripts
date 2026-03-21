-- ==========================================
-- MUMU RIVALS - 終極兼容修復版 (強制注入)
-- ==========================================

local Settings = {
    ESP = true,
    Aimbot = true,
    FOV = 250,           
    Smoothness = 0.05,   
    TeamCheck = false,   
}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- [[ UI 建立與 J 鍵開關 ]]
local ScreenGui = Instance.new("ScreenGui", (gethui and gethui()) or game:GetService("CoreGui"))
ScreenGui.Name = "MUMU_Rivals_UI"
ScreenGui.ResetOnSpawn = false

local Main = Instance.new("Frame", ScreenGui)
Main.Size = UDim2.fromOffset(280, 200)
Main.Position = UDim2.fromScale(0.5, 0.5)
Main.AnchorPoint = Vector2.new(0.5, 0.5)
Main.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 10)

local Status = Instance.new("TextLabel", Main)
Status.Size = UDim2.new(1, 0, 0.6, 0)
-- 這裡已經幫你修改為 MUMU RIVALS
Status.Text = "⚡ MUMU RIVALS\nSTATUS: ACTIVE\n[J] 隱藏/顯示\n[右鍵] 鎖頭"
Status.TextColor3 = Color3.new(1, 1, 1)
Status.BackgroundTransparency = 1
Status.TextSize = 18
Status.Font = Enum.Font.GothamBold

local LoadBtn = Instance.new("TextButton", Main)
LoadBtn.Size = UDim2.new(0.8, 0, 0.3, 0)
LoadBtn.Position = UDim2.fromScale(0.1, 0.6)
LoadBtn.BackgroundColor3 = Color3.fromRGB(100, 120, 255)
LoadBtn.Text = "PRESS TO START"
LoadBtn.TextColor3 = Color3.new(1, 1, 1)
Instance.new("UICorner", LoadBtn).CornerRadius = UDim.new(0, 5)

-- J 鍵控制
UserInputService.InputBegan:Connect(function(i, g)
    if not g and i.KeyCode == Enum.KeyCode.J then Main.Visible = not Main.Visible end
end)

-- [[ 1. 強力 ESP 邏輯 ]]
local function ApplyESP(p)
    if p == LocalPlayer then return end
    
    local function Update()
        local char = p.Character or p.CharacterAdded:Wait()
        -- 刪除舊的
        if char:FindFirstChild("MUMU_Highlight") then char.MUMU_Highlight:Destroy() end
        
        -- 強制建立新的 Highlight
        local h = Instance.new("Highlight")
        h.Name = "MUMU_Highlight"
        h.Parent = char
        h.FillColor = Color3.fromRGB(255, 0, 0)
        h.OutlineColor = Color3.new(1, 1, 1)
        h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        h.Enabled = Settings.ESP
    end
    
    Update()
    p.CharacterAdded:Connect(Update)
end

-- [[ 2. 強制鎖頭邏輯 ]]
local function GetClosest()
    local target = nil
    local dist = Settings.FOV
    
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("Head") then
            -- 檢查活著
            local hum = p.Character:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health > 0 then
                local pos, onScreen = Camera:WorldToViewportPoint(p.Character.Head.Position)
                if onScreen then
                    local mag = (Vector2.new(pos.X, pos.Y) - UserInputService:GetMouseLocation()).Magnitude
                    if mag < dist then
                        dist = mag
                        target = p.Character.Head
                    end
                end
            end
        end
    end
    return target
end

-- [[ 啟動功能 ]]
LoadBtn.MouseButton1Click:Connect(function()
    LoadBtn.Text = "RUNNING..."
    LoadBtn.BackgroundColor3 = Color3.fromRGB(50, 200, 100)
    
    -- 啟動 ESP
    for _, p in pairs(Players:GetPlayers()) do ApplyESP(p) end
    Players.PlayerAdded:Connect(ApplyESP)
    
    -- 啟動鎖頭
    RunService.RenderStepped:Connect(function()
        if Settings.Aimbot and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
            local t = GetClosest()
            if t then
                Camera.CFrame = CFrame.new(Camera.CFrame.Position, t.Position)
            end
        end
    end)
    
    task.wait(1)
    Main.Visible = false
end)

-- 拖曳功能
local d, ds, sp
Main.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then d = true ds = i.Position sp = Main.Position end end)
UserInputService.InputChanged:Connect(function(i) if d and i.UserInputType == Enum.UserInputType.MouseMovement then local delta = i.Position - ds Main.Position = UDim2.new(sp.X.Scale, sp.X.Offset + delta.X, sp.Y.Scale, sp.Y.Offset + delta.Y) end end)
UserInputService.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then d = false end end)
