WARNING_MINOR = 1
WARNING_MEDIUM = 3
WARNING_HIGH = 5
WARNING_CRITICAL = 10

hook.Add("DatabaseCreateTables", "NebulaGangs", function()
    //Table containing gang information
    NebulaDriver:MySQLCreateTable("warnings", {
        id = "INT NOT NULL AUTO_INCREMENT",
        player = "VARCHAR(32)",
        description = "VARCHAR(128)",
        origin = "VARCHAR(96)",
        severity = "INT(1) DEFAULT 1",
        hits = "INT(10) DEFAULT 1",
    }, "id")

    NebulaDriver:MySQLCreateTable("warnings_tags", {
        id = "INT NOT NULL AUTO_INCREMENT",
        player = "VARCHAR(32)",
        description = "VARCHAR(128)",
        origin = "VARCHAR(96)",
        severity = "INT(1) DEFAULT 1",
        hits = "INT(10) DEFAULT 1",
    }, "id")
end)

WARNING_KICK = 15
WARNING_DECAY = 20

local meta = FindMetaTable("Player")
function meta:addWarning(kind, severity, where)

    if (!self._warningScore) then
        self._warningScore = 0
    end

    self._warningScore = self._warningScore + severity

    if not self._warningData then
        self._warningData = {}
    end

    if (self.lastWarning and self.lastWarning[3] != where) then
        NebulaDriver:MySQLQuery("INSERT INTO warnings (player, description, origin, severity, hits) VALUES ('" .. self:SteamID() .. "', '" .. self.lastWarning[1] .. "', '" .. self.lastWarning[3] .. "', " .. self.lastWarning[2] .. ", " .. self.lastWarning[4] .. ")")
        self._warningData[self.lastWarning] = nil
    end

    if (self._warningData[where]) then
        self._warningData[where].hits = self._warningData[where].hits + 1
    else
        self._warningData[where] = {
            hits = severity,
            severity = severity,
        }
    end

    local stamp = self:SteamID64() .. "_cleanwarnings"
    timer.Create(stamp, WARNING_DECAY, 0, function()
        if (self._warningScore > 0) then
            self._warningScore = self._warningScore - 1
            if (self._warningScore == 0) then
                timer.Remove(stamp)
            end
        else
            timer.Remove(stamp)
        end
    end)

    self.lastWarning = {kind, severity, where, self._warningData[where].hits}

    timer.Create(self:SteamID64() .. "_writting_warnings", 30, 1, function()
        NebulaDriver:MySQLQuery("INSERT INTO warnings (player, description, origin, severity, hits) VALUES ('" .. self:SteamID() .. "', '" .. kind .. "', '" .. where .. "', " .. severity .. ", 1)")    
        self._warningData[where] = nil
    end)

    if (self._warningScore >= WARNING_KICK) then
        self:Kick("Disconnect: Client 0 overflowed reliable channel...")
    end
end
