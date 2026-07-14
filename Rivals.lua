-- ==========================================
-- MUMU PRO V66 - RIVALS 最終分類版
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
        Aimbot = false, WallCheck = true, AimbotSens = 2.0, FOV = 280, StickyAim = true,
        SilentAim = true, RageSnap = false, AutoFire = false,
        Fly = false, FlySpeed = 120, Noclip = false, InfJump = false, SpeedHack = false, WalkSpeed = 105,
    },
    Connections = {},
    CurrentTarget = nil,
    LastTargetUpdate = 0,
    MenuVisible = true
}

local function SafeDestroy()
    pcall(function()
        for _, conn in pairs(MUMU.Connections) do conn:Disconnect() end
    end)
end
SafeDestroy()

-- FOV
local FOVCircle = Drawing.new("Circle")
FOVCircle.Color = Color3.fromRGB(120, 180, 255)
FOVCircle.Thickness = 1.8
FOVCircle.Transparency = 0.75

-- ==================== UI ====================
local SafeGui = (gethui and gethui()) or game:GetService("CoreGui")
pcall(function() SafeGui.MUMU_RIVALS:Destroy() end)

local SG = Instance.new("ScreenGui", SafeGui)
SG.Name = "MUMU_RIVALS"

local Main = Instance.new("Frame", SG)
Main.Size = UDim2.fromOffset(740, 580)
Main.Position = UDim2.fromScale(0.5, 0.5)
Main.AnchorPoint = v2new(0.5, 0.5)
Main.BackgroundColor3 = Color3.fromRGB(15, 16, 20)
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 18)
Instance.new("UIStroke", Main).Color = Color3.fromRGB(90, 140, 255)

local Title = Instance.new("TextLabel", Main)
Title.Size = UDim2.new(1,0,0,75)
Title.BackgroundTransparency = 1
Title.Text = "MUMU PRO V66"
Title.TextColor3 = Color3.new(1,1,1)
Title.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold)
Title.TextSize = 30

local Sidebar = Instance.new("Frame", Main)
Sidebar.Size = UDim2.new(0, 220, 1, -95)
Sidebar.Position = UDim2.new(0, 20, 0, 85)
Sidebar.BackgroundTransparency = 1

local Content = Instance.new("Frame", Main)
Content.Size = UDim2.new(1, -255, 1, -95)
Content.Position = UDim2.new(0, 250, 0, 85)
Content.BackgroundTransparency = 1

local Tabs = {}
local function CreateTab(name, isFirst)
    local btn = Instance.new("TextButton", Sidebar)
    btn.Size = UDim2.new(1, -15, 0, 55)
    btn.BackgroundColor3 = isFirst and Color3.fromRGB(45, 70, 140) or Color3.fromRGB(24, 26, 34)
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
    Instance.new("UIListLayout", page).Padding = UDim.new(0, 18)

    btn.MouseButton1Click:Connect(function()
        for _, t in pairs(Tabs) do
            t.Btn.BackgroundColor3 = Color3.fromRGB(24, 26, 34)
            t.Page.Visible = false
        end
        btn.BackgroundColor3 = Color3.fromRGB(60, 95, 180)
        page.Visible = true
    end)
    table.insert(Tabs, {Btn = btn, Page = page})
    return page
end

local function CreateToggle(parent, text, key)
    local frame = Instance.new("Frame", parent)
    frame.Size = UDim2.new(1, -30, 0, 65)
    frame.BackgroundColor3 = Color3.fromRGB(26, 28, 37)
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 14)

    local lbl = Instance.new("TextLabel", frame)
    lbl.Size = UDim2.new(0.65,0,1,0)
    lbl.Position = UDim2.new(0,25,0,0)
    lbl.Text = text
    lbl.TextColor3 = Color3.new(1,1,1)
    lbl.TextSize = 17
    lbl.BackgroundTransparency = 1

    local toggle = Instance.new("TextButton", frame)
    toggle.Size = UDim2.new(0,72,0,40)
    toggle.Position = UDim2.new(1,-95,0.5,-20)
    toggle.BackgroundColor3 = MUMU.Settings[key] and Color3.fromRGB(85,220,140) or Color3.fromRGB(55,58,65)
    toggle.Text = ""
    Instance.new("UICorner", toggle).CornerRadius = UDim.new(1,0)

    toggle.MouseButton1Click:Connect(function()
        MUMU.Settings[key] = not MUMU.Settings[key]
        toggle.BackgroundColor3 = MUMU.Settings[key] and Color3.fromRGB(85,220,140) or Color3.fromRGB(55,58,65)
    end)
end

-- === 更細的分類 ===
local TabAimbot = CreateTab("🎯 自瞄", true)
CreateToggle(TabAimbot, "自瞄 (開鏡鎖定)", "Aimbot")
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

local TabMovement = CreateTab("🏃 移動", false)
CreateToggle(TabMovement, "飛行模式", "Fly")
CreateToggle(TabMovement, "穿牆模式", "Noclip")
CreateToggle(TabMovement, "無限跳躍", "InfJump")
CreateToggle(TabMovement, "速度加速", "SpeedHack")

-- J 鍵
UIS.InputBegan:Connect(function(i, gp)
    if not gp and i.KeyCode == Enum.KeyCode.J then
        MUMU.MenuVisible = not MUMU.MenuVisible
        Main.Visible = MUMU.MenuVisible
    end
end)

-- ==================== 核心 ====================
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
    pcall(function()
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
end)

MUMU.Connections.Target = RunService.Heartbeat:Connect(function()
    pcall(function()
        if tick() - MUMU.LastTargetUpdate < 0.12 then return end
        MUMU.LastTargetUpdate = tick()

        local best, dist = nil, 700
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("Head") then
                local d = (p.Character.Head.Position - Camera.CFrame.Position).Magnitude
                if d < dist then best = p.Character; dist = d end
            end
        end
        MUMU.CurrentTarget = best
    end)
end)

print("✅ V66 分類修復版載入成功！按 J 鍵開關")
