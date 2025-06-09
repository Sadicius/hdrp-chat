Config = {}

-- [Date Format]
Config.DateFormat = '%H:%M' -- To change the date format check this website - https://www.lua.org/pil/22.1.html

-- [Staff Groups]
Config.StaffGroups = {
    'god',
    'admin'
}

Config.doCommand = 'do'
Config.meCommand = 'me'
Config.oocCommand = 'ooc'

-- [Staff]
Config.AllowStaffsToClearEveryonesChat = true
Config.ClearEveryonesChatCommand = 'clear_chatall'
Config.EnableStaffOnlyCommand = true
Config.StaffOnlyCommand = 'adminchat'
Config.EnableStaffCommand = true
Config.StaffCommand = 'anuncio'

-- [REPORT]
Config.EnableReportCommand = true
Config.ReportCommand = 'reportar'
Config.ListReportCommand = "reports"
Config.CloseReportCommand = "closereport"
Config.EnablereplyCommand = true
Config.allowedJobs = { vallaw = true, rholaw = true, blklaw = true, strlaw = true, stdenlaw = true}
Config.replyCommand = 'reply'

-- [Advertisements]
Config.EnableAdvertisementCommand = true
Config.AdvertisementPrice = 5
Config.AdvertisementCooldown = 5 -- in minutes
Config.AdvertisementCommand = 'publicidad'

-- [Clear Player Chat]
Config.AllowPlayersToClearTheirChat = true
Config.ClearChatCommand = 'clear_chat'

-- [gossip]
Config.EnablegossipCommand = true
Config.gossipCommand = 'rumor'

Config.EnablempCommand = true
Config.mpCommand = 'mp'

Config.EnabletestigoCommand = true
Config.testigoCommand = 'testigo'

-- [Medic]
Config.EnableauxilioCommand = true
Config.MedicJob = 'medic'
Config.auxilioCommand = 'auxilio'
Config.replymedicCommand = 'aux_reply'