WarConstants = {
    cSaveLockName = "warmodsavelock",
    cMarshalName = "warmodmarshal",
    rat_side = 1,
    cuman_side = 2,
    troopCost = 100,
    cumanSoldier = "4957c994-1489-f528-130c-a00b9838a4a5",
    ratSoldier = "43b48356-ecf4-5e6e-bce4-1d98ed745baa",
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
    Attack,
    Defend,
    Field
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
    --{center = {x = 3136.570,y= 854.815,z= 122.557}, rat = {x = 3046.669,y = 798.363,z = 115.952}, cuman = {x = 3192.020,y= 910.343,z= 127.216}, name="Rattay Farmhouse"}
    {center = {x = 3136.570,y= 854.815,z= 122.557}, rat = {x = 2995.868,y = 809.014,z = 113.108}, cuman = {x = 3136.570,y= 854.815,z= 122.557}, name="Rattay Farmhouse", resourceNode = false}
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
    marshal = nil,
    warcamp = nil
    
}

function WarController:OnSpawn()
    System.LogAlways("$5 I AM SPAWNED")

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
    if self.marshal ~= nil then
        self.marshal:Hide(1)
        self.marshal:DeleteThis()
        self.warcamp:DeleteThis()
    end
    System.LogAlways("$5 I AM DELETE")
end

function WarController:OnSave(table)
    --this should be easy because all troops and entities should be cleared before any save action
    table.marshal = self.marshal:GetGUID()
    table.warcamp = self.warcamp:GetGUID()
end

function WarController:OnLoad(table)
    self.marshal = System.GetEntityByGUID(table.marshal)
    self.warcamp = System.GetEntityByGUID(table.warcamp)
    if self.warcamp ~= nil then
        self.warcamp:LoadObject(0, WarConstants.campMesh)
        self.warcamp = nil
    end

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
        self.RemoveCorpse(self.currentBattle.troops[key])
        self.currentBattle.troops[key] = nil
    end
    self.readyForNewBattle = true
    Game.RemoveSaveLock(WarConstants.cSaveLockName)
end

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
    local initmsg2 = Utils.makeTable('skirmish:soundSetup',{ intensity=3.0, intensityPerEnemy=0.0, trigger="test"})
    XGenAIModule.SendMessageToEntityData(entity.this.id,'skirmish:soundSetup',initmsg2);

    local initmsg4 = Utils.makeTable('skirmish:command',{type="attackMove",target=objective.this.id, randomRadius=0.5, movementSpeed="AlertedWalk", barkTopic="q_conquest_bernard_parkan2"})
    XGenAIModule.SendMessageToEntityData(entity.this.id,'skirmish:command',initmsg4);
    local initmsg3 = Utils.makeTable('skirmish:barkSetup',{ topicLabel="prib_ramGate", cooldown="5s", once=false, command="*", forceSubtitles = true})
    XGenAIModule.SendMessageToEntityData(entity.this.id,'skirmish:barkSetup',initmsg3);
    
    table.insert(self.currentBattle.troops, entity)
end

-- Very specific helper function, don't use all willy nilly
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
    if self.inBattle == false and self.readyForNewBattle == true then
        local spawnParams = {}
        local key, value = next(WarLocations)
        local locations = value
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
        Utils.DisableSave(WarConstants.cSaveLockName, enum_disableSaveReason.battle)
        
        self.SpawnWave(self)
        self:SpawnLeader(WarConstants.cuman_side, self.currentBattle.locations.cuman)
        self:SpawnLeader(WarConstants.rat_side, self.currentBattle.locations.rat)
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

function WarController:CreateMarshal()
    if self.marshal == nil then
        local spawnParams = {}
        spawnParams.class = "NPC"
        spawnParams.orientation = { x = 0, y = 0, z = 0 }
        --local vec = { x = 2986.043, y = 791.058, z = 111.972 }
        local vec = { x = 2979.425, y = 801.855, z = 111.145 }
        spawnParams.position = vec
        spawnParams.properties = {}
        spawnParams.properties.sharedSoulGuid = "4861066f-1843-2ba9-42d5-05a5e34303ae"
        spawnParams.name = self.cMarshalName
        local entity = System.SpawnEntity(spawnParams)
        entity.lootable = false
        self.marshal = entity
        --"Objects/props/furniture/tables/table_castle/table_10.cgf",
        System.LogAlways("$5 Created Marshal")
        self:CreateWarCamp(vec)
        self:AssignActions(entity)
        self:AssignQuest()
    end
end

function WarController:CreateWarCamp(position)
    local spawnParams = {}
    spawnParams.class = "BasicEntity"
    spawnParams.orientation = { x = 0, y = 0, z = 0 }
    local vec = position
    vec.x = vec.x + 0.1
    vec.y = vec.y + 0.1
    vec.z = vec.z - 1.2
    spawnParams.name = "warcamp"
    spawnParams.position = vec
    spawnParams.properties = {}
    local modelPath = WarConstants.campMesh
    spawnParams.properties.object_Model = modelPath
    local entity = System.SpawnEntity(spawnParams)
    self.warcamp = entity
end

function WarController:AssignQuest()
    QuestSystem.ActivateQuest("quest_warmod")
    if not QuestSystem.IsQuestStarted("quest_warmod") then
        QuestSystem.StartQuest("quest_warmod")
        QuestSystem.StartObjective("quest_warmod", "startBattle", false)
    end
end

function WarController:Debrief(won)
    if won == true then
        local base = WarRewards.base
        base = base + (self.currentBattle.wavesleft * WarRewards.perWave)
        base = base + (self.currentBattle.kills * WarRewards.perKill)
        
        message = "<font color='#111111' size='24'>You won!\n\n</font>"
        message = message .. "<font color='#FF3333' size='20'>Rewards:\n\n</font>"
        message = message .. "You received "
        message = message .. base .. " Groschen"
        Game.ShowTutorial(message, 20, false, true)
        AddMoneyToInventory(player,base)
    else
        message = "<font color='#111111' size='24'>You lost!\n\n</font>"
        message = message .. "The cumans have taken this location"
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
            self:ResetBattle()
            --they get time for victory
            Script.SetTimer(WarConstants.victoryTime, self.ClearTroops, self)
        else
            --not done with battle yet, so do nothing
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
                self:CreateMarshal()
            else
            end
        end
    end
end
