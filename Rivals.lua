-- ==========================================
-- MUMU RIVALS - 防崩潰 + 絕對瞬鎖版
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
    Prediction = 0.12, 
    FOV = 250,
    MaxDistance = 350
}

-- [[ 1. UI 建立: 絕對中心固定 ]]
local SafeGui = (gethui and gethui()) or game:GetService("CoreGui")
if SafeGui:FindFirstChild("MUMU_CRASHFREE") then
    SafeGui.MUMU_CRASHFREE:Destroy()
end

local ScreenGui = Instance.new("ScreenGui", SafeGui)
ScreenGui.Name = "MUMU_CRASHFREE"
ScreenGui.ResetOnSpawn = false

local Main = Instance.new("Frame", ScreenGui)
Main.Size = UDim2.fromOffset(300, 500) 
Main.Position = UDim2.fromScale(0.5, 0.5) 
Main.AnchorPoint = Vector2.new(0.5, 0.5)  
Main.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 10)
Instance.new("UIStroke", Main).Thickness = 3
Instance.new("UIStroke", Main).Color = Color3.fromRGB(255, 0, 0)

local Title = Instance.new("TextLabel", Main)
Title.Size = UDim2.new(1, 0, 0, 70)
Title.Text = "⚡ MUMU INSTANT"
Title.TextSize = 28
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
AddToggle("絕對瞬鎖 (右鍵)", "Aimbot")
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

-- [[ 3. 安全的隔牆檢測 ]]
local function IsVisible(targetChar)
    if not Settings.WallCheck then return true end
    pcall(function()
        local origin = Camera.CFrame.Position
        local targetPos = targetChar.Head.Position
        local raycastParams = RaycastParams.new()
        raycastParams.FilterType = Enum.RaycastFilterType.Exclude
        raycastParams.FilterDescendantsInstances = {LocalPlayer.Character, Camera}
        local result = workspace:Raycast(origin, targetPos - origin, raycastParams)
        if result and not result.Instance:IsDescendantOf(targetChar) then
            return false
        end
    end)
    return true
end

-- [[ 4. 穩定的方框透視 ]]
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
            if Settings.ESP and p.Character and p.Character:FindFirstChild("HumanoidRootPart") and p.Character:FindFirstChild("Head") and p.Character:FindFirstChild("Humanoid") and p.Character.Humanoid.Health > 0 then
                if Settings.TeamCheck and p.Team == LocalPlayer.Team then box.Visible = false continue end
                
                local dist = (Camera.CFrame.Position - p.Character.HumanoidRootPart.Position).Magnitude
                if dist < Settings.MaxDistance then
                    local topPos, onScreen = Camera:WorldToViewportPoint(p.Character.Head.Position + Vector3.new(0, 0.5, 0))
                    local bottomPos = Camera:WorldToViewportPoint(p.Character.HumanoidRootPart.Position - Vector3.new(0, 3, 0))

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

-- [[ 5. 暴力瞬鎖核心 ]]
local function GetTarget()
    local target, maxDist = nil, Settings.FOV
    local mousePos = UserInputService:GetMouseLocation()
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("Head") and p.Character:FindFirstChild("Humanoid") and p.Character.Humanoid.Health > 0 then
            if Settings.TeamCheck and p.Team == LocalPlayer.Team then continue end
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
    -- 使用 pcall 防止遊戲更新導致的報錯卡死整個腳本
    pcall(function()
        UpdateESP()

        if Settings.Aimbot and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
            local target = GetTarget()
            if target and target:FindFirstChild("Head") then
                local headPos = target.Head.Position + (target.HumanoidRootPart.Velocity * Settings.Prediction)
                local screenPos, onScreen = Camera:WorldToViewportPoint(headPos)
                
                if onScreen then
                    local mousePos = UserInputService:GetMouseLocation()
                    
                    if mousemoverel then
                        -- ⚡ 絕對瞬鎖：完全不平滑，計算好距離直接 100% 傳送滑鼠過去
                        local moveX = screenPos.X - mousePos.X
                        local moveY = screenPos.Y - mousePos.Y
                        mousemoverel(moveX, moveY)
                    else
                        -- 備用瞬鎖方案 (雙重強制覆寫)
                        Camera.CFrame = CFrame.lookAt(Camera.CFrame.Position, headPos)
                        LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(LocalPlayer.Character.HumanoidRootPart.Position, Vector3.new(headPos.X, LocalPlayer.Character.HumanoidRootPart.Position.Y, headPos.Z))
                    end
                end
            end
        end
    end)
end)

-- 確保玩家退出時清理 ESP
Players.PlayerRemoving:Connect(function(plr)
    if ESP_Boxes[plr] then ESP_Boxes[plr]:Remove() ESP_Boxes[plr] = nil end
end)
