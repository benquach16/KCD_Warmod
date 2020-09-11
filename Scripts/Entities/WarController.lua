WarConstants = {
	cSaveLockName = "warmodsavelock",
	rat_side = 1,
	cuman_side = 2,
	troopCost = 100,
	cumanSoldier = "4957c994-1489-f528-130c-a00b9838a4a5",
	ratSoldier = "43b48356-ecf4-5e6e-bce4-1d98ed745baa",
	numWaves = 5,
	corpseTime = 5000, --5 seconds
	victoryTime = 30000, -- 30 seconds
	waveInterval = 40000 -- 40 seconds
}

WarTypes = {
	commander = 0,
	knight = 1,
	halberd = 2,
	aux = 3,
	bow = 4,
	halberd_light = 5,
	aux_light = 6
}

WarGuids = {
	knight = {},
	halberd = {},
	aux = {}
}

WarGuids[WarTypes.knight] = {}
WarGuids[WarTypes.knight][WarConstants.rat_side] = "41429725-5368-3cb1-6440-2e2e02b4fc97"
WarGuids[WarTypes.knight][WarConstants.cuman_side] = "49c00005-e5e9-ee50-7370-8bc12c8ad29f"
WarGuids[WarTypes.halberd] = {}
WarGuids[WarTypes.halberd][WarConstants.rat_side] = "43b48356-ecf4-5e6e-bce4-1d98ed745baa"
WarGuids[WarTypes.halberd][WarConstants.cuman_side] = "4957c994-1489-f528-130c-a00b9838a4a5"
WarGuids[WarTypes.aux] = {}
WarGuids[WarTypes.aux][WarConstants.rat_side] = "4aa17e70-525a-1e83-d32f-adf2f8c60daf"
WarGuids[WarTypes.aux][WarConstants.cuman_side] = "4c4f6e9d-aa80-4f1b-a9d9-62573e6de2a7"

WarLocations = {
	--{center = { x=3087.410, y=829.085, z=118.978 }, rat = {x = 3040.93,y = 850.747,z = 119.558}, cuman = {x = 3136.570,y= 854.815,z= 122.557}},
	{center = { x=3106.441, y=819.985, z=118.436 }, rat = {x = 3046.669,y = 798.363,z = 115.952}, cuman = {x = 3136.570,y= 854.815,z= 122.557}, name="Rattay Farmhouse"}
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
	rattayStrengthPerWave = 3, -- temp
	cumanStrengthPerWave = 3, -- temp
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
	currentBattle = Battle
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
	ret.x = position.x + math.random() + math.random(0, radius) - math.random(0, radius)
	ret.y = position.y + math.random() + math.random(0, radius) - math.random(0, radius)
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
		--isEnemy = true
	else
		self.currentBattle.numRattay = self.currentBattle.numRattay + 1
	end
	spawnParams.properties.warmodside = side
	spawnParams.properties.bWH_PerceptibleObject = 1
	local entity = System.SpawnEntity(spawnParams)
	
	entity.soul:AddPerk(string.upper("d2da2217-d46d-4cdb-accb-4ff860a3d83e")) -- perfect block
	entity.soul:AddPerk(string.upper("ec4c5274-50e3-4bbf-9220-823b080647c4")) -- riposte
	entity.soul:AddPerk(string.upper("3e87c467-681d-48b5-9a8c-485443adcd42")) -- pommel strike
	
	local initmsg = Utils.makeTable('skirmish:init',{controller=player.this.id,isEnemy=isEnemy,oponentsNode=player.this.id,useQuickTargeting=true,targetingDistance=5.0, useMassBrain=true})
	XGenAIModule.SendMessageToEntityData(entity.this.id,'skirmish:init',initmsg);
	local initmsg2 = Utils.makeTable('skirmish:command',{type="attackMove",target=objective.this.id, randomRadius=0.5})
	XGenAIModule.SendMessageToEntityData(entity.this.id,'skirmish:command',initmsg2);
	
	table.insert(self.currentBattle.troops, entity)
end

function WarController.SpawnWave(self)
	--System.LogAlways("spawning new wave")
	message = "Troops have arrived! " .. tostring(self.currentBattle.wavesleft) .. " waves left\n"
	Game.SendInfoText(message,false,nil,5)
	if self.currentBattle.wavesleft > 0 then
		Script.SetTimer(WarConstants.waveInterval, self.SpawnWave, self)
		self.currentBattle.wavesleft = self.currentBattle.wavesleft - 1
	end
	for i=0,self.currentBattle.cumanStrengthPerWave,1 do
		self:Spawn(WarConstants.cuman_side, self.currentBattle.locations.cuman, self.currentBattle.rat_point, WarTypes.halberd)
	end
	self:Spawn(WarConstants.cuman_side, self.currentBattle.locations.cuman, self.currentBattle.rat_point, WarTypes.knight)	
	self:Spawn(WarConstants.cuman_side, self.currentBattle.locations.cuman, self.currentBattle.rat_point, WarTypes.aux)
	for i=0,self.currentBattle.rattayStrengthPerWave,1 do
		self:Spawn(WarConstants.rat_side, self.currentBattle.locations.rat, self.currentBattle.cuman_point, WarTypes.halberd)
	end
	self:Spawn(WarConstants.rat_side, self.currentBattle.locations.rat, self.currentBattle.cuman_point, WarTypes.knight)
	self:Spawn(WarConstants.rat_side, self.currentBattle.locations.rat, self.currentBattle.cuman_point, WarTypes.aux)
end

function WarController.RemoveCorpse(entity)
	entity:DestroyPhysics()
	entity:Hide(1)
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
	message = "Our forces have met Cuman forces near " .. locations.name .. "\n"
	message = message .. "A battle is beginning!\n"
	Game.ShowTutorial(message, 20, false, true)
	Dump(locations)
	self.currentBattle.center = self:CreateAITagPoint(locations.center)
	self.currentBattle.rat_point = self:CreateAITagPoint(locations.rat)
	self.currentBattle.cuman_point = self:CreateAITagPoint(locations.cuman)
	self.currentBattle.locations = locations
	--Dump(center)
	self.SpawnWave(self)
	
	self.inBattle = true
	self.readyForNewBattle = false
	Utils.DisableSave(WarConstants.cSaveLockName, enum_disableSaveReason.battle)
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

function WarController:CheckDeaths()
	--System.LogAlways("checking died")
	for key,value in pairs(self.currentBattle.troops) do
		if value.soul:GetState("health") < 1 then
			System.LogAlways("someone died")
			Script.SetTimer(WarConstants.waveInterval, self.RemoveCorpse, value)
			self.currentBattle.troops[key] = nil
			Dump(value.Properties)
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
	end
end

System.AddCCommand("getstatus", "WarController:UpdateStatus()", "[Debug] test follower")
System.AddCCommand("start_war", "WarController:GenerateBattle()", "[Debug] test follower")
