-- ping.lua

local slashCommand = _G.tools.slashCommand("ping", "View the current uptime and status of the bot.")

local function percentageToColor(percentage)
    local r = math.floor(255 * (percentage / 400))
    local g = math.floor(255 * (1 - percentage / 400))
    local b = 0

    local color = string.format("#%02X%02X%02X", r, g, b)

    return color
end

return {
    name = "ping",
    description = "View the current uptime and status of the bot.",
    category = "Utility",
    slashCommand = slashCommand,
    hybridCallback = function(interaction, args)
        local r = interaction:reply({
            embed = { title = _G.emojis.loading, color = _G.colors.loading }
        })

        local responseTime = math.floor((((r and r.createdAt) or os.time()) - interaction.createdAt) * 100)

        local dbConnStatus

        if _G.dbConnection then
            dbConnStatus = "Connected"
        else
            dbConnStatus = "Not Connected"
        end

        local embed = {
            description = _G.emojis.right .. " **Response Time:** `" .. responseTime .. "ms`\n" .. _G.emojis.right .. " **Uptime:** <t:" .. _G.uptime .. ":R>\n" .. _G.emojis.right .. " **Database:** " .. dbConnStatus .. "\n" .. _G.emojis.right .. " **Shard:** " .. tostring(interaction.guild.shardId + 1) .. "/" .. (client.totalShardCount),
            color = (responseTime <= 200 and discordia.Color.fromHex(percentageToColor(responseTime)).value) or (colors.heavyred)
        }

        r:setEmbed(embed)
    end
}