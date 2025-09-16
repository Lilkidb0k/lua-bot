local discordia = _G.discordia
local client = _G.client
local EmbedBuilder = require("./embedBuilder")

local activeEmbeds = {}

local command = {
    name = "embed",
    description = "Create your own discord embed!",
    callback = function(message, args)
        local builder = EmbedBuilder.new()
            :setTitle("Embed Title...")
            :setDescription("Embed Description...")
            :setFooter("Reply with changes like: title: Hello | description: Text | color: 0xFF0000 | done to finish")

        local sentMessage = message:reply({embed = builder:build()})

        activeEmbeds[message.author.id] = {
            builder = builder,
            targetMessage = sentMessage
        }
    end
}

client:on("messageCreate", function(msg)
    if msg.author.bot then return end

    local session = activeEmbeds[msg.author.id]
    if not session then return end

    if not msg.referencedMessage or msg.referencedMessage.id ~= session.targetMessage.id then
        return
    end

    local key, value = msg.content:match("^(%w+)%s*:%s*(.+)$")

    if msg.content:lower() == "done" then
        activeEmbeds[msg.author.id] = nil
        msg:reply("✅ Embed editing finished!")
        return
    end

    if not key then return end
    key = key:lower()

    if key == "title" then
        session.builder:setTitle(value)
    elseif key == "description" then
        session.builder:setDescription(value)
    elseif key == "color" then
        local number = tonumber(value)
        if not number and value:sub(1, 2) == "0x" then
            number = tonumber(value)
        end
        if number then
            session.builder:setColor(number)
        else
            msg:reply("Invalid color. Use a number or hex like `0xFF0000`.")
            return
        end
    elseif key == "field" then
        local name, val, inline = value:match("^(.-)%s*|%s*(.-)%s*|?%s*(true|false)?$")
        if name and val then
            inline = inline == "true"
            session.builder:addField(name, val, inline)
        else
            msg:reply("Use `field: Name | Value | inline?` format.")
            return
        end
    else
        msg:reply("Unknown key. Try `title: ...`, `description: ...`, `color: ...`, `field: Name | Value`, or `done`.")
        return
    end

    session.targetMessage:setEmbed(session.builder:build())
end)

return command