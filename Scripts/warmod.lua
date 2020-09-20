War_Mod = {
    cUniqueIdName="warcontrolleridunique",
    currController = nil
}

function War_Mod.FG_Init()
    allcontrollers = System.GetEntitiesByClass("WarController")
    local key, value = next(allcontrollers)
    local entity = value
    if entity == nil then
        War_Mod.create()
    else
        System.LogAlways("Found existing warcontroller")
        War_Mod.currController = entity
    end
    System.LogAlways("$5 Started WarMod")
end

function War_Mod.endearly()
    War_Mod.currController.currentBattle.cumanCommander.soul:DealDamage(200,200)
end

function War_Mod.testbow()
    local spawnParams = {}
    spawnParams.class = "NPC"
    spawnParams.orientation = { x = 0, y = 0, z = 0 }
    --local vec = { x = 2979.425, y = 801.855, z = 111.145 }
    spawnParams.position = player:GetWorldPos()
    spawnParams.properties = {}
    spawnParams.properties.sharedSoulGuid = "822cfefc-4d92-4fa4-824a-f772b511eeca"
    local entity = System.SpawnEntity(spawnParams)
        local initmsg = Utils.makeTable('skirmish:init',{controller=player.this.id,isEnemy=true,oponentsNode=player.this.id,useQuickTargeting=true,targetingDistance=5.0, useMassBrain=true})
    XGenAIModule.SendMessageToEntityData(entity.this.id,'skirmish:init',initmsg);
end

function War_Mod.uninstall()
    local entities = System.GetEntitiesByClass("WarController")
    for key, value in pairs(entities) do
        System.RemoveEntity(value.id)
    end
end

function War_Mod.create()
    local spawnParams = {}
    spawnParams.class = "WarController"
    spawnParams.orientation = { x = 0, y = 0, z = 1 }
    spawnParams.properties = {}
    spawnParams.name = War_Mod.cUniqueIdName
    local entity = System.SpawnEntity(spawnParams)
    System.LogAlways("$5 [WarController] has been successfully created.")
    War_Mod.currController = entity
end

System.AddCCommand("warmodbow", "War_Mod.testbow()", "[Debug] test follower")
System.AddCCommand("warmod_uninstall", "War_Mod.uninstall()", "[Debug] test follower")
System.AddCCommand("warmod", "War_Mod.create()", "[Debug] test follower")
System.AddCCommand("warmod_kill", "War_Mod.endearly()", "[Debug] test follower")
