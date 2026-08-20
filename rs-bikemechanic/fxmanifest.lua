fx_version 'cerulean'

game 'gta5'

lua54 'yes'

author 'Rico Scripts'
description 'RS Mechanic - ESX Motorcycle Mechanic + Dyno'
version '4.0.2'

shared_scripts {

    '@ox_lib/init.lua',

    'config.lua'

}

client_scripts {

    'client/main.lua'

}

server_scripts {

    '@oxmysql/lib/MySQL.lua',

    'server/duty_bridge.lua',

    'server/vehicle_class_compat.lua',

    'server/main.lua'

}

ui_page 'nui/index.html'

files {

    'nui/index.html',

    'nui/**/*'

}

dependencies {

    'es_extended',

    'ox_lib',

    'ox_inventory',

    'ox_target',

    'oxmysql',

    'rs-duty'

}
