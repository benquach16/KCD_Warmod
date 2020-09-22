

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
    self:DestroyMarshal()
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
    if self.logiOfficer ~= nil then
        self.logiOfficer.soul:DealDamage(200,200)
        self.logiOfficer:DestroyPhysics();
        System.RemoveEntity(self.logiOfficer.id)
        self.logiOfficer = nil
    end
end

function WarController:OnSave(table)
    --this should be easy because all troops and entities should be cleared before any save action
    table.marshal = self.marshal:GetGUID()
    table.warcamp = self.warcamp:GetGUID()
    table.logiOfficer = self.logiOfficer:GetGUID()
    -- reuse this to index on load due to table shallow copy issues
    table.ignoreLocationIdx = self.ignoreLocationIdx
    table.regionalInfluence = self.regionalInfluence
    
    table.currentBattle = {}
    table.currentBattle.wavesleft = self.currentBattle.wavesleft
    table.currentBattle.strengthPerWave = {}
    Utils.DeepCopyTable(self.currentBattle.strengthPerWave, table.currentBattle.strengthPerWave)
end

function WarController:OnLoad(table)
    self.marshal = System.GetEntityByGUID(table.marshal)
    self.warcamp = System.GetEntityByGUID(table.warcamp)
    self.logiOfficer = System.GetEntityByGUID(table.logiOfficer)
    if self.warcamp ~= nil then
        self.warcamp:LoadObject(0, WarConstants.campMesh)
    end
    
    self.ignoreLocationIdx = table.ignoreLocationIdx
    self.nextBattleLocation = WarLocations[self.ignoreLocationIdx]
    self.regionalInfluence = table.regionalInfluence
    if table.currentBattle ~= nil then
        self.currentBattle.wavesleft = table.currentBattle.wavesleft
        Utils.DeepCopyTable(table.currentBattle.strengthPerWave, self.currentBattle.strengthPerWave)
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
    for k in pairs (self.currentBattle.strengthPerWave) do
        self.currentBattle.strengthPerWave[k] = nil
    end
    Utils.DeepCopyTable(WarStrengthPerWave, self.currentBattle.strengthPerWave)
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
    entity.soul:AdvanceToSkillLevel("defense",14)
    --entity.soul:AdvanceToSkillLevel("fencing",14)
    entity.soul:AdvanceToSkillLevel("weapon_large",12)
    entity.soul:AdvanceToSkillLevel("weapon_sword",12)
    local initmsg = Utils.makeTable('skirmish:init',{controller=player.this.id,isEnemy=isEnemy,oponentsNode=player.this.id,useQuickTargeting=true,targetingDistance=5.0, useMassBrain=true})
    XGenAIModule.SendMessageToEntityData(entity.this.id,'skirmish:init',initmsg);
    local initmsg2 = Utils.makeTable('skirmish:soundSetup',{ intensity=1.0, intensityPerEnemy=0.2, trigger="battle_ambient"})
    --XGenAIModule.SendMessageToEntityData(entity.this.id,'skirmish:soundSetup',initmsg2);

    local initmsg4 = Utils.makeTable('skirmish:command',{type="attackMove",target=objective.this.id, randomRadius=0.5, movementSpeed="AlertedWalk"})
    XGenAIModule.SendMessageToEntityData(entity.this.id,'skirmish:command',initmsg4);
    local initmsg3 = Utils.makeTable('skirmish:barkSetup',{ metarole="COMBAT_CHARGE", cooldown="15s", once=false, command="*", forceSubtitles = false})
    XGenAIModule.SendMessageToEntityData(entity.this.id,'skirmish:barkSetup',initmsg3)
    
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
    entity.soul:AdvanceToSkillLevel("defense",24)
    entity.soul:AdvanceToSkillLevel("weapon_unarmed",20)
    entity.soul:AdvanceToSkillLevel("weapon_large",20)
    entity.soul:AdvanceToSkillLevel("weapon_sword",20)
    local initmsg = Utils.makeTable('skirmish:init',{controller=player.this.id,isEnemy=isEnemy,oponentsNode=player.this.id,useQuickTargeting=true,targetingDistance=5.0, useMassBrain=true})
    XGenAIModule.SendMessageToEntityData(entity.this.id,'skirmish:init',initmsg);
    
    return entity
end

function WarController:SpawnSquad(side, position, objective)
    local num = 0
    local strengthFuzz = self.currentBattle.strengthPerWave[WarTroopTypes.halberd][side]
    -- fuzz halberd strength because they are the meat and potatoes of a squad
    strengthFuzz = strengthFuzz + math.random(0, WarConstants.squadNumberVariance) - math.random(0,WarConstants.squadNumberVariance)
    
    -- lua is not 0 indexed, start loops at 1
    for i=1,strengthFuzz,1 do
        self:Spawn(side, position, objective, WarTroopTypes.halberd)
    end
    
    for i=1,self.currentBattle.strengthPerWave[WarTroopTypes.knight][side],1 do
        self:Spawn(side, position, objective, WarTroopTypes.knight)
    end
    for i=1,self.currentBattle.strengthPerWave[WarTroopTypes.aux][side],1 do
        self:Spawn(side, position,objective, WarTroopTypes.aux)
    end    
    for i=1,self.currentBattle.strengthPerWave[WarTroopTypes.bow][side],1 do
        self:Spawn(side, position,objective, WarTroopTypes.bow)
    end
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
    
    self:SpawnSquad(WarConstants.cuman_side, self.currentBattle.locations.cuman, self.currentBattle.rat_point)
    self:SpawnSquad(WarConstants.rat_side, self.currentBattle.locations.rat, self.currentBattle.cuman_point)
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
    local influence = self.currentBattle.locations.influence + math.random(0,3) - math.random(0,3)
    
    self:DestroyMarshal()
    if won == true then
        local base = WarRewards.base
        base = base + (self.currentBattle.wavesleft * WarRewards.perWave)
        base = base + (self.currentBattle.kills * WarRewards.perKill)
        self.regionalInfluence = self.regionalInfluence + influence
        message = "<font color='#111111' size='24'>You won!\n\n</font>"
        message = message .. "<font color='#FF3333' size='20'>Rewards:\n\n</font>"
        message = message .. "You received "
        message = message .. base .. " Groschen\n\n"
        message = message .. "You gained " .. influence .. " Regional Influence\n"
        message = message .. "Current Regional Influence: " .. self.regionalInfluence
        Game.ShowTutorial(message, 20, false, true)
        -- ingame functions allow for fractions of groschen
        AddMoneyToInventory(player,base * 10)
    else
        self.regionalInfluence = self.regionalInfluence - influence
        message = "<font color='#111111' size='24'>You lost!\n\n</font>"
        message = message .. "The Cumans have taken this location\n\n"
        message = message .. "You lost " .. influence .. " Regional Influence\n"
        message = message .. "Current Regional Influence: " .. self.regionalInfluence
        Game.ShowTutorial(message, 20, false, true)
    end
end

function WarController:Brief()
        message = "<font color='#333333' size='28'>Briefing\n\n</font>"
        message = message .. "Current Regional Influence: " .. self.regionalInfluence .. "\n\n"
        message = message .. "Bohemian Knights: " .. self.currentBattle.strengthPerWave[WarTroopTypes.knight][WarConstants.rat_side] .. "\n"
        message = message .. "Bohemian Halberdiers: " .. self.currentBattle.strengthPerWave[WarTroopTypes.halberd][WarConstants.rat_side] .. "\n"
        message = message .. "Bohemian Auxiliaries: " .. self.currentBattle.strengthPerWave[WarTroopTypes.aux][WarConstants.rat_side] .. "\n"
        message = message .. "Bohemian Archers: " .. self.currentBattle.strengthPerWave[WarTroopTypes.bow][WarConstants.rat_side] .. "\n\n"
        message = message .. "Cuman Strength: " .. self:DetermineDifficultyText() .. "\n\n"
        message = message .. "Available Reinforcement Waves: " .. self.currentBattle.wavesleft
        Game.ShowTutorial(message, 20, false, true)
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

function WarController:DetermineDifficultyText()
    if self.regionalInfluence > WarDifficulty.veryhard then
        return "Very Hard"
    elseif self.regionalInfluence > WarDifficulty.hard then
        return "Hard"
    elseif self.regionalInfluence > WarDifficulty.medium then
        return "Medium"
    else
        return "Easy"
    end
end

-- temp numbers
function WarController:DetermineDifficulty()
    if self.regionalInfluence > WarDifficulty.veryhard then
        self.Properties.controller.currentBattle.strengthPerWave[WarTroopTypes.knight][WarConstants.cuman_side] = 4
        self.Properties.controller.currentBattle.strengthPerWave[WarTroopTypes.bow][WarConstants.cuman_side] = 3
        self.Properties.controller.currentBattle.strengthPerWave[WarTroopTypes.halberd][WarConstants.cuman_side] = 3
        self.Properties.controller.currentBattle.strengthPerWave[WarTroopTypes.aux][WarConstants.cuman_side] = 0
    elseif self.regionalInfluence > WarDifficulty.hard then
        self.Properties.controller.currentBattle.strengthPerWave[WarTroopTypes.knight][WarConstants.cuman_side] = 3
        self.Properties.controller.currentBattle.strengthPerWave[WarTroopTypes.bow][WarConstants.cuman_side] = 1
    elseif self.regionalInfluence > WarDifficulty.medium then
        
    else
        self.Properties.controller.currentBattle.strengthPerWave[WarTroopTypes.halberd][WarConstants.cuman_side] = 2
        self.Properties.controller.currentBattle.strengthPerWave[WarTroopTypes.aux][WarConstants.cuman_side] = 3
    end
end

-- Determines battle setup, as well as difficulty
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
        Game.SendInfoText(message,false,nil,10)
        for k in pairs (self.currentBattle.strengthPerWave) do
            self.currentBattle.strengthPerWave[k] = nil
        end
        -- reset strengths
        Utils.DeepCopyTable(WarStrengthPerWave, self.currentBattle.strengthPerWave)
        
        self:DetermineDifficulty()
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
        if self.logiOfficer ~= nil then
            self:AssignActionsLogiOfficer(self.logiOfficer)
            self.logiOfficer:SetViewDistUnlimited()
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
