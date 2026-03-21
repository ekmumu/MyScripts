-- ==========================================
-- Z3US RIVALS - 最終整合版 (新增 J 鍵開關)
-- ==========================================

local Settings = {
    Autoload = true,
    Aimbot = true,
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
ScreenGui.ResetOnSpawn = false -- 確保角色死亡 UI 不會消失

-- [[ UI 建立 ]]
local Main = Instance.new("Frame", ScreenGui)
Main.Size = UDim2.fromOffset(320, 420)
Main.Position = UDim2.fromScale(0.5, 0.5)
Main.AnchorPoint = Vector2.new(0.5, 0.5)
Main.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
Main.BorderSizePixel = 0
Main.Visible = true -- 初始設為顯示
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 12)

local Stroke = Instance.new("UIStroke", Main)
Stroke.Color = Color3.fromRGB(100, 120, 255)
Stroke.Thickness = 1.5

-- 標題與關閉按鈕 (略，維持原樣)
local Title = Instance.new("TextLabel", Main)
Title.Size = UDim2.new(1, 0, 0, 50)
Title.BackgroundTransparency = 1
Title.Text = "⚡ Z3US | RIVALS"
Title.TextColor3 = Color3.new(1, 1, 1)
Title.TextSize = 20
Title.Font = Enum.Font.GothamBold

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

-- [[ 功能區: ESP 與 Aimbot (維持原樣) ]]
local function Start_ESP()
    local function Apply(p)
        if p == LocalPlayer then return end
        local function ch(c)
            local h = Instance.new("Highlight", c)
            h.FillColor = Color3.fromRGB(255, 80, 80)
            h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        end
        if p.Character then ch(p.Character) end
        p.CharacterAdded:Connect(ch)
    end
    for _, p in pairs(Players:GetPlayers()) do Apply(p) end
    Players.PlayerAdded:Connect(Apply)
end

local function Start_Aimbot()
    RunService.RenderStepped:Connect(function()
        if Settings.Aimbot and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
            local Target = nil
            local MaxDist = math.huge
            for _, p in pairs(Players:GetPlayers()) do
                if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("Head") then
                    local Pos, OnScreen = Camera:WorldToViewportPoint(p.Character.Head.Position)
                    if OnScreen then
                        local Dist = (Vector2.new(Pos.X, Pos.Y) - UserInputService:GetMouseLocation()).Magnitude
                        if Dist < MaxDist then MaxDist = Dist Target = p.Character.Head end
                    end
                end
            end
            if Target then Camera.CFrame = Camera.CFrame:Lerp(CFrame.new(Camera.CFrame.Position, Target.Position), 0.15) end
        end
    end)
end

-- [[ 核心加載 ]]
LoadBtn.MouseButton1Click:Connect(function()
    LoadBtn.Text = "Loading..."
    if Settings.Autoload then Start_ESP() end
    if Settings.Aimbot then Start_Aimbot() end
    pcall(function() loadstring(game:HttpGet(Settings.ScriptUrl))() end)
    LoadBtn.Text = "✅ SUCCESS (Press J to Hide)"
    task.wait(1.5)
    -- 注意：這裡我們不 Destroy UI，只是把它隱藏，這樣 J 鍵才有用
    Main.Visible = false 
end)

-- [[ ✨ 新增：按鍵開關功能 ]]
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    -- 如果玩家正在聊天框打字，就不觸發快捷鍵
    if gameProcessed then return end
    
    if input.KeyCode == Enum.KeyCode.J then
        Main.Visible = not Main.Visible
    end
end)

-- [[ 絲滑拖曳 (略) ]]
local dragging, dragStart, startPos
Main.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true dragStart = i.Position startPos = Main.Position end end)
UserInputService.InputChanged:Connect(function(i) if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then local d = i.Position - dragStart Main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y) end end)
UserInputService.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end end)
