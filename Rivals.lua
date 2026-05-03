-- ==========================================
-- MUMU PRO (V78) - 絕對穩定除錯版 (修復卡死/血條回歸/手動安全寫入)
-- ==========================================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

local v2new, v3new = Vector2.new, Vector3.new
local math_clamp, math_abs = math.clamp, math.abs
local Ray_new = Ray.new
local CFrame_new = CFrame.new

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

local Settings = {
    -- 自瞄與拐彎
    SilentAim = false, Wallbang = false, Aimbot = false, AimbotSens = 1.0, FOV = 250, ShowFOV = false, StickyAim = false,
    -- 透視
    ESP = false, HealthBar = false, MaxDistance = 1000
}

_G.SilentTargetPos = nil
local CurrentStickyTarget = nil

local MUMU_RaycastParams = RaycastParams.new()
MUMU_RaycastParams.FilterType = Enum.RaycastFilterType.Exclude
MUMU_RaycastParams.IgnoreWater = true

-- 🚀 [安全手動注入：神槍與解鎖 Skin] 🚀
-- 避免背景迴圈導致的瘋狂報錯，改為按鈕觸發單次執行
local function ApplyPremiumMods()
    if not getgc then return end
    local PremiumSkins = {"Galaxy", "AKEY-47", "Gingerbread AUG", "Phoenix Rifle", "Boneclaw Rifle", "Tommy Gun", "10B Visits", "Dark Matter", "Golden", "Radiant"}
    
    for _, v in pairs(getgc(true)) do
        if type(v) == "table" then
            pcall(function()
                -- 1. 全庫解鎖
                if rawget(v, "OwnedWraps") and type(rawget(v, "OwnedWraps")) == "table" then
                    for _, skin in ipairs(PremiumSkins) do rawset(v.OwnedWraps, skin, true) end
                end
                if rawget(v, "OwnedWeapons") and type(rawget(v, "OwnedWeapons")) == "table" then
                    for _, skin in ipairs(PremiumSkins) do rawset(v.OwnedWeapons, skin, true) end
                end
                
                -- 2. 雷射光束 (神槍)
                if rawget(v, "FireRate") and type(rawget(v, "FireRate")) == "number" then
                    rawset(v, "FireRate", 0.001)       -- 射速極致
                    rawset(v, "BulletsPerShot", 20)    -- 瞬間發射20發
                    rawset(v, "Ammo", 9999)            -- 無限子彈
                    rawset(v, "MaxAmmo", 9999)
                    rawset(v, "StoredAmmo", 9999)
                    rawset(v, "Spread", 0)             -- 零擴散 (雷射光束核心)
                    rawset(v, "MaxSpread", 0)
                    rawset(v, "Recoil", 0)             -- 零後座力
                    if rawget(v, "Cooldown") then rawset(v, "Cooldown", 0) end
                end
            end)
        end
    end
    print("MUMU PRO: Premium Mods Applied Successfully!")
end

-- 🚀 [完美修復卡死：子彈拐彎攔截器] 🚀
if hookmetamethod then
    local OldNC
    OldNC = hookmetamethod(game, "__namecall", function(self, ...)
        local m = getnamecallmethod()
        local a = {...}
        
        -- ⚠️ 核心修復：加入 UIS:IsMouseButtonPressed(MouseButton1)
        -- 確保只有在「玩家按下滑鼠左鍵開槍」的瞬間，才進行射線拐彎。
        -- 這樣絕對不會干擾遊戲底層偵測地板與攝影機的射線，徹底解決卡死與亂飛！
        if not checkcaller() and Settings.SilentAim and _G.SilentTargetPos and UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
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

-- ⚡ [遊戲邏輯] ⚡
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
    local hp = tChar.Head.Position
    local safeVel = v3new(tChar.HumanoidRootPart.Velocity.X, tChar.HumanoidRootPart.Velocity.Y * 0.3, tChar.HumanoidRootPart.Velocity.Z) 
    return hp + (safeVel * (((hp - Camera.CFrame.Position).Magnitude / 3500) + 0.05 + _G.CurrentDT))
end

local function IsVisible(targetPos)
    if not LocalPlayer.Character then return true end
    MUMU_RaycastParams.FilterDescendantsInstances = {LocalPlayer.Character, Camera}
    return not workspace:Raycast(Camera.CFrame.Position, targetPos - Camera.CFrame.Position, MUMU_RaycastParams)
end

-- 💎 [UI 介面生成 (完美還原 V60 質感與血條按鈕)] 💎
local SafeGui = (gethui and gethui()) or game:GetService("CoreGui")
if SafeGui:FindFirstChild("MUMU_UI") then SafeGui.MUMU_UI:Destroy() end

local SG = Instance.new("ScreenGui", SafeGui); SG.Name = "MUMU_UI"; SG.ResetOnSpawn = false
local Main = Instance.new("Frame", SG); Main.Size = UDim2.fromOffset(580, 420); Main.Position = UDim2.fromScale(0.5, 0.5); Main.AnchorPoint = v2new(0.5, 0.5); Main.BackgroundColor3 = Color3.fromRGB(17, 18, 20); Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 8); Instance.new("UIStroke", Main).Color = Color3.fromRGB(168, 85, 247); Instance.new("UIStroke", Main).Thickness = 1.5
local Title = Instance.new("TextLabel", Main); Title.Size = UDim2.new(1, 0, 0, 50); Title.Position = UDim2.new(0, 20, 0, 0); Title.Text = "MUMU PRO (V78 STABLE)"; Title.TextColor3 = Color3.new(1,1,1); Title.FontFace = Font.new("rbxasset://fonts/families/Nunito.json", Enum.FontWeight.Bold); Title.TextSize = 22; Title.BackgroundTransparency = 1; Title.TextXAlignment = Enum.TextXAlignment.Left
local Sidebar = Instance.new("Frame", Main); Sidebar.Size = UDim2.new(0, 140, 1, -60); Sidebar.Position = UDim2.new(0, 10, 0, 50); Sidebar.BackgroundTransparency = 1; Instance.new("UIListLayout", Sidebar).Padding = UDim.new(0, 6)
local ContentArea = Instance.new("Frame", Main); ContentArea.Size = UDim2.new(1, -160, 1, -60); ContentArea.Position = UDim2.new(0, 150, 0, 50); ContentArea.BackgroundTransparency = 1

local Tabs = {}
local function CreateTab(name, isFirst)
    local btn = Instance.new("TextButton", Sidebar); btn.Size = UDim2.new(1, 0, 0, 36); btn.Text = "  " .. name; btn.FontFace = Font.new("rbxasset://fonts/families/Nunito.json", Enum.FontWeight.SemiBold); btn.TextSize = 15; btn.TextColor3 = Color3.new(1,1,1); btn.TextXAlignment = Enum.TextXAlignment.Left; Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    local page = Instance.new("ScrollingFrame", ContentArea); page.Size = UDim2.new(1, -10, 1, 0); page.BackgroundTransparency = 1; page.ScrollBarThickness = 2; page.Visible = isFirst; page.CanvasSize = UDim2.new(0,0,1.2,0); Instance.new("UIListLayout", page).Padding = UDim.new(0, 8)
    if isFirst then btn.BackgroundColor3 = Color3.fromRGB(30, 32, 38) else btn.BackgroundColor3 = Color3.fromRGB(17, 18, 20) end
    btn.MouseButton1Click:Connect(function() for _, t in pairs(Tabs) do t.Btn.BackgroundColor3 = Color3.fromRGB(17, 18, 20); t.Page.Visible = false end; btn.BackgroundColor3 = Color3.fromRGB(30, 32, 38); page.Visible = true end)
    table.insert(Tabs, {Btn = btn, Page = page}); return page
end

local function CreateToggle(parent, name, key)
    local frame = Instance.new("Frame", parent); frame.Size = UDim2.new(1, -10, 0, 42); frame.BackgroundColor3 = Color3.fromRGB(24, 25, 29); Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 6); Instance.new("UIStroke", frame).Color = Color3.fromRGB(35, 37, 43)
    local lbl = Instance.new("TextLabel", frame); lbl.Size = UDim2.new(0.8, 0, 1, 0); lbl.Position = UDim2.new(0, 15, 0, 0); lbl.Text = name; lbl.TextColor3 = Color3.new(1,1,1); lbl.FontFace = Font.new("rbxasset://fonts/families/Nunito.json"); lbl.TextSize = 14; lbl.BackgroundTransparency = 1; lbl.TextXAlignment = Enum.TextXAlignment.Left
    local btn = Instance.new("TextButton", frame); btn.Size = UDim2.new(0, 44, 0, 22); btn.Position = UDim2.new(1, -60, 0.5, -11); btn.Text = ""; Instance.new("UICorner", btn).CornerRadius = UDim.new(1, 0)
    local function update() if Settings[key] then btn.BackgroundColor3 = Color3.fromRGB(168, 85, 247) else btn.BackgroundColor3 = Color3.fromRGB(60, 60, 65) end end
    update(); btn.MouseButton1Click:Connect(function() Settings[key] = not Settings[key]; update() end)
end

local function CreateSlider(parent, name, key, min, max)
    local frame = Instance.new("Frame", parent); frame.Size = UDim2.new(1, -10, 0, 50); frame.BackgroundColor3 = Color3.fromRGB(24, 25, 29); Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 6); Instance.new("UIStroke", frame).Color = Color3.fromRGB(35, 37, 43)
    local lbl = Instance.new("TextLabel", frame); lbl.Size = UDim2.new(0.6, 0, 0.5, 0); lbl.Position = UDim2.new(0, 15, 0, 5); lbl.Text = name; lbl.TextColor3 = Color3.new(1,1,1); lbl.FontFace = Font.new("rbxasset://fonts/families/Nunito.json"); lbl.TextSize = 13; lbl.BackgroundTransparency = 1; lbl.TextXAlignment = Enum.TextXAlignment.Left
    local val = Instance.new("TextLabel", frame); val.Size = UDim2.new(0, 30, 0.5, 0); val.Position = UDim2.new(1, -45, 0, 5); val.Text = tostring(Settings[key]); val.TextColor3 = Color3.fromRGB(168, 85, 247); val.FontFace = Font.new("rbxasset://fonts/families/Nunito.json", Enum.FontWeight.Bold); val.TextSize = 13; val.BackgroundTransparency = 1; val.TextXAlignment = Enum.TextXAlignment.Right
    local track = Instance.new("Frame", frame); track.Size = UDim2.new(1, -30, 0, 6); track.Position = UDim2.new(0, 15, 1, -15); track.BackgroundColor3 = Color3.fromRGB(40, 42, 48); Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)
    local fill = Instance.new("Frame", track); fill.Size = UDim2.new((Settings[key]-min)/(max-min), 0, 1, 0); fill.BackgroundColor3 = Color3.fromRGB(168, 85, 247); Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)
    local btn = Instance.new("TextButton", track); btn.Size = UDim2.new(1, 0, 0, 20); btn.Position = UDim2.new(0, 0, 0.5, -10); btn.BackgroundTransparency = 1; btn.Text = ""
    local dragging = false
    btn.MouseButton1Down:Connect(function() dragging = true end); UIS.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end end)
    UIS.InputChanged:Connect(function(i) if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then local pct = math_clamp((i.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1); fill.Size = UDim2.new(pct, 0, 1, 0); Settings[key] = math.floor((min + (max - min) * pct) * 10)/10; val.Text = tostring(Settings[key]) end end)
end

-- 手動執行神仙功能的按鈕
local function CreateExecuteButton(parent, name, callback)
    local btn = Instance.new("TextButton", parent); btn.Size = UDim2.new(1, -10, 0, 42); btn.BackgroundColor3 = Color3.fromRGB(168, 85, 247); btn.Text = name; btn.TextColor3 = Color3.new(1,1,1); btn.FontFace = Font.new("rbxasset://fonts/families/Nunito.json", Enum.FontWeight.Bold); btn.TextSize = 14; Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    btn.MouseButton1Click:Connect(callback)
end

local TabRage = CreateTab("🔥 暴力神權", true)
CreateToggle(TabRage, "🎯 啟用子彈拐彎 (Silent Aim)", "SilentAim")
CreateToggle(TabRage, "🚀 穿牆魔術彈 (無視建築物)", "Wallbang")
CreateExecuteButton(TabRage, "⚠️ 點擊手動寫入：解鎖全庫 + 雷射光束", ApplyPremiumMods)

local TabLegit = CreateTab("🎯 常規自瞄", false)
CreateToggle(TabLegit, "啟用相機自瞄 (Aimbot)", "Aimbot")
CreateToggle(TabLegit, "啟用黏性瞄準 (Sticky Aim)", "StickyAim")
CreateToggle(TabLegit, "顯示自瞄圈 (FOV)", "ShowFOV")
CreateSlider(TabLegit, "自瞄平滑度 (1.0=暴力死鎖)", "AimbotSens", 1.0, 10.0) 
CreateSlider(TabLegit, "自瞄範圍 (FOV)", "FOV", 50, 800)

local TabVisuals = CreateTab("👁️ 透視與血條", false)
CreateToggle(TabVisuals, "開啟方框透視 (ESP)", "ESP")
CreateToggle(TabVisuals, "顯示綠色血條 (Health Bar)", "HealthBar")

local draggingUI, dragInput, dragStart, startPos
Main.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then draggingUI = true; dragStart = i.Position; startPos = Main.Position end end)
Main.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then draggingUI = false end end)
UIS.InputChanged:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseMovement then dragInput = i end end)
RunService.RenderStepped:Connect(function() if draggingUI and dragInput then local delta = dragInput.Position - dragStart; Main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y) end end)
UIS.InputBegan:Connect(function(i, gp) if not gp and i.KeyCode == Enum.KeyCode.J then Main.Visible = not Main.Visible end end)

-- ⚡ [渲染與索敵引擎 (血條回歸)] ⚡
_G.MUMU_CONN = RunService.RenderStepped:Connect(function()
    if _G.MUMU_FOV_CIRCLE then 
        _G.MUMU_FOV_CIRCLE.Position = Camera.ViewportSize / 2
        _G.MUMU_FOV_CIRCLE.Radius = Settings.FOV
        _G.MUMU_FOV_CIRCLE.Visible = Settings.ShowFOV 
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
                if hp > 0 then
                    local hrp = char.HumanoidRootPart; local headPos = char.Head.Position; local dist3D = (hrp.Position - myPos).Magnitude
                    
                    if dist3D < Settings.MaxDistance then
                        -- ESP 與血條渲染
                        if Settings.ESP or Settings.HealthBar then
                            local topPos, onScreen = Camera:WorldToViewportPoint(hrp.Position + v3new(0, 2.5, 0))
                            if onScreen then
                                local bottomPos = Camera:WorldToViewportPoint(hrp.Position - v3new(0, 3, 0)); local centerPos = Camera:WorldToViewportPoint(hrp.Position)
                                local height = math_abs(topPos.Y - bottomPos.Y); local width = height * 0.6
                                
                                if Settings.ESP then
                                    d.Box.Size = v2new(width, height); d.Box.Position = v2new(centerPos.X - width/2, centerPos.Y - height/2); d.Box.Visible = true
                                else d.Box.Visible = false end
                                
                                if Settings.HealthBar then
                                    local pct = math_clamp(hp/maxHp, 0, 1); local barX, barYBottom, barYTop = centerPos.X - width/2 - 6, centerPos.Y + height/2, centerPos.Y - height/2
                                    d.HealthBg.From = v2new(barX, barYBottom); d.HealthBg.To = v2new(barX, barYTop); d.HealthBg.Visible = true
                                    d.HealthBar.From = v2new(barX, barYBottom); d.HealthBar.To = v2new(barX, barYBottom - (height * pct)); d.HealthBar.Color = Color3.fromRGB(50, 255, 50); d.HealthBar.Visible = true
                                else d.HealthBg.Visible = false; d.HealthBar.Visible = false end
                            else d.Box.Visible = false; d.HealthBg.Visible = false; d.HealthBar.Visible = false end
                        else d.Box.Visible = false; d.HealthBg.Visible = false; d.HealthBar.Visible = false end
                        
                        -- 索敵邏輯
                        local isTargetVisible = Settings.Wallbang or IsVisible(headPos)
                        
                        if Settings.SilentAim and dist3D < bestSilentDist and isTargetVisible then 
                            bestSilentDist = dist3D; bestSilentTarget = char 
                        end
                        
                        if Settings.Aimbot then
                            local sp, os2 = Camera:WorldToViewportPoint(headPos)
                            if os2 then 
                                local dCenter = (v2new(sp.X, sp.Y) - screenCenter).Magnitude
                                if dCenter < bestAimbotDist and IsVisible(headPos) then 
                                    bestAimbotDist = dCenter; bestAimbotTarget = char 
                                end 
                            end
                        end
                    else d.Box.Visible = false; d.HealthBg.Visible = false; d.HealthBar.Visible = false end
                else d.Box.Visible = false; d.HealthBg.Visible = false; d.HealthBar.Visible = false end
            else d.Box.Visible = false; d.HealthBg.Visible = false; d.HealthBar.Visible = false end
        end
    end

    _G.SilentTargetPos = (Settings.SilentAim and bestSilentTarget) and GetPred(bestSilentTarget) or nil

    if Settings.Aimbot then
        if Settings.StickyAim and CurrentStickyTarget then
            local hp, _ = GetHealth(CurrentStickyTarget)
            if hp <= 0 or not CurrentStickyTarget:FindFirstChild("Head") or not IsVisible(CurrentStickyTarget.Head.Position) or not isRC then CurrentStickyTarget = nil end
        end
        if not CurrentStickyTarget and isRC then CurrentStickyTarget = bestAimbotTarget end
        local activeTarget = (Settings.StickyAim and CurrentStickyTarget) or bestAimbotTarget
        
        if activeTarget and isRC then
            local fp = GetPred(activeTarget)
            if fp then 
                local sp, os = Camera:WorldToViewportPoint(fp)
                if os and mousemoverel then 
                    local deltaX = sp.X - screenCenter.X; local deltaY = sp.Y - screenCenter.Y
                    if Settings.AimbotSens <= 1.1 then 
                        mousemoverel(deltaX, deltaY) 
                    else 
                        mousemoverel(deltaX / Settings.AimbotSens, deltaY / Settings.AimbotSens) 
                    end
                end 
            end
        end
    else CurrentStickyTarget = nil end
end)
