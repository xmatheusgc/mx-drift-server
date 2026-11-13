fx_version 'cerulean'
game 'gta5'
description 'MX: identidade, persistência e contratos'
version '0.1.0'
dependency 'oxmysql'
shared_scripts {'shared.lua', 'config.lua'}
server_scripts {'@oxmysql/lib/MySQL.lua', 'server.lua'}
client_script 'client.lua'
files {'shared.lua', 'config.lua'}
