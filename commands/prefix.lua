-- prefix.lua
local sqldb = _G.sqldb

return {
    name = "prefix",
    description = "View or change the prefix.",
    callback = function(message, args)
        local guildId = message.guild.id

        local succ, config = sqldb:registerGuild(guildId)

        if not succ or not config then
            return message:reply({
                embed = {
                    description = _G.emojis.fail .. " An error occurred when trying to configure your server, please try again later.",
                    color = _G.colors.fail
                }, ephemeral = true
            })
        end

        local prefix = config.prefix
        local newPrefix = args and args[1]

        if newPrefix then
            if newPrefix:len() > 5 then
                return message:reply({
                    embed = {
                        description = _G.emojis.fail .. " Prefixes can be set to a maximum of 5 characters in length.",
                        color = _G.colors.fail
                    }
                })
            else
                config.prefix = newPrefix
                sqldb:set(guildId, { prefix = config.prefix }, "EDIT_PREFIX")

                return message:reply({
                    embed = {
                        description = _G.emojis.success ..
                        " Set prefix to `" .. newPrefix .. "`.",
                        color = _G.colors.success
                    }
                })
            end
        else
            return message:reply({
                embed = {
                    description = "The current prefix is `" .. prefix .. "`.",
                    color = _G.colors.info
                }
            })
        end
    end
}