-- db.lua
local db = {}

local discodia = _G.discordia
local client = _G.client
local sqldb = _G.sqldb

function db:case(member, moderator, actionType, reason, duration, guild)
    if not reason or reason == "" then
        reason = "No reason provided."
    end

    guild = guild or member.guild
    local config = sqldb:get(guild.id) or {}

    if not config.cases then
        config.cases = {}
    end

    local highestId = 0
    for _, case in pairs(config.cases) do
        if case.caseID > highestId then
            highestId = case.caseID
        end
    end
    local nextId = highestId + 1

    local caseData = {
        member = member.id,
        moderator = moderator.id,
        caseID = nextId,
        reason = reason,
        type = actionType,
        length = duration,
        timestamp = os.time(),
    }

    config.cases[nextId] = caseData
    local ok, updated = sqldb:set(guild.id, { cases = config.cases }, "NEW_CASE_ENTRY")
    config = updated or config

    return config.cases[nextId]
end

local function deepGet(tbl, path)
    local cur = tbl
    for key in string.gmatch(path, "[^%.]+") do
        if type(cur) ~= "table" then return nil end
        cur = cur[key]
    end
    return cur
end

function db:send(guild, keyPath, tosend)
    coroutine.wrap(function()
        local config = sqldb:get(guild.id)
        if not config then return end

        local channelId = deepGet(config, keyPath)
        if not channelId then return end

        local channel = guild:getChannel(channelId)
        if (not channel) or (not channel.send) then
            return
        end

        return channel:send(tosend)
    end)()
end

return db