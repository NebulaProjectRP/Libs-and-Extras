local ServerWhitelist = {
    "76561198112004800", -- Wookie
    "76561198044940228", -- Gonzo
}

hook.Add("CheckPassword", "Nebula.WhitelistCheck", function(steamid64)
    return table.HasValue(ServerWhitelist, steamid64), "You are not whitelisted on this server."
end)