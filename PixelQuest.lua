-- ==========================================
-- MUMU PRO (V77) - 終極淨化版 (零報錯 / 解決亂飛 / 雷射光束)
-- ==========================================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

local v2new, v3new = Vector2.new, Vector3.new
local math_clamp, math_abs = math.clamp, math.abs
local Ray_new = Ray.new

-- ⚡ [核心清理] ⚡
if _G.MUMU_CONN then _G.MUMU_CONN:Disconnect() end
if _G.MUMU_DRAWINGS then for _, d in pairs(_G.MUMU_DRAWINGS) do pcall(function() d.Box:Remove(); d.HealthBg:Remove(); d.HealthBar:Remove() end) end end
if _G.MUMU_FOV_CIRCLE then pcall(function() _G.MUMU_FOV_CIRCLE:Remove() end) end

_G.MUMU_DRAWINGS = {}
_G.CurrentDT = 1/60 
RunService.RenderStepped:Connect(function(dt) _G.CurrentDT = dt end)

_G.MUMU_FOV_CIRCLE = Drawing.new("Circle")
_G.MUMU_FOV_CIRCLE.Color = Color3.fromRGB(168, 85, 247)
_G.MUMU_FOV_CIRCLE.Thickness = 1.5
_G.MUMU_FOV_CIRCLE.Filled = false
_G.MUMU_FOV_CIRCLE.Visible = false

-- 🚀 [功能預設全關] 🚀
local Settings = {
    -- 神仙
    SilentAim = false, GodGun = false, SkinChanger = false,
    -- 相機自瞄 (隔牆不瞄已寫死在底層)
    Aimbot = false, AimbotSens = 1.0, FOV = 250, ShowFOV = false, 
    -- 視覺與玩家
    ESP = false, HealthBar = false, MaxDistance = 1000,
    Fly = false, FlySpeed = 100, SpeedHack = false, WalkSpeed = 100
}

_G.SilentTargetPos = nil

local MUMU_RaycastParams = RaycastParams.new()
MUMU_RaycastParams.FilterType = Enum.RaycastFilterType.Exclude
MUMU_RaycastParams.IgnoreWater = true

-- 🚀 [零報錯：背景神仙引擎 (解鎖 Skin + 雷射神槍)] 🚀
task.spawn(function()
    local PremiumSkins = {"Galaxy", "AKEY-47", "Gingerbread AUG", "Phoenix Rifle", "Boneclaw Rifle", "Tommy Gun", "10B Visits", "Dark Matter", "Golden"}
    while task.wait(1) do
        if Settings.SkinChanger or Settings.GodGun then
            if not getgc then continue end
            local gc = getgc(true)
            for i = 1, #gc do
                local v = gc[i]
                if type(v) == "table" then
                    pcall(function()
                        if Settings.SkinChanger and rawget(v, "OwnedWraps") and type(rawget(v, "OwnedWraps")) == "table" then
                            for _, skin in ipairs(PremiumSkins) do v.OwnedWraps[skin] = true end
                        end
                        if Settings.SkinChanger and rawget(v, "OwnedWeapons") and type(rawget(v, "OwnedWeapons")) == "table" then
                            for _, skin in ipairs(PremiumSkins) do v.OwnedWeapons[skin] = true end
                        end
                        if Settings.GodGun and rawget(v, "FireRate") and type(rawget(v, "FireRate")) == "number" then
                            v.FireRate = 0.001      -- 射速極致
                            v.BulletsPerShot = 20   -- 一瞬20發雷射
                            v.Ammo = 9999           -- 無限子彈
                            v.MaxAmmo = 9999
                            v.Spread = 0            -- 絕對直線
                            v.MaxSpread = 0
                            v.Recoil = 0            -- 無後座力
                        end
                    end)
                end
            end
        end
    end
end)

-- 🚀 [解決亂飛：完美子彈拐彎攔截器] 🚀
if hookmetamethod then
    local OldNC
    OldNC = hookmetamethod(game, "__namecall", function(self, ...)
        local m = getnamecallmethod()
        local a = {...}
        if Settings.SilentAim and _G.SilentTargetPos and not checkcaller() then
            if m == "Raycast" and typeof(a[2]) == "Vector3" then 
                -- ⚠️ 關鍵修復：確保射線是從玩家/相機附近射出的 (排除地板偵測射線)
                if (a[1] - Camera.CFrame.Position).Magnitude < 15 then
                    a[2] = (_G.SilentTargetPos - a[1]).Unit * 5000
                    return OldNC(self, unpack(a)) 
                end
            elseif (m == "FindPartOnRay" or m == "FindPartOnRayWithIgnoreList") and typeof(a[1]) == "Ray" then
                if (a[1].Origin - Camera.CFrame.Position).Magnitude < 15 then
                    a[1] = Ray_new(a[1].Origin, (_G.SilentTargetPos - a[1].Origin).Unit * 5000)
                    return OldNC(self, unpack(a)) 
                end
            end
        end
        return OldNC(self, ...)
    end)
end

-- ⚡ [遊戲邏輯] ⚡
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
    local safeVel = v3new(tChar.HumanoidRootPart.Velocity.X, tChar.HumanoidRootPart.Velocity.Y * 0.3, tChar.HumanoidRootPart.Velocity.Z) 
    return hp + (safeVel * (((hp - Camera.CFrame.Position).Magnitude / 3500) + 0.05 + _G.CurrentDT))
end

-- 強制底層：永遠檢查牆壁
local function IsVisible(targetPos)
    if not LocalPlayer.Character then return true end
    MUMU_RaycastParams.FilterDescendantsInstances = {LocalPlayer.Character, Camera}
    return not workspace:Raycast(Camera.CFrame.Position, targetPos - Camera.CFrame.Position, MUMU_RaycastParams)
end

-- 💎 [精簡極致 UI 介面 (Midnight Purple)] 💎
local SafeGui = (gethui and gethui()) or game:GetService("CoreGui")
if SafeGui:FindFirstChild("MUMU_UI") then SafeGui.MUMU_UI:Destroy() end

local SG = Instance.new("ScreenGui", SafeGui); SG.Name = "MUMU_UI"; SG.ResetOnSpawn = false
local Main = Instance.new("Frame", SG); Main.Size = UDim2.fromOffset(560, 360); Main.Position = UDim2.fromScale(0.5, 0.5); Main.AnchorPoint = v2new(0.5, 0.5); Main.BackgroundColor3 = Color3.fromRGB(15, 15, 20); Main.BorderSizePixel = 0
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 10)
local MainStroke = Instance.new("UIStroke", Main); MainStroke.Color = Color3.fromRGB(168, 85, 247); MainStroke.Thickness = 2; MainStroke.Transparency = 0.3

local Title = Instance.new("TextLabel", Main); Title.Size = UDim2.new(1, 0, 0, 50); Title.Position = UDim2.new(0, 20, 0, 0); Title.Text = "MUMU PRO"; Title.TextColor3 = Color3.new(1,1,1); Title.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold); Title.TextSize = 22; Title.BackgroundTransparency = 1; Title.TextXAlignment = Enum.TextXAlignment.Left
local TitleAccent = Instance.new("TextLabel", Title); TitleAccent.Size = UDim2.new(1, 0, 1, 0); TitleAccent.Position = UDim2.new(0, 135, 0, 0); TitleAccent.Text = "V77"; TitleAccent.TextColor3 = Color3.fromRGB(168, 85, 247); TitleAccent.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Heavy); TitleAccent.TextSize = 22; TitleAccent.BackgroundTransparency = 1; TitleAccent.TextXAlignment = Enum.TextXAlignment.Left
local Divider = Instance.new("Frame", Main); Divider.Size = UDim2.new(1, 0, 0, 1); Divider.Position = UDim2.new(0, 0, 0, 50); Divider.BackgroundColor3 = Color3.fromRGB(35, 35, 45); Divider.BorderSizePixel = 0

local Sidebar = Instance.new("Frame", Main); Sidebar.Size = UDim2.new(0, 140, 1, -60); Sidebar.Position = UDim2.new(0, 10, 0, 60); Sidebar.BackgroundTransparency = 1; Instance.new("UIListLayout", Sidebar).Padding = UDim.new(0, 8)
local ContentArea = Instance.new("Frame", Main); ContentArea.Size = UDim2.new(1, -165, 1, -60); ContentArea.Position = UDim2.new(0, 155, 0, 60); ContentArea.BackgroundTransparency = 1

local Tabs = {}
local function CreateTab(name, isFirst)
    local btn = Instance.new("TextButton", Sidebar); btn.Size = UDim2.new(1, 0, 0, 40); btn.Text = "  " .. name; btn.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium); btn.TextSize = 14; btn.TextColor3 = Color3.fromRGB(160, 160, 175); btn.TextXAlignment = Enum.TextXAlignment.Left; btn.BackgroundColor3 = Color3.fromRGB(22, 22, 28); btn.BackgroundTransparency = 1; Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
    local page = Instance.new("ScrollingFrame", ContentArea); page.Size = UDim2.new(1, 0, 1, -10); page.BackgroundTransparency = 1; page.ScrollBarThickness = 3; page.ScrollBarImageColor3 = Color3.fromRGB(168, 85, 247); page.Visible = isFirst; page.CanvasSize = UDim2.new(0,0,1.2,0); Instance.new("UIListLayout", page).Padding = UDim.new(0, 10)
    if isFirst then btn.BackgroundTransparency = 0; btn.TextColor3 = Color3.new(1,1,1) end
    btn.MouseButton1Click:Connect(function() 
        for _, t in pairs(Tabs) do t.Btn.BackgroundTransparency = 1; t.Btn.TextColor3 = Color3.fromRGB(160, 160, 175); t.Page.Visible = false end
        btn.BackgroundTransparency = 0; btn.TextColor3 = Color3.new(1,1,1); page.Visible = true 
    end)
    table.insert(Tabs, {Btn = btn, Page = page}); return page
end

local function CreateToggle(parent, name, key)
    local frame = Instance.new("Frame", parent); frame.Size = UDim2.new(1, -10, 0, 42); frame.BackgroundColor3 = Color3.fromRGB(22, 22, 28); Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8); Instance.new("UIStroke", frame).Color = Color3.fromRGB(40, 40, 50)
    local lbl = Instance.new("TextLabel", frame); lbl.Size = UDim2.new(0.75, 0, 1, 0); lbl.Position = UDim2.new(0, 15, 0, 0); lbl.Text = name; lbl.TextColor3 = Color3.new(1,1,1); lbl.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium); lbl.TextSize = 13; lbl.BackgroundTransparency = 1; lbl.TextXAlignment = Enum.TextXAlignment.Left
    local btn = Instance.new("TextButton", frame); btn.Size = UDim2.new(0, 40, 0, 20); btn.Position = UDim2.new(1, -55, 0.5, -10); btn.Text = ""; btn.BackgroundColor3 = Color3.fromRGB(45, 45, 55); Instance.new("UICorner", btn).CornerRadius = UDim.new(1, 0)
    local circle = Instance.new("Frame", btn); circle.Size = UDim2.new(0, 14, 0, 14); circle.Position = UDim2.new(0, 3, 0.5, -7); circle.BackgroundColor3 = Color3.new(1,1,1); Instance.new("UICorner", circle).CornerRadius = UDim.new(1, 0)
    local function update()
        if Settings[key] then btn.BackgroundColor3 = Color3.fromRGB(168, 85, 247); circle.Position = UDim2.new(1, -17, 0.5, -7)
        else btn.BackgroundColor3 = Color3.fromRGB(45, 45, 55); circle.Position = UDim2.new(0, 3, 0.5, -7) end
    end
    update()
    btn.MouseButton1Click:Connect(function() Settings[key] = not Settings[key]; update() end)
end

local function CreateSlider(parent, name, key, min, max)
    local frame = Instance.new("Frame", parent); frame.Size = UDim2.new(1, -10, 0, 50); frame.BackgroundColor3 = Color3.fromRGB(22, 22, 28); Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8); Instance.new("UIStroke", frame).Color = Color3.fromRGB(40, 40, 50)
    local lbl = Instance.new("TextLabel", frame); lbl.Size = UDim2.new(0.6, 0, 0.5, 0); lbl.Position = UDim2.new(0, 15, 0, 5); lbl.Text = name; lbl.TextColor3 = Color3.new(1,1,1); lbl.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium); lbl.TextSize = 13; lbl.BackgroundTransparency = 1; lbl.TextXAlignment = Enum.TextXAlignment.Left
    local val = Instance.new("TextLabel", frame); val.Size = UDim2.new(0, 30, 0.5, 0); val.Position = UDim2.new(1, -45, 0, 5); val.Text = tostring(Settings[key]); val.TextColor3 = Color3.fromRGB(168, 85, 247); val.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold); val.TextSize = 13; val.BackgroundTransparency = 1; val.TextXAlignment = Enum.TextXAlignment.Right
    local track = Instance.new("Frame", frame); track.Size = UDim2.new(1, -30, 0, 6); track.Position = UDim2.new(0, 15, 1, -15); track.BackgroundColor3 = Color3.fromRGB(35, 35, 45); Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)
    local fill = Instance.new("Frame", track); fill.Size = UDim2.new((Settings[key]-min)/(max-min), 0, 1, 0); fill.BackgroundColor3 = Color3.fromRGB(168, 85, 247); Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)
    local btn = Instance.new("TextButton", track); btn.Size = UDim2.new(1, 0, 0, 24); btn.Position = UDim2.new(0, 0, 0.5, -12); btn.BackgroundTransparency = 1; btn.Text = ""
    local dragging = false
    btn.MouseButton1Down:Connect(function() dragging = true end); UIS.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end end)
    UIS.InputChanged:Connect(function(i) if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then local pct = math_clamp((i.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1); fill.Size = UDim2.new(pct, 0, 1, 0); Settings[key] = math.floor((min + (max - min) * pct) * 10)/10; val.Text = tostring(Settings[key]) end end)
end

-- UI 構建 (極致精簡單一自瞄)
local TabRage = CreateTab("🔥 神仙核心", true)
CreateToggle(TabRage, "🎯 子彈拐彎 (自帶穿牆)", "SilentAim")
CreateToggle(TabRage, "🔫 終極雷射神槍 (無限+零擴散)", "GodGun")
CreateToggle(TabRage, "💎 裝備庫全解鎖 (Skin Changer)", "SkinChanger")

local TabLegit = CreateTab("🎯 視覺自瞄", false)
CreateToggle(TabLegit, "開啟單一相機自瞄 (內建隔牆不瞄)", "Aimbot")
CreateSlider(TabLegit, "自瞄平滑度 (1.0=暴力死鎖)", "AimbotSens", 1.0, 10.0) 
CreateToggle(TabLegit, "開啟自瞄圈 (FOV)", "ShowFOV")
CreateSlider(TabLegit, "自瞄範圍 (FOV)", "FOV", 50, 800)
CreateToggle(TabLegit, "開啟方框透視 (ESP)", "ESP")

local TabPlayer = CreateTab("🏃 玩家控制", false)
CreateToggle(TabPlayer, "無限制飛行 (Fly)", "Fly")
CreateSlider(TabPlayer, "飛行速度", "FlySpeed", 20, 300)
CreateToggle(TabPlayer, "加速模式 (Speed Hack)", "SpeedHack")
CreateSlider(TabPlayer, "移動速度", "WalkSpeed", 16, 300)

local draggingUI, dragInput, dragStart, startPos
Main.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then draggingUI = true; dragStart = i.Position; startPos = Main.Position end end)
Main.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then draggingUI = false end end)
UIS.InputChanged:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseMovement then dragInput = i end end)
RunService.RenderStepped:Connect(function() if draggingUI and dragInput then local delta = dragInput.Position - dragStart; Main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y) end end)
UIS.InputBegan:Connect(function(i, gp) if not gp and i.KeyCode == Enum.KeyCode.J then Main.Visible = not Main.Visible end end)

local FlyBodyGyro, FlyBodyVelocity, CONTROL = nil, nil, {F=0, B=0, L=0, R=0, UP=0, DOWN=0}
UIS.InputBegan:Connect(function(i, gp) if not gp then local k=i.KeyCode; if k==Enum.KeyCode.W then CONTROL.F=1 elseif k==Enum.KeyCode.S then CONTROL.B=-1 elseif k==Enum.KeyCode.A then CONTROL.L=-1 elseif k==Enum.KeyCode.D then CONTROL.R=1 elseif k==Enum.KeyCode.Space then CONTROL.UP=1 elseif k==Enum.KeyCode.LeftControl then CONTROL.DOWN=-1 end end end)
UIS.InputEnded:Connect(function(i) local k=i.KeyCode; if k==Enum.KeyCode.W then CONTROL.F=0 elseif k==Enum.KeyCode.S then CONTROL.B=0 elseif k==Enum.KeyCode.A then CONTROL.L=0 elseif k==Enum.KeyCode.D then CONTROL.R=0 elseif k==Enum.KeyCode.Space then CONTROL.UP=0 elseif k==Enum.KeyCode.LeftControl then CONTROL.DOWN=0 end end)

-- ⚡ [完美防禦與渲染引擎] ⚡
_G.MUMU_CONN = RunService.RenderStepped:Connect(function()
    if _G.MUMU_FOV_CIRCLE then 
        _G.MUMU_FOV_CIRCLE.Position = Camera.ViewportSize / 2
        _G.MUMU_FOV_CIRCLE.Radius = Settings.FOV
        _G.MUMU_FOV_CIRCLE.Visible = Settings.ShowFOV 
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
            if not _G.MUMU_DRAWINGS[p] then _G.MUMU_DRAWINGS[p] = { Box = Drawing.new("Square") }; local d = _G.MUMU_DRAWINGS[p]; d.Box.Color = Color3.fromRGB(168, 85, 247); d.Box.Thickness = 1.5; d.Box.Filled = false end
            local d = _G.MUMU_DRAWINGS[p]; local char = p.Character
            
            if char and char:FindFirstChild("HumanoidRootPart") and char:FindFirstChild("Head") then
                local hp, _ = GetHealth(char)
                if hp > 0 then
                    local hrp = char.HumanoidRootPart; local headPos = char.Head.Position; local dist3D = (hrp.Position - myPos).Magnitude
                    
                    if dist3D < Settings.MaxDistance then
                        if Settings.ESP then
                            local topPos, onScreen = Camera:WorldToViewportPoint(hrp.Position + v3new(0, 2.5, 0))
                            if onScreen then
                                local bottomPos = Camera:WorldToViewportPoint(hrp.Position - v3new(0, 3, 0)); local centerPos = Camera:WorldToViewportPoint(hrp.Position)
                                local height = math_abs(topPos.Y - bottomPos.Y); local width = height * 0.6
                                d.Box.Size = v2new(width, height); d.Box.Position = v2new(centerPos.X - width/2, centerPos.Y - height/2); d.Box.Visible = true
                            else d.Box.Visible = false end
                        else d.Box.Visible = false end
                        
                        -- 🎯 子彈拐彎索敵 (無視牆壁)
                        if Settings.SilentAim and dist3D < bestSilentDist then 
                            bestSilentDist = dist3D; bestSilentTarget = char 
                        end
                        
                        -- 🎯 唯一相機自瞄索敵 (嚴格檢查牆壁)
                        if Settings.Aimbot then
                            local sp, os2 = Camera:WorldToViewportPoint(headPos)
                            if os2 then 
                                local dCenter = (v2new(sp.X, sp.Y) - screenCenter).Magnitude
                                if dCenter < bestAimbotDist and IsVisible(headPos) then 
                                    bestAimbotDist = dCenter; bestAimbotTarget = char 
                                end 
                            end
                        end
                    else d.Box.Visible = false end
                else d.Box.Visible = false end
            else d.Box.Visible = false end
        end
    end

    _G.SilentTargetPos = (Settings.SilentAim and bestSilentTarget) and GetPred(bestSilentTarget) or nil

    -- 單一自瞄執行邏輯
    if Settings.Aimbot and bestAimbotTarget and isRC then
        local fp = GetPred(bestAimbotTarget)
        if fp then 
            local sp, os = Camera:WorldToViewportPoint(fp)
            if os and mousemoverel then 
                local deltaX = sp.X - screenCenter.X; local deltaY = sp.Y - screenCenter.Y
                if Settings.AimbotSens <= 1.1 then 
                    mousemoverel(deltaX, deltaY) -- 絕對死鎖
                else 
                    mousemoverel(deltaX / Settings.AimbotSens, deltaY / Settings.AimbotSens) 
                end
            end 
        end
    end
end)
