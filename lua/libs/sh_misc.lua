NebulaAPI = "http://loopback.gmod:80/";

function p(x)
    return x and player.GetByID(x) or (CLIENT and LocalPlayer() or player.GetByID(1))
end

if SERVER then
    util.AddNetworkString("Nebula.CallOnClient")
end

local ent = FindMetaTable("Entity")

function ent:getFrameTime()
    local diff = CurTime() - (self._lastFrame or CurTime())
    self._lastFrame = CurTime()
    return diff
end

RPC_OWNER = 1
RPC_PVS = 2
RPC_PAS = 3
RPC_ALL = 4

function ent:callOnClient(target, method, args)
    net.Start("Nebula.CallOnClient")
    net.WriteEntity(self)
    net.WriteString(method)
    net.WriteBool(args == nil)
    if (args) then
        net.WriteData(args)
    end

    if (target == RPC_OWNER) then
        net.Send(self:GetOwner())
    elseif (target == RPC_PVS) then
        net.SendPVS(self:GetPos())
    elseif (target == RPC_PAS) then
        net.SendPAS(self:GetPos())
    elseif (target == RPC_ALL) then
        net.Broadcast()
    elseif (target:IsPlayer()) then
        net.Send(target)
    end
end

local awaiting = {}
net.Receive("Nebula.CallOnClient", function()
    local ent = net.ReadUInt(16)
    if not IsValid(Entity(ent)) then
        if not (awaiting[ent]) then
            awaiting[ent] = {}
            MsgN("Entity#" , ent, " is awaiting to be spawned.")
        end
        table.insert(awaiting[ent], {
            net.ReadString(),
            net.ReadBool() and net.ReadData(net.BytesLeft()) or nil
        })
    end
    ent = Entity(ent)
    local method = net.ReadString()
    local hasArg = net.ReadBool()
    if (hasArg) then
        local args = net.ReadData(net.BytesLeft())
        ent[method](ent, args)
    else
        ent[method](ent)
    end
end)

if CLIENT then
    
hook.Add("OnEntityCreated", "Nebula.CallOnClient", function(ent)
    if (awaiting[ent:EntIndex()]) then
        for _, data in pairs(awaiting[ent:EntIndex()]) do
            ent:callOnClient(data[1], data[2])
        end
        awaiting[ent:EntIndex()] = nil
    end
end)

end