local ServerWhitelist = {

}

hook.Add("CheckPassword", "Nebula.WhitelistCheck", function(steamid64)
    return table.HasValue(ServerWhitelist, steamid64), "You are not whitelisted on this server."
end)