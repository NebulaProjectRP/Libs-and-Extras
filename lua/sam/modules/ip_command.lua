if SAM_LOADED then return end

local sam, command = sam, sam.command

command.set_category("Nebula")

command.new("ip")
    :SetPermission("ip", "superadmin")

    :Help("Check the IP of a user.")

    :AddArg("player", { single_target = true })

    :OnExecute(function(ply, targets)
        local ip = targets[1]:IPAddress()

        sam.player.send_message(ply, "{T}'s IP: {V}", { T = targets, V = ip })
    end)
:End()