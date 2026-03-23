-- ==========================================
-- MUMU PRO (V26) - 全局防崩潰清理 + 絕對視角同步 + 雙模式真實開火
-- ==========================================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- [[ 0. 核心防禦：全局清理系統 (防止重複執行導致互相打架) ]]
if _G.MUMU_PRO_CONNECTION then _G.MUMU_PRO_CONNECTION:Disconnect() end
if _G.MUMU_ESP_DRAWINGS then
    for _, drawings in pairs(_G.MUMU_ESP_DRAWINGS) do
        for _, obj in pairs(drawings) do pcall(function() obj:Remove() end) end
    end
end
_G.MUMU_ESP_DRAWINGS = {}

local Settings = {
    ESP = true,
    Aimbot = true,
    AutoFire_Hip = false, 
    AutoFire_ADS = false, 
    TeamCheck = true,  
    WallCheck = true,  
    Fly = false,       
    Noclip = false,    
    FlySpeed = 100,    
    Prediction = 0.12, 
    FOV = 250,         
    MaxDistance = 350
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
Main.Size = UDim2.fromOffset(320, 580) 
Main.Position = UDim2.fromScale(0.5, 0.5) 
Main.AnchorPoint = Vector2.new(0.5, 0.5)  
Main.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 10)
Instance.new("UIStroke", Main).Thickness = 3
Instance.new("UIStroke", Main).Color = Color3.fromRGB(255, 0, 0)

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
Container.CanvasSize = UDim2.new(0, 0, 1.8, 0) 
local Layout = Instance.new("UIListLayout", Container)
Layout.Padding = UDim.new(0, 8)

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
            Settings[settingKey] = Settings[settingKey] - step; valText.Text = tostring(Settings[settingKey])
        end
    end)
    btnPlus.MouseButton1Click:Connect(function()
        if Settings[settingKey] + step <= max then
            Settings[settingKey] = Settings[settingKey] + step; valText.Text = tostring(Settings[settingKey])
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
            FlyBodyGyro = Instance.new("BodyGyro", hrp); FlyBodyGyro.Name = "MUMU_GYRO"; FlyBodyGyro.P = 9e4; FlyBodyGyro.maxTorque = Vector3.new(9e9, 9e9, 9e9); FlyBodyGyro.cframe = hrp.CFrame
        end
        if not hrp:FindFirstChild("MUMU_VELOCITY") then
            FlyBodyVelocity = Instance.new("BodyVelocity", hrp); FlyBodyVelocity.Name = "MUMU_VELOCITY"; FlyBodyVelocity.velocity = Vector3.new(0, 0, 0); FlyBodyVelocity.maxForce = Vector3.new(9e9, 9e9, 9e9)
        end
        char.Humanoid.PlatformStand = true 
    else
        if hrp:FindFirstChild("MUMU_GYRO") then hrp.MUMU_GYRO:Destroy() end
        if hrp:FindFirstChild("MUMU_VELOCITY") then hrp.MUMU_VELOCITY:Destroy() end
        char.Humanoid.PlatformStand = false
    end
end

AddToggle("方框與血條 (ESP)", "ESP")
AddToggle("絕對鎖頭 (100% 視角)", "Aimbot")
AddToggle("鎖定後盲射 (不開鏡射擊)", "AutoFire_Hip") 
AddToggle("開鏡時射擊 (右鍵射擊)", "AutoFire_ADS") 
AddToggle("不瞄隊友 (Team)", "TeamCheck")
AddToggle("隔牆不瞄 (Wall)", "WallCheck")
AddToggle("飛行模式常駐 (Fly)", "Fly", UpdateFlyState) 
AddToggle("穿牆模式 (Noclip)", "Noclip")           

AddAdjuster("飛行速度", "FlySpeed", 20, 20, 300)
AddAdjuster("FOV 鎖定範圍", "FOV", 25, 50, 800)

local Hint = Instance.new("TextLabel", Main)
Hint.Size = UDim2.new(1, 0, 0, 25); Hint.Position = UDim2.new(0, 0, 1, -25)
Hint.Text = "按 [J] 顯示/隱藏面板"
Hint.TextColor3 = Color3.fromRGB(150, 150, 150); Hint.TextSize = 13; Hint.Font = Enum.Font.Gotham; Hint.BackgroundTransparency = 1

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if not gameProcessed and input.KeyCode == Enum.KeyCode.J then Main.Visible = not Main.Visible end
    if not gameProcessed then
        local k = input.KeyCode
        if k == Enum.KeyCode.W then CONTROL.F = 1 elseif k == Enum.KeyCode.S then CONTROL.B = -1 elseif k == Enum.KeyCode.A then CONTROL.L = -1 elseif k == Enum.KeyCode.D then CONTROL.R = 1 elseif k == Enum.KeyCode.Space then CONTROL.UP = 1 elseif k == Enum.KeyCode.LeftControl then CONTROL.DOWN = -1 end
    end
end)

UserInputService.InputEnded:Connect(function(input, gameProcessed)
    local k = input.KeyCode
    if k == Enum.KeyCode.W then CONTROL.F = 0 elseif k == Enum.KeyCode.S then CONTROL.B = 0 elseif k == Enum.KeyCode.A then CONTROL.L = 0 elseif k == Enum.KeyCode.D then CONTROL.R = 0 elseif k == Enum.KeyCode.Space then CONTROL.UP = 0 elseif k == Enum.KeyCode.LeftControl then CONTROL.DOWN = 0 end
end)

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

-- 穿牆線程獨立運作 (防崩潰)
RunService.Stepped:Connect(function()
    if Settings.Noclip and LocalPlayer.Character then
        for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
            if part:IsA("BasePart") and part.CanCollide then part.CanCollide = false end
        end
    end
end)

-- [[ 5. 堅若磐石的 ESP 系統 ]]
local function UpdateESP()
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            if not _G.MUMU_ESP_DRAWINGS[p] then
                _G.MUMU_ESP_DRAWINGS[p] = { Box = Drawing.new("Square"), HealthBg = Drawing.new("Square"), HealthBar = Drawing.new("Square") }
                _G.MUMU_ESP_DRAWINGS[p].Box.Color = Color3.fromRGB(255, 50, 50); _G.MUMU_ESP_DRAWINGS[p].Box.Thickness = 1.5; _G.MUMU_ESP_DRAWINGS[p].Box.Filled = false
                _G.MUMU_ESP_DRAWINGS[p].HealthBg.Color = Color3.fromRGB(0, 0, 0); _G.MUMU_ESP_DRAWINGS[p].HealthBg.Thickness = 1; _G.MUMU_ESP_DRAWINGS[p].HealthBg.Filled = true
                _G.MUMU_ESP_DRAWINGS[p].HealthBar.Thickness = 1; _G.MUMU_ESP_DRAWINGS[p].HealthBar.Filled = true
            end

            local drawings = _G.MUMU_ESP_DRAWINGS[p]
            -- ⚡ 增加 pcall 防止任何因為人物死掉產生的報錯
            local success, _ = pcall(function()
                if Settings.ESP and p.Character and p.Character:FindFirstChild("HumanoidRootPart") and p.Character:FindFirstChild("Humanoid") and p.Character.Humanoid.Health > 0 then
                    if IsTeammate(p) then drawings.Box.Visible = false; drawings.HealthBg.Visible = false; drawings.HealthBar.Visible = false return end
                    
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
                            
                            local health = p.Character.Humanoid.Health; 
                            local maxHealth = math.max(p.Character.Humanoid.MaxHealth, 1) -- ⚡ 防治 0 血量崩潰
                            local healthPercent = math.clamp(health / maxHealth, 0, 1)
                            
                            drawings.HealthBg.Size = Vector2.new(4, height); drawings.HealthBg.Position = Vector2.new(centerPos.X - width/2 - 6, topPos.Y); drawings.HealthBg.Visible = true
                            local barHeight = height * healthPercent
                            drawings.HealthBar.Size = Vector2.new(2, barHeight); drawings.HealthBar.Position = Vector2.new(centerPos.X - width/2 - 5, topPos.Y + (height - barHeight)); drawings.HealthBar.Color = Color3.fromHSV(healthPercent * 0.3, 1, 1); drawings.HealthBar.Visible = true
                        else drawings.Box.Visible = false; drawings.HealthBg.Visible = false; drawings.HealthBar.Visible = false end
                    else drawings.Box.Visible = false; drawings.HealthBg.Visible = false; drawings.HealthBar.Visible = false end
                else drawings.Box.Visible = false; drawings.HealthBg.Visible = false; drawings.HealthBar.Visible = false end
            end)
            if not success then drawings.Box.Visible = false; drawings.HealthBg.Visible = false; drawings.HealthBar.Visible = false end
        end
    end
end

local LockedTarget = nil 
local lastRapidFire = 0

-- ⚡ 終極光速連點 (徹底解決有鎖定卻不開火的問題)
local function FireWeapon()
    if mouse1click then 
        pcall(function() mouse1click() end) 
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

-- [[ 6. 核心引擎註冊到全局變量防干擾 ]]
_G.MUMU_PRO_CONNECTION = RunService.RenderStepped:Connect(function()
    UpdateESP()

    if Settings.Fly and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        local hrp = LocalPlayer.Character.HumanoidRootPart
        local gyro = hrp:FindFirstChild("MUMU_GYRO"); local vel = hrp:FindFirstChild("MUMU_VELOCITY")
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

    local isRightClicking = UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
    local shouldAimbot = (Settings.Aimbot and (isRightClicking or Settings.AutoFire_Hip))

    if shouldAimbot then
        if not LockedTarget then LockedTarget = FindNewTarget() end

        if LockedTarget and LockedTarget:FindFirstChild("Head") and LockedTarget:FindFirstChild("Humanoid") and LockedTarget.Humanoid.Health > 0 then
            if (Camera.CFrame.Position - LockedTarget.HumanoidRootPart.Position).Magnitude > Settings.MaxDistance or not IsVisible(LockedTarget) then 
                LockedTarget = nil; return 
            end

            local headPos = LockedTarget.Head.Position + (LockedTarget.HumanoidRootPart.Velocity * Settings.Prediction)
            local screenPos, onScreen = Camera:WorldToViewportPoint(headPos)
            
            if onScreen then
                -- ⚡ 1. 視角絕對鎖死 (保證螢幕中央對準頭部)
                Camera.CFrame = CFrame.lookAt(Camera.CFrame.Position, headPos)

                -- ⚡ 2. 引擎欺騙：強制觸發滑鼠位移信號，讓槍管同步轉過來
                if mousemoverel then
                    mousemoverel(1, 0); mousemoverel(-1, 0)
                end

                -- ⚡ 3. 判斷開火 (邏輯最簡化，有對準就扣板機)
                local shouldFire = false
                if Settings.AutoFire_ADS and isRightClicking then shouldFire = true
                elseif Settings.AutoFire_Hip and not isRightClicking then shouldFire = true end

                if shouldFire then
                    -- 限制最高射速 (0.05秒點一次，手槍/步槍皆適用)
                    if tick() - lastRapidFire > 0.05 then
                        FireWeapon()
                        lastRapidFire = tick()
                    end
                end
            else LockedTarget = nil end
        else LockedTarget = nil end
    else LockedTarget = nil end
end)

LocalPlayer.CharacterAdded:Connect(function(newChar)
    task.delay(0.5, function()
        if Settings.Fly and newChar:FindFirstChild("HumanoidRootPart") then UpdateFlyState(true) end
    end)
end)

Players.PlayerRemoving:Connect(function(plr)
    if _G.MUMU_ESP_DRAWINGS and _G.MUMU_ESP_DRAWINGS[plr] then 
        _G.MUMU_ESP_DRAWINGS[plr].Box:Remove() 
        _G.MUMU_ESP_DRAWINGS[plr].HealthBg:Remove()
        _G.MUMU_ESP_DRAWINGS[plr].HealthBar:Remove()
        _G.MUMU_ESP_DRAWINGS[plr] = nil 
    end
    if LockedTarget and LockedTarget.Name == plr.Name then LockedTarget = nil end
end)
