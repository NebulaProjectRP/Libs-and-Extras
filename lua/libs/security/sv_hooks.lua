
-- Disables editing of properties on entities

hook.Add("CanEditVariable", "NebulaSecure.EditProperties", function(ent, ply)
    return ply:IsSuperAdmin()
end)