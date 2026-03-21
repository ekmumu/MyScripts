-- ==========================================
-- MUMU RIVALS - 暴力鎖頭 + 彈道預測版
-- ==========================================

local Settings = {
    ESP = true,
    Aimbot = true,
    FOV = 200,            -- 鎖頭範圍 (圈圈大小)
    Smoothness = 0.05,    -- 強力鎖定！(數值越小，吸得越死)
    Prediction = 0.165,   -- 預判係數 (針對移動目標)
    TeamCheck = false,
    TargetPart = "Head"   -- 想鎖身體可以改成 "HumanoidRootPart"
}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- [[ FOV 視覺化圈圈 ]]
local FOVCircle = Drawing.new("Circle")
FOVCircle.Thickness = 1.5
FOVCircle.Color = Color3.fromRGB(100, 120, 255)
FOVCircle.Transparency = 0.7
FOVCircle.Filled = false
FOVCircle.Visible = true
FOVCircle.Radius = Settings.FOV

-- [[ UI 容器 ]]
local UI_Parent = (gethui and gethui()) or game:GetService("CoreGui")
if UI_Parent:FindFirstChild("MUMU_V2") then UI_Parent.MUMU_V2:Destroy() end

local ScreenGui = Instance.new("ScreenGui", UI_Parent)
ScreenGui.Name = "MUMU_V2"
local Main = Instance.new("Frame", ScreenGui)
Main.Size = UDim2.fromOffset(250, 100)
Main.Position = UDim2.new(0.5, -125, 0, 20)
Main.BackgroundColor3 = Color3.fromRGB(20, 0, 0) -- 暴力紅黑配色
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 10)

local Status = Instance.new("TextLabel", Main)
Status.Size = UDim2.new(1, 0, 1, 0)
Status.Text = "🔥 MUMU GOD MODE\n[J] 隱藏 | [右鍵] 強制鎖定\nPrediction: ON | Rage: MAX"
Status.TextColor3 = Color3.new(1, 1, 1)
Status.BackgroundTransparency = 1
Status.TextSize = 16
Status.Font = Enum.Font.GothamBlack

-- J 鍵開關
UserInputService.InputBegan:Connect(function(i, g)
    if not g and i.KeyCode == Enum.KeyCode.J then 
        Main.Visible = not Main.Visible 
        FOVCircle.Visible = Main.Visible
    end
end)

-- [[ 1. ESP (維持不變) ]]
local function ApplyESP(p)
    p.CharacterAdded:Connect(function(char)
        task.wait(0.5)
        if Settings.ESP then
            local h = Instance.new("Highlight", char)
            h.Name = "MUMU_ESP"
            h.FillColor = Color3.fromRGB(255, 0, 0)
            h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        end
    end)
    if p.Character then
        local h = Instance.new("Highlight", p.Character)
        h.Name = "MUMU_ESP"
        h.FillColor = Color3.fromRGB(255, 0, 0)
        h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    end
end
for _, p in pairs(Players:GetPlayers()) do if p ~= LocalPlayer then ApplyESP(p) end end
Players.PlayerAdded:Connect(ApplyESP)

-- [[ 2. 暴力鎖頭引擎 (帶預判) ]]
local function GetClosestPlayer()
    local target = nil
    local dist = Settings.FOV
    local mousePos = UserInputService:GetMouseLocation()

    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild(Settings.TargetPart) then
            if Settings.TeamCheck and p.Team == LocalPlayer.Team then continue end
            
            local hum = p.Character:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health > 0 then
                local pos, onScreen = Camera:WorldToViewportPoint(p.Character[Settings.TargetPart].Position)
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

RunService.RenderStepped:Connect(function()
    -- 更新圈圈位置
    FOVCircle.Position = UserInputService:GetMouseLocation()
    
    if Settings.Aimbot and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
        local target = GetClosestPlayer()
        if target and target:FindFirstChild(Settings.TargetPart) then
            local targetPart = target[Settings.TargetPart]
            local velocity = target.HumanoidRootPart.Velocity
            
            -- 【核心預判邏輯】預測目標下一刻的位置
            local predictedPosition = targetPart.Position + (velocity * Settings.Prediction)
            
            -- 【強制吸附】
            local lookAt = CFrame.new(Camera.CFrame.Position, predictedPosition)
            Camera.CFrame = Camera.CFrame:Lerp(lookAt, Settings.Smoothness)
        end
    end
end)
