NebulaSecure = NebulaSecure or {}

hook.Add("DatabaseCreateTables", "Nebula.Secure:CreateTables", function()
    NebulaDriver:MySQLCreateTable("secure_players", {
        id = "INT NOT NULL AUTO_INCREMENT",
        steamid32 = "VARCHAR(22)",
        steamid64 = "VARCHAR(22)",
        ip = "VARCHAR(22)",
    })

    NebulaDriver:MySQLSelect("secure_players", nil, function(data)
        for _, ply in pairs(data) do
            local rawIp = string.Split(ip, ":")[1]
            NebulaPlayers[rawIp] = ply
        end
    end)
end)

hook.Add("CheckPassword", "Nebula.Secure:InitialConnect", function(sid64, ipAddress)
    local sid32 = util.SteamIDFrom64(sid64)
    return NebulaSecure:ValidateIP(sid64, sid32, ipAddress)
end)

-- Disables editing of properties on entities

hook.Add("CanEditVariable", "NebulaRP.Secure:EditProperties", function(ent, ply)
    return ply:IsSuperAdmin()
end)