local playerCollisions = CreateConVar("sv_nebula_playercollisions", 1, { FCVAR_ARCHIVE, FCVAR_SERVER_CAN_EXECUTE }, "Whether to enable player collisions.")

hook.Add("PlayerSpawn", "Nebula.PlayerCollisions", function(ply)
    if not playerCollisions:GetBool() then return end
    timer.Simple(1, function()
        if IsValid(ply) then
            ply:SetCollisionGroup(COLLISION_GROUP_PASSABLE_DOOR)
            ply:SetAvoidPlayers(false)
        end
    end)
end)