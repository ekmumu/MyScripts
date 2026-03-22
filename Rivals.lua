
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

local Settings = {
    ESP = true,
    Aimbot = true,
    Prediction = 0.12, 
    FOV = 250,
    Smoothness = 0.5, 
    MaxDistance = 350 -- 
}


local SafeGui = (gethui and gethui()) or game:GetService("CoreGui")
if SafeGui:FindFirstChild("MUMU_STABLE") then
    SafeGui.MUMU_STABLE:Destroy()
end

local ScreenGui = Instance.new("ScreenGui", SafeGui)
ScreenGui.Name = "MUMU_STABLE"
ScreenGui.ResetOnSpawn = false

local Main = Instance.new("Frame", ScreenGui)
Main.Size = UDim2.fromOffset(300, 380)
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
Container.Size = UDim2.new(0.9, 0, 0.7, 0)
Container.Position = UDim2.fromScale(0.05, 0.2)
Container.BackgroundTransparency = 1
local Layout = Instance.new("UIListLayout", Container)
Layout.Padding = UDim.new(0, 15)


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

local Hint = Instance.new("TextLabel", Main)
Hint.Size = UDim2.new(1, 0, 0, 30)
Hint.Position = UDim2.new(0, 0, 1, -40)
Hint.Text = "按 [J] 鍵顯示/隱藏選單"
Hint.TextColor3 = Color3.fromRGB(150, 150, 150)
Hint.TextSize = 16
Hint.Font = Enum.Font.Gotham
Hint.BackgroundTransparency = 1


UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if not gameProcessed and input.KeyCode == Enum.KeyCode.J then
        Main.Visible = not Main.Visible
    end
end)


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
            
            if Settings.ESP and p.Character and p.Character:FindFirstChild("HumanoidRootPart") and p.Character:FindFirstChild("Head") and p.Character:FindFirstChild("Humanoid") and p.Character.Humanoid.Health > 0 then
                
              
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


local function GetTarget()
    local target, maxDist = nil, Settings.FOV
    local mousePos = UserInputService:GetMouseLocation()
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("Head") and p.Character:FindFirstChild("Humanoid") and p.Character.Humanoid.Health > 0 then
            
            
            local distFromPlayer = (Camera.CFrame.Position - p.Character.HumanoidRootPart.Position).Magnitude
            if distFromPlayer > Settings.MaxDistance then continue end

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
