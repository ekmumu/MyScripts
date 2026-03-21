-- ==========================================
-- MUMU RIVALS - 功能分離 + 子彈轉彎 (Silent Aim)
-- ==========================================

local Settings = {
    ESP = true,
    SmoothAim = true,    -- 右鍵絲滑瞄準
    SnapLock = true,     -- 開槍瞬間鎖頭
    SilentAim = true,    -- ⚡ 子彈轉彎 (吸附)
    
    FOV = 200,
    MaxDistance = 300,
    SmoothValue = 0.08,  -- 絲滑度
    Prediction = 0.15,
    WallCheck = true
}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- [[ UI 建立 ]]
local SafeGui = (gethui and gethui()) or game:GetService("CoreGui")
if SafeGui:FindFirstChild("MUMU_ULTRA") then SafeGui.MUMU_ULTRA:Destroy() end
local ScreenGui = Instance.new("ScreenGui", SafeGui)
ScreenGui.Name = "MUMU_ULTRA"

local Main = Instance.new("Frame", ScreenGui)
Main.Size = UDim2.fromOffset(380, 520) -- 視窗加大
Main.Position = UDim2.fromScale(0.5, 0.5)
Main.AnchorPoint = Vector2.new(0.5, 0.5)
Main.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 15)
local Stroke = Instance.new("UIStroke", Main)
Stroke.Thickness = 4
Stroke.Color = Color3.fromRGB(255, 50, 50)

local Title = Instance.new("TextLabel", Main)
Title.Size = UDim2.new(1, 0, 0, 70)
Title.Text = "⚡ MUMU ULTRA V7"
Title.TextSize = 30
Title.Font = Enum.Font.GothamBlack
Title.TextColor3 = Color3.new(1, 1, 1)
Title.BackgroundTransparency = 1

local Container = Instance.new("Frame", Main)
Container.Size = UDim2.new(0.9, 0, 0.8, 0)
Container.Position = UDim2.fromScale(0.05, 0.15)
Container.BackgroundTransparency = 1
Instance.new("UIListLayout", Container).Padding = UDim.new(0, 10)

-- [[ 按鈕生成器 ]]
local function AddToggle(name, default, callback)
    local state = default
    local btn = Instance.new("TextButton", Container)
    btn.Size = UDim2.new(1, 0, 0, 55)
    btn.BackgroundColor3 = state and Color3.fromRGB(255, 50, 50) or Color3.fromRGB(40, 40, 40)
    btn.Text = "  " .. name .. ": " .. (state and "ON" or "OFF")
    btn.TextSize = 20
    btn.Font = Enum.Font.GothamBold
    btn.TextColor3 = Color3.new(1, 1, 1)
    btn.TextXAlignment = Enum.TextXAlignment.Left
    Instance.new("UICorner", btn)
    
    btn.MouseButton1Click:Connect(function()
        state = not state
        btn.BackgroundColor3 = state and Color3.fromRGB(255, 50, 50) or Color3.fromRGB(40, 40, 40)
        btn.Text = "  " .. name .. ": " .. (state and "ON" or "OFF")
        callback(state)
    end)
end

AddToggle("ESP 框框透視", Settings.ESP, function(v) Settings.ESP = v end)
AddToggle("右鍵絲滑瞄準", Settings.SmoothAim, function(v) Settings.SmoothAim = v end)
AddToggle("射擊瞬間鎖頭", Settings.SnapLock, function(v) Settings.SnapLock = v end)
AddToggle("子彈轉彎吸附", Settings.SilentAim, function(v) Settings.SilentAim = v end)
AddToggle("隔牆檢查", Settings.WallCheck, function(v) Settings.WallCheck = v end)

-- [[ 核心邏輯區 ]]

local function IsVisible(part, character)
    if not Settings.WallCheck then return true end
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {LocalPlayer.Character, Camera}
    local result = workspace:Raycast(Camera.CFrame.Position, part.Position - Camera.CFrame.Position, params)
    return result == nil or result.Instance:IsDescendantOf(character)
end

local function GetTarget()
    local target, maxDist = nil, Settings.FOV
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("Head") and p.Character.Humanoid.Health > 0 then
            local dist = (LocalPlayer.Character.HumanoidRootPart.Position - p.Character.HumanoidRootPart.Position).Magnitude
            if dist > Settings.MaxDistance then continue end
            local pos, onScreen = Camera:WorldToViewportPoint(p.Character.Head.Position)
            if onScreen then
                local mDist = (Vector2.new(pos.X, pos.Y) - UserInputService:GetMouseLocation()).Magnitude
                if mDist < maxDist and IsVisible(p.Character.Head, p.Character) then
                    maxDist = mDist
                    target = p.Character
                end
            end
        end
    end
    return target
end

-- ⚡ 3. 子彈轉彎 (Silent Aim) 攔截技術
local oldNamecall
oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
    local args = {...}
    local method = getnamecallmethod()
    
    if Settings.SilentAim and method == "Raycast" and not checkcaller() then
        local t = GetTarget()
        if t then
            args[2] = (t.Head.Position - args[1]).Unit * 1000 -- 強制將射線方向改向敵人頭部
            return oldNamecall(self, unpack(args))
        end
    end
    return oldNamecall(self, ...)
end)

-- [[ 每一幀執行更新 ]]
RunService.RenderStepped:Connect(function()
    -- ESP 更新
    if Settings.ESP then
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character and not p.Character:FindFirstChild("MUMU_H") then
                Instance.new("Highlight", p.Character).Name = "MUMU_H"
            end
        end
    end

    -- 瞄準邏輯
    local t = GetTarget()
    if t and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
        local targetPos = t.Head.Position + (t.HumanoidRootPart.Velocity * Settings.Prediction)
        local isFiring = UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)
        
        local strength = 0
        if isFiring and Settings.SnapLock then
            strength = 1.0 -- 瞬鎖
        elseif Settings.SmoothAim then
            strength = Settings.SmoothValue -- 絲滑
        end

        if strength > 0 then
            Camera.CFrame = Camera.CFrame:Lerp(CFrame.lookAt(Camera.CFrame.Position, targetPos), strength)
            LocalPlayer.Character.HumanoidRootPart.CFrame = LocalPlayer.Character.HumanoidRootPart.CFrame:Lerp(CFrame.new(LocalPlayer.Character.HumanoidRootPart.Position, Vector3.new(targetPos.X, LocalPlayer.Character.HumanoidRootPart.Position.Y, targetPos.Z)), strength)
        end
    end
end)

-- UI 拖曳與 J 鍵控制
local d, ds, sp
Main.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then d = true ds = i.Position sp = Main.Position end end)
UserInputService.InputChanged:Connect(function(i) if d and i.UserInputType == Enum.UserInputType.MouseMovement then local delta = i.Position - ds Main.Position = UDim2.new(sp.X.Scale, sp.X.Offset + delta.X, sp.Y.Scale, sp.Y.Offset + delta.Y) end end)
UserInputService.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then d = false end end)
UserInputService.InputBegan:Connect(function(i, g) if not g and i.KeyCode == Enum.KeyCode.J then Main.Visible = not Main.Visible end end)
