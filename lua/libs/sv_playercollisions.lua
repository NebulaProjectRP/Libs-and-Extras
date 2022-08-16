hook.Add("PlayerTick", "Nebula.PlayerCollisions", function(ply)
    ply:SetCollisionGroup(COLLISION_GROUP_PASSABLE_DOOR)
    ply:SetAvoidPlayers(false)
end)