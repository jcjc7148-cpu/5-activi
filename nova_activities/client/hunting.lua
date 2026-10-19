-- Chasse : des animaux apparaissent autour de toi dans la zone. Abats-les puis dépèce-les au couteau.
local cfg = ActConfig.Hunting
local animals = {} -- [entity] = key

local function pick()
    local roll, acc = math.random(1, 100), 0
    for _, a in ipairs(cfg.animals) do
        acc = acc + a.chance
        if roll <= acc then return a end
    end
    return cfg.animals[1]
end

local function count()
    local n = 0
    for ent in pairs(animals) do
        if DoesEntityExist(ent) and not IsEntityDead(ent) then n = n + 1 end
    end
    return n
end

local function hasKnife()
    return Act.Count('WEAPON_KNIFE') > 0
end

local function skin(ent)
    local key = animals[ent]
    if not key or not DoesEntityExist(ent) then return end
    if not hasKnife() then return Nova.Notify('Il te faut un couteau de chasse.', 'error') end
    TaskTurnPedToFaceEntity(PlayerPedId(), ent, 800)
    Wait(800)
    if not lib.progressBar({
        duration = cfg.skinTime, label = 'Tu dépèces l\'animal...', canCancel = true,
        disable = { move = true, car = true, combat = true },
        anim = { dict = 'amb@medic@standing@kneel@base', clip = 'base', flag = 1 },
    }) then return end
    local ok, msg = lib.callback.await('nova_activities:skin', false, key)
    Nova.Notify(msg, ok and 'success' or 'error')
    if ok then
        exports.ox_target:removeLocalEntity(ent)
        animals[ent] = nil
        SetEntityAsMissionEntity(ent, true, true)
        DeleteEntity(ent)
    end
end

local function spawnAnimal()
    local a = pick()
    local model = joaat(a.model)
    if not Nova.LoadModel(model) then return end
    local me = GetEntityCoords(PlayerPedId())
    local ang = math.random() * math.pi * 2
    local d = cfg.spawnDistance[1] + math.random() * (cfg.spawnDistance[2] - cfg.spawnDistance[1])
    local x, y = me.x + math.cos(ang) * d, me.y + math.sin(ang) * d
    if #(vector3(x, y, me.z) - cfg.center) > cfg.radius then return end
    local z = Act.Ground(x, y, me.z)
    if TestVerticalProbeAgainstAllWater(x, y, z + 1.0, 0) then return end
    local ped = CreatePed(28, model, x, y, z + 0.5, math.random(0, 359) + 0.0, false, true)
    SetModelAsNoLongerNeeded(model)
    SetEntityAsMissionEntity(ped, true, true)
    TaskWanderStandard(ped, 10.0, 10)
    animals[ped] = a.key
    exports.ox_target:addLocalEntity(ped, { {
        name = 'act_skin', label = 'Dépecer l\'animal', icon = 'fa-solid fa-paw', distance = 2.0,
        canInteract = function(entity) return IsEntityDead(entity) and not cache.vehicle end,
        onSelect = function(data) skin(data.entity) end,
    } })
end

local function clearAll()
    for ent in pairs(animals) do
        if DoesEntityExist(ent) then exports.ox_target:removeLocalEntity(ent) DeleteEntity(ent) end
    end
    animals = {}
end

CreateThread(function()
    while true do
        local me = GetEntityCoords(PlayerPedId())
        local inside = #(me - cfg.center) <= cfg.radius
        if inside then
            -- nettoie les animaux trop loin
            for ent in pairs(animals) do
                if not DoesEntityExist(ent) or #(GetEntityCoords(ent) - me) > 250.0 then
                    if DoesEntityExist(ent) then exports.ox_target:removeLocalEntity(ent) DeleteEntity(ent) end
                    animals[ent] = nil
                end
            end
            if count() < cfg.maxAnimals then spawnAnimal() end
        elseif next(animals) then
            clearAll()
        end
        Wait(inside and 4000 or 8000)
    end
end)

AddEventHandler('onResourceStop', function(res) if res == GetCurrentResourceName() then clearAll() end end)
