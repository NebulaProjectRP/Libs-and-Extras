include('glon.lua')

surface.CreateFont("12ptFont", {
    font = "Arial",
    size = 12,
    width = 500,
    antialias = true,
    additive = false
})

surface.CreateFont("24ptFont", {
    font = "Arial",
    size = 24,
    width = 500,
    antialias = true,
    additive = false
})

SWEP.useThirdPerson = false
SWEP.thirdPersonAngle = Angle(0, -90, 0)
SWEP.thirdPersonDis = 100
SWEP.mlast_x = ScrW() / 2
SWEP.mlast_y = ScrH() / 2

local playerBones = {"ValveBiped.Bip01_Head1", "ValveBiped.Bip01_Pelvis", "ValveBiped.Bip01_Spine", "ValveBiped.Bip01_Spine1", "ValveBiped.Bip01_Spine2", "ValveBiped.Bip01_Spine4", "ValveBiped.Anim_Attachment_RH", "ValveBiped.Bip01_R_Hand", "ValveBiped.Bip01_R_Forearm", "ValveBiped.Bip01_R_UpperArm", "ValveBiped.Bip01_R_Clavicle", "ValveBiped.Bip01_R_Foot", "ValveBiped.Bip01_R_Toe0", "ValveBiped.Bip01_R_Thigh", "ValveBiped.Bip01_R_Calf", "ValveBiped.Bip01_R_Shoulder", "ValveBiped.Bip01_R_Elbow", "ValveBiped.Bip01_Neck1", "ValveBiped.Anim_Attachment_LH", "ValveBiped.Bip01_L_Hand", "ValveBiped.Bip01_L_Forearm", "ValveBiped.Bip01_L_UpperArm", "ValveBiped.Bip01_L_Clavicle", "ValveBiped.Bip01_L_Foot", "ValveBiped.Bip01_L_Toe0", "ValveBiped.Bip01_L_Thigh", "ValveBiped.Bip01_L_Calf", "ValveBiped.Bip01_L_Shoulder", "ValveBiped.Bip01_L_Elbow"}

SWEP.v_models = {}
SWEP.v_panelCache = {}
SWEP.v_modelListing = nil
SWEP.v_bonemods = {}
SWEP.v_modelbonebox = nil
SWEP.w_models = {}
SWEP.w_panelCache = {}
SWEP.w_modelListing = nil
SWEP.world_model = nil
SWEP.cur_wmodel = nil
SWEP.browser_callback = nil
SWEP.modelbrowser = nil
SWEP.modelbrowser_list = nil
SWEP.matbrowser = nil
SWEP.matbrowser_list = nil
SWEP.tpsfocusbone = "ValveBiped.Bip01_R_Hand"
SWEP.save_data = {}

local save_data_template = {
    ViewModel = SWEP.ViewModel,
    CurWorldModel = SWEP.CurWorldModel,
    w_models = {},
    v_models = {},
    v_bonemods = {},
    ViewModelFOV = SWEP.ViewModelFOV,
    HoldType = SWEP.HoldType,
    ViewModelFlip = SWEP.ViewModelFlip,
    IronSightsEnabled = true,
    IronSightsPos = SWEP.IronSightsPos,
    IronSightsAng = SWEP.IronSightsAng,
    ShowViewModel = true,
    ShowWorldModel = true
}

SWEP.ir_drag = {
    x = {true, "-x", 25},
    y = {false, "y", 25},
    z = {true, "y", 25},
    pitch = {false, "y", 10},
    yaw = {false, "x", 10},
    roll = {false, "y", 10}
}

SWEP.Frame = nil
SWEP.cur_drag_mode = "x / z"
SWEP.basecode = "FAILED TO READ BASE CODE"

function SWEP:ClientInit()
    SCKDebug("Client init start")

    if IsValid(self.Owner) then
        -- init view model bone mods
        local vm = self.Owner:GetViewModel()

        if IsValid(vm) then
            self:ResetBonePositions(vm)
        end
    end

    local basecodepath = "lua/weapons/swep_construction_kit/base_code.lua"
    self.basecode = file.Read(basecodepath, "GAME")
    SCKDebug("Loaded base code")
end

function SimplePanel(parent)
    local p = vgui.Create("DPanel", parent)
    p.Paint = function() end

    return p
end

function PrintVec(vec)
    local px, py, pz = math.floor(vec.x * 1000) / 1000, math.floor(vec.y * 1000) / 1000, math.floor(vec.z * 1000) / 1000

    return "Vector(" .. px .. ", " .. py .. ", " .. pz .. ")"
end

function PrintAngle(angle)
    local pp, py, pr = math.floor(angle.p * 1000) / 1000, math.floor(angle.y * 1000) / 1000, math.floor(angle.r * 1000) / 1000

    return "Angle(" .. pp .. ", " .. py .. ", " .. pr .. ")"
end

function PrintColor(col)
    return "Color(" .. col.r .. ", " .. col.g .. ", " .. col.b .. ", " .. col.a .. ")"
end

-- Populates a DChoiceList with all the bones of the specified entity
-- returns if it has a first option
function PopulateBoneList(choicelist, ent)
    if not IsValid(choicelist) then return false end
    if not IsValid(ent) then return end
    SCKDebug("Populating bone list for entity " .. tostring(ent))

    if ent == LocalPlayer() then
        -- if the local player is in third person, his bone lookup is all messed up so
        -- we just use the predefined playerBones table
        for k, v in pairs(playerBones) do
            choicelist:AddChoice(v)
        end

        return true
    else
        local hasfirstoption

        for i = 0, ent:GetBoneCount() - 1 do
            local name = ent:GetBoneName(i)

            -- filter out invalid bones
            if ent:LookupBone(name) then
                choicelist:AddChoice(name)

                if not firstoption then
                    hasfirstoption = true
                end
            end
        end

        return hasfirstoption
    end
end

function SWEP:CreateWeaponWorldModel()
    local model = self.CurWorldModel
    SCKDebug("Creating weapon world model")

    if (not self.world_model or (IsValid(self.world_model) and self.cur_wmodel ~= model)) and string.find(model, ".mdl") and file.Exists(model, "GAME") then
        if IsValid(self.world_model) then
            self.world_model:Remove()
        end

        self.world_model = ClientsideModel(model, RENDERGROUP_TRANSLUCENT)

        if IsValid(self.world_model) then
            self.world_model:SetParent(self.Owner)
            self.world_model:SetNoDraw(true)
            self.cur_wmodel = model

            if self.world_model:LookupBone("ValveBiped.Bip01_R_Hand") then
                self.world_model:AddEffects(EF_BONEMERGE)
            end
        else
            self.world_model = nil
            self.cur_wmodel = nil
        end
    end
end

function SWEP:CreateModels(tab)
    --if true then return end
    -- Create the clientside models here because Garry says we can't do it in the render hook
    for k, v in pairs(tab) do
        if v.type == "Model" and v.model and v.model ~= "" and (not IsValid(v.modelEnt) or v.createdModel ~= v.model) and string.find(v.model, ".mdl") and file.Exists(v.model, "GAME") then
            SCKDebug("Creating new ClientSideModel " .. v.model)
            v.modelEnt = ClientsideModel(v.model, RENDERGROUP_TRANSLUCENT)

            if IsValid(v.modelEnt) then
                v.modelEnt:SetPos(self:GetPos())
                v.modelEnt:SetAngles(self:GetAngles())
                v.modelEnt:SetParent(self)
                v.modelEnt:SetNoDraw(true)
                v.createdModel = v.model
            else
                v.modelEnt = nil
            end
        elseif v.type == "Sprite" and v.sprite and v.sprite ~= "" and (not v.spriteMaterial or v.createdSprite ~= v.sprite) and file.Exists("materials/" .. v.sprite .. ".vmt", "GAME") then
            SCKDebug("Creating new sprite " .. v.sprite)
            local name = v.sprite .. "-"

            local params = {
                ["$basetexture"] = v.sprite
            }

            -- make sure we create a unique name based on the selected options
            local tocheck = {"nocull", "additive", "vertexalpha", "vertexcolor", "ignorez"}

            for i, j in pairs(tocheck) do
                if v[j] then
                    params["$" .. j] = 1
                    name = name .. "1"
                else
                    name = name .. "0"
                end
            end

            v.createdSprite = v.sprite
            v.spriteMaterial = CreateMaterial(name, "UnlitGeneric", params)
        end
    end
end

function SWEP:Think()
    self:CreateModels(self.v_models)
    self:CreateModels(self.w_models)
    -- Some hacky shit to get 3rd person view compatible with 
    -- other addons that override CalcView
    self:CalcViewHookManagement()
    --[[***********************
		Camera fiddling
	***********************]]
    self.useThirdPerson = self:GetThirdPerson()
    local mx, my = gui.MousePos()
    local diffx, diffy = mx - self.mlast_x, my - self.mlast_y

    -- right mouse press without sudden jumps
    if input.IsMouseDown(MOUSE_RIGHT) and not (diffx > 40 or diffy > 40) and self.Frame and self.Frame:IsVisible() then
        if self.useThirdPerson then
            if input.IsKeyDown(KEY_E) then
                self.thirdPersonDis = math.Clamp(self.thirdPersonDis + diffy, 10, 500)
            else
                self.thirdPersonAngle = self.thirdPersonAngle + Angle(diffy / 2, diffx / 2, 0)
            end
        else
            -- ironsight adjustment
            for k, v in pairs(self.ir_drag) do
                if v[1] then
                    local temp = GetConVar("_sp_ironsight_" .. k):GetFloat()

                    if v[2] == "x" then
                        local add = -(diffx / v[3])

                        if self.ViewModelFlip then
                            add = add * -1
                        end

                        RunConsoleCommand("_sp_ironsight_" .. k, temp + add)
                    elseif v[2] == "-x" then
                        local add = diffx / v[3]

                        if self.ViewModelFlip then
                            add = add * -1
                        end

                        RunConsoleCommand("_sp_ironsight_" .. k, temp + add)
                    elseif v[2] == "y" then
                        RunConsoleCommand("_sp_ironsight_" .. k, temp - diffy / v[3])
                    end
                end
            end
        end
    end

    self.mlast_x, self.mlast_y = mx, my
end

function SWEP:RemoveModels()
    SCKDebug("Removing models")

    for k, v in pairs(self.v_models) do
        if IsValid(v.modelEnt) then
            v.modelEnt:Remove()
        end
    end

    for k, v in pairs(self.w_models) do
        if IsValid(v.modelEnt) then
            v.modelEnt:Remove()
        end
    end

    self.v_models = {}
    self.w_models = {}

    if IsValid(self.world_model) then
        self.world_model:Remove()
        self.world_model = nil
        self.cur_wmodel = nil
    end
end

function SWEP:GetBoneOrientation(basetab, name, ent, bone_override, buildup)
    local bone, pos, ang
    local tab = basetab[name]

    if tab.rel and tab.rel ~= "" then
        local v = basetab[tab.rel]
        if not v then return end

        if not buildup then
            buildup = {}
        end

        table.insert(buildup, name)
        if table.HasValue(buildup, tab.rel) then return end
        -- Technically, if there exists an element with the same name as a bone
        -- you can get in an infinite loop. Let's just hope nobody's that stupid.
        pos, ang = self:GetBoneOrientation(basetab, tab.rel, ent, nil, buildup)
        if not pos then return end
        pos = pos + ang:Forward() * v.pos.x + ang:Right() * v.pos.y + ang:Up() * v.pos.z

        if v.angle then
            ang:RotateAroundAxis(ang:Up(), v.angle.y)
            ang:RotateAroundAxis(ang:Right(), v.angle.p)
            ang:RotateAroundAxis(ang:Forward(), v.angle.r)
        end
    else
        bone = ent:LookupBone(bone_override or tab.bone)
        if not bone then return end
        pos, ang = Vector(0, 0, 0), Angle(0, 0, 0)
        local m = ent:GetBoneMatrix(bone)

        if m then
            pos, ang = m:GetTranslation(), m:GetAngles()
        end

        if IsValid(self.Owner) and self.Owner:IsPlayer() and ent == self.Owner:GetViewModel() and self.ViewModelFlip then
            ang.r = -ang.r -- Fixes mirrored models
        end
    end

    return pos, ang
end

local allbones
local hasGarryFixedBoneScalingYet = false

function SWEP:UpdateBonePositions(vm)
    if self.v_bonemods then
        if not vm:GetBoneCount() then return end
        -- !! WORKAROUND !! //
        -- We need to check all model names :/
        local loopthrough = self.v_bonemods

        if not hasGarryFixedBoneScalingYet then
            allbones = {}

            for i = 0, vm:GetBoneCount() do
                local bonename = vm:GetBoneName(i)

                if self.v_bonemods[bonename] then
                    allbones[bonename] = self.v_bonemods[bonename]
                else
                    allbones[bonename] = {
                        scale = Vector(1, 1, 1),
                        pos = Vector(0, 0, 0),
                        angle = Angle(0, 0, 0)
                    }
                end
            end

            loopthrough = allbones
        end

        -- !! ----------- !! //
        for k, v in pairs(loopthrough) do
            local bone = vm:LookupBone(k)
            if not bone then continue end
            -- !! WORKAROUND !! //
            local s = Vector(v.scale.x, v.scale.y, v.scale.z)
            local p = Vector(v.pos.x, v.pos.y, v.pos.z)
            local ms = Vector(1, 1, 1)

            if not hasGarryFixedBoneScalingYet then
                local cur = vm:GetBoneParent(bone)

                while cur >= 0 do
                    local pscale = loopthrough[vm:GetBoneName(cur)].scale
                    ms = ms * pscale
                    cur = vm:GetBoneParent(cur)
                end
            end

            --local bpos = vm:GetBonePosition(bone)
            --local par = vm:GetBoneParent(bone)
            s = s * ms

            --SCKDebug("Bone ("..bone..") "..vm:GetBoneName(bone).." rel to p ("..par.."): "..tostring(bpos - (vm:GetBonePosition(vm:GetBoneParent(bone)) or bpos)))
            --local relp = bpos - (vm:GetBonePosition(vm:GetBoneParent(bone)) or bpos)
            --p = relp * ms - relp
            --SCKDebug("Bone ("..bone..") scale = "..tostring(ms).." | newpos = "..tostring(p))
            -- !! ----------- !! //
            if vm:GetManipulateBoneScale(bone) ~= s then
                vm:ManipulateBoneScale(bone, s)
            end

            if vm:GetManipulateBoneAngles(bone) ~= v.angle then
                vm:ManipulateBoneAngles(bone, v.angle)
            end

            if vm:GetManipulateBonePosition(bone) ~= p then
                vm:ManipulateBonePosition(bone, p)
            end
        end
    else
        self:ResetBonePositions(vm)
    end
end

function SWEP:ResetBonePositions(vm)
    if not vm:GetBoneCount() then return end

    for i = 0, vm:GetBoneCount() do
        vm:ManipulateBoneScale(i, Vector(1, 1, 1))
        vm:ManipulateBoneAngles(i, Angle(0, 0, 0))
        vm:ManipulateBonePosition(i, Vector(0, 0, 0))
    end
end

--[[*******************************
	All viewmodel drawing magic
********************************]]
SWEP.vRenderOrder = nil

function SWEP:ViewModelDrawn()
    --if true then return end
    --SCKDebugRepeat( "SWEP:VMD", "Drawing viewmodel!" )
    local vm = self.Owner:GetViewModel()
    if not IsValid(vm) then return end
    self:UpdateBonePositions(vm)

    --[[if vm.BuildBonePositions ~= self.BuildViewModelBones then
		vm.BuildBonePositions = self.BuildViewModelBones
	end]]
    if not self.vRenderOrder then
        -- we build a render order because sprites need to be drawn after models
        self.vRenderOrder = {}

        for k, v in pairs(self.v_models) do
            if v.type == "Model" then
                table.insert(self.vRenderOrder, 1, k)
            elseif v.type == "Sprite" or v.type == "Quad" then
                table.insert(self.vRenderOrder, k)
            end
        end
    end

    for k, name in ipairs(self.vRenderOrder) do
        local v = self.v_models[name]

        if not v then
            self.vRenderOrder = nil
            break
        end

        local model = v.modelEnt
        local sprite = v.spriteMaterial
        if not v.bone then continue end
        local pos, ang = self:GetBoneOrientation(self.v_models, name, vm)
        if not pos then continue end

        if v.type == "Model" and IsValid(model) then
            model:SetPos(pos + ang:Forward() * v.pos.x + ang:Right() * v.pos.y + ang:Up() * v.pos.z)
            ang:RotateAroundAxis(ang:Up(), v.angle.y)
            ang:RotateAroundAxis(ang:Right(), v.angle.p)
            ang:RotateAroundAxis(ang:Forward(), v.angle.r)
            model:SetAngles(ang)
            --model:SetModelScale(v.size)
            local matrix = Matrix()
            matrix:Scale(v.size)
            model:EnableMatrix("RenderMultiply", matrix)

            if v.material == "" then
                model:SetMaterial("")
            elseif model:GetMaterial() ~= v.material then
                model:SetMaterial(v.material)
            end

            if v.skin ~= model:GetSkin() then
                model:SetSkin(v.skin)
            end

            for k, v in pairs(v.bodygroup) do
                if model:GetBodygroup(k) ~= v then
                    model:SetBodygroup(k, v)
                end
            end

            -- Ain't working :/
            --[[halo.Render({
				Ents = {model},
				Color = Color(255,0,0,200),
				BlurX = 2,
				BlurY = 2,
				DrawPasses = 1,
				Additive = true,
				IgnoreZ = true
			})]]
            if v.surpresslightning then
                render.SuppressEngineLighting(true)
            end

            render.SetColorModulation(v.color.r / 255, v.color.g / 255, v.color.b / 255)
            render.SetBlend(v.color.a / 255)
            model:DrawModel()
            render.SetBlend(1)
            render.SetColorModulation(1, 1, 1)

            if v.surpresslightning then
                render.SuppressEngineLighting(false)
            end
        elseif v.type == "Sprite" and sprite then
            local drawpos = pos + ang:Forward() * v.pos.x + ang:Right() * v.pos.y + ang:Up() * v.pos.z
            render.SetMaterial(sprite)
            render.DrawSprite(drawpos, v.size.x, v.size.y, v.color)
        elseif v.type == "Quad" then
            local drawpos = pos + ang:Forward() * v.pos.x + ang:Right() * v.pos.y + ang:Up() * v.pos.z
            ang:RotateAroundAxis(ang:Up(), v.angle.y)
            ang:RotateAroundAxis(ang:Right(), v.angle.p)
            ang:RotateAroundAxis(ang:Forward(), v.angle.r)
            cam.Start3D2D(drawpos, ang, v.size)
            draw.RoundedBox(0, -20, -20, 40, 40, Color(200, 0, 0, 100))
            surface.SetDrawColor(255, 255, 255, 100)
            surface.DrawOutlinedRect(-20, -20, 40, 40)
            draw.SimpleTextOutlined("12pt arial", "12ptFont", 0, -12, Color(255, 255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP, 1, Color(0, 0, 0, 255))
            draw.SimpleTextOutlined("40x40 box", "12ptFont", 0, 2, Color(255, 255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP, 1, Color(0, 0, 0, 255))
            surface.SetDrawColor(0, 255, 0, 230)
            surface.DrawLine(0, 0, 0, 8)
            surface.DrawLine(0, 0, 8, 0)
            cam.End3D2D()
        end
    end
end

--[[*******************************
	All worldmodel drawing science
********************************]]
SWEP.wRenderOrder = nil

function SWEP:DrawWorldModel()
    --if true then return end
    --SCKDebugRepeat( "SWEP:WMD", "Drawing worldmodel!" )
    local wm = self.world_model
    if not IsValid(wm) then return end

    if not self.wRenderOrder then
        self.wRenderOrder = {}

        for k, v in pairs(self.w_models) do
            if v.type == "Model" then
                table.insert(self.wRenderOrder, 1, k)
            elseif v.type == "Sprite" or v.type == "Quad" then
                table.insert(self.wRenderOrder, k)
            end
        end
    end

    local bone_ent

    if IsValid(self.Owner) then
        self:SetColor(Color(255, 255, 255, 255))
        self:SetRenderMode(0)
        wm:SetNoDraw(true)
        if self.Owner:GetActiveWeapon() ~= self.Weapon then return end
        wm:SetParent(self.Owner)

        if self.ShowWorldModel then
            wm:DrawModel()
        end

        bone_ent = self.Owner
    else
        -- this only happens if the weapon is dropped, which shouldn't happen normally.
        self:SetColor(Color(255, 0, 0, 0))
        self:SetRenderMode(1)
        wm:SetNoDraw(false) -- else DrawWorldModel stops being called for some reason
        wm:SetParent(self)

        --wm:SetPos(opos)
        --wm:SetAngles(oang)
        if self.ShowWorldModel then
            wm:DrawModel()
        end

        -- the reason that we don't always use this bone is because it lags 1 frame behind the player's right hand bone when held
        bone_ent = wm
    end

    --[[ BASE CODE FOR NEW SWEPS ]]
    --[[self:DrawModel()
	if (IsValid(self.Owner)) then
		bone_ent = self.Owner
	else
		// when the weapon is dropped
		bone_ent = self
	end]]
    for k, name in pairs(self.wRenderOrder) do
        local v = self.w_models[name]

        if not v then
            self.wRenderOrder = nil
            break
        end

        local pos, ang

        if v.bone then
            pos, ang = self:GetBoneOrientation(self.w_models, name, bone_ent)
        else
            pos, ang = self:GetBoneOrientation(self.w_models, name, bone_ent, "ValveBiped.Bip01_R_Hand")
        end

        if not pos then continue end
        local model = v.modelEnt
        local sprite = v.spriteMaterial

        if v.type == "Model" and IsValid(model) then
            model:SetPos(pos + ang:Forward() * v.pos.x + ang:Right() * v.pos.y + ang:Up() * v.pos.z)
            ang:RotateAroundAxis(ang:Up(), v.angle.y)
            ang:RotateAroundAxis(ang:Right(), v.angle.p)
            ang:RotateAroundAxis(ang:Forward(), v.angle.r)
            model:SetAngles(ang)
            --model:SetModelScale(v.size)
            local matrix = Matrix()
            matrix:Scale(v.size)
            model:EnableMatrix("RenderMultiply", matrix)

            if v.material == "" then
                model:SetMaterial("")
            elseif model:GetMaterial() ~= v.material then
                model:SetMaterial(v.material)
            end

            if v.skin ~= model:GetSkin() then
                model:SetSkin(v.skin)
            end

            for k, v in pairs(v.bodygroup) do
                if model:GetBodygroup(k) ~= v then
                    model:SetBodygroup(k, v)
                end
            end

            if v.surpresslightning then
                render.SuppressEngineLighting(true)
            end

            render.SetColorModulation(v.color.r / 255, v.color.g / 255, v.color.b / 255)
            render.SetBlend(v.color.a / 255)
            model:DrawModel()
            render.SetBlend(1)
            render.SetColorModulation(1, 1, 1)

            if v.surpresslightning then
                render.SuppressEngineLighting(false)
            end
        elseif v.type == "Sprite" and sprite then
            local drawpos = pos + ang:Forward() * v.pos.x + ang:Right() * v.pos.y + ang:Up() * v.pos.z
            render.SetMaterial(sprite)
            render.DrawSprite(drawpos, v.size.x, v.size.y, v.color)
        elseif v.type == "Quad" then
            local drawpos = pos + ang:Forward() * v.pos.x + ang:Right() * v.pos.y + ang:Up() * v.pos.z
            ang:RotateAroundAxis(ang:Up(), v.angle.y)
            ang:RotateAroundAxis(ang:Right(), v.angle.p)
            ang:RotateAroundAxis(ang:Forward(), v.angle.r)
            cam.Start3D2D(drawpos, ang, v.size)
            draw.RoundedBox(0, -20, -20, 40, 40, Color(200, 0, 0, 100))
            surface.SetDrawColor(255, 255, 255, 100)
            surface.DrawOutlinedRect(-20, -20, 40, 40)
            draw.SimpleTextOutlined("12pt arial", "12ptFont", 0, -12, Color(255, 255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP, 1, Color(0, 0, 0, 255))
            draw.SimpleTextOutlined("40x40 box", "12ptFont", 0, 2, Color(255, 255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP, 1, Color(0, 0, 0, 255))
            surface.SetDrawColor(0, 255, 0, 230)
            surface.DrawLine(0, 0, 0, 8)
            surface.DrawLine(0, 0, 8, 0)
            cam.End3D2D()
        end
    end
end

function SWEP:Holster()
    self.useThirdPerson = false
    local vm = self.Owner:GetViewModel()

    if IsValid(vm) then
        self:ResetBonePositions(vm)
    end

    return true
end

local function DrawDot(x, y)
    surface.SetDrawColor(100, 100, 100, 255)
    surface.DrawRect(x - 2, y - 2, 4, 4)
    surface.SetDrawColor(255, 255, 255, 255)
    surface.DrawRect(x - 1, y - 1, 2, 2)
end

SWEP.FirstTimeOpen = true

function SWEP:DrawHUD()
    DrawDot(ScrW() / 2, ScrH() / 2)
    DrawDot(ScrW() / 2 + 10, ScrH() / 2)
    DrawDot(ScrW() / 2 - 10, ScrH() / 2)
    DrawDot(ScrW() / 2, ScrH() / 2 + 10)
    DrawDot(ScrW() / 2, ScrH() / 2 - 10)

    if self.Frame and self.Frame:IsVisible() then
        self.FirstTimeOpen = false
        local text = ""

        if self.useThirdPerson then
            text = "Hold right mouse and drag to rotate. Additionally hold E key to zoom."
        else
            text = "Hold right mouse and drag to adjust ironsights (mode: " .. self.cur_drag_mode .. ")"
        end

        draw.SimpleTextOutlined(text, "default", ScrW() / 2, ScrH() / 4, Color(255, 255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP, 1, Color(20, 20, 20, 255))
    elseif self.FirstTimeOpen then
        draw.SimpleTextOutlined("Press right mouse to open menu", "default", ScrW() / 2, ScrH() / 4, Color(255, 255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP, 1, Color(20, 20, 20, 255))
    end
end

--[[***** Create model browser ****]]
-- callback = function( selected_model )
function SWEP:OpenBrowser(current, browse_type, callback)
    local wep = self
    wep.browser_callback = callback
	if IsValid(wep.modelbrowser) then
		wep.modelbrowser:Remove()
		wep.modelbrowser = nil
	end

	if IsValid(wep.Frame) then
    	wep.Frame:SetVisible(false)
	end

    if browse_type == "model" and IsValid(wep.modelbrowser) then
        wep.modelbrowser:SetVisible(true)
        wep.modelbrowser:MakePopup()
        wep.modelbrowser_list.OnRowSelected(nil, nil, current)

        return
    elseif browse_type == "material" and wep.matbrowser then
        wep.matbrowser:SetVisible(true)
        wep.matbrowser:MakePopup()
        wep.matbrowser_list.OnRowSelected(nil, nil, current)

        return
    end

    local browser = vgui.Create("DFrame")
    browser:SetSize(480, ScrH() * 0.8)
    browser:SetPos(50, 50)
    browser:SetDraggable(true)
    browser:ShowCloseButton(false)
    browser:SetSizable(true)
    browser:SetDeleteOnClose(false)

    if browse_type == "model" then
        browser:SetTitle("Model browser")
        wep.modelbrowser = browser
    elseif browse_type == "material" then
        browser:SetTitle("Material browser")
        wep.matbrowser = browser
    end

    local tree = vgui.Create("DTree", browser)
    --tree:SetPos( 5, 30 )
    --tree:SetSize( browser:GetWide() - 10, browser:GetTall()-355 )
    tree:SetTall(300)
    tree:DockPadding(5, 5, 5, 5)
    tree:Dock(TOP)
    tree:SetKeyboardInputEnabled(true)

	local browsing = ""
	local clearBrowsing = 0
    local mainNode
    local searchSelect

    local function setScroll()
        local node = tree:GetSelectedItem()
        local _, initialY = tree:LocalToScreen(0, 0)
        local _, nodeY = node:LocalToScreen(0, 0)
        local scrollOffset = tree:GetVBar():GetOffset()
        local offsetY = nodeY - initialY - scrollOffset
        tree:GetVBar():SetScroll(offsetY)
    end

    wep.modelbrowser.OnKeyCodePressed = function(s, key)
        if (key == KEY_BACKSPACE) then
            if !IsValid(searchSelect) then return end
            local parentNode = searchSelect:GetParentNode()
            if not IsValid(parentNode) then return end
            searchSelect:SetSelected(false)
            tree:SetSelectedItem(parentNode)
            parentNode:SetSelected(true)
            timer.Simple(0, function()
                local _, y = parentNode:GetPos()
                tree:GetVBar():SetScroll(y)
            end)
            searchSelect = parentNode
            setScroll(searchSelect)
        elseif (key == KEY_DOWN)  then
            local node = tree:GetSelectedItem()
            if not IsValid(node) or not IsValid(node:GetParentNode()) then return end
            if (table.Count(node:GetParentNode():GetChildNodes()) <= 1) then return end

            for k, v in pairs(node:GetParentNode():GetChildNodes()) do
                if v == node and k < table.Count(node:GetParentNode():GetChildNodes()) then
                    local newNode = node:GetParentNode():GetChildNodes()[k + 1]
                    searchSelect = newNode
                    newNode:DoClick()
                    tree:SetSelectedItem(newNode)
                    break
                end
            end
            setScroll(searchSelect)
        elseif (key == KEY_UP)  then
            local node = tree:GetSelectedItem()
            if not IsValid(node) or not IsValid(node:GetParentNode()) then return end
            if (table.Count(node:GetParentNode():GetChildNodes()) <= 1) then return end

            for k, v in pairs(node:GetParentNode():GetChildNodes()) do
                if v == node and k > 1 then
                    local newNode = node:GetParentNode():GetChildNodes()[k - 1]
                    searchSelect = newNode
                    newNode:DoClick()
                    tree:SetSelectedItem(newNode)
                    break
                end
            end

            setScroll(searchSelect)
        elseif (key == KEY_LEFT) then
            local node = tree:GetSelectedItem()
            if not IsValid(node) or not IsValid(node:GetParentNode()) then return end
            if IsValid(searchSelect) then
                searchSelect:ExpandRecurse(false)
            end
            searchSelect = node:GetParentNode()
            tree:SetSelectedItem(searchSelect)
            setScroll(searchSelect)
        elseif (key == KEY_RIGHT) then
            local node = tree:GetSelectedItem()
            if not IsValid(node) then return end
            if (!IsValid(node:GetChildNodes()[1])) then return end

            searchSelect = node:GetChildNodes()[1]
            searchSelect:DoClick()
            searchSelect:ExpandTo(true)
            tree:SetSelectedItem(searchSelect)
            setScroll(searchSelect)
        end
        if not input.GetKeyName(key) or #input.GetKeyName(key) > 1 then return end

        browsing = browsing .. input.GetKeyName(key)
		clearBrowsing = RealTime() + 1

        if not IsValid(mainNode) then
            local selected = tree:GetSelectedItem()
            if not IsValid(selected) then return end
            mainNode = selected
        end

        for k, v in pairs(mainNode:GetChildNodes()) do
            if (string.StartWith(string.lower(v:GetText()), string.lower(browsing))) then
                tree:GetSelectedItem():SetSelected(false)
                if IsValid(searchSelect) then
                    searchSelect:SetSelected(false)
                    searchSelect:ExpandTo(false)
                end
                searchSelect = v
                tree:SetSelectedItem(v)
                v:SetSelected(true)
                v:DoClick()
                v:ExpandTo(true)
                tree:ScrollToChild(v)
                break
            end
        end
    end

    if (IsValid(wep.modelbrowser)) then
        wep.modelbrowser.PaintOver = function(s, w, h)
            if (clearBrowsing < RealTime()) then
                browsing = ""
                mainNode = nil
            end

            if (browsing != "") then
                draw.SimpleText(browsing, NebulaUI:Font(24), w - 8, 4, Color(255, 255, 255, 255), TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)
            end
        end
    end

    local nodelist = {}
    local filecache = {}
    local checked = {}
    local modlist = vgui.Create("DListView", browser)
    modlist:SetMultiSelect(false)
    modlist:SetDrawBackground(true)

    if browse_type == "model" then
        modlist:AddColumn("Model")
    elseif browse_type == "material" then
        modlist:AddColumn("Material")
    end

    modlist:DockPadding(5, 5, 5, 0)
    modlist:Dock(FILL)
    local bpanel = vgui.Create("DPanel", browser)
    bpanel:SetTall(200)
    bpanel:SetDrawBackground(false)
    bpanel:DockMargin(5, 5, 5, 5)
    bpanel:Dock(BOTTOM)
    local modzoom = 30
    local modview

    if browse_type == "model" then
        modview = vgui.Create("DModelPanel", bpanel)
        modview:SetModel("")
        modview:SetCamPos(Vector(modzoom, modzoom, modzoom / 2))
        modview:SetLookAt(Vector(0, 0, 0))
    elseif browse_type == "material" then
        modview = vgui.Create("DImage", bpanel)
    end

    --modview:SetImage("")
    modview:SetSize(200, 200)
    modview:Dock(LEFT)
    local rpanel = vgui.Create("DPanel", bpanel)
    rpanel:SetDrawBackground(false)
    rpanel:DockPadding(5, 0, 0, 0)
    rpanel:Dock(FILL)
    local mdlabel = vgui.Create("DLabel", rpanel)
    mdlabel:SetText(current)
    mdlabel:SizeToContents()
    mdlabel:Dock(TOP)

    if browse_type == "model" then
        local zoomslider = vgui.Create("DNumSlider", rpanel)
        zoomslider:SetText("Zoom")
        zoomslider:SetMin(8)
        zoomslider:SetMax(256)
        zoomslider:SetDecimals(0)
        zoomslider:SetValue(modzoom)

        zoomslider.Wang.ConVarChanged = function(panel, value)
            local modzoom = tonumber(value)
            modview:SetCamPos(Vector(modzoom, modzoom, modzoom / 2))
            modview:SetLookAt(Vector(0, 0, 0))
        end

        zoomslider:Dock(FILL)
    end

    local selected = ""

    modlist.OnRowSelected = function(panel, line, override)
        -- for some reason the list itself throws a panel at it in the callback
        if type(override) ~= "string" then
            override = nil
        end

        local path = override or modlist:GetLine(line):GetValue(1)

        if browse_type == "model" then
            modview:SetModel(path)
        elseif browse_type == "material" then
            if path:sub(1, 10) == "materials/" then
                path = path:sub(11) -- removes the "materials/" part
            end

            path = path:gsub("%.vmt", "")

            if file.Exists("materials/" .. path .. ".vmt", "GAME") then
                modview:SetImage(path)
            end
        end

        mdlabel:SetText(path)
        selected = path
    end

    -- set the default
    modlist.OnRowSelected(nil, nil, current)

    if browse_type == "model" then
        wep.modelbrowser_list = modlist
    elseif browse_type == "material" then
        wep.matbrowser_list = modlist
    end

    local cancelbtn = vgui.Create("DButton", rpanel)
    cancelbtn:SetTall(20)
    cancelbtn:SetText("cancel")

    cancelbtn.DoClick = function()
        if wep.Frame then
            wep.Frame:SetVisible(true)
        end

        browser:Close()
    end

    cancelbtn:Dock(BOTTOM)
    local choosebtn = vgui.Create("DButton", rpanel)
    choosebtn:SetTall(20)

    if browse_type == "model" then
        choosebtn:SetText("DO WANT THIS MODEL")
    elseif browse_type == "material" then
        choosebtn:SetText("DO WANT THIS MATERIAL")
    end

    choosebtn.DoClick = function()
        if wep.browser_callback then
            pcall(wep.browser_callback, selected)
        end

        if wep.Frame then
            wep.Frame:SetVisible(true)
        end

        browser:Close()
    end

    choosebtn:DockMargin(0, 0, 0, 5)
    choosebtn:Dock(BOTTOM)
    local LoadDirectories

    local AddNode = function(base, dir, tree_override)
        local newpath = base .. "/" .. dir
        local basenode = nodelist[base]

        if tree_override then
            newpath = dir
            basenode = tree_override
        end

        if not basenode then
            print("No base node for \"" .. tostring(base) .. "\", \"" .. tostring(dir) .. "\", " .. tostring(tree_override))
        end

        nodelist[newpath] = basenode:AddNode(dir)
		if not IsValid(nodelist[newpath]) then
			return
		end

        nodelist[newpath].DoClick = function()
            LoadDirectories(newpath)
            modlist:Clear()
            modlist:SetVisible(true)

            if filecache[newpath] then
                for k, f in pairs(filecache[newpath]) do
                    modlist:AddLine(f)
                end
            else
                filecache[newpath] = {}
                local files, folders

                if newpath:sub(1, 9) == "materials" then
                    files, folders = file.Find(newpath .. "/*.vmt", "GAME")
                else
                    files, folders = file.Find(newpath .. "/*.mdl", "GAME")
                end

                table.sort(files)

                for k, f in pairs(files) do
                    local newfilepath = newpath .. "/" .. f
                    modlist:AddLine(newfilepath)
                    table.insert(filecache[newpath], newfilepath)
                end
            end
        end
    end

    if browse_type == "model" then
        AddNode("", "models", tree)
    elseif browse_type == "material" then
        AddNode("", "materials", tree)
    end

    LoadDirectories = function(v)
        if table.HasValue(checked, v) then return end
        local files
        files, newdirs = file.Find(v .. "/*", "GAME")
        table.insert(checked, v)
        table.sort(newdirs)

        for _, dir in pairs(newdirs) do
            AddNode(v, dir)
        end
    end

    if browse_type == "model" then
        LoadDirectories("models")
    elseif browse_type == "material" then
        LoadDirectories("materials")
    end

    browser:SetVisible(true)
    browser:MakePopup()
end

--[[**************************
			Menu
**************************]]
local function CreateMenu(preset)
    local wep = GetSCKSWEP(LocalPlayer())
    if not IsValid(wep) then return nil end
    wep.save_data = table.Copy(save_data_template)

    if preset then
        -- use the preset
        for k, v in pairs(preset) do
            wep.save_data[k] = v
        end
    end

	if IsValid(main_menu) then
		main_menu:Remove()
	end
    -- Now for the actual menu:		
    local f = vgui.Create("DFrame")
	main_menu = f
    f:SetSize(480, ScrH() * 0.8)
    f:SetPos(50, 50)
    f:SetTitle("SWEP Construction Kit")
    f:SetDraggable(true)
    f:ShowCloseButton(true)
    f:SetSizable(true)
    f:SetDeleteOnClose(false)
    local tpanel = vgui.Create("DPanel", f)
    tpanel:SetDrawBackground(false)
    tpanel:SetTall(20)
    tpanel:DockMargin(0, 0, 0, 5)
    tpanel:Dock(TOP)
    local tpsbonelist = vgui.Create("DComboBox", tpanel)
    tpsbonelist:SetWide(150)
    tpsbonelist:SetToolTip("Bone to focus third person view on")

    tpsbonelist.OnSelect = function(p, index, value)
        wep.tpsfocusbone = value
    end

    tpsbonelist:SetText(wep.tpsfocusbone)
    tpsbonelist:DockMargin(5, 0, 0, 0)
    tpsbonelist:Dock(RIGHT)
    local tlabel = vgui.Create("DLabel", tpanel)
    tlabel:SetText("Focus:")
    tlabel:SizeToContents()
    tlabel:SetTall(20)
    tlabel:DockMargin(10, 0, 0, 0)
    tlabel:Dock(RIGHT)
    PopulateBoneList(tpsbonelist, LocalPlayer())
    local tbtn = vgui.Create("DButton", tpanel)
    tbtn:SetText("Toggle thirdperson")

    tbtn.DoClick = function()
        RunConsoleCommand("swepck_togglethirdperson")
    end

    tbtn:Dock(FILL)
    local tab = vgui.Create("DPropertySheet", f)
    wep.ptool = vgui.Create("DPanel", tab)

    wep.ptool.Paint = function()
        surface.SetDrawColor(70, 70, 70, 255)
        surface.DrawRect(0, 0, wep.ptool:GetWide(), wep.ptool:GetTall())
    end

    wep.pweapon = vgui.Create("DPanel", tab)

    wep.pweapon.Paint = function()
        surface.SetDrawColor(70, 70, 70, 255)
        surface.DrawRect(0, 0, wep.pweapon:GetWide(), wep.pweapon:GetTall())
    end

    wep.pironsight = vgui.Create("DPanel", tab)

    wep.pironsight.Paint = function()
        surface.SetDrawColor(70, 70, 70, 255)
        surface.DrawRect(0, 0, wep.pironsight:GetWide(), wep.pironsight:GetTall())
    end

    wep.pmodels = vgui.Create("DPanel", tab)

    wep.pmodels.Paint = function()
        surface.SetDrawColor(70, 70, 70, 255)
        surface.DrawRect(0, 0, wep.pmodels:GetWide(), wep.pmodels:GetTall())
    end

    wep.pwmodels = vgui.Create("DPanel", tab)

    wep.pwmodels.Paint = function()
        surface.SetDrawColor(70, 70, 70, 255)
        surface.DrawRect(0, 0, wep.pwmodels:GetWide(), wep.pwmodels:GetTall())
    end

    tab:AddSheet("Tool", wep.ptool, nil, false, false, "Modify tool settings")
    tab:AddSheet("Weapon", wep.pweapon, nil, false, false, "Modify weapon settings")
    tab:AddSheet("Ironsights", wep.pironsight, nil, false, false, "Modify ironsights")
    tab:AddSheet("View Models", wep.pmodels, nil, false, false, "Modify view models")
    tab:AddSheet("World Models", wep.pwmodels, nil, false, false, "Modify world models")
    wep.ptool:DockPadding(5, 5, 5, 5)
    wep.pweapon:DockPadding(5, 5, 5, 5)
    wep.pironsight:DockPadding(5, 5, 5, 5)
    wep.pmodels:DockPadding(5, 5, 5, 5)
    wep.pwmodels:DockPadding(5, 5, 5, 5)
    tab:Dock(FILL)
    --[[****************
		Tool page
	****************]]
    include("weapons/" .. wep:GetClass() .. "/menu/tool.lua")
    --[[****************
		Weapon page
	****************]]
    include("weapons/" .. wep:GetClass() .. "/menu/weapon.lua")
    --[[********************
		Ironsights page
	********************]]
    include("weapons/" .. wep:GetClass() .. "/menu/ironsights.lua")
    --[[***************************************
		View models and World models page
	***************************************]]
    include("weapons/" .. wep:GetClass() .. "/menu/models.lua")
    -- finally, return the frame!

    return f
end

function SWEP:OpenMenu(preset)
    if not self.Frame then
        self.Frame = CreateMenu(preset)
    end

    if IsValid(self.Frame) then
        self.Frame:SetVisible(true)
        self.Frame:MakePopup()
    else
        self.Frame = nil
    end
end

function SWEP:OnRemove()
    self:CleanMenu()
end

function SWEP:OnDropWeapon()
    self.useThirdPerson = false
    self.LastOwner = nil
    if not self.Frame then return end
    self.Frame:Close()
end

function SWEP:CleanMenu()
    self:RemoveModels()
    if not self.Frame then return end
    self.v_modelListing = nil
    self.w_modelListing = nil
    self.v_panelCache = {}
    self.w_panelCache = {}
    self.Frame:Remove()
    self.Frame = nil
end

function SWEP:HUDShouldDraw(el)
    return el ~= "CHudAmmo" and el ~= "CHudSecondaryAmmo"
end

--[[**************************
	Third person view
**************************]]
function TPCalcView(pl, pos, angles, fov)
    local wep = pl:GetActiveWeapon()

    if not IsValid(wep) or not wep.IsSCK or not wep.useThirdPerson then
        wep.useThirdPerson = false

        return
    end

    local look_pos = pos
    local rhand_bone = pl:LookupBone(wep.tpsfocusbone)

    if rhand_bone then
        look_pos = pl:GetBonePosition(rhand_bone)
    end

    local view = {}
    view.origin = look_pos + ((pl:GetAngles() + wep.thirdPersonAngle):Forward() * wep.thirdPersonDis)
    view.angles = (look_pos - view.origin):Angle()
    view.fov = fov

    return view
end

oldCVHooks = {}
hooksCleared = false

local function CVHookReset()
    --print("Hook reset")
    hook.Remove("CalcView", "TPCalcView")

    for k, v in pairs(oldCVHooks) do
        hook.Add("CalcView", k, v)
    end

    oldCVHooks = {}
    hooksCleared = false
end

function SWEP:CalcViewHookManagement()
    if not hooksCleared then
        local CVHooks = hook.GetTable()["CalcView"]

        if CVHooks then
            for k, v in pairs(CVHooks) do
                oldCVHooks[k] = v
                hook.Remove("CalcView", k)
            end
        end

        hook.Add("CalcView", "TPCalcView", TPCalcView)
        hooksCleared = true
    else
        timer.Create("CVHookReset", 2, 1, CVHookReset)
    end
end

hook.Add("ShouldDrawLocalPlayer", "ThirdPerson", function(pl)
    local wep = pl:GetActiveWeapon()
    if IsValid(wep) and wep.useThirdPerson then return true end
end)

-- local wep = p(1):GetActiveWeapon()

-- timer.Simple(0.1, function()
-- 	//wep:OpenBrowser("models/player/alyx.mdl", "model")
-- end)