local RSGcore = exports['rsg-core']:GetCoreObject()

RegisterNetEvent('chat:whisper')
AddEventHandler('chat:whisper', function(id, name, message, time)
    local id1 = PlayerId()
    local id2 = GetPlayerFromServerId(id)
    local sourcePlayer = GetPlayerFromServerId(id1)

    -- Asynchronously retrieve the player data
    RSGcore.Functions.GetPlayerData(function(PlayerData)
        local firstname = PlayerData.charinfo.firstname
        local lastname = PlayerData.charinfo.lastname
        local playerName = firstname .. ' ' .. lastname

        -- Check the distance and broadcast the message if it's within the bisikDistance limit
        if id2 == id1 or GetDistanceBetweenCoords(GetEntityCoords(GetPlayerPed(id1)), GetEntityCoords(GetPlayerPed(id2)), true) < Config.bisikDistance then
            TriggerEvent('chat:addMessage', {
                template = [[
                    <div class="chat-message" style=
                        "background-color: var(--bg-mensaje);
                        color: var(--color-plata);
                        border-left: 4px solid var(--color-ooc);
                        padding-left: 12px;">
                        <i class="fas fa-ear-listen" style="
                        color: var(--color-ooc); 
                        margin-right: 6px;"></i>
                        <b><span style="font-size: var(--fuente-size-text); color: var(--color-do);">[WHISPER] {0}</span></b>
                        <span style="font-size: var(--fuente-size-title); color: var(--color-do); float: right;">{2}</span>
                        <div style="margin-top: 5px; font-weight: 300; color: var(--color-do);">
                            {1}
                        </div>
                    </div>
                ]],
                args = {playerName, message, time}
            })
        end
    end)
end)

RegisterNetEvent('hdrp-chat:client:SendReport', function(name, src, msg)
    TriggerServerEvent('hdrp-chat:server:SendReport', name, src, msg)
end)