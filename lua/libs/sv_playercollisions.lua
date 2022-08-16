local playerCollisions = CreateConVar("sv_nebula_playercollisions", 0, { FCVAR_ARCHIVE, FCVAR_SERVER_CAN_EXECUTE })

hook.Add("PlayerSpawn", "Nebula.PlayerCollisions", function(ply)
    if playerCollisions:GetBool() then
        ply:SetCollisionGroup(COLLISION_GROUP_PASSABLE_DOOR)
    else
        ply:SetCollisionGroup(COLLISION_GROUP_PLAYER)
    end

    ply:SetAvoidPlayers(false)
end)