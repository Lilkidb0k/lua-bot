-- setup.lua
local discordia = _G.discordia
local sqldb = _G.sqldb
local tools = _G.tools

local slashCommand = tools.slashCommand("setup", "Setup and configure to bot.")

-------------------------------------------------------------------------------------------------------------

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
                label = "Permissions",
                value = "role_permissions",
                emoji = _G.resolvedEmojis.permission
            },
            {
                label = "Modules",
                value = "modules",
                emoji = _G.resolvedEmojis.module
            }
        }
    }
)

-------------------------------------------------------------------------------------------------------------

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

local permissions_menu = discordia.SelectMenu(
    {
        id = "permissions_menu",
        placeholder = "Select a permission...",
        min_values = 1,
        max_values = 1,
        actionRow = 1,
        options = {
            {
                label = "Edit Discord Moderator Roles",
                value = "edit_discord_mod_roles",
                emoji = _G.resolvedEmojis.moderator
            },
            {
                label = "Edit Discord Administrator Roles",
                value = "edit_discord_admin_roles",
                emoji = _G.resolvedEmojis.tools
            }
        }
    }
)

local modules_menu = discordia.SelectMenu(
    {
        id = "modules_menu",
        placeholder = "Select a module...",
        min_values = 0,
        max_values = 1,
        actionRow = 1,
        options = {
            {
                label = "Staff Management",
                value = "staff_management_module",
                emoji = _G.resolvedEmojis.tools
            },
            {
                label = "Discord Moderation",
                value = "discord_moderation_module",
                emoji = _G.resolvedEmojis.moderator
            }
        }
    }
)

-------------------------------------------------------------------------------------------------------------

local staff_management_module_menu = discordia.SelectMenu(
    {
        id = "staff_management_module_menu",
        placeholder = "Edit Configuration...",
        min_values = 0,
        max_values = 1,
        actionRow = 1,
        options = {
            {
                label = "Toggle Module",
                value = "toggle_staff_management_module",
                emoji = _G.resolvedEmojis.module
            },
            {
                label = "Edit Infraction Embed",
                value = "edit_infraction_embed",
                emoji = _G.resolvedEmojis.edit
            },
            {
                label = "Edit Infraction Channel",
                value = "edit_infraction_channel",
                emoji = _G.resolvedEmojis.channel
            },
            {
                label = "Add Infraction Type",
                value = "add_infraction_type",
                emoji = _G.resolvedEmojis.add
            },
            {
                label = "Edit Infraction Type",
                value = "edit_infraction_type",
                emoji = _G.resolvedEmojis.edit
            },
            {
                label = "Remove Infraction Type",
                value = "remove_infraction_type",
                emoji = _G.resolvedEmojis.delete
            }
        }
    }
)

local discord_moderation_module_menu = discordia.SelectMenu(
    {
        id = "discord_moderation_module_menu",
        placeholder = "Edit Configuration...",
        min_values = 0,
        max_values = 1,
        actionRow = 1,
        options = {
            {
                label = "Toggle Module",
                value = "toggle_discord_moderation_module",
                emoji = _G.resolvedEmojis.module
            },
            {
                label = "Edit Moderation Logs Channel",
                value = "edit_moderation_logs_channel",
                emoji = _G.resolvedEmojis.channel
            }
        }
    }
)

-------------------------------------------------------------------------------------------------------------

return {
    name = "setup",
    description = "Setup and configure the bot.",
    slashCommand = slashCommand,
    requiredPermissions = { "MANAGE_SERVER" },
    category = "Configuration",
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

            elseif pageName == "permissions_page" then
                return discordia.Components({ permissions_menu, back_button}):raw()

            elseif pageName == "modules_menu" then
                return discordia.Components({ modules_menu, back_button }):raw()

            elseif pageName == "staff_management_module_page" then
                return discordia.Components({ staff_management_module_menu, back_button }):raw()

            elseif pageName == "discord_moderation_module_page" then
                return discordia.Components({ discord_moderation_module_menu, back_button}):raw()
            end
        end

        local function getEmbedDescription(pageName)
            if pageName == "config_menu" then
                return "## " .. _G.emojis.setting .. " Configuration Menu\n"

                    .. "> Welcome to the " .. _G.emojis.setting .. " **Configuration Menu**. To get started configurating the bot, select an option below."

            elseif pageName == "bot_settings" then
                local disabled = (config.disabledcommands and #config.disabledcommands > 0)
                and table.concat(config.disabledcommands, ", ")
                or "None"
                return "## " .. _G.emojis.wrench .. " Bot Settings\n"

                    .. _G.emojis.right .. " Manage your bot’s prefix, disabled commands, and more.\n"
                    
                    .. "### " .. _G.emojis.setting .. " Configurations\n"
                    .. _G.emojis.right .. " **Prefix:** `" .. (config.prefix or "!") .. "`\n"
                    .. _G.emojis.right .. " **Disabled Commands:** `" .. disabled .. "`"

            elseif pageName == "permissions_page" then
                local NBSP = "\194\160"
                local indent = string.rep(NBSP, 2)

                local modRolesText = indent .. _G.emojis.right .. " None"
                if config.discord_mod_roles and #config.discord_mod_roles > 0 then
                    local lines = {}
                    for _, roleId in ipairs(config.discord_mod_roles) do
                        table.insert(lines, indent .. _G.emojis.right .. " <@&" .. roleId .. ">")
                    end
                    modRolesText = table.concat(lines, "\n")
                end

                local adminRolesText = indent .. _G.emojis.right .. " None"
                if config.discord_admin_roles and #config.discord_admin_roles > 0 then
                    local lines = {}
                    for _, roleId in ipairs(config.discord_admin_roles) do
                        table.insert(lines, indent .. _G.emojis.right .. " <@&" .. roleId .. ">")
                    end
                    adminRolesText = table.concat(lines, "\n")
                end

                return "## " .. _G.emojis.permission .. " Bot Settings\n"
                    .. _G.emojis.right .. " Configure and restrict various features to specific roles.\n\n"
                    .. "### " .. _G.emojis.setting .. " Configurations\n"

                    .. _G.emojis.right .. " **Discord Moderator Roles:**\n"
                    .. modRolesText .. "\n\n"

                    .. _G.emojis.right .. " **Discord Administrator Roles:**\n"
                    .. adminRolesText .. "\n\n"

            elseif pageName == "modules_menu" then
                return "## " .. _G.emojis.module .. " Modules\n"
                    .. _G.emojis.right .. " Select a module below to toggle and configure."

            elseif pageName == "staff_management_module_page" then
                local smConfig = config.modules and config.modules.staff_management or {}
                local infractionChannel = smConfig.infraction_channel and client:getChannel(smConfig.infraction_channel).mentionString or "N/A"
                local infractionEmbed = smConfig.infraction_embed and "Custom" or "N/A"

                return "## " .. _G.emojis.tools .. " Staff Management\n"
                    .. _G.emojis.right .. " Manage your staff.\n"
                    .. "### " .. _G.emojis.setting .. " Configurations\n"
                    .. _G.emojis.right .. " **Module Enabled:** " .. (smConfig.enabled and _G.emojis.success or _G.emojis.fail) .. "\n"
                    .. _G.emojis.right .. " **Infraction Channel:** " .. infractionChannel .. "\n"
                    .. _G.emojis.right .. " **Infraction Embed:** " .. infractionEmbed .. "\n"

            elseif pageName == "discord_moderation_module_page" then
                local dmConfig = config.modules and config.modules.discord_moderation or {}
                local modlogsChannel = dmConfig.moderation_logs_channel and client:getChannel(dmConfig.moderation_logs_channel).mentionString or "N/A"

                return "## " .. _G.emojis.moderator .. " Discord Moderation\n"
                    .. _G.emojis.right .. " Moderate your discord server with ease.\n"
                    .. "### " .. _G.emojis.setting .. " Configurations\n"
                    .. _G.emojis.right .. " **Module Enabled:** " .. (dmConfig.enabled and _G.emojis.success or _G.emojis.fail) .. "\n"
                    .. _G.emojis.right .. " **Moderation Logs Channel:** " .. modlogsChannel .. "\n"
            end
        end

        local currentPage = "config_menu"
        local history = {}

        local function updatePage(ia, newPage, fromBack)
            if not fromBack and currentPage and currentPage ~= newPage then
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
                updatePage(ia, lastPage, true)
            else
                updatePage(ia, "main_menu", true)
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
                components = getComps(currentPage),
                reference = {
                    message = ctx.id
                }
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

                elseif choice == "modules" then
                    updatePage(ia, "modules_menu")

                elseif choice == "role_permissions" then
                    updatePage(ia, "permissions_page")
                end

-- [[ Bot Settings Configuration menu ]] --
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

                elseif choice == "edit_disabled_commands" then
                    prompt(ia, "Edit Disabled Commands", {
                        {
                            question = "Disabled Commands",
                            placeholder = "Enter commands separated by commas...",
                            style = "paragraph",
                            default = (config.disabledcommands and #config.disabledcommands > 0) and table.concat(config.disabledcommands, ",") or " ",
                            required = false,
                        }
                    }, function(mia, responses)
                        local input = responses["Disabled Commands"] or ""
                        local commands = {}
                        
                        for cmd in string.gmatch(input, '([^,%s]+)') do
                            if cmd == "setup" then
                                return mia:reply({
                                    embed = {
                                        description = _G.emojis.fail .. " You cannot disable to `/setup` command.",
                                        color = _G.colors.fail
                                    },
                                    ephemeral = true
                                })
                            end
                            table.insert(commands, cmd)
                        end
                        
                        config.disabledcommands = commands
                        sqldb:set(ctx.guild.id, { disabledcommands = config.disabledcommands }, "EDIT_DISABLED_COMMANDS_SETUP")
                        
                        updatePage(mia, "bot_settings")
                    end, true)
                end

-- [[ Permissions Menu ]] --
            elseif ia.data.custom_id == "permissions_menu" then
                local choice = ia.data.values and ia.data.values[1]

                if choice == "edit_discord_mod_roles" then
                    _G.roleSelect(ia, {
                        placeholder = "Select one or more moderator roles...",
                        min = 0,
                        max = 5,
                        defaults = config.discord_mod_roles
                    }, function(selected, cia)

                        config.discord_mod_roles = selected
                        sqldb:set(ia.guild.id, { discord_mod_roles = config.discord_mod_roles }, "EDIT_DISCORD_MOD_ROLES_SETUP")

                        updatePage(ia, "permissions_page")
                    end)

                elseif choice == "edit_discord_admin_roles" then
                    _G.roleSelect(ia, {
                        placeholder = "Select one or more administrator roles...",
                        min = 0,
                        max = 5,
                        defaults = config.discord_admin_roles
                    }, function(selected, cia)

                        config.discord_admin_roles = selected
                        sqldb:set(ia.guild.id, { discord_admin_roles = config.discord_admin_roles }, "EDIT_DISCORD_ADMIN_ROLES_SETUP")

                        updatePage(ia, "permissions_page")
                    end)
                end

-- [[ Modules Menu ]] --
            elseif ia.data.custom_id == "modules_menu" then
                local choice = ia.data.values and ia.data.values[1]
                if choice == "staff_management_module" then
                    updatePage(ia, "staff_management_module_page")
                elseif choice == "discord_moderation_module" then
                    updatePage(ia, "discord_moderation_module_page")
                end

-- [[ Staff Management Module Menu ]] -- 
            elseif ia.data.custom_id == "staff_management_module_menu" then
                local choice = ia.data.values and ia.data.values[1]

                if choice == "toggle_staff_management_module" then
                    local current = config.modules.staff_management.enabled or false
                    config.modules.staff_management.enabled = not current

                    sqldb:set(ctx.guild.id, { modules = config.modules }, "TOGGLE_STAFF_MANAGEMENT_MODULE_SETUP")

                    updatePage(ia, "staff_management_module_page")

                elseif choice == "edit_infraction_channel" then
                    _G.channelSelect(ia, {
                        placeholder = "Select a channel...",
                        min = 0,
                        max = 1,
                        defaults = config.modules.staff_management.infraction_channel
                    }, function(selectedChannels)
                        local selectedChannelId = selectedChannels[1]

                        if selectedChannelId then
                            config.modules.staff_management.infraction_channel = selectedChannelId
                        else
                            config.modules.staff_management.infraction_channel = nil
                        end

                        sqldb:set(ctx.guild.id, { modules = config.modules }, "EDIT_INFRACTION_CHANNEL_SETUP")
                        updatePage(ia, "staff_management_module_page")
                    end)

                elseif choice == "edit_infraction_embed" then
                    local builtEmbed = config.modules.staff_management.infraction_embed or nil

                    local varList = {
                        issuer_name = "The name of the user who issued the infraction.",
                        server_name = "The name of the server.",
                        server_id = "The ID of the server.",
                    }
                    _G.embedBuilder(ia, builtEmbed, function(finalEmbed, saved)
                        builtEmbed = finalEmbed
                        config.modules.staff_management.infraction_embed = builtEmbed
                        sqldb:set(ctx.guild.id, { modules = config.modules }, "EDIT_INFRACTION_EMBED_SETUP")
                        updatePage(ia, "staff_management_module_page")
                    end, ia)
                end

-- [[ Discord Moderation ]] --
            elseif ia.data.custom_id == "discord_moderation_module_menu" then
                local choice = ia.data.values and ia.data.values[1]

                if choice == "toggle_discord_moderation_module" then
                    local current = config.modules.discord_moderation.enabled or false
                    config.modules.discord_moderation.enabled = not current

                    sqldb:set(ctx.guild.id, { modules = config.modules }, "TOGGLE_DISCORD_MODERATION_MODULE_SETUP")

                    updatePage(ia, "discord_moderation_module_page")

                elseif choice == "edit_moderation_logs_channel" then
                    _G.channelSelect(ia, {
                        placeholder = "Select a channel...",
                        min = 0,
                        max = 1,
                        defaults = config.modules.discord_moderation.moderation_logs_channel
                    }, function(selectedChannels)
                        local selectedChannelId = selectedChannels[1]

                        if selectedChannelId then
                            config.modules.discord_moderation.moderation_logs_channel = selectedChannelId
                        else
                            config.modules.discord_moderation.moderation_logs_channel = nil
                        end

                        sqldb:set(ctx.guild.id, { modules = config.modules }, "EDIT_MODERATION_LOGS_CHANNEL_SETUP")
                        updatePage(ia, "discord_moderation_module_page")
                    end)
                end
            end
        end)
    end
}