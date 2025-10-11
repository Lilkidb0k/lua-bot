local tools = _G.tools

local slashCommand = tools.slashCommand("infraction", "Issue, revoke or manage an infraction.")
local subcmd = tools.subCommand("issue", "Issue an infraction.")
subcmd = subcmd:addOption(tools.user("user", "Who are you issuing the infraction towards?"):setRequired(true))
subcmd = subcmd:addOption(tools.string("reason", "The infraction reason."):setRequired(true))
subcmd = subcmd:addOption(tools.string("notes", "The infraction notes."):setRequired(false))
slashCommand = slashCommand:addOption(subcmd)

return {
    name = "infraction",
    description = "Issue, revoke or manage an infraction.",
    module = "staff_management",
    requiredPermissions = {"DISCORD_MANAGER", "SETUP"},
    slashCommand = slashCommand,
    subcommands = {"issue"},
    category = "Utility",
    callback = function(interaction, args, slash, subcmd)
        interaction:reply("Infraction given!")
    end
}
