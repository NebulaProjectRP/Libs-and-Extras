if BSHADOWS == nil then
BSHADOWS = {}

--The original drawing layer
BSHADOWS.RenderTarget = GetRenderTarget("bshadows_original", ScrW(), ScrH())

--The shadow layer
BSHADOWS.RenderTarget2 = GetRenderTarget("bshadows_shadow",  ScrW(), ScrH())

--The matarial to draw the render targets on
BSHADOWS.ShadowMaterial = CreateMaterial("bshadows","UnlitGeneric",{
	["$translucent"] = 1,
	["$vertexalpha"] = 1,
	["alpha"] = 1
})

--When we copy the rendertarget it retains color, using this allows up to force any drawing to be black
--Then we can blur it to create the shadow effect
BSHADOWS.ShadowMaterialGrayscale = CreateMaterial("bshadows_grayscale","UnlitGeneric",{
	["$translucent"] = 1,
	["$vertexalpha"] = 1,
	["$alpha"] = 1,
	["$color"] = "0 0 0",
	["$color2"] = "0 0 0"
})

--Call this to begin drawing a shadow
BSHADOWS.BeginShadow = function()

	--Set the render target so all draw calls draw onto the render target instead of the screen
	render.PushRenderTarget(BSHADOWS.RenderTarget)

	--Clear is so that theres no color or alpha
	render.OverrideAlphaWriteEnable(true, true)
	render.Clear(0,0,0,0)
	render.OverrideAlphaWriteEnable(false, false)

	--Start Cam2D as where drawing on a flat surface 
	cam.Start2D()

	--Now leave the rest to the user to draw onto the surface
end

--This will draw the shadow, and mirror any other draw calls the happened during drawing the shadow
BSHADOWS.EndShadow = function(intensity, spread, blur, opacity, direction, distance, _shadowOnly)
	
	--Set default opcaity
	opacity = opacity or 255
	direction = direction or 0
	distance = distance or 0
	_shadowOnly = _shadowOnly or false

	--Copy this render target to the other
	render.CopyRenderTargetToTexture(BSHADOWS.RenderTarget2)

	--Blur the second render target
	if blur > 0 then
		render.OverrideAlphaWriteEnable(true, true)
		render.BlurRenderTarget(BSHADOWS.RenderTarget2, spread, spread, blur)
		render.OverrideAlphaWriteEnable(false, false) 
	end

	--First remove the render target that the user drew
	render.PopRenderTarget()

	--Now update the material to what was drawn
	BSHADOWS.ShadowMaterial:SetTexture('$basetexture', BSHADOWS.RenderTarget)

	--Now update the material to the shadow render target
	BSHADOWS.ShadowMaterialGrayscale:SetTexture('$basetexture', BSHADOWS.RenderTarget2)

	--Work out shadow offsets
	local xOffset = math.sin(math.rad(direction)) * distance 
	local yOffset = math.cos(math.rad(direction)) * distance

	--Now draw the shadow
	BSHADOWS.ShadowMaterialGrayscale:SetFloat("$alpha", opacity/255) --set the alpha of the shadow
	render.SetMaterial(BSHADOWS.ShadowMaterialGrayscale)
	for i = 1 , math.ceil(intensity) do
		render.DrawScreenQuadEx(xOffset, yOffset, ScrW(), ScrH())
	end

	if not _shadowOnly then
		--Now draw the original
		BSHADOWS.ShadowMaterial:SetTexture('$basetexture', BSHADOWS.RenderTarget)
		render.SetMaterial(BSHADOWS.ShadowMaterial)
		render.DrawScreenQuad()
	end

	cam.End2D()
end

--This will draw a shadow based on the texture you passed it.
BSHADOWS.DrawShadowTexture = function(texture, intensity, spread, blur, opacity, direction, distance, shadowOnly)

	--Set default opcaity
	opacity = opacity or 255
	direction = direction or 0
	distance = distance or 0
	shadowOnly = shadowOnly or false

	--Copy the texture we wish to create a shadow for to the shadow render target
	render.CopyTexture(texture, BSHADOWS.RenderTarget2)

	--Blur the second render target
	if blur > 0 then
		render.PushRenderTarget(BSHADOWS.RenderTarget2)
		render.OverrideAlphaWriteEnable(true, true)
		render.BlurRenderTarget(BSHADOWS.RenderTarget2, spread, spread, blur)
		render.OverrideAlphaWriteEnable(false, false) 
		render.PopRenderTarget()
	end

	--Now update the material to the shadow render target
	BSHADOWS.ShadowMaterialGrayscale:SetTexture('$basetexture', BSHADOWS.RenderTarget2)

	--Work out shadow offsets
	local xOffset = math.sin(math.rad(direction)) * distance 
	local yOffset = math.cos(math.rad(direction)) * distance

	--Now draw the shadow 
	BSHADOWS.ShadowMaterialGrayscale:SetFloat("$alpha", opacity/255) --Set the alpha
	render.SetMaterial(BSHADOWS.ShadowMaterialGrayscale)
	for i = 1 , math.ceil(intensity) do
		render.DrawScreenQuadEx(xOffset, yOffset, ScrW(), ScrH())
	end
	if not shadowOnly then
		--Now draw the original
		BSHADOWS.ShadowMaterial:SetTexture('$basetexture', texture)
		render.SetMaterial(BSHADOWS.ShadowMaterial)
		render.DrawScreenQuad()
	end
end
end

--This code can be improved a lot.
--Feel free to improve, use or modify in any way although credit would be appreciated.

if BMASKS == nil then
BMASKS = {} --Global table, access the functions here

BMASKS.Materials = {} --Cache materials so they dont need to be reloaded
BMASKS.Masks = {} --A table of all active mask objects, you should destroy a mask object when done with it

--The material used to draw the render targets
BMASKS.MaskMaterial = CreateMaterial("!bluemask","UnlitGeneric",{
	["$translucent"] = 1,
	["$vertexalpha"] = 1,
	["$alpha"] = 1,
})

--Creates a mask with the specified options
--Be sure to pass a unique maskName for each mask, otherwise they will override each other
BMASKS.CreateMask = function(maskName, maskPath, maskProperties)
	local mask = {}

	--Set mask name
	mask.name = maskName

	--Load materials
	if BMASKS.Materials[maskPath] == nil then
		BMASKS.Materials[maskPath] = Material(maskPath, maskProperties)
	end

	--Set the mask material
	mask.material = BMASKS.Materials[maskPath]

	--Create the render target
	mask.renderTarget = GetRenderTargetEx("BMASKS:"..maskName, ScrW(), ScrH(), RT_SIZE_FULL_FRAME_BUFFER, MATERIAL_RT_DEPTH_NONE, 2, CREATERENDERTARGETFLAGS_UNFILTERABLE_OK, IMAGE_FORMAT_RGBA8888)

	BMASKS.Masks[maskName] = mask

	return maskName
end

--Call this to begin drawing with a mask.
--After calling this any draw call will be masked until you call EndMask(maskName)
BMASKS.BeginMask = function(maskName)
	--FindMask
	if BMASKS.Masks[maskName] == nil then 
		print("Cannot begin a mask without creating it first!") 
		return false
	end

	--Store current render target
	BMASKS.Masks[maskName].previousRenderTarget = render.GetRenderTarget() 
	
	--Confirgure drawing so that we write to the masks render target
	render.PushRenderTarget(BMASKS.Masks[maskName].renderTarget)
	render.OverrideAlphaWriteEnable( true, true )
	render.Clear( 0, 0, 0, 0 ) 
end

--Ends the mask and draws it
--Not calling this after calling BeginMask will cause some really bad effects 
--This done return the render target used, using this you can create other effects such as drop shadows without problems
--Passes true for dontDraw will result in it not being render and only returning the texture of the result (which is ScrW()xScrH())
BMASKS.EndMask = function(maskName, x, y, sizex, sizey, opacity, rotation, dontDraw)

	dontDraw = dontDraw or false
	rotation = rotation or 0
	opacity = opacity or 255

	--Draw the mask
	render.OverrideBlendFunc( true, BLEND_ZERO, BLEND_SRC_ALPHA, BLEND_DST_ALPHA, BLEND_ZERO )
	surface.SetDrawColor(Color(255,255,255,opacity))
	surface.SetMaterial(BMASKS.Masks[maskName].material)
	if rotation == nil or rotation == 0 then
		surface.DrawTexturedRect(x, y, sizex, sizey) 
	else
		surface.DrawTexturedRectRotated(x, y, sizex, sizey, rotation) 
	end
	render.OverrideBlendFunc(false)
	render.OverrideAlphaWriteEnable( false )
	render.PopRenderTarget() 

    --Update material
	BMASKS.MaskMaterial:SetTexture('$basetexture', BMASKS.Masks[maskName].renderTarget)

	--Clear material for upcoming draw calls
	draw.NoTexture()

	--Only draw if they want is to
	if not dontDraw then
		--Now draw finished result
		surface.SetDrawColor(Color(255,255,255,255)) 
		surface.SetMaterial(BMASKS.MaskMaterial) 
		render.SetMaterial(BMASKS.MaskMaterial)
		render.DrawScreenQuad() 
	end

	return BMASKS.Masks[maskName].renderTarget
end
end