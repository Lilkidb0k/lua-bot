-- customembed.lua

local comps = discordia.Components()
:button{
    label = "Customize Embed",
    id = "customize_embed",
    style = "secondary"
}
:button{
    label = "Send",
    id = "send_button",
    style = "success"
}

return {
    name = "customembed",
    description = "Use embed editor to generate a custom embed",
    callback = function(message, args)
        local builtEmbed = nil

        local r = message:replyComponents({
            embed = {
                description = _G.emojis.right .. " Use the buttons below to configure your embed.",
                color = _G.colors.info
            },
            components = comps
        })

        onComp(r, "button", nil, message.author.id, false, function(ia)
            local id = ia.data.custom_id

            if id == "customize_embed" then
                -- open the embed builder
                _G.embedBuilder(r, builtEmbed, function(finalEmbed, saved)
                    -- store the final built embed when user clicks Save
                    builtEmbed = finalEmbed
                    r:setEmbed({
                            description = _G.emojis.right .. " Use the buttons below to configure your embed.\n\n" ..
                            _G.emojis.right .. " **Embed:** Custom",
                            color = _G.colors.info
                        })
                end, ia)

            elseif id == "send_button" then
                if not builtEmbed then
                    return ia:reply({
                        embed = {
                            description = _G.emojis.fail .. " You need to customize and save your embed first!",
                            color = _G.colors.fail
                        },
                        ephemeral = true
                    })
                end

                -- send the built embed
                message.channel:send({
                    embed = builtEmbed
                })

                ia:reply({
                    embed = {
                        description = _G.emojis.success .. " Embed sent!",
                        color = _G.colors.success
                    },
                    ephemeral = true
                })
            end
        end)
    end
}