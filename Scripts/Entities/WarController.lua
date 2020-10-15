

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
        self.marshal = nil
    end
    if self.logiOfficer ~= nil then
        self.logiOfficer.soul:DealDamage(200,200)
        self.logiOfficer:DestroyPhysics();
        System.RemoveEntity(self.logiOfficer.id)
        self.logiOfficer = nil
    end
    if self.warcamp ~= nil then
        System.RemoveEntity(self.warcamp.id)
        self.warcamp = nil
    end
end

function WarController:OnSave(table)
    --this should be easy because all troops and entities should be cleared before any save action
    table.marshal = self.marshal:GetGUID()
    table.logiOfficer = self.logiOfficer:GetGUID()
    -- reuse this to index on load due to table shallow copy issues
    table.ignoreLocationIdx = self.ignoreLocationIdx
    table.regionalInfluence = self.regionalInfluence
    
    table.currentBattle = {}
    table.currentBattle.wavesleft = self.currentBattle.wavesleft
    table.currentBattle.strengthPerWave = {}
    Utils.DeepCopyTable(self.currentBattle.strengthPerWave, table.currentBattle.strengthPerWave)
    table.currentBattle.currentEvent = self.currentBattle.currentEvent
    table.currentBattle.isDefense = self.currentBattle.isDefense
    table.currentBattle.isAssault = self.currentBattle.isAssault
end

function WarController:OnLoad(table)
    self.marshal = System.GetEntityByGUID(table.marshal)
    self.logiOfficer = System.GetEntityByGUID(table.logiOfficer)
    
    self.ignoreLocationIdx = table.ignoreLocationIdx
    self.currentBattle.isDefense = table.currentBattle.isDefense
    self.currentBattle.isAssault = table.currentBattle.isAssault
    if self.currentBattle.isDefense == true then
        self.nextBattleLocation = WarRaidLocations[self.ignoreLocationIdx]
    else
        self.nextBattleLocation = WarLocations[self.ignoreLocationIdx]
    end
    
    self.regionalInfluence = table.regionalInfluence
    if table.currentBattle ~= nil then
        self.currentBattle.wavesleft = table.currentBattle.wavesleft
        Utils.DeepCopyTable(table.currentBattle.strengthPerWave, self.currentBattle.strengthPerWave)
        self.currentBattle.currentEvent = table.currentBattle.currentEvent
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
    self.currentBattle.currentEvent = nil
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
    self.currentBattle.isDefense = false
    self.currentBattle.isAssault = false
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

function WarController:StartBattle()
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
        self.regionalInfluence = math.max(self.regionalInfluence, 0)
        message = "<font color='#111111' size='24'>You lost!\n\n</font>"
        message = message .. "The Cumans have taken this location\n\n"
        message = message .. "You lost " .. influence .. " Regional Influence\n"
        message = message .. "Current Regional Influence: " .. self.regionalInfluence
        Game.ShowTutorial(message, 20, false, true)
    end
end

function WarController:Debrief2(won)
    QuestSystem.CompleteObjective("quest_warmod", "startBattle")
    QuestSystem.CompleteObjective("quest_warmod", "finishBattle")
    local influence = self.nextBattleLocation.influence + math.random(0,3) - math.random(0,3)
    
    self:DestroyMarshal()
    if won == true then
        self.regionalInfluence = self.regionalInfluence + influence
        message = "<font color='#111111' size='24'>You won!\n\n</font>"
        message = message .. "You gained " .. influence .. " Regional Influence\n"
        message = message .. "Current Regional Influence: " .. self.regionalInfluence
        Game.ShowTutorial(message, 20, false, true)
    else
        self.regionalInfluence = self.regionalInfluence - influence
        self.regionalInfluence = math.max(self.regionalInfluence, 0)
        message = "<font color='#111111' size='24'>You lost!\n\n</font>"
        message = message .. "The Cumans have taken this location\n\n"
        message = message .. "You lost " .. influence .. " Regional Influence\n"
        message = message .. "Current Regional Influence: " .. self.regionalInfluence
        Game.ShowTutorial(message, 20, false, true)
    end
end

function WarController:Brief()
        message = "<font color='#333333' size='28'>Briefing\n\n</font>"
        if self.currentBattle.isDefense == true then
            message = message .. "<font color='#FF3333' size='28'>This is a city defense!\n\n</font>"
        end
        message = message .. "Current Regional Influence: " .. self.regionalInfluence .. "\n\n"
        message = message .. "Bohemian Knights: " .. self.currentBattle.strengthPerWave[WarTroopTypes.knight][WarConstants.rat_side] .. "\n"
        message = message .. "Bohemian Halberdiers: " .. self.currentBattle.strengthPerWave[WarTroopTypes.halberd][WarConstants.rat_side] .. "\n"
        message = message .. "Bohemian Auxiliaries: " .. self.currentBattle.strengthPerWave[WarTroopTypes.aux][WarConstants.rat_side] .. "\n"
        message = message .. "Bohemian Archers: " .. self.currentBattle.strengthPerWave[WarTroopTypes.bow][WarConstants.rat_side] .. "\n\n"
        message = message .. "Cuman Strength: " .. self:DetermineDifficultyText() .. "\n\n"
        message = message .. "Available Reinforcement Waves: " .. self.currentBattle.wavesleft
        Game.ShowTutorial(message, 20, false, true)
end

function WarController:Scout()
        message = "<font color='#333333' size='28'>Scouting Information\n\n</font>"
        if self.currentBattle.currentEvent == nil then
            message = message .. "Scouts report nothing unusual at the moment\n\n"
        else
            message = message .. self:ReportEvent()
        end
        Game.ShowTutorial(message, 20, false, true)
end

function WarController:DetermineVictor()
    if self.currentBattle.ratCommander.soul:GetState("health") < 1 then
        Game.SendInfoText("Your commander has died! The battle was a defeat!",false,nil,10)
        
        self:Debrief(false)
        self:ResetBattle()
        --self:KillSide(WarConstants.rat_side)
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
    if self.regionalInfluence > WarDifficulty.impossible then
        return "Impossible"
    elseif self.regionalInfluence > WarDifficulty.veryhard then
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
    if self.regionalInfluence > WarDifficulty.impossible then
        self.currentBattle.strengthPerWave[WarTroopTypes.knight][WarConstants.cuman_side] = 6
        self.currentBattle.strengthPerWave[WarTroopTypes.bow][WarConstants.cuman_side] = 3
        self.currentBattle.strengthPerWave[WarTroopTypes.halberd][WarConstants.cuman_side] = 2
        self.currentBattle.strengthPerWave[WarTroopTypes.aux][WarConstants.cuman_side] = 0
    elseif self.regionalInfluence > WarDifficulty.veryhard then
        self.currentBattle.strengthPerWave[WarTroopTypes.knight][WarConstants.cuman_side] = 4
        self.currentBattle.strengthPerWave[WarTroopTypes.bow][WarConstants.cuman_side] = 3
        self.currentBattle.strengthPerWave[WarTroopTypes.halberd][WarConstants.cuman_side] = 3
        self.currentBattle.strengthPerWave[WarTroopTypes.aux][WarConstants.cuman_side] = 0
    elseif self.regionalInfluence > WarDifficulty.hard then
        self.currentBattle.strengthPerWave[WarTroopTypes.bow][WarConstants.cuman_side] = 2
        self.currentBattle.strengthPerWave[WarTroopTypes.aux][WarConstants.cuman_side] = 2
    elseif self.regionalInfluence > WarDifficulty.medium then
        
    else
        self.currentBattle.strengthPerWave[WarTroopTypes.halberd][WarConstants.cuman_side] = 2
        self.currentBattle.strengthPerWave[WarTroopTypes.aux][WarConstants.cuman_side] = 3
        self.currentBattle.strengthPerWave[WarTroopTypes.knight][WarConstants.cuman_side] = 1
    end
end

function WarController:GenerateRandomKey(tbl)
    local keyset = {}
    for k in pairs(tbl) do
        table.insert(keyset, k)
    end
    local key = math.random(#keyset)
    return keyset[key]
end

function WarController:GenerateEvent()
    if math.random(100) <= WarConstants.eventChance then
        local key = self:GenerateRandomKey(WarEvents)
        self.currentBattle.currentEvent = WarEvents[key]
        local message = self:ReportEvent()
        Game.SendInfoText(message,false,nil,10)
        
        if WarEvents[key] == WarEvents.cumanMoreArchers then
            self.currentBattle.strengthPerWave[WarTroopTypes.bow][WarConstants.cuman_side] = 4
        elseif WarEvents[key] == WarEvents.ratMoreArchers then
            self.currentBattle.strengthPerWave[WarTroopTypes.bow][WarConstants.rat_side] = 4
        elseif WarEvents[key] == WarEvents.lessWaves then
            self.currentBattle.wavesleft = 4
        end
    end
end

function WarController:ReportEvent()
    local event = self.currentBattle.currentEvent
    local message = ""
    if event == WarEvents.cumanMoreArchers then
        message = message .. "Our scouts have reported that the enemy is bringing a large amount of archers to the next battle." 
    end
    if event == WarEvents.ratMoreArchers then
        message = message .. "Sir Hanush has mustered up some additional archers. They will be deployed with us in the next battle." 
    end
    if event == WarEvents.lessWaves then
        message = message .. "Our logistics train has fallen behind! We cannot provide as many troop waves in the next battle." 
    end
    return message
end

function WarController:GenerateRandomKey(tbl, ignore)
    ignore = ignore or false
    local keyset = {}
    for k in pairs(tbl) do
        table.insert(keyset, k)
    end
    local idx = math.random(#keyset)
    
    -- ignore location if we have already fought there
    if #keyset > 1 and ignore == true then
        while idx == self.ignoreLocationIdx do
            idx = math.random(#keyset)
        end
    end
    return keyset[idx]
end

function WarController:ResetStrengths()
    for k in pairs (self.currentBattle.strengthPerWave) do
        self.currentBattle.strengthPerWave[k] = nil
    end
    -- reset strengths
    Utils.DeepCopyTable(WarStrengthPerWave, self.currentBattle.strengthPerWave)
end

-- Determines battle setup, as well as difficulty
function WarController:ReadyForBattle()
    -- lua is really fucking annoying because there are only hash tables
    -- we are not guaranteed that a key may be numeric
    if self.inBattle == false and self.readyForNewBattle == true then
        if self.regionalInfluence < WarDifficulty.low then
            -- chance for defense battle
            if math.random(2) == 2 then
                self.currentBattle.isDefense = true
            else
                self.currentBattle.isDefense = false
            end
        end
        --self.currentBattle.isDefense = true
        if self.currentBattle.isDefense ~= true then
            local idx = self:GenerateRandomKey(WarLocations, true)
            
            local location = WarLocations[idx]
            self.ignoreLocationIdx = idx
            local message = "The War Marshal sends you word. Troops are gathering for a battle at "
            message = message .. location.name .. " and would like your help"
            Game.SendInfoText(message,false,nil,10)
            
            self:ResetStrengths()
            -- must generate event after strengths have been reset
            self:GenerateEvent()
            
            self:DetermineDifficulty()
            self.nextBattleLocation = location
            self:CreateMarshal(location.camp)
        else
            local idx = self:GenerateRandomKey(WarRaidLocations, false)
            local location = WarRaidLocations[idx]
            self.ignoreLocationIdx = idx
            local message = "Warning! The Cumans are planning to attack "
            message = message .. location.name .. "! Our towns and civilians are at risk!"
            Game.SendInfoText(message,false,nil,10)
            self:ResetStrengths()
            
            self:DetermineDifficulty()
            self.nextBattleLocation = location
            self:CreateMarshal(location.camp)
        end
    end
end

function WarController:OffScreenBattle()
    self:Debrief2(false)
    self:ResetBattle()
    self.ClearTroops(self)
end

function WarController:OnUpdate(delta)
    if self.needReload == true then
        if self.marshal ~= nil then
            self:AssignActions(self.marshal)
            self.marshal:SetViewDistUnlimited()
        end
        if self.logiOfficer ~= nil then
            self:AssignActionsLogiOfficer(self.logiOfficer)
            self.logiOfficer:SetViewDistUnlimited()
        end
        self:CreateWarCamp(self.nextBattleLocation.camp)
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
