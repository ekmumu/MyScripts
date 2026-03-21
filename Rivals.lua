-- ==========================================
-- MUMU RIVALS - 暴力鎖頭強化版 (加強鎖死 + 牆壁檢查)
-- ==========================================

local Settings = {
    ESP = true,
    Aimbot = true,
    WallCheck = true,    -- ⚡ 新增：隔牆不鎖 (防止亂飄)
    Strength = 0.25,     -- ⚡ 加強：鎖頭強度 (原 0.12 -> 0.25)
    FOV = 220,           
    MaxDistance = 300,   
    Prediction = 0.16,   
    TeamCheck = false
}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- [[ UI 與視覺化 ]]
local SafeGui = (gethui and gethui()) or game:GetService("CoreGui")
if SafeGui:FindFirstChild("MUMU_V5") then SafeGui.MUMU_V5:Destroy() end
local ScreenGui = Instance.new("ScreenGui", SafeGui)
ScreenGui.Name = "MUMU_V5"

local FOVCircle = Drawing.new("Circle")
FOVCircle.Thickness = 2
FOVCircle.Color = Color3.fromRGB(255, 0, 0)
FOVCircle.Transparency = 1
FOVCircle.Visible = true

local Main = Instance.new("Frame", ScreenGui)
Main.Size = UDim2.fromOffset(350, 480)
Main.Position = UDim2.fromScale(0.5, 0.5)
Main.AnchorPoint = Vector2.new(0.5, 0.5)
Main.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 15)
local Stroke = Instance.new("UIStroke", Main)
Stroke.Thickness = 4
Stroke.Color = Color3.fromRGB(255, 0, 0)

local Title = Instance.new("TextLabel", Main)
Title.Size = UDim2.new(1, 0, 0, 80)
Title.Text = "⚡ MUMU | OVERPOWER"
Title.TextSize = 30
Title.Font = Enum.Font.GothamBlack
Title.TextColor3 = Color3.new(1, 1, 1)
Title.BackgroundTransparency = 1

local Container = Instance.new("Frame", Main)
Container.Size = UDim2.new(0.9, 0, 0.75, 0)
Container.Position = UDim2.fromScale(0.05, 0.18)
Container.BackgroundTransparency = 1
Instance.new("UIListLayout", Container).Padding = UDim.new(0, 12)

local function AddToggle(name, default, callback)
    local state = default
    local btn = Instance.new("TextButton", Container)
    btn.Size = UDim2.new(1, 0, 0, 55)
    btn.BackgroundColor3 = state and Color3.fromRGB(200, 0, 0) or Color3.fromRGB(40, 40, 40)
    btn.Text = name .. ": " .. (state and "ON" or "OFF")
    btn.TextSize = 20
    btn.Font = Enum.Font.GothamBold
    btn.TextColor3 = Color3.new(1, 1, 1)
    Instance.new("UICorner", btn)
    btn.MouseButton1Click:Connect(function()
        state = not state
        btn.BackgroundColor3 = state and Color3.fromRGB(200, 0, 0) or Color3.fromRGB(40, 40, 40)
        btn.Text = name .. ": " .. (state and "ON" or "OFF")
        callback(state)
    end)
end

AddToggle("ESP 框框", Settings.ESP, function(v) Settings.ESP = v end)
AddToggle("暴力鎖頭", Settings.Aimbot, function(v) Settings.Aimbot = v end)
AddToggle("隔牆檢查", Settings.WallCheck, function(v) Settings.WallCheck = v end)

-- [[ 牆壁檢查邏輯 ]]
local function IsVisible(part, character)
    if not Settings.WallCheck then return true end
    local castPoints = {Camera.CFrame.Position, part.Position}
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {LocalPlayer.Character, Camera}
    
    local result = workspace:Raycast(Camera.CFrame.Position, part.Position - Camera.CFrame.Position, params)
    return result == nil or result.Instance:IsDescendantOf(character)
end

-- [[ 鎖頭與 ESP 核心 ]]
local function GetTarget()
    local target, maxDist = nil, Settings.FOV
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("Head") then
            if p.Character.Humanoid.Health <= 0 then continue end
            
            local distFromPlayer = (LocalPlayer.Character.HumanoidRootPart.Position - p.Character.HumanoidRootPart.Position).Magnitude
            if distFromPlayer > Settings.MaxDistance then continue end
            
            local pos, onScreen = Camera:WorldToViewportPoint(p.Character.Head.Position)
            if onScreen then
                local distFromMouse = (Vector2.new(pos.X, pos.Y) - UserInputService:GetMouseLocation()).Magnitude
                if distFromMouse < maxDist then
                    if IsVisible(p.Character.Head, p.Character) then -- ⚡ 牆壁檢查
                        maxDist = distFromMouse
                        target = p.Character
                    end
                end
            end
        end
    end
    return target
end

RunService.RenderStepped:Connect(function()
    -- ESP 更新 (保持框框)
    if Settings.ESP then
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                local h = p.Character:FindFirstChild("MUMU_Highlight") or Instance.new("Highlight", p.Character)
                h.Name = "MUMU_Highlight"
                h.FillTransparency = 1
                h.OutlineColor = Color3.new(1, 0, 0)
            end
        end
    end

    FOVCircle.Position = UserInputService:GetMouseLocation()
    FOVCircle.Radius = Settings.FOV
    FOVCircle.Visible = Main.Visible

    -- ⚡ 強化鎖頭：更高的插值數值帶來更硬的鎖定感
    if Settings.Aimbot and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
        local t = GetTarget()
        if t then
            local targetPos = t.Head.Position + (t.HumanoidRootPart.Velocity * Settings.Prediction)
            
            -- 視角鎖定
            Camera.CFrame = Camera.CFrame:Lerp(CFrame.lookAt(Camera.CFrame.Position, targetPos), Settings.Strength)
            -- 身體同步 (加強旋轉力道)
            local hrp = LocalPlayer.Character.HumanoidRootPart
            hrp.CFrame = hrp.CFrame:Lerp(CFrame.new(hrp.Position, Vector3.new(targetPos.X, hrp.Position.Y, targetPos.Z)), Settings.Strength)
        end
    end
end)

-- UI 拖曳
local d, ds, sp
Main.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then d = true ds = i.Position sp = Main.Position end end)
UserInputService.InputChanged:Connect(function(i) if d and i.UserInputType == Enum.UserInputType.MouseMovement then local delta = i.Position - ds Main.Position = UDim2.new(sp.X.Scale, sp.X.Offset + delta.X, sp.Y.Scale, sp.Y.Offset + delta.Y) end end)
UserInputService.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then d = false end end)
UserInputService.InputBegan:Connect(function(i, g) if not g and i.KeyCode == Enum.KeyCode.J then Main.Visible = not Main.Visible end end)
