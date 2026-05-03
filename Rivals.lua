-- ==========================================
-- MUMU PRO (V72) - 尊爵防崩潰版 (Premium UI + Safe Hook)
-- ==========================================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local VIM = game:GetService("VirtualInputManager")
local TweenService = game:GetService("TweenService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- ⚡ [局部變數快取] ⚡
local v2new, v3new = Vector2.new, Vector3.new
local math_clamp, math_abs, math_huge = math.clamp, math.abs, math.huge
local CFrame_new = CFrame.new
local Ray_new = Ray.new

-- ⚡ [核心清理與變數] ⚡
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
local Settings = {
    -- 常規自瞄
    Aimbot = false, WallCheck = true, AimbotSens = 1.0, FOV = 250, StickyAim = true, ShowFOV = true, 
    -- 暴力功能
    SilentAim = false, Wallbang = false, UseDynamicPred = true, BulletSpeed = 3500, RageAutoClick = false,
    -- 付費級神仙功能
    UnlockSkins = false, GodGun = false,
    -- 透視與玩家
    ESP = true, TeamESP = true, ConstantBox = true, HealthBar = true, MaxDistance = 1000,
    Fly = false, FlySpeed = 100, Noclip = false, SpeedHack = false, WalkSpeed = 100, InfJump = false,
    PingComp = 0.05, StaticPred = 0.12
}

local CurrentStickyTarget = nil
_G.SilentTargetPos = nil
local MUMU_RaycastParams = RaycastParams.new()
MUMU_RaycastParams.FilterType = Enum.RaycastFilterType.Exclude
MUMU_RaycastParams.IgnoreWater = true

-- 🚀 [安全修復版：全庫解鎖與神仙槍法 (防崩潰)] 🚀
local PremiumSkins = {
    "Galaxy", "AKEY-47", "Gingerbread AUG", "Phoenix Rifle", 
    "Boneclaw Rifle", "Tommy Gun", "10B Visits", "Dark Matter", "Golden"
}

local function ApplyGodMods()
    if not getgc then return end
    for _, v in pairs(getgc(true)) do
        if type(v) == "table" then
            -- 1. 安全版全庫解鎖 (絕對不碰 Metatable，防 ClientFighter 報錯)
            if Settings.UnlockSkins and rawget(v, "OwnedWraps") and type(v.OwnedWraps) == "table" then
                for _, skin in ipairs(PremiumSkins) do
                    v.OwnedWraps[skin] = true
                end
            end
            
            -- 2. 安全版神仙槍法 (控制 BulletsPerShot 防止射線引擎過載)
            if Settings.GodGun and rawget(v, "FireRate") and type(rawget(v, "FireRate")) == "number" then
                rawset(v, "FireRate", 0.015) 
                if rawget(v, "Cooldown") then rawset(v, "Cooldown", 0) end
                if rawget(v, "Ammo") then rawset(v, "Ammo", 9999) end
                if rawget(v, "MaxAmmo") then rawset(v, "MaxAmmo", 9999) end
                if rawget(v, "StoredAmmo") then rawset(v, "StoredAmmo", 9999) end
                if rawget(v, "BulletsPerShot") then rawset(v, "BulletsPerShot", 5) end -- 5發霰彈效應，極致且安全
                if rawget(v, "Recoil") then rawset(v, "Recoil", 0); rawset(v, "Spread", 0) end
            end
        end
    end
end

-- 背景定時安全注入
task.spawn(function()
    while task.wait(1.5) do ApplyGodMods() end
end)

-- ⚡ [遊戲邏輯與改良版預判] ⚡
local function ToggleNoclip(state)
    if state then
        _G.MUMU_NOCLIP = RunService.Stepped:Connect(function()
            if LocalPlayer.Character then for _, p in pairs(LocalPlayer.Character:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide = false end end end
        end)
    else
        if _G.MUMU_NOCLIP then _G.MUMU_NOCLIP:Disconnect() end
        if LocalPlayer.Character then for _, p in pairs(LocalPlayer.Character:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide = true end end end
    end
end

local function IsTeammate(p)
    if p == LocalPlayer or Whitelisted[p.UserId] then return true end
    if not Settings.TeamESP then return false end
    local lpData = LocalPlayer:FindFirstChild("ClientData")
    local pData = p:FindFirstChild("ClientData")
    if lpData and pData then
        local lpTeam = lpData:FindFirstChild("Team")
        local pTeam = pData:FindFirstChild("Team")
        if lpTeam and pTeam and lpTeam.Value == pTeam.Value then return true end
    end
    return false
end

local function GetHealth(c)
    if not c then return 0, 100 end
    local hp, mx = 0, 100
    local hum = c:FindFirstChild("Humanoid")
    if hum then hp = tonumber(hum.Health) or 0; mx = tonumber(hum.MaxHealth) or 100 end
    return math_clamp(hp, 0, mx), mx
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
    local origin = Camera.CFrame.Position
    return not workspace:Raycast(origin, targetPos - origin, MUMU_RaycastParams)
end

-- 💎 [頂級付費級 UI 生成系統 (Midnight Purple Theme)] 💎
local SafeGui = (gethui and gethui()) or game:GetService("CoreGui")
if SafeGui:FindFirstChild("MUMU_UI") then SafeGui.MUMU_UI:Destroy() end

local SG = Instance.new("ScreenGui", SafeGui); SG.Name = "MUMU_UI"; SG.ResetOnSpawn = false
local Main = Instance.new("Frame", SG); Main.Size = UDim2.fromOffset(620, 440); Main.Position = UDim2.fromScale(0.5, 0.5); Main.AnchorPoint = v2new(0.5, 0.5); Main.BackgroundColor3 = Color3.fromRGB(13, 13, 18); Main.BorderSizePixel = 0
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 10)
local MainStroke = Instance.new("UIStroke", Main); MainStroke.Color = Color3.fromRGB(168, 85, 247); MainStroke.Thickness = 1.5; MainStroke.Transparency = 0.2

local Title = Instance.new("TextLabel", Main); Title.Size = UDim2.new(1, 0, 0, 55); Title.Position = UDim2.new(0, 20, 0, 0); Title.Text = "MUMU PRO"; Title.TextColor3 = Color3.new(1,1,1); Title.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold); Title.TextSize = 24; Title.BackgroundTransparency = 1; Title.TextXAlignment = Enum.TextXAlignment.Left
local TitleAccent = Instance.new("TextLabel", Title); TitleAccent.Size = UDim2.new(1, 0, 1, 0); TitleAccent.Position = UDim2.new(0, 150, 0, 0); TitleAccent.Text = "PREMIUM"; TitleAccent.TextColor3 = Color3.fromRGB(168, 85, 247); TitleAccent.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Heavy); TitleAccent.TextSize = 24; TitleAccent.BackgroundTransparency = 1; TitleAccent.TextXAlignment = Enum.TextXAlignment.Left
local Divider = Instance.new("Frame", Main); Divider.Size = UDim2.new(1, 0, 0, 1); Divider.Position = UDim2.new(0, 0, 0, 55); Divider.BackgroundColor3 = Color3.fromRGB(30, 30, 38); Divider.BorderSizePixel = 0

local Sidebar = Instance.new("Frame", Main); Sidebar.Size = UDim2.new(0, 150, 1, -65); Sidebar.Position = UDim2.new(0, 10, 0, 65); Sidebar.BackgroundTransparency = 1; Instance.new("UIListLayout", Sidebar).Padding = UDim.new(0, 8)
local ContentArea = Instance.new("Frame", Main); ContentArea.Size = UDim2.new(1, -180, 1, -65); ContentArea.Position = UDim2.new(0, 170, 0, 65); ContentArea.BackgroundTransparency = 1

local Tabs = {}
local function CreateTab(name, icon, isFirst)
    local btn = Instance.new("TextButton", Sidebar); btn.Size = UDim2.new(1, 0, 0, 40); btn.Text = "  " .. icon .. "  " .. name; btn.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium); btn.TextSize = 14; btn.TextColor3 = Color3.fromRGB(150, 150, 160); btn.TextXAlignment = Enum.TextXAlignment.Left; btn.BackgroundColor3 = Color3.fromRGB(20, 20, 25); btn.BackgroundTransparency = 1; Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
    local page = Instance.new("ScrollingFrame", ContentArea); page.Size = UDim2.new(1, 0, 1, -10); page.BackgroundTransparency = 1; page.ScrollBarThickness = 3; page.ScrollBarImageColor3 = Color3.fromRGB(168, 85, 247); page.Visible = isFirst; page.CanvasSize = UDim2.new(0,0,1.8,0); Instance.new("UIListLayout", page).Padding = UDim.new(0, 10)
    
    if isFirst then btn.BackgroundTransparency = 0; btn.TextColor3 = Color3.new(1,1,1) end
    btn.MouseButton1Click:Connect(function() 
        for _, t in pairs(Tabs) do TweenService:Create(t.Btn, TweenInfo.new(0.3), {BackgroundTransparency = 1, TextColor3 = Color3.fromRGB(150, 150, 160)}):Play(); t.Page.Visible = false end
        TweenService:Create(btn, TweenInfo.new(0.3), {BackgroundTransparency = 0, TextColor3 = Color3.new(1,1,1)}):Play(); page.Visible = true 
    end)
    table.insert(Tabs, {Btn = btn, Page = page}); return page
end

local function CreateToggle(parent, name, key, callback)
    local frame = Instance.new("Frame", parent); frame.Size = UDim2.new(1, -10, 0, 46); frame.BackgroundColor3 = Color3.fromRGB(20, 20, 26); Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8); Instance.new("UIStroke", frame).Color = Color3.fromRGB(35, 35, 45)
    local lbl = Instance.new("TextLabel", frame); lbl.Size = UDim2.new(0.75, 0, 1, 0); lbl.Position = UDim2.new(0, 15, 0, 0); lbl.Text = name; lbl.TextColor3 = Color3.new(1,1,1); lbl.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium); lbl.TextSize = 13; lbl.BackgroundTransparency = 1; lbl.TextXAlignment = Enum.TextXAlignment.Left
    
    local btn = Instance.new("TextButton", frame); btn.Size = UDim2.new(0, 44, 0, 22); btn.Position = UDim2.new(1, -60, 0.5, -11); btn.Text = ""; btn.BackgroundColor3 = Color3.fromRGB(40, 40, 45); Instance.new("UICorner", btn).CornerRadius = UDim.new(1, 0)
    local circle = Instance.new("Frame", btn); circle.Size = UDim2.new(0, 16, 0, 16); circle.Position = UDim2.new(0, 3, 0.5, -8); circle.BackgroundColor3 = Color3.new(1,1,1); Instance.new("UICorner", circle).CornerRadius = UDim.new(1, 0)
    
    local function update(anim)
        local bgGoal = Settings[key] and Color3.fromRGB(168, 85, 247) or Color3.fromRGB(40, 40, 45)
        local circleGoal = Settings[key] and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8)
        if anim then
            TweenService:Create(btn, TweenInfo.new(0.25, Enum.EasingStyle.Quad), {BackgroundColor3 = bgGoal}):Play()
            TweenService:Create(circle, TweenInfo.new(0.25, Enum.EasingStyle.Quad), {Position = circleGoal}):Play()
        else btn.BackgroundColor3 = bgGoal; circle.Position = circleGoal end
    end
    update(false)
    btn.MouseButton1Click:Connect(function() Settings[key] = not Settings[key]; update(true); if callback then callback(Settings[key]) end end)
end

local function CreateSlider(parent, name, key, min, max)
    local frame = Instance.new("Frame", parent); frame.Size = UDim2.new(1, -10, 0, 54); frame.BackgroundColor3 = Color3.fromRGB(20, 20, 26); Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8); Instance.new("UIStroke", frame).Color = Color3.fromRGB(35, 35, 45)
    local lbl = Instance.new("TextLabel", frame); lbl.Size = UDim2.new(0.6, 0, 0.5, 0); lbl.Position = UDim2.new(0, 15, 0, 5); lbl.Text = name; lbl.TextColor3 = Color3.new(1,1,1); lbl.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium); lbl.TextSize = 13; lbl.BackgroundTransparency = 1; lbl.TextXAlignment = Enum.TextXAlignment.Left
    local val = Instance.new("TextLabel", frame); val.Size = UDim2.new(0, 30, 0.5, 0); val.Position = UDim2.new(1, -45, 0, 5); val.Text = tostring(Settings[key]); val.TextColor3 = Color3.fromRGB(168, 85, 247); val.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold); val.TextSize = 13; val.BackgroundTransparency = 1; val.TextXAlignment = Enum.TextXAlignment.Right
    local track = Instance.new("Frame", frame); track.Size = UDim2.new(1, -30, 0, 6); track.Position = UDim2.new(0, 15, 1, -15); track.BackgroundColor3 = Color3.fromRGB(30, 30, 35); Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)
    local fill = Instance.new("Frame", track); fill.Size = UDim2.new((Settings[key]-min)/(max-min), 0, 1, 0); fill.BackgroundColor3 = Color3.fromRGB(168, 85, 247); Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)
    local btn = Instance.new("TextButton", track); btn.Size = UDim2.new(1, 0, 0, 20); btn.Position = UDim2.new(0, 0, 0.5, -10); btn.BackgroundTransparency = 1; btn.Text = ""
    local dragging = false
    btn.MouseButton1Down:Connect(function() dragging = true end); UIS.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end end)
    UIS.InputChanged:Connect(function(i) if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then local pct = math_clamp((i.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1); fill.Size = UDim2.new(pct, 0, 1, 0); Settings[key] = math.floor((min + (max - min) * pct) * 10)/10; val.Text = tostring(Settings[key]) end end)
end

-- UI 構建
local TabRage = CreateTab("Rage 暴力", "🔥", true)
CreateToggle(TabRage, "💎 全庫頂級解鎖 (Skin/Wrap)", "UnlockSkins", function() ApplyGodMods() end)
CreateToggle(TabRage, "🔫 神仙槍法 (極限射速+無限散彈)", "GodGun", function() ApplyGodMods() end)
CreateToggle(TabRage, "🚀 穿牆魔術彈 (Wallbang)", "Wallbang")
CreateToggle(TabRage, "🎯 360 靜默自瞄 (Silent Aim)", "SilentAim")
CreateToggle(TabRage, "開鏡自動連發 (Auto Click)", "RageAutoClick")

local TabLegit = CreateTab("Legit 常規", "🎯", false)
CreateToggle(TabLegit, "啟用常規自瞄 (Enable)", "Aimbot")
CreateToggle(TabLegit, "顯示 FOV 範圍圈", "ShowFOV")
CreateToggle(TabLegit, "隔牆不瞄 (Wall Check)", "WallCheck")
CreateSlider(TabLegit, "自瞄平滑度 (1.0=暴力死鎖)", "AimbotSens", 1.0, 10.0) 
CreateToggle(TabLegit, "啟用黏性瞄準 (Sticky Aim)", "StickyAim")
CreateSlider(TabLegit, "自瞄範圍 (FOV)", "FOV", 50, 800)

local TabVisuals = CreateTab("Visuals 透視", "👁️", false)
CreateToggle(TabVisuals, "啟用透視 (ESP)", "ESP")
CreateToggle(TabVisuals, "恆定方框 (Constant Box)", "ConstantBox")
CreateToggle(TabVisuals, "顯示綠色血條 (Health Bar)", "HealthBar")

local TabPlayer = CreateTab("Player 玩家", "🏃", false)
CreateToggle(TabPlayer, "無限制飛行 (Fly)", "Fly")
CreateSlider(TabPlayer, "飛行速度", "FlySpeed", 20, 300)
CreateToggle(TabPlayer, "加速模式 (Speed Hack)", "SpeedHack")
CreateSlider(TabPlayer, "移動速度", "WalkSpeed", 16, 300)
CreateToggle(TabPlayer, "穿牆模式 (Noclip)", "Noclip", function(state) ToggleNoclip(state) end)

-- UI 拖曳 & J鍵隱藏
local draggingUI, dragInput, dragStart, startPos
Main.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then draggingUI = true; dragStart = i.Position; startPos = Main.Position end end)
Main.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then draggingUI = false end end)
UIS.InputChanged:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseMovement then dragInput = i end end)
RunService.RenderStepped:Connect(function() if draggingUI and dragInput then local delta = dragInput.Position - dragStart; Main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y) end end)
UIS.InputBegan:Connect(function(i, gp) if not gp and i.KeyCode == Enum.KeyCode.J then Main.Visible = not Main.Visible end end)

-- 🚀 輕量化攔截器 (兼容 Wallbang)
if hookmetamethod then
    local OldNC = hookmetamethod(game, "__namecall", function(self, ...)
        local m = getnamecallmethod(); local a = {...}
        if not checkcaller() and Settings.SilentAim and _G.SilentTargetPos then
            if m == "Raycast" and typeof(a[2]) == "Vector3" then a[2] = (_G.SilentTargetPos - a[1]).Unit * 5000; return OldNC(self, unpack(a)) end
            if m == "FindPartOnRay" or m == "FindPartOnRayWithIgnoreList" then
                if typeof(a[1]) == "Ray" then a[1] = Ray_new(a[1].Origin, (_G.SilentTargetPos - a[1].Origin).Unit * 5000); return OldNC(self, unpack(a)) end
            end
        end
        return OldNC(self, ...)
    end)
    local OldIdx = hookmetamethod(game, "__index", function(self, k)
        if not checkcaller() and Settings.SilentAim and _G.SilentTargetPos and typeof(self) == "Instance" and self:IsA("Mouse") then
            if k == "Hit" then return CFrame_new(_G.SilentTargetPos) elseif k == "Target" and _G.SilentTarget then return _G.SilentTarget:FindFirstChild("Head") end
        end
        return OldIdx(self, k)
    end)
end

local function FireWeapon() if mouse1click then pcall(mouse1click) else VIM:SendMouseButtonEvent(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2, 0, true, game, 1); task.wait(0.01); VIM:SendMouseButtonEvent(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2, 0, false, game, 1) end end

local lastFire = 0
local FlyBodyGyro, FlyBodyVelocity, CONTROL = nil, nil, {F=0, B=0, L=0, R=0, UP=0, DOWN=0}
UIS.InputBegan:Connect(function(i, gp) if not gp then local k=i.KeyCode; if k==Enum.KeyCode.W then CONTROL.F=1 elseif k==Enum.KeyCode.S then CONTROL.B=-1 elseif k==Enum.KeyCode.A then CONTROL.L=-1 elseif k==Enum.KeyCode.D then CONTROL.R=1 elseif k==Enum.KeyCode.Space then CONTROL.UP=1 elseif k==Enum.KeyCode.LeftControl then CONTROL.DOWN=-1 end end end)
UIS.InputEnded:Connect(function(i) local k=i.KeyCode; if k==Enum.KeyCode.W then CONTROL.F=0 elseif k==Enum.KeyCode.S then CONTROL.B=0 elseif k==Enum.KeyCode.A then CONTROL.L=0 elseif k==Enum.KeyCode.D then CONTROL.R=0 elseif k==Enum.KeyCode.Space then CONTROL.UP=0 elseif k==Enum.KeyCode.LeftControl then CONTROL.DOWN=0 end end)

-- ⚡ [防禦渲染引擎] ⚡
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
