WarConstants = {
	cSaveLockName = "warmodsavelock",
	rat_side = 1,
	cuman_side = 2,
	troopCost = 100,
	cumanSoldier = "4957c994-1489-f528-130c-a00b9838a4a5",
	ratSoldier = "43b48356-ecf4-5e6e-bce4-1d98ed745baa",
	numWaves = 7,
	corpseTime = 5000, --5 seconds
	victoryTime = 20000, -- 30 seconds
	waveInterval = 75000 -- 75 seconds
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
	numRattay = 0
}

WarController = {
	Rattay = Side,
	Cuman = Side,
	reload = false,
	-- only 1 battle can occur at a time
	inBattle = false,
	readyForNewBattle = true,
	currentBattle = Battle,
	nextBattleLocation = nil
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
	System.LogAlways("$5 I AM DELETE")
end

function WarController:OnSave(table)
	--this should be easy because all troops and entities should be cleared before any save action
end

function WarController:OnLoad(table)
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
	System.RemoveEntity(self.currentBattle.center.id)
	self.currentBattle.center = nil
	System.RemoveEntity(self.currentBattle.rat_point.id)
	self.currentBattle.rat_point = nil	
	System.RemoveEntity(self.currentBattle.cuman_point.id)
	self.currentBattle.cuman_point = nil
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

function WarController:DetermineVictor()
	if self.currentBattle.numRattay == 0 and self.currentBattle.numCuman == 0 then
		Game.SendInfoText("The battle was a draw!",false,nil,10)
		self:ResetBattle()
		-- no need to clear trops here
	elseif self.currentBattle.numRattay == 0 then
		Game.SendInfoText("The battle was a defeat!",false,nil,10)
		self:ResetBattle()
		--they get time for victory
		Script.SetTimer(WarConstants.victoryTime, self.ClearTroops, self)
	elseif self.currentBattle.numCuman == 0 then
		Game.SendInfoText("The battle was a victory!",false,nil,10)
		self:ResetBattle()
		--they get time for victory
		Script.SetTimer(WarConstants.victoryTime, self.ClearTroops, self)
	else
		--not done with battle yet, so do nothing
	end
end

function WarController:KillSide(side)
	for key,value in pairs(self.currentBattle.troops) do
		if value.Properties.warmodside == side then
			if value.Properties.warmodside == WarConstants.cuman_side then
				self.currentBattle.numCuman = self.currentBattle.numCuman - 1
			else
				self.currentBattle.numRattay = self.currentBattle.numRattay - 1
			end
			RemoveCorpse(value)
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
	if self.inBattle == true then
		self:CheckDeaths()
		-- kill current battle
		if self.currentBattle.wavesleft == 0 then
			--System.LogAlways("done with battle")
			self:DetermineVictor()
			--self:ResetBattle()
		end
	else
		--generate battles and do general war AI things
		local position = player:GetWorldPos()
	end
end

System.AddCCommand("getstatus", "WarController:UpdateStatus()", "[Debug] test follower")
System.AddCCommand("start_war", "WarController:GenerateBattle()", "[Debug] test follower")
