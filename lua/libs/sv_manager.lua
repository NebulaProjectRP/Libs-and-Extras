concommand.Add("reset", function(ply, cmd, args)
    if IsValid(ply) then return end
    RunConsoleCommand("changelevel", game.GetMap())
end)

function _gonzo()
    return player.GetBySteamID64("76561198044940228")
end