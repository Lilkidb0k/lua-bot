return {
    name = "message",
    description = "Start the interactive message builder",
    aliases = { "msg" },
    callback = function(message, args)
        _G.messageBuilder(message, true)
    end
}
