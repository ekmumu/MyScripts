-- ==========================================
-- Z3US RIVALS - 專屬優化載入器 (內建強化 ESP + Aimbot + J鍵隱藏)
-- ==========================================

local Settings = {
    ESP = true,
    Aimbot = true,
    FOV = 150,           -- 鎖頭範圍大小 (避免亂轉)
    Smoothness = 0.15,   -- 鎖頭平滑度 (越小越順，像真人)
    TeamCheck = true,    -- 開啟隊友過濾
    ScriptUrl = "https://raw.githubusercontent.com/ekmumu/MyScripts/refs/heads/main/Rivals.lua" 
}

local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- 確保使用最安全的 UI 容器
local SafeGui = (gethui and gethui()) or CoreGui
if SafeGui:FindFirstChild("Z3US_Rivals") then 
    SafeGui.Z3US_Rivals:Destroy() 
end

local ScreenGui = Instance.new("ScreenGui", SafeGui)
ScreenGui.Name = "Z3US_Rivals"
ScreenGui.ResetOnSpawn = false -- 確保玩家死亡重生時，UI 不會消失

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

-- 標題列
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

-- 內容排版
local Content = Instance.new("Frame", Main)
Content.Size = UDim2.new(0.9, 0, 0.75, 0)
Content.Position = UDim2.fromScale(0.05, 0.16)
Content.BackgroundTransparency = 1

local Layout = Instance.new("UIListLayout", Content)
Layout.Padding = UDim.new(0, 12)
Layout.HorizontalAlignment = Enum.HorizontalAlignment.Center

-- 動畫輔助函數
local function TweenColor(obj, targetColor, duration)
    TweenService:Create(obj, TweenInfo.new(duration or 0.2), {BackgroundColor3 = targetColor}):Play()
end

-- [[ 開關按鈕產生器 ]]
local function CreateToggle(text, defaultValue, callback)
    local Enabled = defaultValue
    local ColorOn = Color3.fromRGB(100, 120, 255)
    local ColorOff = Color3.fromRGB(35, 35, 40)
    
    local Btn = Instance.new("TextButton", Content)
    Btn.Size = UDim2.new(1, 0, 0, 45)
    Btn.BackgroundColor3 = Enabled and ColorOn or ColorOff
    Btn.Text = "  " .. text .. ": " .. (Enabled and "ON" or "OFF")
    Btn.TextColor3 = Color3.new(1, 1, 1)
    Btn.Font = Enum.Font.GothamSemibold
    Btn.TextSize = 15
    Btn.AutoButtonColor = false
    Instance.new("UICorner", Btn).CornerRadius = UDim.new(0, 8)
    
    Btn.MouseButton1Click:Connect(function()
        Enabled = not Enabled
        TweenColor(Btn, Enabled and ColorOn or ColorOff, 0.2)
        Btn.Text = "  " .. text .. ": " .. (Enabled and "ON" or "OFF")
        callback(Enabled)
    end)
end

CreateToggle("ESP (透視)", Settings.ESP, function(v) Settings.ESP = v end)
CreateToggle("Aimbot (鎖頭)", Settings.Aimbot, function(v) Settings.Aimbot = v end)

-- [[ 載入按鈕 ]]
local LoadBtn = Instance.new("TextButton", Content)
LoadBtn.Size = UDim2.new(1, 0, 0, 55)
LoadBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
LoadBtn.Text = "LOAD SCRIPT"
LoadBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
LoadBtn.Font = Enum.Font.GothamBlack
LoadBtn.TextSize = 16
LoadBtn.AutoButtonColor = false
Instance.new("UICorner", LoadBtn).CornerRadius = UDim.new(0, 8)

LoadBtn.MouseEnter:Connect(function() TweenColor(LoadBtn, Color3.fromRGB(60, 60, 65), 0.2) end)
LoadBtn.MouseLeave:Connect(function() TweenColor(LoadBtn, Color3.fromRGB(45, 45, 50), 0.2) end)

-- ==========================================
-- 內建強化功能區 (ESP + Aimbot)
-- ==========================================

-- 1. 強化版透視 (循環掃描，防止消失)
local function Start_ESP()
    task.spawn(function()
        while task.wait(1) do -- 每秒檢查一次
            if Settings.ESP then
                for _, p in pairs(Players:GetPlayers()) do
                    if p ~= Players.LocalPlayer and p.Character then
                        -- 隊友判斷
                        if Settings.TeamCheck and p.Team == Players.LocalPlayer.Team then
                            if p.Character:FindFirstChild("Z3US_ESP") then 
                                p.Character.Z3US_ESP:Destroy() 
                            end
                        else
                            -- 如果敵人身上沒有透視，就幫他加上去
                            if not p.Character:FindFirstChild("Z3US_ESP") then
                                local h = Instance.new("Highlight")
                                h.Name = "Z3US_ESP"
                                h.Parent = p.Character
                                h.FillColor = Color3.fromRGB(255, 50, 50) -- 紅色
                                h.OutlineColor = Color3.new(1, 1, 1)      -- 白邊
                                h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                            end
                        end
                    end
                end
            else
                -- 如果關閉 ESP，清除所有透視
                for _, p in pairs(Players:GetPlayers()) do
                    if p.Character and p.Character:FindFirstChild("Z3US_ESP") then
                        p.Character.Z3US_ESP:Destroy()
                    end
                end
            end
        end
    end)
end

-- 2. 平滑鎖頭 (右鍵觸發)
local function Start_Aimbot()
    RunService.RenderStepped:Connect(function()
        local Camera = workspace.CurrentCamera
        -- 判斷是否開啟鎖頭 且 按住滑鼠右鍵
        if Settings.Aimbot and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
            local ClosestTarget = nil
            local MaxDist = Settings.FOV
            local MousePos = UserInputService:GetMouseLocation()

            for _, p in pairs(Players:GetPlayers()) do
                if p ~= Players.LocalPlayer and p.Character and p.Character:FindFirstChild("Head") then
                    if Settings.TeamCheck and p.Team == Players.LocalPlayer.Team then continue end
                    
                    -- 檢查敵人是否活著
                    local hum = p.Character:FindFirstChildOfClass("Humanoid")
                    if hum and hum.Health <= 0 then continue end

                    local Pos, OnScreen = Camera:WorldToViewportPoint(p.Character.Head.Position)
                    if OnScreen then
                        local Dist = (Vector2.new(Pos.X, Pos.Y) - MousePos).Magnitude
                        if Dist < MaxDist then
                            MaxDist = Dist
                            ClosestTarget = p.Character.Head
                        end
                    end
                end
            end

            -- 執行平滑視角轉動
            if ClosestTarget then
                Camera.CFrame = Camera.CFrame:Lerp(CFrame.new(Camera.CFrame.Position, ClosestTarget.Position), Settings.Smoothness)
            end
        end
    end)
end

-- ==========================================
-- 核心邏輯與按鍵事件
-- ==========================================

LoadBtn.MouseButton1Click:Connect(function()
    TweenColor(LoadBtn, Color3.fromRGB(100, 120, 255), 0.1)
    LoadBtn.Text = "Loading..."
    
    -- 啟動內建功能
    Start_ESP()
    Start_Aimbot()
    
    task.spawn(function()
        -- 嘗試從外部載入額外腳本
        local success, err = pcall(function()
            loadstring(game:HttpGet(Settings.ScriptUrl))()
        end)
        
        if success then
            TweenColor(LoadBtn, Color3.fromRGB(50, 200, 100), 0.2)
            LoadBtn.Text = "✅ SUCCESS [Press J to Hide]"
        else
            TweenColor(LoadBtn, Color3.fromRGB(50, 200, 100), 0.2)
            LoadBtn.Text = "✅ READY [Press J to Hide]"
            warn("外部腳本無效，但內建透視/鎖頭已啟動: " .. tostring(err))
        end
        
        task.wait(1.5)
        -- 注意：改成隱藏，不要 Destroy，這樣按 J 才能叫回來
        Main.Visible = false 
    end)
end)

-- [[ ✨ 新增: J 鍵隱藏/顯示功能 ]]
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    -- 如果玩家正在聊天框打字，就不會觸發
    if gameProcessed then return end
    
    if input.KeyCode == Enum.KeyCode.J then
        Main.Visible = not Main.Visible
    end
end)

-- 關閉按鈕現在也是隱藏，而不是徹底刪除
CloseBtn.MouseButton1Click:Connect(function() 
    Main.Visible = false 
end)

-- [[ 絲滑拖曳功能 ]]
local dragging, dragStart, startPos
Main.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = Main.Position
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - dragStart
        Main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end)
