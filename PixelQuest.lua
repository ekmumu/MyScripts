-- 載入 Rayfield UI 庫
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

-- 建立主視窗
local Window = Rayfield:CreateWindow({
   Name = "Pixel Quest! 專屬腳本",
   LoadingTitle = "腳本載入中...",
   LoadingSubtitle = "準備戰鬥",
   ConfigurationSaving = {
      Enabled = false -- 先不開存檔功能，避免報錯
   },
   KeySystem = false -- 不需要輸入密碼
})

-- 建立分頁
local CombatTab = Window:CreateTab("戰鬥功能", 4483345998) -- 4483345998 是劍的圖示ID

-- 變數設定
local isFastAttackEnabled = false
local attackSpeedMultiplier = 1

-- 加入滑桿 (調控攻速)
local Slider = CombatTab:CreateSlider({
   Name = "攻速倍率調整",
   Range = {1, 100},
   Increment = 1,
   Suffix = "倍",
   CurrentValue = 1,
   Flag = "AttackSpeedSlider",
   Callback = function(Value)
       attackSpeedMultiplier = Value
   end,
})

-- 加入開關 (自動攻擊/超快攻速)
local Toggle = CombatTab:CreateToggle({
   Name = "啟用自動攻擊 / 超快攻速",
   CurrentValue = false,
   Flag = "AutoAttackToggle",
   Callback = function(Value)
       isFastAttackEnabled = Value
       
       if isFastAttackEnabled then
           task.spawn(function()
               while isFastAttackEnabled do
                   -- ==========================================
                   -- ⚠️ 這裡是你之後需要填入遊戲真實攻擊代碼的地方 ⚠️
                   -- ==========================================
                   
                   -- 測試用的印出訊息
                   print("揮刀！目前攻速倍率: " .. attackSpeedMultiplier)
                   
                   -- 控制攻擊頻率
                   task.wait(1 / attackSpeedMultiplier)
               end
           end)
       end
   end,
})
