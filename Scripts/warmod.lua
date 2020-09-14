War_Mod = {
	cUniqueIdName="warmarshallidname",
	currController = nil
}

function War_Mod.AssignActions(entity)
	entity.GetActions = function (user,firstFast)
		output = {}
		AddInteractorAction( output, firstFast, Action():hint("Start Battle"):action("use"):hintType( AHT_HOLD ):func(entity.OnUsed):interaction(inr_talk))
		return output
	end
	entity.OnUsed = function (self, user)
		War_Mod.create()
		War_Mod.startwar()
	end
end


function War_Mod.FG_Init()
	local entity = System.GetEntityByName(War_Mod.cUniqueIdName) 
	War_Mod.quest()
	System.LogAlways("$5 Started WarMod")
end

function War_Mod.startwar()
	War_Mod.currController:GenerateBattle()
end

function War_Mod.createtable()
	--"Objects/props/furniture/tables/table_castle/table_10.cgf",
end

function War_Mod.quest()
    local spawnParams = {}
    spawnParams.class = "NPC"
    spawnParams.orientation = { x = 0, y = 0, z = 1 }
	spawnParams.position = { x = 2986.043, y = 791.058, z = 111.972 }
    spawnParams.properties = {}
	spawnParams.properties.sharedSoulGuid = "4861066f-1843-2ba9-42d5-05a5e34303ae"
	--spawnParams.properties.sharedSoulGuid = "4a34c4de-21f9-a475-80dc-70b0dcfa7fa6"
    spawnParams.name = War_Mod.cUniqueIdName
    local entity = System.SpawnEntity(spawnParams)
	entity.lootable = false
	War_Mod.AssignActions(entity)
	--"Objects/props/furniture/tables/table_castle/table_10.cgf",
	System.LogAlways("$5 Created Marshal")
	
	QuestSystem.ActivateQuest("quest_warmod")
	if not QuestSystem.IsQuestStarted("quest_warmod") then
		QuestSystem.StartQuest("quest_warmod")
		QuestSystem.StartObjective("quest_warmod", "startBattle", false)
	end

end

function War_Mod.create()
    local spawnParams = {}
    spawnParams.class = "WarController"
    spawnParams.orientation = { x = 0, y = 0, z = 1 }
    spawnParams.properties = {}
    spawnParams.name = "warcontroller"
    local entity = System.SpawnEntity(spawnParams)
    System.LogAlways("$5 [WarController] has been successfully created.")
    War_Mod.currController = entity
end
System.AddCCommand("quest", "War_Mod.quest()", "[Debug] test follower")
System.AddCCommand("warmod", "War_Mod.create()", "[Debug] test follower")
System.AddCCommand("startwar", "War_Mod.startwar()", "[Debug] test follower")
