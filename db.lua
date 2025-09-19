local db = {}

local discodia = _G.discordia
local client = _G.client
local sqldb = _G.sqldb

function db:infract(member, type, reason, issuer, notes)
    local guild = member.guild
    local config = sqldb:get(guild.id)
    if not config then
        return nil, "Could not find configuration for this guild."
    end
end