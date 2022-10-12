fx_version 'cerulean'
-- MADE BY Renzuzu
game 'gta5'

lua54 'on'
shared_script '@renzu_shield/init.lua'
shared_script '@ox_lib/init.lua'
ui_page {
    'html/index.html',
}
client_scripts {
	'config.lua',
	'client/main.lua'
}

server_scripts {
	'config.lua',
	'server/main.lua'
}

files {
	'html/index.html',
	'html/script.js',
	'html/style.css',
	'html/levelup.gif',
    'html/audio/*.ogg',
}