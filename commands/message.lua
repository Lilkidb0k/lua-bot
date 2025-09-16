return {
    name = "message",
    description = "Start the interactive message builder",
    callback = function(message, args)
        _G.messageBuilder(message)
    end
}
