NebulaSecure = NebulaSecure or {}

hook.Add("DatabaseCreateTables", "Nebula.Secure:CreateTables", function()
    NebulaDriver:MySQLCreateTable("secure_players", {
        id = "INT NOT NULL AUTO_INCREMENT",
        steamid32 = "VARCHAR(22)",
        steamid64 = "VARCHAR(22)",
        ip = "VARCHAR(22)",
    })

    NebulaDriver:MySQLSelect("secure_players", nil, function(data)
        NebulaSecure.Players = data
    end)
end)

hook.Add("CheckPassword", "Nebula.Secure:InitialConnect", function(sid64, ipAddress)
    local ip = string.Split(ipAddress, ":")[1]
    return NebulaSecure:ValidateIP(ip)
end)

-- Disables editing of properties on entities

hook.Add("CanEditVariable", "NebulaRP.Secure:EditProperties", function(ent, ply)
    return ply:IsSuperAdmin()
end)