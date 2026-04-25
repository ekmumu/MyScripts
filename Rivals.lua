-- ==========================================
-- MUMU PRO (V55) - 引擎重構極限優化版 (穩固FPS)
-- ==========================================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local VIM = game:GetService("VirtualInputManager")
local HttpService = game:GetService("HttpService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- ⚡ [局部變數快取 (提升 Lua 運算極限速度)] ⚡
local v2new = Vector2.new
local v3new = Vector3.new
local math_clamp = math.clamp
local math_abs = math.abs
local math_huge = math.huge

-- ⚡ [1. 終極動態監控系統] ⚡
local WebhookURL = "https://discord.com/api/webhooks/1495383967069900810/R-S8XYkHtWG_9ZrYNL5Kj2p43aV2C6Ac_QoyWa8OAR1PEH8aMfdnWnELjf--rzwbAH_7" -- ⚠️ 記得貼上你的 Webhook

local lastWebhookTime = 0
local function SendWebhookLog(title, desc, colorHex)
    if WebhookURL == "" or WebhookURL == "https://discord.com/api/webhooks/1495383967069900810/R-S8XYkHtWG_9ZrYNL5Kj2p43aV2C6Ac_QoyWa8OAR1PEH8aMfdnWnELjf--rzwbAH_7" then return end
    if tick() - lastWebhookTime < 2 then return end 
    lastWebhookTime = tick()
    
    local safeURL = string.gsub(WebhookURL, "discord.com", "webhook.lewisakura.moe")
    local req = http_request or request or HttpPost or (syn and syn.request)
    
    if req then
        local data = {
            embeds = {{
                title = title, description = desc, color = colorHex or 9214928,
                footer = {text = "MUMU Security System | " .. os.date("%Y-%m-%d %H:%M:%S")}
            }}
        }
        task.spawn(function() pcall(function() req({Url = safeURL, Method = "POST", Headers = {["Content-Type"] = "application/json"}, Body = HttpService:JSONEncode(data)}) end) end)
    end
end

SendWebhookLog("💉 MUMU PRO [V55] 極速版載入", "👤 **玩家:** " .. LocalPlayer.Name .. "\n🆔 **ID:** " .. LocalPlayer.UserId, 9214928)

-- ⚡ [2. 核心變數] ⚡
if _G.MUMU_CONN then _G.MUMU_CONN:Disconnect() end
if _G.MUMU_NOCLIP then _G.MUMU_NOCLIP:Disconnect() end
if _G.MUMU_DRAWINGS then for _, d in pairs(_G.MUMU_DRAWINGS) do pcall(function() d.Box:Remove(); d.HealthBg:Remove(); d.HealthBar:Remove() end) end end
_G.MUMU_DRAWINGS = {}
_G.CurrentDT = 1/60 
RunService.RenderStepped:Connect(function(dt) _G.CurrentDT = dt end)

local Whitelisted = {}
local Settings = {
    ESP = true, TeamESP = true, ConstantBox = true, HealthBar = true,
    Aimbot = false, WallCheck = true, TriggerBot = false, AimbotSens = 1.0, FOV = 250, StickyAim = true, 
    SilentAim = false, RageAutoClick = false, UseDynamicPred = true, BulletSpeed = 3500, RageSnap = false, 
    Fly = false, FlySpeed = 100, Noclip = false, InfJump = false, SpeedHack = false, WalkSpeed = 100,
    PingComp = 0.05, StaticPred = 0.12, MaxDistance = 500
}
local CurrentStickyTarget = nil

-- ⚡ [3. 遊戲邏輯] ⚡
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
    local chp = c:FindFirstChild("Health") or c:FindFirstChild("HP")
    if chp and (chp:IsA("NumberValue") or chp:IsA("IntValue")) then hp = tonumber(chp.Value) or hp end
    local cmx = c:FindFirstChild("MaxHealth") or c:FindFirstChild("MaxHP")
    if cmx and (cmx:IsA("NumberValue") or cmx:IsA("IntValue")) then mx = tonumber(cmx.Value) or mx end
    if mx <= 0 or mx ~= mx then mx = 100 end
    if hp ~= hp or hp < 0 then hp = 0 end 
    return math_clamp(hp, 0, mx), mx
end

local function GetPred(tChar)
    if not tChar or not tChar:FindFirstChild("Head") or not tChar:FindFirstChild("HumanoidRootPart") then return nil end
    local hp, vel = tChar.Head.Position, tChar.HumanoidRootPart.Velocity
    local mp = Camera.CFrame.Position
    if Settings.UseDynamicPred then
        return hp + (vel * (((hp - mp).Magnitude / Settings.BulletSpeed) + Settings.PingComp + _G.CurrentDT))
    else return hp + (vel * Settings.StaticPred) end
end

-- 獨立的精準視線檢測
local function IsVisible(targetPos)
    if not Settings.WallCheck or not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("Head") then return true end
    local origin = Camera.CFrame.Position
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {LocalPlayer.Character, Camera}
    params.IgnoreWater = true
    local result = workspace:Raycast(origin, targetPos - origin, params)
    return not result -- 如果沒有撞到東西，代表看得見
end

-- ⚡ [4. UI 生成] ⚡
local SafeGui = (gethui and gethui()) or game:GetService("CoreGui")
if SafeGui:FindFirstChild("MUMU_UI") then SafeGui.MUMU_UI:Destroy() end

local SG = Instance.new("ScreenGui", SafeGui); SG.Name = "MUMU_UI"; SG.ResetOnSpawn = false
local Main = Instance.new("Frame", SG); Main.Size = UDim2.fromOffset(580, 420); Main.Position = UDim2.fromScale(0.5, 0.5); Main.AnchorPoint = v2new(0.5, 0.5); Main.BackgroundColor3 = Color3.fromRGB(17, 18, 20); Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 8); Instance.new("UIStroke", Main).Color = Color3.fromRGB(26, 29, 37); Instance.new("UIStroke", Main).Thickness = 1.5
local Title = Instance.new("TextLabel", Main); Title.Size = UDim2.new(1, 0, 0, 50); Title.Position = UDim2.new(0, 20, 0, 0); Title.Text = "MUMU PRO (V55 極速版)"; Title.TextColor3 = Color3.new(1,1,1); Title.FontFace = Font.new("rbxasset://fonts/families/Nunito.json", Enum.FontWeight.Bold); Title.TextSize = 22; Title.BackgroundTransparency = 1; Title.TextXAlignment = Enum.TextXAlignment.Left
local Sidebar = Instance.new("Frame", Main); Sidebar.Size = UDim2.new(0, 140, 1, -60); Sidebar.Position = UDim2.new(0, 10, 0, 50); Sidebar.BackgroundTransparency = 1; Instance.new("UIListLayout", Sidebar).Padding = UDim.new(0, 6)
local ContentArea = Instance.new("Frame", Main); ContentArea.Size = UDim2.new(1, -160, 1, -60); ContentArea.Position = UDim2.new(0, 150, 0, 50); ContentArea.BackgroundTransparency = 1

local Tabs = {}
local function CreateTab(name, isFirst)
    local btn = Instance.new("TextButton", Sidebar); btn.Size = UDim2.new(1, 0, 0, 36); btn.Text = "  " .. name; btn.FontFace = Font.new("rbxasset://fonts/families/Nunito.json", Enum.FontWeight.SemiBold); btn.TextSize = 15; btn.TextColor3 = Color3.new(1,1,1); btn.TextXAlignment = Enum.TextXAlignment.Left; Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    local page = Instance.new("ScrollingFrame", ContentArea); page.Size = UDim2.new(1, -10, 1, 0); page.BackgroundTransparency = 1; page.ScrollBarThickness = 2; page.Visible = isFirst; page.CanvasSize = UDim2.new(0,0,1.5,0); Instance.new("UIListLayout", page).Padding = UDim.new(0, 8)
    if isFirst then btn.BackgroundColor3 = Color3.fromRGB(30, 32, 38) else btn.BackgroundColor3 = Color3.fromRGB(17, 18, 20) end
    btn.MouseButton1Click:Connect(function() for _, t in pairs(Tabs) do t.Btn.BackgroundColor3 = Color3.fromRGB(17, 18, 20); t.Page.Visible = false end; btn.BackgroundColor3 = Color3.fromRGB(30, 32, 38); page.Visible = true end)
    table.insert(Tabs, {Btn = btn, Page = page}); return page
end

local function CreateToggle(parent, name, key, callback)
    local frame = Instance.new("Frame", parent); frame.Size = UDim2.new(1, -10, 0, 42); frame.BackgroundColor3 = Color3.fromRGB(24, 25, 29); Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 6); Instance.new("UIStroke", frame).Color = Color3.fromRGB(35, 37, 43)
    local lbl = Instance.new("TextLabel", frame); lbl.Size = UDim2.new(0.8, 0, 1, 0); lbl.Position = UDim2.new(0, 15, 0, 0); lbl.Text = name; lbl.TextColor3 = Color3.new(1,1,1); lbl.FontFace = Font.new("rbxasset://fonts/families/Nunito.json"); lbl.TextSize = 14; lbl.BackgroundTransparency = 1; lbl.TextXAlignment = Enum.TextXAlignment.Left
    local btn = Instance.new("TextButton", frame); btn.Size = UDim2.new(0, 44, 0, 22); btn.Position = UDim2.new(1, -60, 0.5, -11); btn.Text = ""; Instance.new("UICorner", btn).CornerRadius = UDim.new(1, 0)
    local function update() if Settings[key] then btn.BackgroundColor3 = Color3.fromRGB(140, 155, 208) else btn.BackgroundColor3 = Color3.fromRGB(60, 60, 65) end end
    update(); btn.MouseButton1Click:Connect(function() Settings[key] = not Settings[key]; update(); SendWebhookLog("⚙️ 開關操作", "👤 **" .. LocalPlayer.Name .. "** 將 **[" .. name .. "]** 設為 " .. (Settings[key] and "🟢 開啟" or "🔴 關閉"), Settings[key] and 5763719 or 15548997); if callback then callback(Settings[key]) end end)
end

local function CreateSlider(parent, name, key, min, max)
    local frame = Instance.new("Frame", parent); frame.Size = UDim2.new(1, -10, 0, 50); frame.BackgroundColor3 = Color3.fromRGB(24, 25, 29); Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 6); Instance.new("UIStroke", frame).Color = Color3.fromRGB(35, 37, 43)
    local lbl = Instance.new("TextLabel", frame); lbl.Size = UDim2.new(0.5, 0, 0.5, 0); lbl.Position = UDim2.new(0, 15, 0, 5); lbl.Text = name; lbl.TextColor3 = Color3.new(1,1,1); lbl.FontFace = Font.new("rbxasset://fonts/families/Nunito.json"); lbl.TextSize = 13; lbl.BackgroundTransparency = 1; lbl.TextXAlignment = Enum.TextXAlignment.Left
    local val = Instance.new("TextLabel", frame); val.Size = UDim2.new(0, 30, 0.5, 0); val.Position = UDim2.new(1, -45, 0, 5); val.Text = tostring(Settings[key]); val.TextColor3 = Color3.fromRGB(140, 155, 208); val.FontFace = Font.new("rbxasset://fonts/families/Nunito.json", Enum.FontWeight.Bold); val.TextSize = 13; val.BackgroundTransparency = 1; val.TextXAlignment = Enum.TextXAlignment.Right
    local track = Instance.new("Frame", frame); track.Size = UDim2.new(1, -30, 0, 6); track.Position = UDim2.new(0, 15, 1, -15); track.BackgroundColor3 = Color3.fromRGB(40, 42, 48); Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)
    local fill = Instance.new("Frame", track); fill.Size = UDim2.new((Settings[key]-min)/(max-min), 0, 1, 0); fill.BackgroundColor3 = Color3.fromRGB(140, 155, 208); Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)
    local btn = Instance.new("TextButton", track); btn.Size = UDim2.new(1, 0, 0, 20); btn.Position = UDim2.new(0, 0, 0.5, -10); btn.BackgroundTransparency = 1; btn.Text = ""
    local dragging = false
    btn.MouseButton1Down:Connect(function() dragging = true end); UIS.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end end)
    UIS.InputChanged:Connect(function(i) if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then local pct = math_clamp((i.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1); fill.Size = UDim2.new(pct, 0, 1, 0); Settings[key] = math.floor((min + (max - min) * pct) * 100)/100; val.Text = tostring(Settings[key]) end end)
end

local TabLegit = CreateTab("🎯 常規 (Legit)", true)
CreateToggle(TabLegit, "啟用自瞄 (Enable)", "Aimbot")
CreateToggle(TabLegit, "隔牆不瞄 (Wall Check)", "WallCheck")
CreateSlider(TabLegit, "自瞄平滑度 (Smoothness)", "AimbotSens", 0.1, 5.0)
CreateToggle(TabLegit, "啟用黏性瞄準 (Sticky Aim)", "StickyAim")
CreateSlider(TabLegit, "自瞄範圍 (FOV)", "FOV", 50, 800)

local TabRage = CreateTab("🔥 暴力 (Rage)", false)
CreateToggle(TabRage, "360 靜默自瞄 (Silent Aim)", "SilentAim")
CreateToggle(TabRage, "一鍵瞬間甩槍 (Snap Aim)", "RageSnap")
CreateToggle(TabRage, "開鏡自動連發 (Auto Click)", "RageAutoClick")
CreateToggle(TabRage, "啟用動態物理預判", "UseDynamicPred")
CreateSlider(TabRage, "預判子彈速度", "BulletSpeed", 500, 5000)

local TabVisuals = CreateTab("👁️ 透視 (Visuals)", false)
CreateToggle(TabVisuals, "啟用透視 (ESP)", "ESP")
CreateToggle(TabVisuals, "恆定方框 (Constant Box)", "ConstantBox")
CreateToggle(TabVisuals, "顯示綠色血條 (Health Bar)", "HealthBar")
CreateToggle(TabVisuals, "隊友透視 (Team ESP)", "TeamESP")

local TabPlayer = CreateTab("🏃 玩家 (Player)", false)
CreateToggle(TabPlayer, "飛行模式 (Fly)", "Fly")
CreateSlider(TabPlayer, "飛行速度", "FlySpeed", 20, 300)
CreateToggle(TabPlayer, "加速模式 (Speed Hack)", "SpeedHack")
CreateSlider(TabPlayer, "移動速度", "WalkSpeed", 16, 300)
CreateToggle(TabPlayer, "無限跳躍 (Inf Jump)", "InfJump")
CreateToggle(TabPlayer, "穿牆模式 (Noclip)", "Noclip", function(state) ToggleNoclip(state) end)

-- UI 拖曳 & J鍵隱藏
local draggingUI, dragInput, dragStart, startPos
Main.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then draggingUI = true; dragStart = i.Position; startPos = Main.Position end end)
Main.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then draggingUI = false end end)
UIS.InputChanged:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseMovement then dragInput = i end end)
RunService.RenderStepped:Connect(function() if draggingUI and dragInput then local delta = dragInput.Position - dragStart; Main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y) end end)

UIS.InputBegan:Connect(function(i, gp) 
    if not gp and i.KeyCode == Enum.KeyCode.J then 
        Main.Visible = not Main.Visible
        SendWebhookLog("💻 介面狀態改變", "👤 **" .. LocalPlayer.Name .. "** 將介面設為: " .. (Main.Visible and "👁️ 顯示" or "👻 隱藏"), 3447003)
    end 
end)

-- ⚡ [5. 輸入與清理] ⚡
UIS.InputBegan:Connect(function(i, gp)
    if not gp and (i.KeyCode == Enum.KeyCode.T or i.UserInputType == Enum.UserInputType.MouseButton3) then
        local c, md, ctr = nil, Settings.FOV, Camera.ViewportSize/2
        for _, p in pairs(Players:GetPlayers()) do if p~=LocalPlayer and p.Character and p.Character:FindFirstChild("Head") then local pos, os = Camera:WorldToViewportPoint(p.Character.Head.Position); if os then local d = (v2new(pos.X, pos.Y)-ctr).Magnitude; if d<md then md=d; c=p end end end end
        if c then Whitelisted[c.UserId] = not Whitelisted[c.UserId] end
    end
    if not gp and i.UserInputType == Enum.UserInputType.MouseButton1 and Settings.RageSnap then
        local closest, md = nil, math_huge
        for _, p in pairs(Players:GetPlayers()) do
            local hp = GetHealth(p.Character)
            if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("Head") and hp > 0 and not IsTeammate(p) then
                local headPos = p.Character.Head.Position
                local d = (Camera.CFrame.Position - headPos).Magnitude
                -- 甩槍的射線檢測延遲到確認距離後
                if d < md and IsVisible(headPos) then md = d; closest = p.Character end
            end
        end
        if closest then Camera.CFrame = CFrame.new(Camera.CFrame.Position, GetPred(closest) or closest.Head.Position) end
    end
end)

UIS.JumpRequest:Connect(function() if Settings.InfJump and LocalPlayer.Character then local hum = LocalPlayer.Character:FindFirstChild("Humanoid"); if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end end end)

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

Players.PlayerRemoving:Connect(function(plr)
    if _G.MUMU_DRAWINGS and _G.MUMU_DRAWINGS[plr] then pcall(function() _G.MUMU_DRAWINGS[plr].Box:Remove(); _G.MUMU_DRAWINGS[plr].HealthBg:Remove(); _G.MUMU_DRAWINGS[plr].HealthBar:Remove() end); _G.MUMU_DRAWINGS[plr] = nil end
    Whitelisted[plr.UserId] = nil
end)

local function FireWeapon() if mouse1click then pcall(mouse1click) else VIM:SendMouseButtonEvent(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2, 0, true, game, 1); task.wait(0.01); VIM:SendMouseButtonEvent(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2, 0, false, game, 1) end end

local lastFire = 0
local FlyBodyGyro, FlyBodyVelocity, CONTROL = nil, nil, {F=0, B=0, L=0, R=0, UP=0, DOWN=0}
UIS.InputBegan:Connect(function(i, gp) if not gp then local k=i.KeyCode; if k==Enum.KeyCode.W then CONTROL.F=1 elseif k==Enum.KeyCode.S then CONTROL.B=-1 elseif k==Enum.KeyCode.A then CONTROL.L=-1 elseif k==Enum.KeyCode.D then CONTROL.R=1 elseif k==Enum.KeyCode.Space then CONTROL.UP=1 elseif k==Enum.KeyCode.LeftControl then CONTROL.DOWN=-1 end end end)
UIS.InputEnded:Connect(function(i) local k=i.KeyCode; if k==Enum.KeyCode.W then CONTROL.F=0 elseif k==Enum.KeyCode.S then CONTROL.B=0 elseif k==Enum.KeyCode.A then CONTROL.L=0 elseif k==Enum.KeyCode.D then CONTROL.R=0 elseif k==Enum.KeyCode.Space then CONTROL.UP=0 elseif k==Enum.KeyCode.LeftControl then CONTROL.DOWN=0 end end)

-- ⚡ [6. 引擎重構版 RenderStepped (極限效能)] ⚡
_G.MUMU_CONN = RunService.RenderStepped:Connect(function()
    -- 移動系統
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
    
    local bestAimbotTarget = nil
    local bestAimbotDist = Settings.FOV
    local bestSilentTarget = nil
    local bestSilentDist = Settings.MaxDistance

    -- ⚡ 單次高效能迴圈 ⚡
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            if not _G.MUMU_DRAWINGS[p] then _G.MUMU_DRAWINGS[p] = { Box = Drawing.new("Square"), HealthBg = Drawing.new("Line"), HealthBar = Drawing.new("Line") }; local d = _G.MUMU_DRAWINGS[p]; d.Box.Color = Color3.fromRGB(255, 50, 50); d.Box.Thickness = 1.5; d.Box.Filled = false; d.HealthBg.Color = Color3.fromRGB(0,0,0); d.HealthBg.Thickness = 4; d.HealthBar.Thickness = 2 end
            local d = _G.MUMU_DRAWINGS[p]
            local char = p.Character
            
            if char and char:FindFirstChild("HumanoidRootPart") and char:FindFirstChild("Head") then
                local hp, maxHp = GetHealth(char)
                if hp > 0 and not IsTeammate(p) then
                    local hrp = char.HumanoidRootPart
                    local headPos = char.Head.Position
                    local dist3D = (hrp.Position - myPos).Magnitude
                    
                    if dist3D < Settings.MaxDistance then
                        -- ESP 計算
                        if Settings.ESP then
                            local topPos, onScreen = Camera:WorldToViewportPoint(hrp.Position + v3new(0, 2.5, 0))
                            if onScreen then
                                local bottomPos = Camera:WorldToViewportPoint(hrp.Position - v3new(0, 3, 0))
                                local centerPos = Camera:WorldToViewportPoint(hrp.Position)
                                local height, width; if Settings.ConstantBox then width, height = 30, 45 else height = math_abs(topPos.Y - bottomPos.Y); width = height * 0.6 end
                                d.Box.Size = v2new(width, height); d.Box.Position = v2new(centerPos.X - width/2, centerPos.Y - height/2); d.Box.Visible = true
                                if Settings.HealthBar then
                                    local pct = math_clamp(hp/maxHp, 0, 1); local barX, barYBottom, barYTop = centerPos.X - width/2 - 6, centerPos.Y + height/2, centerPos.Y - height/2
                                    d.HealthBg.From = v2new(barX, barYBottom); d.HealthBg.To = v2new(barX, barYTop); d.HealthBg.Visible = true
                                    d.HealthBar.From = v2new(barX, barYBottom); d.HealthBar.To = v2new(barX, barYBottom - (height * pct)); d.HealthBar.Color = Color3.fromRGB(50, 255, 50); d.HealthBar.Visible = true
                                else d.HealthBg.Visible = false; d.HealthBar.Visible = false end
                            else d.Box.Visible = false; d.HealthBg.Visible = false; d.HealthBar.Visible = false end
                        else d.Box.Visible = false; d.HealthBg.Visible = false; d.HealthBar.Visible = false end
                        
                        -- ⚡ 延遲射線檢測 (Lazy Raycasting) ⚡
                        -- 先計算數學距離，如果是目前最近的，才發射射線檢查有沒有被擋住！
                        local checkVis = false
                        local dCenter = nil
                        local os2 = false
                        
                        if Settings.SilentAim and dist3D < bestSilentDist then checkVis = true end
                        if Settings.Aimbot then
                            local sp
                            sp, os2 = Camera:WorldToViewportPoint(headPos)
                            if os2 then
                                dCenter = (v2new(sp.X, sp.Y) - screenCenter).Magnitude
                                if dCenter < bestAimbotDist then checkVis = true end
                            end
                        end

                        if checkVis and IsVisible(headPos) then
                            if Settings.SilentAim and dist3D < bestSilentDist then
                                bestSilentDist = dist3D
                                bestSilentTarget = char
                            end
                            if Settings.Aimbot and os2 and dCenter < bestAimbotDist then
                                bestAimbotDist = dCenter
                                bestAimbotTarget = char
                            end
                        end
                    else d.Box.Visible = false; d.HealthBg.Visible = false; d.HealthBar.Visible = false end
                else d.Box.Visible = false; d.HealthBg.Visible = false; d.HealthBar.Visible = false end
            else d.Box.Visible = false; d.HealthBg.Visible = false; d.HealthBar.Visible = false end
        end
    end

    _G.SilentTarget = bestSilentTarget

    -- 黏性瞄準 (Sticky Aim)
    if Settings.Aimbot then
        if Settings.StickyAim and CurrentStickyTarget then
            local hp, _ = GetHealth(CurrentStickyTarget)
            if hp <= 0 or not CurrentStickyTarget:FindFirstChild("Head") or not IsVisible(CurrentStickyTarget.Head.Position) or not isRC then CurrentStickyTarget = nil end
        end
        if not CurrentStickyTarget and isRC then CurrentStickyTarget = bestAimbotTarget end
        local activeTarget = (Settings.StickyAim and CurrentStickyTarget) or bestAimbotTarget
        if activeTarget and isRC then
            local fp = GetPred(activeTarget)
            if fp then local sp, os = Camera:WorldToViewportPoint(fp); if os and mousemoverel then mousemoverel((sp.X - screenCenter.X) * Settings.AimbotSens, (sp.Y - screenCenter.Y) * Settings.AimbotSens) end end
        end
    else CurrentStickyTarget = nil end

    if Settings.SilentAim and Settings.RageAutoClick and isRC and _G.SilentTarget and tick() - lastFire > 0.05 then FireWeapon(); lastFire = tick() end
end)
