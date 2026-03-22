-- ==========================================
-- MUMU RIVALS - 物理鎖頭 + 隔牆過濾 + 隊友過濾
-- ==========================================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

local Settings = {
    ESP = true,
    Aimbot = true,
    TeamCheck = true,  -- ⚡ 新增：預設開啟隊友過濾
    WallCheck = true,  -- ⚡ 新增：預設開啟隔牆過濾
    Prediction = 0.12, 
    FOV = 250,
    Smoothness = 1.0, 
    MaxDistance = 350
}

-- [[ 1. UI 建立: 絕對中心固定 ]]
local SafeGui = (gethui and gethui()) or game:GetService("CoreGui")
if SafeGui:FindFirstChild("MUMU_STABLE") then
    SafeGui.MUMU_STABLE:Destroy()
end

local ScreenGui = Instance.new("ScreenGui", SafeGui)
ScreenGui.Name = "MUMU_STABLE"
ScreenGui.ResetOnSpawn = false

local Main = Instance.new("Frame", ScreenGui)
Main.Size = UDim2.fromOffset(300, 500) -- ⚡ 拉長 UI 以容納新按鈕
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
Container.Position = UDim2.fromScale(0.05, 0.15)
Container.BackgroundTransparency = 1
local Layout = Instance.new("UIListLayout", Container)
Layout.Padding = UDim.new(0, 15)

-- [ 按鈕生成器 ]
local function AddToggle(name, settingKey)
    local btn = Instance.new("TextButton", Container)
    btn.Size = UDim2.new(1, 0, 0, 60)
    btn.BackgroundColor3 = Settings[settingKey] and Color3.fromRGB(200, 0, 0) or Color3.fromRGB(45, 45, 45)
    btn.Text = name .. ": " .. (Settings[settingKey] and "ON" or "OFF")
    btn.TextSize = 22
    btn.Font = Enum.Font.GothamBold
    btn.TextColor3 = Color3.new(1, 1, 1)
    Instance.new("UICorner", btn)
    
    btn.MouseButton1Click:Connect(function()
        Settings[settingKey] = not Settings[settingKey]
        btn.Text = name .. ": " .. (Settings[settingKey] and "ON" or "OFF")
        btn.BackgroundColor3 = Settings[settingKey] and Color3.fromRGB(200, 0, 0) or Color3.fromRGB(45, 45, 45)
    end)
end

AddToggle("穩定方框 (Box)", "ESP")
AddToggle("物理鎖頭 (右鍵)", "Aimbot")
AddToggle("不瞄隊友 (Team)", "TeamCheck")
AddToggle("隔牆不瞄 (Wall)", "WallCheck")

local Hint = Instance.new("TextLabel", Main)
Hint.Size = UDim2.new(1, 0, 0, 30)
Hint.Position = UDim2.new(0, 0, 1, -40)
Hint.Text = "按 [J] 鍵顯示/隱藏選單"
Hint.TextColor3 = Color3.fromRGB(150, 150, 150)
Hint.TextSize = 16
Hint.Font = Enum.Font.Gotham
Hint.BackgroundTransparency = 1

-- [[ 2. J鍵開關邏輯 ]]
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if not gameProcessed and input.KeyCode == Enum.KeyCode.J then
        Main.Visible = not Main.Visible
    end
end)

-- [[ ⚡ 核心：隔牆檢測函數 ]]
local function IsVisible(targetChar)
    if not Settings.WallCheck then return true end -- 沒開過濾就一律當作看得到

    local origin = Camera.CFrame.Position
    local targetPos = targetChar.Head.Position
    local direction = targetPos - origin

    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude
    -- 忽略自己、攝影機，確保射線不會被自己擋住
    raycastParams.FilterDescendantsInstances = {LocalPlayer.Character, Camera}
    raycastParams.IgnoreWater = true

    local result = workspace:Raycast(origin, direction, raycastParams)
    
    -- 如果射線打到了東西，且那個東西是敵人身上的部位，代表沒被牆壁擋住
    if result then
        if result.Instance:IsDescendantOf(targetChar) then
            return true
        else
            return false -- 打到牆壁了
        end
    end
    return true
end

-- [[ 3. 穩定方框透視 (Box ESP) ]]
local ESP_Boxes = {}

Players.PlayerRemoving:Connect(function(plr)
    if ESP_Boxes[plr] then
        ESP_Boxes[plr]:Remove()
        ESP_Boxes[plr] = nil
    end
end)

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
            -- 檢查是否存活 + ⚡ 隊友過濾 (如果是隊友就不畫框)
            if Settings.ESP and p.Character and p.Character:FindFirstChild("HumanoidRootPart") and p.Character:FindFirstChild("Head") and p.Character:FindFirstChild("Humanoid") and p.Character.Humanoid.Health > 0 then
                
                if Settings.TeamCheck and p.Team == LocalPlayer.Team then
                    box.Visible = false
                    continue
                end

                local dist = (Camera.CFrame.Position - p.Character.HumanoidRootPart.Position).Magnitude
                if dist < Settings.MaxDistance then
                    local head = p.Character.Head
                    local hrp = p.Character.HumanoidRootPart
                    
                    local topPos, onScreen = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0))
                    local bottomPos = Camera:WorldToViewportPoint(hrp.Position - Vector3.new(0, 3, 0))

                    if onScreen then
                        local height = math.abs(topPos.Y - bottomPos.Y)
                        local width = height * 0.65

                        box.Size = Vector2.new(width, height)
                        box.Position = Vector2.new(topPos.X - width/2, topPos.Y)
                        box.Visible = true
                    else
                        box.Visible = false
                    end
                else
                    box.Visible = false 
                end
            else
                box.Visible = false
            end
        end
    end
end

-- [[ 4. 物理抓取鎖頭 + 各種過濾 ]]
local function GetTarget()
    local target, maxDist = nil, Settings.FOV
    local mousePos = UserInputService:GetMouseLocation()
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("Head") and p.Character:FindFirstChild("Humanoid") and p.Character.Humanoid.Health > 0 then
            
            -- ⚡ 隊友過濾
            if Settings.TeamCheck and p.Team == LocalPlayer.Team then continue end

            -- ⚡ 距離過濾
            local distFromPlayer = (Camera.CFrame.Position - p.Character.HumanoidRootPart.Position).Magnitude
            if distFromPlayer > Settings.MaxDistance then continue end

            -- ⚡ 隔牆過濾
            if not IsVisible(p.Character) then continue end

            local pos, onScreen = Camera:WorldToViewportPoint(p.Character.Head.Position)
            if onScreen then
                local dist = (Vector2.new(pos.X, pos.Y) - mousePos).Magnitude
                if dist < maxDist then 
                    maxDist = dist 
                    target = p.Character 
                end
            end
        end
    end
    return target
end

RunService.RenderStepped:Connect(function()
    UpdateESP()

    -- 物理鎖頭 (mousemoverel)
    if Settings.Aimbot and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
        local target = GetTarget()
        
        if target and target:FindFirstChild("Head") then
            local headPos = target.Head.Position + (target.HumanoidRootPart.Velocity * Settings.Prediction)
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
            end
        end
    end
end)
