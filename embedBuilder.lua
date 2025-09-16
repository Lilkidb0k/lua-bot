-- EmbedBuilder.lua
local EmbedBuilder = {}
EmbedBuilder.__index = EmbedBuilder

function EmbedBuilder.new()
    local self = setmetatable({}, EmbedBuilder)
    self.embed = {}
    return self
end

function EmbedBuilder:setTitle(title)
    self.embed.title = title
    return self
end

function EmbedBuilder:setDescription(desc)
    self.embed.description = desc
    return self
end

function EmbedBuilder:setColor(color)
    self.embed.color = color
    return self
end

function EmbedBuilder:addField(name, value, inline)
    if not self.embed.fields then
        self.embed.fields = {}
    end
    table.insert(self.embed.fields, {
        name = name,
        value = value,
        inline = inline or false
    })
    return self
end

function EmbedBuilder:setFooter(text, icon)
    self.embed.footer = { text = text, icon_url = icon }
    return self
end

function EmbedBuilder:setThumbnail(url)
    self.embed.thumbnail = { url = url }
    return self
end

function EmbedBuilder:setImage(url)
    self.embed.image = { url = url }
    return self
end

function EmbedBuilder:build()
    return self.embed
end

return EmbedBuilder
