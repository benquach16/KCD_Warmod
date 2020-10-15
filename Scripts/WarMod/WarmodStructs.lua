-- Constant struct
WarConstants = {
    cSaveLockName = "warmodsavelock",
    cMarshalName = "warmodmarshal",
    -- todo: inconsistent naming schema, change to camel case
    rat_side = 1,
    cuman_side = 2,
    troopCost = 100,
    waveCost = 200,
    numWaves = 8,
    corpseTime = 15000, --15 seconds
    victoryTime = 20000, -- 20 seconds
    waveInterval = 75000, -- 75 seconds
    
    -- todo: put this in another data structure that will help set up a whole encampment
    campMesh = "objects/structures/tent_cuman/tent_cuman_v6_b.cgf",
    squadNumberVariance = 1,
    
    eventChance = 40 -- clamp this to 0 to 100
}

WarEncampmentMeshes = {
    { -- tent
        mesh = "objects/structures/tent_cuman/tent_cuman_v6_b.cgf",
        class = "BasicEntity",
        offset = { x = 0, y = 0, z = 0 },
        orientation = { x = 1, y = 0, z = 0}
    },
    { -- table or something
        mesh = "objects/structures/tent_cuman/tent_cuman_v6_b.cgf",
        class = "BasicEntity",
        offset = { x = 0, y = 0, z = 0 },
        orientation = { x = 1, y = 0, z = 0}
    },
    { -- weapons rack
        mesh = "objects/structures/tent_cuman/tent_cuman_v6_b.cgf",
        class = "BasicEntity",
        offset = { x = 0, y = 0, z = 0 },
        orientation = { x = 1, y = 0, z = 0}
    },
}

WarEvents = {
    cumanMoreArchers = 0,
    ratMoreArchers = 1,
    lessWaves = 2,
    --cumanAmbush = 3,
    --rattayAmbush = 4
}

WarRewards = {
    base = 250,
    perWave = 150,
    perKill = 6,
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

-- is this still worth it? event system can substitute some of this
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
    veryhard = 120,
    impossible = 160
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
WarStrengthPerWave[WarTroopTypes.halberd][WarConstants.cuman_side] = 5
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
        influence = 12,
    },
    {
        center = {x = 2089.945,y= 975.7307,z= 73.8557}, rat = {x = 2151.766,y = 1075.697,z = 59.3605}, cuman = {x = 2037.570,y= 956.5421,z= 71.7819}, camp = { x = 2164.941, y = 1090.227, z = 54.1317 },
        name="Ledetchko Assault",
        resourceNode = false,
        influence = 5,
    },
    {
        center = {x = 657.9334,y= 1478.049,z= 47.2376}, rat = {x = 745.2598,y = 1542.538,z = 45.724}, cuman = {x = 606.0286,y= 1462.844,z= 45.5769 }, camp = { x = 762.5239, y = 1541.537, z = 42.5058 },
        name="Sasau Outskirts",
        resourceNode = false,
        influence = 12,
    },
    {
        center = {x = 3241.431,y= 1622.319,z= 125.2832}, rat = {x = 3318.59,y = 1606.279,z = 134.142}, cuman = {x = 3148.392,y= 1617.583,z= 134.8769 }, camp = { x = 3327.961, y = 1607.87, z = 137.135 },
        name="Glade by Neuhof",
        resourceNode = false,
        influence = 7,
    },
    {
        center = {x = 3185.878,y= 2788.162,z= 172.306}, rat = {x = 3190.970,y = 2679.227,z = 178.983}, cuman = {x = 3119.160,y= 2775.543,z= 178.973 }, camp = { x = 3208.894, y = 2679.775, z = 182.106 },
        name="Uzhitz Farmstead",
        resourceNode = false,
        influence = 8,
    },
    {
        center = {x = 2429.339,y= 1431.145,z= 26.173}, rat = {x = 2478.896,y = 1460.795,z = 28.472}, cuman = {x = 2452.467,y=1358.63,z= 30.273 }, camp = { x = 2490.646, y = 1471.634, z = 28.122 },
        name="Waterway Crossing",
        resourceNode = false,
        influence = 5,
    },
    {
        center = {x = 1278.3,y=1086.085,z=18.95}, rat = {x =1280.972,y =1028.137,z = 28.3514}, cuman = {x =1320.383,y=1100.662,z=22.02 }, camp = { x =1309.143, y = 1017.945, z = 27 },
        name="West Forest Camp",
        resourceNode = false,
        influence = 9,
    },
    {
        center = {x = 2211.522,y=2168.705,z=137.704}, rat = {x =2141.664,y =2224.004,z = 157.082}, cuman = {x =2241.437,y=2129.12,z=132.246 }, camp = { x =2135.879, y = 2236.649, z = 159.522 },
        name="Road to Merhojed",
        resourceNode = false,
        influence = 13,
    },
    {
        center = {x = 860.044,y=2197.744,z=37.991}, rat = {x =919.13,y =2201.141,z = 48.582}, cuman = {x =800.501,y=2239.367,z=30.563 }, camp = { x =926.977, y = 2184.792, z = 52.51 },
        name="Field by Samopesh",
        resourceNode = false,
        influence = 8,
    },
    {
        center = {x = 370.944,y=1878.444,z=17.991}, rat = {x =364.72,y =1859.137,z = 18.382}, cuman = {x =320.63355,y=1912.88,z=20.5 }, camp = { x=369.22,y =1851.437,z = 20.582 },
        name="Bridge Crossing",
        resourceNode = false,
        influence = 7,
    },
    {
        center = {x = 858.944,y=2661.044,z=52.991}, rat = {x =814.4106,y =2680.68,z = 75.3123}, cuman = {x =866.9485,y=2747.528,z=57.06 }, camp = { x=802.9427,y =2672.488,z = 81.0 },
        name="South Skalitz Mineshaft",
        resourceNode = false,
        influence = 11,
    },
    {
        center = {x = 985.0812,y=2748.828,z=72.991}, rat = {x =1028.441,y =2791.381,z = 67.3123}, cuman = {x =983.0874,y=2666.154,z=57.6 }, camp = {x =1025.441,y =2800.381,z = 68.3123},
        name="Mountainside Assault",
        resourceNode = false,
        influence = 11,
    }
}

-- If your Regional Influence gets too low, enemy starts doing raids on towns and cities
WarRaidLocations = {
    {
        rat = {x =2558.429,y =463.0462,z = 68.1582}, cuman = {x =2370.252,y=558.5708,z=32.163 }, camp = { x =2552.782, y = 512.0674, z = 72.5 },
        name="Castle Pirkstein and Rattay",
        resourceNode = false,
        influence = 15,
    },
    {
        rat = {x =911.6,y =1703.476,z = 43.7582}, cuman = {x =805.8848,y=1708.74,z=59.8 }, camp = { x =908, y = 1697.313, z = 42.7 },
        name="Sasau Monastary",
        resourceNode = false,
        influence = 15,
    }
}

-- If your Regional Influence gets too high, you start making assaults on enemy camps
WarAssaultLocations = {
    {
        rat = {x =866.8859,y =3199.533,z = 23.8}, cuman = {x =870.2924,y=3336.631,z=24.963 }, camp = { x =854.09, y = 3177.754, z = 32.4 },
        name="Skalitz Camp Assault",
        resourceNode = false,
        influence = 15,
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
    cumanCommander = nil,
    
    currentEvent = nil,
    isDefense = false,
    isAssault = false,
    
}

WarController = {
    Rattay = Side,
    Cuman = Side,
    needReload = false,
    -- only 1 battle can occur at a time
    inBattle = false,
    readyForNewBattle = true,
    currentBattle = Battle,
    -- important - this can refer to different structures, war locations, war raid locations, etc
    nextBattleLocation = nil,
    

    -- in gametime
    timeBattleStarted = 0, 
    -- try not to repeat the same location multiple times
    -- misnomer because its really a key
    ignoreLocationIdx = -1,
    marshal = nil,
    logiOfficer = nil,
    regionalInfluence = 50,
    
}