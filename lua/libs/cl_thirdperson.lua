local thirdPerson = CreateClientConVar("cl_nebula_thirdperson", 0)

hook.Add("CalcView", "Nebula.ThirdPerson", function(ply, origin, ang, fov, znear, zfar)
    if not ply or not thirdPerson:GetBool() then return end
    
    local pos = ply:EyePos()

    local trace = util.TraceHull({
        start = pos,
        mask = MASK_DEADSOLID,
        endpos = pos - ang:Forward() * 96,
        filter = {ply:GetActiveWeapon(), ply},
        mins = Vector(-6, -4, -4),
        maxs = Vector(6, 4, 4),
    })

    if trace.Hit then
        pos = trace.HitPos
    else
        pos = pos - ang:Forward() * 96
    end

    local view = {}
    view.fov = fov
    view.origin = pos
    view.drawviewer = true
    view.angles = ang

    return view
end)

concommand.Add("nebula_thirdperson", function()
    thirdPerson:SetBool(not thirdPerson:GetBool())
end)