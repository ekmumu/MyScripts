-- ==========================================
-- MUMU PRO (V39) - 隊友判斷極簡化 (解除全場誤判封印)
-- ==========================================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- [[ 0. 核心防禦：全局清理系統 ]]
if _G.MUMU_PRO_CONNECTION then 
    _G.MUMU_PRO_CONNECTION:Disconnect() 
end

if _G.MUMU_ESP_DRAWINGS then
    for _, drawings in pairs(_G.MUMU_ESP_DRAWINGS) do
        for _, obj in pairs(drawings) do 
            pcall(function() 
                obj:Remove() 
            end) 
        end
    end
end
_G.MUMU_ESP_DRAWINGS = {}

local Settings = {
    ESP = true,
    Aimbot = true,        
    TriggerBot = false,   
    TriggerRadius = 15,   
    AutoFire_ADS = false, 
    AutoFire_Hip = false, 
    TeamCheck = true,  
    WallCheck = true,  
    Fly = false,       
    Noclip = false,    
    FlySpeed = 100,    
    Prediction = 0.12, 
    FOV = 250,         
    MaxDistance = 350,
    AimbotSens = 0.5   
}

-- [[ 1. UI 介面建立 ]]
local SafeGui = (gethui and gethui()) or game:GetService("CoreGui")
if SafeGui:FindFirstChild("MUMU_PHYSICS_LOCK") then 
    SafeGui.MUMU_PHYSICS_LOCK:Destroy() 
end

local ScreenGui = Instance.new("ScreenGui", SafeGui)
ScreenGui.Name = "MUMU_PHYSICS_LOCK"
ScreenGui.ResetOnSpawn = false

local Main = Instance.new("Frame", ScreenGui)
Main.Size = UDim2.fromOffset(340, 680) 
Main.Position = UDim2.fromScale(0.5, 0.5)
Main.AnchorPoint = Vector2.new(0.5, 0.5)
Main.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 10)

local stroke = Instance.new("UIStroke", Main)
stroke.Thickness = 3
stroke.Color = Color3.fromRGB(255, 0, 0)

local Title = Instance.new("TextLabel", Main)
Title.Size = UDim2.new(1, 0, 0, 60)
Title.Text = "⚡ MUMU PRO"
Title.TextSize = 28
Title.Font = Enum.Font.GothamBlack
Title.TextColor3 = Color3.new(1, 1, 1)
Title.BackgroundTransparency = 1

local Container = Instance.new("ScrollingFrame", Main)
Container.Size = UDim2.new(0.9, 0, 1, -100)
Container.Position = UDim2.fromScale(0.05, 0.12)
Container.BackgroundTransparency = 1
Container.ScrollBarThickness = 2
Container.CanvasSize = UDim2.new(0, 0, 2.1, 0) 

local Layout = Instance.new("UIListLayout", Container)
Layout.Padding = UDim.new(0, 8)

local function AddToggle(name, settingKey, customCallback)
    local btn = Instance.new("TextButton", Container)
    btn.Size = UDim2.new(1, -10, 0, 45)
    
    if Settings[settingKey] then
        btn.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
        btn.Text = name .. ": ON"
    else
        btn.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
        btn.Text = name .. ": OFF"
    end
    
    btn.TextSize = 15
    btn.Font = Enum.Font.GothamBold
    btn.TextColor3 = Color3.new(1, 1, 1)
    Instance.new("UICorner", btn)
    
    btn.MouseButton1Click:Connect(function() 
        Settings[settingKey] = not Settings[settingKey]
        
        if Settings[settingKey] then
            btn.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
            btn.Text = name .. ": ON"
        else
            btn.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
            btn.Text = name .. ": OFF"
        end
        
        if customCallback then 
            customCallback(Settings[settingKey]) 
        end
    end)
end

local function AddAdjuster(name, settingKey, step, min, max)
    local frame = Instance.new("Frame", Container)
    frame.Size = UDim2.new(1, -10, 0, 45)
    frame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    Instance.new("UICorner", frame)
    
    local title = Instance.new("TextLabel", frame)
    title.Size = UDim2.new(0.55, 0, 1, 0)
    title.Position = UDim2.new(0.05, 0, 0, 0)
    title.Text = name
    title.TextColor3 = Color3.new(1, 1, 1)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 13
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.BackgroundTransparency = 1
    
    local valText = Instance.new("TextLabel", frame)
    valText.Size = UDim2.new(0.2, 0, 1, 0)
    valText.Position = UDim2.new(0.65, 0, 0, 0)
    valText.Text = tostring(Settings[settingKey])
    valText.TextColor3 = Color3.new(1, 1, 1)
    valText.Font = Enum.Font.GothamBold
    valText.TextSize = 14
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

-- [[ 2. 飛行與穿牆控制 ]]
local FlyBodyGyro, FlyBodyVelocity
local CONTROL = {F = 0, B = 0, L = 0, R = 0, UP = 0, DOWN = 0}

local function UpdateFlyState(state)
    local char = LocalPlayer.Character
    if not char then return end
    if not char:FindFirstChild("HumanoidRootPart") then return end
    
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
        
        if char:FindFirstChild("Humanoid") then 
            char.Humanoid.PlatformStand = true 
        end
    else
        if hrp:FindFirstChild("MUMU_GYRO") then 
            hrp.MUMU_GYRO:Destroy() 
        end
        
        if hrp:FindFirstChild("MUMU_VELOCITY") then 
            hrp.MUMU_VELOCITY:Destroy() 
        end
        
        if char:FindFirstChild("Humanoid") then 
            char.Humanoid.PlatformStand = false 
        end
    end
end

local function UpdateNoclipState(state)
    if not state then
        if LocalPlayer.Character then
            for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
                if part:IsA("BasePart") then 
                    part.CanCollide = true 
                end
            end
        end
    end
end

-- UI 生成
AddToggle("方框與血條 (ESP)", "ESP")
AddToggle("實體滑鼠鎖頭 (右鍵瞄準)", "Aimbot") 
AddToggle("純扳機 (指到敵人自動開火)", "TriggerBot") 
AddToggle("自動鎖頭+開火 (開鏡時)", "AutoFire_ADS") 
AddToggle("暴力鎖頭+開火 (不開鏡)", "AutoFire_Hip") 
AddToggle("不瞄隊友 (Team)", "TeamCheck")
AddToggle("隔牆不瞄 (Wall)", "WallCheck")
AddToggle("飛行模式常駐 (Fly)", "Fly", UpdateFlyState)     
AddToggle("穿牆模式 (Noclip)", "Noclip", UpdateNoclipState) 

AddAdjuster("鎖頭推力 (太抖請調低)", "AimbotSens", 0.1, 0.1, 2.0)
AddAdjuster("扳機判定範圍", "TriggerRadius", 5, 5, 100)
AddAdjuster("飛行速度", "FlySpeed", 20, 20, 300)
AddAdjuster("FOV 鎖定範圍", "FOV", 25, 50, 800)

local Hint = Instance.new("TextLabel", Main)
Hint.Size = UDim2.new(1, 0, 0, 25)
Hint.Position = UDim2.new(0, 0, 1, -25)
Hint.Text = "按 [J] 顯示/隱藏面板"
Hint.TextColor3 = Color3.fromRGB(150, 150, 150)
Hint.TextSize = 13
Hint.Font = Enum.Font.Gotham
Hint.BackgroundTransparency = 1

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if not gameProcessed then
        if input.KeyCode == Enum.KeyCode.J then 
            Main.Visible = not Main.Visible 
        end
        
        local k = input.KeyCode
        if k == Enum.KeyCode.W then 
            CONTROL.F = 1 
        elseif k == Enum.KeyCode.S then 
            CONTROL.B = -1 
        elseif k == Enum.KeyCode.A then 
            CONTROL.L = -1 
        elseif k == Enum.KeyCode.D then 
            CONTROL.R = 1 
        elseif k == Enum.KeyCode.Space then 
            CONTROL.UP = 1 
        elseif k == Enum.KeyCode.LeftControl then 
            CONTROL.DOWN = -1 
        end
    end
end)

UserInputService.InputEnded:Connect(function(input, gameProcessed)
    local k = input.KeyCode
    if k == Enum.KeyCode.W then 
        CONTROL.F = 0 
    elseif k == Enum.KeyCode.S then 
        CONTROL.B = 0 
    elseif k == Enum.KeyCode.A then 
        CONTROL.L = 0 
    elseif k == Enum.KeyCode.D then 
        CONTROL.R = 0 
    elseif k == Enum.KeyCode.Space then 
        CONTROL.UP = 0 
    elseif k == Enum.KeyCode.LeftControl then 
        CONTROL.DOWN = 0 
    end
end)

local function IsVisible(targetChar)
    if not Settings.WallCheck then 
        return true 
    end
    
    if not LocalPlayer.Character then 
        return true 
    end
    
    if not LocalPlayer.Character:FindFirstChild("Head") then 
        return true 
    end
    
    local origin = Camera.CFrame.Position
    local targetPos = targetChar.Head.Position
    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    rayParams.FilterDescendantsInstances = {LocalPlayer.Character, Camera}
    rayParams.IgnoreWater = true
    
    local result = workspace:Raycast(origin, targetPos - origin, rayParams)
    
    if result then 
        if result.Instance:IsDescendantOf(targetChar) then 
            return true 
        else 
            return false 
        end 
    end
    
    return true
end

-- ⚡ 極簡版隊友判斷 (拔掉所有可能造成全場誤判的自定義掃描)
local function IsTeammate(p)
    if not Settings.TeamCheck then 
        return false 
    end
    
    if p == LocalPlayer then 
        return true 
    end
    
    -- 只檢查 Roblox 最官方、最基礎的 Team 屬性
    if p.Team ~= nil and LocalPlayer.Team ~= nil then
        if p.Team == LocalPlayer.Team then 
            return true 
        end
    end
    
    -- 不再去猜測其他隱藏屬性了，避免把所有人都當隊友
    return false
end

local function GetHealth(char)
    if not char then 
        return 0, 100 
    end
    
    local hp = 0
    local maxHp = 100
    
    local hum = char:FindFirstChild("Humanoid")
    if hum then
        hp = tonumber(hum.Health) or 0
        maxHp = tonumber(hum.MaxHealth) or 100
    end
    
    local customHealth = char:FindFirstChild("Health") or char:FindFirstChild("HP")
    if customHealth then
        if customHealth:IsA("NumberValue") or customHealth:IsA("IntValue") then 
            hp = tonumber(customHealth.Value) or hp 
        end
    end
    
    local customMaxHealth = char:FindFirstChild("MaxHealth") or char:FindFirstChild("MaxHP")
    if customMaxHealth then
        if customMaxHealth:IsA("NumberValue") or customMaxHealth:IsA("IntValue") then 
            maxHp = tonumber(customMaxHealth.Value) or maxHp 
        end
    end
    
    if maxHp <= 0 then 
        maxHp = 100 
    end
    
    return hp, maxHp
end

RunService.Stepped:Connect(function()
    if Settings.Noclip then
        if LocalPlayer.Character then
            for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
                if part:IsA("BasePart") then
                    if part.CanCollide then 
                        part.CanCollide = false 
                    end
                end
            end
        end
    end
end)

local function UpdateESP()
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            if not _G.MUMU_ESP_DRAWINGS[p] then
                _G.MUMU_ESP_DRAWINGS[p] = { 
                    Box = Drawing.new("Square"), 
                    HealthBg = Drawing.new("Line"), 
                    HealthBar = Drawing.new("Line") 
                }
                _G.MUMU_ESP_DRAWINGS[p].Box.Color = Color3.fromRGB(255, 50, 50)
                _G.MUMU_ESP_DRAWINGS[p].Box.Thickness = 1.5
                _G.MUMU_ESP_DRAWINGS[p].Box.Filled = false
                
                _G.MUMU_ESP_DRAWINGS[p].HealthBg.Color = Color3.fromRGB(0, 0, 0)
                _G.MUMU_ESP_DRAWINGS[p].HealthBg.Thickness = 4
                
                _G.MUMU_ESP_DRAWINGS[p].HealthBar.Thickness = 2
            end

            local drawings = _G.MUMU_ESP_DRAWINGS[p]
            local success, err = pcall(function()
                local hp, maxHp = GetHealth(p.Character)
                
                if Settings.ESP and p.Character and p.Character:FindFirstChild("HumanoidRootPart") and hp > 0 then
                    
                    if IsTeammate(p) then 
                        drawings.Box.Visible = false
                        drawings.HealthBg.Visible = false
                        drawings.HealthBar.Visible = false 
                        return 
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
                            
                            drawings.Box.Size = Vector2.new(width, height)
                            drawings.Box.Position = Vector2.new(centerPos.X - width/2, topPos.Y)
                            drawings.Box.Visible = true
                            
                            local healthPercent = math.clamp(hp / maxHp, 0, 1)
                            if healthPercent ~= healthPercent then 
                                healthPercent = 1 
                            end
                            
                            local barX = centerPos.X - width/2 - 6
                            
                            drawings.HealthBg.From = Vector2.new(barX, bottomPos.Y)
                            drawings.HealthBg.To = Vector2.new(barX, topPos.Y)
                            drawings.HealthBg.Visible = true
                            
                            local barHeight = height * healthPercent
                            drawings.HealthBar.From = Vector2.new(barX, bottomPos.Y)
                            drawings.HealthBar.To = Vector2.new(barX, bottomPos.Y - barHeight)
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
            end)
            
            if not success then 
                drawings.Box.Visible = false
                drawings.HealthBg.Visible = false
                drawings.HealthBar.Visible = false 
            end
        end
    end
end

local LockedTarget = nil 
local lastRapidFire = 0

local function FireWeapon()
    if mouse1click then 
        pcall(function() 
            mouse1click() 
        end) 
    else
        local center = Camera.ViewportSize / 2
        task.spawn(function()
            VirtualInputManager:SendMouseButtonEvent(center.X, center.Y, 0, true, game, 1)
            task.wait(0.01)
            VirtualInputManager:SendMouseButtonEvent(center.X, center.Y, 0, false, game, 1)
        end)
    end
end

local function FindNewTarget()
    local target = nil
    local maxDist = Settings.FOV
    local screenCenter = Camera.ViewportSize / 2 
    
    for _, p in pairs(Players:GetPlayers()) do
        local hp, _ = GetHealth(p.Character)
        
        if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("Head") and p.Character:FindFirstChild("HumanoidRootPart") and hp > 0 then
            
            if not IsTeammate(p) then
                local distToPlayer = (Camera.CFrame.Position - p.Character.HumanoidRootPart.Position).Magnitude
                if distToPlayer <= Settings.MaxDistance then
                    if IsVisible(p.Character) then
                        local pos, onScreen = Camera:WorldToViewportPoint(p.Character.Head.Position)
                        if onScreen then
                            local dist = (Vector2.new(pos.X, pos.Y) - screenCenter).Magnitude
                            if dist < maxDist then 
                                maxDist = dist
                                target = p.Character 
                            end
                        end
                    end
                end
            end
        end
    end
    return target
end

-- [[ 4. 戰鬥核心引擎 ]]
_G.MUMU_PRO_CONNECTION = RunService.RenderStepped:Connect(function()
    UpdateESP()

    if Settings.Fly then
        if LocalPlayer.Character then
            if LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
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
                    
                    if moveDir.Magnitude > 0 then 
                        vel.velocity = moveDir.Unit * Settings.FlySpeed 
                    else 
                        vel.velocity = Vector3.new(0, 0, 0) 
                    end
                end
            end
        end
    end

    local isRightClicking = UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
    
    if Settings.Aimbot or Settings.AutoFire_Hip or Settings.AutoFire_ADS or Settings.TriggerBot then
        if not LockedTarget then 
            LockedTarget = FindNewTarget() 
        end

        local hp, _ = GetHealth(LockedTarget)
        
        if LockedTarget and LockedTarget:FindFirstChild("Head") and LockedTarget:FindFirstChild("HumanoidRootPart") and hp > 0 then
            
            local distFromTarget = (Camera.CFrame.Position - LockedTarget.HumanoidRootPart.Position).Magnitude
            
            if distFromTarget > Settings.MaxDistance or not IsVisible(LockedTarget) then 
                LockedTarget = nil
                return 
            end

            local headPos = LockedTarget.Head.Position + (LockedTarget.HumanoidRootPart.Velocity * Settings.Prediction)
            local screenPos, onScreen = Camera:WorldToViewportPoint(headPos)
            
            if onScreen then
                local screenCenter = Camera.ViewportSize / 2
                local deltaX = screenPos.X - screenCenter.X
                local deltaY = screenPos.Y - screenCenter.Y
                local distToCenter = math.sqrt(deltaX^2 + deltaY^2)

                local shouldAim = false
                if Settings.Aimbot and isRightClicking then 
                    shouldAim = true 
                end
                
                if Settings.AutoFire_ADS and isRightClicking then 
                    shouldAim = true 
                end
                
                if Settings.AutoFire_Hip then 
                    shouldAim = true 
                end 

                if shouldAim then
                    if mousemoverel then 
                        mousemoverel(deltaX * Settings.AimbotSens, deltaY * Settings.AimbotSens) 
                    end
                end

                local shouldFire = false
                if Settings.AutoFire_ADS and isRightClicking then 
                    shouldFire = true 
                end
                
                if Settings.AutoFire_Hip then 
                    shouldFire = true 
                end
                
                if Settings.TriggerBot and distToCenter <= Settings.TriggerRadius then 
                    shouldFire = true 
                end

                if shouldFire then
                    if tick() - lastRapidFire > 0.05 then
                        FireWeapon()
                        lastRapidFire = tick()
                    end
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

LocalPlayer.CharacterAdded:Connect(function(newChar)
    task.delay(0.5, function() 
        if Settings.Fly then
            if newChar:FindFirstChild("HumanoidRootPart") then 
                UpdateFlyState(true) 
            end
        end
    end)
end)

Players.PlayerRemoving:Connect(function(plr)
    if _G.MUMU_ESP_DRAWINGS then
        if _G.MUMU_ESP_DRAWINGS[plr] then 
            _G.MUMU_ESP_DRAWINGS[plr].Box:Remove()
            _G.MUMU_ESP_DRAWINGS[plr].HealthBg:Remove()
            _G.MUMU_ESP_DRAWINGS[plr].HealthBar:Remove()
            _G.MUMU_ESP_DRAWINGS[plr] = nil 
        end
    end
    
    if LockedTarget then
        if LockedTarget.Name == plr.Name then 
            LockedTarget = nil
        end
    end
end)
