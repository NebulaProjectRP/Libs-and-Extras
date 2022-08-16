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
end, nil, "Toggle thirdperson view.")

local jellyTargets = {}
local maxDistance = 32 ^ 2

hook.Add("Think", "Nebula.TransparentPerrs", function()
    for ply, dist in pairs(jellyTargets) do
        if (dist > maxDistance) then
            ply:SetMaterial("")
            jellyTargets[ply] = nil
        end
    end
end)

hook.Add("PrePlayerDraw", "Nebula.TransparentPerrs", function(ply)
    if (ply == LocalPlayer()) then return end

    local pos = LocalPlayer():GetPos() + LocalPlayer():OBBCenter()
    local target = ply:GetPos() + ply:OBBCenter()
    local dist = pos:DistToSqr(target)

    if (not jellyTargets[ply] and dist < maxDistance) then
        jellyTargets[ply] = dist
        ply:SetMaterial("models/effects/resist_shield/resist_shield_gonzo")
    else
        jellyTargets[ply] = dist
    end
end)