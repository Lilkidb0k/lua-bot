-- setup.lua
local discordia = _G.discordia
local sqldb = _G.sqldb
local tools = _G.tools

local slashCommand = tools.slashCommand("setup", "Setup and configure to bot.")

local back_button = discordia.Button(
    {
        id = "back_button",
        style = "secondary",
        emoji = _G.resolvedEmojis.left
    }
)

local configuration_menu = discordia.SelectMenu(
    {
        id = "configuration_menu",
        placeholder = "Edit Configuration...",
        min_values = 0,
        max_values = 1,
        actionRow = 1,
        options = {
            {
                label = "Bot Settings",
                value = "bot_settings",
                emoji = _G.resolvedEmojis.wrench
            },
            {
                label = "Modules",
                value = "modules",
                emoji = _G.resolvedEmojis.module
            }
        }
    }
)

local bot_settings_menu = discordia.SelectMenu(
    {
        id = "bot_settings_menu",
        placeholder = "Edit Configuration...",
        min_values = 0,
        max_values = 1,
        actionRow = 1,
        options = {
            {
                label = "Edit Prefix",
                value = "edit_prefix",
                emoji = _G.resolvedEmojis.edit
            },
            {
                label = "Edit Disabled Commands",
                value = "edit_disabled_commands",
                emoji = _G.resolvedEmojis.edit
            }
        }
    }
)

return {
    name = "setup",
    description = "Setup and configure the bot.",
    slashCommand = slashCommand,
    requiredPermissions = { "MANAGE_SERVER" },
    hybridCallback = function(ctx, args, slash)

        local succ, config = sqldb:registerGuild(ctx.guild.id)
        if not succ then
            if slash then
                return ctx:reply({
                    embed = {
                        description = _G.emojis.fail ..
                            " Failed to initialize configuration for your server.",
                        color = _G.colors.fail
                    },
                    ephemeral = true
                })
            else
                return ctx:reply({
                    embed = {
                        description = _G.emojis.fail ..
                            " Failed to initialize configuration for your server.",
                        color = _G.colors.fail
                    }
                })
            end
        end

        local function getComps(pageName)
            if pageName == "config_menu" then
                return discordia.Components():selectMenu(configuration_menu):raw()
            elseif pageName == "bot_settings" then
                return discordia.Components({ bot_settings_menu, back_button }):raw()
            end
        end

        local function getEmbedDescription(pageName)
            if pageName == "config_menu" then
                return "## " .. _G.emojis.setting .. " Configuration Menu\n"
                    .. "> Welcome to the " .. _G.emojis.setting .. " **Configuration Menu**. To get started configurating the bot, select an option below."
            elseif pageName == "bot_settings" then
                return "## " .. _G.emojis.wrench .. " Bot Settings\n"
                    .. _G.emojis.right .. " Manage your bot’s prefix, disabled commands, and more.\n"
                    .. "### " .. _G.emojis.setting .. " Configurations\n"
                    .. _G.emojis.right .. " **Prefix:** `" .. (config.prefix or "!") .. "`\n"
                    .. _G.emojis.right .. " **Disabled Commands:** "
            end
        end

        local currentPage = "config_menu"
        local history = {}

        local function updatePage(ia, newPage)
            if currentPage and currentPage ~= newPage then
                table.insert(history, currentPage)
            end

            currentPage = newPage
            local updated = {
                embed = {
                    description = getEmbedDescription(newPage),
                    color = _G.colors.info
                },
                components = getComps(newPage)
            }

            if ia and ia.update then
                ia:update(updated)
            elseif slash then
                ctx:reply(updated)
            else
                ctx:replyComponents(updated)
            end
        end

        local function goBack(ia)
            local lastPage = table.remove(history)
            if lastPage then
                updatePage(ia, lastPage)
            else
                updatePage(ia, "config_menu")
            end
        end

        local msg
        if slash then
            msg = ctx:reply({
                embed = {
                    description = getEmbedDescription(currentPage),
                    color = _G.colors.info
                },
                components = getComps(currentPage)
            })
        else
            msg = ctx:replyComponents({
                embed = {
                    description = getEmbedDescription(currentPage),
                    color = _G.colors.info
                },
                components = getComps(currentPage)
            })
        end

        local ownerId = slash and ctx.user.id or ctx.author.id

        onComp(msg, nil, nil, ownerId, false, function(ia)
            if ia.data.custom_id == "back_button" then
                goBack(ia)

            elseif ia.data.custom_id == "configuration_menu" then
                local choice = ia.data.values and ia.data.values[1]
                if choice == "bot_settings" then
                    updatePage(ia, "bot_settings")
                end

            elseif ia.data.custom_id == "bot_settings_menu" then
                local choice = ia.data.values and ia.data.values[1]
                if choice == "edit_prefix" then
                    prompt(ia, "Edit Prefix", {
                        {
                            question = "Edit Prefix",
                            placeholder = "Enter new prefix...",
                            min = 1,
                            max = 5,
                        }
                    }, function(mia, responses)
                        config.prefix = responses["Edit Prefix"]
                        sqldb:set(ctx.guild.id, { prefix = config.prefix }, "EDIT_PREFIX_SETUP")

                        updatePage(mia, "bot_settings")
                    end, true)
                end
            end
        end)
    end
}