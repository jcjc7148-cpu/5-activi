fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'nova_activities'
author 'Vexora'
description 'Activités libres : mine, pêche, chasse (zones, matériel, revente)'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    '@es_extended/imports.lua',
    '@nova_core/lib/shared.lua',
    'config.lua',
}

client_scripts {
    '@nova_core/lib/menu.lua',
    'client/main.lua',
    'client/mining.lua',
    'client/fishing.lua',
    'client/hunting.lua',
}

server_scripts { 'server/main.lua' }

dependencies { 'nova_core', 'ox_inventory', 'ox_target' }
