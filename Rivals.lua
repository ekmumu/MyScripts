-- ==========================================
-- MUMU PRO (V66.1) - 純淨按鍵版 (J鍵專武)
-- ==========================================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local VIM = game:GetService("VirtualInputManager")
local TweenService = game:GetService("TweenService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- ⚡ [核心變數與清理] ⚡
if _G.MUMU_CONN then _G.MUMU_CONN:Disconnect() end
if _G.MUMU_DRAWINGS then for _, d in pairs(_G.MUMU_DRAWINGS) do pcall(function() d.Box:Remove() end) end end
if _G.MUMU_FOV_CIRCLE then pcall(function() _G.MUMU_FOV_CIRCLE:Remove() end) end

_G.MUMU_DRAWINGS = {}
_G.MUMU_FOV_CIRCLE = Drawing.new("Circle")
_G.MUMU_FOV_CIRCLE.Color = Color3.fromRGB(255, 255, 255); _G.MUMU_FOV_CIRCLE.Thickness = 1; _G.MUMU_FOV_CIRCLE.Filled = false; _G.MUMU_FOV_CIRCLE.Transparency = 0.8

local Settings = {
    Aimbot = false, FOV = 400, ShowFOV = true, GlobalAim = false,
    SilentAim = false, AutoShoot = false, 
    RapidFire = false, NoRecoil = false,
    SkinChanger = false, TargetSkin = "Galaxy", TargetEffect = "Lightning",
    Fly = false, FlySpeed = 75, BarrierBypass = true,
    ThirdPerson = false, TP_Distance = 12
}

-- ⚡ [神仙功能：Skin Changer & 穿牆魔術彈攔截] ⚡
local _G_SilentTargetPos = nil
if hookmetamethod then
    local OldIdx; local OldNC
    
    OldIdx = hookmetamethod(game, "__index", function(self, k)
        if not checkcaller() and Settings.SkinChanger then
            if k == "EquippedWrap" or k == "Skin" or k == "WeaponSkin" then return Settings.TargetSkin
            elseif k == "EquippedKillEffect" or k == "KillEffect" then return Settings.TargetEffect 
            elseif k == "OwnedWraps" or k == "OwnedEffects" then return { [Settings.TargetSkin] = true, [Settings.TargetEffect] = true } end
        end
        return OldIdx(self, k)
    end)
    
    OldNC = hookmetamethod(game, "__namecall", function(self, ...)
        local m = getnamecallmethod(); local a = {...}
        if not checkcaller() and Settings.SilentAim and _G_SilentTargetPos then
            if m == "Raycast" and typeof(a[2]) == "Vector3" then 
                a[2] = (_G_SilentTargetPos - a[1]).Unit * 9999; return OldNC(self, unpack(a)) 
            end
            if (m == "FindPartOnRay" or m == "FindPartOnRayWithIgnoreList") and typeof(a[1]) == "Ray" then 
                a[1] = Ray.new(a[1].Origin, (_G_SilentTargetPos - a[1].Origin).Unit * 9999); return OldNC(self, unpack(a)) 
            end
        end
        return OldNC(self, ...)
    end)
end

-- ⚡ [神仙功能：暴力改槍] ⚡
local function ApplyGodMods()
    if not getgc then return end
    for _, v in pairs(getgc(true)) do
        if type(v) == "table" then
            if Settings.RapidFire and rawget(v, "FireRate") then rawset(v, "FireRate", 0.001) end
            if Settings.NoRecoil and rawget(v, "Recoil") then rawset(v, "Recoil", 0); rawset(v, "Spread", 0) end
        end
    end
end

-- ⚡ [高級尊爵版 UI 介面生成] ⚡
local SafeGui = (gethui and gethui()) or game:GetService("CoreGui")
if SafeGui:FindFirstChild("MUMU_UI") then SafeGui.MUMU_UI:Destroy() end

local SG = Instance.new("ScreenGui", SafeGui); SG.Name = "MUMU_UI"; SG.ResetOnSpawn = false
local Main = Instance.new("Frame", SG); Main.Size = UDim2.fromOffset(600, 400); Main.Position = UDim2.fromScale(0.5, 0.5); Main.AnchorPoint = Vector2.new(0.5, 0.5); Main.BackgroundColor3 = Color3.fromRGB(20, 20, 25); Main.BorderSizePixel = 0; Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 12); Instance.new("UIStroke", Main).Color = Color3.fromRGB(255, 215, 0); Instance.new("UIStroke", Main).Thickness = 1.5
local Title = Instance.new("TextLabel", Main); Title.Size = UDim2.new(1, 0, 0, 50); Title.Position = UDim2.new(0, 20, 0, 0); Title.Text = "MUMU PRO PREMIUM"; Title.TextColor3 = Color3.fromRGB(255, 215, 0); Title.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold); Title.TextSize = 20; Title.BackgroundTransparency = 1; Title.TextXAlignment = Enum.TextXAlignment.Left

local Sidebar = Instance.new("Frame", Main); Sidebar.Size = UDim2.new(0, 150, 1, -60); Sidebar.Position = UDim2.new(0, 10, 0, 50); Sidebar.BackgroundTransparency = 1; Instance.new("UIListLayout", Sidebar).Padding = UDim.new(0, 8)
local ContentArea = Instance.new("Frame", Main); ContentArea.Size = UDim2.new(1, -170, 1, -60); ContentArea.Position = UDim2.new(0, 160, 0, 50); ContentArea.BackgroundTransparency = 1

local Tabs = {}
local function CreateTab(name, isFirst)
    local btn = Instance.new("TextButton", Sidebar); btn.Size = UDim2.new(1, 0, 0, 38); btn.Text = "  " .. name; btn.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium); btn.TextSize = 14; btn.TextColor3 = Color3.fromRGB(180, 180, 190); btn.TextXAlignment = Enum.TextXAlignment.Left; btn.BackgroundColor3 = Color3.fromRGB(25, 25, 30); btn.BackgroundTransparency = isFirst and 0 or 1; Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
    local page = Instance.new("ScrollingFrame", ContentArea); page.Size = UDim2.new(1, -10, 1, -10); page.BackgroundTransparency = 1; page.ScrollBarThickness = 2; page.Visible = isFirst; page.CanvasSize = UDim2.new(0,0,2,0); Instance.new("UIListLayout", page).Padding = UDim.new(0, 10)
    
    btn.MouseButton1Click:Connect(function()
        for _, t in pairs(Tabs) do TweenService:Create(t.Btn, TweenInfo.new(0.3), {BackgroundTransparency = 1, TextColor3 = Color3.fromRGB(180, 180, 190)}):Play(); t.Page.Visible = false end
        TweenService:Create(btn, TweenInfo.new(0.3), {BackgroundTransparency = 0, TextColor3 = Color3.new(1,1,1)}):Play(); page.Visible = true 
    end)
    table.insert(Tabs, {Btn = btn, Page = page}); return page
end

local function CreateToggle(parent, name, key, callback)
    local frame = Instance.new("Frame", parent); frame.Size = UDim2.new(1, -10, 0, 46); frame.BackgroundColor3 = Color3.fromRGB(28, 28, 35); Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)
    local lbl = Instance.new("TextLabel", frame); lbl.Size = UDim2.new(0.75, 0, 1, 0); lbl.Position = UDim2.new(0, 15, 0, 0); lbl.Text = name; lbl.TextColor3 = Color3.new(1,1,1); lbl.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json"); lbl.TextSize = 13; lbl.BackgroundTransparency = 1; lbl.TextXAlignment = Enum.TextXAlignment.Left
    local btn = Instance.new("TextButton", frame); btn.Size = UDim2.new(0, 44, 0, 24); btn.Position = UDim2.new(1, -60, 0.5, -12); btn.Text = ""; btn.BackgroundColor3 = Color3.fromRGB(45, 45, 55); Instance.new("UICorner", btn).CornerRadius = UDim.new(1, 0)
    local circle = Instance.new("Frame", btn); circle.Size = UDim2.new(0, 18, 0, 18); circle.Position = UDim2.new(0, 3, 0.5, -9); circle.BackgroundColor3 = Color3.new(1,1,1); Instance.new("UICorner", circle).CornerRadius = UDim.new(1, 0)

    local function update(anim)
        local goalBtnColor = Settings[key] and Color3.fromRGB(255, 215, 0) or Color3.fromRGB(45, 45, 55)
        local goalCirclePos = Settings[key] and UDim2.new(1, -21, 0.5, -9) or UDim2.new(0, 3, 0.5, -9)
        if anim then TweenService:Create(btn, TweenInfo.new(0.3), {BackgroundColor3 = goalBtnColor}):Play(); TweenService:Create(circle, TweenInfo.new(0.3), {Position = goalCirclePos}):Play()
        else btn.BackgroundColor3 = goalBtnColor; circle.Position = goalCirclePos end
    end
    update(false)
    btn.MouseButton1Click:Connect(function() Settings[key] = not Settings[key]; update(true); if callback then callback(Settings[key]) end end)
end

-- 生成選單內容
local TabCombat = CreateTab("⚔️ 開局滅團", true)
CreateToggle(TabCombat, "穿牆魔術子彈 (Wallbang)", "SilentAim")
CreateToggle(TabCombat, "全圖鎖定 (Global Aim)", "GlobalAim")
CreateToggle(TabCombat, "全自動開火 (Spawn Wipe)", "AutoShoot")
CreateToggle(TabCombat, "極限射速 (Rapid Fire)", "RapidFire", function() ApplyGodMods() end)
CreateToggle(TabCombat, "無後座力 (No Recoil)", "NoRecoil", function() ApplyGodMods() end)

local TabVisuals = CreateTab("💎 造型與視覺", false)
CreateToggle(TabVisuals, "解鎖頂級造型與特效 (Skin Changer)", "SkinChanger")
CreateToggle(TabVisuals, "顯示 FOV 範圍", "ShowFOV")

local TabMisc = CreateTab("🚀 飛行與視角", false)
CreateToggle(TabMisc, "無敵越界飛行", "Fly")
CreateToggle(TabMisc, "第三人稱視角", "ThirdPerson")

-- 拖曳 UI 邏輯
local draggingUI, dragInput, dragStart, startPos
Main.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then draggingUI = true; dragStart = i.Position; startPos = Main.Position end end)
Main.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then draggingUI = false end end)
UIS.InputChanged:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseMovement then dragInput = i end end)
RunService.RenderStepped:Connect(function() if draggingUI and dragInput then local delta = dragInput.Position - dragStart; Main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y) end end)

-- ⚡ [快捷鍵系統] ⚡
local FlyBodyGyro, FlyBodyVelocity, CONTROL = nil, nil, {F=0, B=0, L=0, R=0, UP=0, DOWN=0}
UIS.InputBegan:Connect(function(i, gp)
    if gp then return end
    local k = i.KeyCode
    if k == Enum.KeyCode.J then Main.Visible = not Main.Visible -- 只有 J 鍵開關選單
    -- 這裡僅保留飛行模式下的 W A S D 空白鍵 控制，不綁定功能開關
    elseif k == Enum.KeyCode.W then CONTROL.F=1 elseif k == Enum.KeyCode.S then CONTROL.B=-1 
    elseif k == Enum.KeyCode.A then CONTROL.L=-1 elseif k == Enum.KeyCode.D then CONTROL.R=1 
    elseif k == Enum.KeyCode.Space then CONTROL.UP=1 elseif k == Enum.KeyCode.LeftControl then CONTROL.DOWN=-1 end 
end)
UIS.InputEnded:Connect(function(i) 
    local k=i.KeyCode
    if k==Enum.KeyCode.W then CONTROL.F=0 elseif k==Enum.KeyCode.S then CONTROL.B=0 
    elseif k==Enum.KeyCode.A then CONTROL.L=0 elseif k==Enum.KeyCode.D then CONTROL.R=0 
    elseif k==Enum.KeyCode.Space then CONTROL.UP=0 elseif k==Enum.KeyCode.LeftControl then CONTROL.DOWN=0 end 
end)

-- ⚡ [核心戰鬥與物理迴圈] ⚡
local lastFire = 0
_G.MUMU_CONN = RunService.RenderStepped:Connect(function()
    if _G.MUMU_FOV_CIRCLE then _G.MUMU_FOV_CIRCLE.Position = Camera.ViewportSize / 2; _G.MUMU_FOV_CIRCLE.Radius = Settings.FOV; _G.MUMU_FOV_CIRCLE.Visible = not Settings.GlobalAim and Settings.ShowFOV end

    -- 第三人稱切換
    if Settings.ThirdPerson then 
        LocalPlayer.CameraMode = Enum.CameraMode.Classic
        LocalPlayer.CameraMaxZoomDistance = Settings.TP_Distance
        LocalPlayer.CameraMinZoomDistance = Settings.TP_Distance 
    else 
        LocalPlayer.CameraMode = Enum.CameraMode.LockFirstPerson
        LocalPlayer.CameraMaxZoomDistance = 0.5
        LocalPlayer.CameraMinZoomDistance = 0.5 
    end
    
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        local hrp = LocalPlayer.Character.HumanoidRootPart
        if Settings.BarrierBypass then for _, part in pairs(LocalPlayer.Character:GetDescendants()) do if part:IsA("BasePart") then part.CanCollide = false end end end
        
        -- 飛行物理
        if Settings.Fly then
            if not hrp:FindFirstChild("MUMU_GYRO") then 
                FlyBodyGyro=Instance.new("BodyGyro", hrp); FlyBodyGyro.Name="MUMU_GYRO"; FlyBodyGyro.P=9e4; FlyBodyGyro.maxTorque=Vector3.new(9e9,9e9,9e9)
                FlyBodyVelocity=Instance.new("BodyVelocity", hrp); FlyBodyVelocity.Name="MUMU_VELOCITY"; FlyBodyVelocity.maxForce=Vector3.new(9e9,9e9,9e9) 
            end
            FlyBodyGyro.cframe = Camera.CFrame
            FlyBodyVelocity.velocity = ((Camera.CFrame.LookVector*(CONTROL.F+CONTROL.B)) + (Camera.CFrame.RightVector*(CONTROL.L+CONTROL.R)) + (Camera.CFrame.UpVector*(CONTROL.UP+CONTROL.DOWN))).Magnitude > 0 and ((Camera.CFrame.LookVector*(CONTROL.F+CONTROL.B)) + (Camera.CFrame.RightVector*(CONTROL.L+CONTROL.R)) + (Camera.CFrame.UpVector*(CONTROL.UP+CONTROL.DOWN))).Unit * Settings.FlySpeed or Vector3.new(0,0,0)
            if LocalPlayer.Character:FindFirstChild("Humanoid") then LocalPlayer.Character.Humanoid.PlatformStand = true end
        else
            if hrp:FindFirstChild("MUMU_GYRO") then hrp.MUMU_GYRO:Destroy(); hrp.MUMU_VELOCITY:Destroy(); if LocalPlayer.Character:FindFirstChild("Humanoid") then LocalPlayer.Character.Humanoid.PlatformStand = false end end
        end
    end

    -- 索敵與自動開火
    local screenCenter = Camera.ViewportSize / 2
    local bestTarget = nil; local bestDist = Settings.GlobalAim and math.huge or Settings.FOV

    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("Head") and p.Character:FindFirstChild("Humanoid") and p.Character.Humanoid.Health > 0 then
            local sp, os = Camera:WorldToViewportPoint(p.Character.Head.Position)
            if Settings.GlobalAim or os then
                local dist = os and (Vector2.new(sp.X, sp.Y) - screenCenter).Magnitude or 1000
                if dist < bestDist then bestDist = dist; bestTarget = p.Character end
            end
        end
    end

    if bestTarget then
        _G_SilentTargetPos = bestTarget.Head.Position
        if Settings.AutoShoot and tick() - lastFire > 0.01 then
            lastFire = tick()
            VIM:SendMouseButtonEvent(0, 0, 0, true, game, 1); task.wait(); VIM:SendMouseButtonEvent(0, 0, 0, false, game, 1)
        end
    else _G_SilentTargetPos = nil end
end)

task.spawn(function() while task.wait(3) do ApplyGodMods() end end)
