hook.Add("ShouldCollide", "Nebula.PlayerCollisions", function(ent1, ent2)
    if ent1:IsPlayer() and ent2:IsPlayer() then
        return false
    end
end)