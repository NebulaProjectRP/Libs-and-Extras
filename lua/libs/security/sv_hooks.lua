
-- Disables editing of properties on entities

hook.Add("CanEditVariable", "NebulaRP.Secure:EditProperties", function(ent, ply)
    return ply:IsSuperAdmin()
end)