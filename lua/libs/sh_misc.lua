
NebulaAPI = NebulaAPI or {}
NebulaAPI.HOST = string.StartWith(GetHostName(), "Dev") and "http://loopback.gmod:2001/" or "http://145.239.205.161:2001/"

function p(x)
    return x and player.GetByID(x) or (CLIENT and LocalPlayer() or player.GetByID(1))
end

if SERVER then
    util.AddNetworkString("Nebula.CallOnClient")
end

local meta = FindMetaTable("Entity")

function meta:getFrameTime()
    local diff = CurTime() - (self._lastFrame or CurTime())
    self._lastFrame = CurTime()
    return diff
end

function meta:getFrameTime()
    local diff = CurTime() - (self._lastFrame or CurTime())
    self._lastFrame = CurTime()
    return diff
end

local timerMeta = {
    Name = "",
    Func = function()
    end,
    Remove = function(s)
        timer.Remove(s.Name)
    end,
    Remaining = function(s)
        return timer.TimeLeft(s.Name)
    end,
    Pause = function(s)
        timer.Pause(s.Name)
    end,
    Resume = function(s)
        timer.UnPause(s.Name)
    end,
    Do = function(s, substract)
        s.Func(s.Controller)
        if (substract) then
            timer.Adjust(s.Name, s.Delay, timer.RepsLeft(s.Name) - 1)
            if (timer.RepsLeft(s.Name) <= 0) then
                s:Remove()
            end
        end
    end
}

//timerMeta.__index = timerMeta

function meta:Wait(time, fun)
    self._timerIndex = (self._timerIndex or 0) + 1
    local timerName = self:EntIndex() .. "#_Simple_" .. self._timerIndex

    local timerObject = table.Copy(timerMeta)
    timerObject.Name = timerName
    timerObject.Controller = self
    timerObject.Func = fun
    timerObject.__tostring = function()
        return timerName
    end

    timer.Create(timerName, time, 1, function()
        if not IsValid(self) then
            return
        end
        fun()
    end)

    return timerObject
end

function meta:LoopTimer(name, interval, fun)
    if not self._loopTimers then
        self._loopTimers = {}
    end
    self._loopTimers[name] = self:EntIndex() .. "#_Loop_" .. name

    local timerObject = table.Copy(timerMeta)
    timerObject.Name = self._loopTimers[name]
    timerObject.Controller = self
    timerObject.Func = fun

    timer.Create(self._loopTimers[name], interval, 0, function()
        if not IsValid(self) then
            return
        end
        fun()
    end)

    return timerObject
end

hook.Add("EntityRemoved", "RemoveTimers", function(ent)
    if (ent._timerIndex) then
        for k = 1, ent._timerIndex do
            timer.Remove(ent:EntIndex() .. "#_ID" .. k)
        end
    end
    if (ent._loopTimers) then
        for k, v in pairs(ent._loopTimers) do
            timer.Remove(v)
        end
    end
end)

RPC_OWNER = 1
RPC_PVS = 2
RPC_PAS = 3
RPC_ALL = 4

function meta:callOnClient(target, method, args)
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
    elseif (isentity(target) and target:IsPlayer()) then
        net.Send(target)
    else
        net.SendPVS(self:GetPos())
    end
end

local awaiting = {}
net.Receive("Nebula.CallOnClient", function()
    local ent = net.ReadUInt(16)
    if not IsValid(Entity(ent)) then
        if not awaiting[ent] then
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
