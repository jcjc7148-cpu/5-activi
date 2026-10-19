-- Pêche : utiliser la canne face à l'eau (un appât par lancer). X pour arrêter.
local cfg = ActConfig.Fishing
local fishing = false

-- Y a-t-il de l'eau devant (rivière, lac, mer, au bout d'un ponton...) ?
local function facingWater()
    local ped = PlayerPedId()
    if IsEntityInWater(ped) then return true end
    local c = GetEntityCoords(ped)
    for d = 2, 24, 2 do
        local p = GetOffsetFromEntityInWorldCoords(ped, 0.0, d + 0.0, 0.0)
        local ok, h = GetWaterHeightNoWaves(p.x, p.y, c.z + 2.0)
        if ok and h <= c.z + 1.0 then
            local g, gz = GetGroundZFor_3dCoord(p.x, p.y, c.z + 2.0, false)
            if not g or gz <= h + 0.3 then return true end
        end
    end
    local from = c + vector3(0.0, 0.0, 1.0)
    local to = GetOffsetFromEntityInWorldCoords(ped, 0.0, 15.0, -25.0)
    local hit = TestProbeAgainstWater(from.x, from.y, from.z, to.x, to.y, to.z)
    return hit == true or hit == 1
end

local function currentSpot()
    local me = GetEntityCoords(PlayerPedId())
    for i, s in ipairs(cfg.spots) do
        if #(me - s.coords) <= s.radius then return i end
    end
    return nil
end

local function stop()
    fishing = false
    Nova.HideHelp()
    ClearPedTasks(PlayerPedId())
end

local function fish()
    if fishing then return stop() end
    local ped = PlayerPedId()
    if cache.vehicle or IsPedSwimming(ped) then return Nova.Notify('Impossible de pêcher ici.', 'error') end
    if not facingWater() then return Nova.Notify('Mets-toi face à l\'eau pour pêcher (bord d\'un lac, d\'une rivière, ponton...).', 'error') end
    if Act.Count('fishbait') < 1 then Nova.Notify('Sans appât, ça mord beaucoup moins (appâts au magasin de plein air).', 'info', 5000) end

    fishing = true
    TaskStartScenarioInPlace(ped, 'WORLD_HUMAN_STAND_FISHING', 0, true)
    Nova.ShowHelp('Arrêter de pêcher', 'X')
    CreateThread(function()
        while fishing do
            local bait = Act.Count('fishbait') > 0
            local wait = GetGameTimer() + math.random(cfg.waitMin, cfg.waitMax) * (bait and 1000 or 1600)
            while fishing and GetGameTimer() < wait do
                if IsControlJustPressed(0, 73) or IsPedRagdoll(ped) or IsPedDeadOrDying(ped, true) or cache.vehicle then stop() return end
                if not IsPedUsingAnyScenario(ped) then TaskStartScenarioInPlace(ped, 'WORLD_HUMAN_STAND_FISHING', 0, true) end
                Wait(0)
            end
            if not fishing then return end
            PlaySoundFrontend(-1, 'Beep_Red', 'DLC_HEIST_HACKING_SNAKE_SOUNDS', true)
            Nova.Notify('Ça mord !', 'info', 1500)
            local success = lib.skillCheck({ 'easy', 'medium' }, { 'e' })
            local ok, msg = lib.callback.await('nova_activities:fish', false, success, currentSpot())
            Nova.Notify(msg, ok and 'success' or 'error', 3000)
        end
    end)
end

exports('useRod', function() fish() end)
RegisterCommand('pecher', fish, false)
