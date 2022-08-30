NebulaSecure = NebulaSecure or {}

function NebulaSecure:Validate(steamid64, steamid32, ip)
    local info = self:Search(steamid64, steamid32, ip)

    if not info then return true end

    local rawIp = string.Split(info.ip, ":")[1]

    for _, ply in pairs(player.GetAll()) do
        if string.Split(ply:IPAddress(), ":")[1] == rawIp then
            if NebulaSecure.PlayerWhitelist[ply:SteamID()] then continue end
            return false, "Nebula Secure | You already have an account connected on this IP!"
        end
    end

    -- for _, data in pairs(NebulaSecure.Players) do
    --     -- More validation here
    -- end

    return true
end

function NebulaSecure:Search(steamid64, steamid32, ip)
    if not NebulaSecure.Players then return end

    local found = false

    for _, data in pairs(NebulaSecure.Players) do
        if data.steamid64 == steamid64 then found = data end
    end

    if not found then
        local data = {
            time = os.time(),
            steamid64 = steamid64,
            steamid32 = steamid32,
            ip = ip,
        }

        NebulaDriver:MySQLInsert("secure_players", data, function()
            table.insert(NebulaSecure.Players, data)
            MsgN("[NebulaSecure] " .. steamid64 .. " has been added to the database.")
        end)

        found = data
    end

    return found
end