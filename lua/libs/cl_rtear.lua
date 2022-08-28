--The beggining of an idea 
--https://i.imgur.com/0fgocTF.jpg
RT = RT or {}
RT.Pool = RT.Pool or {}
local seed = os.time()

function RT.Create(identifier, wi, he, mat, add)
    local newRT = GetRenderTarget(identifier, wi, he, add)

    if (not mat) then
        mat = CreateMaterial("RT_" .. (identifier or 1) .. (seed or 1), "UnLitGeneric", {
            ["$basetexture"] = newRT:GetName(),
            ["$vertexalpha"] = 1,
            ["$ignorez"] = true,
            ["$additive"] = add and 1 or 0,
            ["$vertexcolor"] = 1,
            ["$nocull"] = 1
        })
    end

    RT.Pool[identifier] = {
        RT = newRT,
        w = wi,
        h = he,
        material = mat,
        mat_path = mat.GetPath ~= nil and mat:GetPath() or "RT_" .. identifier .. seed
    }

    return identifier
end

function RT.Pop(id)
    RT.Pool[id].material:SetTexture("$basetexture", RT.Pool[id].RT)
    render.PushRenderTarget(RT.Pool[id].RT)
    render.OverrideAlphaWriteEnable(true, true)
    cam.Start2D()
    render.ClearDepth()
    render.Clear(0, 0, 0, 0)
end

function RT.Push()
    cam.End2D()
    render.OverrideAlphaWriteEnable(false)
    render.PopRenderTarget()
end

function RT.Get(id)
    return RT.Pool[id]
end

function RT.Material(id)
    if (RT.Get(id)) then return RT.Get(id).material end
end