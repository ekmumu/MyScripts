-- ==========================================
-- MUMU PRO (V65) - 終極神權版 (Spawn Wipe + Skin Hook)
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
_G.MUMU_DRAWINGS = {}

local Settings = {
    -- 戰鬥設定
    Aimbot = true, FOV = 800, GlobalAim = true, 
    SilentAim = true, Wallbang = true, AutoShoot = true, 
    RapidFire = true, NoRecoil = true,
    -- 造型與特效 (Skin Changer)
    SkinChanger = true, TargetSkin = "Galaxy", TargetEffect = "Lightning",
    -- 物理與移動
    Fly = false, FlySpeed = 75, BarrierBypass = true,
    ThirdPerson = false, WalkSpeed = 150
}

-- ⚡ [Skin Changer 核心攔截] ⚡
if hookmetamethod then
    local OldIdx
    OldIdx = hookmetamethod(game, "__index", function(self, k)
        if not checkcaller() and Settings.SkinChanger then
            -- 欺騙客戶端已擁有造型與特效
            if k == "EquippedWrap" or k == "Skin" or k == "WeaponSkin" then return Settings.TargetSkin
            elseif k == "EquippedKillEffect" or k == "KillEffect" then return Settings.TargetEffect 
            elseif k == "OwnedWraps" or k == "OwnedEffects" then return { [Settings.TargetSkin] = true, [Settings.TargetEffect] = true } end
        end
        return OldIdx(self, k)
    end)
end

-- ⚡ [記憶體暴力改槍] ⚡
local function ApplyGodMods()
    if not getgc then return end
    for _, v in pairs(getgc(true)) do
        if type(v) == "table" then
            if Settings.RapidFire and rawget(v, "FireRate") then rawset(v, "FireRate", 0.0001) end
            if Settings.NoRecoil and rawget(v, "Recoil") then rawset(v, "Recoil", 0); rawset(v, "Spread", 0) end
        end
    end
end

-- ⚡ [越界飛行與物理屏蔽] ⚡
local FlyBodyGyro, FlyBodyVelocity, CONTROL = nil, nil, {F=0, B=0, L=0, R=0, UP=0, DOWN=0}
RunService.Stepped:Connect(function()
    if Settings.BarrierBypass and LocalPlayer.Character then
        for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
            if part:IsA("BasePart") then part.CanCollide = false end -- 穿透死牆
        end
    end
end)

-- ⚡ [全圖秒殺邏輯] ⚡
local _G_SilentTargetPos = nil
local lastFire = 0
local function AutoWipe()
    if Settings.AutoShoot and _G_SilentTargetPos and (tick() - lastFire > 0.005) then
        lastFire = tick()
        VIM:SendMouseButtonEvent(0, 0, 0, true, game, 1)
        task.wait()
        VIM:SendMouseButtonEvent(0, 0, 0, false, game, 1)
    end
end

-- ⚡ [高級介面 UI] ⚡
local SafeGui = (gethui and gethui()) or game:GetService("CoreGui")
if SafeGui:FindFirstChild("MUMU_UI") then SafeGui.MUMU_UI:Destroy() end
local SG = Instance.new("ScreenGui", SafeGui); SG.Name = "MUMU_UI"
local Main = Instance.new("Frame", SG); Main.Size = UDim2.fromOffset(620, 440); Main.Position = UDim2.fromScale(0.5, 0.5); Main.AnchorPoint = Vector2.new(0.5, 0.5); Main.BackgroundColor3 = Color3.fromRGB(15, 15, 20); Main.BorderSizePixel = 0; Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 15)
local Title = Instance.new("TextLabel", Main); Title.Size = UDim2.new(1, 0, 0, 60); Title.Text = "  MUMU PRO PREMIUM"; Title.TextColor3 = Color3.fromRGB(255, 215, 0); Title.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold); Title.TextSize = 22; Title.BackgroundTransparency = 1; Title.TextXAlignment = Enum.TextXAlignment.Left

-- 介面開關功能與自瞄渲染
_G.MUMU_CONN = RunService.RenderStepped:Connect(function()
    local screenCenter = Camera.ViewportSize / 2
    local bestTarget = nil; local bestDist = Settings.GlobalAim and math.huge or Settings.FOV

    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("Head") then
            local hum = p.Character:FindFirstChild("Humanoid")
            if hum and hum.Health > 0 then
                local headPos = p.Character.Head.Position
                local sp, os = Camera:WorldToViewportPoint(headPos)
                if Settings.GlobalAim or os then
                    local dist = os and (Vector2.new(sp.X, sp.Y) - screenCenter).Magnitude or 1000
                    if dist < bestDist then bestDist = dist; bestTarget = p.Character end
                end
            end
        end
    end

    if bestTarget then
        _G_SilentTargetPos = bestTarget.Head.Position
        AutoWipe() -- 執行秒殺
    else _G_SilentTargetPos = nil end

    -- 飛行物理更新
    if Settings.Fly and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        local hrp = LocalPlayer.Character.HumanoidRootPart
        if not hrp:FindFirstChild("MUMU_GYRO") then
            FlyBodyGyro = Instance.new("BodyGyro", hrp); FlyBodyGyro.Name = "MUMU_GYRO"; FlyBodyGyro.maxTorque = Vector3.new(9e9, 9e9, 9e9); FlyBodyGyro.P = 9e4
            FlyBodyVelocity = Instance.new("BodyVelocity", hrp); FlyBodyVelocity.Name = "MUMU_VELOCITY"; FlyBodyVelocity.maxForce = Vector3.new(9e9, 9e9, 9e9)
        end
        FlyBodyGyro.cframe = Camera.CFrame
        FlyBodyVelocity.velocity = ((Camera.CFrame.LookVector*(CONTROL.F+CONTROL.B)) + (Camera.CFrame.RightVector*(CONTROL.L+CONTROL.R)) + (Camera.CFrame.UpVector*(CONTROL.UP+CONTROL.DOWN))).Unit * Settings.FlySpeed
    end
end)

-- 初始改槍與造型
task.spawn(function()
    while task.wait(3) do ApplyGodMods() end
end)

-- 快捷鍵綁定
UIS.InputBegan:Connect(function(i, gp)
    if gp then return end
    if i.KeyCode == Enum.KeyCode.V then Settings.Fly = not Settings.Fly
    elseif i.KeyCode == Enum.KeyCode.M then Settings.ThirdPerson = not Settings.ThirdPerson 
    elseif i.KeyCode == Enum.KeyCode.Insert then Main.Visible = not Main.Visible end
end)
