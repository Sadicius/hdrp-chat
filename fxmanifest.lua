fx_version 'cerulean'
rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'
game 'rdr3'

description 'hdrp-chat'
version '1.0.0'

ui_page 'web/ui.html'

files {
    'locales/*.json',
    'web/*.*',
}

shared_script {
    '@ox_lib/init.lua',
    'config.lua'
}

client_scripts {
    'client/client.lua',
    'client/whisper.lua',
}

server_scripts {
    'server/server.lua',
    'server/commands.lua',
}

dependencies {
    'rsg-core',
    'ox_lib',
}

lua54 'yes'