ActConfig = {}

-- Les positions n'ont besoin que de x / y : la hauteur du sol est calculée en jeu.

---------------------------------------------------------------- MAGASIN DE MATÉRIEL
ActConfig.Shop = {
    label = 'Matériel de plein air',
    coords = vector4(1338.5, 4225.3, 33.9, 90.0), -- lac Alamo
    ped = 'a_m_m_hillbilly_01',
    blip = { sprite = 52, color = 0 },
    items = {
        { item = 'pickaxe', label = 'Pioche', price = 150 },
        { item = 'fishingrod', label = 'Canne à pêche', price = 120 },
        { item = 'fishbait', label = 'Appât', price = 5, multi = true },
        { item = 'WEAPON_KNIFE', label = 'Couteau de chasse', price = 80 },
        { item = 'WEAPON_MUSKET', label = 'Fusil de chasse', price = 2500 },
        { item = 'ammo-musket', label = 'Cartouches', price = 10, multi = true },
    },
}

---------------------------------------------------------------- REVENDEUR
ActConfig.Buyer = {
    label = 'Revendeur (poissons, minerais, viande)',
    coords = vector4(-1038.5, -1396.8, 5.5, 75.0), -- marché de Vespucci
    ped = 's_m_m_linecook',
    blip = { sprite = 431, color = 0 },
    prices = {
        stone = 4, copper = 18, iron = 25, gold = 70, diamond = 350,
        fish = 15, fish_bass = 25, fish_salmon = 40, fish_catfish = 55, fish_shark = 250,
        meat_rabbit = 20, meat_boar = 45, meat_deer = 60, leather = 35,
    },
}

---------------------------------------------------------------- MINE
ActConfig.Mining = {
    label = 'Carrière (mine)',
    center = vector3(2954.0, 2790.0, 41.0), -- Davis Quartz
    radius = 90.0,
    blip = { sprite = 618, color = 0 },
    rock = 'prop_rock_4_c',
    rockRespawn = 90, -- secondes avant qu'un rocher réapparaisse
    time = 6000,      -- durée du minage (ms)
    breakChance = 3,  -- % de chance de casser la pioche
    rocks = {
        { 2938.6, 2771.9 }, { 2948.1, 2810.9 }, { 2972.4, 2796.2 }, { 2925.3, 2794.6 }, { 2970.9, 2762.6 },
        { 2951.9, 2754.4 }, { 2925.0, 2811.3 }, { 2990.0, 2780.0 }, { 2958.0, 2826.0 }, { 2935.0, 2752.0 },
    },
    loot = { { 'stone', 58, 1, 3 }, { 'copper', 20, 1, 2 }, { 'iron', 14, 1, 2 }, { 'gold', 6, 1, 1 }, { 'diamond', 2, 1, 1 } },
}

---------------------------------------------------------------- PÊCHE
-- On peut pêcher partout face à l'eau (canne + appât). Les spots donnent plus de chances de grosses prises.
ActConfig.Fishing = {
    blip = { sprite = 68, color = 0 },
    spots = {
        { label = 'Spot de pêche', coords = vector3(-1850.0, -1247.0, 8.6), radius = 60.0 },  -- jetée de Del Perro
        { label = 'Spot de pêche', coords = vector3(1301.0, 4224.0, 33.9), radius = 80.0 },   -- lac Alamo
        { label = 'Spot de pêche', coords = vector3(-275.0, 6635.0, 7.5), radius = 60.0 },    -- jetée de Paleto
    },
    waitMin = 6, waitMax = 18, -- secondes avant que ça morde
    loot = { { 'fish', 48, 1, 1 }, { 'fish_bass', 26, 1, 1 }, { 'fish_salmon', 15, 1, 1 }, { 'fish_catfish', 9, 1, 1 }, { 'fish_shark', 2, 1, 1 } },
    spotBonus = { fish_salmon = 6, fish_catfish = 4, fish_shark = 2 }, -- chances en plus sur un spot
    -- Cannes acceptées (nom de l'objet = niveau : plus il est haut, plus les grosses prises sont fréquentes)
    rods = { fishingrod = 1, canneapeche = 1, canneapechecarbonne = 2, canneapecheoretcarbonne = 3 },
}

---------------------------------------------------------------- CHASSE
ActConfig.Hunting = {
    label = 'Zone de chasse',
    center = vector3(-1150.0, 4550.0, 140.0), -- forêt du mont Chiliad
    radius = 450.0,
    blip = { sprite = 141, color = 0 },
    maxAnimals = 5,
    spawnDistance = { 45.0, 90.0 },
    animals = {
        { model = 'a_c_deer', key = 'deer', chance = 40 },
        { model = 'a_c_boar', key = 'boar', chance = 30 },
        { model = 'a_c_rabbit_01', key = 'rabbit', chance = 30 },
    },
    loot = {
        deer = { { 'meat_deer', 2, 4 }, { 'leather', 1, 2 } },
        boar = { { 'meat_boar', 2, 3 }, { 'leather', 1, 1 } },
        rabbit = { { 'meat_rabbit', 1, 2 } },
    },
    skinTime = 7000,
}
