hook.Add("PlayerTick", "Nebula.PlayerCollisions", function(ply)
    local penetrating = ply:GetPhysicsObject() and ply:GetPhysicsObject():IsPenetrating()

    if penetrating then
        ply:SetRenderMode(RENDERMODE_TRANSCOLOR)
        ply:SetColor(Color(255, 255, 255, 150))
    else
        ply:SetRenderMode(RENDERMODE_NORMAL)
        ply:SetColor(Color(255, 255, 255, 255))
    end
end)