-- [[ 純淨本地版 攻速修改器 (已修正打字錯誤) ]] --

local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")

-- 1. 清除舊介面，避免重複開啟
if CoreGui:FindFirstChild("SafeSpeedUI") then
    CoreGui.SafeSpeedUI:Destroy()
end

-- 2. 建立極簡主視窗 (可拖曳)
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "SafeSpeedUI"
ScreenGui.Parent = CoreGui

local Frame = Instance.new("Frame")
Frame.Size = UDim2.new(0, 220, 0, 120)
Frame.Position = UDim2.new(0.5, -110, 0.5, -60)
Frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
Frame.Active = true
Frame.Draggable = true
Frame.Parent = ScreenGui

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 30)
Title.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Text = "純淨版 攻速修改器 (可拖曳)"
Title.Font = Enum.Font.SourceSansBold
Title.TextSize = 16
Title.Parent = Frame

local TextBox = Instance.new("TextBox")
TextBox.Size = UDim2.new(0.8, 0, 0, 30)
TextBox.Position = UDim2.new(0.1, 0, 0.35, 0)
TextBox.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
TextBox.TextColor3 = Color3.fromRGB(255, 255, 255)
TextBox.Text = "輸入攻速倍率 (例: 5)"
-- ⚠️ 就是這裡！已經修正為正確的 ClearTextOnFocus
TextBox.ClearTextOnFocus = true 
TextBox.Parent = Frame

local Button = Instance.new("TextButton")
Button.Size = UDim2.new(0.8, 0, 0, 30)
Button.Position = UDim2.new(0.1, 0, 0.65, 0)
Button.BackgroundColor3 = Color3.fromRGB(0, 120, 215)
Button.TextColor3 = Color3.fromRGB(255, 255, 255)
Button.Text = "套用攻速"
Button.Font = Enum.Font.SourceSansBold
Button.TextSize = 16
Button.Parent = Frame

-- 3. 核心攻速邏輯
local attackConnection

Button.MouseButton1Click:Connect(function()
    local speedMultiplier = tonumber(TextBox.Text)
    
    -- 防呆機制：如果輸入的不是數字
    if not speedMultiplier then
        Button.Text = "請輸入正確數字!"
        Button.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
        task.wait(1)
        Button.Text = "套用攻速"
        Button.BackgroundColor3 = Color3.fromRGB(0, 120, 215)
        return
    end

    Button.Text = "已啟用: " .. speedMultiplier .. " 倍"
    Button.BackgroundColor3 = Color3.fromRGB(0, 150, 0)

    -- 如果之前有開啟過，先關閉舊的迴圈
    if attackConnection then
        attackConnection:Disconnect()
    end

    -- 啟動後台監聽，動態修改攻速
    attackConnection = RunService.RenderStepped:Connect(function()
        local char = LocalPlayer.Character
        if char then
            local humanoid = char:FindFirstChildOfClass("Humanoid")
            if humanoid then
                local animator = humanoid:FindFirstChildOfClass("Animator")
                if animator then
                    -- 抓取所有正在播放的動畫 (揮刀動作) 並加速
                    for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
                        track:AdjustSpeed(speedMultiplier)
                    end
                end
            end
        end
    end)
end)
