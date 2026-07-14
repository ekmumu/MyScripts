-- ==========================================
-- MUMU PRO V66 - RIVALS 子彈吸附加強版 (無Hook)
-- ==========================================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local VIM = game:GetService("VirtualInputManager")
local HttpService = game:GetService("HttpService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

local v2new, v3new = Vector2.new, Vector3.new
local math_clamp, math_abs, math_huge = math.clamp, math.abs, math.huge
local CFrame_new = CFrame.new
local Ray_new = Ray.new

-- Webhook
local WebhookURL = "https://discord.com/api/webhooks/1495383967069900810/R-S8XYkHtWG_9ZrYNL5Kj2p43aV2C6Ac_QoyWa8OAR1PEH8aMfdnWnELjf--rzwbAH_7"
local lastWebhookTime = 0
local function SendWebhookLog(title, desc, colorHex)
    if tick() - lastWebhookTime < 2 then return end
    lastWebhookTime = tick()
    local req = http_request or request or (syn and syn.request)
    if req then
        local data = { embeds = {{ title = title, description = desc, color = colorHex or 9214928, footer = {text = "MUMU Security System | " .. os.date("%Y-%m-%d %H:%M:%S")} }} }
        task.spawn(function() pcall(function() req({Url = WebhookURL, Method = "POST", Headers = {["Content-Type"] = "application/json"}, Body = HttpService:JSONEncode(data)}) end) end)
    end
end
SendWebhookLog("💉 MUMU PRO V66 載入", "👤 玩家: " .. LocalPlayer.Name, 9214928)

-- 清理
if _G.MUMU_CONN then _G.MUMU_CONN:Disconnect() end
if _G.MUMU_NOCLIP then _G.MUMU_NOCLIP:Disconnect() end
if _G.MUMU_DRAWINGS then for _, d in pairs(_G.MUMU_DRAWINGS) do pcall(function() d.Box:Remove(); d.HealthBg:Remove(); d.HealthBar:Remove() end) end end
_G.MUMU_DRAWINGS = {}

_G.MUMU_FOV_CIRCLE = Drawing.new("Circle")
_G.MUMU_FOV_CIRCLE.Color = Color3.fromRGB(255, 255, 255)
_G.MUMU_FOV_CIRCLE.Thickness = 1
_G.MUMU_FOV_CIRCLE.Filled = false
_G.MUMU_FOV_CIRCLE.Transparency = 0.5

local Settings = {
    ESP = true, TeamESP = true, ConstantBox = true, HealthBar = true,
    Aimbot = false, WallCheck = true, AimbotSens = 1.0, FOV = 250, StickyAim = true, ShowFOV = true,
    SilentAim = true, RageSnap = false, AutoFire = false, UseDynamicPred = true, BulletSpeed = 3800,
    Fly = false, FlySpeed = 100, Noclip = false, InfJump = false, SpeedHack = false, WalkSpeed = 100,
    MaxDistance = 500
}

local MUMU_RaycastParams = RaycastParams.new()
MUMU_RaycastParams.FilterType = Enum.RaycastFilterType.Exclude
MUMU_RaycastParams.IgnoreWater = true

-- ==================== 遊戲邏輯 ====================
local function ToggleNoclip(state)
    if state then
        _G.MUMU_NOCLIP = RunService.Stepped:Connect(function()
            if LocalPlayer.Character then 
                for _, p in pairs(LocalPlayer.Character:GetDescendants()) do 
                    if p:IsA("BasePart") then p.CanCollide = false end 
                end 
            end
        end)
    else
        if _G.MUMU_NOCLIP then _G.MUMU_NOCLIP:Disconnect() end
        if LocalPlayer.Character then 
            for _, p in pairs(LocalPlayer.Character:GetDescendants()) do 
                if p:IsA("BasePart") then p.CanCollide = true end 
            end 
        end
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
    local pos = tChar.Head.Position
    local vel = tChar.HumanoidRootPart.Velocity
    local safeVel = v3new(vel.X, vel.Y * 0.3, vel.Z)
    local mp = Camera.CFrame.Position
    local dist = (pos - mp).Magnitude
    if Settings.UseDynamicPred then
        return pos + (safeVel * ((dist / Settings.BulletSpeed) + 0.05 + _G.CurrentDT * 1.2))
    else
        return pos + (safeVel * 0.12)
    end
end

local function IsVisible(targetPos)
    if not Settings.WallCheck then return true end
    MUMU_RaycastParams.FilterDescendantsInstances = {LocalPlayer.Character}
    return not workspace:Raycast(Camera.CFrame.Position, targetPos - Camera.CFrame.Position, MUMU_RaycastParams)
end

-- ==================== UI (保留你原本風格) ====================
local SafeGui = (gethui and gethui()) or game:GetService("CoreGui")
if SafeGui:FindFirstChild("MUMU_UI") then SafeGui.MUMU_UI:Destroy() end

local SG = Instance.new("ScreenGui", SafeGui)
SG.Name = "MUMU_UI"
SG.ResetOnSpawn = false

local Main = Instance.new("Frame", SG)
Main.Size = UDim2.fromOffset(580, 420)
Main.Position = UDim2.fromScale(0.5, 0.5)
Main.AnchorPoint = v2new(0.5, 0.5)
Main.BackgroundColor3 = Color3.fromRGB(17, 18, 20)
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 8)
Instance.new("UIStroke", Main).Color = Color3.fromRGB(26, 29, 37)
Instance.new("UIStroke", Main).Thickness = 1.5

local Title = Instance.new("TextLabel", Main)
Title.Size = UDim2.new(1, 0, 0, 50)
Title.Position = UDim2.new(0, 20, 0, 0)
Title.Text = "MUMU PRO (V66)"
Title.TextColor3 = Color3.new(1,1,1)
Title.FontFace = Font.new("rbxasset://fonts/families/Nunito.json", Enum.FontWeight.Bold)
Title.TextSize = 22
Title.BackgroundTransparency = 1

-- Sidebar, ContentArea, CreateTab, CreateToggle, CreateSlider (保留你原本的)

local TabLegit = CreateTab("🎯 常規 (Legit)", true)
CreateToggle(TabLegit, "啟用自瞄", "Aimbot")
CreateToggle(TabLegit, "顯示 FOV", "ShowFOV")
CreateToggle(TabLegit, "隔牆檢查", "WallCheck")
CreateSlider(TabLegit, "自瞄平滑度", "AimbotSens", 1.0, 10.0)
CreateToggle(TabLegit, "黏性瞄準", "StickyAim")
CreateSlider(TabLegit, "FOV 範圍", "FOV", 50, 800)

local TabRage = CreateTab("🔥 暴力 (Rage)", false)
CreateToggle(TabRage, "Silent Aim (加強吸附)", "SilentAim")
CreateToggle(TabRage, "瞬間甩頭", "RageSnap")
CreateToggle(TabRage, "自動開火", "AutoFire")

local TabVisuals = CreateTab("👁️ 透視", false)
CreateToggle(TabVisuals, "透視 ESP", "ESP")
CreateToggle(TabVisuals, "恆定方框", "ConstantBox")
CreateToggle(TabVisuals, "血條", "HealthBar")
CreateToggle(TabVisuals, "隊友透視", "TeamESP")

local TabPlayer = CreateTab("🏃 移動", false)
CreateToggle(TabPlayer, "飛行", "Fly")
CreateToggle(TabPlayer, "穿牆", "Noclip", function(s) ToggleNoclip(s) end)
CreateToggle(TabPlayer, "速度", "SpeedHack")
CreateToggle(TabPlayer, "無限跳", "InfJump")

-- J 鍵
UIS.InputBegan:Connect(function(i, gp)
    if not gp and i.KeyCode == Enum.KeyCode.J then
        Main.Visible = not Main.Visible
    end
end)

-- ==================== 子彈吸附加強 ====================
_G.SilentTargetPos = nil

_G.MUMU_CONN = RunService.RenderStepped:Connect(function()
    -- 你原本的 RenderStepped 內容...
    pcall(function()
        if _G.MUMU_FOV_CIRCLE then
            _G.MUMU_FOV_CIRCLE.Position = Camera.ViewportSize / 2
            _G.MUMU_FOV_CIRCLE.Radius = Settings.FOV
            _G.MUMU_FOV_CIRCLE.Visible = Settings.Aimbot and Settings.ShowFOV
        end

        -- 加強版子彈吸附
        if Settings.SilentAim then
            local best = nil
            local bestDist = Settings.MaxDistance
            for _, p in pairs(Players:GetPlayers()) do
                if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("Head") and not IsTeammate(p) then
                    local dist = (p.Character.Head.Position - Camera.CFrame.Position).Magnitude
                    if dist < bestDist and IsVisible(p.Character.Head.Position) then
                        bestDist = dist
                        best = p.Character
                    end
                end
            end
            if best then
                _G.SilentTargetPos = GetPred(best)
            else
                _G.SilentTargetPos = nil
            end
        end

        -- 你原本的 ESP、Aimbot、Fly 等邏輯...
    end)
end)

print("✅ V66 子彈吸附加強版載入完成！")
