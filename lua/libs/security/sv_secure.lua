NebulaSecure = NebulaSecure or {}

function NebulaSecure:ValidateIP(ip)
    if NebulaIP.IPWhitelist[ip] then return true end

    for _, ply in pairs(player.GetAll()) do
        if string.Split(ply:IPAddress(), ":")[1] == ip then
            return false, "Nebula Secure | You already have an account connected on this IP!"
        end
    end

    return true
end