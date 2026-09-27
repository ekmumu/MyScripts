-- mumu ez script

local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local workspace = game:GetService("Workspace")
local players = game:GetService("Players")
local runService = game:GetService("RunService")
local replicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local localPlayer = players.LocalPlayer

----------------------------------------------------------------
-- [Config & Variables]
----------------------------------------------------------------
_G.AutoFarm = false
_G.AutoMaterial = false
_G.AutoKillBoss = false
_G.AutoSummonDuck = false
_G.AutoBusoForced = false
_G.AutoM1 = true
_G.SelectedSlot = 1
_G.SelectedSkills = {Z = true, X = true, C = true, V = false}
_G.TargetBossName = "GooGooGaaGaa"
_G.AutoGachaMode = "x5"
_G.AutoGachaEnabled = false
_G.AutoRebirthEnabled = false
_G.AutoStatsEnabled = false
_G.UpgradeAmount = "1000"
_G.AutoStatsSettings = {
    Melee = false,
    Defense = false,
    Sword = false,
    Power = false
}
_G.SelectedMatMobs = {}
_G.HasTeleportedToIsland = false
_G.AutoEventMoon = false
_G.KillAllMobMoon = false

----------------------------------------------------------------
-- [Queue On Teleport]
----------------------------------------------------------------
local queue_on_teleport = queue_on_teleport or syn and syn.queue_on_teleport

if queue_on_teleport then
    players.LocalPlayer.OnTeleport:Connect(function(State)
        if State == Enum.TeleportState.Started then
            queue_on_teleport([[
                repeat task.wait() until game:IsLoaded()
                loadstring(game:HttpGet("https://raw.githubusercontent.com/daucobonhi/UiRedzV5/refs/heads/main/DemoUi.lua"))()
            ]])
        end
    end)
end

----------------------------------------------------------------
-- [Material Mob List]
----------------------------------------------------------------
local mobGroupTargets = {
    {displayName = "Bacon (Wood + Bandage + Bacon)", mobName = "Bacon", enabled = true},
    {displayName = "Bacon Strong (Dumbbell + Sandbag)", mobName = "Bacon Strong", enabled = false},
    {displayName = "Gorilla (Old Iron + Orb Black)", mobName = "Gorilla", enabled = false},
    {displayName = "Bacon Tarzan (Old Rock + Old Wood)", mobName = "Bacon Tarzan", enabled = false},
    {displayName = "Bacon Pirate (Iron + Shark Teeth)", mobName = "Bacon Pirate", enabled = false},
    {displayName = "Bacon Clown (Orb Spirit)", mobName = "Bacon Clown", enabled = false},
    {displayName = "Bacon Traveler (Iron Pipe)", mobName = "Bacon Traveler", enabled = false},
    {displayName = "Bacon Fawkes (Gold + Black Belt)", mobName = "Bacon Fawkes", enabled = false},
    {displayName = "Bacon Fisherman (Fish)", mobName = "Bacon Fisherman", enabled = false},
    {displayName = "Bacon The Deep (Orb Water)", mobName = "Bacon The Deep", enabled = false},
    {displayName = "Marine Captain (Orb Green + Holy Wood)", mobName = "Bacon Marine Captain", enabled = false},
    {displayName = "Bacon Iron (Holy Stone + Holy Gold + Black Iron)", mobName = "Bacon Iron", enabled = false},
    {displayName = "Bacon Kryptonite (Wind Stone + Orb Red)", mobName = "Bacon Minerals", enabled = false},
    {displayName = "Bacon Snow (Book of Rokuogan + Khaw phad kai)", mobName = "Bacon Snow", enabled = false},
    {displayName = "Bacon Ice (Cursed Wood + Cursed Iron)", mobName = "Bacon Ice", enabled = false},
    {displayName = "Bacon Lava (Orb Fire)", mobName = "Bacon Lava", enabled = false},
    {displayName = "Bacon Hellfire (Orb Dragon + Dragon Fang)", mobName = "Bacon Hellfire", enabled = false},
    {displayName = "Bacon Shadow Garden (Orb Purple)", mobName = "Bacon Shadow Garden", enabled = false},
    {displayName = "Bacon Seinen (Shadow Diary)", mobName = "Bacon Seinen", enabled = false}
}

for _, group in ipairs(mobGroupTargets) do
    _G.SelectedMatMobs[group.mobName] = group.enabled
end

----------------------------------------------------------------
-- [Remotes]
----------------------------------------------------------------
local actionRemote = replicatedStorage:WaitForChild("Remotes"):WaitForChild("Action")
local cancelQuestRemote =
    replicatedStorage:WaitForChild("Modules")
    :WaitForChild("NetworkFramework")
    :WaitForChild("NetworkEvent")

----------------------------------------------------------------
-- [Variables]
----------------------------------------------------------------
local skillDelay = 0.05
local questCheckInterval = 3
local lastQuestTime = 0
local currentTargetRoot = nil
local teleportConnection = nil
local lastNpcTarget = ""
local isProcessingQuest = false

----------------------------------------------------------------
-- [Material Teleport Positions]
----------------------------------------------------------------
local matPositionMap = {
    ["Bacon"] = Vector3.new(-67.018, 7.859, -224.919),
    ["Bacon Strong"] = Vector3.new(-67.018, 7.859, -224.919),
    ["Gorilla"] = Vector3.new(-1172.509, 7.398, -1193.154),
    ["Bacon Tarzan"] = Vector3.new(-1172.509, 7.398, -1193.154),
    ["Bacon Pirate"] = Vector3.new(-1228.169, 11.51, -61.182),
    ["Bacon Clown"] = Vector3.new(-1228.169, 11.51, -61.182),
    ["Bacon Traveler"] = Vector3.new(-944.594, 5.031, 1123.314),
    ["Bacon Fawkes"] = Vector3.new(-944.594, 5.031, 1123.314),
    ["Bacon Fisherman"] = Vector3.new(196.577, 12.496, 1029.665),
    ["Bacon The Deep"] = Vector3.new(196.577, 12.496, 1029.665),
    ["Bacon Marine Captain"] = Vector3.new(-1055.156, 9.066, -2476.378),
    ["Bacon Iron"] = Vector3.new(1335.431, 8.986, -998.337),
    ["Bacon Minerals"] = Vector3.new(1335.431, 8.986, -998.337),
    ["Bacon Snow"] = Vector3.new(62.811, 9.5, -2406.402),
    ["Bacon Ice"] = Vector3.new(62.811, 9.5, -2406.402),
    ["Bacon Lava"] = Vector3.new(1109.942, 6.856, -2179.784),
    ["Bacon Hellfire"] = Vector3.new(1109.942, 6.856, -2179.784),
    ["Bacon Shadow Garden"] = Vector3.new(-2203.343, 6.542, -730.282),
    ["Bacon Seinen"] = Vector3.new(-2203.343, 6.542, -730.282)
}

----------------------------------------------------------------
-- [Quest Map]
----------------------------------------------------------------
local questMap = {
    {minLv = 0, maxLv = 999, npc = "NPC_Quest1", mob = "Bacon"},
    {minLv = 1000, maxLv = 1999, npc = "NPC_Quest2", mob = "Bacon Strong"},
    {minLv = 2000, maxLv = 2999, npc = "NPC_Quest3", mob = "Bacon Traveler"},
    {minLv = 3000, maxLv = 3999, npc = "NPC_Quest4", mob = "Bacon Fawkes"},
    {minLv = 4000, maxLv = 4999, npc = "NPC_Quest5", mob = "Bacon Pirate"},
    {minLv = 5000, maxLv = 5999, npc = "NPC_Quest6", mob = "Bacon Clown"},
    {minLv = 6000, maxLv = 6999, npc = "NPC_Quest7", mob = "Bacon Tarzan"},
    {minLv = 7000, maxLv = 7999, npc = "NPC_Quest8", mob = "Gorilla"},
    {minLv = 8000, maxLv = 8999, npc = "NPC_Quest9", mob = "Bacon Fisherman"},
    {minLv = 9000, maxLv = 9999, npc = "NPC_Quest10", mob = "Bacon The Deep"},
    {minLv = 10000, maxLv = 10999, npc = "NPC_Quest11", mob = "Bacon Marine"},
    {minLv = 11000, maxLv = 11999, npc = "NPC_Quest12", mob = "Bacon Marine Captain"},
    {minLv = 12000, maxLv = 12999, npc = "NPC_Quest13", mob = "Bacon Rock"},
    {minLv = 13000, maxLv = 13999, npc = "NPC_Quest14", mob = "Bacon Iron"},
    {minLv = 14000, maxLv = 14999, npc = "NPC_Quest15", mob = "Bacon Minerals"},
    {minLv = 15000, maxLv = 15999, npc = "NPC_Quest16", mob = "Bacon Kryptonite"},
    {minLv = 16000, maxLv = 16999, npc = "NPC_Quest17", mob = "Bacon Snow"},
    {minLv = 17000, maxLv = 17999, npc = "NPC_Quest18", mob = "Bacon Ice"},
    {minLv = 18000, maxLv = 18999, npc = "NPC_Quest19", mob = "Bacon Lava"},
    {minLv = 19000, maxLv = 19999, npc = "NPC_Quest20", mob = "Bacon Hellfire"},
    {minLv = 20000, maxLv = math.huge, npc = "NPC_Quest21", mob = "Bacon Shadow Garden"}
}

----------------------------------------------------------------
-- [Buso]
----------------------------------------------------------------
local function checkBusoActive()
    local char = localPlayer.Character

    if char then
        for _, child in pairs(char:GetDescendants()) do
            if child:IsA("Model") and (
                string.find(string.lower(child.Name), "buso")
                or string.find(string.lower(child.Name), "haki")
            ) then
                return true
            end

            if child:IsA("BasePart")
                and child.Name == "LeftArm"
                and child.Color == Color3.fromRGB(0, 0, 0) then
                return true
            end
        end
    end

    return false
end

local function activateBuso()
    pcall(function()
        actionRemote:FireServer("Misc", "buso")
    end)
end

----------------------------------------------------------------
-- [Level]
----------------------------------------------------------------
local function getPlayerLevel()
    local currentLevel = 1

    pcall(function()
        local playerData =
            localPlayer:FindFirstChild("Data")
            or replicatedStorage:FindFirstChild("PlayerData")
                and replicatedStorage.PlayerData:FindFirstChild(localPlayer.Name)

        if playerData and playerData:FindFirstChild("Level") then
            currentLevel = playerData.Level.Value
        else
            local leaderstats = localPlayer:FindFirstChild("leaderstats")

            if leaderstats and leaderstats:FindFirstChild("Level") then
                currentLevel = leaderstats.Level.Value
            else
                local playerGui = localPlayer:FindFirstChild("PlayerGui")

                if playerGui then
                    for _, gui in pairs(playerGui:GetChildren()) do
                        if gui:IsA("ScreenGui") and gui.Enabled then
                            local frameDisplay =
                                gui:FindFirstChild("Frame_Display", true)

                            if frameDisplay then
                                local levelTextObj =
                                    frameDisplay:FindFirstChild("LevelText", true)

                                if levelTextObj
                                    and levelTextObj:IsA("TextLabel")
                                    and levelTextObj.Text ~= "" then

                                    local cleanNumber =
                                        string.gsub(levelTextObj.Text, "%D", "")

                                    if cleanNumber and cleanNumber ~= "" then
                                        currentLevel = tonumber(cleanNumber)
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end)

    return currentLevel or 1
end

local function getCurrentQuestConfig()
    local level = getPlayerLevel()

    for _, config in ipairs(questMap) do
        if level >= config.minLv and level <= config.maxLv then
            return config
        end
    end

    return questMap[1]
end

----------------------------------------------------------------
-- [Quest]
----------------------------------------------------------------
local function closeQuestUI()
    pcall(function()
        local playerGui = localPlayer:FindFirstChild("PlayerGui")

        if playerGui then
            local frameQuest =
                playerGui:FindFirstChild("Frame_Quest", true)

            if frameQuest then
                local closeButton =
                    frameQuest:FindFirstChild("Close_")

                if closeButton
                    and (
                        closeButton:IsA("TextButton")
                        or closeButton:IsA("ImageButton")
                    ) then

                    firesignal(closeButton.MouseButton1Click)
                end
            end
        end
    end)
end

local function abandonCurrentQuest()
    pcall(function()
        local args = {
            "fire",
            [3] = "Quest",
            [4] = "Cancel"
        }

        cancelQuestRemote:FireServer(unpack(args))
    end)

    closeQuestUI()
end

local function getTargetNPC()
    local config = getCurrentQuestConfig()
    local npcFolder = workspace:FindFirstChild("NpcQuest")

    if npcFolder and config then
        return npcFolder:FindFirstChild(config.npc)
    end

    return nil
end

----------------------------------------------------------------
-- [Tool]
----------------------------------------------------------------
local function getToolAtSlot(slotIndex)
    local backpack = localPlayer:FindFirstChild("Backpack")
    local character = localPlayer.Character

    if character and character:FindFirstChildOfClass("Tool") then
        return character:FindFirstChildOfClass("Tool")
    end

    if backpack then
        local toolItems = {}

        for _, item in ipairs(backpack:GetChildren()) do
            if item:IsA("Tool") then
                table.insert(toolItems, item)
            end
        end

        return toolItems[slotIndex]
    end

    return nil
end

local function equipSelectedSlot()
    pcall(function()
        local character = localPlayer.Character

        if character and not character:FindFirstChildOfClass("Tool") then
            local targetTool = getToolAtSlot(_G.SelectedSlot)

            if targetTool and targetTool.Parent ~= character then
                local humanoid = character:FindFirstChildOfClass("Humanoid")

                if humanoid then
                    humanoid:EquipTool(targetTool)
                end
            end
        end
    end)
end

----------------------------------------------------------------
-- [NPC Interaction]
----------------------------------------------------------------
local function interactWithNPC(npc, isNewNpc)
    if not npc or not localPlayer.Character then
        return
    end

    local root =
        npc:FindFirstChild("HumanoidRootPart")
        or npc:FindFirstChildOfClass("Part")

    local myRoot =
        localPlayer.Character:FindFirstChild("HumanoidRootPart")

    if root and myRoot then
        isProcessingQuest = true
        currentTargetRoot = nil

        myRoot.CFrame =
            root.CFrame * CFrame.new(0, 0, -3)

        task.wait(0.4)

        if isNewNpc then
            abandonCurrentQuest()
            task.wait(2.0)
        end

        local prompt =
            npc:FindFirstChildWhichIsA("ProximityPrompt", true)

        if prompt then
            fireproximityprompt(prompt)
        else
            local clickDetector =
                npc:FindFirstChildWhichIsA("ClickDetector", true)

            if clickDetector then
                fireclickdetector(clickDetector)
            end
        end

        task.wait(0.4)

        isProcessingQuest = false
    end
end

----------------------------------------------------------------
-- [Skill]
----------------------------------------------------------------
local function useSkillRemote(skillKey)
    pcall(function()
        local targetTool =
            getToolAtSlot(_G.SelectedSlot)

        local toolName =
            targetTool and targetTool.Name or "Combat"

        actionRemote:FireServer(
            toolName,
            skillKey
        )
    end)
end

----------------------------------------------------------------
-- [Material Teleport]
----------------------------------------------------------------
local function teleportOnceToIsland(targetPos)
    if _G.HasTeleportedToIsland then
        return
    end

    if not localPlayer.Character
        or not localPlayer.Character:FindFirstChild("HumanoidRootPart") then
        return
    end

    local myRoot =
        localPlayer.Character.HumanoidRootPart

    currentTargetRoot = nil

    myRoot.CFrame =
        CFrame.new(targetPos + Vector3.new(0, 15, 0))

    _G.HasTeleportedToIsland = true

    task.wait(2.5)
end

----------------------------------------------------------------
-- [Boss]
----------------------------------------------------------------
local function warpAndOpenSummonMenu()
    pcall(function()
        local npc =
            workspace:FindFirstChild("NpcBoss")
            and workspace.NpcBoss:FindFirstChild("NPC_SummonBoss")

        local npcRoot =
            npc
            and (
                npc:FindFirstChild("HumanoidRootPart")
                or npc:FindFirstChildOfClass("Part")
            )

        local myRoot =
            localPlayer.Character
            and localPlayer.Character:FindFirstChild("HumanoidRootPart")

        if npcRoot and myRoot then
            myRoot.CFrame =
                npcRoot.CFrame * CFrame.new(0, 0, -3)

            task.wait(0.3)

            local prompt =
                npc:FindFirstChildWhichIsA("ProximityPrompt", true)

            if prompt then
                fireproximityprompt(prompt)
            end
        end
    end)
end

local function clickSummonAndClose(bossName)
    local success = false

    pcall(function()
        local frameSummon =
            localPlayer.PlayerGui.HUD.Main.Frame_SummonBoss

        local summonBtn =
            frameSummon.ScrollingFrame[bossName].Main.TextButton

        local closeBtn =
            frameSummon:FindFirstChild("Close_")

        if summonBtn then
            firesignal(summonBtn.MouseButton1Click)

            task.wait(0.2)

            if closeBtn then
                firesignal(closeBtn.MouseButton1Click)
            end

            success = true
        end
    end)

    return success
end

----------------------------------------------------------------
-- [Target System]
----------------------------------------------------------------
local function getLockedMobTarget()

    ------------------------------------------------------------
    -- Duck
    ------------------------------------------------------------
    if _G.AutoSummonDuck then
        local mobFolder =
            workspace:FindFirstChild("Mob")

        if mobFolder then
            for _, mob in pairs(mobFolder:GetChildren()) do
                if mob.Name == "Duck Monster" then

                    local root =
                        mob:FindFirstChild("HumanoidRootPart")

                    local humanoid =
                        mob:FindFirstChildOfClass("Humanoid")

                    if root and (not humanoid or humanoid.Health > 0) then
                        return root
                    end
                end
            end
        end

        return nil
    end

    ------------------------------------------------------------
    -- Boss
    ------------------------------------------------------------
    if _G.AutoKillBoss then
        local bossFolder =
            workspace:FindFirstChild("Boss")

        if bossFolder then
            for _, mob in pairs(bossFolder:GetChildren()) do

                if string.lower(mob.Name)
                    == string.lower(_G.TargetBossName) then

                    local root =
                        mob:FindFirstChild("HumanoidRootPart")
                        or mob:FindFirstChild("HumanoidRootPart", true)
                        or mob:FindFirstChildOfClass("Part")

                    local hum =
                        mob:FindFirstChildOfClass("Humanoid")
                        or mob:FindFirstChildWhichIsA("Humanoid", true)

                    if root and (not hum or hum.Health > 0) then
                        return root
                    end
                end
            end
        end

        return nil
    end

    ------------------------------------------------------------
    -- Normal Mob
    ------------------------------------------------------------
    local mobFolder =
        workspace:FindFirstChild("Mob")

    if not mobFolder then
        return nil
    end

    ------------------------------------------------------------
    -- Material
    ------------------------------------------------------------
    if _G.AutoMaterial then

        for mobName, isSelected in pairs(_G.SelectedMatMobs) do

            if isSelected then

                local targetIslandPos =
                    matPositionMap[mobName]

                if targetIslandPos then
                    teleportOnceToIsland(targetIslandPos)
                end

                for _, mob in pairs(mobFolder:GetChildren()) do

                    local isMatch =
                        (mob.Name == mobName)

                    if mobName == "Bacon Minerals" then
                        isMatch =
                            (
                                mob.Name == "Bacon Minerals"
                                or mob.Name == "Bacon Kryptonite"
                                or mob.Name == "Bacon Iron"
                            )

                    elseif mobName == "Bacon Lava" then
                        isMatch =
                            (
                                mob.Name == "Bacon Lava"
                                or mob.Name == "Bacon Hellfire"
                            )
                    end

                    if isMatch then

                        local root =
                            mob:FindFirstChild("HumanoidRootPart")

                        local humanoid =
                            mob:FindFirstChildOfClass("Humanoid")

                        if root
                            and (not humanoid or humanoid.Health > 0) then
                            return root
                        end
                    end
                end
            end
        end
    end

    ------------------------------------------------------------
    -- Auto Farm
    ------------------------------------------------------------
    if _G.AutoFarm then

        local config =
            getCurrentQuestConfig()

        if config then

            for _, mob in pairs(mobFolder:GetChildren()) do

                if mob.Name == config.mob then

                    local root =
                        mob:FindFirstChild("HumanoidRootPart")

                    local humanoid =
                        mob:FindFirstChildOfClass("Humanoid")

                    if root
                        and (not humanoid or humanoid.Health > 0) then
                        return root
                    end
                end
            end
        end
    end

    return nil
end

----------------------------------------------------------------
-- [Max Level]
----------------------------------------------------------------
local function isMaxLevel()
    local ready = false

    pcall(function()
        local playerGui =
            localPlayer:FindFirstChild("PlayerGui")

        if playerGui then

            for _, v in pairs(playerGui:GetDescendants()) do

                if v:IsA("TextLabel")
                    and (
                        string.find(v.Text, "20000")
                        or string.find(string.lower(v.Text), "max")
                    ) then

                    ready = true
                    break
                end
            end
        end
    end)

    return ready
end

----------------------------------------------------------------
-- [Rebirth]
----------------------------------------------------------------
local function clickRebirthButton()
    pcall(function()
        local playerGui =
            localPlayer:FindFirstChild("PlayerGui")

        if playerGui then

            local frameStats =
                playerGui:FindFirstChild("Frame_Stats", true)

            if frameStats then

                local rebirthFrame =
                    frameStats:FindFirstChild("Rebirth")

                if rebirthFrame
                    and rebirthFrame:IsA("Frame") then

                    local realButton =
                        rebirthFrame:FindFirstChild("Rebirth")

                    if realButton
                        and realButton:IsA("TextButton") then

                        if firesignal then
                            firesignal(
                                realButton.MouseButton1Click
                            )
                        else
                            realButton:Activate()
                        end
                    end
                end
            end
        end
    end)
end

local function startRebirthLoop()
    while _G.AutoRebirthEnabled do

        if isMaxLevel() then
            clickRebirthButton()
        end

        task.wait(0.5)
    end
end

----------------------------------------------------------------
-- [Auto Stats]
----------------------------------------------------------------
local function runAutoStatsLoop()

    while _G.AutoStatsEnabled do

        pcall(function()

            local pGui =
                localPlayer:FindFirstChild("PlayerGui")

            if pGui then

                local mainHUD =
                    pGui:FindFirstChild("HUD")
                    or pGui:FindFirstChildWhichIsA("ScreenGui")

                local statsFrame =
                    mainHUD
                    and mainHUD:FindFirstChild("Frame_Stats", true)

                local statsContainer =
                    statsFrame
                    and statsFrame:FindFirstChild("Stats", true)

                if statsContainer then

                    local gameBox =
                        statsContainer:FindFirstChild("Box")

                    local gameTextBox =
                        gameBox
                        and gameBox:FindFirstChildWhichIsA(
                            "TextBox",
                            true
                        )

                    if gameTextBox then

                        gameTextBox.Text =
                            tostring(_G.UpgradeAmount)

                        pcall(function()
                            gameTextBox:ReleaseFocus(true)
                        end)
                    end

                    local containerFrame =
                        statsContainer:FindFirstChild("Frame")

                    if containerFrame then

                        for statName, shouldUpgrade
                            in pairs(_G.AutoStatsSettings) do

                            if shouldUpgrade
                                and _G.AutoStatsEnabled then

                                local statCategory =
                                    containerFrame:FindFirstChild(statName)

                                local plusButton =
                                    statCategory
                                    and statCategory:FindFirstChild("Plus")

                                if plusButton
                                    and plusButton.Visible then

                                    firesignal(
                                        plusButton.MouseButton1Click
                                    )

                                    task.wait(0.2)
                                end
                            end
                        end
                    end
                end
            end
        end)

        task.wait(0.3)
    end
end

----------------------------------------------------------------
-- [Main Farm Loop]
----------------------------------------------------------------
_G.StartFarmLoopFunc = function()

    task.spawn(function()

        local firstConfig =
            getCurrentQuestConfig()

        if firstConfig then
            lastNpcTarget = firstConfig.npc
        end

        if (
            _G.AutoBusoForced
            and not checkBusoActive()
        )
        or _G.AutoFarm
        or _G.AutoMaterial
        or _G.AutoKillBoss
        or _G.AutoSummonDuck then

            activateBuso()
        end

        while
            _G.AutoFarm
            or _G.AutoMaterial
            or _G.AutoKillBoss
            or _G.AutoSummonDuck do

            if not isProcessingQuest then

                equipSelectedSlot()

                ------------------------------------------------
                -- Quest
                ------------------------------------------------
                if _G.AutoFarm
                    and not _G.AutoMaterial
                    and not _G.AutoKillBoss
                    and not _G.AutoSummonDuck then

                    local config =
                        getCurrentQuestConfig()

                    local currentNPC =
                        getTargetNPC()

                    if currentNPC
                        and (tick() - lastQuestTime > questCheckInterval) then

                        local isNewNpc =
                            (config and config.npc ~= lastNpcTarget)

                        if config then
                            lastNpcTarget = config.npc
                        end

                        interactWithNPC(
                            currentNPC,
                            isNewNpc
                        )

                        lastQuestTime = tick()
                    end
                end

                ------------------------------------------------
                -- Target
                ------------------------------------------------
                local targetMobRoot =
                    getLockedMobTarget()

                if targetMobRoot
                    and not isProcessingQuest then

                    currentTargetRoot =
                        targetMobRoot

                    local orderedSkills =
                        {"Z", "X", "C", "V"}

                    for _, skill in ipairs(orderedSkills) do

                        if
                            (
                                not _G.AutoFarm
                                and not _G.AutoMaterial
                                and not _G.AutoKillBoss
                                and not _G.AutoSummonDuck
                            )
                            or currentTargetRoot ~= targetMobRoot
                            or isProcessingQuest then

                            break
                        end

                        if _G.SelectedSkills[skill] then

                            useSkillRemote(
                                string.lower(skill)
                            )

                            task.wait(skillDelay)
                        end
                    end

                else

                    currentTargetRoot = nil

                    task.wait(0.1)
                end
            end

            task.wait(0.01)
        end
    end)
end

----------------------------------------------------------------
-- [Save / Load]
----------------------------------------------------------------
local fileName = "RockFruit_Config.json"

local function saveSettings()

    local config = {
        AutoFarm = _G.AutoFarm,
        AutoMaterial = _G.AutoMaterial,
        AutoKillBoss = _G.AutoKillBoss,
        AutoSummonDuck = _G.AutoSummonDuck,
        AutoBusoForced = _G.AutoBusoForced,
        AutoM1 = _G.AutoM1,
        SelectedSlot = _G.SelectedSlot,
        SelectedSkills = _G.SelectedSkills,
        TargetBossName = _G.TargetBossName,
        AutoGachaMode = _G.AutoGachaMode,
        AutoGachaEnabled = _G.AutoGachaEnabled,
        AutoRebirthEnabled = _G.AutoRebirthEnabled,
        AutoStatsEnabled = _G.AutoStatsEnabled,
        UpgradeAmount = _G.UpgradeAmount,
        AutoStatsSettings = _G.AutoStatsSettings,
        AutoEventMoon = _G.AutoEventMoon,
        KillAllMobMoon = _G.KillAllMobMoon
    }

    pcall(function()
        if writefile then
            writefile(
                fileName,
                HttpService:JSONEncode(config)
            )
        end
    end)
end

local function loadSettings()

    pcall(function()

        if isfile
            and isfile(fileName)
            and readfile then

            local data =
                HttpService:JSONDecode(
                    readfile(fileName)
                )

            if data then

                _G.AutoFarm =
                    data.AutoFarm or false

                _G.AutoMaterial =
                    data.AutoMaterial or false

                _G.AutoKillBoss =
                    data.AutoKillBoss or false

                _G.AutoSummonDuck =
                    data.AutoSummonDuck or false

                _G.AutoBusoForced =
                    data.AutoBusoForced or false

                _G.AutoM1 =
                    data.AutoM1 ~= nil
                    and data.AutoM1
                    or true

                _G.SelectedSlot =
                    data.SelectedSlot or 1

                _G.SelectedSkills =
                    data.SelectedSkills
                    or _G.SelectedSkills

                _G.TargetBossName =
                    data.TargetBossName
                    or "GooGooGaaGaa"

                _G.AutoGachaMode =
                    data.AutoGachaMode
                    or "x5"

                _G.AutoGachaEnabled =
                    data.AutoGachaEnabled
                    or false

                _G.AutoRebirthEnabled =
                    data.AutoRebirthEnabled
                    or false

                _G.AutoStatsEnabled =
                    data.AutoStatsEnabled
                    or false

                _G.UpgradeAmount =
                    data.UpgradeAmount
                    or "1000"

                _G.AutoStatsSettings =
                    data.AutoStatsSettings
                    or _G.AutoStatsSettings

                _G.AutoEventMoon =
                    data.AutoEventMoon
                    or false

                _G.KillAllMobMoon =
                    data.KillAllMobMoon
                    or false
            end
        end
    end)
end

loadSettings()

----------------------------------------------------------------
-- [UI Library]
----------------------------------------------------------------
local redzlib =
    loadstring(
        game:HttpGet(
            "https://raw.githubusercontent.com/daucobonhi/UiRedzV5/refs/heads/main/DemoUi.lua"
        )
    )()

----------------------------------------------------------------
-- [MuMu UI]
----------------------------------------------------------------
local Window =
    redzlib:MakeWindow({
        Title = "MuMu",
        SubTitle = "MuMu Script",
        SaveFolder = "MuMu.lua"
    })

local MainTab =
    Window:MakeTab({"Main", "home"})

local BossTab =
    Window:MakeTab({"Boss", "swords"})

local MaterialTab =
    Window:MakeTab({"Material", "package"})

local MoonTab =
    Window:MakeTab({"Event Moon", "moon"})

local StatsTab =
    Window:MakeTab({"Stats", "settings"})

local RebirthTab =
    Window:MakeTab({"Rebirth", "refresh-cw"})

local ConfigTab =
    Window:MakeTab({"Config", "file-text"})

----------------------------------------------------------------
-- [Config UI]
----------------------------------------------------------------
ConfigTab:AddSection({
    "Save & Load Settings"
})

ConfigTab:AddButton({
    Name = "Save Config (mumu top 1)",
    Callback = function()
        saveSettings()
    end
})

----------------------------------------------------------------
-- [Main UI]
----------------------------------------------------------------
MainTab:AddSection({
    "MuMu Auto Farm System"
})

local toggleFarm =
    MainTab:AddToggle({
        Name = "Start Auto Farm",
        Default = _G.AutoFarm,

        Callback = function(Value)

            _G.AutoFarm = Value

            if Value then

                _G.AutoMaterial = false
                _G.AutoKillBoss = false
                _G.AutoSummonDuck = false
                _G.AutoEventMoon = false
                _G.KillAllMobMoon = false

                if _G.StartFarmLoopFunc then
                    _G.StartFarmLoopFunc()
                end
            end
        end
    })

MainTab:AddToggle({
    Name = "Auto M1 (Attack)",
    Default = _G.AutoM1,

    Callback = function(Value)
        _G.AutoM1 = Value
    end
})

MainTab:AddToggle({
    Name = "Auto Forced Buso",
    Default = _G.AutoBusoForced,

    Callback = function(Value)
        _G.AutoBusoForced = Value
    end
})

MainTab:AddDropdown({
    Name = "Select Hotbar Slot",
    Options = {"1", "2", "3", "4", "5"},
    Default = tostring(_G.SelectedSlot),

    Callback = function(Value)
        _G.SelectedSlot =
            tonumber(Value)
    end
})

----------------------------------------------------------------
-- [Skill UI]
----------------------------------------------------------------
MainTab:AddSection({
    "Auto Skill Use"
})

for _, skill in ipairs({"Z", "X", "C", "V"}) do

    MainTab:AddToggle({
        Name = "Use Skill " .. skill,
        Default = _G.SelectedSkills[skill],

        Callback = function(Value)
            _G.SelectedSkills[skill] = Value
        end
    })
end

----------------------------------------------------------------
-- [Gacha UI]
----------------------------------------------------------------
MainTab:AddSection({
    "Auto Gacha System"
})

MainTab:AddDropdown({
    Name = "Select Gacha Mode",
    Options = {"x5", "x10", "x15"},
    Default = _G.AutoGachaMode,

    Callback = function(Value)
        _G.AutoGachaMode = Value
    end
})

MainTab:AddToggle({
    Name = "Start Auto Gacha",
    Default = _G.AutoGachaEnabled,

    Callback = function(Value)
        _G.AutoGachaEnabled = Value
    end
})

----------------------------------------------------------------
-- [Moon UI]
----------------------------------------------------------------
MoonTab:AddSection({
    "Event Moon System"
})

MoonTab:AddToggle({
    Name = "Start Auto Event Moon",
    Default = _G.AutoEventMoon,

    Callback = function(Value)

        _G.AutoEventMoon = Value

        if Value then
            _G.AutoFarm = false
            _G.AutoMaterial = false
            _G.AutoKillBoss = false
            _G.AutoSummonDuck = false
            _G.KillAllMobMoon = false
        end
    end
})

MoonTab:AddToggle({
    Name = "Kill All Mob - FASTEST",
    Default = _G.KillAllMobMoon,

    Callback = function(Value)

        _G.KillAllMobMoon = Value

        if Value then
            _G.AutoFarm = false
            _G.AutoMaterial = false
            _G.AutoKillBoss = false
            _G.AutoSummonDuck = false
            _G.AutoEventMoon = false

            if _G.StartFarmLoopFunc then
                -- 不啟動普通 Farm Loop
            end
        end
    end
})

----------------------------------------------------------------
-- [Boss UI]
----------------------------------------------------------------
BossTab:AddSection({
    "Normal Boss System"
})

BossTab:AddDropdown({
    Name = "Select Target Boss",
    Options = {
        "GooGooGaaGaa",
        "Dark Bacon"
    },
    Default = _G.TargetBossName,

    Callback = function(Value)
        _G.TargetBossName = Value
    end
})

BossTab:AddToggle({
    Name = "Auto Summon & Kill Boss (Normal)",
    Default = _G.AutoKillBoss,

    Callback = function(Value)

        _G.AutoKillBoss = Value

        if Value then

            _G.AutoFarm = false
            _G.AutoMaterial = false
            _G.AutoSummonDuck = false
            _G.AutoEventMoon = false
            _G.KillAllMobMoon = false

            if _G.StartFarmLoopFunc then
                _G.StartFarmLoopFunc()
            end
        end
    end
})

BossTab:AddSection({
    "Summon Duck Monster"
})

BossTab:AddToggle({
    Name = "Auto Summon & Kill Duck Monster",
    Default = _G.AutoSummonDuck,

    Callback = function(Value)

        _G.AutoSummonDuck = Value

        if Value then

            _G.AutoFarm = false
            _G.AutoMaterial = false
            _G.AutoKillBoss = false
            _G.AutoEventMoon = false
            _G.KillAllMobMoon = false

            if _G.StartFarmLoopFunc then
                _G.StartFarmLoopFunc()
            end
        end
    end
})

----------------------------------------------------------------
-- [Material UI]
----------------------------------------------------------------
MaterialTab:AddSection({
    "Material System"
})

MaterialTab:AddToggle({
    Name = "Start Material Farm",
    Default = _G.AutoMaterial,

    Callback = function(Value)

        _G.AutoMaterial = Value

        if Value then

            _G.AutoFarm = false
            _G.AutoKillBoss = false
            _G.AutoSummonDuck = false
            _G.AutoEventMoon = false
            _G.KillAllMobMoon = false
            _G.HasTeleportedToIsland = false

            if _G.StartFarmLoopFunc then
                _G.StartFarmLoopFunc()
            end
        end
    end
})

local mobOptionsList = {}

for _, group in ipairs(mobGroupTargets) do
    table.insert(
        mobOptionsList,
        group.displayName
    )
end

MaterialTab:AddDropdown({
    Name = "Select Target Mob",
    Options = mobOptionsList,
    Default = mobOptionsList[1],

    Callback = function(Value)

        _G.HasTeleportedToIsland = false

        for _, g in ipairs(mobGroupTargets) do

            if g.displayName == Value then
                _G.SelectedMatMobs[g.mobName] = true
            else
                _G.SelectedMatMobs[g.mobName] = false
            end
        end
    end
})

----------------------------------------------------------------
-- [Stats UI]
----------------------------------------------------------------
StatsTab:AddSection({
    "Auto Stats Config"
})

StatsTab:AddTextBox({
    Name = "Upgrade Amount",
    Default = _G.UpgradeAmount,
    TextDisappear = false,

    Callback = function(Value)
        _G.UpgradeAmount = Value
    end
})

StatsTab:AddToggle({
    Name = "Start Auto Stats",
    Default = _G.AutoStatsEnabled,

    Callback = function(Value)

        _G.AutoStatsEnabled = Value

        if Value then
            task.spawn(runAutoStatsLoop)
        end
    end
})

StatsTab:AddSection({
    "Select Stats to Upgrade"
})

StatsTab:AddToggle({
    Name = "Melee",
    Default = _G.AutoStatsSettings.Melee,

    Callback = function(Value)
        _G.AutoStatsSettings.Melee = Value
    end
})

StatsTab:AddToggle({
    Name = "Defense",
    Default = _G.AutoStatsSettings.Defense,

    Callback = function(Value)
        _G.AutoStatsSettings.Defense = Value
    end
})

StatsTab:AddToggle({
    Name = "Sword",
    Default = _G.AutoStatsSettings.Sword,

    Callback = function(Value)
        _G.AutoStatsSettings.Sword = Value
    end
})

StatsTab:AddToggle({
    Name = "Fruit & Special",
    Default = _G.AutoStatsSettings.Power,

    Callback = function(Value)
        _G.AutoStatsSettings.Power = Value
    end
})

----------------------------------------------------------------
-- [Rebirth UI]
----------------------------------------------------------------
RebirthTab:AddSection({
    "Rebirth System"
})

RebirthTab:AddToggle({
    Name = "Auto Rebirth (Lv. 36000+)",
    Default = _G.AutoRebirthEnabled,

    Callback = function(Value)

        _G.AutoRebirthEnabled = Value

        if Value then
            task.spawn(startRebirthLoop)
        end
    end
})

----------------------------------------------------------------
-- [Start Saved Systems]
----------------------------------------------------------------
if
    _G.AutoFarm
    or _G.AutoMaterial
    or _G.AutoKillBoss
    or _G.AutoSummonDuck
then

    if _G.StartFarmLoopFunc then
        _G.StartFarmLoopFunc()
    end
end

if _G.AutoStatsEnabled then
    task.spawn(runAutoStatsLoop)
end

if _G.AutoRebirthEnabled then
    task.spawn(startRebirthLoop)
end

----------------------------------------------------------------
-- [Kill All Mob - FASTEST WALK SPEED]
----------------------------------------------------------------
task.spawn(function()

    while true do

        if _G.KillAllMobMoon
            and localPlayer.Character
            and localPlayer.Character:FindFirstChild("HumanoidRootPart") then

            pcall(function()

                local mobFolder =
                    workspace:FindFirstChild("Mob")
                    or workspace:FindFirstChild("Mobs")

                ------------------------------------------------
                -- 找 WalkSpeed 最高的 Mob
                ------------------------------------------------
                local fastestTarget = nil
                local fastestSpeed = -math.huge

                if mobFolder then

                    for _, mob in pairs(mobFolder:GetChildren()) do

                        local mobRoot =
                            mob:FindFirstChild("HumanoidRootPart")

                        local mobHum =
                            mob:FindFirstChildOfClass("Humanoid")

                        if mobRoot
                            and mobHum
                            and mobHum.Health > 0 then

                            local speed =
                                mobHum.WalkSpeed

                            if speed > fastestSpeed then

                                fastestSpeed = speed
                                fastestTarget = mobRoot

                            end
                        end
                    end
                end

                ------------------------------------------------
                -- 使用最快 Mob 作為目標
                ------------------------------------------------
                local finalTarget =
                    fastestTarget

                if finalTarget
                    and finalTarget.Parent then

                    currentTargetRoot =
                        finalTarget

                    local orderedSkills =
                        {"Z", "X", "C", "V"}

                    for _, skill in ipairs(orderedSkills) do

                        if not _G.KillAllMobMoon
                            or not finalTarget.Parent then
                            break
                        end

                        if _G.SelectedSkills[skill] then

                            pcall(function()

                                local character =
                                    localPlayer.Character

                                local targetTool =
                                    character
                                    and character:FindFirstChildOfClass("Tool")

                                local toolName =
                                    targetTool
                                    and targetTool.Name
                                    or "Combat"

                                actionRemote:FireServer(
                                    toolName,
                                    string.lower(skill)
                                )
                            end)

                            task.wait(0.05)
                        end
                    end

                else

                    currentTargetRoot = nil

                end
            end)
        end

        task.wait(0.01)
    end
end)

----------------------------------------------------------------
-- [Auto Event Moon]
----------------------------------------------------------------
task.spawn(function()

    while true do

        if _G.AutoEventMoon
            and localPlayer.Character
            and localPlayer.Character:FindFirstChild("HumanoidRootPart") then

            pcall(function()

                local myRoot =
                    localPlayer.Character.HumanoidRootPart

                local npcPromptFolder =
                    workspace:FindFirstChild("NpcPrompt")

                local goMoonNPC =
                    npcPromptFolder
                    and npcPromptFolder:FindFirstChild("GoMoon")

                if goMoonNPC then

                    local npcRoot =
                        goMoonNPC:FindFirstChild("HumanoidRootPart")
                        or goMoonNPC:FindFirstChild("Head")
                        or goMoonNPC:FindFirstChildOfClass("Part")

                    if npcRoot then

                        currentTargetRoot = nil

                        myRoot.CFrame =
                            npcRoot.CFrame
                            * CFrame.new(0, 0.5, 0)

                        task.wait(0.15)

                        local prompt =
                            goMoonNPC:FindFirstChildWhichIsA(
                                "ProximityPrompt",
                                true
                            )

                        if prompt then
                            fireproximityprompt(prompt)
                        end

                        task.wait(0.1)

                        myRoot.CFrame =
                            npcRoot.CFrame
                            * CFrame.new(0, 1, -20)

                        _G.AutoEventMoon = false
                    end
                end
            end)
        end

        task.wait(0.5)
    end
end)

----------------------------------------------------------------
-- [Auto Buso]
----------------------------------------------------------------
task.spawn(function()

    while true do

        if _G.AutoBusoForced
            and not checkBusoActive() then

            activateBuso()
        end

        task.wait(0.5)
    end
end)

----------------------------------------------------------------
-- [Duck / Boss Summon]
----------------------------------------------------------------
task.spawn(function()

    while true do

        --------------------------------------------------------
        -- Duck
        --------------------------------------------------------
        if _G.AutoSummonDuck
            and localPlayer.Character
            and localPlayer.Character:FindFirstChild("HumanoidRootPart") then

            local mobFolder =
                workspace:FindFirstChild("Mob")

            local duckFound = false

            if mobFolder then

                for _, m in pairs(mobFolder:GetChildren()) do

                    if m.Name == "Duck Monster" then

                        local hum =
                            m:FindFirstChildOfClass("Humanoid")

                        if not hum or hum.Health > 0 then
                            duckFound = true
                            break
                        end
                    end
                end
            end

            if not duckFound then

                local currentPos =
                    localPlayer.Character.HumanoidRootPart.CFrame

                local duckNpc =
                    workspace:FindFirstChild("NpcPrompt")
                    and workspace.NpcPrompt:FindFirstChild("DuckMonster")

                local targetPart =
                    duckNpc
                    and (
                        duckNpc:FindFirstChild("HumanoidRootPart")
                        or duckNpc:FindFirstChild("Duck")
                    )

                if targetPart then

                    currentTargetRoot = nil

                    localPlayer.Character.HumanoidRootPart.CFrame =
                        targetPart.CFrame
                        * CFrame.new(0, 0, -3)

                    task.wait(0.4)

                    local prompt =
                        duckNpc:FindFirstChildWhichIsA(
                            "ProximityPrompt",
                            true
                        )

                    if prompt then
                        fireproximityprompt(prompt)
                    end

                    task.wait(0.5)

                    if localPlayer.Character
                        and localPlayer.Character:FindFirstChild("HumanoidRootPart") then

                        localPlayer.Character.HumanoidRootPart.CFrame =
                            currentPos
                    end
                end
            end
        end

        --------------------------------------------------------
        -- Boss
        --------------------------------------------------------
        if _G.AutoKillBoss
            and localPlayer.Character
            and localPlayer.Character:FindFirstChild("HumanoidRootPart") then

            local bossFolder =
                workspace:FindFirstChild("Boss")

            local bossFound = false

            if bossFolder then

                for _, mob in pairs(bossFolder:GetChildren()) do

                    if string.lower(mob.Name)
                        == string.lower(_G.TargetBossName) then

                        local hum =
                            mob:FindFirstChildOfClass("Humanoid")
                            or mob:FindFirstChildWhichIsA(
                                "Humanoid",
                                true
                            )

                        if not hum or hum.Health > 0 then
                            bossFound = true
                            break
                        end
                    end
                end
            end

            if not bossFound then

                local currentPos =
                    localPlayer.Character.HumanoidRootPart.CFrame

                warpAndOpenSummonMenu()

                task.wait(0.5)

                clickSummonAndClose(
                    _G.TargetBossName
                )

                task.wait(0.5)

                if localPlayer.Character
                    and localPlayer.Character:FindFirstChild("HumanoidRootPart") then

                    localPlayer.Character.HumanoidRootPart.CFrame =
                        currentPos
                end
            end
        end

        task.wait(2.5)
    end
end)

----------------------------------------------------------------
-- [Position / Teleport System]
----------------------------------------------------------------
if teleportConnection then
    teleportConnection:Disconnect()
end

teleportConnection =
    runService.Heartbeat:Connect(function()

        if
            (
                _G.AutoFarm
                or _G.AutoMaterial
                or _G.AutoKillBoss
                or _G.AutoSummonDuck
                or _G.KillAllMobMoon
            )
            and localPlayer.Character
            and localPlayer.Character:FindFirstChild("HumanoidRootPart")
        then

            local root =
                localPlayer.Character.HumanoidRootPart

            ----------------------------------------------------
            -- Disable Character Collision
            ----------------------------------------------------
            for _, part in pairs(
                localPlayer.Character:GetChildren()
            ) do

                if part:IsA("BasePart") then
                    part.CanCollide = false
                end
            end

            ----------------------------------------------------
            -- Target Position
            ----------------------------------------------------
            if currentTargetRoot
                and currentTargetRoot.Parent then

                if _G.KillAllMobMoon then

                    local targetPos =
                        currentTargetRoot.Position

                    local targetLook =
                        currentTargetRoot.CFrame.LookVector

                    local standPosition =
                        Vector3.new(
                            targetPos.X
                                + (targetLook.X * 4.5),

                            targetPos.Y,

                            targetPos.Z
                                + (targetLook.Z * 4.5)
                        )

                    root.CFrame =
                        CFrame.new(
                            standPosition,

                            Vector3.new(
                                targetPos.X,
                                standPosition.Y,
                                targetPos.Z
                            )
                        )

                else

                    root.CFrame =
                        (
                            currentTargetRoot.CFrame
                            * CFrame.new(0, 7, 0)
                        )
                        * CFrame.Angles(
                            math.rad(-90),
                            0,
                            0
                        )
                end

            else

                root.Velocity =
                    Vector3.new(0, 0, 0)

                root.RotVelocity =
                    Vector3.new(0, 0, 0)
            end

            ----------------------------------------------------
            -- Velocity Handler
            ----------------------------------------------------
            if not root:FindFirstChild("VelocityHandler") then

                local bv =
                    Instance.new("BodyVelocity")

                bv.Name =
                    "VelocityHandler"

                bv.Velocity =
                    Vector3.new(0, 0, 0)

                bv.MaxForce =
                    Vector3.new(
                        math.huge,
                        math.huge,
                        math.huge
                    )

                bv.Parent = root
            end

        else

            if localPlayer.Character
                and localPlayer.Character:FindFirstChild("HumanoidRootPart") then

                local bv =
                    localPlayer.Character.HumanoidRootPart:FindFirstChild(
                        "VelocityHandler"
                    )

                if bv then
                    bv:Destroy()
                end
            end
        end
    end)

----------------------------------------------------------------
-- [Auto M1]
----------------------------------------------------------------
task.spawn(function()

    while true do

        if
            _G.AutoM1
            and (
                _G.AutoFarm
                or _G.AutoMaterial
                or _G.AutoKillBoss
                or _G.AutoSummonDuck
                or _G.KillAllMobMoon
            )
            and not isProcessingQuest
        then

            pcall(function()

                local character =
                    localPlayer.Character

                if character
                    and currentTargetRoot then

                    local tool =
                        character:FindFirstChildOfClass("Tool")

                    if tool then
                        tool:Activate()
                    else
                        actionRemote:FireServer(
                            "Combat",
                            "attack"
                        )
                    end
                end
            end)
        end

        task.wait(0.1)
    end
end)

----------------------------------------------------------------
-- [Quest Change Check]
----------------------------------------------------------------
task.spawn(function()

    while true do

        if
            _G.AutoFarm
            and not _G.AutoMaterial
            and not _G.AutoKillBoss
            and not _G.AutoSummonDuck
        then

            local config =
                getCurrentQuestConfig()

            if config
                and config.npc ~= lastNpcTarget
                and not isProcessingQuest then

                abandonCurrentQuest()
            end
        end

        task.wait(0.5)
    end
end)

----------------------------------------------------------------
-- [Auto Gacha]
----------------------------------------------------------------
task.spawn(function()

    while true do

        if _G.AutoGachaEnabled
            and _G.AutoGachaMode then

            pcall(function()

                local playerGui =
                    localPlayer:FindFirstChild("PlayerGui")

                if playerGui then

                    local randomFrame =
                        playerGui:FindFirstChild(
                            "Frame_RandomItem",
                            true
                        )

                    local displayFrame =
                        randomFrame
                        and randomFrame:FindFirstChild(
                            "DisplayFrame"
                        )

                    local targetButton =
                        displayFrame
                        and displayFrame:FindFirstChild(
                            _G.AutoGachaMode
                        )

                    if targetButton
                        and targetButton.Visible then

                        firesignal(
                            targetButton.MouseButton1Click
                        )
                    end
                end
            end)
        end

        task.wait(0.3)
    end
end)

----------------------------------------------------------------
-- [Character Respawn]
----------------------------------------------------------------
localPlayer.CharacterAdded:Connect(function()

    task.wait(2.0)

    if
        (
            _G.AutoBusoForced
            or _G.AutoFarm
            or _G.AutoMaterial
            or _G.AutoKillBoss
            or _G.AutoSummonDuck
        )
        and not checkBusoActive()
    then

        activateBuso()
    end
end)

