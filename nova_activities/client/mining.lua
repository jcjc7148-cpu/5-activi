-- Mine : des rochers apparaissent dans la carrière, on les casse à la pioche
local cfg = ActConfig.Mining
local rocks = {} -- [i] = { entity, respawnAt }
local busy = false

local function mine(i)
    if busy then return end
    if Act.Count('pickaxe') < 1 then return Nova.Notify('Il te faut une pioche (magasin de plein air).', 'error') end
    busy = true
    local ok = lib.progressBar({
        duration = cfg.time, label = 'Tu casses la roche...', canCancel = true,
        disable = { move = true, car = true, combat = true },
        anim = { dict = 'melee@large_wpn@streamed_core', clip = 'ground_attack_on_spot', flag = 1 },
        prop = { model = 'prop_tool_pickaxe', bone = 57005, pos = vec3(0.18, -0.02, -0.02), rot = vec3(-90.0, 180.0, 0.0) },
    })
    if ok then
        local res, msg = lib.callback.await('nova_activities:mine', false, i)
        Nova.Notify(msg, res and 'success' or 'error')
        if res then
            local r = rocks[i]
            if r and r.entity then
                exports.ox_target:removeLocalEntity(r.entity)
                DeleteEntity(r.entity)
                r.entity = nil
                r.respawnAt = GetGameTimer() + cfg.rockRespawn * 1000
            end
        end
    end
    busy = false
end

local function spawnRock(i)
    local p = cfg.rocks[i]
    local model = joaat(cfg.rock)
    if not Nova.LoadModel(model) then return end
    local z = Act.Ground(p[1], p[2], cfg.center.z)
    local obj = CreateObject(model, p[1], p[2], z - 0.4, false, false, false)
    SetEntityHeading(obj, (i * 47) % 360 + 0.0)
    FreezeEntityPosition(obj, true)
    SetModelAsNoLongerNeeded(model)
    exports.ox_target:addLocalEntity(obj, { {
        name = 'act_mine', label = 'Miner', icon = 'fa-solid fa-hammer', distance = 2.5,
        canInteract = function() return not busy and not cache.vehicle end,
        onSelect = function() mine(i) end,
    } })
    rocks[i] = { entity = obj }
end

local function clear()
    for _, r in pairs(rocks) do
        if r.entity then exports.ox_target:removeLocalEntity(r.entity) DeleteEntity(r.entity) end
    end
    rocks = {}
end

CreateThread(function()
    while true do
        local inside = #(GetEntityCoords(PlayerPedId()) - cfg.center) < cfg.radius + 60.0
        if inside then
            for i in ipairs(cfg.rocks) do
                local r = rocks[i]
                if not r or (not r.entity and r.respawnAt and GetGameTimer() >= r.respawnAt) then spawnRock(i) end
            end
        elseif next(rocks) then
            clear()
        end
        Wait(inside and 2000 or 5000)
    end
end)

AddEventHandler('onResourceStop', function(res) if res == GetCurrentResourceName() then clear() end end)
