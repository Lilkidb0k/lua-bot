-- setup.lua

local discordia = _G.discordia
local sqldb = _G.sqldb
local tools = _G.tools

local slashCommand = tools.slashCommand("setup", "Setup and configure to bot.")

return {
    name = "setup",
    description = "Setup and configure the bot.",
    slashCommand = slashCommand,
    requiredPermissions = { "MANAGE_SERVER "},
    hybridCallback = function(interaction, args)

        local succ, config = sqldb:registerGuild(interaction.guild.id)

        if not succ then
            return interaction:reply({
                embed = {
                    description = _G.emojis.fail .. " Failed to initialize configuration for your server.",
                    color = _G.colors.fail
                },
                ephemeral = true
            })
        end

        
    end
}