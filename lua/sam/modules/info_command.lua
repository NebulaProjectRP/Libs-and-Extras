if SAM_LOADED then return end

local sam, command = sam, sam.command

command.set_category("Nebula")

command.new("info")
    :SetPermission("info", "superadmin")

    :Help("Get information of a user.")

    :AddArg("player", { single_target = true })

    :OnExecute(function(ply, targets)
        local steamid = targets[1]:SteamID()
        local steamid64 = targets[1]:SteamID64()
        local ip = targets[1]:IPAddress()

        sam.player.send_message(ply, "Information: {T} \nSteamID32: {V} \nSteamID64: {V_1} \nIP: {V_2}", { T = targets, V = steamid, V_1 = steamid64, V_2 = ip })
    end)
:End()