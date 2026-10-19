-- Activités : blips, magasin de matériel, revendeur, outils partagés
Act = {}

function Act.Ground(x, y, zGuess)
    zGuess = zGuess or 50.0
    RequestCollisionAtCoord(x, y, zGuess)
    for _ = 1, 40 do
        local ok, z = GetGroundZFor_3dCoord(x, y, zGuess + 80.0, false)
        if ok then return z end
        Wait(50)
    end
    return zGuess
end

function Act.Count(item)
    return exports.ox_inventory:Search('count', item) or 0
end

function Act.ItemLabel(name)
    local it = exports.ox_inventory:Items(name)
    return it and it.label or name
end

local function blip(coords, b, label)
    return Nova.AddBlip(coords, b.sprite, b.color, 0.75, label, true)
end

local function radiusBlip(coords, radius)
    local r = AddBlipForRadius(coords.x, coords.y, coords.z, radius)
    SetBlipColour(r, 0)
    SetBlipAlpha(r, 70)
    return r
end

CreateThread(function()
    blip(ActConfig.Shop.coords, ActConfig.Shop.blip, ActConfig.Shop.label)
    blip(ActConfig.Buyer.coords, ActConfig.Buyer.blip, 'Revendeur')
    blip(ActConfig.Mining.center, ActConfig.Mining.blip, ActConfig.Mining.label)
    radiusBlip(ActConfig.Mining.center, ActConfig.Mining.radius)
    blip(ActConfig.Hunting.center, ActConfig.Hunting.blip, ActConfig.Hunting.label)
    radiusBlip(ActConfig.Hunting.center, ActConfig.Hunting.radius)
    for _, s in ipairs(ActConfig.Fishing.spots) do blip(s.coords, ActConfig.Fishing.blip, s.label) end
end)

---------------------------------------------------------------- PNJ (magasin / revendeur)
local function shopMenu()
    local items = {}
    for i, it in ipairs(ActConfig.Shop.items) do
        items[#items + 1] = {
            label = it.label, rightLabel = ('%s $'):format(Nova.FormatMoney(it.price)),
            description = it.multi and 'Choisis la quantité.' or nil,
            onSelect = function()
                local qty = 1
                if it.multi then
                    qty = Nova.NumberInput(it.label, 'Quantité', 10, 1, 200)
                    if not qty then return end
                end
                local ok, msg = lib.callback.await('nova_activities:buy', false, i, qty)
                Nova.Notify(msg, ok and 'success' or 'error')
            end,
        }
    end
    NovaMenu.Open({ title = 'PLEIN AIR', subtitle = ActConfig.Shop.label, items = items })
end

local function buyerMenu()
    NovaMenu.Open({
        title = 'REVENDEUR', subtitle = 'Ce que tu peux vendre',
        items = function()
            local items, total = {}, 0
            local names = {}
            for name in pairs(ActConfig.Buyer.prices) do names[#names + 1] = name end
            table.sort(names)
            for _, name in ipairs(names) do
                local n = Act.Count(name)
                if n > 0 then
                    local price = ActConfig.Buyer.prices[name]
                    total = total + n * price
                    items[#items + 1] = {
                        label = ('%dx %s'):format(n, Act.ItemLabel(name)), rightLabel = ('%s $'):format(Nova.FormatMoney(n * price)),
                        description = ('%d $ l\'unité'):format(price),
                        onSelect = function()
                            local ok, msg = lib.callback.await('nova_activities:sell', false, name)
                            Nova.Notify(msg, ok and 'success' or 'error')
                            NovaMenu.Refresh()
                        end,
                    }
                end
            end
            if #items == 0 then
                items[1] = { label = 'Tu n\'as rien à vendre', disabled = true, description = 'Minerais, poissons, viande et cuir.' }
            else
                table.insert(items, 1, { label = 'Tout vendre', rightLabel = ('%s $'):format(Nova.FormatMoney(total)), onSelect = function()
                    local ok, msg = lib.callback.await('nova_activities:sell', false, nil)
                    Nova.Notify(msg, ok and 'success' or 'error')
                    NovaMenu.Refresh()
                end })
                table.insert(items, 2, { type = 'separator', label = 'Au détail' })
            end
            return items
        end,
    })
end

local npcs = {
    { cfg = ActConfig.Shop, label = 'Acheter du matériel', icon = 'fa-solid fa-store', fn = shopMenu },
    { cfg = ActConfig.Buyer, label = 'Vendre ma récolte', icon = 'fa-solid fa-hand-holding-dollar', fn = buyerMenu },
}

CreateThread(function()
    while true do
        local me = GetEntityCoords(PlayerPedId())
        for _, n in ipairs(npcs) do
            local c = n.cfg.coords
            local near = #(me.xy - vector2(c.x, c.y)) < 120.0
            if near and not n.ped then
                local model = joaat(n.cfg.ped)
                if Nova.LoadModel(model) then
                    local z = Act.Ground(c.x, c.y, c.z)
                    n.ped = CreatePed(4, model, c.x, c.y, z, c.w, false, true)
                    SetEntityInvincible(n.ped, true)
                    FreezeEntityPosition(n.ped, true)
                    SetBlockingOfNonTemporaryEvents(n.ped, true)
                    TaskStartScenarioInPlace(n.ped, 'WORLD_HUMAN_STAND_IMPATIENT', 0, true)
                    SetModelAsNoLongerNeeded(model)
                    exports.ox_target:addLocalEntity(n.ped, { {
                        name = 'act_npc', label = n.label, icon = n.icon, distance = 2.5,
                        onSelect = function() n.fn() end,
                    } })
                end
            elseif not near and n.ped then
                exports.ox_target:removeLocalEntity(n.ped)
                DeleteEntity(n.ped)
                n.ped = nil
            end
        end
        Wait(1500)
    end
end)

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    for _, n in ipairs(npcs) do if n.ped then DeleteEntity(n.ped) end end
end)
