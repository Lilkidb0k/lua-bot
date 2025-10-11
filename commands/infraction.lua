-- infraction.lua
local tools = _G.tools

local slashCommand = tools.slashCommand("infraction", "Issue, revoke or manage an infraction.")
local subcmd = tools.subCommand("issue", "Issue an infraction.")
subcmd = subcmd:addOption(tools.user("user", "Who are you issuing the infraction towards?"):setRequired(true))
subcmd = subcmd:addOption(tools.string("type", "The infraction type."):setRequired(true):setAutocomplete(true))
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
    autocomplete = function(interaction, command, focused, args)
        local opts = {}

        if focused and focused.name == "type" then
            local config = sqldb:get(interaction.guild.id)
            local types = config
                and config.modules
                and config.modules.staff_management
                and config.modules.staff_management.infraction_types

            if types then
                for _, v in ipairs(types) do
                    if not focused.value or v:lower():find(focused.value:lower(), 1, true) then
                        table.insert(opts, {
                            name = v,
                            value = v
                        })
                    end
                end
            end
        end

        if #opts == 0 then
            opts = {
                { name = "No infraction types found", value = "none" }
            }
        end

        return interaction:autocomplete(opts)
    end,
    hybridCallback = function(interaction, args, slash, subcmd)
        local config = sqldb:get(interaction.guild.id) or {}

        if subcmd == "issue" then
            if not config.module.staff_management.infraction_channel then
                return interaction:fail("No infractions channel has been configurated.", nil, true)
            end

            if not config.module.staff_management.infraction_types then
                return interaction:fail("No infraction types has been configured.", nil, true)
            end

            local user = getMemberFromInteraction(interaction, args, slash)
            local type = (slash and args.type) or args and args[2]
            local reason = (slash and args.reason) or ((not slash) and table.remove(args, 1) and table.remove(args, 1) and table.concat(args, " "))


        end
    end
}
