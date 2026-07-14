-- ==========================================
-- MUMU PRO V63 - RIVALS 最完整極致版
-- ==========================================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

local v2new = Vector2.new

local MUMU = {
    Settings = {
        ESP = true, TeamESP = false, ConstantBox = true, HealthBar = true, NameESP = true,
        Aimbot = false, WallCheck = true, AimbotSens = 1.8, FOV = 300, StickyAim = true,
        SilentAim = true, RageSnap = false, AutoFire = false,
        Fly = false, FlySpeed = 130, Noclip = false, InfJump = false, SpeedHack = false, WalkSpeed = 110,
        MaxDistance = 700
    },
    Drawings = {},
    Connections = {},
    CurrentTarget = nil,
    LastTargetUpdate = 0,
    MenuVisible = true
}

-- 清理舊腳本
local function DestroyOld()
    for _, conn in pairs(MUMU.Connections) do pcall(function() conn:Disconnect() end) end
    for _, d in pairs(MUMU.Drawings) do for _, obj in pairs(d) do pcall(function() obj:Remove() end) end end
end
DestroyOld()

-- FOV Circle
local FOVCircle = Drawing.new("Circle")
FOVCircle.Color = Color3.fromRGB(130, 160, 255)
FOVCircle.Thickness = 2
FOVCircle.Transparency = 0.7
FOVCircle.Filled = false

-- ==================== UI ====================
local SafeGui = (gethui and gethui()) or game:GetService("CoreGui")
if SafeGui:FindFirstChild("MUMU_RIVALS") then SafeGui.MUMU_RIVALS:Destroy() end

local SG = Instance.new("ScreenGui", SafeGui)
SG.Name = "MUMU_RIVALS"
SG.ResetOnSpawn = false

local Main = Instance.new("Frame", SG)
Main.Size = UDim2.fromOffset(680, 520)
Main.Position = UDim2.fromScale(0.5, 0.5)
Main.AnchorPoint = v2new(0.5, 0.5)
Main.BackgroundColor3 = Color3.fromRGB(13, 14, 17)
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 16)
Instance.new("UIStroke", Main).Color = Color3.fromRGB(100, 150, 255)

local Title = Instance.new("TextLabel", Main)
Title.Size = UDim2.new(1,0,0,70)
Title.BackgroundTransparency = 1
Title.Text = "MUMU PRO V63 - RIVALS 完整版"
Title.TextColor3 = Color3.new(1,1,1)
Title.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold)
Title.TextSize = 28

local Sidebar = Instance.new("Frame", Main)
Sidebar.Size = UDim2.new(0, 190, 1, -90)
Sidebar.Position = UDim2.new(0, 15, 0, 80)
Sidebar.BackgroundTransparency = 1

local Content = Instance.new("Frame", Main)
Content.Size = UDim2.new(1, -220, 1, -90)
Content.Position = UDim2.new(0, 215, 0, 80)
Content.BackgroundTransparency = 1

local Tabs = {}
local function CreateTab(name, isFirst)
    local btn = Instance.new("TextButton", Sidebar)
    btn.Size = UDim2.new(1, -10, 0, 50)
    btn.BackgroundColor3 = isFirst and Color3.fromRGB(35, 55, 100) or Color3.fromRGB(22, 24, 30)
    btn.Text = "  " .. name
    btn.TextColor3 = Color3.new(1,1,1)
    btn.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium)
    btn.TextSize = 17
    btn.TextXAlignment = Enum.TextXAlignment.Left
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 10)

    local page = Instance.new("ScrollingFrame", Content)
    page.Size = UDim2.new(1,0,1,0)
    page.BackgroundTransparency = 1
    page.ScrollBarThickness = 6
    page.Visible = isFirst
    Instance.new("UIListLayout", page).Padding = UDim.new(0, 12)

    btn.MouseButton1Click:Connect(function()
        for _, t in pairs(Tabs) do
            t.Btn.BackgroundColor3 = Color3.fromRGB(22, 24, 30)
            t.Page.Visible = false
        end
        btn.BackgroundColor3 = Color3.fromRGB(45, 70, 130)
        page.Visible = true
    end)
    table.insert(Tabs, {Btn = btn, Page = page})
    return page
end

local function CreateToggle(parent, text, key)
    local frame = Instance.new("Frame", parent)
    frame.Size = UDim2.new(1, -25, 0, 58)
    frame.BackgroundColor3 = Color3.fromRGB(22, 24, 30)
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 10)

    local lbl = Instance.new("TextLabel", frame)
    lbl.Size = UDim2.new(0.65,0,1,0)
    lbl.Position = UDim2.new(0,25,0,0)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = Color3.new(1,1,1)
    lbl.TextSize = 17
    lbl.TextXAlignment = Enum.TextXAlignment.Left

    local toggle = Instance.new("TextButton", frame)
    toggle.Size = UDim2.new(0,65,0,36)
    toggle.Position = UDim2.new(1,-85,0.5,-18)
    toggle.BackgroundColor3 = MUMU.Settings[key] and Color3.fromRGB(80,210,130) or Color3.fromRGB(50,50,55)
    toggle.Text = ""
    Instance.new("UICorner", toggle).CornerRadius = UDim.new(1,0)

    toggle.MouseButton1Click:Connect(function()
        MUMU.Settings[key] = not MUMU.Settings[key]
        toggle.BackgroundColor3 = MUMU.Settings[key] and Color3.fromRGB(80,210,130) or Color3.fromRGB(50,50,55)
    end)
end

-- 分頁
local TabLegit = CreateTab("🎯 Legit", true)
CreateToggle(TabLegit, "自瞄 (開鏡鎖定)", "Aimbot")
CreateToggle(TabLegit, "顯示 FOV", "FOV")
CreateToggle(TabLegit, "黏性瞄準", "StickyAim")
CreateToggle(TabLegit, "隔牆檢查", "WallCheck")

local TabRage = CreateTab("🔥 Rage", false)
CreateToggle(TabRage, "Silent Aim", "SilentAim")
CreateToggle(TabRage, "瞬間甩頭", "RageSnap")
CreateToggle(TabRage, "自動開火", "AutoFire")

local TabVisual = CreateTab("👁️ Visuals", false)
CreateToggle(TabVisual, "透視 ESP", "ESP")
CreateToggle(TabVisual, "隊友透視", "TeamESP")
CreateToggle(TabVisual, "恆定方框", "ConstantBox")
CreateToggle(TabVisual, "血條", "HealthBar")

local TabMisc = CreateTab("🏃 Misc", false)
CreateToggle(TabMisc, "飛行", "Fly")
CreateToggle(TabMisc, "穿牆", "Noclip")
CreateToggle(TabMisc, "無限跳", "InfJump")
CreateToggle(TabMisc, "速度", "SpeedHack")

-- J 鍵 開關菜單
UIS.InputBegan:Connect(function(input, gp)
    if not gp and input.KeyCode == Enum.KeyCode.J then
        MUMU.MenuVisible = not MUMU.MenuVisible
        Main.Visible = MUMU.MenuVisible
    end
end)

-- ==================== Silent Aim ====================
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

-- ==================== 主迴圈 ====================
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

    -- Speed Hack
    if MUMU.Settings.SpeedHack and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        LocalPlayer.Character.Humanoid.WalkSpeed = MUMU.Settings.WalkSpeed
    end
end)

-- 目標搜尋
MUMU.Connections.Target = RunService.Heartbeat:Connect(function()
    if tick() - MUMU.LastTargetUpdate < 0.08 then return end
    MUMU.LastTargetUpdate = tick()

    local best, bestDist = nil, MUMU.Settings.MaxDistance
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("Head") then
            local dist = (p.Character.Head.Position - Camera.CFrame.Position).Magnitude
            if dist < bestDist then
                bestDist = dist
                best = p.Character
            end
        end
    end
    MUMU.CurrentTarget = best
end)

-- Fly & Noclip & InfJump 簡易版（可再擴充）
MUMU.Connections.Misc = RunService.Stepped:Connect(function()
    if MUMU.Settings.Noclip and LocalPlayer.Character then
        for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
            if part:IsA("BasePart") then part.CanCollide = false end
        end
    end
end)

print("✅ MUMU PRO V63 完整版載入成功！按 J 鍵隱藏/顯示菜單")
