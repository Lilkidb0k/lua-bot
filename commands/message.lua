-- message.lua
local tools = _G.tools

local slashCommand = tools.slashCommand("message", "Use the message builder.")

return {
    name = "message",
    description = "Use the message builder.",
    aliases = { "msg" },
    slashCommand = slashCommand,
    category = "Utility",
    hybridCallback = function(interaction, args)
        _G.messageBuilder(interaction, true)
    end
}
