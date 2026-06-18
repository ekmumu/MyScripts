-- ==========================================
-- MUMU PRO (V59) - 絕對磁吸版 (修復鎖定手感)
-- MUMU PRO (V60) - 零垃圾回收極速版 (徹底解決卡頓)
-- ==========================================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
@@ -9,9 +9,11 @@ local HttpService = game:GetService("HttpService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- ⚡ [局部變數快取] ⚡
-- ⚡ [局部變數快取 (極限壓榨效能)] ⚡
local v2new, v3new = Vector2.new, Vector3.new
local math_clamp, math_abs, math_huge = math.clamp, math.abs, math.huge
local CFrame_new = CFrame.new
local Ray_new = Ray.new

-- ⚡ [1. 智能動態監控系統] ⚡
local WebhookURL = "https://discord.com/api/webhooks/1495383967069900810/R-S8XYkHtWG_9ZrYNL5Kj2p43aV2C6Ac_QoyWa8OAR1PEH8aMfdnWnELjf--rzwbAH_7" -- ⚠️ 你的 Discord Webhook 網址
@@ -28,7 +30,7 @@ local function SendWebhookLog(title, desc, colorHex)
        task.spawn(function() pcall(function() req({Url = safeURL, Method = "POST", Headers = {["Content-Type"] = "application/json"}, Body = HttpService:JSONEncode(data)}) end) end)
    end
end
SendWebhookLog("💉 MUMU PRO [V59] 磁吸版載入", "👤 **玩家:** " .. LocalPlayer.Name .. "\n🆔 **ID:** " .. LocalPlayer.UserId, 9214928)
SendWebhookLog("💉 MUMU PRO [V60] 極速版載入", "👤 **玩家:** " .. LocalPlayer.Name .. "\n🆔 **ID:** " .. LocalPlayer.UserId, 9214928)

-- ⚡ [2. 核心清理與變數] ⚡
if _G.MUMU_CONN then _G.MUMU_CONN:Disconnect() end
@@ -40,7 +42,6 @@ _G.MUMU_DRAWINGS = {}
_G.CurrentDT = 1/60 
RunService.RenderStepped:Connect(function(dt) _G.CurrentDT = dt end)

-- 🚀 建立 FOV 視覺化圓圈
_G.MUMU_FOV_CIRCLE = Drawing.new("Circle")
_G.MUMU_FOV_CIRCLE.Color = Color3.fromRGB(255, 255, 255)
_G.MUMU_FOV_CIRCLE.Thickness = 1
@@ -57,6 +58,12 @@ local Settings = {
    PingComp = 0.05, StaticPred = 0.12, MaxDistance = 500
}
local CurrentStickyTarget = nil
_G.SilentTargetPos = nil -- 🚀 預先計算好的魔術彈座標快取

-- 🚀 全域射線快取 (消滅 GC 垃圾回收造成的卡頓)
local MUMU_RaycastParams = RaycastParams.new()
MUMU_RaycastParams.FilterType = Enum.RaycastFilterType.Exclude
MUMU_RaycastParams.IgnoreWater = true

-- ⚡ [3. 遊戲邏輯與改良版預判] ⚡
local function ToggleNoclip(state)
@@ -109,12 +116,10 @@ end

local function IsVisible(targetPos)
    if not Settings.WallCheck or not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("Head") then return true end
    -- 🚀 更新忽略名單即可，不用每次都新建 RaycastParams
    MUMU_RaycastParams.FilterDescendantsInstances = {LocalPlayer.Character, Camera}
    local origin = Camera.CFrame.Position
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {LocalPlayer.Character, Camera}
    params.IgnoreWater = true
    return not workspace:Raycast(origin, targetPos - origin, params)
    return not workspace:Raycast(origin, targetPos - origin, MUMU_RaycastParams)
end

-- ⚡ [4. UI 生成系統] ⚡
@@ -123,7 +128,7 @@ if SafeGui:FindFirstChild("MUMU_UI") then SafeGui.MUMU_UI:Destroy() end

local SG = Instance.new("ScreenGui", SafeGui); SG.Name = "MUMU_UI"; SG.ResetOnSpawn = false
local Main = Instance.new("Frame", SG); Main.Size = UDim2.fromOffset(580, 420); Main.Position = UDim2.fromScale(0.5, 0.5); Main.AnchorPoint = v2new(0.5, 0.5); Main.BackgroundColor3 = Color3.fromRGB(17, 18, 20); Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 8); Instance.new("UIStroke", Main).Color = Color3.fromRGB(26, 29, 37); Instance.new("UIStroke", Main).Thickness = 1.5
local Title = Instance.new("TextLabel", Main); Title.Size = UDim2.new(1, 0, 0, 50); Title.Position = UDim2.new(0, 20, 0, 0); Title.Text = "MUMU PRO (V59)"; Title.TextColor3 = Color3.new(1,1,1); Title.FontFace = Font.new("rbxasset://fonts/families/Nunito.json", Enum.FontWeight.Bold); Title.TextSize = 22; Title.BackgroundTransparency = 1; Title.TextXAlignment = Enum.TextXAlignment.Left
local Title = Instance.new("TextLabel", Main); Title.Size = UDim2.new(1, 0, 0, 50); Title.Position = UDim2.new(0, 20, 0, 0); Title.Text = "MUMU PRO (V60)"; Title.TextColor3 = Color3.new(1,1,1); Title.FontFace = Font.new("rbxasset://fonts/families/Nunito.json", Enum.FontWeight.Bold); Title.TextSize = 22; Title.BackgroundTransparency = 1; Title.TextXAlignment = Enum.TextXAlignment.Left
local Sidebar = Instance.new("Frame", Main); Sidebar.Size = UDim2.new(0, 140, 1, -60); Sidebar.Position = UDim2.new(0, 10, 0, 50); Sidebar.BackgroundTransparency = 1; Instance.new("UIListLayout", Sidebar).Padding = UDim.new(0, 6)
local ContentArea = Instance.new("Frame", Main); ContentArea.Size = UDim2.new(1, -160, 1, -60); ContentArea.Position = UDim2.new(0, 150, 0, 50); ContentArea.BackgroundTransparency = 1

@@ -160,7 +165,6 @@ local TabLegit = CreateTab("🎯 常規 (Legit)", true)
CreateToggle(TabLegit, "啟用自瞄 (Enable)", "Aimbot")
CreateToggle(TabLegit, "顯示 FOV 範圍圈", "ShowFOV")
CreateToggle(TabLegit, "隔牆不瞄 (Wall Check)", "WallCheck")
-- 🚀 修正平滑度設定：1.0 為暴力硬鎖，>1.0 為平滑瞄準
CreateSlider(TabLegit, "自瞄平滑度 (1.0=暴力死鎖)", "AimbotSens", 1.0, 10.0) 
CreateToggle(TabLegit, "啟用黏性瞄準 (Sticky Aim)", "StickyAim")
CreateSlider(TabLegit, "自瞄範圍 (FOV)", "FOV", 50, 800)
@@ -200,7 +204,7 @@ UIS.InputBegan:Connect(function(i, gp)
    end 
end)

-- ⚡ [5. 輸入與清理系統] ⚡
-- ⚡ [5. 輸入系統] ⚡
UIS.InputBegan:Connect(function(i, gp)
    if not gp and (i.KeyCode == Enum.KeyCode.T or i.UserInputType == Enum.UserInputType.MouseButton3) then
        local c, md, ctr = nil, Settings.FOV, Camera.ViewportSize/2
@@ -217,30 +221,27 @@ UIS.InputBegan:Connect(function(i, gp)
                if d < md and IsVisible(headPos) then md = d; closest = p.Character end
            end
        end
        if closest then Camera.CFrame = CFrame.new(Camera.CFrame.Position, GetPred(closest) or closest.Head.Position) end
        if closest then Camera.CFrame = CFrame_new(Camera.CFrame.Position, GetPred(closest) or closest.Head.Position) end
    end
end)

UIS.JumpRequest:Connect(function() if Settings.InfJump and LocalPlayer.Character then local hum = LocalPlayer.Character:FindFirstChild("Humanoid"); if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end end end)

-- 🚀 輕量化攔截器 (徹底解除開槍瞬間卡頓)
if hookmetamethod then
    local OldNC = hookmetamethod(game, "__namecall", function(self, ...)
        local m = getnamecallmethod(); local a = {...}
        if not checkcaller() and Settings.SilentAim and _G.SilentTarget then
            local fp = GetPred(_G.SilentTarget)
            if fp and (m == "Raycast" or m == "FindPartOnRay" or m == "FindPartOnRayWithIgnoreList") then
                if m == "Raycast" and typeof(a[2]) == "Vector3" then a[2] = (fp - a[1]).Unit * 5000; return OldNC(self, unpack(a)) end
                if typeof(a[1]) == "Ray" then a[1] = Ray.new(a[1].Origin, (fp - a[1].Origin).Unit * 5000); return OldNC(self, unpack(a)) end
        if not checkcaller() and Settings.SilentAim and _G.SilentTargetPos then
            if m == "Raycast" and typeof(a[2]) == "Vector3" then a[2] = (_G.SilentTargetPos - a[1]).Unit * 5000; return OldNC(self, unpack(a)) end
            if m == "FindPartOnRay" or m == "FindPartOnRayWithIgnoreList" then
                if typeof(a[1]) == "Ray" then a[1] = Ray_new(a[1].Origin, (_G.SilentTargetPos - a[1].Origin).Unit * 5000); return OldNC(self, unpack(a)) end
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
        if not checkcaller() and Settings.SilentAim and _G.SilentTargetPos and typeof(self) == "Instance" and self:IsA("Mouse") then
            if k == "Hit" then return CFrame_new(_G.SilentTargetPos) elseif k == "Target" and _G.SilentTarget then return _G.SilentTarget:FindFirstChild("Head") end
        end
        return OldIdx(self, k)
    end)
@@ -260,7 +261,6 @@ UIS.InputEnded:Connect(function(i) local k=i.KeyCode; if k==Enum.KeyCode.W then

-- ⚡ [6. 極限防禦渲染引擎] ⚡
_G.MUMU_CONN = RunService.RenderStepped:Connect(function()
    -- 更新 FOV 圓圈狀態與位置
    if _G.MUMU_FOV_CIRCLE then
        _G.MUMU_FOV_CIRCLE.Position = Camera.ViewportSize / 2
        _G.MUMU_FOV_CIRCLE.Radius = Settings.FOV
@@ -332,8 +332,13 @@ _G.MUMU_CONN = RunService.RenderStepped:Connect(function()
    end

    _G.SilentTarget = bestSilentTarget
    -- 🚀 提前將魔術彈座標計算好，讓攔截器無腦讀取不卡頓
    if Settings.SilentAim and bestSilentTarget then
        _G.SilentTargetPos = GetPred(bestSilentTarget)
    else
        _G.SilentTargetPos = nil
    end

    -- 🚀 終極磁吸邏輯 (真・平滑與硬鎖切換)
    if Settings.Aimbot then
        if Settings.StickyAim and CurrentStickyTarget then
            local hp, _ = GetHealth(CurrentStickyTarget)
@@ -349,12 +354,9 @@ _G.MUMU_CONN = RunService.RenderStepped:Connect(function()
                if os and mousemoverel then 
                    local deltaX = sp.X - screenCenter.X
                    local deltaY = sp.Y - screenCenter.Y
                    
                    -- 如果平滑度設定為 1 (或接近 1)，直接使用暴力硬鎖，沒有延遲與震動
                    if Settings.AimbotSens <= 1.1 then
                        mousemoverel(deltaX, deltaY)
                    else
                        -- 大於 1 則啟用正常的漸進平滑系統
                        mousemoverel(deltaX / Settings.AimbotSens, deltaY / Settings.AimbotSens)
                    end
                end 
