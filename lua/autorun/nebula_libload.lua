MsgC(Color(255, 50, 255), "[LIB] ", color_white, " Loading libraries...\n")

for _, v in pairs(file.Find("libs/*.lua", "LUA")) do
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

for _, v in pairs(file.Find("libs/security/*.lua", "LUA")) do
    if (SERVER and string.StartWith(v, "sv_")) then
        include("libs/security/" .. v)
    elseif (string.StartWith(v, "cl_")) then
        if SERVER then
            AddCSLuaFile("libs/security/" .. v)
        else
            include("libs/security/" .. v)
        end
    elseif (string.StartWith(v, "sh_")) then
        if SERVER then
            AddCSLuaFile("libs/security/" .. v)
        end
        include("libs/security/" .. v)
    end
end

MsgC(Color(255, 50, 255), "[NebulaSecure] ", color_white, " Loaded\n")

MsgC(Color(255, 50, 255), "[LIB] ", color_white, " Libraries loaded successfuly.\n")

if SERVER then
    resource.AddWorkshop("2687867292")
    resource.AddWorkshop("2842851973")
    resource.AddWorkshop("2843426694")
    resource.AddWorkshop("2845283096")
    resource.AddWorkshop("2845286113")
end