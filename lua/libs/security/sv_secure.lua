NebulaSecure = NebulaSecure or {}

function NebulaSecure:Validate(steamid64, steamid32, ip)
    local rawIp = string.Split(ip, ":")[1]

    for _, ply in pairs(player.GetAll()) do
        if string.Split(ply:IPAddress(), ":")[1] == rawIp then
            if NebulaSecure.PlayerWhitelist[ply:SteamID()] then continue end
            return false, "Nebula Secure | You already have an account connected on this IP!"
        end
    end

    if NebulaSecure.Players then
        local found = false

        for _, data in pairs(NebulaSecure.Players) do
            -- if string.Split(ply.ip, ":")[1] == rawIp then
            --     -- IP Warnings here
            -- end

            if data.steamid64 == steamid64 then found = true end
        end

        if not found then
            NebulaDriver:MySQLInsert("secure_players", {
                steamid64 = steamid64,
                steamid32 = steamid32,
                ip = ip
            }, function()
                MsgN("[NebulaSecure] " .. steamid64 .. " has been added to the database.")
            end)
        end
    end

    return true
end