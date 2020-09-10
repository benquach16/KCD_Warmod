War_Mod = {
	cUniqueIdName="uniqueIdMercenaryMerchant",
	currController = nil
}

function War_Mod.startwar()
	War_Mod.currController:GenerateBattle()
end

function War_Mod.create()
QuestSystem.ActivateQuest("q_troubleCorpse")
QuestSystem.StartQuest("q_troubleCorpse")
    local spawnParams = {}
    spawnParams.class = "WarController"
    spawnParams.orientation = { x = 0, y = 0, z = 1 }
    spawnParams.properties = {}
    spawnParams.name = "warcontroller"
    local entity = System.SpawnEntity(spawnParams)
    System.LogAlways("$5 [WarController] has been successfully created.")
    War_Mod.currController = entity
end

System.AddCCommand("warmod", "War_Mod.create()", "[Debug] test follower")
System.AddCCommand("startwar", "War_Mod.startwar()", "[Debug] test follower")
