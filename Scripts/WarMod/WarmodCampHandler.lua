
function WarController:AssignActions(entity)
    entity.GetActions = function (user,firstFast)
        output = {}
        AddInteractorAction( output, firstFast, Action():hint("Start Battle"):action("use"):hintType( AHT_HOLD ):func(entity.OnStart):interaction(inr_talk))
        AddInteractorAction( output, firstFast, Action():hint("View Briefing"):action("use"):func(entity.OnBrief):interaction(inr_talk))
        return output
    end
    entity.Properties.controller = self
    entity.OnStart = function (self, user)
        self.Properties.controller:GenerateBattle()
    end
    entity.OnBrief = function (self, user)
        self.Properties.controller:Brief()
    end
end

function WarController:AssignActionsLogiOfficer(entity)
    entity.GetActions = function (user,firstFast)
        output = {}
        AddInteractorAction( output, firstFast, Action():hint("Buy Extra Wave (200 Groschen)"):action("use"):func(entity.OnWave):interaction(inr_talk))
        AddInteractorAction( output, firstFast, Action():hint("Buy Archers (400 Groschen)"):action("use"):hintType( AHT_HOLD ):func(entity.OnArcher):interaction(inr_talk))
        AddInteractorAction( output, firstFast, Action():hint("Buy Halberdiers (400 Groschen)"):action("mount_horse"):func(entity.OnHalberd):interaction(inr_talk))
        return output
    end
    entity.Properties.controller = self
    entity.OnArcher = function (self, user)
        if player.inventory:GetMoney() < 200 then
            Game.SendInfoText("You need 200 Groschen",false,nil,5)
        else
            RemoveMoneyFromInventory(player, 2000)
            Game.SendInfoText("Waves increased by 1",false,nil,5)
            self.Properties.controller.currentBattle.wavesleft = self.Properties.controller.currentBattle.wavesleft + 1
        end
    end
    entity.OnHalberd = function (self, user)
        if player.inventory:GetMoney() < 400 then
            Game.SendInfoText("You need 400 Groschen",false,nil,5)
        else
            RemoveMoneyFromInventory(player, 4000)
            Game.SendInfoText("Halberdiers per wave increased by 1",false,nil,5)
            self.Properties.controller.currentBattle.strengthPerWave[WarTroopTypes.halberd][WarConstants.rat_side] = self.Properties.controller.currentBattle.strengthPerWave[WarTroopTypes.halberd][WarConstants.rat_side] + 1
        end
    end
    entity.OnArcher = function (self, user)
        if player.inventory:GetMoney() < 400 then
            Game.SendInfoText("You need 400 Groschen",false,nil,5)
        else
            RemoveMoneyFromInventory(player, 4000)
            Game.SendInfoText("Archers per wave increased by 1",false,nil,5)
            self.Properties.controller.currentBattle.strengthPerWave[WarTroopTypes.bow][WarConstants.rat_side] = self.Properties.controller.currentBattle.strengthPerWave[WarTroopTypes.bow][WarConstants.rat_side] + 1
        end
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
        self:CreateLogiOfficer(position)
        self:CreateWarCamp(position)
        self:AssignActions(entity)
        self:AssignQuest()
    end
end

function WarController:CreateLogiOfficer(position)
    if self.logiOfficer == nil then
        local spawnParams = {}
        spawnParams.class = "NPC"
        spawnParams.orientation = { x = 0, y = 0, z = 0 }
        local vec = {}
        vec.x = position.x + 1
        vec.y = position.y + 2
        vec.z = position.z
        spawnParams.position = vec
        spawnParams.properties = {}
        spawnParams.properties.sharedSoulGuid = "3c122d09-c4db-4673-989c-b9594427cd2e"
        spawnParams.name = "logiofficer"
        local entity = System.SpawnEntity(spawnParams)
        entity.lootable = false
        entity.AI.invulnerable = true
        self.logiOfficer = entity
        System.LogAlways("$5 Created Logi Officer")
        self:AssignActionsLogiOfficer(entity)
    end
end

function WarController:CreateWarCamp(position)
    local spawnParams = {}
    spawnParams.class = "BasicEntity"
    spawnParams.orientation = { x = 0, y = 0, z = 0 }
    local vec = {}
    vec.x = position.x + 0.3
    vec.y = position.y + 0.3
    vec.z = position.z
    spawnParams.name = "warcamp"
    spawnParams.position = vec
    spawnParams.properties = {}
    local modelPath = WarConstants.campMesh
    spawnParams.properties.object_Model = modelPath
    local entity = System.SpawnEntity(spawnParams)
    self.warcamp = entity
end
