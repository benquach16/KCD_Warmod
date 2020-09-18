-- Constant struct
WarConstants = {
    cSaveLockName = "warmodsavelock",
    cMarshalName = "warmodmarshal",
    rat_side = 1,
    cuman_side = 2,
    troopCost = 100,
    numWaves = 8,
    corpseTime = 5000, --5 seconds
    victoryTime = 20000, -- 30 seconds
    waveInterval = 75000, -- 75 seconds
    campMesh = "objects/structures/tent_cuman/tent_cuman_v6_b.cgf"
}

WarRewards = {
    base = 250,
    perWave = 150,
    perKill = 4,
}

WarTroopTypes = {
    commander = 0,
    knight = 1,
    halberd = 2,
    aux = 3,
    bow = 4,
    halberd_light = 5,
    aux_light = 6
}

BattleTypes = {
    Attack = 0,
    Defend = 1,
    Field = 2,
    Ambush = 3
}

WarGuids = {
    knight = {},
    halberd = {},
    aux = {}
}

WarGuids[WarTroopTypes.knight] = {}
WarGuids[WarTroopTypes.knight][WarConstants.rat_side] = "41429725-5368-3cb1-6440-2e2e02b4fc97"
WarGuids[WarTroopTypes.knight][WarConstants.cuman_side] = "49c00005-e5e9-ee50-7370-8bc12c8ad29f"
WarGuids[WarTroopTypes.halberd] = {}
WarGuids[WarTroopTypes.halberd][WarConstants.rat_side] = "43b48356-ecf4-5e6e-bce4-1d98ed745baa"
WarGuids[WarTroopTypes.halberd][WarConstants.cuman_side] = "4957c994-1489-f528-130c-a00b9838a4a5"
WarGuids[WarTroopTypes.aux] = {}
WarGuids[WarTroopTypes.aux][WarConstants.rat_side] = "4aa17e70-525a-1e83-d32f-adf2f8c60daf"
WarGuids[WarTroopTypes.aux][WarConstants.cuman_side] = "4c4f6e9d-aa80-4f1b-a9d9-62573e6de2a7"

WarLocations = {
    {
        center = {x = 3136.570,y= 854.815,z= 122.557}, rat = {x = 2995.868,y = 809.014,z = 113.108}, cuman = {x = 3136.570,y= 854.815,z= 122.557}, camp = { x = 2979.425, y = 801.855, z = 110.145 },
        name="Rattay Farmhouse",
        resourceNode = false,
        influence = 8,
    },
    {
        center = {x = 2145.845,y= 967.7307,z= 76.2557}, rat = {x = 2242.227,y = 925.3737,z = 77.3386}, cuman = {x = 2037.570,y= 956.5421,z= 71.7819}, camp = { x = 2264.966, y = 917.7789, z = 76.3017 },
        name="Ledetchko Encampment",
        resourceNode = false,
        influence = 5,
    },
    {
        center = {x = 657.9334,y= 1478.049,z= 47.2376}, rat = {x = 745.2598,y = 1542.538,z = 45.724}, cuman = {x = 606.0286,y= 1462.844,z= 45.5769 }, camp = { x = 762.5239, y = 1541.537, z = 42.3058 },
        name="Sasau Outskirts",
        resourceNode = false,
        influence = 9,
    }
}

-- If your Regional Influence gets too low, enemy starts doing raids on towns and cities
WarRaidLocations = {
    {
        target = { x = 20, y = 20, z = 20 },
        start = { x = 30, y = 30, z = 20 },
        name = "Rattay"
    }
}

WarLocationstest = {
    {center = { x=47.969, y=43.522, z=33.583}, rat = { x=27.969, y=43.522, z=33.583}, cuman = { x=67.969, y=43.522, z=33.583}, name="Test battleground"}
}

Side = {
    strength = 500,
    money = 100000,
    controlledLocations = {}
}

Battle = {
    center = nil,
    rat_point = nil,
    cuman_point = nil,
    locations = nil,
    
    wavesleft = WarConstants.numWaves,
    rattayStrengthPerWave = 4, -- temp
    cumanStrengthPerWave = 6, -- temp
    rattayTroops = {},
    cumanTroops = {},
    
    troops = {},
    numCuman = 0,
    numRattay = 0,
    
    kills = 0,
    
    ratCommander = nil,
    cumanCommander = nil
}

WarController = {
    Rattay = Side,
    Cuman = Side,
    needReload = false,
    -- only 1 battle can occur at a time
    inBattle = false,
    readyForNewBattle = true,
    currentBattle = Battle,
    nextBattleLocation = nil,
    -- in gametime
    timeBattleStarted = 0, 
    -- try not to repeat the same location multiple times
    -- misnomer because its really a key
    ignoreLocationIdx = -1,
    marshal = nil,
    warcamp = nil,
    regionalInfluence = 50,
    
}

function WarController:OnSpawn()
    -- needed for OnUpdate callback
    self:Activate(1)
end

function WarController:UpdateStatus()
    message = "<font color='#FF3333' size='28'>Cuman War Status\n\n</font>"
    message = message .. "<font color='#333333' size='23'>Boehemian Strength: " .. tostring(WarController.Rattay.strength) .. "\n"
    message = message .. "Boehemian Treasury: " .. tostring(WarController.Rattay.money) .. "\n"
    message = message .. "Cuman Strength: " .. tostring(WarController.Cuman.strength) .. "\n"
    message = message .. "Cuman Treasury: " .. tostring(WarController.Cuman.money) .. "\n</font>"
    Game.ShowTutorial(message, 20, false, true)
end

function WarController:OnDestroy()
    self:ResetBattle()
    
    self.ClearTroops(self)
end

function WarController:DestroyMarshal()
    if self.marshal ~= nil then
        System.LogAlways("attempting to kill marshal")
        self.marshal.soul:DealDamage(200,200)
        self.marshal:DestroyPhysics();
        System.RemoveEntity(self.marshal.id)
        System.RemoveEntity(self.warcamp.id)
        self.marshal = nil
        self.warcamp = nil
    end
end

function WarController:OnSave(table)
    --this should be easy because all troops and entities should be cleared before any save action
    table.marshal = self.marshal:GetGUID()
    table.warcamp = self.warcamp:GetGUID()
    -- reuse this to index on load due to table shallow copy issues
    table.ignoreLocationIdx = self.ignoreLocationIdx
    table.regionalInfluence = self.regionalInfluence
end

function WarController:OnLoad(table)
    self.marshal = System.GetEntityByGUID(table.marshal)
    self.warcamp = System.GetEntityByGUID(table.warcamp)
    if self.warcamp ~= nil then
        self.warcamp:LoadObject(0, WarConstants.campMesh)
    end
    
    self.ignoreLocationIdx = table.ignoreLocationIdx
    self.nextBattleLocation = WarLocations[self.ignoreLocationIdx]
    self.regionalInfluence = table.regionalInfluence
    
    self.needReload = true
end

function getrandomposnear(position, radius)
    -- deep copy
    local ret = {}
    ret.x = position.x
    ret.y = position.y
    ret.z = position.z
    if radius > 0 then
        ret.x = position.x + math.random() - math.random() + math.random(0, radius) - math.random(0, radius)
        ret.y = position.y + math.random() - math.random() + math.random(0, radius) - math.random(0, radius)
    end
    return ret
end

-- This should only be called at the end of a battle, so we can safely reset here
function WarController.ClearTroops(self)
    if self.currentBattle.ratCommander ~= nil then
        self.RemoveCorpse(self.currentBattle.ratCommander)
        self.currentBattle.ratCommander = nil 
    end
    if self.currentBattle.cumanCommander ~= nil then
        self.RemoveCorpse(self.currentBattle.cumanCommander)
        self.currentBattle.cumanCommander = nil
    end
    for key,value in pairs(self.currentBattle.troops) do
        self.RemoveCorpse(value)
        self.currentBattle.troops[key] = nil
    end
    self.readyForNewBattle = true
    self.nextBattleLocation = nil
    Game.RemoveSaveLock(WarConstants.cSaveLockName)
end

-- should be called alongside cleartroops
function WarController:ResetBattle()
    self.currentBattle.wavesleft = WarConstants.numWaves
    self.currentBattle.locations = nil
    self.inBattle = false
    
    if self.currentBattle.center ~= nil then
        System.RemoveEntity(self.currentBattle.center.id)
        self.currentBattle.center = nil
    end
    
    if self.currentBattle.rat_point ~= nil then
        System.RemoveEntity(self.currentBattle.rat_point.id)
        self.currentBattle.rat_point = nil  
    end
    
    if self.currentBattle.cuman_point ~= nil then
        System.RemoveEntity(self.currentBattle.cuman_point.id)
        self.currentBattle.cuman_point = nil
    end
    

    self.currentBattle.kills = 0
    self.currentBattle.numCuman = 0
    self.currentBattle.numRattay = 0
end

-- Spawn function spawns an entity and then adds that entity to current troop
-- Nomenclature conflicts with SpawnSpecial so this should be renamed
function WarController:Spawn(side, position, objective, troopType)
    --System.LogAlways("$5 Attempting to Spawn troop")
    local spawnParams = {}
    local isEnemy = false
    spawnParams.class = "NPC"
    spawnParams.name = "soldier"
    spawnParams.position=getrandomposnear(position, 2.0)
    spawnParams.properties = {}
    spawnParams.properties.sharedSoulGuid = WarGuids[troopType][side]
    if side == WarConstants.cuman_side then
        self.currentBattle.numCuman = self.currentBattle.numCuman + 1
        isEnemy = true
    else
        self.currentBattle.numRattay = self.currentBattle.numRattay + 1
    end
    spawnParams.properties.warmodside = side
    spawnParams.properties.bWH_PerceptibleObject = 1
    local entity = System.SpawnEntity(spawnParams)
    
    entity.lootable = false
    if side == WarConstants.cuman_side then
        -- give cumans better stats because glaives are worse than halberds
        entity.soul:AdvanceToStatLevel("str", 13)
        entity.soul:AdvanceToStatLevel("vit", 11)
    end
    entity.soul:AddPerk(string.upper("d2da2217-d46d-4cdb-accb-4ff860a3d83e")) -- perfect block
    entity.soul:AddPerk(string.upper("ec4c5274-50e3-4bbf-9220-823b080647c4")) -- riposte
    entity.soul:AddPerk(string.upper("3e87c467-681d-48b5-9a8c-485443adcd42")) -- pommel strike
    
    local initmsg = Utils.makeTable('skirmish:init',{controller=player.this.id,isEnemy=isEnemy,oponentsNode=player.this.id,useQuickTargeting=true,targetingDistance=5.0, useMassBrain=true})
    XGenAIModule.SendMessageToEntityData(entity.this.id,'skirmish:init',initmsg);
    local initmsg2 = Utils.makeTable('skirmish:soundSetup',{ intensity=1.0, intensityPerEnemy=-0.5})
    --XGenAIModule.SendMessageToEntityData(entity.this.id,'skirmish:soundSetup',initmsg2);

    local initmsg4 = Utils.makeTable('skirmish:command',{type="attackMove",target=objective.this.id, randomRadius=0.5, movementSpeed="AlertedWalk", barkTopic="q_conquest_bernard_parkan2"})
    XGenAIModule.SendMessageToEntityData(entity.this.id,'skirmish:command',initmsg4);
    local initmsg3 = Utils.makeTable('skirmish:barkSetup',{ topicLabel="q_defence_soldier", cooldown="5s", once=false, command="*", forceSubtitles = false})
    XGenAIModule.SendMessageToEntityData(entity.this.id,'skirmish:barkSetup',initmsg3);
    
    table.insert(self.currentBattle.troops, entity)
end

-- Very specific helper function, don't use all willy nilly
-- Returns the entity and does not add it to the list of troops
-- actually there is a lot of shared code so this needs refactoring
function WarController:SpawnSpecial(side, position, troopType, radius)
    --System.LogAlways("$5 Attempting to Spawn troop")
    local spawnParams = {}
    local isEnemy = false
    spawnParams.class = "NPC"
    spawnParams.name = "soldier"
    spawnParams.position=getrandomposnear(position, radius)
    spawnParams.properties = {}
    spawnParams.properties.sharedSoulGuid = WarGuids[troopType][side]
    if side == WarConstants.cuman_side then
        self.currentBattle.numCuman = self.currentBattle.numCuman + 1
        isEnemy = true
    else
        self.currentBattle.numRattay = self.currentBattle.numRattay + 1
    end
    spawnParams.properties.warmodside = side
    spawnParams.properties.bWH_PerceptibleObject = 1
    local entity = System.SpawnEntity(spawnParams)
    entity.lootable = false
    entity.soul:AddPerk(string.upper("d2da2217-d46d-4cdb-accb-4ff860a3d83e")) -- perfect block
    entity.soul:AddPerk(string.upper("ec4c5274-50e3-4bbf-9220-823b080647c4")) -- riposte
    entity.soul:AddPerk(string.upper("3e87c467-681d-48b5-9a8c-485443adcd42")) -- pommel strike
    
    local initmsg = Utils.makeTable('skirmish:init',{controller=player.this.id,isEnemy=isEnemy,oponentsNode=player.this.id,useQuickTargeting=true,targetingDistance=5.0, useMassBrain=true})
    XGenAIModule.SendMessageToEntityData(entity.this.id,'skirmish:init',initmsg);
    
    return entity
end

function WarController:SpawnSquad(side, position, objective, strength)
    local num = 0
    for i=0,strength,1 do
        self:Spawn(side, position, objective, WarTroopTypes.halberd)
    end
    self:Spawn(side, position,objective, WarTroopTypes.knight)
    -- Cumans get another knight because the rattay get the player, the ultimate knight
    if side == WarConstants.cuman_side then
        self:Spawn(side, position,objective, WarTroopTypes.knight)
    end
    self:Spawn(side, position,objective, WarTroopTypes.aux)
end

function WarController:SpawnLeader(side, position)
    System.LogAlways("spawning leaders")
    local leader = self:SpawnSpecial(side, position, WarTroopTypes.knight, 0)
    if side == WarConstants.cuman_side then
        leader.actor:EquipClothingPreset("47875046-71f3-a06f-8ec9-ea8546176b8d")
    else
        leader.actor:EquipClothingPreset("4a45929c-690e-b01a-95ef-f975bbf6b0bd")
    end
    leader.soul:AdvanceToStatLevel("vit", 25)
    leader.soul:AdvanceToStatLevel("str", 20)
    leader.soul:SetState("health", 800)
    leader.soul:OverrideHead("404f142d-dc33-769c-f121-ac7a579c7fbc")

    if side == WarConstants.cuman_side then
        self.currentBattle.cumanCommander = leader
    else
        self.currentBattle.ratCommander = leader
    end
    
    local bodyguard = self:SpawnSpecial(side, position, WarTroopTypes.knight, 2.0)
    bodyguard.soul:AdvanceToStatLevel("vit", 25)
    bodyguard.soul:AdvanceToStatLevel("str", 20)
    bodyguard.soul:SetState("health", 200)
    table.insert(self.currentBattle.troops, bodyguard)
    local bodyguard2 = self:SpawnSpecial(side, position, WarTroopTypes.knight, 2.0)
    bodyguard2.soul:AdvanceToStatLevel("vit", 25)
    bodyguard2.soul:AdvanceToStatLevel("str", 20)
    bodyguard2.soul:SetState("health", 200)
    table.insert(self.currentBattle.troops, bodyguard2)
end

function WarController.SpawnWave(self)
    if self.inBattle == false then
        System.LogAlways("Somehow tried to spawn after battle was finished")
        return
    end
    --System.LogAlways("spawning new wave")
    message = "Troops have arrived! " .. tostring(self.currentBattle.wavesleft) .. " waves left\n"
    Game.SendInfoText(message,false,nil,5)
    if self.currentBattle.wavesleft > 0 then
        Script.SetTimer(WarConstants.waveInterval, self.SpawnWave, self)
        self.currentBattle.wavesleft = self.currentBattle.wavesleft - 1
    end
    
    self:SpawnSquad(WarConstants.cuman_side, self.currentBattle.locations.cuman, self.currentBattle.rat_point, self.currentBattle.cumanStrengthPerWave)
    self:SpawnSquad(WarConstants.rat_side, self.currentBattle.locations.rat, self.currentBattle.cuman_point, self.currentBattle.rattayStrengthPerWave)
end

function WarController.RemoveCorpse(entity)
    entity:DestroyPhysics()
    entity:Hide(1) 
    --entity:DeleteThis()
    System.RemoveEntity(entity.id)
end

function WarController:CreateAITagPoint(location)
    local spawnParams = {}
    spawnParams.class = "Grunt"
    spawnParams.name = "battlepoint"
    spawnParams.position=location
    spawnParams.properties = {}
    spawnParams.properties.bWH_PerceptibleObject = 0
    local entity = System.SpawnEntity(spawnParams)
    return entity
end

function WarController:GenerateBattle()
    if self.inBattle == false and self.readyForNewBattle == true and self.nextBattleLocation ~= nil then
        QuestSystem.CompleteObjective("quest_warmod", "startBattle")
        local spawnParams = {}
        local locations = self.nextBattleLocation
        message = "<font color='#FF3333' size='28'>A battle is beginning!\n\n</font>"
        message = message .. "Our forces have met Cuman forces near " .. locations.name .. "\n\n"
        message = message .. "Objectives:\nElimate enemy commander\nProtect your commander\nDon't lose all your men\n"
        Game.ShowTutorial(message, 20, false, true)
        Dump(locations)
        self.currentBattle.center = self:CreateAITagPoint(locations.center)
        self.currentBattle.rat_point = self:CreateAITagPoint(locations.rat)
        self.currentBattle.cuman_point = self:CreateAITagPoint(locations.cuman)
        self.currentBattle.locations = locations
        --Dump(center)
        self.inBattle = true
        self.readyForNewBattle = false
        self.timeBattleStarted = Calendar.GetWorldTime()
        Utils.DisableSave(WarConstants.cSaveLockName, enum_disableSaveReason.battle)
        
        self.SpawnWave(self)
        self:SpawnLeader(WarConstants.cuman_side, self.currentBattle.locations.cuman)
        self:SpawnLeader(WarConstants.rat_side, self.currentBattle.locations.rat)
    else
        System.LogAlways("tried to create battle but state does not allow it")
    end
end

function WarController:AssignActions(entity)
    entity.GetActions = function (user,firstFast)
        output = {}
        AddInteractorAction( output, firstFast, Action():hint("Start Battle"):action("use"):hintType( AHT_HOLD ):func(entity.OnUsed):interaction(inr_talk))
        return output
    end
    entity.Properties.controller = self
    entity.OnUsed = function (self, user)
        self.Properties.controller:GenerateBattle()
    end
end

function WarController:CreateMarshal(position)
    if self.marshal == nil then
        local spawnParams = {}
        spawnParams.class = "NPC"
        spawnParams.orientation = { x = 0, y = 0, z = 0 }
        --local vec = { x = 2979.425, y = 801.855, z = 111.145 }
        spawnParams.position = position
        spawnParams.properties = {}
        spawnParams.properties.sharedSoulGuid = "4861066f-1843-2ba9-42d5-05a5e34303ae"
        spawnParams.name = self.cMarshalName
        local entity = System.SpawnEntity(spawnParams)
        entity.lootable = false
        entity.AI.invulnerable = true
        self.marshal = entity
        System.LogAlways("$5 Created Marshal")
        self:CreateWarCamp(position)
        self:AssignActions(entity)
        self:AssignQuest()
    end
end

function WarController:CreateWarCamp(position)
    local spawnParams = {}
    spawnParams.class = "BasicEntity"
    spawnParams.orientation = { x = 0, y = 0, z = 0 }
    local vec = {}
    vec.x = position.x + 0.1
    vec.y = position.y + 0.1
    vec.z = position.z
    spawnParams.name = "warcamp"
    spawnParams.position = vec
    spawnParams.properties = {}
    local modelPath = WarConstants.campMesh
    spawnParams.properties.object_Model = modelPath
    local entity = System.SpawnEntity(spawnParams)
    self.warcamp = entity
end

function WarController:AssignQuest()
    QuestSystem.ResetQuest("quest_warmod")
    QuestSystem.ActivateQuest("quest_warmod")
    if not QuestSystem.IsQuestStarted("quest_warmod") then
        QuestSystem.StartQuest("quest_warmod")
        QuestSystem.StartObjective("quest_warmod", "startBattle", false)
    end
end

-- Reset objective and issue rewards
function WarController:Debrief(won)
    QuestSystem.CompleteObjective("quest_warmod", "finishBattle")
    self:DestroyMarshal()
    if won == true then
        local base = WarRewards.base
        base = base + (self.currentBattle.wavesleft * WarRewards.perWave)
        base = base + (self.currentBattle.kills * WarRewards.perKill)
        self.regionalInfluence = self.regionalInfluence + self.currentBattle.locations.influence
        message = "<font color='#111111' size='24'>You won!\n\n</font>"
        message = message .. "<font color='#FF3333' size='20'>Rewards:\n\n</font>"
        message = message .. "You received "
        message = message .. base .. " Groschen\n\n"
        message = message .. "You gained " .. self.currentBattle.locations.influence .. " Regional Influence\n"
        message = message .. "Current Regional Influence: " .. self.regionalInfluence
        Game.ShowTutorial(message, 20, false, true)
        -- ingame functions allow for fractions of groschen
        AddMoneyToInventory(player,base * 10)
    else
        self.regionalInfluence = self.regionalInfluence - self.currentBattle.locations.influence
        message = "<font color='#111111' size='24'>You lost!\n\n</font>"
        message = message .. "The Cumans have taken this location\n\n"
        message = message .. "You lost " .. self.currentBattle.locations.influence .. " Regional Influence\n"
        message = message .. "Current Regional Influence: " .. self.regionalInfluence
        Game.ShowTutorial(message, 20, false, true)
    end
end

function WarController:DetermineVictor()
    if self.currentBattle.ratCommander.soul:GetState("health") < 1 then
        Game.SendInfoText("Your commander has died! The battle was a defeat!",false,nil,10)
        
        self:Debrief(false)
        self:ResetBattle()
        self:KillSide(WarConstants.rat_side)
        --they get time for victory
        Script.SetTimer(WarConstants.victoryTime, self.ClearTroops, self)
        return
    end
    if self.currentBattle.cumanCommander.soul:GetState("health") < 1 then
        Game.SendInfoText("You have killed the enemy commander! The battle was a victory!",false,nil,10)
        
        self:Debrief(true)
        self:ResetBattle()
        self:KillSide(WarConstants.cuman_side)
        --they get time for victory
        Script.SetTimer(WarConstants.victoryTime, self.ClearTroops, self)
        return
    end 
    if self.currentBattle.wavesleft == 0 then
        if self.currentBattle.numRattay == 0 then
            Game.SendInfoText("All Bohemian troops have died! The battle was a defeat!",false,nil,10)
            self:Debrief(true)
            self:ResetBattle()
            --they get time for victory
            Script.SetTimer(WarConstants.victoryTime, self.ClearTroops, self)
        end
    end
end

function WarController:KillSide(side)
    --System.LogAlways("attempting to kill")
    for key,value in pairs(self.currentBattle.troops) do
        if value.Properties.warmodside == side then
            if value.Properties.warmodside == WarConstants.cuman_side then
                self.currentBattle.numCuman = self.currentBattle.numCuman - 1
            else
                self.currentBattle.numRattay = self.currentBattle.numRattay - 1
            end
            value.soul:DealDamage(200,200)
            Script.SetTimer(WarConstants.corpseTime, self.RemoveCorpse, value)
        end
    end
end

function WarController:CheckDeaths()
    --System.LogAlways("checking died")
    for key,value in pairs(self.currentBattle.troops) do
        if value.soul:GetState("health") < 1 then
            --System.LogAlways("someone died")
            Script.SetTimer(WarConstants.corpseTime, self.RemoveCorpse, value)
            self.currentBattle.troops[key] = nil
            --Dump(value.Properties)
            if value.Properties.warmodside == WarConstants.cuman_side then
                self.currentBattle.kills = self.currentBattle.kills + 1
                self.currentBattle.numCuman = self.currentBattle.numCuman - 1
            else
                self.currentBattle.numRattay = self.currentBattle.numRattay - 1
            end
        end
    end
end

function WarController:ReadyForBattle()
    -- lua is really fucking annoying because there are only hash tables
    -- we are not guaranteed that a key may be numeric
    if self.inBattle == false and self.readyForNewBattle == true then
        local keyset = {}
        for k in pairs(WarLocations) do
            table.insert(keyset, k)
        end
        local idx = math.random(#keyset)
        
        -- only ignore if we have more than 1 location
        if #keyset > 1 then
            -- try not to repeat same battle twice
            while idx == self.ignoreLocationIdx do
                idx = math.random(#keyset)
            end
        end
        
        local location = WarLocations[keyset[idx]]
        self.ignoreLocationIdx = idx
        message = "The War Marshal sends you word. Troops are gathering for a battle at "
        message = message .. location.name .. " and would like your help"
        Game.SendInfoText(message,false,nil,20)
        
        self.nextBattleLocation = location
        self:CreateMarshal(location.camp)
    end
end

function WarController:OffScreenBattle()
end

function WarController:OnUpdate(delta)
    if self.needReload == true then
        if self.marshal ~= nil then
            self:AssignActions(self.marshal)
            self.marshal:SetViewDistUnlimited()
            self.warcamp:SetViewDistUnlimited()
        end
        self.needReload = false
    else
        if self.inBattle == true then
            self:CheckDeaths()
            self:DetermineVictor()
        else
            --generate battles and do general war AI things
            local position = player:GetWorldPos()
            if self.marshal == nil then
                self:ReadyForBattle()
            else
                -- just chillin
            end
        end
    end
end
