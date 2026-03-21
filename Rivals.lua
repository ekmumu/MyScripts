-- ==========================================
-- Z3US RIVALS - 專屬優化載入器 (Xeno 優化版)
-- ==========================================

local Settings = {
    Autoload = true,
    Silentload = false,
    -- 這裡放你真正要執行的 RIVALS 腳本網址 (你原本用的是 Test.lua)
    ScriptUrl = "https://raw.githubusercontent.com/blackowl1231/Z3US/refs/heads/main/Games/Test.lua" 
}

local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

-- 確保使用最安全的 UI 容器 (支援 Xeno 等高階執行器)
local SafeGui = (gethui and gethui()) or CoreGui
if SafeGui:FindFirstChild("Z3US_Rivals") then 
    SafeGui.Z3US_Rivals:Destroy() 
end

local ScreenGui = Instance.new("ScreenGui", SafeGui)
ScreenGui.Name = "Z3US_Rivals"

-- [[ UI 建立 ]]
local Main = Instance.new("Frame", ScreenGui)
Main.Size = UDim2.fromOffset(320, 360)
Main.Position = UDim2.fromScale(0.5, 0.5)
Main.AnchorPoint = Vector2.new(0.5, 0.5)
Main.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
Main.BorderSizePixel = 0
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

CreateToggle("Autoload", Settings.Autoload, function(v) Settings.Autoload = v end)
CreateToggle("Silentload", Settings.Silentload, function(v) Settings.Silentload = v end)

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

-- [[ 核心邏輯 ]]
LoadBtn.MouseButton1Click:Connect(function()
    TweenColor(LoadBtn, Color3.fromRGB(100, 120, 255), 0.1)
    LoadBtn.Text = "Loading..."
    
    -- 寫入全域變數
    getgenv().autoload = Settings.Autoload
    getgenv().silentload = Settings.Silentload
    getgenv().SCRIPT_KEY = "" -- 配合你原本的設定
    
    task.spawn(function()
        local success, err = pcall(function()
            loadstring(game:HttpGet(Settings.ScriptUrl))()
        end)
        
        if success then
            TweenColor(LoadBtn, Color3.fromRGB(50, 200, 100), 0.2) -- 成功變綠色
            LoadBtn.Text = "✅ SUCCESS"
            task.wait(1.5)
            ScreenGui:Destroy()
        else
            TweenColor(LoadBtn, Color3.fromRGB(255, 60, 60), 0.2) -- 失敗變紅色
            LoadBtn.Text = "❌ ERROR"
            warn("腳本載入失敗: " .. tostring(err))
            task.wait(2)
            TweenColor(LoadBtn, Color3.fromRGB(45, 45, 50), 0.2)
            LoadBtn.Text = "LOAD SCRIPT"
        end
    end)
end)

CloseBtn.MouseButton1Click:Connect(function() ScreenGui:Destroy() end)

-- [[ 絲滑拖曳功能 ]]
local dragging, dragInput, dragStart, startPos

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
