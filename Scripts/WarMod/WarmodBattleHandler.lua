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
    entity.GetActions = function (user,firstFast)
        output = {}
        return output
    end
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