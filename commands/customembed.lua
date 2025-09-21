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

local slashCommand = _G.tools.slashCommand("customembed", "Custom Embed Sigma")

return {
    name = "customembed",
    description = "Use embed editor to generate a custom embed",
    slashCommand = slashCommand,
    category = "Utility",
    hybridCallback = function(interaction, args)
        local builtEmbed = nil

        local r = interaction:reply({
            embed = {
                description = _G.emojis.right .. " Use the buttons below to configure your embed.",
                color = _G.colors.info
            },
            components = comps:raw()
        })

        onComp(r, "button", nil, interaction.user and interaction.user.id or interaction.author.id, false, function(ia)
            local id = ia.data.custom_id

            if id == "customize_embed" then
                _G.embedBuilder(r, builtEmbed, function(finalEmbed, saved)
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

                interaction.channel:send({
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