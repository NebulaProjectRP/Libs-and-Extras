local ServerWhitelist = {
    "76561198112004800", -- Wookie
    "76561198044940228", -- Gonzo
    "76561198401500432", -- Deathreaper
    "76561198220362804", -- Choran
    "76561198370651409", -- Az
    "76561198138988114", -- Starman
    "76561198406835224", -- Riptea
    "76561198833323010", -- Drizz
    "76561198138008004", -- Blackrain
    "76561198952132323", -- Shed
    "76561198124205745", -- Sincryer
    "76561198804609222", -- Big book
    "76561198031185743", -- Choicesquiddy
    "76561198877328209", -- Kibou
    "76561198369672715", -- MrDonDon
    "76561198878066418", -- Obama Nae
    "76561199044806685", -- LoserLG
}

hook.Add("CheckPassword", "Nebula.WhitelistCheck", function(steamid64)
    return table.HasValue(ServerWhitelist, steamid64), "You are not whitelisted on this server."
end)