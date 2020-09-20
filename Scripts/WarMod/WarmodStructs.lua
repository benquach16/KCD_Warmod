-- Constant struct
WarConstants = {
    cSaveLockName = "warmodsavelock",
    cMarshalName = "warmodmarshal",
    rat_side = 1,
    cuman_side = 2,
    troopCost = 100,
    waveCost = 200,
    numWaves = 8,
    corpseTime = 15000, --15 seconds
    victoryTime = 20000, -- 30 seconds
    waveInterval = 75000, -- 75 seconds
    campMesh = "objects/structures/tent_cuman/tent_cuman_v6_b.cgf",
    squadNumberVariance = 1,
    
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
    Attack = 0,
    Defend = 1,
    Field = 2,
    Ambush = 3
}

WarGuids = {
    knight = {},
    halberd = {},
    aux = {},
    bow = {}
}

WarDifficulty = {
    low = 0,
    medium = 40,
    hard = 80,
    veryhard = 120
}

WarStrengthPerWave = {
    cumanStrengthPerWave = 6,
    rattayStrengthPerWave = 4,
}
-- Defaults
-- Cumans get another knight because the rattay get the player, the ultimate knight
WarStrengthPerWave[WarTroopTypes.knight] = {}
WarStrengthPerWave[WarTroopTypes.knight][WarConstants.rat_side] = 1
WarStrengthPerWave[WarTroopTypes.knight][WarConstants.cuman_side] = 2
WarStrengthPerWave[WarTroopTypes.halberd] = {}
WarStrengthPerWave[WarTroopTypes.halberd][WarConstants.rat_side] = 4
WarStrengthPerWave[WarTroopTypes.halberd][WarConstants.cuman_side] = 6
WarStrengthPerWave[WarTroopTypes.aux] = {}
WarStrengthPerWave[WarTroopTypes.aux][WarConstants.rat_side] = 1
WarStrengthPerWave[WarTroopTypes.aux][WarConstants.cuman_side] = 1
WarStrengthPerWave[WarTroopTypes.bow] = {}
WarStrengthPerWave[WarTroopTypes.bow][WarConstants.rat_side] = 0
WarStrengthPerWave[WarTroopTypes.bow][WarConstants.cuman_side] = 0

WarGuids[WarTroopTypes.knight] = {}
WarGuids[WarTroopTypes.knight][WarConstants.rat_side] = "41429725-5368-3cb1-6440-2e2e02b4fc97"
WarGuids[WarTroopTypes.knight][WarConstants.cuman_side] = "49c00005-e5e9-ee50-7370-8bc12c8ad29f"
WarGuids[WarTroopTypes.halberd] = {}
WarGuids[WarTroopTypes.halberd][WarConstants.rat_side] = "43b48356-ecf4-5e6e-bce4-1d98ed745baa"
WarGuids[WarTroopTypes.halberd][WarConstants.cuman_side] = "4957c994-1489-f528-130c-a00b9838a4a5"
WarGuids[WarTroopTypes.aux] = {}
WarGuids[WarTroopTypes.aux][WarConstants.rat_side] = "4aa17e70-525a-1e83-d32f-adf2f8c60daf"
WarGuids[WarTroopTypes.aux][WarConstants.cuman_side] = "4c4f6e9d-aa80-4f1b-a9d9-62573e6de2a7"
WarGuids[WarTroopTypes.bow] = {}
WarGuids[WarTroopTypes.bow][WarConstants.rat_side] = "822cfefc-4d92-4fa4-824a-f772b511eeca"
WarGuids[WarTroopTypes.bow][WarConstants.cuman_side] = "8f876dd6-9457-4072-b8f8-693de5debaad"

WarLocations = {
    {
        center = {x = 3136.570,y= 854.815,z= 122.557}, rat = {x = 2995.868,y = 809.014,z = 113.108}, cuman = {x = 3136.570,y= 854.815,z= 122.557}, camp = { x = 2979.425, y = 801.855, z = 110.145 },
        name="Rattay Farmhouse",
        resourceNode = false,
        influence = 8,
    },
    {
        center = {x = 2145.845,y= 967.7307,z= 76.2557}, rat = {x = 2242.227,y = 925.3737,z = 77.3386}, cuman = {x = 2037.570,y= 956.5421,z= 71.7819}, camp = { x = 2264.966, y = 917.7789, z = 76.5017 },
        name="Ledetchko Encampment",
        resourceNode = false,
        influence = 5,
    },
    {
        center = {x = 657.9334,y= 1478.049,z= 47.2376}, rat = {x = 745.2598,y = 1542.538,z = 45.724}, cuman = {x = 606.0286,y= 1462.844,z= 45.5769 }, camp = { x = 762.5239, y = 1541.537, z = 42.5058 },
        name="Sasau Outskirts",
        resourceNode = false,
        influence = 9,
    }
}

-- If your Regional Influence gets too low, enemy starts doing raids on towns and cities
WarRaidLocations = {
    {
        target = { x = 20, y = 20, z = 20 },
        start = { x = 30, y = 30, z = 20 },
        name = "Rattay"
    }
}

WarLocationstest = {
    {
        center = { x=47.969, y=43.522, z=33.583}, rat = { x=27.969, y=43.522, z=33.583}, cuman = { x=67.969, y=43.522, z=33.583}, camp = { x=47.969, y=43.522, z=33.583},
        name="Test battleground",
        influence = 10
    }
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
    rattayStrengthPerWave = WarStrengthPerWave.rattayStrengthPerWave,
    cumanStrengthPerWave = WarStrengthPerWave.cumanStrengthPerWave,
    strengthPerWave = {},
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
    -- in gametime
    timeBattleStarted = 0, 
    -- try not to repeat the same location multiple times
    -- misnomer because its really a key
    ignoreLocationIdx = -1,
    marshal = nil,
    warcamp = nil,
    logiOfficer = nil,
    regionalInfluence = 50,
    
}