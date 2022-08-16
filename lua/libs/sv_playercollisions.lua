local playerCollisions = CreateConVar("sv_nebula_playercollisions", 1, { FCVAR_ARCHIVE, FCVAR_SERVER_CAN_EXECUTE }, "Whether to enable player collisions.")

hook.Add("PlayerTick", "Nebula.PlayerCollisions", function(ply)
    if not playerCollisions:GetBool() then
        ply:SetCollisionGroup(COLLISION_GROUP_PASSABLE_DOOR)
    else
        ply:SetCollisionGroup(COLLISION_GROUP_PLAYER)
    end

    ply:SetAvoidPlayers(false)
end)