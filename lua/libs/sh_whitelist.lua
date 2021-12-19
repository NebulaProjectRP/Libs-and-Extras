NebulaOwners = {
    ["76561198044940228"] = true, -- Gonzo
    ["76561198112004800"] = true, -- Wookie
} -- The owners of the server.

local meta = FindMetaTable("Player")

function meta:IsOwner()
    return NebulaOwners[self:SteamID64()]
end