fx_version 'cerulean'

game 'gta5'

lua54 'yes'

author 'Rico Scripts'
description 'RS Mechanic - ESX Motorcycle Mechanic + Dyno + Moto Lift'
version '4.1.0'

shared_scripts {

    '@ox_lib/init.lua',

    'config.lua',

    'lift_config.lua'

}

client_scripts {

    'client/main.lua',

    'client/lift.lua'

}

server_scripts {

    '@oxmysql/lib/MySQL.lua',

    'server/duty_bridge.lua',

    'server/vehicle_class_compat.lua',

    'server/main.lua',

    'server/lift.lua'

}

ui_page 'nui/index.html'

files {

    'nui/index.html',

    'nui/**/*',

    'inventory_images/*.png'

}

dependencies {

    'es_extended',

    'ox_lib',

    'ox_inventory',

    'ox_target',

    'oxmysql',

    'rs-duty'

}
