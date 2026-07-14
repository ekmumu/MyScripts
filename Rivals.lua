-- ==========================================
-- MUMU PRO V64 - RIVALS 美化分類版
-- ==========================================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

local v2new = Vector2.new

local MUMU = {
    Settings = {
        ESP = true, TeamESP = false, ConstantBox = true, HealthBar = true,
        Aimbot = false, WallCheck = true, AimbotSens = 1.8, FOV = 300, StickyAim = true,
        SilentAim = true, RageSnap = false, AutoFire = false,
        Fly = false, FlySpeed = 130, Noclip = false, InfJump = false, SpeedHack = false, WalkSpeed = 110,
        MaxDistance = 700
    },
    Connections = {},
    CurrentTarget = nil,
    LastTargetUpdate = 0,
    MenuVisible = true
}

local function DestroyOld()
    for _, conn in pairs(MUMU.Connections) do pcall(function() conn:Disconnect() end) end
end
DestroyOld()

-- FOV Circle
local FOVCircle = Drawing.new("Circle")
FOVCircle.Color = Color3.fromRGB(120, 180, 255)
FOVCircle.Thickness = 1.8
FOVCircle.Transparency = 0.75

-- ==================== 美化 UI ====================
local SafeGui = (gethui and gethui()) or game:GetService("CoreGui")
if SafeGui:FindFirstChild("MUMU_RIVALS") then SafeGui.MUMU_RIVALS:Destroy() end

local SG = Instance.new("ScreenGui", SafeGui)
SG.Name = "MUMU_RIVALS"

local Main = Instance.new("Frame", SG)
Main.Size = UDim2.fromOffset(720, 560)
Main.Position = UDim2.fromScale(0.5, 0.5)
Main.AnchorPoint = v2new(0.5, 0.5)
Main.BackgroundColor3 = Color3.fromRGB(14, 15, 19)
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 18)

local Gradient = Instance.new("UIGradient", Main)
Gradient.Color = ColorSequence.new{ColorSequenceKeypoint.new(0, Color3.fromRGB(20,22,30)), ColorSequenceKeypoint.new(1, Color3.fromRGB(14,15,19))}

Instance.new("UIStroke", Main).Color = Color3.fromRGB(90, 140, 255)

local Title = Instance.new("TextLabel", Main)
Title.Size = UDim2.new(1,0,0,75)
Title.BackgroundTransparency = 1
Title.Text = "MUMU PRO V64"
Title.TextColor3 = Color3.new(1,1,1)
Title.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold)
Title.TextSize = 30

local Sidebar = Instance.new("Frame", Main)
Sidebar.Size = UDim2.new(0, 210, 1, -95)
Sidebar.Position = UDim2.new(0, 20, 0, 85)
Sidebar.BackgroundTransparency = 1

local Content = Instance.new("Frame", Main)
Content.Size = UDim2.new(1, -245, 1, -95)
Content.Position = UDim2.new(0, 240, 0, 85)
Content.BackgroundTransparency = 1

local Tabs = {}
local function CreateTab(name, isFirst)
    local btn = Instance.new("TextButton", Sidebar)
    btn.Size = UDim2.new(1, -15, 0, 54)
    btn.BackgroundColor3 = isFirst and Color3.fromRGB(40, 65, 130) or Color3.fromRGB(24, 26, 34)
    btn.Text = "   " .. name
    btn.TextColor3 = Color3.new(1,1,1)
    btn.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium)
    btn.TextSize = 17
    btn.TextXAlignment = Enum.TextXAlignment.Left
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 12)

    local page = Instance.new("ScrollingFrame", Content)
    page.Size = UDim2.new(1,0,1,0)
    page.BackgroundTransparency = 1
    page.ScrollBarThickness = 6
    page.Visible = isFirst
    Instance.new("UIListLayout", page).Padding = UDim.new(0, 16)  -- 加大間距

    btn.MouseButton1Click:Connect(function()
        for _, t in pairs(Tabs) do
            t.Btn.BackgroundColor3 = Color3.fromRGB(24, 26, 34)
            t.Page.Visible = false
        end
        btn.BackgroundColor3 = Color3.fromRGB(55, 85, 170)
        page.Visible = true
    end)
    table.insert(Tabs, {Btn = btn, Page = page})
    return page
end

local function CreateToggle(parent, text, key)
    local frame = Instance.new("Frame", parent)
    frame.Size = UDim2.new(1, -30, 0, 64)
    frame.BackgroundColor3 = Color3.fromRGB(26, 28, 37)
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 14)

    local lbl = Instance.new("TextLabel", frame)
    lbl.Size = UDim2.new(0.65,0,1,0)
    lbl.Position = UDim2.new(0, 25, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = Color3.new(1,1,1)
    lbl.TextSize = 17.5
    lbl.TextXAlignment = Enum.TextXAlignment.Left

    local toggle = Instance.new("TextButton", frame)
    toggle.Size = UDim2.new(0, 70, 0, 40)
    toggle.Position = UDim2.new(1, -90, 0.5, -20)
    toggle.BackgroundColor3 = MUMU.Settings[key] and Color3.fromRGB(85, 220, 140) or Color3.fromRGB(55, 58, 65)
    toggle.Text = ""
    Instance.new("UICorner", toggle).CornerRadius = UDim.new(1, 0)

    toggle.MouseButton1Click:Connect(function()
        MUMU.Settings[key] = not MUMU.Settings[key]
        toggle.BackgroundColor3 = MUMU.Settings[key] and Color3.fromRGB(85, 220, 140) or Color3.fromRGB(55, 58, 65)
    end)
end

-- 分類更細
local TabAimbot = CreateTab("🎯 自瞄", true)
CreateToggle(TabAimbot, "開啟自瞄 (開鏡鎖定)", "Aimbot")
CreateToggle(TabAimbot, "黏性瞄準", "StickyAim")
CreateToggle(TabAimbot, "隔牆檢查", "WallCheck")

local TabSilent = CreateTab("🔇 Silent", false)
CreateToggle(TabSilent, "Silent Aim", "SilentAim")
CreateToggle(TabSilent, "瞬間甩頭", "RageSnap")
CreateToggle(TabSilent, "自動開火", "AutoFire")

local TabVisual = CreateTab("👁️ 透視", false)
CreateToggle(TabVisual, "透視 ESP", "ESP")
CreateToggle(TabVisual, "隊友透視", "TeamESP")
CreateToggle(TabVisual, "恆定方框", "ConstantBox")
CreateToggle(TabVisual, "血條", "HealthBar")

local TabMisc = CreateTab("🏃 其他", false)
CreateToggle(TabMisc, "飛行模式", "Fly")
CreateToggle(TabMisc, "穿牆模式", "Noclip")
CreateToggle(TabMisc, "無限跳躍", "InfJump")
CreateToggle(TabMisc, "速度加速", "SpeedHack")

-- J 鍵開關
UIS.InputBegan:Connect(function(i, gp)
    if not gp and i.KeyCode == Enum.KeyCode.J then
        MUMU.MenuVisible = not MUMU.MenuVisible
        Main.Visible = MUMU.MenuVisible
    end
end)

-- ==================== 核心功能 ====================
local OldRaycast
if hookfunction then
    OldRaycast = hookfunction(workspace.Raycast, function(self, origin, direction, params)
        if MUMU.Settings.SilentAim and MUMU.CurrentTarget and MUMU.CurrentTarget:FindFirstChild("Head") then
            local targetPos = MUMU.CurrentTarget.Head.Position
            direction = (targetPos - origin).Unit * direction.Magnitude
        end
        return OldRaycast(self, origin, direction, params)
    end)
end

MUMU.Connections.Render = RunService.RenderStepped:Connect(function()
    FOVCircle.Position = Camera.ViewportSize / 2
    FOVCircle.Radius = MUMU.Settings.FOV
    FOVCircle.Visible = MUMU.Settings.Aimbot

    local isAiming = UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)

    if MUMU.Settings.Aimbot and isAiming and MUMU.CurrentTarget then
        local predPos = MUMU.CurrentTarget.Head.Position
        local screenPos = Camera:WorldToViewportPoint(predPos)
        local center = Camera.ViewportSize / 2
        local delta = (v2new(screenPos.X, screenPos.Y) - center) / MUMU.Settings.AimbotSens
        if mousemoverel then mousemoverel(delta.X, delta.Y) end
    end
end)

MUMU.Connections.Target = RunService.Heartbeat:Connect(function()
    if tick() - MUMU.LastTargetUpdate < 0.1 then return end
    MUMU.LastTargetUpdate = tick()

    local best, dist = nil, MUMU.Settings.MaxDistance
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("Head") then
            local d = (p.Character.Head.Position - Camera.CFrame.Position).Magnitude
            if d < dist then best = p.Character; dist = d end
        end
    end
    MUMU.CurrentTarget = best
end)

print("✅ MUMU PRO V64 分類美化版載入成功！按 J 鍵開關菜單")
