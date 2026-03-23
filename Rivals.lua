-- ==========================================
-- MUMU RIVALS - 物理滑鼠硬鎖 (靈敏度補償) + 飛行穿牆 + 動態血條
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
    Fly = false,       
    Noclip = false,    
    FlySpeed = 100,     
    Prediction = 0.12, 
    FOV = 250,
    MaxDistance = 350,
    Smoothness = 1,
    AimbotSens = 1.5 -- ⚡ 新增：靈敏度補償 (放大滑鼠推力，數值越大鎖越死)
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

-- [ 按鈕生成器 ]
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

-- [[ 飛行系統 ]]
local FlyBodyGyro, FlyBodyVelocity
local CONTROL = {F = 0, B = 0, L = 0, R = 0, UP = 0, DOWN = 0}

local function UpdateFlyState(state)
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") or not char:FindFirstChild("Humanoid") then return end
    local hrp = char.HumanoidRootPart

    if state then
        FlyBodyGyro = Instance.new("BodyGyro", hrp)
        FlyBodyGyro.P = 9e4
        FlyBodyGyro.maxTorque = Vector3.new(9e9, 9e9, 9e9)
        FlyBodyGyro.cframe = hrp.CFrame

        FlyBodyVelocity = Instance.new("BodyVelocity", hrp)
        FlyBodyVelocity.velocity = Vector3.new(0, 0, 0)
        FlyBodyVelocity.maxForce = Vector3.new(9e9, 9e9, 9e9)

        char.Humanoid.PlatformStand = true 
    else
        if FlyBodyGyro then FlyBodyGyro:Destroy() end
        if FlyBodyVelocity then FlyBodyVelocity:Destroy() end
        char.Humanoid.PlatformStand = false
    end
end

AddToggle("方框與血條 (ESP)", "ESP")
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

-- [[ 5. 升級版 ESP (方框 + 動態血量條) ]]
local ESP_Drawings = {}

local function UpdateESP()
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            if not ESP_Drawings[p] then
                ESP_Drawings[p] = {
                    Box = Drawing.new("Square"),
                    HealthBg = Drawing.new("Square"),
                    HealthBar = Drawing.new("Square")
                }
                
                ESP_Drawings[p].Box.Color = Color3.fromRGB(255, 50, 50)
                ESP_Drawings[p].Box.Thickness = 1.5
                ESP_Drawings[p].Box.Filled = false
                
                ESP_Drawings[p].HealthBg.Color = Color3.fromRGB(0, 0, 0)
                ESP_Drawings[p].HealthBg.Thickness = 1
                ESP_Drawings[p].HealthBg.Filled = true
                
                ESP_Drawings[p].HealthBar.Thickness = 1
                ESP_Drawings[p].HealthBar.Filled = true
            end

            local drawings = ESP_Drawings[p]

            if Settings.ESP and p.Character and p.Character:FindFirstChild("HumanoidRootPart") and p.Character:FindFirstChild("Humanoid") and p.Character.Humanoid.Health > 0 then
                
                if IsTeammate(p) then 
                    drawings.Box.Visible = false
                    drawings.HealthBg.Visible = false
                    drawings.HealthBar.Visible = false
                    continue 
                end
                
                local hrp = p.Character.HumanoidRootPart
                local dist = (Camera.CFrame.Position - hrp.Position).Magnitude
                
                if dist < Settings.MaxDistance then
                    local topPos, onScreen = Camera:WorldToViewportPoint(hrp.Position + Vector3.new(0, 2.5, 0))
                    local bottomPos = Camera:WorldToViewportPoint(hrp.Position - Vector3.new(0, 3, 0))
                    local centerPos = Camera:WorldToViewportPoint(hrp.Position)

                    if onScreen then
                        local height = math.abs(topPos.Y - bottomPos.Y)
                        local width = height * 0.6
                        
                        local boxX = centerPos.X - width/2
                        local boxY = topPos.Y
                        
                        drawings.Box.Size = Vector2.new(width, height)
                        drawings.Box.Position = Vector2.new(boxX, boxY)
                        drawings.Box.Visible = true
                        
                        local health = p.Character.Humanoid.Health
                        local maxHealth = p.Character.Humanoid.MaxHealth
                        local healthPercent = math.clamp(health / maxHealth, 0, 1)
                        
                        drawings.HealthBg.Size = Vector2.new(4, height)
                        drawings.HealthBg.Position = Vector2.new(boxX - 6, boxY)
                        drawings.HealthBg.Visible = true
                        
                        local barHeight = height * healthPercent
                        drawings.HealthBar.Size = Vector2.new(2, barHeight)
                        drawings.HealthBar.Position = Vector2.new(boxX - 5, boxY + (height - barHeight))
                        
                        drawings.HealthBar.Color = Color3.fromHSV(healthPercent * 0.3, 1, 1)
                        drawings.HealthBar.Visible = true

                    else 
                        drawings.Box.Visible = false
                        drawings.HealthBg.Visible = false
                        drawings.HealthBar.Visible = false
                    end
                else 
                    drawings.Box.Visible = false
                    drawings.HealthBg.Visible = false
                    drawings.HealthBar.Visible = false
                end
            else 
                drawings.Box.Visible = false
                drawings.HealthBg.Visible = false
                drawings.HealthBar.Visible = false
            end
        end
    end
end

-- [[ 6. 核心：物理模擬 + 死鎖記憶 + 飛行 ]]
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
                    -- ⚡ 加入 AimbotSens 補償倍率，強行推動滑鼠對抗遊戲靈敏度
                    local moveX = (screenPos.X - mousePos.X) * Settings.Smoothness * Settings.AimbotSens
                    local moveY = (screenPos.Y - mousePos.Y) * Settings.Smoothness * Settings.AimbotSens
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

LocalPlayer.CharacterAdded:Connect(function()
    if Settings.Fly then
        Settings.Fly = false
    end
end)

-- 退出遊戲時確保所有框框與血條都被清乾淨，防止記憶體外洩
Players.PlayerRemoving:Connect(function(plr)
    if ESP_Drawings[plr] then 
        ESP_Drawings[plr].Box:Remove() 
        -- ⚡ 幫你修復的隱藏 Bug：原本這裡寫成 p，導致別人退遊戲時可能會報錯閃退
        ESP_Drawings[plr].HealthBg:Remove()
        ESP_Drawings[plr].HealthBar:Remove()
        ESP_Drawings[plr] = nil 
    end
    if LockedTarget and LockedTarget.Name == plr.Name then LockedTarget = nil end
end)
