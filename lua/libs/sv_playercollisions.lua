local playerCollisions = CreateConVar("sv_nebula_playercollisions", 0, { FCVAR_ARCHIVE, FCVAR })

hook.Add("PlayerSpawn", "Nebula.PlayerCollisions", function(ply)
    print(ply:GetCollisionGroup())

    -- if playerCollisions:GetBool() then
    --     ply:SetCollisionGroup(COLLISION_GROUP_PASSABLE_DOOR)
    -- else
    --     ply:SetCollisionGroup(COLLISION_GROUP_PLAYER)
    -- end

    -- ply:SetAvoidPlayers(false)
end)