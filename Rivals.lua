-- ==========================================
-- MUMU RIVALS - 物理硬鎖 + 飛行常駐 + 破壞死區 + 真實開火
-- ==========================================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

local Settings = {
    ESP = true,
    Aimbot = true,
    AutoFire = false,  
    TeamCheck = true,  
    WallCheck = true,  
    Fly = false,       
    Noclip = false,    
    AntiKill = false,  -- ⚡ 新增：破壞場外死亡磚塊
    FlySpeed = 100,    
    Prediction = 0.12, 
    FOV = 250,         
    MaxDistance = 350,
    Smoothness = 1,    
    AimbotSens = 1.5   
}

local SafeGui = (gethui and gethui()) or game:GetService("CoreGui")
if SafeGui:FindFirstChild("MUMU_PHYSICS_LOCK") then
    SafeGui.MUMU_PHYSICS_LOCK:Destroy()
end

local ScreenGui = Instance.new("ScreenGui", SafeGui)
ScreenGui.Name = "MUMU_PHYSICS_LOCK"
ScreenGui.ResetOnSpawn = false

local Main = Instance.new("Frame", ScreenGui)
Main.Size = UDim2.fromOffset(320, 620) 
Main.Position = UDim2.fromScale(0.5, 0.5) 
Main.AnchorPoint = Vector2.new(0.5, 0.5)  
Main.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 10)
Instance.new("UIStroke", Main).Thickness = 3
Instance.new("UIStroke", Main).Color = Color3.fromRGB(255, 0, 0)

local Title = Instance.new("TextLabel", Main)
Title.Size = UDim2.new(1, 0, 0, 60)
Title.Text = "⚡ MUMU CORE"
Title.TextSize = 28
Title.Font = Enum.Font.GothamBlack
Title.TextColor3 = Color3.new(1, 1, 1)
Title.BackgroundTransparency = 1

local Container = Instance.new("ScrollingFrame", Main)
Container.Size = UDim2.new(0.9, 0, 1, -100)
Container.Position = UDim2.fromScale(0.05, 0.12)
Container.BackgroundTransparency = 1
Container.ScrollBarThickness = 2
Container.CanvasSize = UDim2.new(0, 0, 2, 0) 
local Layout = Instance.new("UIListLayout", Container)
Layout.Padding = UDim.new(0, 8)

-- [ 按鈕生成器 ]
local function AddToggle(name, settingKey, customCallback)
    local btn = Instance.new("TextButton", Container)
    btn.Size = UDim2.new(1, -10, 0, 45)
    btn.BackgroundColor3 = Settings[settingKey] and Color3.fromRGB(200, 0, 0) or Color3.fromRGB(45, 45, 45)
    btn.Text = name .. ": " .. (Settings[settingKey] and "ON" or "OFF")
    btn.TextSize = 18
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

-- [ 數值微調器 ]
local function AddAdjuster(name, settingKey, step, min, max)
    local frame = Instance.new("Frame", Container)
    frame.Size = UDim2.new(1, -10, 0, 45)
    frame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    Instance.new("UICorner", frame)

    local title = Instance.new("TextLabel", frame)
    title.Size = UDim2.new(0.5, 0, 1, 0)
    title.Position = UDim2.new(0.05, 0, 0, 0)
    title.Text = name
    title.TextColor3 = Color3.new(1, 1, 1)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 16
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.BackgroundTransparency = 1

    local valText = Instance.new("TextLabel", frame)
    valText.Size = UDim2.new(0.2, 0, 1, 0)
    valText.Position = UDim2.new(0.65, 0, 0, 0)
    valText.Text = tostring(Settings[settingKey])
    valText.TextColor3 = Color3.new(1, 1, 1)
    valText.Font = Enum.Font.GothamBold
    valText.TextSize = 16
    valText.BackgroundTransparency = 1

    local btnMinus = Instance.new("TextButton", frame)
    btnMinus.Size = UDim2.new(0, 30, 0, 30)
    btnMinus.Position = UDim2.new(0.55, 0, 0.5, -15)
    btnMinus.BackgroundColor3 = Color3.fromRGB(80, 20, 20)
    btnMinus.Text = "-"
    btnMinus.TextColor3 = Color3.new(1, 1, 1)
    btnMinus.Font = Enum.Font.GothamBold
    btnMinus.TextSize = 20
    Instance.new("UICorner", btnMinus)

    local btnPlus = Instance.new("TextButton", frame)
    btnPlus.Size = UDim2.new(0, 30, 0, 30)
    btnPlus.Position = UDim2.new(0.85, 0, 0.5, -15)
    btnPlus.BackgroundColor3 = Color3.fromRGB(20, 80, 20)
    btnPlus.Text = "+"
    btnPlus.TextColor3 = Color3.new(1, 1, 1)
    btnPlus.Font = Enum.Font.GothamBold
    btnPlus.TextSize = 20
    Instance.new("UICorner", btnPlus)

    btnMinus.MouseButton1Click:Connect(function()
        if Settings[settingKey] - step >= min then
            Settings[settingKey] = Settings[settingKey] - step
            valText.Text = tostring(Settings[settingKey])
        end
    end)
    btnPlus.MouseButton1Click:Connect(function()
        if Settings[settingKey] + step <= max then
            Settings[settingKey] = Settings[settingKey] + step
            valText.Text = tostring(Settings[settingKey])
        end
    end)
end

-- [[ 飛行系統控制 ]]
local FlyBodyGyro, FlyBodyVelocity
local CONTROL = {F = 0, B = 0, L = 0, R = 0, UP = 0, DOWN = 0}

local function UpdateFlyState(state)
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") or not char:FindFirstChild("Humanoid") then return end
    local hrp = char.HumanoidRootPart

    if state then
        if not hrp:FindFirstChild("MUMU_GYRO") then
            FlyBodyGyro = Instance.new("BodyGyro", hrp)
            FlyBodyGyro.Name = "MUMU_GYRO"
            FlyBodyGyro.P = 9e4
            FlyBodyGyro.maxTorque = Vector3.new(9e9, 9e9, 9e9)
            FlyBodyGyro.cframe = hrp.CFrame
        end
        if not hrp:FindFirstChild("MUMU_VELOCITY") then
            FlyBodyVelocity = Instance.new("BodyVelocity", hrp)
            FlyBodyVelocity.Name = "MUMU_VELOCITY"
            FlyBodyVelocity.velocity = Vector3.new(0, 0, 0)
            FlyBodyVelocity.maxForce = Vector3.new(9e9, 9e9, 9e9)
        end
        char.Humanoid.PlatformStand = true 
    else
        if hrp:FindFirstChild("MUMU_GYRO") then hrp.MUMU_GYRO:Destroy() end
        if hrp:FindFirstChild("MUMU_VELOCITY") then hrp.MUMU_VELOCITY:Destroy() end
        char.Humanoid.PlatformStand = false
    end
end

-- ⚡ 破壞死區函數 (Anti-KillBrick)
local function DestroyKillBricks(state)
    if state then
        for _, v in pairs(workspace:GetDescendants()) do
            -- 如果這是一個碰觸觸發器，且父零件是隱形的，拔掉它防暴斃
            if v:IsA("TouchTransmitter") and v.Parent and v.Parent:IsA("BasePart") then
                if v.Parent.Transparency == 1 or v.Parent.Name:lower():match("kill") then
                    v:Destroy()
                end
            end
        end
    end
end

-- ⚡ UI 生成
AddToggle("方框與血條 (ESP)", "ESP")
AddToggle("物理硬鎖 (右鍵)", "Aimbot")
AddToggle("自動開火 (真實點擊)", "AutoFire") 
AddToggle("不瞄隊友 (Team)", "TeamCheck")
AddToggle("隔牆不瞄 (Wall)", "WallCheck")
AddToggle("飛行模式常駐 (Fly)", "Fly", UpdateFlyState) 
AddToggle("穿牆模式 (Noclip)", "Noclip")           
AddToggle("破壞場外死區 (Anti-Kill)", "AntiKill", DestroyKillBricks) -- ⚡ 點下去就幫你拔除空氣牆死亡判定

AddAdjuster("飛行速度", "FlySpeed", 20, 20, 300)
AddAdjuster("鎖頭推力", "AimbotSens", 0.5, 0.5, 5.0)
AddAdjuster("FOV 範圍", "FOV", 25, 50, 800)

local Hint = Instance.new("TextLabel", Main)
Hint.Size = UDim2.new(1, 0, 0, 25)
Hint.Position = UDim2.new(0, 0, 1, -25)
Hint.Text = "按 [J] 顯示/隱藏面板"
Hint.TextColor3 = Color3.fromRGB(150, 150, 150)
Hint.TextSize = 13
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
    if result then if result.Instance:IsDescendantOf(targetChar) then return true else return false end end
    return true
end

local function IsTeammate(p)
    if not Settings.TeamCheck then return false end
    if p.Team ~= nil and LocalPlayer.Team ~= nil then return p.Team == LocalPlayer.Team end
    return false
end

-- [[ 4. 穿牆系統 ]]
RunService.Stepped:Connect(function()
    if Settings.Noclip and LocalPlayer.Character then
        for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
            if part:IsA("BasePart") and part.CanCollide then part.CanCollide = false end
        end
    end
end)

-- [[ 5. ESP ]]
local ESP_Drawings = {}
local function UpdateESP()
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            if not ESP_Drawings[p] then
                ESP_Drawings[p] = { Box = Drawing.new("Square"), HealthBg = Drawing.new("Square"), HealthBar = Drawing.new("Square") }
                ESP_Drawings[p].Box.Color = Color3.fromRGB(255, 50, 50); ESP_Drawings[p].Box.Thickness = 1.5; ESP_Drawings[p].Box.Filled = false
                ESP_Drawings[p].HealthBg.Color = Color3.fromRGB(0, 0, 0); ESP_Drawings[p].HealthBg.Thickness = 1; ESP_Drawings[p].HealthBg.Filled = true
                ESP_Drawings[p].HealthBar.Thickness = 1; ESP_Drawings[p].HealthBar.Filled = true
            end

            local drawings = ESP_Drawings[p]
            if Settings.ESP and p.Character and p.Character:FindFirstChild("HumanoidRootPart") and p.Character:FindFirstChild("Humanoid") and p.Character.Humanoid.Health > 0 then
                if IsTeammate(p) then drawings.Box.Visible = false; drawings.HealthBg.Visible = false; drawings.HealthBar.Visible = false continue end
                local hrp = p.Character.HumanoidRootPart
                local dist = (Camera.CFrame.Position - hrp.Position).Magnitude
                if dist < Settings.MaxDistance then
                    local topPos, onScreen = Camera:WorldToViewportPoint(hrp.Position + Vector3.new(0, 2.5, 0))
                    local bottomPos = Camera:WorldToViewportPoint(hrp.Position - Vector3.new(0, 3, 0))
                    local centerPos = Camera:WorldToViewportPoint(hrp.Position)
                    if onScreen then
                        local height = math.abs(topPos.Y - bottomPos.Y)
                        local width = height * 0.6
                        drawings.Box.Size = Vector2.new(width, height); drawings.Box.Position = Vector2.new(centerPos.X - width/2, topPos.Y); drawings.Box.Visible = true
                        local health = p.Character.Humanoid.Health; local maxHealth = p.Character.Humanoid.MaxHealth; local healthPercent = math.clamp(health / maxHealth, 0, 1)
                        drawings.HealthBg.Size = Vector2.new(4, height); drawings.HealthBg.Position = Vector2.new(centerPos.X - width/2 - 6, topPos.Y); drawings.HealthBg.Visible = true
                        local barHeight = height * healthPercent
                        drawings.HealthBar.Size = Vector2.new(2, barHeight); drawings.HealthBar.Position = Vector2.new(centerPos.X - width/2 - 5, topPos.Y + (height - barHeight)); drawings.HealthBar.Color = Color3.fromHSV(healthPercent * 0.3, 1, 1); drawings.HealthBar.Visible = true
                    else drawings.Box.Visible = false; drawings.HealthBg.Visible = false; drawings.HealthBar.Visible = false end
                else drawings.Box.Visible = false; drawings.HealthBg.Visible = false; drawings.HealthBar.Visible = false end
            else drawings.Box.Visible = false; drawings.HealthBg.Visible = false; drawings.HealthBar.Visible = false end
        end
    end
end

-- [[ 6. 核心：物理模擬 + 安全開火 + 飛行 ]]
local LockedTarget = nil 
local isAutoFiring = false

-- ⚡ 安全保護的滑鼠點擊函數
local function SafePress()
    if mouse1press then pcall(function() mouse1press() end) end
end

local function SafeRelease()
    if mouse1release then pcall(function() mouse1release() end) end
end

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

    if Settings.Fly and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        local hrp = LocalPlayer.Character.HumanoidRootPart
        local gyro = hrp:FindFirstChild("MUMU_GYRO")
        local vel = hrp:FindFirstChild("MUMU_VELOCITY")
        
        if gyro and vel then
            local camCF = Camera.CFrame
            gyro.cframe = camCF 
            local moveDir = Vector3.new(0, 0, 0)
            moveDir = moveDir + camCF.LookVector * (CONTROL.F + CONTROL.B)
            moveDir = moveDir + camCF.RightVector * (CONTROL.L + CONTROL.R)
            moveDir = moveDir + camCF.UpVector * (CONTROL.UP + CONTROL.DOWN)
            if moveDir.Magnitude > 0 then vel.velocity = moveDir.Unit * Settings.FlySpeed else vel.velocity = Vector3.new(0, 0, 0) end
        end
    end

    if Settings.Aimbot and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
        if not LockedTarget then LockedTarget = FindNewTarget() end

        if LockedTarget and LockedTarget:FindFirstChild("Head") and LockedTarget:FindFirstChild("Humanoid") and LockedTarget.Humanoid.Health > 0 then
            if (Camera.CFrame.Position - LockedTarget.HumanoidRootPart.Position).Magnitude > Settings.MaxDistance or not IsVisible(LockedTarget) then 
                LockedTarget = nil 
                if isAutoFiring then isAutoFiring = false SafeRelease() end
                return 
            end

            local headPos = LockedTarget.Head.Position + (LockedTarget.HumanoidRootPart.Velocity * Settings.Prediction)
            local screenPos, onScreen = Camera:WorldToViewportPoint(headPos)
            
            if onScreen then
                local mousePos = UserInputService:GetMouseLocation()
                
                -- ⚡ 真實模擬點擊
                if Settings.AutoFire then
                    local dist = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
                    if dist < 45 then 
                        if not isAutoFiring then
                            isAutoFiring = true
                            SafePress() 
                        end
                    else
                        if isAutoFiring then
                            isAutoFiring = false
                            SafeRelease() 
                        end
                    end
                end

                if mousemoverel then
                    local moveX = (screenPos.X - mousePos.X) * Settings.Smoothness * Settings.AimbotSens
                    local moveY = (screenPos.Y - mousePos.Y) * Settings.Smoothness * Settings.AimbotSens
                    mousemoverel(moveX, moveY)
                else
                    Camera.CFrame = CFrame.lookAt(Camera.CFrame.Position, headPos)
                end
            else 
                LockedTarget = nil 
                if isAutoFiring then isAutoFiring = false SafeRelease() end
            end
        else 
            LockedTarget = nil 
            if isAutoFiring then isAutoFiring = false SafeRelease() end
        end
    else 
        LockedTarget = nil 
        if isAutoFiring then isAutoFiring = false SafeRelease() end
    end
end)

-- ⚡ 重生後自動續傳飛行狀態
LocalPlayer.CharacterAdded:Connect(function(newChar)
    if isAutoFiring then isAutoFiring = false SafeRelease() end
    
    -- 等待身體載入後，如果飛行開關是開的，就幫你重新掛上飛行引擎
    task.delay(0.5, function()
        if Settings.Fly and newChar:FindFirstChild("HumanoidRootPart") then
            UpdateFlyState(true)
        end
        if Settings.AntiKill then
            DestroyKillBricks(true)
        end
    end)
end)

Players.PlayerRemoving:Connect(function(plr)
    if ESP_Drawings[plr] then 
        ESP_Drawings[plr].Box:Remove() 
        ESP_Drawings[plr].HealthBg:Remove()
        ESP_Drawings[plr].HealthBar:Remove()
        ESP_Drawings[plr] = nil 
    end
    if LockedTarget and LockedTarget.Name == plr.Name then 
        LockedTarget = nil 
        if isAutoFiring then isAutoFiring = false SafeRelease() end
    end
end)
