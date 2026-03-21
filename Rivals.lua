-- ==========================================
-- MUMU RIVALS - XENO 輕量優化版
-- ==========================================

local Settings = {
    ESP = true,
    Aimbot = true,
    FOV = 150,           -- 鎖頭範圍
    Smoothness = 0.12,   -- 微調平滑度，適合低速注射器
    TeamCheck = false    -- 預設關閉，確保 Xeno 能偵測到人
}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- [[ UI 容器核心 (相容 Xeno) ]]
local UI_Parent = (gethui and gethui()) or game:GetService("CoreGui")
if UI_Parent:FindFirstChild("MUMU_Xeno") then UI_Parent.MUMU_Xeno:Destroy() end

local ScreenGui = Instance.new("ScreenGui", UI_Parent)
ScreenGui.Name = "MUMU_Xeno"

local Main = Instance.new("Frame", ScreenGui)
Main.Size = UDim2.fromOffset(250, 120)
Main.Position = UDim2.fromScale(0.5, 0.05) -- 改到上方，避免擋住視野
Main.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
Main.BorderSizePixel = 0
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 8)

local Status = Instance.new("TextLabel", Main)
Status.Size = UDim2.new(1, 0, 1, 0)
Status.Text = "⚡ MUMU RIVALS\n[J] 開關 | [右鍵] 鎖頭\nStatus: Running (Xeno)"
Status.TextColor3 = Color3.new(1, 1, 1)
Status.BackgroundTransparency = 1
Status.TextSize = 15
Status.Font = Enum.Font.GothamBold

-- J 鍵開關 (優化偵測)
UserInputService.InputBegan:Connect(function(input, gp)
    if not gp and input.KeyCode == Enum.KeyCode.J then
        Main.Visible = not Main.Visible
    end
end)

-- [[ 1. 優化版 ESP 引擎 ]]
local function CreateESP(player)
    local function Setup(char)
        if not char then return end
        task.wait(0.5) -- 等待角色完全載入，防止 Xeno 抓不到物件
        
        -- 清除舊的
        if char:FindFirstChild("MUMU_ESP") then char.MUMU_ESP:Destroy() end
        
        if Settings.ESP then
            if Settings.TeamCheck and player.Team == LocalPlayer.Team then return end
            
            local highlight = Instance.new("Highlight")
            highlight.Name = "MUMU_ESP"
            highlight.Parent = char
            highlight.FillColor = Color3.fromRGB(255, 50, 50)
            highlight.OutlineColor = Color3.new(1, 1, 1)
            highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        end
    end
    
    player.CharacterAdded:Connect(Setup)
    if player.Character then Setup(player.Character) end
end

-- 初始掃描 & 玩家加入監聽 (比 while 迴圈更省效能)
for _, p in pairs(Players:GetPlayers()) do if p ~= LocalPlayer then CreateESP(p) end end
Players.PlayerAdded:Connect(function(p) if p ~= LocalPlayer then CreateESP(p) end end)

-- [[ 2. 精準鎖頭優化 ]]
local function GetClosestPlayer()
    local target = nil
    local dist = Settings.FOV
    local mousePos = UserInputService:GetMouseLocation()

    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("Head") then
            if Settings.TeamCheck and p.Team == LocalPlayer.Team then continue end
            
            local hum = p.Character:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health > 0 then
                local pos, onScreen = Camera:WorldToViewportPoint(p.Character.Head.Position)
                if onScreen then
                    local mag = (Vector2.new(pos.X, pos.Y) - mousePos).Magnitude
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

RunService.RenderStepped:Connect(function()
    if Settings.Aimbot and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
        local target = GetClosestPlayer()
        if target then
            local goal = CFrame.new(Camera.CFrame.Position, target.Position)
            Camera.CFrame = Camera.CFrame:Lerp(goal, Settings.Smoothness)
        end
    end
end)
