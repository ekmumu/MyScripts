-- ==========================================
-- MUMU PRO (V48) - 封神介面版 (完整單行展開)
-- ==========================================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

if _G.MUMU_PRO_CONNECTION then _G.MUMU_PRO_CONNECTION:Disconnect() end
if _G.MUMU_FPS_CONNECTION then _G.MUMU_FPS_CONNECTION:Disconnect() end
if _G.MUMU_ESP_DRAWINGS then for _, d in pairs(_G.MUMU_ESP_DRAWINGS) do pcall(function() d.Box:Remove(); d.HealthBg:Remove(); d.HealthBar:Remove() end) end end
_G.MUMU_ESP_DRAWINGS = {}

_G.CurrentDeltaTime = 1/60 
_G.MUMU_FPS_CONNECTION = RunService.RenderStepped:Connect(function(dt) _G.CurrentDeltaTime = dt end)

local WhitelistedPlayers = {}
local Settings = {
    ESP = true, TeamESP = true, ConstantBox = true, HealthBar = true,
    Aimbot = false, SilentAim = false, TriggerBot = false, AutoFireADS = false,
    WallCheck = true, Fly = false, FlySpeed = 100, Noclip = false, InfJump = false, SpeedHack = false, WalkSpeed = 100,
    UseDynamicPred = true, BulletSpeed = 2000, PingComp = 0.05, StaticPred = 0.15,
    FOV = 250, MaxDistance = 500, AimbotSens = 1.0, RageAutoClick = false
}

-- [[ 1. 核心邏輯：隊友與血量防崩潰 ]]
local function IsTeammate(p)
    if p == LocalPlayer or WhitelistedPlayers[p.UserId] then return true end
    if not Settings.TeamESP then return false end
    local s, r = pcall(function() return p:FindFirstChild("ClientData").Team.Value == LocalPlayer:FindFirstChild("ClientData").Team.Value end)
    return s and r or false
end

local function GetHealth(char)
    if not char then return 0, 100 end
    local hp, maxHp = 0, 100
    local hum = char:FindFirstChild("Humanoid")
    if hum then hp = tonumber(hum.Health) or 0; maxHp = tonumber(hum.MaxHealth) or 100 end
    local cHP = char:FindFirstChild("Health") or char:FindFirstChild("HP")
    if cHP and (cHP:IsA("NumberValue") or cHP:IsA("IntValue")) then hp = tonumber(cHP.Value) or hp end
    local cMaxHP = char:FindFirstChild("MaxHealth") or char:FindFirstChild("MaxHP")
    if cMaxHP and (cMaxHP:IsA("NumberValue") or cMaxHP:IsA("IntValue")) then maxHp = tonumber(cMaxHP.Value) or maxHp end
    if maxHp <= 0 or maxHp ~= maxHp then maxHp = 100 end
    if hp ~= hp or hp < 0 then hp = 0 end 
    return math.clamp(hp, 0, maxHp), maxHp
end

local function GetPredictedPosition(targetChar)
    if not targetChar or not targetChar:FindFirstChild("Head") or not targetChar:FindFirstChild("HumanoidRootPart") then return nil end
    local headPos, vel = targetChar.Head.Position, targetChar.HumanoidRootPart.Velocity
    local myPos = Camera.CFrame.Position
    if Settings.UseDynamicPred then
        local timeToHit = ((headPos - myPos).Magnitude / Settings.BulletSpeed) + Settings.PingComp + _G.CurrentDeltaTime
        return headPos + (vel * timeToHit)
    else return headPos + (vel * Settings.StaticPred) end
end

-- [[ 2. 現代化 UI 引擎 ]]
local SafeGui = (gethui and gethui()) or game:GetService("CoreGui")
if SafeGui:FindFirstChild("MUMU_V48") then SafeGui.MUMU_V48:Destroy() end

local SG = Instance.new("ScreenGui", SafeGui); SG.Name = "MUMU_V48"; SG.ResetOnSpawn = false
local Main = Instance.new("Frame", SG); Main.Size = UDim2.fromOffset(600, 400); Main.Position = UDim2.fromScale(0.5, 0.5); Main.AnchorPoint = Vector2.new(0.5, 0.5); Main.BackgroundColor3 = Color3.fromRGB(20, 21, 25)
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 8)
local Title = Instance.new("TextLabel", Main); Title.Size = UDim2.new(0, 150, 0, 40); Title.Position = UDim2.new(0, 15, 0, 5); Title.Text = "Z3US | Rivals (MUMU)"; Title.TextColor3 = Color3.new(1,1,1); Title.Font = Enum.Font.GothamBold; Title.TextSize = 16; Title.BackgroundTransparency = 1; Title.TextXAlignment = Enum.TextXAlignment.Left

local Sidebar = Instance.new("Frame", Main); Sidebar.Size = UDim2.new(0, 150, 1, -50); Sidebar.Position = UDim2.new(0, 0, 0, 50); Sidebar.BackgroundTransparency = 1
local SidebarLayout = Instance.new("UIListLayout", Sidebar); SidebarLayout.Padding = UDim.new(0, 5); SidebarLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
local ContentArea = Instance.new("Frame", Main); ContentArea.Size = UDim2.new(1, -160, 1, -50); ContentArea.Position = UDim2.new(0, 160, 0, 50); ContentArea.BackgroundTransparency = 1

local Tabs = {}
local function CreateTab(name, isFirst)
    local btn = Instance.new("TextButton", Sidebar); btn.Size = UDim2.new(0.9, 0, 0, 35); btn.Text = "  " .. name; btn.Font = Enum.Font.GothamSemibold; btn.TextSize = 14; btn.TextColor3 = Color3.new(1,1,1); btn.TextXAlignment = Enum.TextXAlignment.Left; Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    local page = Instance.new("ScrollingFrame", ContentArea); page.Size = UDim2.new(1, 0, 1, 0); page.BackgroundTransparency = 1; page.ScrollBarThickness = 2; page.Visible = isFirst
    local layout = Instance.new("UIListLayout", page); layout.Padding = UDim.new(0, 8)
    
    if isFirst then btn.BackgroundColor3 = Color3.fromRGB(30, 31, 38) else btn.BackgroundColor3 = Color3.fromRGB(20, 21, 25) end
    btn.MouseButton1Click:Connect(function()
        for _, t in pairs(Tabs) do t.Btn.BackgroundColor3 = Color3.fromRGB(20, 21, 25); t.Page.Visible = false end
        btn.BackgroundColor3 = Color3.fromRGB(30, 31, 38); page.Visible = true
    end)
    table.insert(Tabs, {Btn = btn, Page = page}); return page
end

local function CreateToggle(parent, name, key)
    local frame = Instance.new("Frame", parent); frame.Size = UDim2.new(1, -10, 0, 40); frame.BackgroundColor3 = Color3.fromRGB(26, 28, 33); Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 6); Instance.new("UIStroke", frame).Color = Color3.fromRGB(40, 42, 48)
    local lbl = Instance.new("TextLabel", frame); lbl.Size = UDim2.new(0.8, 0, 1, 0); lbl.Position = UDim2.new(0, 15, 0, 0); lbl.Text = name; lbl.TextColor3 = Color3.new(1,1,1); lbl.Font = Enum.Font.Gotham; lbl.TextSize = 14; lbl.BackgroundTransparency = 1; lbl.TextXAlignment = Enum.TextXAlignment.Left
    local btn = Instance.new("TextButton", frame); btn.Size = UDim2.new(0, 40, 0, 20); btn.Position = UDim2.new(1, -55, 0.5, -10); btn.Text = ""; Instance.new("UICorner", btn).CornerRadius = UDim.new(1, 0)
    local function update() if Settings[key] then btn.BackgroundColor3 = Color3.fromRGB(140, 155, 208) else btn.BackgroundColor3 = Color3.fromRGB(60, 60, 65) end end
    update(); btn.MouseButton1Click:Connect(function() Settings[key] = not Settings[key]; update() end)
end

local function CreateSlider(parent, name, key, min, max)
    local frame = Instance.new("Frame", parent); frame.Size = UDim2.new(1, -10, 0, 40); frame.BackgroundColor3 = Color3.fromRGB(26, 28, 33); Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 6); Instance.new("UIStroke", frame).Color = Color3.fromRGB(40, 42, 48)
    local lbl = Instance.new("TextLabel", frame); lbl.Size = UDim2.new(0.5, 0, 1, 0); lbl.Position = UDim2.new(0, 15, 0, 0); lbl.Text = name; lbl.TextColor3 = Color3.new(1,1,1); lbl.Font = Enum.Font.Gotham; lbl.TextSize = 14; lbl.BackgroundTransparency = 1; lbl.TextXAlignment = Enum.TextXAlignment.Left
    local val = Instance.new("TextLabel", frame); val.Size = UDim2.new(0, 30, 1, 0); val.Position = UDim2.new(1, -150, 0, 0); val.Text = tostring(Settings[key]); val.TextColor3 = Color3.fromRGB(150, 150, 150); val.Font = Enum.Font.Gotham; val.TextSize = 12; val.BackgroundTransparency = 1
    local track = Instance.new("Frame", frame); track.Size = UDim2.new(0, 100, 0, 4); track.Position = UDim2.new(1, -115, 0.5, -2); track.BackgroundColor3 = Color3.fromRGB(60, 60, 65); Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)
    local fill = Instance.new("Frame", track); fill.Size = UDim2.new((Settings[key]-min)/(max-min), 0, 1, 0); fill.BackgroundColor3 = Color3.fromRGB(140, 155, 208); Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)
    local btn = Instance.new("TextButton", track); btn.Size = UDim2.new(1, 0, 0, 20); btn.Position = UDim2.new(0, 0, 0.5, -10); btn.BackgroundTransparency = 1; btn.Text = ""
    local dragging = false
    btn.MouseButton1Down:Connect(function() dragging = true end)
    UserInputService.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local pct = math.clamp((input.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
            fill.Size = UDim2.new(pct, 0, 1, 0)
            local newVal = min + (max - min) * pct; Settings[key] = math.floor(newVal * 100)/100; val.Text = tostring(Settings[key])
        end
    end)
end

local TabLegit = CreateTab("Legit", true)
CreateToggle(TabLegit, "Enable Aimbot", "Aimbot")
CreateToggle(TabLegit, "Wall Check", "WallCheck")
CreateToggle(TabLegit, "TriggerBot (Auto Shoot)", "TriggerBot")
CreateSlider(TabLegit, "Aimbot Smoothness", "AimbotSens", 0.1, 2.0)
CreateSlider(TabLegit, "Aimbot FOV", "FOV", 50, 800)

local TabRage = CreateTab("Rage", false)
CreateToggle(TabRage, "360 Silent Aim (Magic Bullet)", "SilentAim")
CreateToggle(TabRage, "Auto Click When ADS", "RageAutoClick")
CreateToggle(TabRage, "Enable Dynamic Prediction", "UseDynamicPred")
CreateSlider(TabRage, "Bullet Speed (Pred)", "BulletSpeed", 500, 5000)

local TabVisuals = CreateTab("Visuals", false)
CreateToggle(TabVisuals, "Enable ESP", "ESP")
CreateToggle(TabVisuals, "Constant Box Size", "ConstantBox")
CreateToggle(TabVisuals, "Show Health Bar", "HealthBar")
CreateToggle(TabVisuals, "Team ESP", "TeamESP")

local TabPlayer = CreateTab("Player", false)
CreateToggle(TabPlayer, "Enable Fly", "Fly")
CreateSlider(TabPlayer, "Fly Speed", "FlySpeed", 20, 300)
CreateToggle(TabPlayer, "Speed Hack", "SpeedHack")
CreateSlider(TabPlayer, "Walk Speed", "WalkSpeed", 16, 300)
CreateToggle(TabPlayer, "Infinite Jump", "InfJump")
CreateToggle(TabPlayer, "Noclip", "Noclip")

-- UI 拖曳邏輯
local draggingUI, dragInput, dragStart, startPos
Main.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 then draggingUI = true; dragStart = input.Position; startPos = Main.Position end end)
Main.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 then draggingUI = false end end)
UserInputService.InputChanged:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseMovement then dragInput = input end end)
RunService.RenderStepped:Connect(function() if draggingUI and dragInput then local delta = dragInput.Position - dragStart; Main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y) end end)
UserInputService.InputBegan:Connect(function(i, gp) if not gp and i.KeyCode == Enum.KeyCode.J then Main.Visible = not Main.Visible end end)

-- [[ 3. 外掛核心系統 ]]
local FlyBodyGyro, FlyBodyVelocity, CONTROL = nil, nil, {F=0, B=0, L=0, R=0, UP=0, DOWN=0}
UserInputService.InputBegan:Connect(function(i, gp) if not gp then local k=i.KeyCode; if k==Enum.KeyCode.W then CONTROL.F=1 elseif k==Enum.KeyCode.S then CONTROL.B=-1 elseif k==Enum.KeyCode.A then CONTROL.L=-1 elseif k==Enum.KeyCode.D then CONTROL.R=1 elseif k==Enum.KeyCode.Space then CONTROL.UP=1 elseif k==Enum.KeyCode.LeftControl then CONTROL.DOWN=-1 elseif k==Enum.KeyCode.T then local c, md, ctr = nil, Settings.FOV, Camera.ViewportSize/2; for _, p in pairs(Players:GetPlayers()) do if p~=LocalPlayer and p.Character and p.Character:FindFirstChild("Head") then local pos, os = Camera:WorldToViewportPoint(p.Character.Head.Position) if os then local d = (Vector2.new(pos.X, pos.Y)-ctr).Magnitude; if d<md then md=d; c=p end end end end; if c then WhitelistedPlayers[c.UserId] = not WhitelistedPlayers[c.UserId] end end end end)
UserInputService.InputEnded:Connect(function(i) local k=i.KeyCode; if k==Enum.KeyCode.W then CONTROL.F=0 elseif k==Enum.KeyCode.S then CONTROL.B=0 elseif k==Enum.KeyCode.A then CONTROL.L=0 elseif k==Enum.KeyCode.D then CONTROL.R=0 elseif k==Enum.KeyCode.Space then CONTROL.UP=0 elseif k==Enum.KeyCode.LeftControl then CONTROL.DOWN=0 end end)
UserInputService.JumpRequest:Connect(function() if Settings.InfJump and LocalPlayer.Character then local hum=LocalPlayer.Character:FindFirstChild("Humanoid") if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end end end)

local function IsVisible(tChar)
    if not Settings.WallCheck or not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("Head") then return true end
    local r = workspace:Raycast(Camera.CFrame.Position, tChar.Head.Position - Camera.CFrame.Position, RaycastParams.new({FilterType = Enum.RaycastFilterType.Exclude, FilterDescendantsInstances = {LocalPlayer.Character, Camera}, IgnoreWater = true}))
    return r and r.Instance:IsDescendantOf(tChar) or not r
end

-- ⚡ 360 魔術彈攔截器
if hookmetamethod then
    local OldNC = hookmetamethod(game, "__namecall", function(self, ...)
        local m = getnamecallmethod(); local a = {...}
        if not checkcaller() and Settings.SilentAim and _G.SilentTarget then
            local fp = GetPredictedPosition(_G.SilentTarget)
            if fp and (m == "Raycast" or m == "FindPartOnRay" or m == "FindPartOnRayWithIgnoreList") then
                if m == "Raycast" and typeof(a[2]) == "Vector3" then a[2] = (fp - a[1]).Unit * 5000; return OldNC(self, unpack(a)) end
                if typeof(a[1]) == "Ray" then a[1] = Ray.new(a[1].Origin, (fp - a[1].Origin).Unit * 5000); return OldNC(self, unpack(a)) end
            end
        end
        return OldNC(self, ...)
    end)
    local OldIdx = hookmetamethod(game, "__index", function(self, k)
        if not checkcaller() and Settings.SilentAim and _G.SilentTarget then
            local fp = GetPredictedPosition(_G.SilentTarget)
            if fp and typeof(self) == "Instance" and self:IsA("Mouse") then
                if k == "Hit" then return CFrame.new(fp) elseif k == "Target" then return _G.SilentTarget:FindFirstChild("Head") end
            end
        end
        return OldIdx(self, k)
    end)
end

local function FireWeapon() if mouse1click then pcall(mouse1click) else VirtualInputManager:SendMouseButtonEvent(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2, 0, true, game, 1); task.wait(0.01); VirtualInputManager:SendMouseButtonEvent(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2, 0, false, game, 1) end end

local LockedTarget = nil; local lastFire = 0
_G.MUMU_PRO_CONNECTION = RunService.RenderStepped:Connect(function()
    -- Fly, Noclip, Speed
    if LocalPlayer.Character then
        if Settings.Fly and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            local hrp = LocalPlayer.Character.HumanoidRootPart
            if not hrp:FindFirstChild("MUMU_GYRO") then FlyBodyGyro=Instance.new("BodyGyro", hrp); FlyBodyGyro.Name="MUMU_GYRO"; FlyBodyGyro.P=9e4; FlyBodyGyro.maxTorque=Vector3.new(9e9,9e9,9e9); FlyBodyVelocity=Instance.new("BodyVelocity", hrp); FlyBodyVelocity.Name="MUMU_VELOCITY"; FlyBodyVelocity.maxForce=Vector3.new(9e9,9e9,9e9) end
            FlyBodyGyro.cframe = Camera.CFrame; FlyBodyVelocity.velocity = ((Camera.CFrame.LookVector*(CONTROL.F+CONTROL.B)) + (Camera.CFrame.RightVector*(CONTROL.L+CONTROL.R)) + (Camera.CFrame.UpVector*(CONTROL.UP+CONTROL.DOWN))).Magnitude > 0 and ((Camera.CFrame.LookVector*(CONTROL.F+CONTROL.B)) + (Camera.CFrame.RightVector*(CONTROL.L+CONTROL.R)) + (Camera.CFrame.UpVector*(CONTROL.UP+CONTROL.DOWN))).Unit * Settings.FlySpeed or Vector3.new(0,0,0)
            if LocalPlayer.Character:FindFirstChild("Humanoid") then LocalPlayer.Character.Humanoid.PlatformStand = true end
        elseif LocalPlayer.Character:FindFirstChild("HumanoidRootPart") and LocalPlayer.Character.HumanoidRootPart:FindFirstChild("MUMU_GYRO") then
            LocalPlayer.Character.HumanoidRootPart.MUMU_GYRO:Destroy(); LocalPlayer.Character.HumanoidRootPart.MUMU_VELOCITY:Destroy()
            if LocalPlayer.Character:FindFirstChild("Humanoid") then LocalPlayer.Character.Humanoid.PlatformStand = false end
        end
        if Settings.Noclip then for _, p in pairs(LocalPlayer.Character:GetDescendants()) do if p:IsA("BasePart") and p.CanCollide then p.CanCollide = false end end end
        if Settings.SpeedHack and LocalPlayer.Character:FindFirstChild("Humanoid") then LocalPlayer.Character.Humanoid.WalkSpeed = Settings.WalkSpeed end
    end

    -- ESP 繪製 (含恆定大小方框)
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            if not _G.MUMU_ESP_DRAWINGS[p] then _G.MUMU_ESP_DRAWINGS[p] = { Box = Drawing.new("Square"), HealthBg = Drawing.new("Line"), HealthBar = Drawing.new("Line") }; local d = _G.MUMU_ESP_DRAWINGS[p]; d.Box.Color = Color3.fromRGB(255, 50, 50); d.Box.Thickness = 1.5; d.Box.Filled = false; d.HealthBg.Color = Color3.fromRGB(0,0,0); d.HealthBg.Thickness = 4; d.HealthBar.Thickness = 2 end
            local d = _G.MUMU_ESP_DRAWINGS[p]
            local hp, maxHp = GetHealth(p.Character)
            if Settings.ESP and p.Character and p.Character:FindFirstChild("HumanoidRootPart") and hp > 0 and not IsTeammate(p) then
                local hrp = p.Character.HumanoidRootPart
                local topPos, onScreen = Camera:WorldToViewportPoint(hrp.Position + Vector3.new(0, 2.5, 0))
                local bottomPos = Camera:WorldToViewportPoint(hrp.Position - Vector3.new(0, 3, 0))
                local centerPos = Camera:WorldToViewportPoint(hrp.Position)
                if onScreen and (hrp.Position - Camera.CFrame.Position).Magnitude < Settings.MaxDistance then
                    -- 恆定尺寸或動態尺寸
                    local height, width
                    if Settings.ConstantBox then width, height = 40, 60 else height = math.abs(topPos.Y - bottomPos.Y); width = height * 0.6 end
                    
                    d.Box.Size = Vector2.new(width, height); d.Box.Position = Vector2.new(centerPos.X - width/2, centerPos.Y - height/2); d.Box.Visible = true
                    
                    if Settings.HealthBar then
                        local pct = math.clamp(hp/maxHp, 0, 1)
                        local barX, barYBottom, barYTop = centerPos.X - width/2 - 6, centerPos.Y + height/2, centerPos.Y - height/2
                        d.HealthBg.From = Vector2.new(barX, barYBottom); d.HealthBg.To = Vector2.new(barX, barYTop); d.HealthBg.Visible = true
                        d.HealthBar.From = Vector2.new(barX, barYBottom); d.HealthBar.To = Vector2.new(barX, barYBottom - (height * pct)); d.HealthBar.Color = Color3.fromHSV(pct * 0.3, 1, 1); d.HealthBar.Visible = true
                    else d.HealthBg.Visible = false; d.HealthBar.Visible = false end
                else d.Box.Visible = false; d.HealthBg.Visible = false; d.HealthBar.Visible = false end
            else d.Box.Visible = false; d.HealthBg.Visible = false; d.HealthBar.Visible = false end
        end
    end

    -- 戰鬥系統 (Aimbot & 360 魔術彈 & 自動連點)
    local isRC = UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
    local myPos = Camera.CFrame.Position
    _G.SilentTarget = nil; LockedTarget = nil
    
    -- 搜尋目標
    local mdA, mdS = Settings.FOV, Settings.MaxDistance
    for _, p in pairs(Players:GetPlayers()) do
        local hp, _ = GetHealth(p.Character)
        if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("Head") and hp > 0 and not IsTeammate(p) and IsVisible(p.Character) then
            local tPos = p.Character.Head.Position
            if Settings.SilentAim and (tPos - myPos).Magnitude < mdS then mdS = (tPos - myPos).Magnitude; _G.SilentTarget = p.Character end
            if Settings.Aimbot or Settings.TriggerBot then
                local sp, os = Camera:WorldToViewportPoint(tPos)
                if os then local d = (Vector2.new(sp.X, sp.Y) - Camera.ViewportSize/2).Magnitude; if d < mdA then mdA = d; LockedTarget = p.Character end end
            end
        end
    end

    -- Rage Auto Click (只要開啟魔術彈且按住右鍵，全自動開火)
    if Settings.SilentAim and Settings.RageAutoClick and isRC and _G.SilentTarget and tick() - lastFire > 0.05 then
        FireWeapon(); lastFire = tick()
    end

    -- Legit Aimbot
    if LockedTarget and isRC and Settings.Aimbot then
        local fp = GetPredictedPosition(LockedTarget)
        if fp then
            local sp, os = Camera:WorldToViewportPoint(fp)
            if os and mousemoverel then mousemoverel((sp.X - Camera.ViewportSize.X/2) * Settings.AimbotSens, (sp.Y - Camera.ViewportSize.Y/2) * Settings.AimbotSens) end
        end
    end
end)
