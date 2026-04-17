-- [[ 🐲 RUAJAD HUB: WORLD AUTOQUEST (BUG FIX EDITION) ]]
local Players = game:GetService("Players")
local LP = Players.LocalPlayer
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- [[ 📺 CENTER WARNING UI ]]
local ScreenGui = Instance.new("ScreenGui")
local WarningLabel = Instance.new("TextLabel")
ScreenGui.Name = "RUAJAD_Warning"
ScreenGui.Parent = LP:WaitForChild("PlayerGui")
ScreenGui.ResetOnSpawn = false

WarningLabel.Name = "Msg"
WarningLabel.Parent = ScreenGui
WarningLabel.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
WarningLabel.BackgroundTransparency = 1
WarningLabel.Position = UDim2.new(0.5, -200, 0.4, -25)
WarningLabel.Size = UDim2.new(0, 400, 0, 50)
WarningLabel.Font = Enum.Font.GothamBold
WarningLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
WarningLabel.TextSize = 24
WarningLabel.Text = "⚠️ [System waiting for chest spawn] ⚠️"
WarningLabel.Visible = false

-- Lightweight blinking system - no spec consumption
task.spawn(function()
    while true do
        if WarningLabel.Visible then
            WarningLabel.TextTransparency = 0
            task.wait(0.5)
            WarningLabel.TextTransparency = 1
            task.wait(0.5)
        else
            task.wait(1)
        end
    end
end)

local function showCenterWarning(active, text)
    if WarningLabel.Text ~= text then WarningLabel.Text = text or "" end
    WarningLabel.Visible = active
    if not active then WarningLabel.TextTransparency = 0 end
end

-- [[ 🛡️ SHIELD + 👻 GHOST MODE DAMAGE BLOCKER ]]
-- [[ 🛡️ SHIELD + 👻 GHOST MODE DAMAGE BLOCKER ]]
-- ⚠️ Mobile-Safe: ข้าม Hook ทุกชนิดแบบ 100% บนมือถือ
-- Mobile Executors (Delta/Fluxus) มีปัญหาเรื่อง hookmetamethod ที่ทำให้ Remote Arguments คลาดเคลื่อน
-- อาการ: เกมรับรู้ว่ากดพ่นไฟ (ตัวแข็ง/ล็อคเดิน) แต่เซิร์ฟเวอร์ไม่ตอบสนอง เพราะ Remote ส่งข้อมูลแหว่ง
local _isMobileDevice = game:GetService("UserInputService").TouchEnabled
local oldNamecall

if not _isMobileDevice then
    oldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
        local method = getnamecallmethod()
        -- ⚡ Fast exit: ถ้าไม่ใช่ FireServer/InvokeServer ปล่อยผ่านทันที
        if method ~= "FireServer" and method ~= "InvokeServer" then
            return oldNamecall(self, ...)
        end
        if not checkcaller() then
            if typeof(self) == "Instance" then
                local n = self.Name
                if n == "Ban" or n == "Kick" or n == "Report" then return nil end
                -- [[ 👻 GHOST MODE: Network-level damage blocking ]]
                if _G.GhostMode and n == "MobDamageRemote" then return nil end
            end
        end
        return oldNamecall(self, ...)
    end))
    warn("🛡️ [PC] __namecall hook installed (Anti-Ban/GhostMode)")
else
    warn("📱 [Mobile] __namecall hook SKIPPED (Bypassing executor vararg corruption)")
end

-- [[ 🧲 AUTO COLLECT DROPS (MAGNET) ]]
task.spawn(function()
    local Remotes = ReplicatedStorage:WaitForChild("Remotes")
    
    -- Path: Auto collect drops from Node/Mob via: Server→Client(BillboardPart, waveId, itemsTable)
    local function setupAutoCollect(remoteName)
        local remote = Remotes:FindFirstChild(remoteName)
        if not (remote and remote:IsA("RemoteEvent")) then return end
        warn("✅ [Magnet] Installed: " .. remoteName)
        remote.OnClientEvent:Connect(function(nodePart, waveId, itemsTable)
            if type(itemsTable) ~= "table" then return end
            for itemIndex, _ in pairs(itemsTable) do
                pcall(function()
                    remote:FireServer(nodePart, waveId, itemIndex)
                end)
                task.wait(0.03)
            end
        end)
    end
    
    -- Real remotes in game (filter out fake ones)
    setupAutoCollect("LargeNodeDropsRemote")  -- For drops from Node (trees, rocks, food)
    setupAutoCollect("MobDropsRemote")         -- For drops from mobs
end)

-- [[ 🛑 AUTO SHUTDOWN & RESUME ON BOSS DEATH ]]
local QuestToggles = {}
task.spawn(function()
    local Remotes = ReplicatedStorage:WaitForChild("Remotes")
    local BossDropRemote = Remotes:WaitForChild("StartBossDropRemote")
    
    BossDropRemote.OnClientEvent:Connect(function()
        warn("🎊 [System] Boss defeated! Pausing system for 10 seconds to wait for drop points...")
        
        local activeBefore = {}
        for name, toggle in pairs(QuestToggles) do
            local flagName = "AutoQuest" .. name
            if _G[flagName] == true then
                table.insert(activeBefore, {t = toggle, f = flagName, n = name})
                pcall(function() toggle:Set(false) end)
            end
        end

        -- Single notification no overlapping
        Rayfield:Notify({
            Title = "BOSS DEFEATED",
            Content = "Boss defeated! พัก 10 seconds then auto-farming will resume...",
            Duration = 10,
            Image = 4483362458
        })

        warn("⏳ [System] Counting down 10 seconds...")
        -- นับถอยหลังใน Console แทนการแจ้งเตือนซ้อนทับ
        for countdown = 10, 1, -1 do
            warn("⏳ [System] Resuming farm system in " .. countdown .. " seconds...")
            task.wait(1)
        end

        warn("✅ [System] ครบ 10 secondsแล้ว! Starting system again...")
        
        -- เปิดระบบsystemอัตโนมัติโดยตรง (ไม่ต้องเช็ค Flag)
        for _, data in ipairs(activeBefore) do
            warn("♻️ [System] Resuming " .. data.n .. " system...")
            
            -- วิธีที่ 1: ใช้ Toggle UI
            local success = pcall(function() data.t:Set(true) end)
            
            -- วิธีที่ 2: Fallback Calling function directlyถ้ากดปุ่มไม่ได้
            if not success then
                warn("⚠️ [System] UI button press failed! Calling function directly...")
                local questFuncs = {
                    Origins = runOriginsQuest,
                    Grassland = runGrasslandQuest,
                    Jungle = runJungleQuest,
                    Volcano = runVolcanoQuest,
                    Tundra = runTundraQuest,
                    Ocean = runOceanQuest,
                    Desert = runDesertQuest,
                    Fantasy = runFantasyQuest,
                    Wasteland = runWastelandQuest,
                    Prehistoric = runPrehistoricQuest,
                    Shinrin = runShinrinQuest
                }
                local func = questFuncs[data.n]
                if func then
                    _G[data.f] = true
                    task.spawn(func)
                end
            end
        end
    end)
end)

-- [[ 🚀 DRAGON CORE ]]
local function getActiveDragonModel()
    local char = workspace:FindFirstChild("Characters") and workspace.Characters:FindFirstChild(LP.Name)
    if char and char:FindFirstChild("Dragons") then return char.Dragons:GetChildren()[1] end
    local c = LP.Character
    if c and c:FindFirstChild("Dragons") then return c.Dragons:GetChildren()[1] end
    return nil
end

local function getRoot()
    local char = LP.Character
    if not char then return nil end
    local dragon = getActiveDragonModel()
    -- ล็อคที่ Root มังกรเป็นหลัก เพราะถ้ามังกรอยู่ต่ำเราจะโดนดาเมจ
    return (dragon and dragon:FindFirstChild("HumanoidRootPart")) or char:FindFirstChild("HumanoidRootPart")
end

-- เติมเกจพ่นไฟจากค่า capacity จริงของมังกร (อ้างอิงจาก maindragon.Lua)
local function refillDragonBreathFuel(dragon)
    if not dragon then return end
    local data = dragon:FindFirstChild("Data")
    if not data then return end

    local combatStats = data:FindFirstChild("CombatStats")
    local fireFolder = data:FindFirstChild("Fire")
    local breathCapacity = combatStats and combatStats:FindFirstChild("BreathCapacity")
    local breathFuel = fireFolder and fireFolder:FindFirstChild("BreathFuel")
    if breathCapacity and breathFuel then
        breathFuel.Value = breathCapacity.Value
    end

    local breathCooldown = fireFolder and fireFolder:FindFirstChild("BreathCooldown")
    if breathCooldown and breathCooldown:IsA("NumberValue") then
        breathCooldown.Value = 0
    end
end

local bv = nil
local function setPhysics(active)
    local root = getRoot()
    if not root then return end
    if active then
        -- ถ้าย้ายร่างไปขี่มังกร แต่ตัวต้านแรงโน้มถ่วงยังติดอยู่กับตัวเก่า ให้ทิ้งซะแล้วสร้างใหม่
        if bv and bv.Parent ~= root then
            pcall(function() bv:Destroy() end)
            bv = nil
        end

        if not bv then
            bv = Instance.new("BodyVelocity")
            bv.MaxForce = Vector3.new(9e9, 9e9, 9e9)
            bv.Velocity = Vector3.new(0, 0, 0)
            bv.Parent = root
        end
        
        -- ล็อคความเร็วปัจจุบันไม่ให้ร่วง
        root.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
        
        -- บังคับกล้องให้systemมาโฟกัสที่ตัวเรา/มังกร กันกล้องค้างที่เดิมตอนบินไวๆ
        pcall(function()
            local cam = workspace.CurrentCamera
            local hum = nil
            local dragon = getActiveDragonModel()
            if dragon then hum = dragon:FindFirstChildWhichIsA("Humanoid") end
            if not hum and LP.Character then hum = LP.Character:FindFirstChildWhichIsA("Humanoid") end
            if hum and cam.CameraSubject ~= hum then cam.CameraSubject = hum end
        end)
    else
        if bv then 
            pcall(function() bv:Destroy() end) 
            bv = nil 
        end
    end
end

local SPEED = 250
local FLY_HEIGHT_OFFSET = 80  -- บินสูงขึ้นจากจุดปัจจุบันเท่านี้ (แทนค่าตายตัว เพื่อรองรับทุกโลก)

-- ============================================================
-- [[ 🔄 AUTO RESET CHARACTER SYSTEM ]]
-- ============================================================
local function resetCharacter()
    pcall(function()
        warn("🔄 [System] กำลังรีเซ็ทตัวละคร...")
        local RefreshRemote = LP:WaitForChild("Remotes"):WaitForChild("RefreshAppearanceRemote")
        if RefreshRemote then
            RefreshRemote:FireServer()
            task.wait(0.8)
            -- รีเซ็ท HP และฟูลสเตททุกอย่าง
            local dragon = getActiveDragonModel()
            if dragon then
                refillDragonBreathFuel(dragon)
                local hum = dragon:FindFirstChildOfClass("Humanoid")
                if hum then hum.Health = hum.MaxHealth end
            end
            local char = LP.Character
            if char then
                local hum = char:FindFirstChildOfClass("Humanoid")
                if hum then hum.Health = hum.MaxHealth end
            end
            task.wait(0.3)
            warn("✅ [System] รีเซ็ทตัวละครเสร็จสิ้น!")
        end
    end)
end

-- [[ ✈️ SMART FLY: วาร์ปขึ้นสูง → Tween ในอากาศ → วาร์ปลงหาเป้าหมาย (เลี่ยง Portal 100%) ]]
local function flyTo(targetCF)
    local root = getRoot()
    if not root then return end
    local dist = (root.Position - targetCF.Position).Magnitude
    if dist < 10 then
        root.CFrame = targetCF
        root.AssemblyLinearVelocity = Vector3.new(0,0,0)
        return
    end

    -- Step 1: ✅ วาร์ปขึ้นสูง ทันที (ไม่ Tween ขึ้น)
    setPhysics(true)
    local flyY = math.max(root.Position.Y, targetCF.Position.Y) + FLY_HEIGHT_OFFSET
    local highPos = CFrame.new(root.Position.X, flyY, root.Position.Z)
    root.CFrame = highPos
    root.AssemblyLinearVelocity = Vector3.new(0,0,0)
    task.wait(0.1)

    -- Step 2: ✅ Tween ในอากาศไปเหนือเป้าหมาย (เหมือนเดิม ไม่เปลี่ยน)
    local aboveTarget = CFrame.new(targetCF.Position.X, flyY, targetCF.Position.Z)
    local horizDist = (Vector3.new(root.Position.X, 0, root.Position.Z) - Vector3.new(targetCF.Position.X, 0, targetCF.Position.Z)).Magnitude
    local tw2 = TweenService:Create(root, TweenInfo.new(horizDist / SPEED, Enum.EasingStyle.Linear), {CFrame = aboveTarget})
    tw2:Play()
    tw2.Completed:Wait()

    -- Step 3: ✅ วาร์ปลงหา Target ทันที (ไม่ Tween ลง)
    setPhysics(false)
    root.CFrame = targetCF
    root.AssemblyLinearVelocity = Vector3.new(0,0,0)
    root.AssemblyAngularVelocity = Vector3.new(0,0,0)
    task.wait(0.2)
end

local function isTargetAlive(targetObj)
    if not targetObj or not targetObj.Parent then return false end
    -- เช็คแบบลึก: บางมอนเก็บ Health/Dead ไว้ใน descendants
    local hp = targetObj:FindFirstChild("Health", true)
    local dead = targetObj:FindFirstChild("Dead", true)

    if hp and hp:IsA("ValueBase") then
        local n = tonumber(hp.Value)
        if n and n <= 0 then return false end
    end
    if dead and dead:IsA("BoolValue") and dead.Value == true then
        return false
    end

    return true
end

local function findNearestPortalMinion(radius)
    local root = getRoot()
    if not root then return nil end
    
    local nearest = nil
    local minD = radius

    -- สแกนทั้งหมดใน Workspace.MobFolder (ไม่กรองชื่อมอน)
    local mobFolder = workspace:FindFirstChild("MobFolder")
    if not mobFolder then return nil end
    for _, mob in pairs(mobFolder:GetChildren()) do
        if mob:IsA("Model") and isTargetAlive(mob) then
            local hrp = mob:FindFirstChild("HumanoidRootPart") or mob:FindFirstChildWhichIsA("BasePart")
            if hrp then
                local d = (root.Position - hrp.Position).Magnitude
                if d < minD then
                    minD = d
                    nearest = mob
                end
            end
        end
    end
    return nearest
end

local function isDead(node)
    if not node or not node.Parent then return true end
    local deadVal = node:FindFirstChild("Dead", true)
    if deadVal and deadVal:IsA("BoolValue") and deadVal.Value == true then return true end
    local hpVal = node:FindFirstChild("Health", true)
    if hpVal and hpVal:IsA("ValueBase") and tonumber(hpVal.Value) and tonumber(hpVal.Value) <= 0 then return true end
    if not node:FindFirstChild("BillboardPart", true) then return true end
    return false
end

-- ============================================================
-- [[ 🧠 SMART QUEST SCANNER v2: MODULE-BASED (LANGUAGE-AGNOSTIC) ]]
-- ดึงข้อมูลจาก ModuleScript ของเกมโดยตรง ไม่สนภาษา!
-- ใช้ LayoutOrder + RequiredAmount เพื่อระบุประเภทเควสแบบ 100% แม่นยำ
-- ============================================================
local WorldMissionData = nil
pcall(function()
    WorldMissionData = require(ReplicatedStorage.Storage.Missions.WorldMissions)
end)
if WorldMissionData then
    warn("✅ [SmartScanner] โหลด WorldMissions Module สำเร็จ!")
else
    warn("⚠️ [SmartScanner] ไม่สามารถโหลด Module ได้ จะใช้ค่า Fallback")
end


-- Fallback RequiredAmounts (ใช้เมื่อ require ไม่ได้)
local FALLBACK_AMOUNTS = {
    EggQuest      = {Default = 5,  Lobby = 1},
    RidingRing    = {Default = 30, Lobby = 10},
    TreasureChest = {Default = 3},
    KillMobs      = {Default = 15, Lobby = 10},
    KillBoss      = {Default = 1},
    SpendTime      = {Default = 450},
    Harvest       = {Default = 50},
}

local function getMaxAmount(questType, worldName)
    -- ลองดึงจาก Module จริงก่อน
    if WorldMissionData and WorldMissionData[questType] then
        local def = WorldMissionData[questType]
        if def.CustomRequiredAmounts and def.CustomRequiredAmounts[worldName] then
            return def.CustomRequiredAmounts[worldName]
        end
        return def.RequiredAmount
    end
    -- Fallback
    local fb = FALLBACK_AMOUNTS[questType]
    if fb then return fb[worldName] or fb.Default or 0 end
    return 0
end

local function getQuestRemaining(questType, worldName)
    local maxAmount = getMaxAmount(questType, worldName)
    if maxAmount == 0 then return 0 end

    local pg = LP:FindFirstChild("PlayerGui")
    if not pg then return 0 end

    local hudGui = pg:FindFirstChild("HUDGui")
    local missionsFrame = hudGui and hudGui:FindFirstChild("MissionsFrame")
    
    if not missionsFrame then
        warn("⚠️ [Scanner] ไม่พบ HUDGui.MissionsFrame รอโหลดก่อน...")
        return 0
    end

    -- เจาะจงหา Frame ใน HUD ที่มีชื่อตรงกับเควส + โลก (เช่น KillMobsOcean จะตรงกับ KillMobs + Ocean)
    for _, desc in ipairs(missionsFrame:GetDescendants()) do
        local nameMatch = (desc.Name:find(questType) or (questType:find("Boss") and desc.Name:find("Boss")))
        local worldMatch = desc.Name:find(worldName)
        
    -- ☢️ Wasteland/Toxic/Prehistoric/Shinrin Fallback: เฉพาะโลก Wasteland/Wastelands/Toxic/Prehistoric/Shinrin เท่านั้น
    -- ถ้าหาชื่อโลกในชื่อ Frame ไม่เจอ ให้รับ Frame ที่ไม่มีชื่อโลกอื่นปนอยู่
    if not worldMatch and (worldName == "Wasteland" or worldName == "Wastelands" or worldName == "Toxic" or worldName == "Prehistoric" or worldName == "Shinrin") then
        local otherWorlds = {"Lobby", "Origins", "Grassland", "Jungle", "Volcano", "Tundra", "Ocean", "Desert", "Fantasy"}
        local isOther = false
        for _, w in ipairs(otherWorlds) do if desc.Name:find(w) then isOther = true break end end
        if not isOther then worldMatch = true end
    end

        if nameMatch and worldMatch and (desc:IsA("Frame") or desc:IsA("ImageButton")) then
            -- หา ProgressLabel ข้างใน
            local rightSide = desc:FindFirstChild("RightSideFrame")
            local progLabel = rightSide and rightSide:FindFirstChild("ProgressLabel")
            
            if progLabel and progLabel:IsA("TextLabel") then
                local rawText = progLabel.Text:gsub("<[^>]+>", "")
                local cur, mx = rawText:match("(%d+)%s*/%s*(%d+)")
                
                if cur and mx then
                    local curNum = tonumber(cur)
                    local mxNum = tonumber(mx)
                    local needed = mxNum - curNum
                    warn("📊 [Scanner] " .. questType .. " เจอเป้าหมายจริง!: " .. cur .. "/" .. mx .. " → เหลืออีก " .. math.max(0, needed))
                    return math.max(0, needed)
                elseif questType:find("Boss") then
                    -- สำหรับเควสบอส บางทีมันไม่มีตัวเลขขึ้น (เช่นโชว์แค่ Defeat Boss) ให้ถือว่าเหลือ 1
                    warn("📊 [Scanner] พบเควสบอสแล้วแต่ไม่มีตัวเลขคืบหน้า ให้ค่าเริ่มต้นเป็น 1")
                    return 1
                end
            end
        end
    end

    -- ถ้าหาบน HUD ไม่เจอ แปลว่าไม่ได้ปักหมุด หรือทำเสร็จแล้ว
    return 0
end

-- [[ 📍 AUTO TRACKER ]]
local function trackQuest(questType, worldName)
    local focusR = ReplicatedStorage:WaitForChild("Remotes"):FindFirstChild("FocusMissionRemote")
    if focusR then
        warn("📌 [AutoTrack] กำลังปักหมุดเควส: " .. questType)
        focusR:FireServer("WorldMission", worldName, questType, true)
        task.wait(0.3) -- ลดดีเลย์ (เดิม 0.8) เพื่อความไว
    end
end

-- ============================================================
-- [[ SHARED QUEST FUNCTIONS ]]
-- ============================================================

-- 🥚 EGG COLLECTOR
local function collectEggs(amount, flagKey, worldName)
    local Rem = ReplicatedStorage:WaitForChild("Remotes")
    local FocusR = Rem:FindFirstChild("FocusMissionRemote")
    local SetR = Rem:FindFirstChild("SetCollectEggRemote")
    local CollR = Rem:FindFirstChild("CollectEggRemote")
    if not (FocusR and SetR and CollR) then return end

    local collected = 0
    while collected < amount and _G[flagKey] do
        local interactions = workspace:FindFirstChild("Interactions")
        local eggNodes = interactions and interactions:FindFirstChild("Nodes")
            and interactions.Nodes:FindFirstChild("Eggs")
            and interactions.Nodes.Eggs:FindFirstChild("ActiveNodes")
        if not eggNodes then task.wait(2) continue end

        local activeNodes = eggNodes:GetChildren()
        if #activeNodes == 0 then task.wait(2) continue end

        local root = getRoot()
        if not root then task.wait(1) continue end

        local nearestNode, minDist = nil, math.huge
        for _, node in pairs(activeNodes) do
            local ok, p = pcall(function() return node:GetPivot().Position end)
            if ok then
                local d = (root.Position - p).Magnitude
                if d < minDist then minDist = d nearestNode = node end
            end
        end

        if nearestNode then
            -- 🚀 ลงไปใกล้ไข่มากขึ้น (จาก 15 เหลือ 5) เพื่อให้เกมตัดสินใจว่าเราอยู่ใกล้จริงๆ
            flyTo(nearestNode:GetPivot() * CFrame.new(0, 5, 0))
            
            local eggId = nearestNode.Name
            FocusR:FireServer("WorldMission", worldName, "EggQuest")
            
            local success = false
            pcall(function()
                SetR:InvokeServer(eggId)
                success = CollR:InvokeServer(eggId)
            end)
            
            if success == true then
                collected = collected + 1
            else
                -- ⚡ Fallback แบบติดจรวด (หยุดทันทีที่เจอ ไม่รันครบ 20 รอบ)
                for i = 1, 25 do
                    if not _G[flagKey] then return end
                    local idStr = tostring(i)
                    task.spawn(function()
                        pcall(function() SetR:InvokeServer(idStr) end)
                    end)
                    -- รัน CollR สลับทีละตัว
                    local s2 = false
                    pcall(function() s2 = CollR:InvokeServer(idStr) end)
                    if s2 == true then
                        collected = collected + 1
                        break
                    end
                end
            end
        end
        task.wait(0.05) -- ลดดีเลย์รอรอบต่อไปให้ไวที่สุด
    end
end

-- 💍 RING FLYER (Nearest First)
local monsterLockConnection = nil
local monsterLockTarget = nil
local monsterLockHeight = 15

-- Ghost Mode & Safe Noclip Logic
local noclipCharParts = {}
local noclipDragonParts = {}
local noclipCacheChar = nil
local noclipCacheDragon = nil
local noclipCacheRefreshAt = 0

local function applyGhostPhysicsStep()
    local char = LP.Character
    local dragon = getActiveDragonModel()
    local root = getRoot()
    if not char or not root then return end

    local now = os.clock()
    if char ~= noclipCacheChar or dragon ~= noclipCacheDragon or now >= noclipCacheRefreshAt then
        noclipCacheChar = char
        noclipCacheDragon = dragon
        noclipCacheRefreshAt = now + 2
        noclipCharParts = {}
        noclipDragonParts = {}

        for _, v in pairs(char:GetDescendants()) do
            if v:IsA("BasePart") then table.insert(noclipCharParts, v) end
        end
        if dragon then
            for _, v in pairs(dragon:GetDescendants()) do
                if v:IsA("BasePart") then table.insert(noclipDragonParts, v) end
            end
        end
    end

    local isGhost = _G.GhostMode
    local isNearGround = false
    local rayParams = RaycastParams.new()
    rayParams.FilterDescendantsInstances = {char, dragon}
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    local ray = workspace:Raycast(root.Position, Vector3.new(0, -6, 0), rayParams)
    if ray then isNearGround = true end

    -- อัปเดตชิ้นส่วนตัวละคร
    for _, part in ipairs(noclipCharParts) do
        if part and part.Parent then
            if isGhost then
                -- [[ 👻 GHOST MODE ]]
                part.CanTouch = true -- เปิดเพื่อเก็บของได้ (อมตะผ่าน MobDamageRemote block + Heal 60fps)
                part.CanQuery = true -- ⚠️ ฟิกซ์บักมือถือพ่นไฟไม่ออก: ต้องเปิดไว้เพราะเกมใช้ Raycast ตรวจจับทิศทางพ่นไฟ
                if part.Name == "HumanoidRootPart" then
                    part.CanCollide = true -- กันตกพื้น
                else
                    part.CanCollide = false -- บังคับมอนทะลุ
                end
            else
                -- [[ 🛡️ NORMAL/SAFE NOCLIP ]]
                part.CanTouch = true
                part.CanQuery = true
                if part.Name == "HumanoidRootPart" and isNearGround then
                    part.CanCollide = true
                else
                    part.CanCollide = false
                end
            end
        end
    end

    -- ปิดการยุ่งเกี่ยวกับระบบฟิสิกส์ (CanCollide/CanQuery) ของมังกรอย่างถาวร
    -- ⚠️ ฟิกซ์บัก: หน้าที่ของการเป็นอมตะใช้แค่ส่ง Heal() 60fps และบล็อก MobDamageRemote ก็รอด 100% แล้ว
    -- การไปแก้ฟิสิกส์มังกรทำให้เกมส่วนอื่น (เช่น พ่นไฟ อนิเมชั่น และ Raycast บนมือถือ) พังหมด
    -- ปล่อยให้มังกรเป็น Solis/Physical 100% ตามธรรมชาติของเกม
    -- (ชิ้นส่วนตัวละคร Player ยังเป็นวิญญาณอยู่เหมือนเดิมเพื่อกันมอนติดหัว)
end

local function lockPlayerToMonster(target, height)
    if monsterLockConnection then monsterLockConnection:Disconnect() end
    monsterLockTarget = target
    monsterLockHeight = height or 15
    monsterLockConnection = RunService.Heartbeat:Connect(function(dt)
        if not monsterLockTarget or (typeof(monsterLockTarget) == "Instance" and not monsterLockTarget.Parent) then 
            if monsterLockConnection then monsterLockConnection:Disconnect() monsterLockConnection = nil end
            return 
        end

        local root = getRoot()
        if root then
            local ok, cf = pcall(function() 
                return (typeof(monsterLockTarget) == "Instance") and monsterLockTarget:GetPivot() or monsterLockTarget 
            end)
            if ok then
                -- บังคับล็อคพิกัดและเคลียร์แรงทุกเฟรม (Heartbeat) รับรองนิ่งสนิท ไม่สะบัด ไม่กระตุก
                root.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                root.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
                root.CFrame = cf * CFrame.new(0, monsterLockHeight, 0)
            end
        end
    end)
end

local function unlockPlayerFromMonster()
    if monsterLockConnection then monsterLockConnection:Disconnect() monsterLockConnection = nil end
end

local function unlockPlayer()
    unlockPlayerFromMonster()
end

local function flyRings(amount, flagKey)
    local ringsFolder = workspace:FindFirstChild("Interactions")
        and workspace.Interactions:FindFirstChild("RidingRings")
        and workspace.Interactions.RidingRings:FindFirstChild("Flying")
    if not ringsFolder then return end

    local available = {}
    for _, ring in ipairs(ringsFolder:GetChildren()) do
        if ring:IsA("BasePart") then table.insert(available, ring) end
    end

    local count = 0
    while #available > 0 and count < amount and _G[flagKey] do
        local root = getRoot()
        if not root then task.wait(1) break end
        local nearest, idx, minD = nil, -1, math.huge
        for i, ring in ipairs(available) do
            local d = (root.Position - ring.Position).Magnitude
            if d < minD then minD = d nearest = ring idx = i end
        end
        if nearest then
            -- ห่วงอยู่สูงอยู่แล้ว ไม่ต้องหนี Portal ใช้ Tween ตรงได้เลย
            setPhysics(true)
            local tw = TweenService:Create(root, TweenInfo.new(minD / SPEED, Enum.EasingStyle.Linear), {CFrame = nearest.CFrame})
            tw:Play()
            tw.Completed:Wait()
            setPhysics(false)
            table.remove(available, idx)
            count = count + 1
            task.wait(0.1)
        else break end
    end
end

-- ============================================================
-- [[ 🔒 HEARTBEAT LOCKER (AUTO-AIMMING) ]]
-- ============================================================

-- ⚔️ MOB KILLER (Real-time HUD update)
local function killMobs(targetAmount, flagKey, worldName)
    while _G[flagKey] do
        -- เช็คความคืบหน้าจริงจากหน้าจอทุกครั้ง
        local remaining = getQuestRemaining("KillMobs", worldName)
        if remaining <= 0 then 
            warn("✅ [KillMobs] ภารกิจมอนสเตอร์เสร็จสิ้น!")
            break 
        end

        local root = getRoot()
        local mobFolder = workspace:FindFirstChild("MobFolder")
        if not (root and mobFolder) then task.wait(1) continue end

        local nearest, minD = nil, math.huge
        for _, obj in pairs(mobFolder:GetDescendants()) do
            if (obj:IsA("MeshPart") or obj:IsA("Part")) and isTargetAlive(obj) then
                local d = (root.Position - obj.Position).Magnitude
                if d < minD then minD = d nearest = obj end
            end
        end

        if nearest then
            -- เช็คอีกทีก่อนบิน (กันกรณี mob ตายระหว่างสแกน)
            if not isTargetAlive(nearest) then task.wait(0.3) continue end
            
            flyTo(nearest:GetPivot() * CFrame.new(0, 15, 0))
            
            -- เช็คอีกทีหลังบินถึง (กันกรณี mob ตายระหว่างบิน)
            if not isTargetAlive(nearest) then 
                task.wait(0.3) 
                continue 
            end
            
            local dragon = getActiveDragonModel()
            if dragon and dragon:FindFirstChild("Remotes") then
                local soundR = dragon.Remotes:FindFirstChild("PlaySoundRemote")
                local breathR = dragon.Remotes:FindFirstChild("BreathFireRemote")
                if breathR then breathR:FireServer(true) end
                
                local t = os.clock()
                lockPlayerToMonster(nearest:GetPivot() * CFrame.new(0, 15, 0))
                
                while _G[flagKey] and isTargetAlive(nearest) and (os.clock() - t < 15) do
                    -- [[ 🔥 AURA DAMAGE: โจมตี 1 ครั้งต่อ 1 ตัวในรัศมี 50 Studs ]]
                    local rootForAura = getRoot()
                    if rootForAura then
                        local attackedMobs = {}
                        for _, obj in pairs(mobFolder:GetDescendants()) do
                            if (obj:IsA("MeshPart") or obj:IsA("Part")) and isTargetAlive(obj) then
                                local mobModel = obj.Parent
                                if mobModel and not attackedMobs[mobModel] then
                                    local d = (rootForAura.Position - obj.Position).Magnitude
                                    if d <= 50 then
                                        if soundR then soundR:FireServer("Breath", "Mobs", obj) end
                                        attackedMobs[mobModel] = true -- จำไว้ว่าตีตัวนี้ไปแล้วในรอบนี้
                                    end
                                end
                            end
                        end
                    end
                    task.wait(0.25)
                end
                
                unlockPlayerFromMonster()
                if breathR then breathR:FireServer(false) end
            end

        else
            task.wait(2)
        end
        task.wait(0.5)
    end
end

-- 🍎 HARVESTER (FIX: บินสูงเลี่ยง Portal)
-- 🍎 HARVESTER (Real-time HUD update - สนใจจำนวนของที่ดรอป ไม่ใช่จำนวนต้นไม้)
local function harvestResources(targetAmount, flagKey, worldName)
    local Rem = ReplicatedStorage:WaitForChild("Remotes")
    local HitRemote = Rem:FindFirstChild("ClientDestructibleHitRemote")
    if not HitRemote then return end

    while _G[flagKey] do
        -- อัปเดต Progress จาก HUD ตลอดเวลา (เพราะ 1 ต้นอาจได้ของหลายชิ้น)
        local remaining = getQuestRemaining("Harvest", worldName)
        if remaining <= 0 then 
            warn("✅ [Harvest] เก็บเกี่ยวครบตามจำนวนบน HUD แล้ว!")
            break 
        end

        local root = getRoot()
        local nodes = workspace:FindFirstChild("Interactions") and workspace.Interactions:FindFirstChild("Nodes")
        if not (root and nodes) then task.wait(1) continue end

        local nearest, minD = nil, math.huge
        for _, folderName in ipairs({"Food", "Resources"}) do
            local folder = nodes:FindFirstChild(folderName)
            if folder then
                for _, node in pairs(folder:GetChildren()) do
                    if node:IsA("Model") and not isDead(node) then
                        local ok, p = pcall(function() return node:GetPivot().Position end)
                        if ok then
                            local d = (root.Position - p).Magnitude
                            if d < minD then minD = d nearest = node end
                        end
                    end
                end
            end
        end

        if nearest then
            -- ดิ่งลงพื้น (-10 จากแกนกลาง) เพื่อให้ชนไอเท็มดรอปที่พื้น
            flyTo(nearest:GetPivot() * CFrame.new(0, -10, 0))
            local billboard = nearest:FindFirstChild("BillboardPart", true)
            local dragon = getActiveDragonModel()
            local t = os.clock()
            
            -- ล็อคพิกัดแนบแน่นกับต้นไม้ ป้องกันภาพตัดหรือกระตุกไปมา
            lockPlayerToMonster(nearest, -10)
            
            while _G[flagKey] and not isDead(nearest) and (os.clock() - t < 12) do
                pcall(function()
                    if dragon and dragon:FindFirstChild("Remotes") then
                        dragon.Remotes.PlaySoundRemote:FireServer("Breath", "Destructibles", billboard)
                    end
                    HitRemote:FireServer(nearest, billboard)
                end)
                task.wait(0.15)
            end
            unlockPlayerFromMonster()
        else
            task.wait(2)
        end
        task.wait(0.3)
    end
end

-- 📦 CHEST FINDER (FIX: เพิ่ม Delay พ่นไฟ)
local function findChests(amount, flagKey, worldName)
    local found = 0
    while found < amount and _G[flagKey] do
        local root = getRoot()
        local nodes = workspace:FindFirstChild("Interactions") and workspace.Interactions:FindFirstChild("Nodes")
        local treasure = nil
        if nodes then
            -- รองรับชื่อโฟลเดอร์หีบของทุกโลกที่มักจะตั้งชื่อสะกดไม่เหมือนกัน
            treasure = nodes:FindFirstChild("Treasure") or nodes:FindFirstChild("TreasureChests") or nodes:FindFirstChild("TreasureChest") or nodes:FindFirstChild("Treasure Chests")
        end
        if not (root and treasure) then task.wait(2) continue end

        local nearest, minD = nil, math.huge
        for _, nodeFolder in pairs(treasure:GetChildren()) do
            for _, chest in pairs(nodeFolder:GetChildren()) do
                if chest:IsA("Model") and chest:FindFirstChild("HumanoidRootPart") then
                    local hrp = chest.HumanoidRootPart
                    local hp = hrp:FindFirstChild("Health")
                    local dead = hrp:FindFirstChild("Dead")
                    local alive = (hp and hp.Value > 0) and (not dead or dead.Value == false)
                    if alive then
                        local d = (root.Position - hrp.Position).Magnitude
                        if d < minD then minD = d nearest = chest end
                    end
                end
            end
        end

        if nearest then
            local hrp = nearest.HumanoidRootPart
            local chestPos = hrp.Position
            
            -- 🚀 บินไปอยู่เหนือหีบเตรียมทำพายุพ่นไฟ
            flyTo(CFrame.new(chestPos + Vector3.new(0, 8, 0)))
            
            -- ฟังก์ชันจำลองการกดปุ่มพ่นไฟ (ใช้ Path จากผลสแกนของลูกพี่ เป็นการแตะ 1 ครั้ง)
            local function toggleMobileFire()
                local UIS = game:GetService("UserInputService")
                if not UIS.TouchEnabled then return end
                
                -- ดึงปุ่มตาม Path ที่สแกนได้เป๊ะๆ
                local fireBtn = LP:FindFirstChild("PlayerGui") 
                    and LP.PlayerGui:FindFirstChild("HUDGui") 
                    and LP.PlayerGui.HUDGui:FindFirstChild("BottomFrame") 
                    and LP.PlayerGui.HUDGui.BottomFrame:FindFirstChild("MobileControlsFrame") 
                    and LP.PlayerGui.HUDGui.BottomFrame.MobileControlsFrame:FindFirstChild("TouchControlFrame") 
                    and LP.PlayerGui.HUDGui.BottomFrame.MobileControlsFrame.TouchControlFrame:FindFirstChild("JumpButton") 
                    and LP.PlayerGui.HUDGui.BottomFrame.MobileControlsFrame.TouchControlFrame.JumpButton:FindFirstChild("Frame") 
                    and LP.PlayerGui.HUDGui.BottomFrame.MobileControlsFrame.TouchControlFrame.JumpButton.Frame:FindFirstChild("Fire")
                
                -- ถ้าหาปุ่มเจอ ให้ดึงพิกัดกึ่งกลางและจำลองการแตะ
                if fireBtn and (fireBtn:IsA("GuiObject")) then
                    local btnPos = fireBtn.AbsolutePosition
                    local btnSize = fireBtn.AbsoluteSize
                    
                    -- หาจุดกึ่งกลางของปุ่ม (บวก 36 ชดเชยขอบบน Topbar)
                    local cx = btnPos.X + (btnSize.X / 2)
                    local cy = btnPos.Y + (btnSize.Y / 2) + 36 
                    
                    pcall(function()
                        local vim = game:GetService("VirtualInputManager")
                        vim:SendTouchEvent(12, 0, cx, cy) -- แตะลง
                        task.wait(0.05)
                        vim:SendTouchEvent(12, 2, cx, cy) -- ปล่อยนิ้ว
                    end)
                end
            end

            -- ฟังก์ชันกดปุ่มพ่นไฟ (โจมตี UI โดยตรงเหมือนที่เคยทำกับบอส)
            local function toggleMobileFire()
                pcall(function()
                    -- ดึงปุ่มตาม Path ที่สแกนได้เป๊ะๆ
                    local fireBtn = LP:FindFirstChild("PlayerGui") 
                        and LP.PlayerGui:FindFirstChild("HUDGui") 
                        and LP.PlayerGui.HUDGui:FindFirstChild("BottomFrame") 
                        and LP.PlayerGui.HUDGui.BottomFrame:FindFirstChild("MobileControlsFrame") 
                        and LP.PlayerGui.HUDGui.BottomFrame.MobileControlsFrame:FindFirstChild("TouchControlFrame") 
                        and LP.PlayerGui.HUDGui.BottomFrame.MobileControlsFrame.TouchControlFrame:FindFirstChild("JumpButton") 
                        and LP.PlayerGui.HUDGui.BottomFrame.MobileControlsFrame.TouchControlFrame.JumpButton:FindFirstChild("Frame") 
                        and LP.PlayerGui.HUDGui.BottomFrame.MobileControlsFrame.TouchControlFrame.JumpButton.Frame:FindFirstChild("Fire")
                    
                    if fireBtn and (fireBtn:IsA("GuiObject")) then
                        -- วิธีที่ 1: ตีตรงเข้าสัญญาณภายในของปุ่ม (ทะลุทุกหน้าจอ ไม่สนพิกัด)
                        if firesignal then
                            pcall(function() firesignal(fireBtn.TouchTap) end)
                            pcall(function() firesignal(fireBtn.MouseButton1Click) end)
                            pcall(function() firesignal(fireBtn.Activated) end)
                        end
                        if getconnections then
                            pcall(function()
                                for _, conn in pairs(getconnections(fireBtn.Activated)) do
                                    conn:Fire()
                                end
                            end)
                        end
                        
                        -- วิธีที่ 2: จำลองนิ้วแตะกึ่งกลางปุ่มแบบเป๊ะๆ (ลบการชดเชย +36 ออก เพราะจอแต่ละคนทดไม่เหมือนกัน)
                        local cx = fireBtn.AbsolutePosition.X + (fireBtn.AbsoluteSize.X / 2)
                        local cy = fireBtn.AbsolutePosition.Y + (fireBtn.AbsoluteSize.Y / 2)
                        
                        local vim = game:GetService("VirtualInputManager")
                        vim:SendTouchEvent(15, 0, cx, cy) -- แตะลง
                        task.wait(0.05)
                        vim:SendTouchEvent(15, 2, cx, cy) -- ปล่อยนิ้ว
                    end
                end)
            end
            
            -- เปิดไฟพ่น
            local dragon = getActiveDragonModel()
            local breathR = dragon and dragon:FindFirstChild("Remotes") and dragon.Remotes:FindFirstChild("BreathFireRemote")
            local isMobile = game:GetService("UserInputService").TouchEnabled
            
            -- รีฟิลหลอดพ่นไฟให้เต็มก่อน (แก้บัคกดพ่นแล้วไม่ออกเพราะมานาหมด)
            if dragon then pcall(refillDragonBreathFuel, dragon) end
            
            if isMobile then
                toggleMobileFire() -- สั่งแตะปุ่ม UI 1 ครั้งเพื่อเปิดพ่นไฟ
            else
                if breathR then breathR:FireServer(true) end
            end
            
            -- 🌪️ ระบบหมุนควงสว่าน 360 องศา (X และ Y)
            unlockPlayerFromMonster() -- ปลดล็อคระบบเดิมก่อน
            local chestLocker = true
            local startSpinTime = os.clock()
            local spinConn = RunService.Heartbeat:Connect(function()
                if not chestLocker then return end
                local root = getRoot()
                if root then
                    -- คำนวณองศาการหมุนแบบพายุ (360 องศา)
                    local elapsed = os.clock() - startSpinTime
                    local spinX = elapsed * math.rad(360) * 3.0 -- ตีลังกา 3 รอบต่อseconds
                    local spinY = elapsed * math.rad(360) * 4.0 -- ควงสว่าน 4 รอบต่อseconds
                    
                    -- ลอยตัวเหนือหีบ 8 เมตร แล้วหมุนทุกทิศทาง
                    local rotCF = CFrame.new(chestPos + Vector3.new(0, 8, 0)) * CFrame.Angles(spinX, spinY, 0)
                    root.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                    root.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
                    root.CFrame = rotCF
                end
            end)
            
            local t = os.clock()
            while _G[flagKey] and nearest.Parent do
                local hp = hrp:FindFirstChild("Health")
                local dead = hrp:FindFirstChild("Dead")
                if (dead and dead.Value == true) or (hp and hp.Value <= 0) then break end
                
                if os.clock() - t > 5 then 
                    pcall(function() nearest:Destroy() end)
                    warn("⚠️ [Chest Finder] ข้ามหีบเนื่องจากบัค (ใช้เวลาเกิน 5 seconds)")
                    break 
                end
                
                -- รีฟิลเกจตลอดระหว่างตี
                if dragon then pcall(refillDragonBreathFuel, dragon) end
                
                -- โจมตี Backup: สำหรับ PC ให้ส่งเมาส์คลิกคลิกได้ไม่มีปัญหา
                -- แต่บนมือถือ ยกเลิกการจำลองจิ้มกลางจอ เพราะมันไปกวนการแตะหน้าจอ/กดปุ่ม UI รัวๆ
                pcall(function()
                    if not isMobile then
                        mouse1press()
                        task.wait(0.05)
                        mouse1release()
                    end
                end)
                task.wait(0.15)
            end
            
            -- หยุดหมุน 360 องศาเมื่อหีบพังเสร็จแล้ว
            chestLocker = false
            if spinConn then spinConn:Disconnect() spinConn = nil end
            
            -- ปิดไฟพ่น
            if isMobile then
                toggleMobileFire() -- สั่งแตะปุ่ม UI อีก 1 ครั้งเพื่อปิดพ่นไฟ
            else
                if breathR then breathR:FireServer(false) end
            end

            -- เปิดหีบเก็บของ
            local nodeID = tonumber(nearest.Parent and nearest.Parent.Name)
            if nodeID then
                pcall(function()
                    local OpenR = LP:WaitForChild("Remotes"):FindFirstChild("OpenChestRemote")
                    local TDropR = ReplicatedStorage.Remotes:FindFirstChild("TreasureChestDropsRemote")
                    if OpenR and TDropR then
                        local items = nil
                        local conn = TDropR.OnClientEvent:Connect(function(_, i) if typeof(i) == "table" then items = i end end)
                        OpenR:InvokeServer(nodeID, false)
                        local s = tick()
                        while not items and tick() - s < 2 do task.wait(0.05) end
                        conn:Disconnect()
                        local dataRef = nil
                        for _, folderName in ipairs({"TreasureChests", "EventTreasureChests"}) do
                            if dataRef then break end
                            local mainFolder = LP.Data:FindFirstChild(folderName)
                            if mainFolder then
                                for _, mapFolder in pairs(mainFolder:GetChildren()) do
                                    local ref = mapFolder:FindFirstChild(tostring(nodeID))
                                    if ref then dataRef = ref break end
                                end
                            end
                        end
                        if dataRef then
                            if items then
                                for idx, _ in pairs(items) do TDropR:FireServer(dataRef, idx) task.wait(0.05) end
                            else
                                for idx = 1, 4 do TDropR:FireServer(dataRef, idx) task.wait(0.05) end
                            end
                        end
                    end
                end)
            end
            found = found + 1
            showCenterWarning(false) -- เจอแล้ว ปิดคำเตือน
        else
            -- [[ 🧠 SMART SKIP: ไม่มีหีบในเซิร์ฟ → systemไปทำเควสอื่นก่อน ]]
            warn("📦 [Chest] ไม่พบหีบในเซิร์ฟตอนนี้ ข้ามไปทำเควสอื่นก่อน...")
            showCenterWarning(true, "⚠️ [กรุณารอหีบเกิด / Server กำลัง Refresh] ⚠️")
            task.wait(3) -- โชว์เตือนสักพัก
            showCenterWarning(false)
            return found -- คืนจำนวนที่เจอ (อาจเป็น 0) เพื่อให้ SmartLoop ทำเควสถัดไป
        end
        task.wait(1)
    end
    return found
end

-- ============================================================
-- [[ 🎮 UI ]]
-- ============================================================
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
local Window = Rayfield:CreateWindow({
    Name = "RUAJAD HUB",
    LoadingTitle = "Bug Fix Edition",
    LoadingSubtitle = "Portal-Safe Navigation",
    ConfigurationSaving = { Enabled = false },
    KeySystem = false
})

local MainTab = Window:CreateTab("Quest", 4483362458)
_G.AutoQuestOrigins = false
_G.AutoQuestGrassland = false
_G.AutoQuestJungle = false
_G.AutoQuestVolcano = false
_G.AutoQuestTundra = false
_G.AutoQuestOcean = false
_G.AutoQuestDesert = false
_G.AutoQuestFantasy = false
_G.AutoQuestShinrin = false
_G.AutoQuestPrehistoric = false
_G.AutoQuestWasteland = false

-- [[ 🎮 BOSS QUEUE AUTOMATION ]]
local vim = game:GetService("VirtualInputManager")
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local HitRemote = Remotes:FindFirstChild("ClientDestructibleHitRemote")

local function fastClick(obj)
    if not obj then return end
    pcall(function()
        if getconnections then
            for _, c in pairs(getconnections(obj.Activated)) do c:Fire() end
            for _, c in pairs(getconnections(obj.MouseButton1Click)) do c:Fire() end
        end
        local pos = obj.AbsolutePosition
        local size = obj.AbsoluteSize
        local center = pos + (size / 2)
        vim:SendMouseButtonEvent(center.X, center.Y + 36, 0, true, game, 0)
        task.wait(0.05)
        vim:SendMouseButtonEvent(center.X, center.Y + 36, 0, false, game, 0)
    end)
end

-- [[ 🌋 พิกัดบอสแต่ละโลก ]]
local BOSS_QUEUE_COORDS = {
    Default  = CFrame.new(-634.14, 165.47, 743.25, -0.866, 0.108, 0.488, 0.014, 0.981, -0.192, -0.500, -0.159, -0.851),
    Volcano  = CFrame.new(-1318.37, 178.56, -605.27, 1.000, 0.006, 0.010, -0.004, 0.984, -0.180, -0.011, 0.180, 0.984),
    Tundra   = CFrame.new(1461.48, 1629.44, 209.71, -0.493, -0.154, -0.856, -0.014, 0.985, -0.169, 0.870, -0.072, -0.488),
    Ocean    = CFrame.new(-240.35, -56.83, 1765.83, 0.665, 0.055, -0.745, -0.042, 0.998, 0.036, 0.746, 0.008, 0.666),
    Desert   = CFrame.new(2822.57, 1003.45, 1402.59, -0.305, -0.143, -0.942, -0.030, 0.990, -0.141, 0.952, -0.014, -0.306),
    Fantasy  = CFrame.new(-1242.81, 271.30, -551.95, 0.605, 0.134, 0.785, 0.012, 0.984, -0.178, -0.796, 0.117, 0.594),
    Wasteland = CFrame.new(-684.70, 226.54, -1229.74),
    Prehistoric = CFrame.new(-514.82, 750.51, -704.42, -0.488, 0.097, 0.867, -0.094, 0.982, -0.163, -0.868, -0.161, -0.471),
}

local currentBossWorld = "Default" -- จะถูกเซ็ตตอนเรียก killBoss จาก SmartLoop

local function joinBossQueue()
    local targetCF = BOSS_QUEUE_COORDS[currentBossWorld] or BOSS_QUEUE_COORDS.Default
    warn("🚀 [BossQueue] กำลังบินไปจุดรวมพล (" .. currentBossWorld .. ") พิกัด: " .. tostring(targetCF.Position))
    flyTo(targetCF)
    lockPlayerToMonster(targetCF, 0) -- ล็อคความสูงที่ 0 เมตร (แนบพื้น) เพื่อให้ GUI เด้ง
    task.wait(1.5)

    local pg = LP:FindFirstChild("PlayerGui")
    local bossGui = pg and pg:FindFirstChild("BossGui")
    local queueFrame = bossGui and bossGui:FindFirstChild("QueueFrame")
    if not queueFrame then 
        warn("⚠️ [BossQueue] ไม่พบป้ายคิวบอส!")
        unlockPlayerFromMonster()
        return false 
    end

    local function performClicks()
        local createBtn1 = queueFrame:FindFirstChild("ActiveFrame", true) 
            and queueFrame.ActiveFrame:FindFirstChild("CreateFrame")
            and queueFrame.ActiveFrame.CreateFrame:FindFirstChild("CreateButton")
        if createBtn1 and createBtn1.Visible then
            warn("🖱️ [BossQueue] คลิก Create (1/3)")
            fastClick(createBtn1)
            task.wait(1.5)
        end
        local createFrame = queueFrame:FindFirstChild("CreateFrame")
        if createFrame and createFrame.Visible then
            local createBtn2 = createFrame:FindFirstChild("CreateButton")
            if createBtn2 then
                warn("🖱️ [BossQueue] คลิก Create (2/3)")
                fastClick(createBtn2)
                task.wait(1.5)
            end
        end
        local currentFrame = queueFrame:FindFirstChild("CurrentFrame")
        if currentFrame and currentFrame.Visible then
            local startBtn = currentFrame:FindFirstChild("ButtonsFrame") and currentFrame.ButtonsFrame:FindFirstChild("Start")
            if startBtn then
                warn("🖱️ [BossQueue] คลิก Start (3/3)")
                fastClick(startBtn)
                task.wait(1.5)
                return true
            end
        end
        return false
    end
    local success = performClicks()
    unlockPlayerFromMonster()
    return success
end

local function killBoss(amount, flagKey)
    -- ปรับจูนแบบ conservative: ลดความถี่สแกน/ยิงเพื่อลดกระตุก แต่ยังคง flow เดิม
    local SEARCH_WAIT = 0.25
    local COMBAT_TICK = 0.45
    local MINION_SCAN_INTERVAL = 0.35
    local ENABLE_MINION_INTERRUPT = true
    local MINION_ENABLE_AFTER_BOSS_SECONDS = 15
    local MINION_DETECT_RADIUS = 250

    local killed = 0
    while killed < amount and _G[flagKey] do
        local myNameStr = LP.Name
        local bossInstances = workspace:FindFirstChild("Interactions") 
            and workspace.Interactions:FindFirstChild("Boss")
            and workspace.Interactions.Boss:FindFirstChild("BossInstances")
        local myArenaFolder = nil
        if bossInstances then
            for _, folder in pairs(bossInstances:GetChildren()) do
                if folder.Name:find(myNameStr) then myArenaFolder = folder break end
            end
        end
        if not myArenaFolder then
            warn("📢 [BossKiller] เริ่มขั้นตอนกดเข้าคิว...")
            local success = joinBossQueue()
            if success then task.wait(8) else task.wait(2) end
            continue
        end
        warn("🏟️ [BossKiller] บอสกำลังแสกนหาบอส: " .. myNameStr)
        local targetBoss = nil
        local scanStartTime = os.clock()
        local hoverLockApplied = false
        while _G[flagKey] and myArenaFolder and myArenaFolder.Parent ~= nil and not targetBoss and (os.clock() - scanStartTime < 60) do
            local activeBosses = workspace:FindFirstChild("ActiveBossModels")
            if activeBosses then
                for _, boss in pairs(activeBosses:GetChildren()) do
                    if boss:IsA("Model") and boss.Name:find(myNameStr) then targetBoss = boss break end
                end
            end
            if not targetBoss then
                -- ล็อคค้างครั้งเดียวพอ (ไม่ reconnect ทุก SEARCH_WAIT)
                if not hoverLockApplied then
                    local root = getRoot()
                    if root then
                        lockPlayerToMonster(CFrame.new(root.Position.X, root.Position.Y + 35, root.Position.Z))
                        hoverLockApplied = true
                    end
                end
                task.wait(SEARCH_WAIT) 
            end
        end
        if hoverLockApplied then unlockPlayerFromMonster() end
        if targetBoss then
            warn("🎯 [BossKiller] ล็อคเป้าสำเร็จ!")
            local dragon = getActiveDragonModel()
            if dragon and dragon:FindFirstChild("Remotes") then
                local breathR = dragon.Remotes:FindFirstChild("BreathFireRemote")
                local soundR = dragon.Remotes:FindFirstChild("PlaySoundRemote")
                if breathR then breathR:FireServer(true) end
                local targetPart = targetBoss:FindFirstChild("HumanoidRootPart") or targetBoss:FindFirstChild("HitboxPart") or targetBoss:FindFirstChildWhichIsA("BasePart")
                local lastMinionScan = 0
                local bossFightStart = os.clock()
                local hitPulse = 0
                local breathPulse = 0
                local currentLockTarget = nil
                local currentLockHeight = nil
                local function setCombatLock(nextTarget, nextHeight)
                    if not nextTarget then return end
                    if currentLockTarget ~= nextTarget or currentLockHeight ~= nextHeight then
                        lockPlayerToMonster(nextTarget, nextHeight)
                        currentLockTarget = nextTarget
                        currentLockHeight = nextHeight
                    end
                end
                while _G[flagKey] and myArenaFolder and myArenaFolder.Parent ~= nil and isTargetAlive(targetBoss) and targetPart do
                    -- ล็อคค้าง ไม่ reconnect ซ้ำทุกรอบลูป (ลดอาการกระตุกเป็นจังหวะ)
                    setCombatLock(targetPart, 30)

                    -- [[ 🛡️ ระบบสแกนหาลูกน้องแบบ throttle เพื่อลดภาระ CPU ]]
                    local minion = nil
                    local now = os.clock()
                    local minionInterruptActive = ENABLE_MINION_INTERRUPT and ((now - bossFightStart) >= MINION_ENABLE_AFTER_BOSS_SECONDS)
                    if minionInterruptActive then
                        if (now - lastMinionScan) >= MINION_SCAN_INTERVAL then
                            minion = findNearestPortalMinion(MINION_DETECT_RADIUS)
                            lastMinionScan = now
                        end
                    end
                    if minion then
                        -- [[ 🔗 CHAIN MODE: วาร์ปจากมอนไปมอนจนหมด แล้วค่อยsystemบอส ]]
                        warn("🛡️ [BossKiller] พบลูกน้อง! เข้าโหมดกวาดล้าง...")
                        while minion and _G[flagKey] and myArenaFolder and myArenaFolder.Parent ~= nil do
                            local mRoot = minion:FindFirstChild("HumanoidRootPart") or minion:FindFirstChildWhichIsA("BasePart")
                            if not mRoot then break end
                            
                            -- วาร์ปไปมอนตัวนี้ทันที
                            flyTo(mRoot.CFrame * CFrame.new(0, 12, 0))
                            setCombatLock(mRoot, 20)
                            
                            -- ตี 1.2 seconds
                            local minionStart = os.clock()
                            while _G[flagKey] and (os.clock() - minionStart < 1.2) do
                                local currentMRoot = minion:FindFirstChild("HumanoidRootPart") or minion:FindFirstChildWhichIsA("BasePart")
                                if not currentMRoot then break end
                                
                                refillDragonBreathFuel(dragon)
                                hitPulse = (hitPulse + 1) % 2
                                breathPulse = (breathPulse + 1) % 3
                                if breathR and breathPulse == 0 then breathR:FireServer(true) end
                                if soundR then
                                    soundR:FireServer("Breath", "Mobs", currentMRoot)
                                    if HitRemote and hitPulse == 0 then HitRemote:FireServer(currentMRoot) end
                                end
                                task.wait(0.2)
                            end
                            
                            -- สแกนหามอนตัวถัดไปทันที (ไม่systemบอส)
                            minion = findNearestPortalMinion(MINION_DETECT_RADIUS)
                        end
                        
                        -- หมดมอนแล้ว systemมาล็อคบอส
                        warn("✅ [BossKiller] กวาดลูกน้องหมด! systemตีบอส...")
                        if targetPart and targetPart.Parent then
                            setCombatLock(targetPart, 30)
                        end
                    else
                        refillDragonBreathFuel(dragon)
                        hitPulse = (hitPulse + 1) % 2
                        breathPulse = (breathPulse + 1) % 3
                        if breathR and breathPulse == 0 then breathR:FireServer(true) end
                        if soundR then 
                            soundR:FireServer("Breath", "Bosses", targetPart)
                            -- [[ 👊 ดาเมจเสริมไม่สนมานา ]]
                            if HitRemote and hitPulse == 0 then HitRemote:FireServer(targetPart) end
                        end
                        task.wait(COMBAT_TICK)
                    end
                end
                unlockPlayer()
                if breathR then breathR:FireServer(false) end
            end
            killed = killed + 1
            
        else
            killed = killed + 1
        end
        task.wait(1)
    end
end

-- ============================================================
-- [[ 🧠 UNIVERSAL SMART QUEST ENGINE v3 ]]
-- สมองกลางคุมทุกโลก: ปักหมุดอัตโนมัติ, จัดลำดับความสำคัญ, และล่าบอส
-- ============================================================

local function getPinnedQuests(worldName)
    local pg = LP:FindFirstChild("PlayerGui")
    if not pg then return {} end
    local hudGui = pg:FindFirstChild("HUDGui")
    local missionsFrame = hudGui and hudGui:FindFirstChild("MissionsFrame")
    if not missionsFrame then return {} end
    
    local pinned = {}
    for _, desc in ipairs(missionsFrame:GetDescendants()) do
        if desc:IsA("Frame") or desc:IsA("ImageButton") then
             for _, qName in ipairs({"EggQuest", "TreasureChest", "KillMobs", "Harvest", "KillBoss", "RidingRing", "Boss"}) do
                 if desc.Name:find(qName) then
                    -- กรองโลก: เช็คว่าชื่อ Frame มีชื่อโลกกำกับ (เช่น EggQuestLobby, KillMobsOcean)
                    local belongsToWorld = (not worldName) or desc.Name:find(worldName)
                    
    -- ☢️ Wasteland/Toxic/Prehistoric/Shinrin Fallback: เฉพาะโลก Wasteland/Wastelands/Toxic/Prehistoric/Shinrin เท่านั้น
    -- ถ้าหาชื่อโลกในชื่อ Frame ไม่เจอ ให้รับ Frame ที่ไม่มีชื่อโลกอื่นปนอยู่
    if not belongsToWorld and (worldName == "Wasteland" or worldName == "Wastelands" or worldName == "Toxic" or worldName == "Prehistoric" or worldName == "Shinrin") then
        local otherWorlds = {"Lobby", "Origins", "Grassland", "Jungle", "Volcano", "Tundra", "Ocean", "Desert", "Fantasy"}
        local isOther = false
        for _, w in ipairs(otherWorlds) do if desc.Name:find(w) then isOther = true break end end
        if not isOther then belongsToWorld = true end
    end
                    
                    if belongsToWorld then
                        local key = (qName == "Boss") and "KillBoss" or qName
                        pinned[key] = true
                    end
                 end
             end
        end
    end
    return pinned
end

local function runUniversalSmartLoop(displayName, internalName, flagKey)
    warn("======== 🚀 เริ่มระบบ Smart Loop: " .. displayName .. " ========")
    
    local heartbeatCount = 0
    local forceRetrack = false -- สัญญาณสั่งปักหมุดใหม่ถ้าทางตัน
    
    while _G[flagKey] do
        heartbeatCount = heartbeatCount + 1
        if heartbeatCount % 5 == 0 then warn("💓 [SmartLoop:" .. displayName .. "] กำลังตรวจสอบ HUD...") end
        
        local pinned = getPinnedQuests(internalName)
        local hasAnyPinned = false
        for _ in pairs(pinned) do hasAnyPinned = true break end
        
        -- [[ 📌 1. ระบบปักหมุดอัตโนมัติ (Auto-Pinning) ]]
        -- บังคับปักหมุดใหม่ถ้า: 1.หน้าจอว่างเปล่า 2.เควสเดิมทำไม่ได้ (Force)
        if not hasAnyPinned or forceRetrack then
             local isForceRetrack = forceRetrack
             forceRetrack = false
             warn("📌 [AutoTrack] หน้าจอว่างเปล่า! กำลังค้นหาเควสใน " .. displayName)
             -- ลำดับความสำคัญ: บอส > ไข่ > หีบ > มอน > เก็บเกี่ยว > ห่วง
             local questOrder = {"KillBoss", "EggQuest", "TreasureChest", "KillMobs", "Harvest", "RidingRing"}
             for _, q in ipairs(questOrder) do
                 -- 🧠 ถ้า forceRetrack (เควสเดิมทำไม่ได้) ให้ข้ามเควสที่ปักอยู่แล้ว ไปปักตัวใหม่แทน
                 if isForceRetrack and pinned[q] then
                     warn("⏭️ [AutoTrack] ข้าม " .. q .. " (ปักอยู่แล้วแต่ทำไม่ได้)")
                 else
                     trackQuest(q, internalName)
                     -- ใช้ Delay 1.5 seconds เท่ากันทุกโลกตามความต้องการของผู้ใช้
                     task.wait(1.5)
                     local checkPinned = getPinnedQuests(internalName)
                     if checkPinned[q] then 
                         hasAnyPinned = true
                         pinned = checkPinned
                         break 
                     end
                 end
             end
             
             if not hasAnyPinned then
                 warn("✅ [SmartLoop] เคลียร์ทุกเควสใน " .. displayName .. " จบแล้ว!")
                 break
             end
        end
        
        -- [[ ⚔️ 2. ระบบรันเควสตามหมุด (Execution) ]]
        local didWork = false
        
        -- 👹 บอส (Priority 1)
        if pinned["KillBoss"] and _G[flagKey] then
             local need = getQuestRemaining("KillBoss", internalName)
             if need > 0 then 
                 warn("👹 [" .. displayName .. "] พบบอส! เข้าจัดการ...")
                -- เซ็ตพิกัดบอส ตามโลกที่กำลังเล่น
                if internalName == "Volcano" then currentBossWorld = "Volcano"
                elseif internalName == "Tundra" then currentBossWorld = "Tundra"
                elseif internalName == "Ocean" then currentBossWorld = "Ocean"
                elseif internalName == "Desert" then currentBossWorld = "Desert"
                elseif internalName == "Fantasy" then currentBossWorld = "Fantasy"
                elseif internalName == "Wasteland" or internalName == "Toxic" then currentBossWorld = "Wasteland"
                elseif internalName == "Prehistoric" then currentBossWorld = "Prehistoric"
                else currentBossWorld = "Default" end
                
                warn("🚀 [BossQueue] ใช้พิกัดโลก: " .. currentBossWorld)
                killBoss(need, flagKey)
                 didWork = true 
             end
        end
        
        -- 🥚 เก็บไข่
        if pinned["EggQuest"] and _G[flagKey] and not didWork then
             local need = getQuestRemaining("EggQuest", internalName)
             if need > 0 then 
                 warn("🥚 [" .. displayName .. "] เก็บไข่อีก " .. need .. " ฟอง")
                 collectEggs(need, flagKey, internalName) 
                 didWork = true 
             end
        end
        
        -- 💍 ลอดห่วง (เฉพาะ Origins/Event)
        if pinned["RidingRing"] and _G[flagKey] and not didWork then
             local need = getQuestRemaining("RidingRing", internalName)
             if need > 0 then 
                 warn("💍 [" .. displayName .. "] ลอดห่วงอีก " .. need .. " ห่วง")
                 flyRings(need, flagKey) 
                 didWork = true 
             end
        end

        -- 📦 หีบสมบัติ (Smart Skip: ถ้าไม่เจอหีบจะข้ามไปเควสถัดไป)
        local chestSkipFallback = false
        if pinned["TreasureChest"] and _G[flagKey] and not didWork then
             local need = getQuestRemaining("TreasureChest", internalName)
             if need > 0 then 
                 warn("📦 [" .. displayName .. "] เปิดหีบอีก " .. need .. " ใบ")
                 local chestFound = findChests(need, flagKey, internalName) or 0
                 if chestFound > 0 then
                     didWork = true -- เจอหีบแล้วตี → ถือว่าทำงานแล้ว
                 else
                     warn("📦 [" .. displayName .. "] ไม่มีหีบ! ข้ามไปเควสถัดไป...")
                     chestSkipFallback = true -- 🧠 สัญญาณ: ลองทำเควสอื่นแม้ไม่ได้ปักหมุด
                 end
             end
        end
        
        -- ⚔️ ฆ่ามอน
        if (pinned["KillMobs"] or chestSkipFallback) and _G[flagKey] and not didWork then
             -- 🧠 ถ้ายังไม่ได้ปักหมุด ลองปักแล้วรอนานขึ้น
             if not pinned["KillMobs"] and chestSkipFallback then
                 trackQuest("KillMobs", internalName)
                 task.wait(1.5)
             end
             local need = getQuestRemaining("KillMobs", internalName)
             if need > 0 then 
                 warn("⚔️ [" .. displayName .. "] ฆ่ามอนอีก " .. need .. " ตัว")
                 killMobs(need, flagKey, internalName) 
                 didWork = true 
             end
        end
        
        -- 🍎 เก็บเกี่ยว
        if (pinned["Harvest"] or chestSkipFallback) and _G[flagKey] and not didWork then
             -- 🧠 ถ้ายังไม่ได้ปักหมุด ลองปักแล้วรอนานขึ้น
             if not pinned["Harvest"] and chestSkipFallback then
                 trackQuest("Harvest", internalName)
                 task.wait(1.5)
             end
             local need = getQuestRemaining("Harvest", internalName)
             if need > 0 then 
                 warn("🍎 [" .. displayName .. "] เก็บเกี่ยวอีก " .. need .. " อัน")
                 harvestResources(need, flagKey, internalName) 
                 didWork = true 
             end
        end
        
        if not didWork then 
            -- ถ้าพยายามรันทุกหมุดแล้วแต่ทำไม่ได้เลย (เช่น มอนไม่เกิด/ไข่ไม่มี) ให้สั่ง Re-track
            if hasAnyPinned then forceRetrack = true end
            task.wait(0.5) 
        end
        task.wait(0.2)
    end
    
    warn("======== 🏁 จบ Smart Loop: " .. displayName .. " ========")
    _G[flagKey] = false
    setPhysics(false)
end

local function runOriginsQuest()
    runUniversalSmartLoop("Origins", "Lobby", "AutoQuestOrigins")
end

local function runGrasslandQuest()
    runUniversalSmartLoop("Grassland", "Grassland", "AutoQuestGrassland")
end

local function runJungleQuest()
    runUniversalSmartLoop("Jungle", "Jungle", "AutoQuestJungle")
end

local function runVolcanoQuest()
    runUniversalSmartLoop("Volcano", "Volcano", "AutoQuestVolcano")
end

local function runTundraQuest()
    runUniversalSmartLoop("Tundra", "Tundra", "AutoQuestTundra")
end

local function runOceanQuest()
    runUniversalSmartLoop("Ocean", "Ocean", "AutoQuestOcean")
end

local function runDesertQuest()
    runUniversalSmartLoop("Desert", "Desert", "AutoQuestDesert")
end

local function runFantasyQuest()
    runUniversalSmartLoop("Fantasy", "Fantasy", "AutoQuestFantasy")
end

local function runShinrinQuest()
    runUniversalSmartLoop("Shinrin", "Shinrin", "AutoQuestShinrin")
end

local function runPrehistoricQuest()
    -- 🛡️ Prehistoric Special: รอโหลด HUD ให้ครบ 6 ตัวก่อนเริ่มทำงาน เพื่อป้องกันปัญหาปักหมุดไม่ได้
    warn("⏳ [Prehistoric] กำลังรอโหลด HUD Missions...")
    task.wait(3)
    runUniversalSmartLoop("Prehistoric", "Prehistoric", "AutoQuestPrehistoric")
end

local function runWastelandQuest()
    -- ใช้ "Toxic" ตามที่สแกนได้จาก Remote Log ของผู้ใช้ (อัปเดตล่าสุด)
    runUniversalSmartLoop("Wasteland", "Toxic", "AutoQuestWasteland")
end

-- ============================================================
-- [[ 🔥 GLOBAL INFINITE BREATH (AUTO FARM CORE) ]]
-- เติมพ่นไฟอัตโนมัติทุกโหมดฟาร์ม (Origins/Grassland/Jungle)
-- ============================================================
local function isAnyAutoFarmEnabled()
    return _G.AutoQuestOrigins or _G.AutoQuestGrassland or _G.AutoQuestJungle or _G.AutoQuestVolcano or _G.AutoQuestTundra or _G.AutoQuestOcean or _G.AutoQuestDesert or _G.AutoQuestFantasy or _G.AutoQuestShinrin or _G.AutoQuestPrehistoric or _G.AutoQuestWasteland
end

_G.AutoAntiHitWhileFarm = true

local function isAntiHitActive()
    return _G.GodMode or _G.GhostMode or (_G.AutoAntiHitWhileFarm and isAnyAutoFarmEnabled())
end

-- ============================================================
-- [[ 📷 HARD CAMERA LOCK FIX - แก้กล้องตก/สั่นตอนบิน Tween ]]
-- ============================================================
local cameraLockConnection = nil
local cameraHardLockEnabled = false

local function applyHardCameraLock()
    if cameraLockConnection then return end
    cameraHardLockEnabled = true
    
    -- ปิด AutoRotate ทั้งคนและมังกร
    pcall(function()
        local char = LP.Character
        local dragon = getActiveDragonModel()
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then hum.AutoRotate = false end
        end
        if dragon then
            local hum = dragon:FindFirstChildOfClass("Humanoid")
            if hum then hum.AutoRotate = false end
        end
    end)

    -- ล็อกกล้องทุกเฟรม Heartbeat (60 ครั้ง/seconds) ไม่มีช่องว่างเลย
    cameraLockConnection = RunService.Heartbeat:Connect(function()
        if not cameraHardLockEnabled then return end
        pcall(function()
            local cam = workspace.CurrentCamera
            local dragon = getActiveDragonModel()
            local char = LP.Character
            
            local targetHum = nil
            if dragon then targetHum = dragon:FindFirstChildOfClass("Humanoid") end
            if not targetHum and char then targetHum = char:FindFirstChildOfClass("Humanoid") end
            
            if targetHum then
                -- Force Lock ไม่สนเกมจะเปลี่ยนอะไร
                cam.CameraSubject = targetHum
                cam.CameraType = Enum.CameraType.Follow
                
                -- ป้องกันการสั่นระหว่าง Tween
                if cam.CFrame.p.Y < 10 then
                    cam.FieldOfView = 70
                end
            end
        end)
    end)
end

local function disableHardCameraLock()
    cameraHardLockEnabled = false
    if cameraLockConnection then
        cameraLockConnection:Disconnect()
        cameraLockConnection = nil
    end
    
    -- คืนค่า AutoRotate systemเป็นปกติ
    pcall(function()
        local char = LP.Character
        local dragon = getActiveDragonModel()
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then hum.AutoRotate = true end
        end
        if dragon then
            local hum = dragon:FindFirstChildOfClass("Humanoid")
            if hum then hum.AutoRotate = true end
        end
    end)
end

-- ============================================================
-- [[ ✈️ FIX TWEEN SHAKE - แก้อาการสั่นตอนเคลื่อนที่ ]]
-- ============================================================
-- ⚠️ Mobile-Safe: ข้าม __newindex hook บนมือถือเด็ดขาด!
-- เหตุผล: Mobile executor (Delta/Fluxus) มีบัคเรื่อง hookmetamethod(__newindex)
-- ทำให้ property writes ของเกมหายไปเงียบๆ → Dragon Fire Breath พัง 100%
-- PC ไม่มีปัญหานี้ จึงยังคงใช้ hook ได้ตามปกติ
if not _isMobileDevice then
    local oldNewIndex
    oldNewIndex = hookmetamethod(game, "__newindex", newcclosure(function(self, idx, val)
        if cameraHardLockEnabled and idx == "CameraSubject" and not checkcaller() then
            if self == workspace.CurrentCamera then
                return nil 
            end
        end
        return oldNewIndex(self, idx, val)
    end))
    warn("✈️ [PC] __newindex hook installed (camera lock)")
else
    warn("📱 [Mobile] __newindex hook SKIPPED (fire breath protection)")
end

-- ============================================================
-- [[ 🛡️ GHOST MODE 3.0: HEARTBEAT-DRIVEN INVINCIBILITY ]]
-- ทำงานทุกเฟรม (~60fps) ไม่มีช่องว่างให้ดาเมจเข้าได้เลย
-- ============================================================
local antiHitApplied = false
local ghostHeartbeatConnection = nil
 local lastBreathRefill = 0
 
 local function startGhostHeartbeat()
     if ghostHeartbeatConnection then return end
     ghostHeartbeatConnection = RunService.Heartbeat:Connect(function()
         pcall(function()
             -- [[ 👻 GHOST PHYSICS: ปิด CanTouch/CanQuery ทุกเฟรม (~60fps) ]]
             applyGhostPhysicsStep()
 
             -- [[ 🩸 INSTANT HEAL (Humanoid): เติมเลือดโมเดลทุกเฟรม แบบเช็คก่อนเขียน (กันบัคกดยกเลิกในมือถือ) ]]
             local char = LP.Character
             local p_hum = char and char:FindFirstChildOfClass("Humanoid")
             if p_hum and p_hum.Health < p_hum.MaxHealth then p_hum.Health = p_hum.MaxHealth end
 
             local dragonModel = getActiveDragonModel()
             local d_hum = dragonModel and dragonModel:FindFirstChildOfClass("Humanoid")
             if d_hum and d_hum.Health < d_hum.MaxHealth then d_hum.Health = d_hum.MaxHealth end
 
             -- [[ 🛡️ ULTIMATE DATA HEAL (Anti-Boss): กันบอสตีเข้าเลือดจริง ]]
             local data = LP:FindFirstChild("Data")
             if data then
                 local dragonsData = data:FindFirstChild("Dragons")
                 if dragonsData then
                     for _, dFolder in pairs(dragonsData:GetChildren()) do
                         local h = dFolder:FindFirstChild("Health")
                         local mh = dFolder:FindFirstChild("MaxHealth")
                         if h and mh and h:IsA("ValueBase") and mh:IsA("ValueBase") and h.Value < mh.Value then 
                             h.Value = mh.Value 
                         end
                     end
                 end
                 local stats = data:FindFirstChild("Stats")
                 if stats then
                     local h = stats:FindFirstChild("Health")
                     local mh = stats:FindFirstChild("MaxHealth")
                     if h and mh and h:IsA("ValueBase") and mh:IsA("ValueBase") and h.Value < mh.Value then 
                         h.Value = mh.Value 
                     end
                 end
             end
             -- ⚠️ ถอดระบบ "รีฟิลพ่นไฟถาวรทุกๆ 0.5 วินาที" ออกจาก Ghost Mode
             -- เพราะการยัดหลอดพ่นไฟให้เต็มรัวๆ มันไปรีเซ็ต UI ของมือถือ ทำให้เวลากดปุ่มพ่นค้างไว้ เกมจะสั่งยกเลิกเองรัวๆ
             -- (ระบบ Auto Farm หีบ จะรีฟิลหลอดไฟก่อนพ่นด้วยตัวเองอยู่แล้ว ไม่ต้องให้ Ghost รีฟิลให้)
         end)
     end)
 end

local function stopGhostHeartbeat()
    if ghostHeartbeatConnection then
        ghostHeartbeatConnection:Disconnect()
        ghostHeartbeatConnection = nil
    end
end

-- ตัวเช็คสถานะ on/off (ไม่ต้องไว เช็คทุก 0.5 secondsพอ)
task.spawn(function()
    while true do
        local active = isAntiHitActive()
        if active ~= antiHitApplied then
            if active then
                applyHardCameraLock()
                startGhostHeartbeat()
                warn("🛡️ [Ghost 3.0] Heartbeat Protection ACTIVE (60fps)")
            else
                stopGhostHeartbeat()
                disableHardCameraLock()
                -- ⚠️ ยกเลิกการบังคับเขียน CanCollide=true ทับทั้งโมเดลมังกรและคน!
                -- การบังคับทำ CanCollide=true ในชิ้นส่วนที่ควรมองไม่เห็น (Hitbox) ทำให้มังกรบัคตัวแข็ง
                
                -- แค่เคลียร์แคช เพื่อให้ตอนเปิดโหมด Ghost ใหม่มันดึงตารางชิ้นส่วนใหม่
                pcall(function()
                    noclipCacheChar = nil
                    noclipCacheDragon = nil
                end)
                warn("🛡️ [Ghost 3.0] Heartbeat Protection DISABLED")
            end
            antiHitApplied = active
        end
        task.wait(0.5)
    end
end)

_G.GhostMode = false

MainTab:CreateToggle({
    Name = "👻 Ghost Mode (Entity Bypass)",
    CurrentValue = false,
    Flag = "GhostModeToggle",
    Callback = function(Value)
        _G.GhostMode = Value
    end,
})

QuestToggles.Origins = MainTab:CreateToggle({
    Name = "🏠 Autoquest Original word",
    CurrentValue = false,
    Flag = "OriginsToggle",
    Callback = function(Value)
        _G.AutoQuestOrigins = Value
        if Value then task.spawn(runOriginsQuest) end
    end,
})

QuestToggles.Grassland = MainTab:CreateToggle({
    Name = "🌱 Autoquest Grass land word",
    CurrentValue = false,
    Flag = "GrasslandToggle",
    Callback = function(Value)
        _G.AutoQuestGrassland = Value
        if Value then task.spawn(runGrasslandQuest) end
    end,
})

QuestToggles.Jungle = MainTab:CreateToggle({
    Name = "🌴 Autoquest Jungle word",
    CurrentValue = false,
    Flag = "JungleToggle",
    Callback = function(Value)
        _G.AutoQuestJungle = Value
        if Value then task.spawn(runJungleQuest) end
    end,
})

QuestToggles.Volcano = MainTab:CreateToggle({
    Name = "🌋 Autoquest Volcano word",
    CurrentValue = false,
    Flag = "VolcanoToggle",
    Callback = function(Value)
        _G.AutoQuestVolcano = Value
        if Value then task.spawn(runVolcanoQuest) end
    end,
})

QuestToggles.Tundra = MainTab:CreateToggle({
    Name = "❄️ Autoquest Tundra word",
    CurrentValue = false,
    Flag = "TundraToggle",
    Callback = function(Value)
        _G.AutoQuestTundra = Value
        if Value then task.spawn(runTundraQuest) end
    end,
})

QuestToggles.Ocean = MainTab:CreateToggle({
    Name = "🌊 Autoquest Ocean word",
    CurrentValue = false,
    Flag = "OceanToggle",
    Callback = function(Value)
        _G.AutoQuestOcean = Value
        if Value then task.spawn(runOceanQuest) end
    end,
})

QuestToggles.Desert = MainTab:CreateToggle({
    Name = "🏜️ Autoquest Desert word",
    CurrentValue = false,
    Flag = "DesertToggle",
    Callback = function(Value)
        _G.AutoQuestDesert = Value
        if Value then task.spawn(runDesertQuest) end
    end,
})

QuestToggles.Fantasy = MainTab:CreateToggle({
    Name = "✨ Autoquest Fantasy word",
    CurrentValue = false,
    Flag = "FantasyToggle",
    Callback = function(Value)
        _G.AutoQuestFantasy = Value
        if Value then task.spawn(runFantasyQuest) end
    end,
})

QuestToggles.Wasteland = MainTab:CreateToggle({
    Name = "☢️ Autoquest Wasteland word",
    CurrentValue = false,
    Flag = "WastelandToggle",
    Callback = function(Value)
        _G.AutoQuestWasteland = Value
        if Value then task.spawn(runWastelandQuest) end
    end,
})

QuestToggles.Prehistoric = MainTab:CreateToggle({
    Name = "🦖 Autoquest Prehistoric word",
    CurrentValue = false,
    Flag = "PrehistoricToggle",
    Callback = function(Value)
        _G.AutoQuestPrehistoric = Value
        if Value then task.spawn(runPrehistoricQuest) end
    end,
})

QuestToggles.Shinrin = MainTab:CreateToggle({
    Name = "🌿 Autoquest Shinrin word",
    CurrentValue = false,
    Flag = "ShinrinToggle",
    Callback = function(Value)
        _G.AutoQuestShinrin = Value
        if Value then task.spawn(runShinrinQuest) end
    end,
})

-- ============================================================
-- [[ 🌍 WORLD TELEPORT SYSTEM (DYNAMIC AUTO-FETCH) ]]
-- ============================================================
local TeleportTab = Window:CreateTab("🌍 Teleport", 4483362458)
TeleportTab:CreateSection("Instant World Teleport")

task.spawn(function()
    -- ใช้ข้อมูลที่รวบรวมมาโดยตรง เพื่อความแม่นยำและรวดเร็วที่สุด
    local manualWorlds = {
        {Name = "🏠 Original / Lobby", ID = 3475422608},
        {Name = "🌱 Grasslands", ID = 3475419198},
        {Name = "🌴 Jungle", ID = 3475422608},
        {Name = "🌋 Volcano", ID = 3487210751},
        {Name = "❄️ Tundra", ID = 3623549100},
        {Name = "🌊 Ocean", ID = 3737848045},
        {Name = "🏜️ Desert", ID = 3752680052},
        {Name = "✨ Fantasy", ID = 4174118306},
        {Name = "☢️ Wasteland", ID = 4728805070},
        {Name = "🦖 Prehistoric", ID = 4869039553},
        {Name = "🌿 Shinrin", ID = 125804922932357},
    }

    TeleportTab:CreateSection("Instant World Teleport")

    for _, world in ipairs(manualWorlds) do
        TeleportTab:CreateButton({
            Name = "Teleport to: " .. world.Name,
            Callback = function()
                local tpRemote = ReplicatedStorage:WaitForChild("Remotes"):FindFirstChild("WorldTeleportRemote")
                if tpRemote then
                    Rayfield:Notify({
                        Title = "Warp Active", 
                        Content = "กำลังวาร์ปทะลุมิติไป " .. world.Name .. "...", 
                        Duration = 3
                    })
                    tpRemote:InvokeServer(world.ID, {})
                else
                    Rayfield:Notify({
                        Title = "Error", 
                        Content = "ไม่พบ Remote วาร์ป!", 
                        Duration = 3
                    })
                end
            end,
        })
    end
end)

Rayfield:Notify({Title = "RUAJAD HUB", Content = "Loot-Friendly Ghost Mode & Auto-Loot Active!", Duration = 5})

-- ============================================================
-- [[ 💰 AUTO-LOOT SYSTEM: ดูดของออโต้ทันทีที่ดรอป ]]
-- ============================================================
task.spawn(function()
    local remotes = ReplicatedStorage:WaitForChild("Remotes")
    
    local dropsRemote = remotes:FindFirstChild("MobDropsRemote")
    if dropsRemote then
        dropsRemote.OnClientEvent:Connect(function(mobFolder, dropsTable)
            if _G.GhostMode and dropsTable then
                for index, _ in pairs(dropsTable) do
                    dropsRemote:FireServer(mobFolder, index)
                end
            end
        end)
    end
end) 
