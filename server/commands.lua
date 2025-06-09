local RSGCore = exports['rsg-core']:GetCoreObject()
local ChatSystem = {
    reportCooldowns = {},
    advertisementCooldowns = {},
    commandCooldowns = {},
    reports = {}
}
lib.locale()
----------------------
-- functions
----------------------
local function sendChat(src, player, template, message, senderName, source)
    if not player and not senderName and not source then
        TriggerClientEvent('chat:addMessage', src, { template = template, args = { message } })
    elseif not senderName and not source then
        TriggerClientEvent('chat:addMessage', src, { template = template, args = { player, message } })
    else
        TriggerClientEvent('chat:addMessage', src, { template = template, args = { senderName, source, message } })
    end
end

local function logToDiscord(category, title, color, content)
    TriggerEvent('rsg-log:server:CreateLog', category, title, color, content, false)
end

local function auditLog(action, src, extraData, severity)
    local Player = RSGCore.Functions.GetPlayer(src)
    local identifier = Player and Player.PlayerData and Player.PlayerData.citizenid or "Unknown"
    local name = GetPlayerName(src) or "Unknown"
    local color = severity == "high" and "red"
               or severity == "medium" and "orange"
               or "gray"

    local message = string.format("**"..locale('cl_lang_1')..":** %s\n**"..locale('cl_lang_2')..":** %s [%s]\n**"..locale('cl_lang_3')..":** %s",
        action,
        name,
        identifier,
        extraData or "N/A"
    )
    logToDiscord('audit', locale('cl_lang_4'), color, message)
end

local function getPlayersWithStaffRoles()
    local players = {}
    for k, v in ipairs(RSGCore.Functions.GetPlayers()) do
        for j, x in ipairs(Config.StaffGroups) do
            if RSGCore.Functions.GetPermission(v) == x then
                table.insert(players, v)
                break
            end
        end
    end

    return players
end

local function HasStaffPermission(src)
    return RSGCore.Functions.HasPermission(src, 'admin') or IsPlayerAceAllowed(src, 'command')
end

local function IsPlayerNear(src, target, distance)
    local ped1 = GetPlayerPed(src)
    local ped2 = GetPlayerPed(target)
    if not ped1 or not ped2 then return false end
    local coords1 = GetEntityCoords(ped1)
    local coords2 = GetEntityCoords(ped2)
    return #(coords1 - coords2) <= distance
end

local function HasCooldown(src, key, seconds)
    local now = os.time()
    if not ChatSystem.commandCooldowns[src] then ChatSystem.commandCooldowns[src] = {} end
    if not ChatSystem.commandCooldowns[src][key] or now - ChatSystem.commandCooldowns[src][key] >= seconds then
        ChatSystem.commandCooldowns[src][key] = now
        return false
    end
    return true
end

----------------------
--restart announcement
----------------------
local times = {
    [1800] = '30 min',
    [900] = '15 min',
    [600] = '10 min',
    [300] = '5 min',
    [240] = '4 min',
    [180] = '3 min',
    [120] = '2 min',
    [60] = '1 min'.. locale('cl_lang_5'),
}

AddEventHandler('txAdmin:events:announcement', function(data)
    local template = [[ <div class="chat-message">
        <i class="fas fa-bullhorn" style="color: var(--color-anuncio); margin-right: 6px;"></i>
        <b> <span style="color: var(--color-anuncio); font-size: var(--fuente-size-text);">'[ANNOUNCEMENT]'</span> </b>
        <span style="var(--fuente-size-anuncio) color: var(--color-anuncio); font-weight: 400;"> {0}</span>
    </div> ]]
    sendChat(-1, nil, template, data.message)
end)

AddEventHandler('txAdmin:events:scheduledRestart', function(data)
    local message = locale('cl_lang_6')..' ' .. times[data.secondsRemaining]
    local template = [[ <div class="chat-message">
        <i class="fas fa-desktop" style="background: var(--bg-anuncio); color: var(--color-anuncio); margin-right: 6px;"></i>
        <b> <span style="color: var(--color-anuncio); font-size: var(--fuente-size-text);">[REINICIO]</span> </b>
        <span style="var(--fuente-size-anuncio) color: var(--color-anuncio); font-weight: 400;"> {0}</span>
    </div> ]]
    sendChat(-1, nil, template, message)
end)

----------------------
-- commands staff
----------------------
if Config.AllowStaffsToClearEveryonesChat then
    RegisterCommand(Config.ClearEveryonesChatCommand, function(source, args, rawCommand)
        local src = source
        if not HasStaffPermission(src) then auditLog(locale('cl_lang_7'), src, locale('cl_lang_8').." /" .. Config.ClearEveryonesChatCommand .. " ".. locale('cl_lang_9')) TriggerClientEvent('ox_lib:notify', src, { title = locale('cl_lang_10'), description = locale('cl_lang_11'), type = 'error' }) return
        else
            TriggerClientEvent('chat:client:ClearChat', -1)
            TriggerClientEvent('ox_lib:notify', -1, { title = locale('cl_lang_12'), description = locale('cl_lang_13'), type = 'success', duration = 4000 })
            auditLog(locale('cl_lang_14'), src, locale('cl_lang_15'))
        end
    end, false)
end

if Config.EnableStaffCommand then
    RegisterCommand(Config.StaffCommand, function(source, args, rawCommand)
        local Player = RSGCore.Functions.GetPlayer(source)
        local length = string.len(Config.StaffCommand)
        local message = rawCommand:sub(length + 1)
        local playerName = Player.PlayerData.name
        local src = source
        if #args < 1 then TriggerClientEvent('ox_lib:notify', src, { title = 'Staff Command', description = string.format(locale('cl_lang_41'), Config.StaffCommand), type = 'error', duration = 5000 }) return end
        if not HasStaffPermission(src) then auditLog("Intento de Comando sin Permiso", src, "Intentó usar /" .. Config.StaffCommand .. " sin permisos.") TriggerClientEvent('ox_lib:notify', src, { title = locale('cl_lang_43'), description = locale('cl_lang_42'), type = 'error' }) return
        else
            local template = '<div class="chat-message" style="background: var(--bg-anuncio); border-left: 12px solid var(--color-anuncio); padding: var(--padding-base);">' ..
                '<i class="fas fa-shield-alt" style="color: var(--color-hierro); margin-right: 6px;"></i>' ..
                '<span style="color: var(--color-anuncio);  margin-right: 6px; font-weight: bold; font-size: var(--fuente-size-title);">[ANNOUNCEMENT]</span> ' ..'\n'..
                '<span style="color: var(--color-anuncio); font-size: var(--fuente-size-text);">' .. message .. '</span></div>'
            sendChat(-1, nil, template, nil)
            local discordMessage = string.format(
                "**Staff Command Used**\n**Player Name:** %s\n**Message:** %s",
                playerName,
                message
            )
           logToDiscord('staff', 'STAFF COMMAND', 'blue', discordMessage)
        end
    end, false)
end

if Config.EnableStaffOnlyCommand then
    RegisterCommand(Config.StaffOnlyCommand, function(source, args, rawCommand)
        local src = source
        local Player = RSGCore.Functions.GetPlayer(src)
        local length = string.len(Config.StaffOnlyCommand)
        local message = rawCommand:sub(length + 2):match("^%s*(.*)")  -- Limpia espacios extras
        if #args < 1 or message == '' then TriggerClientEvent('ox_lib:notify', src, { title = 'Admin Chat', description = string.format(locale('cl_lang_41'), Config.StaffOnlyCommand), type = 'error', duration = 5000 }) return end
        local playerName = Player.PlayerData.name
        if not HasStaffPermission(src) then auditLog("Intento de Comando sin Permiso", src, "Intentó usar /" .. Config.StaffOnlyCommand .. " sin permisos.") TriggerClientEvent('ox_lib:notify', src, { title = locale('cl_lang_43'), description = locale('cl_lang_42'), type = 'error' }) return
        else
            local staffPlayers = getPlayersWithStaffRoles()  -- Debe retornar lista de source IDs
            local formattedMessage =
                '<div class="chat-message" style="background: var(--bg-anuncio); border-left: 8px solid var(--color-staff); padding: var(--padding-base);">' ..
                '<i class="fas fa-eye-slash" style="color: var(--color-hierro); margin-right: 6px;"></i>' ..
                '<span style="color: var(--color-staff); font-weight: bold; font-size: var(--fuente-size-text);">[ADMIN] ' .. playerName .. ':</span> ' ..
                '<span style="color: var(--color-staff); font-size: var(--fuente-size-text);">' .. message .. '</span></div>'
            for _, staffSrc in ipairs(staffPlayers) do
                sendChat(staffSrc, nil, formattedMessage, nil)
            end
            local discordMessage = string.format(
                "**Staff Only Command Used**\n**Player Name:** %s\n**Message:** %s",
                playerName,
                message
            )
            logToDiscord('staffonly', 'STAFF ONLY COMMAND', 'blue', discordMessage)
            TriggerClientEvent('chat:addMessage', src, { template = formattedMessage, args = {} })
        end
    end, false)
end

----------------------
-- system report
----------------------
if Config.EnableReportCommand then
    RegisterCommand(Config.ReportCommand, function(source, args, rawCommand)
        local src = source
        if #args < 1 then TriggerClientEvent('ox_lib:notify', source, {title = 'Report', description = 'Usage: /'..Config.ReportCommand..' [message]', type = 'error', duration = 5000 }) return end
        local msg = table.concat(args, ' ')
        local Player = RSGCore.Functions.GetPlayer(src)
        if not Player or not Player.PlayerData then return TriggerClientEvent('ox_lib:notify', src, { title = 'Sistema de Reportes', description = 'Error al obtener datos del jugador.', type = 'error' }) end
        if ChatSystem.reportCooldown[src] and os.time() - ChatSystem.reportCooldown[src] < 60 then TriggerClientEvent('ox_lib:notify', src, { title = 'Sistema de Reportes', description = 'Debes esperar un momento antes de enviar otro reporte.', type = 'error', duration = 5000 }) return end

        local id = #ChatSystem.reports + 1
        ChatSystem.reports[id] = {
            reporter = src,
            message = msg,
            log = {
                {   author = GetPlayerName(src),
                    msg = msg,
                    date = os.date("%d/%m/%Y %H:%M:%S")
                }
            }
        }

        for _, playerId in ipairs(RSGCore.Functions.GetPlayers()) do
            local xPlayer = tonumber(playerId)
            if not HasStaffPermission(src) then auditLog("Intento de Comando sin Permiso", src, "Intentó usar /"..Config.ReportCommand.." sin permisos.") TriggerClientEvent('ox_lib:notify', src, { title = locale('cl_lang_43'), description = locale('cl_lang_42'), type = 'error' }) return end
            if xPlayer and HasStaffPermission(tonumber(playerId)) then TriggerClientEvent('ox_lib:notify', tonumber(playerId), { title = 'Nuevo Reporte', description = string.format('ID %d | %s: %s', id, GetPlayerName(src), msg), type = 'inform' }) end
        end

        ChatSystem.reportCooldown[src] = os.time()

        TriggerClientEvent('ox_lib:notify', src, { title = 'Sistema de Reportes', description = 'Reporte enviado correctamente. El staff lo revisará pronto.', type = 'success' })
        TriggerClientEvent('rsg-chat:client:SendReport', -1, GetPlayerName(src), src, msg)
        local discordMessage = string.format(
                "Citizenid:** %s\n**Ingame ID:** %d\n**Name:** %s %s\n**Report:** %s**",
                Player.PlayerData.citizenid,
                Player.PlayerData.cid,
                Player.PlayerData.charinfo.firstname,
                Player.PlayerData.charinfo.lastname,
                msg
            )
        logToDiscord('report', 'REPORT', 'green', discordMessage)
    end, false)

    RegisterCommand(Config.ListReportCommand, function(source)
        local src = source
        local xPlayer = RSGCore.Functions.GetPlayer(src)
        if not xPlayer then return end
        if not HasStaffPermission(src) then auditLog("Intento de Comando sin Permiso", src, "Intentó usar  /"..Config.ListReportCommand.." sin permisos.") TriggerClientEvent('ox_lib:notify', src, { title = locale('cl_lang_43'), description = locale('cl_lang_42'), type = 'error' }) return end
        if not next(ChatSystem.reports) then TriggerClientEvent('ox_lib:notify', src, { title = 'Sistema de Reportes', description = 'No hay reportes activos actualmente.', type = 'inform' }) return end

        TriggerClientEvent('chat:addMessage', src, {
            color = { 255, 255, 0 },
            multiline = true,
            args = { "^3Reportes Activos", "ID | Jugador | Mensaje" }
        })

        for id, data in pairs(ChatSystem.reports) do
            local reporterName = GetPlayerName(data.reporter) or "Desconocido"
            local text = string.format("^2%d^0 | ^5%s^0 | %s", id, reporterName, data.message)

            TriggerClientEvent('chat:addMessage', src, {
                color = { 255, 255, 255 },
                args = { text }
            })
        end
    end, false)

    RegisterCommand(Config.CloseReportCommand, function(source, args)
        local src = source
        local xPlayer = RSGCore.Functions.GetPlayer(src)
        if not xPlayer then return end
        if not HasStaffPermission(src) then auditLog("Intento de Comando sin Permiso", src, "Intentó usar /"..Config.CloseReportCommand.." sin permisos.") TriggerClientEvent('ox_lib:notify', src, { title = locale('cl_lang_43'), description = locale('cl_lang_42'), type = 'error' }) return end
        local id = tonumber(args[1])
        if not id or not ChatSystem.reports[id] then  TriggerClientEvent('ox_lib:notify', src, {title = 'Sistema de Reportes', description = string.format(locale('cl_lang_57'), Config.CloseReportCommand), type = 'error', duration = 5000 }) return end
        local reporter = ChatSystem.reports[id].reporter
        ChatSystem.reports[id] = nil

        -- Notificar al staff
        TriggerClientEvent('ox_lib:notify', src, { title = 'Sistema de Reportes',  description = string.format('Reporte %d cerrado correctamente.', id), type = 'success' })

        -- Notificar al jugador que hizo el reporte
        if GetPlayerName(reporter) then
            TriggerClientEvent('ox_lib:notify', reporter, { title = 'Sistema de Reportes', description = 'Tu reporte fue cerrado por el staff.', type = 'inform' })
        end
    end, false)
end

RegisterNetEvent('rsg-chat:server:SendReport', function(name, targetSrc, msg)
    local src = source
    if HasStaffPermission(src) then
        local template = '<div class="chat-message" style="background: var(--bg-anuncio); border-left: 4px solid var(--color-report); padding: var(--padding-base);">' ..
            '<i class="fas fa-comment" style="color: var(--color-report);"></i> ' ..
            '<b style="color: var(--color-report); font-family: var(--fuente-principal); font-size: var(--fuente-size-text);">[REPORT] ' .. name .. '</b> ' ..
            '<span style="font-size: var(--fuente-size-text); color: var(--color-report); margin-left: 10px;">ID: ' .. targetSrc .. '</span>' ..
            '<div style="font-weight: 300; color: var(--color-report); font-family: var(--fuente-principal);">' .. msg .. '</div>' ..
        '</div>'
        sendChat( src, nil, template, nil)

    end
end)

if Config.EnablereplyCommand then
    RegisterCommand(Config.replyCommand, function(source, args, rawCommand)
        local player = RSGCore.Functions.GetPlayer(source)
        local playerName = player.PlayerData.name
        if #args < 2 then TriggerClientEvent('ox_lib:notify', source, {title = 'Report', description = string.format(locale('cl_lang_56'), Config.replyCommand), type = 'error', duration = 5000 }) return end
        local message = table.concat(args, ' ', 2)
        local time = os.date(Config.DateFormat)
        local src = source
        if not HasStaffPermission(src) then auditLog("Intento de Comando sin Permiso", src, "Intentó usar /"..Config.replyCommand.." sin permisos.") TriggerClientEvent('ox_lib:notify', src, { title = locale('cl_lang_43'), description = locale('cl_lang_42'), type = 'error' })
            return
        else
            local reportId = tonumber(args[1])
            local report = ChatSystem.reports[reportId]
            if not report then TriggerClientEvent('ox_lib:notify', source, {title = 'ID de reporte no válido.', type = 'error', duration = 5000 }) return end
            local reportedPlayer = RSGCore.Functions.GetPlayer(report.reporter)
            if not reportedPlayer then TriggerClientEvent('ox_lib:notify', source, {title = 'El jugador reportado no está en línea.', type = 'error', duration = 5000 }) return end

            local replyMessage = table.concat(args, ' ', 2)
            local template = '<div class="chat-message" style="background: var(--bg-mensaje); border-left: 4px solid var(--color-reply); padding: var(--padding-base);">' ..
                '<i class="fas fa-comment" style="color: var(--color-reply);"></i> ' ..
                '<b style="color: var(--color-reply); font-family: var(--fuente-principal); font-size: var(--fuente-size-text);">[RESPUESTA AL REPORTE] ' ..
                playerName .. '</b> ' ..
                -- '<span style="font-size: var(--fuente-size-text); color: var(--color-reply); margin-left: 10px;">' .. time .. '</span>' ..
                '<div style="font-weight: 300; color: var(--color-reply); font-family: var(--fuente-principal);">' .. replyMessage .. '</div>' ..
                '</div>'
            -- Responder al jugador reportado
            sendChat(reportedPlayer.PlayerData.source, nil, template, nil)
            TriggerClientEvent('ox_lib:notify', source, { title = string.format('Tu mensaje fue enviado a %s.', reportedPlayer.PlayerData.name), type = 'inform', duration = 5000 })

            -- Agregar al log
            table.insert(report.log, {
                author = playerName,
                message = replyMessage,
                time = os.date(Config.DateFormat)
            })

            local discordMessage = string.format(
                "**Respuesta a Reporte**\n**Autor:** %s\n**Mensaje:** %s\n**Hora:** %s\n**ID de Reporte:** %d",
                playerName,
                replyMessage,
                time,
                reportId
            )
            logToDiscord('report', 'RESPUESTA A REPORTE', 'green', discordMessage)
            auditLog("Respuesta a Reporte", src, string.format("Report ID: %s | Mensaje: %s", reportId, replyMessage))
        end
    end, false)
end

----------------------
-- lawman
----------------------
if Config.EnabletestigoCommand then
    RegisterCommand(Config.testigoCommand, function(source, args, rawCommand)
        local Player = RSGCore.Functions.GetPlayer(source)
        if #args < 1 then TriggerClientEvent('ox_lib:notify', source, { title = 'TESTIGO', description =string.format(locale('cl_lang_41'), Config.testigoCommand), type = 'error', duration = 5000 }) return end
        local message = table.concat(args, ' ')
        local PlayerData = Player.PlayerData
        local firstname = PlayerData.charinfo.firstname
        local lastname = PlayerData.charinfo.lastname
        local playerName = firstname .. ' ' .. lastname

        for _, targetPlayer in pairs(RSGCore.Functions.GetRSGPlayers()) do
            local targetJob = targetPlayer.PlayerData.job and targetPlayer.PlayerData.job.name or nil
            if targetJob and Config.allowedJobs[targetJob] then
                local template = '<div class="msg" style="background: var(--bg-mesaje); max-height: 300px; margin-right: 5px; font-family: var(--fuente-principal);">' ..
                    '<i class="fas fa-comment" style="color: var(--color-testigo);"></i> ' ..
                    '<b><span style="color: var(--color-testigo); font-size: var(--fuente-size-text);">[TESTIGO]:</span> ' ..
                    '<span style="font-size: var(--fuente-size-title); color: var(--color-testigo);">{0}</span></b></div>'
                sendChat(targetPlayer.PlayerData.source, nil, template, message)
                if IsPlayerNear(source, targetPlayer, 50.0) then TriggerClientEvent('ox_lib:notify', targetPlayer.PlayerData.source, { title = 'Testigo', description = 'Un testigo ha enviado un mensaje cerca de ti!', type = 'inform', duration = 5000 }) end
            end
        end

        -- Log de testigo
        local discordMessage = string.format(
            "**Mensaje de Testigo**\n**Jugador:** %s\n**Mensaje:** %s\n**Hora:** %s",
            playerName,
            message,
            os.date(Config.DateFormat)
        )
        logToDiscord('testigo', 'MENSAJE DE TESTIGO', 'blue', discordMessage)
    end, false)
end

----------------------
-- medic
----------------------
if Config.EnableauxilioCommand then
    activeAuxilio = activeAuxilio or {}

    RegisterCommand(Config.auxilioCommand, function(source, args, rawCommand)
        local Player = RSGCore.Functions.GetPlayer(source)
        if #args < 1 then TriggerClientEvent('ox_lib:notify', source, { title = 'Auxilio', description = string.format(locale('cl_lang_41'), Config.auxilioCommand), type = 'error', duration = 5000 }) return end
        local message = table.concat(args, ' ')
        local template = '<div class="msg" style="background: var(--bg-mesaje); font-family: var(--fuente-principal); max-height: 300px; margin-right: 5px;">' ..
                        '<i class="fas fa-comment" style="color: var(--color-auxilio);"></i> ' ..
                        '<b><span style="color: var(--color-auxilio); font-size: var(--fuente-size-text);">[AUXILIO]: </span>&nbsp;' ..
                        '<span style="font-size: var(--fuente-size-title); color: var(--color-auxilio);">{0}</span></b></div>'

        for _, targetPlayer in pairs(RSGCore.Functions.GetRSGPlayers()) do
            if targetPlayer.PlayerData.job and targetPlayer.PlayerData.job.name == Config.MedicJob then
                sendChat(targetPlayer.PlayerData.source, nil, template, message)

                table.insert(activeAuxilio, {
                    sender = source,
                    recipient = targetPlayer.PlayerData.source,
                    message = message
                })

                -- Log de solicitud de auxilio
                local playerName = Player.PlayerData.name
                local time = os.date(Config.DateFormat)
                local discordMessage = string.format(
                    "**Solicitud de Auxilio**\n**Solicitante:** %s\n**Mensaje:** %s\n**Hora:** %s",
                    playerName,
                    message,
                    time
                )
                logToDiscord('auxilio', 'SOLICITUD DE AUXILIO', 'red', discordMessage)
            end
        end
    end, false)

    RegisterCommand(Config.replymedicCommand, function(source, args, rawCommand)
        if #args < 1 then TriggerClientEvent('ox_lib:notify', source, { title = 'Respuesta', description = string.format(locale('cl_lang_41'), Config.replymedicCommand), type = 'error', duration = 5000 }) return end
        local responseMessage = table.concat(args, ' ')

        if #activeAuxilio > 0 then
            local auxilioRequest = table.remove(activeAuxilio, 1)
            local sender = RSGCore.Functions.GetPlayer(auxilioRequest.sender)
            if sender then
                local template = '<div class="msg" style="background: var(--bg-mesaje); font-family: var(--fuente-principal); max-height: 300px;  margin-right: 5px; ">' ..
                               '<i class="fas fa-comment" style="color: var(--color-auxilio);"></i> ' ..
                               '<b><span style="color: var(--color-auxilio); font-size: var(--fuente-size-text);">[Auxilio Reply]: </span>&nbsp;' ..
                               '<span style="font-size: var(--fuente-size-text); color: var(--color-auxilio);">{0}</span></b></div>'
                sendChat(sender.PlayerData.source, nil, template, responseMessage)
            else
                TriggerClientEvent('ox_lib:notify', source, { title = 'Respuesta', description = 'El jugador que solicitó auxilio ya no está en línea.', type = 'error', duration = 5000 })
            end
        else
            TriggerClientEvent('ox_lib:notify', source, { title = 'Respuesta', description = 'No hay solicitudes de auxilio pendientes.', type = 'error', duration = 5000 })
        end
    end, false)
end

----------------------
-- players
----------------------
RegisterCommand(Config.meCommand, function(source, args, rawCommand)
    local Player = RSGCore.Functions.GetPlayer(source)
    if #args < 1 then TriggerClientEvent('ox_lib:notify', source, {title = 'ME', description = string.format(locale('cl_lang_41'), Config.meCommand), type = 'error', duration = 5000 }) return end
    local message = table.concat(args, ' ')
    local PlayerData = Player.PlayerData
    local firstname = PlayerData.charinfo.firstname
    local lastname = PlayerData.charinfo.lastname
    local playerName = firstname .. ' ' .. lastname
    local radioRange = 5.0
    -- Itera sobre todos los jugadores para enviar el mensaje solo a los cercanos
    for _, targetPlayer in ipairs(GetPlayers()) do
        if IsPlayerNear(source, targetPlayer, radioRange) then
            local template = [[ <div class="chat-message">
                <i class="fas fa-user-gear" style="background: var(--bg-mesaje); color: var(--color-me); margin-right: 5px;"></i>
                <b> <span style="color: var(--color-me); font-size: var(--fuente-size-text);">[ME] {0}:</span> </b>
                <span style="font-size: var(--fuente-size-title); color: var(--color-me); font-weight: 400;"> {1}</span>
                </div> ]]
            sendChat(targetPlayer, playerName, template, message)
        end
    end

    -- Registra el mensaje en el servidor de registro
    local discordMessage = string.format(
            "Citizenid:** %s\n**Ingame ID:** %d\n**Name:** %s %s\n**Message::** %s**",
            Player.PlayerData.citizenid,
            Player.PlayerData.cid,
            Player.PlayerData.charinfo.firstname,
            Player.PlayerData.charinfo.lastname,
            message
        )
    logToDiscord('me', 'ME', 'white', discordMessage)
end, false)

RegisterCommand(Config.doCommand, function(source, args, rawCommand)
    local Player = RSGCore.Functions.GetPlayer(source)
    if #args < 1 then TriggerClientEvent('ox_lib:notify', source, {title = 'DO', description = string.format(locale('cl_lang_41'), Config.doCommand), type = 'error', duration = 5000 }) return end
    local message = table.concat(args, ' ')
    local PlayerData = Player.PlayerData
    local firstname = PlayerData.charinfo.firstname
    local lastname = PlayerData.charinfo.lastname
    local playerName = firstname .. ' ' .. lastname
    local radioRange = 5.0
    -- Itera sobre todos los jugadores para enviar el mensaje solo a los cercanos
    for _, targetPlayer in ipairs(GetPlayers()) do
        if IsPlayerNear(source, targetPlayer, radioRange) then
            local template = [[ <div class="msg">
                <i class="fas fa-scroll" style="background: var(--bg-mesaje); color: var(--color-do); margin-right: 5px;"></i>
                <b> <span style="color: var(--color-do); font-size: var(--fuente-size-text);">[DO] {0}:</span> </b>
                <span style="font-size: var(--fuente-size-title); color: var(--color-do); font-weight: 400;"> {1}</span>
            </div> ]]
            sendChat(targetPlayer, playerName, template, message)
        end
    end

    -- Registra el mensaje en el servidor de registro
    local discordMessage = string.format(
            "Citizenid:** %s\n**Ingame ID:** %d\n**Name:** %s %s\n**Message::** %s**",
            Player.PlayerData.citizenid,
            Player.PlayerData.cid,
            Player.PlayerData.charinfo.firstname,
            Player.PlayerData.charinfo.lastname,
            message
        )
    logToDiscord('do', 'DO', 'white', discordMessage)
end, false)

RegisterCommand(Config.oocCommand, function(source, args, rawCommand)
    local Player = RSGCore.Functions.GetPlayer(source)
    if #args < 1 then TriggerClientEvent('ox_lib:notify', source, {title = 'OOC', description = string.format(locale('cl_lang_41'), Config.mpCommand), type = 'error', duration = 5000 }) return end
    local message = table.concat(args, ' ')
    local PlayerData = Player.PlayerData
    local firstname = PlayerData.charinfo.firstname
    local lastname = PlayerData.charinfo.lastname
    local playerName = firstname .. ' ' .. lastname
    local template = [[ <div class="chat-message">
        <i class="fas fa-masks-theater" style="background: var(--bg-sugerencia); border-left: 8px solid var(--color-ooc); margin-right: 5px;"></i>
        <b> <span style="color: var(--color-ooc); font-size: var(--fuente-size-text);">[OOC] {0}:</span> </b>
        <span style="font-size: var(--fuente-size-title); color: var(--color-ooc); font-weight: 400;"> {1}</span>
    </div>]]
    sendChat(-1, playerName, template, message)

    local discordMessage = string.format(
            "Citizenid:** %s\n**Ingame ID:** %d\n**Name:** %s %s\n**Message::** %s**",
            Player.PlayerData.citizenid,
            Player.PlayerData.cid,
            Player.PlayerData.charinfo.firstname,
            Player.PlayerData.charinfo.lastname,
            message
        )
    logToDiscord('ooc', 'OOC', 'white', discordMessage)
end, false)

if Config.AllowPlayersToClearTheirChat then
    RegisterCommand(Config.ClearChatCommand, function(source, args, rawCommand)
        TriggerClientEvent('chat:client:ClearChat', source)
        TriggerClientEvent('ox_lib:notify', source, { title = 'Chat', description = 'Tu chat ha sido limpiado.', type = 'success', duration = 3000 })
    end, false)
end

if Config.EnableAdvertisementCommand then
    RegisterCommand(Config.AdvertisementCommand, function(source, args, rawCommand)
        local Player = RSGCore.Functions.GetPlayer(source)
        local length = string.len(Config.AdvertisementCommand)
        local message = rawCommand:sub(length + 1):match("^%s*(.*)")
        if #args < 1 or message == '' then TriggerClientEvent('ox_lib:notify', source, { title = 'Publicidad', description = string.format(locale('cl_lang_41'), Config.AdvertisementCommand), type = 'error', duration = 5000 }) return end
        local PlayerData = Player.PlayerData
        local firstname = PlayerData.charinfo.firstname or "Desconocido"
        local lastname = PlayerData.charinfo.lastname or "Jugador"
        local playerName = firstname .. ' ' .. lastname
        local bankMoney = PlayerData.money.bank or 0

        -- Control de cooldown individual
        local now = os.time()
        local lastAdvertise = ChatSystem.advertisementCooldowns[source] or 0
        local cooldownSeconds = Config.AdvertisementCooldown * 60

        if HasCooldown(source, 'advertise', cooldownSeconds) then
            local remaining = cooldownSeconds - (now - lastAdvertise)
            local minutes = math.floor(remaining / 60)
            local seconds = remaining % 60
            TriggerClientEvent('ox_lib:notify', source, { title = 'Publicidad', description = string.format("Puedes hacer una nueva publicidad en %d minutos y %d segundos.", minutes, seconds), type = 'error', duration = 5000 })
            return
        end
        if bankMoney < Config.AdvertisementPrice then TriggerClientEvent('ox_lib:notify', source, { title = 'Publicidad', description = "No tienes suficiente dinero en el banco para hacer una publicidad.", type = 'error', duration = 5000 }) return end

        -- Proceder con la publicidad
        Player.Functions.RemoveMoney('bank', Config.AdvertisementPrice)
        TriggerClientEvent('ox_lib:notify', source, { title = "Publicidad Enviada", description = "Tu publicidad ha sido transmitida por $"..Config.AdvertisementPrice, type = 'inform', duration = 5000 })
        local template = '<div class="chat-message" style="background: var(--bg-sugerencia); border-left: 12px solid var(--color-publicidad); padding: var(--padding-base);">' ..
               -- '<i class="fas fa-ad" style="color: var(--color-publicidad); margin-right: 6px; font-weight: bold;"></i>' ..
               '<span style="color: var(--color-publicidad); font-family: var(--fuente-principal); font-size: var(--fuente-size-text);">[ADVERT] {0}</span></div>'
        sendChat(-1, nil, template, message)

        local discordMessage = string.format(
            "**Comando de Publicidad Usado**\n**Nombre del Jugador:** %s\n**Mensaje:** %s\n**Precio:** $%d",
            playerName,
            message,
            Config.AdvertisementPrice
        )
        logToDiscord('advertisement', 'PUBLICIDAD', 'yellow', discordMessage)
        ChatSystem.advertisementCooldowns[source] = now
    end, false)
end

if Config.EnablegossipCommand then
    RegisterCommand(Config.gossipCommand, function(source, args, rawCommand)
        if #args < 1 then TriggerClientEvent('ox_lib:notify', source, { title = 'Rumor', description = string.format(locale('cl_lang_41'), Config.gossipCommand), type = 'error', duration = 5000 }) return end
        local message = table.concat(args, ' ')
        local template = '<div class="chat-message" style="background: var(--bg-sugerencia); border-left: 8px solid var(--color-rumor); padding: var(--padding-base);">' ..
                -- '<i class="fas fa-ad" style="color: var(--color-rumor); margin-right: 6px; font-weight: bold;"></i>' ..
                '<span style="color: var(--color-rumor); font-family: var(--fuente-principal); font-size: var(--fuente-size-text);">[RUMOR] {0}</span></div>'
        sendChat( -1, nil, template, message)

        -- Log del rumor
        local playerName = RSGCore.Functions.GetPlayer(source).PlayerData.name
        local time = os.date(Config.DateFormat)
        local discordMessage = string.format(
            "**Rumor Enviado**\n**Jugador:** %s\n**Mensaje:** %s\n**Hora:** %s",
            playerName,
            message,
            time
        )
        logToDiscord('gossip', 'RUMOR', 'orange', discordMessage)
    end, false)
end

if Config.EnablempCommand then
    RegisterCommand(Config.mpCommand, function(source, args, rawCommand)
        if #args < 1 then TriggerClientEvent('ox_lib:notify', source, {title = 'MP', description = string.format(locale('cl_lang_56'), Config.mpCommand), type = 'error', duration = 5000 }) return end
        local playerId = tonumber(args[1])
        local message = table.concat(args, ' ', 2)

        -- Validar entrada
        if not playerId or not message or message == '' then TriggerClientEvent('ox_lib:notify', source, { title = 'Error', description = string.format(locale('cl_lang_56'), Config.mpCommand), type = 'erroe', duration = 5000 }) return end
        local sender = RSGCore.Functions.GetPlayer(source)
        local receiver = RSGCore.Functions.GetPlayer(playerId)

        if receiver and receiver.PlayerData and receiver.PlayerData.source then
            -- Obtener nombres completos
            local senderName = sender and sender.PlayerData and sender.PlayerData.charinfo and (sender.PlayerData.charinfo.firstname .. " " .. sender.PlayerData.charinfo.lastname) or "Unknown"
            local receiverName = receiver and receiver.PlayerData and receiver.PlayerData.charinfo and (receiver.PlayerData.charinfo.firstname .. " " .. receiver.PlayerData.charinfo.lastname) or "Unknown"
            local template = [[ <div class="chat-message" style="background: var(--bg-mesaje); margin-right: 5px;">
                <i class="fas fa-envelope"></i> 
                <strong>{0} [MP (ID: {1})]:</strong>&nbsp;
                <span style="font-size: var(--fuente-size-text); color: var(--color-mp);"> {2}</span>
            </div> ]]
            -- Enviar mensaje al receptor
            sendChat(receiver.PlayerData.source, nil, template, message, senderName, source)
            local template_b = [[ <div class="chat-message" style="background: var(--bg-mesaje); margin-right: 5px;">
                <i class="fas fa-envelope"></i> 
                <strong>{0} [MP (ID: {1})]:</strong>&nbsp;
                <span style="font-size: var(--fuente-size-text); color: var(--color-mp);"> {2}</span>
            </div> ]]
            sendChat(sender.PlayerData.source, nil, template_b, message, receiverName, playerId)
        else
            TriggerClientEvent('ox_lib:notify', source, { title = 'Error', description = 'Jugador no encontrado o no está en línea', type = 'erroe', duration = 5000 })
        end
    end, false)
end

if Config.EnableWhisperCommand then
    RegisterCommand(Config.WhisperCommand, function(source, args, rawCommand)
        local xPlayer = RSGCore.Functions.GetPlayer(source)
        local length = string.len(Config.WhisperCommand)
        if #args < 1 then TriggerClientEvent('ox_lib:notify', source, { title = 'Whisper', description = string.format(locale('cl_lang_41'), Config.WhisperCommand), type = 'error', duration = 5000 }) return end
        local message = rawCommand:sub(length + 2) -- +2 para omitir espacio después del comando
        local PlayerData = xPlayer.PlayerData
        local firstname = PlayerData.charinfo.firstname
        local lastname = PlayerData.charinfo.lastname
        local playerName = firstname .. ' ' .. lastname
        local whisperRange = 5.0

        -- Enviar solo a jugadores dentro del rango de susurro
        for _, targetPlayer in ipairs(GetPlayers()) do
            if IsPlayerNear(source, targetPlayer, whisperRange) then
                local template = [[ <div class="msg" style="background: var(--bg-mesaje); margin-right: 5px;">
                    <i class="fas fa-comment-alt"></i> 
                    <b>
                        <span style="color: var(--color-susurro); font-size: var(--fuente-size-text);">[WHISPER] {0}:</span>&nbsp;
                        <span style="color: var(--color-susurro); font-size: var(--fuente-size-title);"> {1}</span>
                    </b>
                </div> ]]
                sendChat(targetPlayer, playerName, template, message)
            end
        end
    end, false)
end
