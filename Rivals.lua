-- ==========================================
-- MUMU PRO (V49) - 終極介面還原 + 後台監控版
-- ==========================================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local VIM = game:GetService("VirtualInputManager")
local HttpService = game:GetService("HttpService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- ⚡ [1. 執行者監控系統 (Discord Webhook)] ⚡
-- ⚠️ 記得把下面這行換成你自己的 Webhook 網址，填好後務必將代碼混淆 (Obfuscate) 再發給別人！
local WebhookURL = "YOUR_WEBHOOK_URL_HERE" 

local function LogExecution()
    if WebhookURL == "" or WebhookURL == "YOUR_WEBHOOK_URL_HERE" then return end
    local req = http_request or request or HttpPost or (syn and syn.request)
    if req then
        local data = {
            embeds = {{
                title = "💉 MUMU PRO 腳本被執行了！",
                color = 9214928, -- 淺紫色
                fields = {
                    {name = "👤 玩家名稱", value = LocalPlayer.Name, inline = true},
                    {name = "🆔 玩家 ID", value = tostring(LocalPlayer.UserId), inline = true},
                    {name = "🎮 遊戲 ID", value = tostring(game.PlaceId), inline = true},
                    {name = "🔗 伺服器 JobId", value = game.JobId, inline = false}
                },
                footer = {text = "MUMU Security System | " .. os.date("%Y-%m-%d %H:%M:%S")}
            }}
        }
        pcall(function() req({Url = WebhookURL, Method = "POST", Headers = {["Content-Type"] = "application/json"}, Body = HttpService:JSONEncode(data)}) end)
    end
end
task.spawn(LogExecution)

-- ⚡ [2. 核心防禦與變數] ⚡
if _G.MUMU_CONN then _G.MUMU_CONN:Disconnect() end
if _G.MUMU_NOCLIP then _G.MUMU_NOCLIP:Disconnect() end
if _G.MUMU_DRAWINGS then for _, d in pairs(_G.MUMU_DRAWINGS) do pcall(function() d.Box:Remove(); d.HealthBg:Remove(); d.HealthBar:Remove() end) end end
_G.MUMU_DRAWINGS = {}
_G.CurrentDT = 1/60 
RunService.RenderStepped:Connect(function(dt) _G.CurrentDT = dt end)

local Whitelisted = {}
local Settings = {
    ESP = true, TeamESP = true, ConstantBox = true, HealthBar = true,
    Aimbot = false, SilentAim = false, TriggerBot = false, AutoFireADS = false, RageAutoClick = false,
    WallCheck = true, Fly = false, FlySpeed = 100, Noclip = false, InfJump = false, SpeedHack = false, WalkSpeed = 100,
    UseDynamicPred = true, BulletSpeed = 2000, PingComp = 0.05, StaticPred = 0.15,
    FOV = 250, MaxDistance = 500, AimbotSens = 1.0
}

-- ⚡ [3. 遊戲邏輯與防崩潰函式] ⚡
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
    local s, r = pcall(function() return p:FindFirstChild("ClientData").Team.Value == LocalPlayer:FindFirstChild("ClientData").Team.Value end)
    return s and r or false
end

local function GetHealth(c)
    if not c then return 0, 100 end
    local hp, mx = 0, 100
    local hum = c:FindFirstChild("Humanoid")
    if hum then hp = tonumber(hum.Health) or 0; mx = tonumber(hum.MaxHealth) or 100 end
    local chp = c:FindFirstChild("Health") or c:FindFirstChild("HP")
    if chp and (chp:IsA("NumberValue") or chp:IsA("IntValue")) then hp = tonumber(chp.Value) or hp end
    local cmx = c:FindFirstChild("MaxHealth") or c:FindFirstChild("MaxHP")
    if cmx and (cmx:IsA("NumberValue") or cmx:IsA("IntValue")) then mx = tonumber(cmx.Value) or mx end
    if mx <= 0 or mx ~= mx then mx = 100 end
    if hp ~= hp or hp < 0 then hp = 0 end 
    return math.clamp(hp, 0, mx), mx
end

local function GetPred(tChar)
    if not tChar or not tChar:FindFirstChild("Head") or not tChar:FindFirstChild("HumanoidRootPart") then return nil end
    local hp, vel = tChar.Head.Position, tChar.HumanoidRootPart.Velocity
    local mp = Camera.CFrame.Position
    if Settings.UseDynamicPred then
        return hp + (vel * (((hp - mp).Magnitude / Settings.BulletSpeed) + Settings.PingComp + _G.CurrentDT))
    else return hp + (vel * Settings.StaticPred) end
end

-- ⚡ [4. 現代化 UI 引擎 (Nunito字體, 深灰底, 淺紫點綴)] ⚡
local SafeGui = (gethui and gethui()) or game:GetService("CoreGui")
if SafeGui:FindFirstChild("MUMU_UI") then SafeGui.MUMU_UI:Destroy() end

local SG = Instance.new("ScreenGui", SafeGui); SG.Name = "MUMU_UI"; SG.ResetOnSpawn = false
local Main = Instance.new("Frame", SG); Main.Size = UDim2.fromOffset(580, 420); Main.Position = UDim2.fromScale(0.5, 0.5); Main.AnchorPoint = Vector2.new(0.5, 0.5); Main.BackgroundColor3 = Color3.fromRGB(17, 18, 20); Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 8); Instance.new("UIStroke", Main).Color = Color3.fromRGB(26, 29, 37); Instance.new("UIStroke", Main).Thickness = 1.5

local Title = Instance.new("TextLabel", Main); Title.Size = UDim2.new(1, 0, 0, 50); Title.Position = UDim2.new(0, 20, 0, 0); Title.Text = "MUMU PRO"; Title.TextColor3 = Color3.new(1,1,1); Title.FontFace = Font.new("rbxasset://fonts/families/Nunito.json", Enum.FontWeight.Bold); Title.TextSize = 22; Title.BackgroundTransparency = 1; Title.TextXAlignment = Enum.TextXAlignment.Left

local Sidebar = Instance.new("Frame", Main); Sidebar.Size = UDim2.new(0, 140, 1, -60); Sidebar.Position = UDim2.new(0, 10, 0, 50); Sidebar.BackgroundTransparency = 1
local SidebarLayout = Instance.new("UIListLayout", Sidebar); SidebarLayout.Padding = UDim.new(0, 6); SidebarLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
local ContentArea = Instance.new("Frame", Main); ContentArea.Size = UDim2.new(1, -160, 1, -60); ContentArea.Position = UDim2.new(0, 150, 0, 50); ContentArea.BackgroundTransparency = 1

local Tabs = {}
local function CreateTab(name, isFirst)
    local btn = Instance.new("TextButton", Sidebar); btn.Size = UDim2.new(1, 0, 0, 36); btn.Text = "  " .. name; btn.FontFace = Font.new("rbxasset://fonts/families/Nunito.json", Enum.FontWeight.SemiBold); btn.TextSize = 16; btn.TextColor3 = Color3.new(1,1,1); btn.TextXAlignment = Enum.TextXAlignment.Left; Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    local page = Instance.new("ScrollingFrame", ContentArea); page.Size = UDim2.new(1, -10, 1, 0); page.BackgroundTransparency = 1; page.ScrollBarThickness = 2; page.Visible = isFirst; page.CanvasSize = UDim2.new(0,0,1.5,0)
    local layout = Instance.new("UIListLayout", page); layout.Padding = UDim.new(0, 8)
    
    if isFirst then btn.BackgroundColor3 = Color3.fromRGB(30, 32, 38) else btn.BackgroundColor3 = Color3.fromRGB(17, 18, 20) end
    btn.MouseButton1Click:Connect(function()
        for _, t in pairs(Tabs) do t.Btn.BackgroundColor3 = Color3.fromRGB(17, 18, 20); t.Page.Visible = false end
        btn.BackgroundColor3 = Color3.fromRGB(30, 32, 38); page.Visible = true
    end)
    table.insert(Tabs, {Btn = btn, Page = page}); return page
end

local function CreateToggle(parent, name, key, callback)
    local frame = Instance.new("Frame", parent); frame.Size = UDim2.new(1, -10, 0, 42); frame.BackgroundColor3 = Color3.fromRGB(24, 25, 29); Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 6); Instance.new("UIStroke", frame).Color = Color3.fromRGB(35, 37, 43)
    local lbl = Instance.new("TextLabel", frame); lbl.Size = UDim2.new(0.8, 0, 1, 0); lbl.Position = UDim2.new(0, 15, 0, 0); lbl.Text = name; lbl.TextColor3 = Color3.new(1,1,1); lbl.FontFace = Font.new("rbxasset://fonts/families/Nunito.json"); lbl.TextSize = 15; lbl.BackgroundTransparency = 1; lbl.TextXAlignment = Enum.TextXAlignment.Left
    local btn = Instance.new("TextButton", frame); btn.Size = UDim2.new(0, 44, 0, 22); btn.Position = UDim2.new(1, -60, 0.5, -11); btn.Text = ""; Instance.new("UICorner", btn).CornerRadius = UDim.new(1, 0)
    local function update() if Settings[key] then btn.BackgroundColor3 = Color3.fromRGB(140, 155, 208) else btn.BackgroundColor3 = Color3.fromRGB(60, 60, 65) end end
    update(); btn.MouseButton1Click:Connect(function() Settings[key] = not Settings[key]; update(); if callback then callback(Settings[key]) end end)
end

local function CreateSlider(parent, name, key, min, max)
    local frame = Instance.new("Frame", parent); frame.Size = UDim2.new(1, -10, 0, 50); frame.BackgroundColor3 = Color3.fromRGB(24, 25, 29); Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 6); Instance.new("UIStroke", frame).Color = Color3.fromRGB(35, 37, 43)
    local lbl = Instance.new("TextLabel", frame); lbl.Size = UDim2.new(0.5, 0, 0.5, 0); lbl.Position = UDim2.new(0, 15, 0, 5); lbl.Text = name; lbl.TextColor3 = Color3.new(1,1,1); lbl.FontFace = Font.new("rbxasset://fonts/families/Nunito.json"); lbl.TextSize = 14; lbl.BackgroundTransparency = 1; lbl.TextXAlignment = Enum.TextXAlignment.Left
    local val = Instance.new("TextLabel", frame); val.Size = UDim2.new(0, 30, 0.5, 0); val.Position = UDim2.new(1, -45, 0, 5); val.Text = tostring(Settings[key]); val.TextColor3 = Color3.fromRGB(140, 155, 208); val.FontFace = Font.new("rbxasset://fonts/families/Nunito.json", Enum.FontWeight.Bold); val.TextSize = 14; val.BackgroundTransparency = 1; val.TextXAlignment = Enum.TextXAlignment.Right
    local track = Instance.new("Frame", frame); track.Size = UDim2.new(1, -30, 0, 6); track.Position = UDim2.new(0, 15, 1, -15); track.BackgroundColor3 = Color3.fromRGB(40, 42, 48); Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)
    local fill = Instance.new("Frame", track); fill.Size = UDim2.new((Settings[key]-min)/(max-min), 0, 1, 0); fill.BackgroundColor3 = Color3.fromRGB(140, 155, 208); Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)
    local btn = Instance.new("TextButton", track); btn.Size = UDim2.new(1, 0, 0, 20); btn.Position = UDim2.new(0, 0, 0.5, -10); btn.BackgroundTransparency = 1; btn.Text = ""
    local dragging = false
    btn.MouseButton1Down:Connect(function() dragging = true end)
    UIS.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end end)
    UIS.InputChanged:Connect(function(i)
        if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
            local pct = math.clamp((i.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
            fill.Size = UDim2.new(pct, 0, 1, 0)
            Settings[key] = math.floor((min + (max - min) * pct) * 100)/100; val.Text = tostring(Settings[key])
        end
    end)
end

-- 建立分頁
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
CreateToggle(TabPlayer, "Noclip", "Noclip", function(state) ToggleNoclip(state) end)

-- UI 拖曳
local draggingUI, dragInput, dragStart, startPos
Main.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then draggingUI = true; dragStart = i.Position; startPos = Main.Position end end)
Main.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then draggingUI = false end end)
UIS.InputChanged:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseMovement then dragInput = i end end)
RunService.RenderStepped:Connect(function() if draggingUI and dragInput then local delta = dragInput.Position - dragStart; Main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y) end end)
UIS.InputBegan:Connect(function(i, gp) if not gp and i.KeyCode == Enum.KeyCode.J then Main.Visible = not Main.Visible end end)

-- 白名單快捷鍵 [T] 或滑鼠中鍵
UIS.InputBegan:Connect(function(i, gp)
    if not gp and (i.KeyCode == Enum.KeyCode.T or i.UserInputType == Enum.UserInputType.MouseButton3) then
        local c, md, ctr = nil, Settings.FOV, Camera.ViewportSize/2
        for _, p in pairs(Players:GetPlayers()) do
            if p~=LocalPlayer and p.Character and p.Character:FindFirstChild("Head") then
                local pos, os = Camera:WorldToViewportPoint(p.Character.Head.Position)
                if os then local d = (Vector2.new(pos.X, pos.Y)-ctr).Magnitude; if d<md then md=d; c=p end end
            end
        end
        if c then Whitelisted[c.UserId] = not Whitelisted[c.UserId] end
    end
end)

-- 無限跳躍
UIS.JumpRequest:Connect(function()
    if Settings.InfJump and LocalPlayer.Character then
        local hum = LocalPlayer.Character:FindFirstChild("Humanoid")
        if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end)

local function IsVisible(tChar)
    if not Settings.WallCheck or not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("Head") then return true end
    local r = workspace:Raycast(Camera.CFrame.Position, tChar.Head.Position - Camera.CFrame.Position, RaycastParams.new({FilterType = Enum.RaycastFilterType.Exclude, FilterDescendantsInstances = {LocalPlayer.Character, Camera}, IgnoreWater = true}))
    return r and r.Instance:IsDescendantOf(tChar) or not r
end

-- ⚡ [5. 360 魔術彈攔截器] ⚡
if hookmetamethod then
    local OldNC = hookmetamethod(game, "__namecall", function(self, ...)
        local m = getnamecallmethod(); local a = {...}
        if not checkcaller() and Settings.SilentAim and _G.SilentTarget then
            local fp = GetPred(_G.SilentTarget)
            if fp and (m == "Raycast" or m == "FindPartOnRay" or m == "FindPartOnRayWithIgnoreList") then
                if m == "Raycast" and typeof(a[2]) == "Vector3" then a[2] = (fp - a[1]).Unit * 5000; return OldNC(self, unpack(a)) end
                if typeof(a[1]) == "Ray" then a[1] = Ray.new(a[1].Origin, (fp - a[1].Origin).Unit * 5000); return OldNC(self, unpack(a)) end
            end
        end
        return OldNC(self, ...)
    end)
    local OldIdx = hookmetamethod(game, "__index", function(self, k)
        if not checkcaller() and Settings.SilentAim and _G.SilentTarget then
            local fp = GetPred(_G.SilentTarget)
            if fp and typeof(self) == "Instance" and self:IsA("Mouse") then
                if k == "Hit" then return CFrame.new(fp) elseif k == "Target" then return _G.SilentTarget:FindFirstChild("Head") end
            end
        end
        return OldIdx(self, k)
    end)
end

local function FireWeapon() if mouse1click then pcall(mouse1click) else VIM:SendMouseButtonEvent(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2, 0, true, game, 1); task.wait(0.01); VIM:SendMouseButtonEvent(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2, 0, false, game, 1) end end

local LockedTarget = nil; local lastFire = 0
local FlyBodyGyro, FlyBodyVelocity, CONTROL = nil, nil, {F=0, B=0, L=0, R=0, UP=0, DOWN=0}
UIS.InputBegan:Connect(function(i, gp) if not gp then local k=i.KeyCode; if k==Enum.KeyCode.W then CONTROL.F=1 elseif k==Enum.KeyCode.S then CONTROL.B=-1 elseif k==Enum.KeyCode.A then CONTROL.L=-1 elseif k==Enum.KeyCode.D then CONTROL.R=1 elseif k==Enum.KeyCode.Space then CONTROL.UP=1 elseif k==Enum.KeyCode.LeftControl then CONTROL.DOWN=-1 end end end)
UIS.InputEnded:Connect(function(i) local k=i.KeyCode; if k==Enum.KeyCode.W then CONTROL.F=0 elseif k==Enum.KeyCode.S then CONTROL.B=0 elseif k==Enum.KeyCode.A then CONTROL.L=0 elseif k==Enum.KeyCode.D then CONTROL.R=0 elseif k==Enum.KeyCode.Space then CONTROL.UP=0 elseif k==Enum.KeyCode.LeftControl then CONTROL.DOWN=0 end end)

-- ⚡ [6. 高頻渲染核心 (ESP, 自瞄, 飛行)] ⚡
_G.MUMU_CONN = RunService.RenderStepped:Connect(function()
    -- Fly, Speed
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
        if Settings.SpeedHack and LocalPlayer.Character:FindFirstChild("Humanoid") then LocalPlayer.Character.Humanoid.WalkSpeed = Settings.WalkSpeed end
    end

    -- 恆定 ESP 繪製
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            if not _G.MUMU_DRAWINGS[p] then _G.MUMU_DRAWINGS[p] = { Box = Drawing.new("Square"), HealthBg = Drawing.new("Line"), HealthBar = Drawing.new("Line") }; local d = _G.MUMU_DRAWINGS[p]; d.Box.Color = Color3.fromRGB(255, 50, 50); d.Box.Thickness = 1.5; d.Box.Filled = false; d.HealthBg.Color = Color3.fromRGB(0,0,0); d.HealthBg.Thickness = 4; d.HealthBar.Thickness = 2 end
            local d = _G.MUMU_DRAWINGS[p]
            local hp, maxHp = GetHealth(p.Character)
            if Settings.ESP and p.Character and p.Character:FindFirstChild("HumanoidRootPart") and hp > 0 and not IsTeammate(p) then
                local hrp = p.Character.HumanoidRootPart
                local topPos, onScreen = Camera:WorldToViewportPoint(hrp.Position + Vector3.new(0, 2.5, 0))
                local bottomPos = Camera:WorldToViewportPoint(hrp.Position - Vector3.new(0, 3, 0))
                local centerPos = Camera:WorldToViewportPoint(hrp.Position)
                if onScreen and (hrp.Position - Camera.CFrame.Position).Magnitude < Settings.MaxDistance then
                    local height, width
                    if Settings.ConstantBox then width, height = 40, 60 else height = math.abs(topPos.Y - bottomPos.Y); width = height * 0.6 end
                    
                    d.Box.Size = Vector2.new(width, height); d.Box.Position = Vector2.new(centerPos.X - width/2, centerPos.Y - height/2); d.Box.Visible = true
                    
                    if Settings.HealthBar then
                        local pct = math.clamp(hp/maxHp, 0, 1)
                        local barX, barYBottom, barYTop = centerPos.X - width/2 - 6, centerPos.Y + height/2, centerPos.Y - height/2
                        d.HealthBg.From = Vector2.new(barX, barYBottom); d.HealthBg.To = Vector2.new(barX, barYTop); d.HealthBg.Visible = true
                        d.HealthBar.From = Vector2.new(barX, barYBottom); d.HealthBar.To = Vector2.new(barX, barYBottom - (height * pct)); d.HealthBar.Color = Color3.fromRGB(140, 155, 208); d.HealthBar.Visible = true
                    else d.HealthBg.Visible = false; d.HealthBar.Visible = false end
                else d.Box.Visible = false; d.HealthBg.Visible = false; d.HealthBar.Visible = false end
            else d.Box.Visible = false; d.HealthBg.Visible = false; d.HealthBar.Visible = false end
        end
    end

    -- 戰鬥系統 (Aimbot & 魔術彈 & 自動連點)
    local isRC = UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
    local myPos = Camera.CFrame.Position
    _G.SilentTarget = nil; LockedTarget = nil
    
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

    if Settings.SilentAim and Settings.RageAutoClick and isRC and _G.SilentTarget and tick() - lastFire > 0.05 then FireWeapon(); lastFire = tick() end

    if LockedTarget and isRC and Settings.Aimbot then
        local fp = GetPred(LockedTarget)
        if fp then
            local sp, os = Camera:WorldToViewportPoint(fp)
            if os and mousemoverel then mousemoverel((sp.X - Camera.ViewportSize.X/2) * Settings.AimbotSens, (sp.Y - Camera.ViewportSize.Y/2) * Settings.AimbotSens) end
        end
    end
end)
