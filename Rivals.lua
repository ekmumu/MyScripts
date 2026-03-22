-- ==========================================
-- MUMU RIVALS - 物理跟槍 + 子彈轉彎 (Magic Bullet)
-- ==========================================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

local Settings = {
    ESP = true,
    Aimbot = true,       -- 物理死鎖 (右鍵)
    SilentAim = true,    -- ⚡ 子彈轉彎 (隨時吸附)
    TeamCheck = true,  
    WallCheck = true,  
    Prediction = 0.12, 
    FOV = 250,
    MaxDistance = 350,
    Smoothness = 1 
}

-- [[ 1. 絕對中心固定 UI ]]
local SafeGui = (gethui and gethui()) or game:GetService("CoreGui")
if SafeGui:FindFirstChild("MUMU_MAGIC") then
    SafeGui.MUMU_MAGIC:Destroy()
end

local ScreenGui = Instance.new("ScreenGui", SafeGui)
ScreenGui.Name = "MUMU_MAGIC"
ScreenGui.ResetOnSpawn = false

local Main = Instance.new("Frame", ScreenGui)
Main.Size = UDim2.fromOffset(300, 540) -- 加高以容納新按鈕
Main.Position = UDim2.fromScale(0.5, 0.5) 
Main.AnchorPoint = Vector2.new(0.5, 0.5)  
Main.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 10)
Instance.new("UIStroke", Main).Thickness = 3
Instance.new("UIStroke", Main).Color = Color3.fromRGB(255, 0, 0)

local Title = Instance.new("TextLabel", Main)
Title.Size = UDim2.new(1, 0, 0, 70)
Title.Text = "⚡ MUMU MAGIC"
Title.TextSize = 28
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
local function AddToggle(name, settingKey)
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
    end)
end

AddToggle("方框透視 (Box)", "ESP")
AddToggle("物理死鎖 (右鍵)", "Aimbot")
AddToggle("子彈轉彎 (Magic)", "SilentAim") -- ⚡ 新增開關
AddToggle("不瞄隊友 (Team)", "TeamCheck")
AddToggle("隔牆不瞄 (Wall)", "WallCheck")

local Hint = Instance.new("TextLabel", Main)
Hint.Size = UDim2.new(1, 0, 0, 30)
Hint.Position = UDim2.new(0, 0, 1, -40)
Hint.Text = "按 [J] 鍵顯示/隱藏"
Hint.TextColor3 = Color3.fromRGB(150, 150, 150)
Hint.TextSize = 16
Hint.Font = Enum.Font.Gotham
Hint.BackgroundTransparency = 1

-- [[ 2. J鍵開關 ]]
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if not gameProcessed and input.KeyCode == Enum.KeyCode.J then
        Main.Visible = not Main.Visible
    end
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

-- [[ 4. 尋找目標核心 ]]
local LockedTarget = nil     -- 給右鍵死鎖用的
local SilentAimTarget = nil  -- 給子彈轉彎用的 (隨時更新)

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

-- [[ 5. ⚡ 核心：子彈轉彎攔截 (Hook) ]]
local oldNamecall
oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
    local method = getnamecallmethod()
    
    -- 攔截遊戲發射出的 Raycast (射線)
    if Settings.SilentAim and method == "Raycast" and not checkcaller() then
        -- 如果有抓到目標，就把子彈強行彎過去
        if SilentAimTarget and SilentAimTarget:FindFirstChild("Head") and SilentAimTarget:FindFirstChild("HumanoidRootPart") then
            local args = {...}
            local origin = args[1]
            local originalDirection = args[2]
            
            -- 計算目標頭部的精準預判位置
            local headPos = SilentAimTarget.Head.Position + (SilentAimTarget.HumanoidRootPart.Velocity * Settings.Prediction)
            
            -- 修改子彈方向：從槍口指向敵人的頭部，保持原本的射程長度
            local newDirection = (headPos - origin).Unit * originalDirection.Magnitude
            args[2] = newDirection
            
            return oldNamecall(self, unpack(args))
        end
    end
    return oldNamecall(self, ...)
end)

-- [[ 6. 每幀更新邏輯 ]]
local ESP_Boxes = {}
RunService.RenderStepped:Connect(function()
    -- 1. 更新 ESP
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
            if Settings.ESP and p.Character and p.Character:FindFirstChild("HumanoidRootPart") and p.Character:FindFirstChild("Head") and p.Character:FindFirstChild("Humanoid") and p.Character.Humanoid.Health > 0 then
                if IsTeammate(p) then box.Visible = false continue end
                if (Camera.CFrame.Position - p.Character.HumanoidRootPart.Position).Magnitude < Settings.MaxDistance then
                    local topPos, onScreen = Camera:WorldToViewportPoint(p.Character.Head.Position + Vector3.new(0, 0.5, 0))
                    local bottomPos = Camera:WorldToViewportPoint(p.Character.HumanoidRootPart.Position - Vector3.new(0, 3.5, 0))
                    if onScreen then
                        local height = math.abs(topPos.Y - bottomPos.Y)
                        local width = height * 0.6
                        box.Size = Vector2.new(width, height)
                        box.Position = Vector2.new(topPos.X - width/2, topPos.Y)
                        box.Visible = true
                    else box.Visible = false end
                else box.Visible = false end
            else box.Visible = false end
        end
    end

    -- 2. 每幀更新子彈轉彎的目標 (不用按右鍵也能吸附)
    if Settings.SilentAim then
        SilentAimTarget = FindNewTarget()
    else
        SilentAimTarget = nil
    end

    -- 3. 物理死鎖 (右鍵)
    if Settings.Aimbot and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
        if not LockedTarget then LockedTarget = FindNewTarget() end

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
            else LockedTarget = nil end
        else LockedTarget = nil end
    else LockedTarget = nil end
end)

Players.PlayerRemoving:Connect(function(plr)
    if ESP_Boxes[plr] then ESP_Boxes[plr]:Remove() ESP_Boxes[plr] = nil end
    if LockedTarget and LockedTarget.Name == plr.Name then LockedTarget = nil end
    if SilentAimTarget and SilentAimTarget.Name == plr.Name then SilentAimTarget = nil end
end)
