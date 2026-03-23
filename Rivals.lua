-- ==========================================
-- MUMU RIVALS - 物理滑鼠死鎖 + 飛行穿牆 + 穩定ESP
-- ==========================================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

local Settings = {
    ESP = true,
    Aimbot = true,
    TeamCheck = true,  
    WallCheck = true,  
    Fly = false,       -- ⚡ 飛行模式
    Noclip = false,    -- ⚡ 穿牆模式
    FlySpeed = 100,     -- ⚡ 飛行速度
    Prediction = 0.12, 
    FOV = 250,
    MaxDistance = 350,
    Smoothness = 1 
}

-- [[ 1. 絕對中心固定 UI ]]
local SafeGui = (gethui and gethui()) or game:GetService("CoreGui")
if SafeGui:FindFirstChild("MUMU_PHYSICS_LOCK") then
    SafeGui.MUMU_PHYSICS_LOCK:Destroy()
end

local ScreenGui = Instance.new("ScreenGui", SafeGui)
ScreenGui.Name = "MUMU_PHYSICS_LOCK"
ScreenGui.ResetOnSpawn = false

local Main = Instance.new("Frame", ScreenGui)
Main.Size = UDim2.fromOffset(300, 580) 
Main.Position = UDim2.fromScale(0.5, 0.5) 
Main.AnchorPoint = Vector2.new(0.5, 0.5)  
Main.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 10)
Instance.new("UIStroke", Main).Thickness = 3
Instance.new("UIStroke", Main).Color = Color3.fromRGB(255, 0, 0)

local Title = Instance.new("TextLabel", Main)
Title.Size = UDim2.new(1, 0, 0, 70)
Title.Text = "⚡ MUMU CORE"
Title.TextSize = 30
Title.Font = Enum.Font.GothamBlack
Title.TextColor3 = Color3.new(1, 1, 1)
Title.BackgroundTransparency = 1

local Container = Instance.new("Frame", Main)
Container.Size = UDim2.new(0.9, 0, 0.8, 0)
Container.Position = UDim2.fromScale(0.05, 0.13)
Container.BackgroundTransparency = 1
local Layout = Instance.new("UIListLayout", Container)
Layout.Padding = UDim.new(0, 12)

-- [ 按鈕生成器 (支援額外回呼函數) ]
local function AddToggle(name, settingKey, customCallback)
    local btn = Instance.new("TextButton", Container)
    btn.Size = UDim2.new(1, 0, 0, 55)
    btn.BackgroundColor3 = Settings[settingKey] and Color3.fromRGB(200, 0, 0) or Color3.fromRGB(45, 45, 45)
    btn.Text = name .. ": " .. (Settings[settingKey] and "ON" or "OFF")
    btn.TextSize = 20
    btn.Font = Enum.Font.GothamBold
    btn.TextColor3 = Color3.new(1, 1, 1)
    Instance.new("UICorner", btn)
    
    btn.MouseButton1Click:Connect(function()
        Settings[settingKey] = not Settings[settingKey]
        btn.Text = name .. ": " .. (Settings[settingKey] and "ON" or "OFF")
        btn.BackgroundColor3 = Settings[settingKey] and Color3.fromRGB(200, 0, 0) or Color3.fromRGB(45, 45, 45)
        if customCallback then customCallback(Settings[settingKey]) end
    end)
end

-- [[ ⚡ 飛行系統的物理元件控制 ]]
local FlyBodyGyro, FlyBodyVelocity
local CONTROL = {F = 0, B = 0, L = 0, R = 0, UP = 0, DOWN = 0}

local function UpdateFlyState(state)
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") or not char:FindFirstChild("Humanoid") then return end
    local hrp = char.HumanoidRootPart

    if state then
        -- 開啟飛行
        FlyBodyGyro = Instance.new("BodyGyro", hrp)
        FlyBodyGyro.P = 9e4
        FlyBodyGyro.maxTorque = Vector3.new(9e9, 9e9, 9e9)
        FlyBodyGyro.cframe = hrp.CFrame

        FlyBodyVelocity = Instance.new("BodyVelocity", hrp)
        FlyBodyVelocity.velocity = Vector3.new(0, 0, 0)
        FlyBodyVelocity.maxForce = Vector3.new(9e9, 9e9, 9e9)

        char.Humanoid.PlatformStand = true 
    else
        -- 關閉飛行
        if FlyBodyGyro then FlyBodyGyro:Destroy() end
        if FlyBodyVelocity then FlyBodyVelocity:Destroy() end
        char.Humanoid.PlatformStand = false
    end
end

AddToggle("方框透視 (Box)", "ESP")
AddToggle("物理死鎖 (右鍵)", "Aimbot")
AddToggle("不瞄隊友 (Team)", "TeamCheck")
AddToggle("隔牆不瞄 (Wall)", "WallCheck")
AddToggle("飛行模式 (Fly)", "Fly", UpdateFlyState) 
AddToggle("穿牆模式 (Noclip)", "Noclip")           

local Hint = Instance.new("TextLabel", Main)
Hint.Size = UDim2.new(1, 0, 0, 30)
Hint.Position = UDim2.new(0, 0, 1, -35)
Hint.Text = "飛行控制: WASD | 空白鍵升 | Ctrl降"
Hint.TextColor3 = Color3.fromRGB(150, 150, 150)
Hint.TextSize = 14
Hint.Font = Enum.Font.Gotham
Hint.BackgroundTransparency = 1

-- [[ 2. 按鍵監聽 ]]
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if not gameProcessed and input.KeyCode == Enum.KeyCode.J then
        Main.Visible = not Main.Visible
    end
    -- 飛行控制按下
    if not gameProcessed then
        local k = input.KeyCode
        if k == Enum.KeyCode.W then CONTROL.F = 1
        elseif k == Enum.KeyCode.S then CONTROL.B = -1
        elseif k == Enum.KeyCode.A then CONTROL.L = -1
        elseif k == Enum.KeyCode.D then CONTROL.R = 1
        elseif k == Enum.KeyCode.Space then CONTROL.UP = 1
        elseif k == Enum.KeyCode.LeftControl then CONTROL.DOWN = -1 end
    end
end)

UserInputService.InputEnded:Connect(function(input, gameProcessed)
    -- 飛行控制鬆開
    local k = input.KeyCode
    if k == Enum.KeyCode.W then CONTROL.F = 0
    elseif k == Enum.KeyCode.S then CONTROL.B = 0
    elseif k == Enum.KeyCode.A then CONTROL.L = 0
    elseif k == Enum.KeyCode.D then CONTROL.R = 0
    elseif k == Enum.KeyCode.Space then CONTROL.UP = 0
    elseif k == Enum.KeyCode.LeftControl then CONTROL.DOWN = 0 end
end)

-- [[ 3. 過濾邏輯 ]]
local function IsVisible(targetChar)
    if not Settings.WallCheck then return true end
    if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("Head") then return true end

    local origin = Camera.CFrame.Position
    local targetPos = targetChar.Head.Position
    
    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    rayParams.FilterDescendantsInstances = {LocalPlayer.Character, Camera}
    rayParams.IgnoreWater = true

    local result = workspace:Raycast(origin, targetPos - origin, rayParams)
    
    if result then
        if result.Instance:IsDescendantOf(targetChar) then return true else return false end
    end
    return true
end

local function IsTeammate(p)
    if not Settings.TeamCheck then return false end
    if p.Team ~= nil and LocalPlayer.Team ~= nil then
        return p.Team == LocalPlayer.Team
    end
    return false
end

-- [[ 4. 穿牆系統 (Stepped) ]]
RunService.Stepped:Connect(function()
    if Settings.Noclip and LocalPlayer.Character then
        for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
            if part:IsA("BasePart") and part.CanCollide then
                part.CanCollide = false
            end
        end
    end
end)

-- [[ 5. ⚡ 修復後絕對穩定的方框透視 (Box ESP) ]]
local ESP_Boxes = {}
local function UpdateESP()
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            if not ESP_Boxes[p] then
                local box = Drawing.new("Square")
                box.Color = Color3.fromRGB(255, 50, 50)
                box.Thickness = 1.5
                box.Filled = false
                ESP_Boxes[p] = box
            end

            local box = ESP_Boxes[p]
            if Settings.ESP and p.Character and p.Character:FindFirstChild("HumanoidRootPart") and p.Character:FindFirstChild("Humanoid") and p.Character.Humanoid.Health > 0 then
                
                if IsTeammate(p) then box.Visible = false continue end
                
                local hrp = p.Character.HumanoidRootPart
                local dist = (Camera.CFrame.Position - hrp.Position).Magnitude
                
                if dist < Settings.MaxDistance then
                    -- ⚡ 關鍵修改：只使用 HRP (身體中心) 進行上下固定偏移，不再抓取會擺動的 Head
                    local topPos, onScreen = Camera:WorldToViewportPoint(hrp.Position + Vector3.new(0, 2.5, 0))
                    local bottomPos = Camera:WorldToViewportPoint(hrp.Position - Vector3.new(0, 3, 0))
                    local centerPos = Camera:WorldToViewportPoint(hrp.Position)

                    if onScreen then
                        local height = math.abs(topPos.Y - bottomPos.Y)
                        local width = height * 0.6
                        box.Size = Vector2.new(width, height)
                        -- 以中心點對齊，確保框框不會隨動畫左右偏移
                        box.Position = Vector2.new(centerPos.X - width/2, topPos.Y)
                        box.Visible = true
                    else box.Visible = false end
                else box.Visible = false end
            else box.Visible = false end
        end
    end
end

-- [[ 6. 核心：物理模擬 + 死鎖記憶 + 飛行物理運算 ]]
local LockedTarget = nil 

local function FindNewTarget()
    local target, maxDist = nil, Settings.FOV
    local mousePos = UserInputService:GetMouseLocation()
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("Head") and p.Character:FindFirstChild("Humanoid") and p.Character.Humanoid.Health > 0 then
            
            if IsTeammate(p) then continue end
            if (Camera.CFrame.Position - p.Character.HumanoidRootPart.Position).Magnitude > Settings.MaxDistance then continue end
            if not IsVisible(p.Character) then continue end

            local pos, onScreen = Camera:WorldToViewportPoint(p.Character.Head.Position)
            if onScreen then
                local dist = (Vector2.new(pos.X, pos.Y) - mousePos).Magnitude
                if dist < maxDist then maxDist = dist target = p.Character end
            end
        end
    end
    return target
end

RunService.RenderStepped:Connect(function()
    UpdateESP()

    -- 飛行物理更新
    if Settings.Fly and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        if FlyBodyGyro and FlyBodyVelocity then
            local camCF = Camera.CFrame
            FlyBodyGyro.cframe = camCF 
            
            local moveDir = Vector3.new(0, 0, 0)
            moveDir = moveDir + camCF.LookVector * (CONTROL.F + CONTROL.B)
            moveDir = moveDir + camCF.RightVector * (CONTROL.L + CONTROL.R)
            moveDir = moveDir + camCF.UpVector * (CONTROL.UP + CONTROL.DOWN)

            if moveDir.Magnitude > 0 then
                FlyBodyVelocity.velocity = moveDir.Unit * Settings.FlySpeed
            else
                FlyBodyVelocity.velocity = Vector3.new(0, 0, 0)
            end
        end
    end

    -- 鎖頭邏輯
    if Settings.Aimbot and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
        
        if not LockedTarget then
            LockedTarget = FindNewTarget()
        end

        if LockedTarget and LockedTarget:FindFirstChild("Head") and LockedTarget:FindFirstChild("Humanoid") and LockedTarget.Humanoid.Health > 0 then
            
            if (Camera.CFrame.Position - LockedTarget.HumanoidRootPart.Position).Magnitude > Settings.MaxDistance or not IsVisible(LockedTarget) then
                LockedTarget = nil 
                return
            end

            local headPos = LockedTarget.Head.Position + (LockedTarget.HumanoidRootPart.Velocity * Settings.Prediction)
            local screenPos, onScreen = Camera:WorldToViewportPoint(headPos)
            
            if onScreen then
                local mousePos = UserInputService:GetMouseLocation()
                
                if mousemoverel then
                    local moveX = (screenPos.X - mousePos.X) * Settings.Smoothness
                    local moveY = (screenPos.Y - mousePos.Y) * Settings.Smoothness
                    mousemoverel(moveX, moveY)
                else
                    Camera.CFrame = CFrame.lookAt(Camera.CFrame.Position, headPos)
                end
            else
                LockedTarget = nil 
            end
        else
            LockedTarget = nil 
        end
    else
        LockedTarget = nil 
    end
end)

-- 角色重生或死亡時關閉飛行，防止 Bug
LocalPlayer.CharacterAdded:Connect(function()
    if Settings.Fly then
        Settings.Fly = false
    end
end)

Players.PlayerRemoving:Connect(function(plr)
    if ESP_Boxes[plr] then ESP_Boxes[plr]:Remove() ESP_Boxes[plr] = nil end
    if LockedTarget and LockedTarget.Name == plr.Name then LockedTarget = nil end
end)
