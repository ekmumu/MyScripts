-- 載入 Orion UI 庫
local OrionLib = loadstring(game:HttpGet(('https://raw.githubusercontent.com/shlexware/Orion/main/source')))()

-- 建立主視窗
local Window = OrionLib:MakeWindow({
    Name = "Pixel Quest! 專屬腳本", 
    HidePremium = false, 
    SaveConfig = true, 
    ConfigFolder = "PixelQuestHub"
})

-- 建立一個分頁 (Tab)
local CombatTab = Window:MakeTab({
    Name = "戰鬥功能 (Combat)",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

-- 變數設定
local isFastAttackEnabled = false
local attackSpeedMultiplier = 1

-- 加入滑桿 (調控攻速)
CombatTab:AddSlider({
    Name = "攻速倍率調整",
    Min = 1,
    Max = 100,
    Default = 1,
    Color = Color3.fromRGB(255, 100, 100),
    Increment = 1,
    ValueName = "倍",
    Callback = function(Value)
        attackSpeedMultiplier = Value
        -- 當滑桿被拉動時，這個 Value 就會改變攻速變數
    end    
})

-- 加入開關 (啟用/關閉超快攻速)
CombatTab:AddToggle({
    Name = "啟用超快攻速 / 自動攻擊",
    Default = false,
    Callback = function(Value)
        isFastAttackEnabled = Value
        
        -- 當開關打開時，啟動一個迴圈來不斷執行攻擊
        if isFastAttackEnabled then
            spawn(function()
                while isFastAttackEnabled do
                    -- ==========================================
                    -- ⚠️ 這裡是你需要修改的地方 ⚠️
                    -- 每個遊戲的攻擊代碼都不同，通常是觸發某個 RemoteEvent
                    -- 假設遊戲的攻擊 Remote 叫做 "Attack" 放 ReplicatedStorage 裡：
                    -- game:GetService("ReplicatedStorage").Attack:FireServer()
                    -- ==========================================
                    
                    -- 這裡作為示範，印出目前的攻擊頻率
                    print("攻擊！目前倍率: " .. attackSpeedMultiplier)
                    
                    -- 控制攻擊速度 (1 秒除以倍率，倍率越高等待時間越短 = 攻速越快)
                    task.wait(1 / attackSpeedMultiplier)
                end
            end)
        end
    end    
})

-- 初始化 UI (這行一定要放在腳本最下面)
OrionLib:Init()
