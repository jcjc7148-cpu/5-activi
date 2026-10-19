-- Activités : contrôles et récompenses côté serveur
local function roll(list)
    local total = 0
    for _, l in ipairs(list) do total = total + l[2] end
    local r, acc = math.random() * total, 0
    for _, l in ipairs(list) do
        acc = acc + l[2]
        if r <= acc then return l end
    end
    return list[1]
end

local function label(item)
    local it = exports.ox_inventory:Items(item)
    return it and it.label or item
end

local function give(src, item, count)
    if not exports.ox_inventory:CanCarryItem(src, item, count) then return false end
    return exports.ox_inventory:AddItem(src, item, count)
end

local function near(src, coords, dist)
    local c = GetEntityCoords(GetPlayerPed(src))
    return #(vector2(c.x, c.y) - vector2(coords.x, coords.y)) <= dist
end

---------------------------------------------------------------- MAGASIN / REVENDEUR
lib.callback.register('nova_activities:buy', function(src, index, qty)
    local it = ActConfig.Shop.items[tonumber(index)]
    qty = math.floor(tonumber(qty) or 1)
    if not it or qty < 1 or qty > 200 or (not it.multi and qty ~= 1) then return false, 'Achat invalide.' end
    if not near(src, ActConfig.Shop.coords, 10.0) then return false, 'Approche-toi du vendeur.' end
    if Nova.Cooldown(src, 'actbuy', 1000) then return false, 'Doucement.' end
    local xPlayer = ESX.GetPlayerFromId(src)
    local price = it.price * qty
    if not exports.ox_inventory:CanCarryItem(src, it.item, qty) then return false, 'Tu n\'as pas assez de place.' end
    if xPlayer.getMoney() >= price then xPlayer.removeMoney(price, 'Matériel plein air')
    elseif xPlayer.getAccount('bank').money >= price then xPlayer.removeAccountMoney('bank', price, 'Matériel plein air')
    else return false, ('Il te faut %s $.'):format(Nova.FormatMoney(price)) end
    exports.ox_inventory:AddItem(src, it.item, qty)
    return true, ('%dx %s acheté(s) pour %s $.'):format(qty, it.label, Nova.FormatMoney(price))
end)

lib.callback.register('nova_activities:sell', function(src, only)
    if not near(src, ActConfig.Buyer.coords, 10.0) then return false, 'Approche-toi du revendeur.' end
    if Nova.Cooldown(src, 'actsell', 1500) then return false, 'Doucement.' end
    local xPlayer = ESX.GetPlayerFromId(src)
    local total, sold = 0, 0
    for item, price in pairs(ActConfig.Buyer.prices) do
        if not only or only == item then
            local n = exports.ox_inventory:Search(src, 'count', item) or 0
            if n > 0 and exports.ox_inventory:RemoveItem(src, item, n) then
                total = total + n * price
                sold = sold + n
            end
        end
    end
    if total <= 0 then return false, 'Rien à vendre.' end
    xPlayer.addMoney(total, 'Revente activités')
    Nova.Log('money', 'Revente activités', ('%s a vendu %d objet(s) pour %s $'):format(GetPlayerName(src), sold, Nova.FormatMoney(total)), src)
    return true, ('Vendu %d objet(s) pour %s $.'):format(sold, Nova.FormatMoney(total))
end)

---------------------------------------------------------------- MINE
lib.callback.register('nova_activities:mine', function(src, rock)
    local cfg = ActConfig.Mining
    local p = cfg.rocks[tonumber(rock)]
    if not p or not near(src, vector3(p[1], p[2], 0.0), 6.0) then return false, 'Trop loin du rocher.' end
    if Nova.Cooldown(src, 'actmine', cfg.time - 500) then return false, 'Doucement.' end
    if (exports.ox_inventory:Search(src, 'count', 'pickaxe') or 0) < 1 then return false, 'Il te faut une pioche.' end
    local l = roll(cfg.loot)
    local n = math.random(l[3], l[4])
    if not give(src, l[1], n) then return false, 'Ton inventaire est plein.' end
    local msg = ('+%d %s'):format(n, label(l[1]))
    if math.random(1, 100) <= cfg.breakChance then
        exports.ox_inventory:RemoveItem(src, 'pickaxe', 1)
        msg = msg .. ' — ta pioche s\'est cassée !'
    end
    return true, msg
end)

---------------------------------------------------------------- PÊCHE
lib.callback.register('nova_activities:fish', function(src, success, spot)
    local cfg = ActConfig.Fishing
    if Nova.Cooldown(src, 'actfish', cfg.waitMin * 1000 - 500) then return false, 'Doucement.', 0 end
    local rod = 0
    for item, lvl in pairs(cfg.rods) do
        if lvl > rod and (exports.ox_inventory:Search(src, 'count', item) or 0) > 0 then rod = lvl end
    end
    if rod == 0 then return false, 'Il te faut une canne à pêche.', 0 end
    -- l'appât est consommé à chaque touche ; sans appât, une prise sur deux s'échappe
    local bait = exports.ox_inventory:RemoveItem(src, 'fishbait', 1)
    local left = exports.ox_inventory:Search(src, 'count', 'fishbait') or 0
    if not success then return false, 'Le poisson s\'est échappé.', left end
    if not bait and math.random() < 0.5 then return false, 'Le poisson a filé (pas d\'appât).', left end
    local s = cfg.spots[tonumber(spot) or 0]
    local onSpot = s and near(src, s.coords, s.radius + 10.0)
    local loot = {}
    for _, l in ipairs(cfg.loot) do
        local bonus = (onSpot and (cfg.spotBonus[l[1]] or 0) or 0) + (cfg.spotBonus[l[1]] and (rod - 1) * 4 or 0)
        loot[#loot + 1] = { l[1], l[2] + bonus, l[3], l[4] }
    end
    local l = roll(loot)
    if not give(src, l[1], 1) then return false, 'Ton inventaire est plein.', left end
    return true, ('Tu as attrapé : %s'):format(label(l[1])), left
end)

---------------------------------------------------------------- CHASSE
lib.callback.register('nova_activities:skin', function(src, key)
    local cfg = ActConfig.Hunting
    local loot = cfg.loot[key]
    if not loot then return false, 'Impossible.' end
    if not near(src, cfg.center, cfg.radius + 50.0) then return false, 'Tu n\'es pas dans la zone de chasse.' end
    if Nova.Cooldown(src, 'actskin', cfg.skinTime - 1000) then return false, 'Doucement.' end
    if (exports.ox_inventory:Search(src, 'count', 'WEAPON_KNIFE') or 0) < 1 then return false, 'Il te faut un couteau.' end
    local got = {}
    for _, l in ipairs(loot) do
        local n = math.random(l[2], l[3])
        if n > 0 and give(src, l[1], n) then got[#got + 1] = ('%d %s'):format(n, label(l[1])) end
    end
    if #got == 0 then return false, 'Ton inventaire est plein.' end
    return true, '+' .. table.concat(got, ', ')
end)
