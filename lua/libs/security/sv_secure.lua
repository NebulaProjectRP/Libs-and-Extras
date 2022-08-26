NebulaSecure = NebulaSecure or {}

function NebulaSecure:Validate(steamid64, steamid32, ip)
    if NebulaIP.IPWhitelist[ip] then return true end

    for _, ply in pairs(player.GetAll()) do
        if string.Split(ply:IPAddress(), ":")[1] == string.Split(ip, ":")[1] then
            return false, "Nebula Secure | You already have an account connected on this IP!"
        end
    end

    if IsValid(NebulaSecure.Players) then
        for _, ply in pairs(NebulaSecure.Players) do
            local rawIp = string.Split(ip, ":")[1]

            -- if NebulaPlayers[rawIp] then
            --     --[[
            --         Do warnings here.
            --     ]]
            -- end

            if not NebulaPlayers[rawIp] then
                NebulaDriver:MySQLInsert("secure_players", {
                    steamid64 = steamid64,
                    steamid32 = steamid32,
                    ip = ip
                }, function()
                    MsgN("Nebula Secure | " .. steamid64 .. " has been added to the database.")
                end)
            end
        end
    end


    return true
end