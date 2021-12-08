MsgC(Color(255, 50, 255), "[LIB] ", color_white, " Loading Library utilities\n")

for k, v in pairs(file.Find("libs/*.lua", "LUA")) do
    if (SERVER and string.StartWith(v, "sv_")) then
        include("libs/" .. v)
    elseif (string.StartWith(v, "cl_")) then
        if SERVER then
            AddCSLuaFile("libs/" .. v)
        else
            include("libs/" .. v)
        end
    elseif (string.StartWith(v, "sh_")) then
        if SERVER then
            AddCSLuaFile("libs/" .. v)
        end
        include("libs/" .. v)
    end
end
MsgC(Color(255, 50, 255), "[LIB] ", color_white, " Loaded successfuly\n")