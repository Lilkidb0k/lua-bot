return {
    name = "infract",
    description = "Give an infraction to a user",
    module = "staff_management",
    callback = function(message, args)
        message:reply("Infraction given!")
    end
}
