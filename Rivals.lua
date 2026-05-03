-- ==========================================
-- MUMU PRO (V75) - 午夜紫尊爵版 (零報錯 / 預設全關 / 雷射光束)
-- ==========================================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local VIM = game:GetService("VirtualInputManager")
local TweenService = game:GetService("TweenService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

local v2new, v3new = Vector2.new, Vector3.new
local math_clamp, math_abs, math_huge = math.clamp, math.abs, math.huge
local Ray_new = Ray.new

-- ⚡ [核心清理] ⚡
if _G.MUMU_CONN then _G.MUMU_CONN:Disconnect() end
if _G.MUMU_NOCLIP then _G.MUMU_NOCLIP:Disconnect() end
if _G.MUMU_DRAWINGS then for _, d in pairs(_G.MUMU_DRAWINGS) do pcall(function() d.Box:Remove(); d.HealthBg:Remove(); d.HealthBar:Remove() end) end end
if _G.MUMU_FOV_CIRCLE then pcall(function() _G.MUMU_FOV_CIRCLE:Remove() end) end

_G.MUMU_DRAWINGS = {}
_G.CurrentDT = 1/60 
RunService.RenderStepped:Connect(function(dt) _G.CurrentDT = dt end)

_G.MUMU_FOV_CIRCLE = Drawing.new("Circle")
_G.MUMU_FOV_CIRCLE.Color = Color3.fromRGB(168, 85, 247) -- 午夜紫
_G.MUMU_FOV_CIRCLE.Thickness = 1.5
_G.MUMU_FOV_CIRCLE.Filled = false
_G.MUMU_FOV_CIRCLE.Transparency = 0.8
_G.MUMU_FOV_CIRCLE.Visible = false

local Whitelisted = {}

-- 🚀 [所有功能預設全關 (All OFF by Default)] 🚀
local Settings = {
    -- 常規
    Aimbot = false, WallCheck = false, AimbotSens = 1.0, FOV = 250, StickyAim = false, ShowFOV = false, 
    -- 暴力
    SilentAim = false, Wallbang = false, UseDynamicPred = false, BulletSpeed = 3500, RageAutoClick = false,
    -- 神仙
    SkinChanger = false, GodGun = false,
    -- 透視
    ESP = false, TeamESP = false, ConstantBox = false, HealthBar = false, MaxDistance = 1000,
    -- 玩家
    Fly = false, FlySpeed = 100, Noclip = false, SpeedHack = false, WalkSpeed = 100, InfJump = false,
    PingComp = 0.05, StaticPred = 0.12
}

local CurrentStickyTarget = nil
_G.SilentTargetPos = nil
local MUMU_RaycastParams = RaycastParams.new()
MUMU_RaycastParams.FilterType = Enum.RaycastFilterType.Exclude
MUMU_RaycastParams.IgnoreWater = true

-- 🚀 [絕對安全背景引擎 (防報錯神仙修改)] 🚀
task.spawn(function()
    local PremiumSkins = {"Galaxy", "AKEY-47", "Gingerbread AUG", "Phoenix Rifle", "Boneclaw Rifle", "Tommy Gun", "10B Visits", "Dark Matter", "Golden", "Radiant"}
    while task.wait(1.5) do
        if not getgc then continue end
        for _, v in pairs(getgc(true)) do
            if type(v) == "table" then
                -- 全庫解鎖
                if Settings.SkinChanger then
                    if rawget(v, "OwnedWraps") and type(rawget(v, "OwnedWraps")) == "table" then
                        for _, skin in ipairs(PremiumSkins) do rawset(v.OwnedWraps, skin, true) end
                    end
                    if rawget(v, "OwnedWeapons") and type(rawget(v, "OwnedWeapons")) == "table" then
                        for _, skin in ipairs(PremiumSkins) do rawset(v.OwnedWeapons, skin, true) end
                    end
                end
                
                -- 雷射光束 (神槍)
                if Settings.GodGun and rawget(v, "FireRate") and type(rawget(v, "FireRate")) == "number" then
                    rawset(v, "FireRate", 0.001)       -- 極限射速
                    rawset(v, "BulletsPerShot", 20)    -- 瞬間發射20發
                    rawset(v, "Ammo", 9999)            -- 無限子彈
                    rawset(v, "MaxAmmo", 9999)
                    rawset(v, "StoredAmmo", 9999)
                    rawset(v, "Spread", 0)             -- 零擴散 (雷射光束核心)
                    rawset(v, "MaxSpread", 0)
                    rawset(v, "Recoil", 0)             -- 零後座力
                    if rawget(v, "Cooldown") then rawset(v, "Cooldown", 0) end
                end
            end
        end
    end
end)

-- 💎 [全新 Midnight Purple 頂級 UI 介面] 💎
local SafeGui = (gethui and gethui()) or game:GetService("CoreGui")
if SafeGui:FindFirstChild("MUMU_UI") then SafeGui.MUMU_UI:Destroy() end

local SG = Instance.new("ScreenGui", SafeGui); SG.Name = "MUMU_UI"; SG.ResetOnSpawn = false
local Main = Instance.new("Frame", SG); Main.Size = UDim2.fromOffset(640, 460); Main.Position = UDim2.fromScale(0.5, 0.5); Main.AnchorPoint = v2new(0.5, 0.5); Main.BackgroundColor3 = Color3.fromRGB(15, 15, 20); Main.BorderSizePixel = 0
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 12)
local MainStroke = Instance.new("UIStroke", Main); MainStroke.Color = Color3.fromRGB(168, 85, 247); MainStroke.Thickness = 2; MainStroke.Transparency = 0.3

local Title = Instance.new("TextLabel", Main); Title.Size = UDim2.new(1, 0, 0, 60); Title.Position = UDim2.new(0, 25, 0, 0); Title.Text = "MUMU PRO"; Title.TextColor3 = Color3.new(1,1,1); Title.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold); Title.TextSize = 26; Title.BackgroundTransparency = 1; Title.TextXAlignment = Enum.TextXAlignment.Left
local TitleAccent = Instance.new("TextLabel", Title); TitleAccent.Size = UDim2.new(1, 0, 1, 0); TitleAccent.Position = UDim2.new(0, 165, 0, 0); TitleAccent.Text = "PREMIUM"; TitleAccent.TextColor3 = Color3.fromRGB(168, 85, 247); TitleAccent.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Heavy); TitleAccent.TextSize = 26; TitleAccent.BackgroundTransparency = 1; TitleAccent.TextXAlignment = Enum.TextXAlignment.Left
local Divider = Instance.new("Frame", Main); Divider.Size = UDim2.new(1, 0, 0, 1); Divider.Position = UDim2.new(0, 0, 0, 60); Divider.BackgroundColor3 = Color3.fromRGB(35, 35, 45); Divider.BorderSizePixel = 0

local Sidebar = Instance.new("Frame", Main); Sidebar.Size = UDim2.new(0, 160, 1, -70); Sidebar.Position = UDim2.new(0, 15, 0, 70); Sidebar.BackgroundTransparency = 1; Instance.new("UIListLayout", Sidebar).Padding = UDim.new(0, 10)
local ContentArea = Instance.new("Frame", Main); ContentArea.Size = UDim2.new(1, -195, 1, -70); ContentArea.Position = UDim2.new(0, 185, 0, 70); ContentArea.BackgroundTransparency = 1

local Tabs = {}
local function CreateTab(name, icon, isFirst)
    local btn = Instance.new("TextButton", Sidebar); btn.Size = UDim2.new(1, 0, 0, 42); btn.Text = "   " .. icon .. "   " .. name; btn.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium); btn.TextSize = 15; btn.TextColor3 = Color3.fromRGB(160, 160, 175); btn.TextXAlignment = Enum.TextXAlignment.Left; btn.BackgroundColor3 = Color3.fromRGB(22, 22, 28); btn.BackgroundTransparency = 1; Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
    local page = Instance.new("ScrollingFrame", ContentArea); page.Size = UDim2.new(1, 0, 1, -10); page.BackgroundTransparency = 1; page.ScrollBarThickness = 4; page.ScrollBarImageColor3 = Color3.fromRGB(168, 85, 247); page.Visible = isFirst; page.CanvasSize = UDim2.new(0,0,1.8,0); Instance.new("UIListLayout", page).Padding = UDim.new(0, 12)
    
    if isFirst then btn.BackgroundTransparency = 0; btn.TextColor3 = Color3.new(1,1,1) end
    btn.MouseButton1Click:Connect(function() 
        for _, t in pairs(Tabs) do TweenService:Create(t.Btn, TweenInfo.new(0.3), {BackgroundTransparency = 1, TextColor3 = Color3.fromRGB(160, 160, 175)}):Play(); t.Page.Visible = false end
        TweenService:Create(btn, TweenInfo.new(0.3), {BackgroundTransparency = 0, TextColor3 = Color3.new(1,1,1)}):Play(); page.Visible = true 
    end)
    table.insert(Tabs, {Btn = btn, Page = page}); return page
end

local function CreateToggle(parent, name, key)
    local frame = Instance.new("Frame", parent); frame.Size = UDim2.new(1, -15, 0, 50); frame.BackgroundColor3 = Color3.fromRGB(22, 22, 28); Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8); Instance.new("UIStroke", frame).Color = Color3.fromRGB(40, 40, 50)
    local lbl = Instance.new("TextLabel", frame); lbl.Size = UDim2.new(0.75, 0, 1, 0); lbl.Position = UDim2.new(0, 20, 0, 0); lbl.Text = name; lbl.TextColor3 = Color3.new(1,1,1); lbl.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium); lbl.TextSize = 14; lbl.BackgroundTransparency = 1; lbl.TextXAlignment = Enum.TextXAlignment.Left
    local btn = Instance.new("TextButton", frame); btn.Size = UDim2.new(0, 48, 0, 24); btn.Position = UDim2.new(1, -65, 0.5, -12); btn.Text = ""; btn.BackgroundColor3 = Color3.fromRGB(45, 45, 55); Instance.new("UICorner", btn).CornerRadius = UDim.new(1, 0)
    local circle = Instance.new("Frame", btn); circle.Size = UDim2.new(0, 18, 0, 18); circle.Position = UDim2.new(0, 3, 0.5, -9); circle.BackgroundColor3 = Color3.new(1,1,1); Instance.new("UICorner", circle).CornerRadius = UDim.new(1, 0)
    
    local function update(anim)
        local bgGoal = Settings[key] and Color3.fromRGB(168, 85, 247) or Color3.fromRGB(45, 45, 55)
        local circleGoal = Settings[key] and UDim2.new(1, -21, 0.5, -9) or UDim2.new(0, 3, 0.5, -9)
        if anim then TweenService:Create(btn, TweenInfo.new(0.25, Enum.EasingStyle.Quad), {BackgroundColor3 = bgGoal}):Play(); TweenService:Create(circle, TweenInfo.new(0.25, Enum.EasingStyle.Quad), {Position = circleGoal}):Play()
        else btn.BackgroundColor3 = bgGoal; circle.Position = circleGoal end
    end
    update(false)
    btn.MouseButton1Click:Connect(function() Settings[key] = not Settings[key]; update(true) end)
end

local function CreateSlider(parent, name, key, min, max)
    local frame = Instance.new("Frame", parent); frame.Size = UDim2.new(1, -15, 0, 60); frame.BackgroundColor3 = Color3.fromRGB(22, 22, 28); Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8); Instance.new("UIStroke", frame).Color = Color3.fromRGB(40, 40, 50)
    local lbl = Instance.new("TextLabel", frame); lbl.Size = UDim2.new(0.6, 0, 0.5, 0); lbl.Position = UDim2.new(0, 20, 0, 5); lbl.Text = name; lbl.TextColor3 = Color3.new(1,1,1); lbl.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium); lbl.TextSize = 14; lbl.BackgroundTransparency = 1; lbl.TextXAlignment = Enum.TextXAlignment.Left
    local val = Instance.new("TextLabel", frame); val.Size = UDim2.new(0, 30, 0.5, 0); val.Position = UDim2.new(1, -50, 0, 5); val.Text = tostring(Settings[key]); val.TextColor3 = Color3.fromRGB(168, 85, 247); val.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold); val.TextSize = 14; val.BackgroundTransparency = 1; val.TextXAlignment = Enum.TextXAlignment.Right
    local track = Instance.new("Frame", frame); track.Size = UDim2.new(1, -40, 0, 6); track.Position = UDim2.new(0, 20, 1, -18); track.BackgroundColor3 = Color3.fromRGB(35, 35, 45); Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)
    local fill = Instance.new("Frame", track); fill.Size = UDim2.new((Settings[key]-min)/(max-min), 0, 1, 0); fill.BackgroundColor3 = Color3.fromRGB(168, 85, 247); Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)
    local btn = Instance.new("TextButton", track); btn.Size = UDim2.new(1, 0, 0, 24); btn.Position = UDim2.new(0, 0, 0.5, -12); btn.BackgroundTransparency = 1; btn.Text = ""
    local dragging = false
    btn.MouseButton1Down:Connect(function() dragging = true end); UIS.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end end)
    UIS.InputChanged:Connect(function(i) if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then local pct = math_clamp((i.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1); fill.Size = UDim2.new(pct, 0, 1, 0); Settings[key] = math.floor((min + (max - min) * pct) * 10)/10; val.Text = tostring(Settings[key]) end end)
end

-- UI 構建
local TabRage = CreateTab("暴力神權", "🔥", true)
CreateToggle(TabRage, "💎 遊戲全庫解鎖 (Skin/Wrap)", "SkinChanger")
CreateToggle(TabRage, "🔫 終極雷射光束 (無限子彈+0後座)", "GodGun")
CreateToggle(TabRage, "🚀 穿牆魔術彈 (Wallbang)", "Wallbang")
CreateToggle(TabRage, "🎯 360 靜默拐彎 (Silent Aim)", "SilentAim")
CreateToggle(TabRage, "開鏡自動連發 (Auto Click)", "RageAutoClick")

local TabLegit = CreateTab("常規自瞄", "🎯", false)
CreateToggle(TabLegit, "啟用常規自瞄 (Aimbot)", "Aimbot")
CreateToggle(TabLegit, "顯示 FOV 自瞄圈", "ShowFOV")
CreateToggle(TabLegit, "隔牆不瞄準 (Wall Check)", "WallCheck")
CreateToggle(TabLegit, "啟用黏性瞄準 (Sticky Aim)", "StickyAim")
CreateSlider(TabLegit, "自瞄平滑度 (1.0=絕對死鎖)", "AimbotSens", 1.0, 10.0) 
CreateSlider(TabLegit, "自瞄範圍 (FOV)", "FOV", 50, 800)

local TabVisuals = CreateTab("視覺透視", "👁️", false)
CreateToggle(TabVisuals, "開啟方框透視 (ESP)", "ESP")
CreateToggle(TabVisuals, "顯示綠色血條 (Health Bar)", "HealthBar")

local TabPlayer = CreateTab("玩家控制", "🏃", false)
CreateToggle(TabPlayer, "無限制飛行 (Fly)", "Fly")
CreateSlider(TabPlayer, "飛行速度", "FlySpeed", 20, 300)
CreateToggle(TabPlayer, "加速模式 (Speed Hack)", "SpeedHack")
CreateSlider(TabPlayer, "移動速度", "WalkSpeed", 16, 300)

-- UI 拖曳 & J鍵隱藏
local draggingUI, dragInput, dragStart, startPos
Main.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then draggingUI = true; dragStart = i.Position; startPos = Main.Position end end)
Main.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then draggingUI = false end end)
UIS.InputChanged:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseMovement then dragInput = i end end)
RunService.RenderStepped:Connect(function() if draggingUI and dragInput then local delta = dragInput.Position - dragStart; Main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y) end end)
UIS.InputBegan:Connect(function(i, gp) if not gp and i.KeyCode == Enum.KeyCode.J then Main.Visible = not Main.Visible end end)

-- ⚡ [完美攔截器：子彈絕對拐彎 (⚠️ 已刪除導致報錯的 Mouse Hook)] ⚡
if hookmetamethod then
    local OldNC
    OldNC = hookmetamethod(game, "__namecall", function(self, ...)
        local m = getnamecallmethod()
        local a = {...}
        if not checkcaller() and Settings.SilentAim and _G.SilentTargetPos then
            if m == "Raycast" and typeof(a[2]) == "Vector3" then 
                a[2] = (_G.SilentTargetPos - a[1]).Unit * 5000
                return OldNC(self, unpack(a)) 
            elseif (m == "FindPartOnRay" or m == "FindPartOnRayWithIgnoreList") and typeof(a[1]) == "Ray" then
                a[1] = Ray_new(a[1].Origin, (_G.SilentTargetPos - a[1].Origin).Unit * 5000)
                return OldNC(self, unpack(a)) 
            end
        end
        return OldNC(self, ...)
    end)
end

-- ⚡ [遊戲邏輯與改良版預判] ⚡
local function GetHealth(c)
    if not c then return 0, 100 end
    local hp, mx = 0, 100
    local hum = c:FindFirstChild("Humanoid")
    if hum then hp = tonumber(hum.Health) or 0; mx = tonumber(hum.MaxHealth) or 100 end
    return math_clamp(hp, 0, mx), mx
end

local function IsTeammate(p)
    if p == LocalPlayer or Whitelisted[p.UserId] then return true end
    if not Settings.TeamESP then return false end
    return false
end

local function GetPred(tChar)
    if not tChar or not tChar:FindFirstChild("Head") or not tChar:FindFirstChild("HumanoidRootPart") then return nil end
    local hp = tChar.Head.Position
    local vel = tChar.HumanoidRootPart.Velocity
    local safeVel = v3new(vel.X, vel.Y * 0.3, vel.Z) 
    local mp = Camera.CFrame.Position
    if Settings.UseDynamicPred then return hp + (safeVel * (((hp - mp).Magnitude / Settings.BulletSpeed) + Settings.PingComp + _G.CurrentDT))
    else return hp + (safeVel * Settings.StaticPred) end
end

local function IsVisible(targetPos)
    if not Settings.WallCheck or not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("Head") then return true end
    MUMU_RaycastParams.FilterDescendantsInstances = {LocalPlayer.Character, Camera}
    return not workspace:Raycast(Camera.CFrame.Position, targetPos - Camera.CFrame.Position, MUMU_RaycastParams)
end

local function FireWeapon() if mouse1click then pcall(mouse1click) else VIM:SendMouseButtonEvent(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2, 0, true, game, 1); task.wait(0.01); VIM:SendMouseButtonEvent(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2, 0, false, game, 1) end end

local lastFire = 0
local FlyBodyGyro, FlyBodyVelocity, CONTROL = nil, nil, {F=0, B=0, L=0, R=0, UP=0, DOWN=0}
UIS.InputBegan:Connect(function(i, gp) if not gp then local k=i.KeyCode; if k==Enum.KeyCode.W then CONTROL.F=1 elseif k==Enum.KeyCode.S then CONTROL.B=-1 elseif k==Enum.KeyCode.A then CONTROL.L=-1 elseif k==Enum.KeyCode.D then CONTROL.R=1 elseif k==Enum.KeyCode.Space then CONTROL.UP=1 elseif k==Enum.KeyCode.LeftControl then CONTROL.DOWN=-1 end end end)
UIS.InputEnded:Connect(function(i) local k=i.KeyCode; if k==Enum.KeyCode.W then CONTROL.F=0 elseif k==Enum.KeyCode.S then CONTROL.B=0 elseif k==Enum.KeyCode.A then CONTROL.L=0 elseif k==Enum.KeyCode.D then CONTROL.R=0 elseif k==Enum.KeyCode.Space then CONTROL.UP=0 elseif k==Enum.KeyCode.LeftControl then CONTROL.DOWN=0 end end)

-- ⚡ [極限防禦渲染引擎] ⚡
_G.MUMU_CONN = RunService.RenderStepped:Connect(function()
    if _G.MUMU_FOV_CIRCLE then
        _G.MUMU_FOV_CIRCLE.Position = Camera.ViewportSize / 2
        _G.MUMU_FOV_CIRCLE.Radius = Settings.FOV
        _G.MUMU_FOV_CIRCLE.Visible = Settings.Aimbot and Settings.ShowFOV
    end

    if LocalPlayer.Character then
        if Settings.Fly and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            local hrp = LocalPlayer.Character.HumanoidRootPart
            if not hrp:FindFirstChild("MUMU_GYRO") then FlyBodyGyro=Instance.new("BodyGyro", hrp); FlyBodyGyro.Name="MUMU_GYRO"; FlyBodyGyro.P=9e4; FlyBodyGyro.maxTorque=v3new(9e9,9e9,9e9); FlyBodyVelocity=Instance.new("BodyVelocity", hrp); FlyBodyVelocity.Name="MUMU_VELOCITY"; FlyBodyVelocity.maxForce=v3new(9e9,9e9,9e9) end
            FlyBodyGyro.cframe = Camera.CFrame; FlyBodyVelocity.velocity = ((Camera.CFrame.LookVector*(CONTROL.F+CONTROL.B)) + (Camera.CFrame.RightVector*(CONTROL.L+CONTROL.R)) + (Camera.CFrame.UpVector*(CONTROL.UP+CONTROL.DOWN))).Magnitude > 0 and ((Camera.CFrame.LookVector*(CONTROL.F+CONTROL.B)) + (Camera.CFrame.RightVector*(CONTROL.L+CONTROL.R)) + (Camera.CFrame.UpVector*(CONTROL.UP+CONTROL.DOWN))).Unit * Settings.FlySpeed or v3new(0,0,0)
            if LocalPlayer.Character:FindFirstChild("Humanoid") then LocalPlayer.Character.Humanoid.PlatformStand = true end
        elseif LocalPlayer.Character:FindFirstChild("HumanoidRootPart") and LocalPlayer.Character.HumanoidRootPart:FindFirstChild("MUMU_GYRO") then
            LocalPlayer.Character.HumanoidRootPart.MUMU_GYRO:Destroy(); LocalPlayer.Character.HumanoidRootPart.MUMU_VELOCITY:Destroy()
            if LocalPlayer.Character:FindFirstChild("Humanoid") then LocalPlayer.Character.Humanoid.PlatformStand = false end
        end
        if Settings.SpeedHack and LocalPlayer.Character:FindFirstChild("Humanoid") then LocalPlayer.Character.Humanoid.WalkSpeed = Settings.WalkSpeed end
    end

    local myPos = Camera.CFrame.Position
    local screenCenter = Camera.ViewportSize / 2
    local isRC = UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
    
    local bestAimbotTarget, bestAimbotDist = nil, Settings.FOV
    local bestSilentTarget, bestSilentDist = nil, Settings.MaxDistance

    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            if not _G.MUMU_DRAWINGS[p] then _G.MUMU_DRAWINGS[p] = { Box = Drawing.new("Square"), HealthBg = Drawing.new("Line"), HealthBar = Drawing.new("Line") }; local d = _G.MUMU_DRAWINGS[p]; d.Box.Color = Color3.fromRGB(168, 85, 247); d.Box.Thickness = 1.5; d.Box.Filled = false; d.HealthBg.Color = Color3.fromRGB(0,0,0); d.HealthBg.Thickness = 4; d.HealthBar.Thickness = 2 end
            local d = _G.MUMU_DRAWINGS[p]; local char = p.Character
            
            if char and char:FindFirstChild("HumanoidRootPart") and char:FindFirstChild("Head") then
                local hp, maxHp = GetHealth(char)
                if hp > 0 and not IsTeammate(p) then
                    local hrp = char.HumanoidRootPart; local headPos = char.Head.Position; local dist3D = (hrp.Position - myPos).Magnitude
                    
                    if dist3D < Settings.MaxDistance then
                        if Settings.ESP then
                            local topPos, onScreen = Camera:WorldToViewportPoint(hrp.Position + v3new(0, 2.5, 0))
                            if onScreen then
                                local bottomPos = Camera:WorldToViewportPoint(hrp.Position - v3new(0, 3, 0)); local centerPos = Camera:WorldToViewportPoint(hrp.Position)
                                local height, width; if Settings.ConstantBox then width, height = 30, 45 else height = math_abs(topPos.Y - bottomPos.Y); width = height * 0.6 end
                                d.Box.Size = v2new(width, height); d.Box.Position = v2new(centerPos.X - width/2, centerPos.Y - height/2); d.Box.Visible = true
                                if Settings.HealthBar then
                                    local pct = math_clamp(hp/maxHp, 0, 1); local barX, barYBottom, barYTop = centerPos.X - width/2 - 6, centerPos.Y + height/2, centerPos.Y - height/2
                                    d.HealthBg.From = v2new(barX, barYBottom); d.HealthBg.To = v2new(barX, barYTop); d.HealthBg.Visible = true
                                    d.HealthBar.From = v2new(barX, barYBottom); d.HealthBar.To = v2new(barX, barYBottom - (height * pct)); d.HealthBar.Color = Color3.fromRGB(168, 85, 247); d.HealthBar.Visible = true
                                else d.HealthBg.Visible = false; d.HealthBar.Visible = false end
                            else d.Box.Visible = false; d.HealthBg.Visible = false; d.HealthBar.Visible = false end
                        else d.Box.Visible = false; d.HealthBg.Visible = false; d.HealthBar.Visible = false end
                        
                        local checkVis, dCenter, os2 = false, nil, false
                        if Settings.SilentAim and dist3D < bestSilentDist then checkVis = true end
                        if Settings.Aimbot then
                            local sp; sp, os2 = Camera:WorldToViewportPoint(headPos)
                            if os2 then dCenter = (v2new(sp.X, sp.Y) - screenCenter).Magnitude; if dCenter < bestAimbotDist then checkVis = true end end
                        end

                        local isTargetVisible = Settings.Wallbang or IsVisible(headPos)
                        if checkVis and isTargetVisible then
                            if Settings.SilentAim and dist3D < bestSilentDist then bestSilentDist = dist3D; bestSilentTarget = char end
                            if Settings.Aimbot and os2 and dCenter < bestAimbotDist then bestAimbotDist = dCenter; bestAimbotTarget = char end
                        end
                    else d.Box.Visible = false; d.HealthBg.Visible = false; d.HealthBar.Visible = false end
                else d.Box.Visible = false; d.HealthBg.Visible = false; d.HealthBar.Visible = false end
            else d.Box.Visible = false; d.HealthBg.Visible = false; d.HealthBar.Visible = false end
        end
    end

    _G.SilentTarget = bestSilentTarget
    if Settings.SilentAim and bestSilentTarget then _G.SilentTargetPos = GetPred(bestSilentTarget) else _G.SilentTargetPos = nil end

    if Settings.Aimbot then
        if Settings.StickyAim and CurrentStickyTarget then
            local hp, _ = GetHealth(CurrentStickyTarget)
            if hp <= 0 or not CurrentStickyTarget:FindFirstChild("Head") or not (Settings.Wallbang or IsVisible(CurrentStickyTarget.Head.Position)) or not isRC then CurrentStickyTarget = nil end
        end
        if not CurrentStickyTarget and isRC then CurrentStickyTarget = bestAimbotTarget end
        local activeTarget = (Settings.StickyAim and CurrentStickyTarget) or bestAimbotTarget
        
        if activeTarget and isRC then
            local fp = GetPred(activeTarget)
            if fp then 
                local sp, os = Camera:WorldToViewportPoint(fp)
                if os and mousemoverel then 
                    local deltaX = sp.X - screenCenter.X; local deltaY = sp.Y - screenCenter.Y
                    if Settings.AimbotSens <= 1.1 then mousemoverel(deltaX, deltaY) else mousemoverel(deltaX / Settings.AimbotSens, deltaY / Settings.AimbotSens) end
                end 
            end
        end
    else CurrentStickyTarget = nil end

    if Settings.SilentAim and Settings.RageAutoClick and isRC and _G.SilentTarget and tick() - lastFire > 0.05 then FireWeapon(); lastFire = tick() end
end)
