-- ==========================================
-- MUMU PRO (V67) - 純淨致命版 (J鍵專武 / 穩定透視自瞄)
-- ==========================================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
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
    ESP = true, -- 透視
    SilentAim = false, FOV = 400, ShowFOV = true, -- 子彈拐彎
    RapidFire = false, NoRecoil = false, -- 改槍
    SkinChanger = false, TargetSkin = "Galaxy", -- 造型
    MaxDistance = 1000
}

local _G_SilentTargetPos = nil

-- ⚡ [穩定版子彈拐彎 (Silent Aim)] ⚡
if hookmetamethod then
    local OldNC
    OldNC = hookmetamethod(game, "__namecall", function(self, ...)
        local m = getnamecallmethod(); local a = {...}
        if not checkcaller() and Settings.SilentAim and _G_SilentTargetPos then
            -- 只攔截發射射線的那一刻，不影響玩家物理
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

-- ⚡ [記憶體改槍與安全造型解鎖] ⚡
local function ApplySafeMods()
    if not getgc then return end
    for _, v in pairs(getgc(true)) do
        if type(v) == "table" then
            -- 射速與後座力
            if Settings.RapidFire and rawget(v, "FireRate") then rawset(v, "FireRate", 0.01) end
            if Settings.NoRecoil and rawget(v, "Recoil") then rawset(v, "Recoil", 0); rawset(v, "Spread", 0) end
            -- 安全解鎖裝備庫
            if Settings.SkinChanger and rawget(v, "OwnedWraps") and type(v.OwnedWraps) == "table" then
                v.OwnedWraps[Settings.TargetSkin] = true
            end
        end
    end
end

-- ⚡ [高級黑金 UI 介面] ⚡
local SafeGui = (gethui and gethui()) or game:GetService("CoreGui")
if SafeGui:FindFirstChild("MUMU_UI") then SafeGui.MUMU_UI:Destroy() end

local SG = Instance.new("ScreenGui", SafeGui); SG.Name = "MUMU_UI"; SG.ResetOnSpawn = false
local Main = Instance.new("Frame", SG); Main.Size = UDim2.fromOffset(500, 350); Main.Position = UDim2.fromScale(0.5, 0.5); Main.AnchorPoint = Vector2.new(0.5, 0.5); Main.BackgroundColor3 = Color3.fromRGB(20, 20, 25); Main.BorderSizePixel = 0; Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 10); Instance.new("UIStroke", Main).Color = Color3.fromRGB(255, 215, 0); Instance.new("UIStroke", Main).Thickness = 1.5
local Title = Instance.new("TextLabel", Main); Title.Size = UDim2.new(1, 0, 0, 45); Title.Position = UDim2.new(0, 15, 0, 0); Title.Text = "MUMU PRO (STABLE)"; Title.TextColor3 = Color3.fromRGB(255, 215, 0); Title.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold); Title.TextSize = 18; Title.BackgroundTransparency = 1; Title.TextXAlignment = Enum.TextXAlignment.Left

local ContentArea = Instance.new("ScrollingFrame", Main); ContentArea.Size = UDim2.new(1, -20, 1, -55); ContentArea.Position = UDim2.new(0, 10, 0, 45); ContentArea.BackgroundTransparency = 1; ContentArea.ScrollBarThickness = 2; Instance.new("UIListLayout", ContentArea).Padding = UDim.new(0, 8)

local function CreateToggle(parent, name, key, callback)
    local frame = Instance.new("Frame", parent); frame.Size = UDim2.new(1, -10, 0, 42); frame.BackgroundColor3 = Color3.fromRGB(28, 28, 35); Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 6)
    local lbl = Instance.new("TextLabel", frame); lbl.Size = UDim2.new(0.7, 0, 1, 0); lbl.Position = UDim2.new(0, 15, 0, 0); lbl.Text = name; lbl.TextColor3 = Color3.new(1,1,1); lbl.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json"); lbl.TextSize = 14; lbl.BackgroundTransparency = 1; lbl.TextXAlignment = Enum.TextXAlignment.Left
    local btn = Instance.new("TextButton", frame); btn.Size = UDim2.new(0, 40, 0, 22); btn.Position = UDim2.new(1, -55, 0.5, -11); btn.Text = ""; btn.BackgroundColor3 = Color3.fromRGB(45, 45, 55); Instance.new("UICorner", btn).CornerRadius = UDim.new(1, 0)
    local circle = Instance.new("Frame", btn); circle.Size = UDim2.new(0, 16, 0, 16); circle.Position = UDim2.new(0, 3, 0.5, -8); circle.BackgroundColor3 = Color3.new(1,1,1); Instance.new("UICorner", circle).CornerRadius = UDim.new(1, 0)

    local function update()
        if Settings[key] then btn.BackgroundColor3 = Color3.fromRGB(255, 215, 0); circle.Position = UDim2.new(1, -19, 0.5, -8)
        else btn.BackgroundColor3 = Color3.fromRGB(45, 45, 55); circle.Position = UDim2.new(0, 3, 0.5, -8) end
    end
    update()
    btn.MouseButton1Click:Connect(function() Settings[key] = not Settings[key]; update(); if callback then callback(Settings[key]) end end)
end

-- 生成純淨版功能
CreateToggle(ContentArea, "👁️ 開啟透視 (ESP Box)", "ESP")
CreateToggle(ContentArea, "🎯 子彈拐彎 (Silent Aim)", "SilentAim")
CreateToggle(ContentArea, "⭕ 顯示 FOV 範圍", "ShowFOV")
CreateToggle(ContentArea, "🔫 解鎖極限射速 (Rapid Fire)", "RapidFire", function() ApplySafeMods() end)
CreateToggle(ContentArea, "🚫 無後座力 (No Recoil)", "NoRecoil", function() ApplySafeMods() end)
CreateToggle(ContentArea, "💎 解鎖 Galaxy 造型 (Skin)", "SkinChanger", function() ApplySafeMods() end)

-- UI 拖曳
local draggingUI, dragInput, dragStart, startPos
Main.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then draggingUI = true; dragStart = i.Position; startPos = Main.Position end end)
Main.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then draggingUI = false end end)
UIS.InputChanged:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseMovement then dragInput = i end end)
RunService.RenderStepped:Connect(function() if draggingUI and dragInput then local delta = dragInput.Position - dragStart; Main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y) end end)

-- J 鍵開關 UI
UIS.InputBegan:Connect(function(i, gp) if not gp and i.KeyCode == Enum.KeyCode.J then Main.Visible = not Main.Visible end end)

-- ⚡ [渲染與自瞄核心] ⚡
_G.MUMU_CONN = RunService.RenderStepped:Connect(function()
    if _G.MUMU_FOV_CIRCLE then 
        _G.MUMU_FOV_CIRCLE.Position = Camera.ViewportSize / 2
        _G.MUMU_FOV_CIRCLE.Radius = Settings.FOV
        _G.MUMU_FOV_CIRCLE.Visible = Settings.SilentAim and Settings.ShowFOV 
    end

    local myPos = Camera.CFrame.Position
    local screenCenter = Camera.ViewportSize / 2
    local bestTarget = nil; local bestDist = Settings.FOV

    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("Head") and p.Character:FindFirstChild("HumanoidRootPart") then
            local hum = p.Character:FindFirstChild("Humanoid")
            if hum and hum.Health > 0 then
                local hrp = p.Character.HumanoidRootPart
                local dist3D = (hrp.Position - myPos).Magnitude
                
                -- ESP 透視方框
                if not _G.MUMU_DRAWINGS[p] then _G.MUMU_DRAWINGS[p] = { Box = Drawing.new("Square") }; _G.MUMU_DRAWINGS[p].Box.Color = Color3.fromRGB(255, 0, 0); _G.MUMU_DRAWINGS[p].Box.Thickness = 1.5; _G.MUMU_DRAWINGS[p].Box.Filled = false end
                local d = _G.MUMU_DRAWINGS[p]

                if dist3D < Settings.MaxDistance then
                    local topPos, onScreen = Camera:WorldToViewportPoint(hrp.Position + Vector3.new(0, 2.5, 0))
                    if Settings.ESP and onScreen then
                        local bottomPos = Camera:WorldToViewportPoint(hrp.Position - Vector3.new(0, 3, 0))
                        local height = math.abs(topPos.Y - bottomPos.Y); local width = height * 0.6
                        d.Box.Size = Vector2.new(width, height); d.Box.Position = Vector2.new(topPos.X - width/2, topPos.Y); d.Box.Visible = true
                    else d.Box.Visible = false end
                    
                    -- 子彈拐彎索敵
                    local sp, os2 = Camera:WorldToViewportPoint(p.Character.Head.Position)
                    if os2 then
                        local dist = (Vector2.new(sp.X, sp.Y) - screenCenter).Magnitude
                        if dist < bestDist then bestDist = dist; bestTarget = p.Character end
                    end
                else d.Box.Visible = false end
            elseif _G.MUMU_DRAWINGS[p] then _G.MUMU_DRAWINGS[p].Box.Visible = false end
        elseif _G.MUMU_DRAWINGS[p] then _G.MUMU_DRAWINGS[p].Box.Visible = false end
    end

    if bestTarget then _G_SilentTargetPos = bestTarget.Head.Position else _G_SilentTargetPos = nil end
end)

task.spawn(function() while task.wait(2) do ApplySafeMods() end end)
