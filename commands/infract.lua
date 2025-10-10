return {
    name = "infract",
    description = "In development...",
    module = "staff_management",
    requiredPermissions = {"DISCORD_MOD"},
    category = "Utility",
    callback = function(message, args)
        message:reply("Infraction given!")
    end
}
