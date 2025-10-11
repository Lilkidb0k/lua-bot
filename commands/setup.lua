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
            },
            {
                label = "Edit Discord Manager Roles",
                value = "edit_discord_manager_roles",
                emoji = _G.resolvedEmojis.setting
            },
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
                return ctx:fail("Failed to initialize configuration for your server.", nil, true)
            else
                return ctx:fail("Failed to initialize configuration for your server.", nil, true)
            end
        end

        local allModules = {
            "staff_management",
            "discord_moderation",
        }

        config.modules = config.modules or {}
        for _, modName in ipairs(allModules) do
            if not config.modules[modName] then
                config.modules[modName] = { enabled = false }
            else
                config.modules[modName].enabled = config.modules[modName].enabled or false
            end
        end

        sqldb:set(ctx.guild.id, { modules = config.modules }, "AUTO_POPULATE_MODULES")

        local function getComps(pageName)
            if pageName == "config_page" then
                return discordia.Components():selectMenu(configuration_menu):raw()

            elseif pageName == "bot_settings_page" then
                return discordia.Components({ bot_settings_menu, back_button }):raw()

            elseif pageName == "permissions_page" then
                return discordia.Components({ permissions_menu, back_button}):raw()

            elseif pageName == "modules_page" then
                return discordia.Components({ modules_menu, back_button }):raw()

            elseif pageName == "staff_management_module_page" then
                return discordia.Components({ staff_management_module_menu, back_button }):raw()

            elseif pageName == "discord_moderation_module_page" then
                return discordia.Components({ discord_moderation_module_menu, back_button}):raw()
                
            else return {}
            end
        end

        local function getEmbedDescription(pageName)
            if pageName == "config_page" then
                return "## " .. _G.emojis.setting .. " Configuration Menu\n"

                    .. "> Welcome to the " .. _G.emojis.setting .. " **Configuration Menu**. To get started configurating the bot, select an option below."

            elseif pageName == "bot_settings_page" then
                local disabled = (config.disabledcommands and #config.disabledcommands > 0)
                and table.concat(config.disabledcommands, ", ")
                or "None"
                return "## " .. _G.emojis.wrench .. " Bot Settings\n"

                    .. _G.emojis.right .. " Manage your bot’s prefix, disabled commands, and more.\n"
                    
                    .. "### " .. _G.emojis.setting .. " Configurations\n"
                    .. _G.emojis.right .. " **Prefix:** `" .. (config.prefix or "!") .. "`\n"
                    .. _G.emojis.right .. " **Disabled Commands:** `" .. disabled .. "`"

            elseif pageName == "permissions_page" then

                local modRolesText = emojis.space .. _G.emojis.right .. " None"
                if config.discord_mod_roles and #config.discord_mod_roles > 0 then
                    local lines = {}
                    for _, roleId in ipairs(config.discord_mod_roles) do
                        table.insert(lines, emojis.space .. _G.emojis.right .. " <@&" .. roleId .. ">")
                    end
                    modRolesText = table.concat(lines, "\n")
                end

                local adminRolesText = emojis.space .. _G.emojis.right .. " None"
                if config.discord_admin_roles and #config.discord_admin_roles > 0 then
                    local lines = {}
                    for _, roleId in ipairs(config.discord_admin_roles) do
                        table.insert(lines, emojis.space .. _G.emojis.right .. " <@&" .. roleId .. ">")
                    end
                    adminRolesText = table.concat(lines, "\n")
                end

                local managerRolesText = emojis.space .. emojis.right .. " None"
                if config.discord_manager_roles and #config.discord_manager_roles > 0 then
                    local lines = {}
                    for _, roleId in ipairs(config.discord_manager_roles) do
                        table.insert(lines, emojis.space .. emojis.right .. " <@&" .. roleId .. ">")
                    end
                    managerRolesText = table.concat(lines, "\n")
                end

                return "## " .. _G.emojis.permission .. " Permissions\n"
                    .. _G.emojis.right .. " Configure and restrict various features to specific roles.\n\n"
                    .. "### " .. _G.emojis.setting .. " Configurations\n"

                    .. _G.emojis.right .. " **Discord Moderator Roles:**\n"
                    .. modRolesText .. "\n\n"

                    .. _G.emojis.right .. " **Discord Administrator Roles:**\n"
                    .. adminRolesText .. "\n\n"

                    .. emojis.right .. " **Discord Manager Roles:**\n"
                    .. managerRolesText .. "\n\n"

            elseif pageName == "modules_page" then
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
                    .. _G.emojis.right .. " **Infraction Types:**\n" .. emojis.space .. emojis.right .. table.concat(smConfig.infraction_types or {}, "\n" .. emojis.space .. emojis.right)

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

        local function extractPages()
            local pages = {}
            
            local getCompsSrc = string.dump(getComps)
            local getDescSrc = string.dump(getEmbedDescription)

            local function extractFromSource(src)
                local t = {}
                for page in string.gmatch(src, '([_%a]+_page)') do
                    t[page] = true
                end
                return t
            end

            local compsPages = extractFromSource(getCompsSrc)
            local descPages = extractFromSource(getDescSrc)

            for page in pairs(compsPages) do pages[page] = true end
            for page in pairs(descPages) do pages[page] = true end

            local arr = {}
            for p in pairs(pages) do table.insert(arr, p) end
            return arr
        end
        local pages = extractPages()

        local function findClosestPage(input)
            input = input:lower():gsub("%s+", "")
            local bestMatch, bestScore = "config_page", 0

            for _, page in ipairs(pages) do
                local normalizedPage = page:lower():gsub("_", "")
                if normalizedPage:match("^" .. input) then
                    return page
                end
                if normalizedPage:find(input, 1, true) then
                    local score = #input / #normalizedPage
                    if score > bestScore then
                        bestScore = score
                        bestMatch = page
                    end
                end
            end

            return bestMatch
        end

        local currentPage = (args and args ~= "" and args[1] and findClosestPage(args[1])) or "config_page"
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
                updatePage(ia, "config_page", true)
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
                    updatePage(ia, "bot_settings_page")

                elseif choice == "modules" then
                    updatePage(ia, "modules_page")

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

                        updatePage(mia, "bot_settings_page")
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
                        
                        updatePage(mia, "bot_settings_page")
                    end, true)
                end

-- [[ Permissions Menu ]] --
            elseif ia.data.custom_id == "permissions_menu" then
                local choice = ia.data.values and ia.data.values[1]

                if choice == "edit_discord_mod_roles" then
                    _G.roleSelect(ia, {
                        placeholder = "Select one or more moderator roles...",
                        min = 0,
                        max = 10,
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
                        max = 10,
                        defaults = config.discord_admin_roles
                    }, function(selected, cia)

                        config.discord_admin_roles = selected
                        sqldb:set(ia.guild.id, { discord_admin_roles = config.discord_admin_roles }, "EDIT_DISCORD_ADMIN_ROLES_SETUP")

                        updatePage(ia, "permissions_page")
                    end)

                elseif choice == "edit_discord_manager_roles" then
                    _G.roleSelect(ia, {
                        placeholder = "Select one or more manager roles...",
                        min = 0,
                        max = 10,
                        defaults = config.discord_manager_roles
                    }, function(selected, cia)

                        config.discord_manager_roles = selected
                        sqldb:set(ia.guild.id, { discord_manager_roles = config.discord_manager_roles }, "EDIT_DISCORD_MANAGER_ROLES_SETUP")

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
                        ["issuer.name"] = "The issuer's name.",
                        ["issuer.username"] = "The issuer's username.",
                        ["issuer.mention"] = "The issuer's mention.",
                        ["issuer.id"] = "The issuer's user ID.",
                        ["issuer.avatar"] = "The issuer's avatar URL.",

                        ["offender.name"] = "The offender's name.",
                        ["offender.username"] = "The offender's username.",
                        ["offender.mention"] = "The offender's mention.",
                        ["offender.id"] = "The offender's user ID.",
                        ["offender.avatar"] = "The offender's avatar URL",

                        ["infraction.type"] = "The infraction type.",
                        ["infraction.reason"] = "The infraction reason.",
                        ["infraction.notes"] = "The infraction notes.",
                        ["infraction.id"] = "The infraction ID.",

                        ["timestamp"] = "The Unix Epoch timestamp.",
                    }
                    _G.embedBuilder(ia, builtEmbed, function(finalEmbed, saved)
                        builtEmbed = finalEmbed
                        config.modules.staff_management.infraction_embed = builtEmbed
                        sqldb:set(ctx.guild.id, { modules = config.modules }, "EDIT_INFRACTION_EMBED_SETUP")
                        updatePage(ia, "staff_management_module_page")
                    end, ia, varList)

                elseif choice == "add_infraction_type" then
                    prompt(ia, "Infraction Type", {
                        {
                            question = "Add Infraction Type",
                            placeholder = "What should this infraction type be called?",
                            max = 50
                        },
                    }, function(mia, responses)
                        local newType = responses["Add Infraction Type"]
                        if not newType or newType:match("^%s*$") then
                            return mia:fail("Invalid infraction type.", nil, true)
                        end

                        config.modules.staff_management.infraction_types = config.modules.staff_management.infraction_types or {}

                        if not table.find(config.modules.staff_management.infraction_types, newType) then
                            table.insert(config.modules.staff_management.infraction_types, newType)
                            sqldb:set(ctx.guild.id, { modules = config.modules }, "ADD_INFRACTION_TYPE_SETUP")
                        else
                            mia:fail("This infraction type already exists.", nil, true)
                        end

                        updatePage(mia, "staff_management_module_page")
                    end)

                elseif choice == "edit_infraction_type" then
                    local types = config.modules.staff_management.infraction_types
                    if #types == 0 then return ia:fail("No infraction types to edit.", nil, true) end

                    local options = {}
                    for _, t in ipairs(types) do
                        table.insert(options, { label = t, value = t })
                    end

                    optionsSelect(ia, "Select Infraction Type to Edit", function(selected, cia)
                        if not selected then return cia:fail("No infraction type selected.", nil, true) end
                        
                        prompt(cia, "Rename Infraction Type", {
                            { question = "New Name", placeholder = "Enter new name...", max = 50 }
                        }, function(mia, responses)
                            local newName = responses["New Name"]
                            if not newName or newName:match("^%s*$") then
                                return mia:fail("Invalid name.", nil, true)
                            end

                            local idx = table.find(types, selected)
                            if idx then
                                mia:deferUpdate(true)
                                types[idx] = newName
                                sqldb:set(ctx.guild.id, { modules = config.modules }, "EDIT_INFRACTION_TYPE_SETUP")
                                updatePage(ia, "staff_management_module_page")
                            else
                                mia:fail("Failed to find the selected infraction type.", nil, true)
                            end
                        end)
                    end, true, options, 1, nil, true)

                elseif choice == "remove_infraction_type" then
                    local types = config.modules.staff_management.infraction_types
                    if #types == 0 then return ia:fail("No infraction types to remove.", nil, true) end

                    local options = {}
                    for _, t in ipairs(types) do
                        table.insert(options, { label = t, value = t })
                    end

                    optionsSelect(ia, "Select Infraction Type to Remove", function(selected, cia)
                        if not selected then return cia:fail("No infraction type selected.", nil, true) end

                        local idx = table.find(types, selected)
                        if idx then
                            table.remove(types, idx)
                            sqldb:set(ctx.guild.id, { modules = config.modules }, "REMOVE_INFRACTION_TYPE_SETUP")
                            updatePage(ia, "staff_management_module_page")
                        else
                            cia:fail("Failed to find the selected infraction type.", nil, true)
                        end
                    end, true, options, 1, nil, true)
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