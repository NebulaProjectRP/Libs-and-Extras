debugoverlay = debugoverlay or {}

local funcs = {
	{"Axis", "Vector", "Angle", "UInt", "Float", "Bool"},
	{"Box", "Vector", "Vector", "Vector", "Float", "Color"},
	{"BoxAngles", "Vector", "Vector", "Vector", "Angle", "Float", "Color"},
	{"Cross", "Vector", "UInt", "Float", "Color", "Bool"},
	{"EntityTextAtPosition", "Vector", "UInt", "String", "Float", "Color"},
	{"Grid", "Vector"},
	{"Line", "Vector", "Vector", "Float", "Color", "Bool"},
	{"ScreenText", "Float", "Float", "String", "Float", "Color"},   -- probably useless serverside
	{"Sphere", "Vector", "UInt", "Float", "Color", "Bool"},
	{"SweptBox", "Vector", "Vector", "Vector", "Vector", "Angle", "Float", "Color"},
	{"Text", "Vector", "String", "Float", "Bool"},
	{"Triangle", "Vector", "Vector", "Vector", "Float", "Color"}
}


if SERVER then
	util.AddNetworkString("dbg")

	local function sendDbg(id, ...)
		net.Start("dbg")
			net.WriteUInt(id, 4)
			net.WriteUInt(select("#", ...), 4)
			for i=2, #funcs[id] do
				local nm = funcs[id][i]
				if select(i-1, ...) ~= nil then
					net["Write" .. nm] ( (select(i-1, ...)), 16 )
				end
			end
		net.Broadcast()
	end

	for k,v in ipairs(funcs) do
		debugoverlay[ v[1] ] = function(...) sendDbg(k, ...) end
	end

else

	net.Receive("dbg", function()
		local what = net.ReadUInt(4)
		local argsAmt = net.ReadUInt(4)
		local fdat = funcs[what]
		local args = {}

		for i=2, math.min(#fdat, argsAmt + 1) do
			args[i - 1] = net["Read" .. fdat[i]] (16)
		end

		--local where, sz, lf, col, igz = net.ReadVector(), net.ReadUInt(8), net.ReadFloat(), net.ReadColor(), net.ReadBool()
		debugoverlay[fdat[1]](unpack(args))
	end)

end