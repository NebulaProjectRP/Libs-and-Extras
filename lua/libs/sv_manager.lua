concommand.Add("reset", function(ply, cmd, args)
    if IsValid(ply) then return end
    RunConsoleCommand("changelevel", game.GetMap())
end)