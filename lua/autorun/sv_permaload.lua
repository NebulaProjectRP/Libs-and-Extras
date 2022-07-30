/*
   ____          _          _   ____          __  __       _ _                     
  / ___|___   __| | ___  __| | | __ ) _   _  |  \/  | __ _| | |__   ___  _ __ ___  
 | |   / _ \ / _` |/ _ \/ _` | |  _ \| | | | | |\/| |/ _` | | '_ \ / _ \| '__/ _ \ 
 | |__| (_) | (_| |  __/ (_| | | |_) | |_| | | |  | | (_| | | |_) | (_) | | | (_) |
  \____\___/ \__,_|\___|\__,_| |____/ \__, | |_|  |_|\__,_|_|_.__/ \___/|_|  \___/ 
                                      |___/                                        
*/

if not PermaProps then PermaProps = {} end

print("---------------------------------")
print("| Loading " .. (SERVER and "Server" or "Client") .. "Side PermaProps |")
print("---------------------------------")

if SERVER then
	AddCSLuaFile("permaprops/cl_drawent.lua")
	AddCSLuaFile("permaprops/cl_menu.lua")
	for k, v in pairs(file.Find("permaprops/sv_*.lua", "LUA")) do
		include("permaprops/".. v)
		print("permaprops/".. v)
	end
else
	include("permaprops/cl_drawent.lua")
	include("permaprops/cl_menu.lua")
end

print("-----------------------------")
print("| Loading Shared PermaProps |")
print("-----------------------------")

for k, v in pairs(file.Find("permaprops/sh_*.lua", "LUA")) do
	
	AddCSLuaFile("permaprops/".. v)
	include("permaprops/".. v)
	print("permaprops/".. v)


end

print("---------------------------------")
print("| Loading ClientSide PermaProps |")
print("---------------------------------")

for k, v in pairs(file.Find("permaprops/cl_*.lua", "LUA")) do
	
	AddCSLuaFile("permaprops/".. v)
	print("permaprops/".. v)

end

print("-------------------------------")