-- help.lua
local discordia = _G.discordia
local tools = _G.tools

local slashCommand = tools.slashCommand("help", "View all of the available commands.")

local back_button = discordia.Button({
    id = "back_button",
    style = "secondary",
    emoji = _G.resolvedEmojis.left
})

local option_menu = discordia.SelectMenu({
    id = "option_menu",
    placeholder = "Select an option...",
    min_values = 0,
    max_values = 1,
    actionRow = 1,
    options = {
        {
            label = "Category Commands",
            value = "category_option",
            emoji = _G.resolvedEmojis.folder
        },
        {
            label = "Module Commands",
            value = "module_option",
            emoji = _G.resolvedEmojis.module
        }
    }
})

local function toTitleCase(str)
    return str:gsub("_", " "):gsub("(%a)([%w_']*)", function(first, rest)
        return first:upper() .. rest:lower()
    end)
end

return {
    name = "help",
    description = "View all of the available commands.",
    aliases = { "cmds", "commands" },
    slashCommand = slashCommand,
    category = "Utility",
    hybridCallback = function(ctx, args, slash)

        local ownerId = slash and ctx.user.id or ctx.author.id

        local currentPage = "main_menu"
        local history = {}

        local seenModules, seenCategories = {}, {}
        local moduleOptions, categoryOptions = {}, {}

        for _, cmd in pairs(_G.commands) do
            if cmd.module then
                local mod = cmd.module:lower()
                if not seenModules[mod] then
                    seenModules[mod] = true
                    table.insert(moduleOptions, {
                        label = toTitleCase(cmd.module),
                        value = "module_" .. cmd.module,
                        emoji = _G.resolvedEmojis.module
                    })
                end
            end
            if cmd.category then
                local cat = cmd.category:lower()
                if not seenCategories[cat] then
                    seenCategories[cat] = true
                    table.insert(categoryOptions, {
                        label = toTitleCase(cmd.category),
                        value = "category_" .. cmd.category,
                        emoji = _G.resolvedEmojis.folder
                    })
                end
            end
        end

        if #moduleOptions == 0 then
            table.insert(moduleOptions, {
                label = "No modules found",
                value = "none_" .. _G.junkStr(15),
                description = "No commands are registered under modules.",
                emoji = _G.resolvedEmojis.warning
            })
        end

        if #categoryOptions == 0 then
            table.insert(categoryOptions, {
                label = "No categories found",
                value = "none_" .. _G.junkStr(15),
                description = "No commands are registered under categories.",
                emoji = _G.resolvedEmojis.warning
            })
        end

        local modules_menu = discordia.SelectMenu({
            id = "modules_menu",
            placeholder = "Select a module...",
            min_values = 0,
            max_values = 1,
            actionRow = 1,
            options = moduleOptions
        })

        local categories_menu = discordia.SelectMenu({
            id = "categories_menu",
            placeholder = "Select a category...",
            min_values = 0,
            max_values = 1,
            actionRow = 1,
            options = categoryOptions
        })

        local function getEmbedDescription(page)
            local prefix = _G.sqldb:get(ctx.guild.id).prefix
            local seenNames = {}

            if page == "main_menu" then
                return "## " .. _G.emojis.setting .. " Command List\n"
                    .. _G.emojis.right .. " Please select an option below."

            elseif page == "category_option" then
                return "## " .. _G.emojis.folder .. " Categories\n"
                    .. _G.emojis.right .. " Choose a category to view commands."

            elseif page == "module_option" then
                return "## " .. _G.emojis.module .. " Modules\n"
                    .. _G.emojis.right .. " Choose a module to view commands."

            elseif page:match("^category_") then
                local cat = page:gsub("^category_", "")
                local lines = { "## " .. _G.emojis.folder .. " " .. toTitleCase(cat) .. " Commands" }

                for _, cmd in pairs(_G.commands) do
                    if cmd.category and cmd.category:lower() == cat:lower() and not seenNames[cmd.name] then
                        seenNames[cmd.name] = true

                        local cmdDisplay = cmd.slashCommand
                            and ("**`/" .. cmd.name .. "`**")
                            or ("**`" .. prefix .. cmd.name .. "`**")

                        if cmd.aliases and #cmd.aliases > 0 then
                            local aliasStr = {}
                            for _, a in ipairs(cmd.aliases) do
                                table.insert(aliasStr, "`" .. prefix .. a .. "`")
                            end
                            cmdDisplay = cmdDisplay .. " *(" .. table.concat(aliasStr, ", ") .. ")*"
                        end

                        local description = cmd.description or "N/A"

                        if cmd.requiredPermissions and #cmd.requiredPermissions > 0 then
                            local perms = {}
                            for _, p in ipairs(cmd.requiredPermissions) do
                                table.insert(perms, "`" .. p .. "`")
                            end
                            description = description
                                .. "\n" .. emojis.space .. emojis.right .. " **Permissions:**"
                                .. "\n" .. emojis.space .. emojis.space .. emojis.right .. " " .. table.concat(perms, "\n" .. emojis.space .. emojis.space .. emojis.right .. " ")
                        end

                        if cmd.subcommands and #cmd.subcommands > 0 then
                            local subcmds = {}
                            for _, s in ipairs(cmd.subcommands) do
                                table.insert(subcmds, "`/" .. cmd.name .. " " .. s .. "`")
                            end
                            description = description
                                .. "\n" .. emojis.space .. emojis.right .. " **Subcommands:**"
                                .. "\n" .. emojis.space .. emojis.space .. emojis.right .. " " .. table.concat(subcmds, "\n" .. emojis.space .. emojis.space .. emojis.right .. " ")
                        end

                        table.insert(lines,
                            "\n" .. emojis.right .. " " .. cmdDisplay .. "\n"
                            .. emojis.space .. emojis.right .. " " .. description
                        )
                    end
                end
                return table.concat(lines, "\n")

            elseif page:match("^module_") then
                local mod = page:gsub("^module_", "")
                local lines = { "## " .. _G.emojis.module .. " " .. toTitleCase(mod) .. " Commands" }

                for _, cmd in pairs(_G.commands) do
                    if cmd.module and cmd.module:lower() == mod:lower() and not seenNames[cmd.name] then
                        seenNames[cmd.name] = true

                        local cmdDisplay = cmd.slashCommand
                            and ("**`/" .. cmd.name .. "`**")
                            or ("**`" .. prefix .. cmd.name .. "`**")

                        if cmd.aliases and #cmd.aliases > 0 then
                            local aliasStr = {}
                            for _, a in ipairs(cmd.aliases) do
                                table.insert(aliasStr, "`" .. prefix .. a .. "`")
                            end
                            cmdDisplay = cmdDisplay .. " *(" .. table.concat(aliasStr, ", ") .. ")*"
                        end

                        local description = cmd.description or "N/A"

                        if cmd.requiredPermissions and #cmd.requiredPermissions > 0 then
                            local perms = {}
                            for _, p in ipairs(cmd.requiredPermissions) do
                                table.insert(perms, "`" .. p .. "`")
                            end
                            description = description
                                .. "\n" .. emojis.space .. emojis.right .. " **Permissions:**"
                                .. "\n" .. emojis.space .. emojis.space .. emojis.right .. " " .. table.concat(perms, "\n" .. emojis.space .. emojis.space .. emojis.right .. " ")
                        end

                        if cmd.subcommands and #cmd.subcommands > 0 then
                            local subcmds = {}
                            for _, s in ipairs(cmd.subcommands) do
                                table.insert(subcmds, "`/" .. cmd.name .. " " .. s .. "`")
                            end
                            description = description
                                .. "\n" .. emojis.space .. emojis.right .. " **Subcommands:**"
                                .. "\n" .. emojis.space .. emojis.space .. emojis.right .. " " .. table.concat(subcmds, "\n" .. emojis.space .. emojis.space .. emojis.right .. " ")
                        end

                        table.insert(lines,
                            "\n" .. emojis.right .. " " .. cmdDisplay .. "\n"
                            .. emojis.space .. emojis.right .. " " .. description
                        )
                    end
                end
                return table.concat(lines, "\n")

            else
                return "*Unknown page.*"
            end
        end

        local function getComps(page)
            if page == "main_menu" then
                return discordia.Components({ option_menu }):raw()
            elseif page == "category_option" then
                return discordia.Components({ categories_menu, back_button }):raw()
            elseif page == "module_option" then
                return discordia.Components({ modules_menu, back_button }):raw()
            elseif page:match("^category_") or page:match("^module_") then
                return discordia.Components({ back_button }):raw()
            end
        end

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

        local r = ctx:reply({
            embed = {
                description = getEmbedDescription("main_menu"),
                color = _G.colors.info
            },
            components = getComps("main_menu")
        })

        onComp(r, nil, nil, ownerId, false, function(ia)
            local id = ia.data.custom_id

            if id == "back_button" then
                goBack(ia)
            elseif id == "option_menu" then
                local choice = ia.data.values[1]
                updatePage(ia, choice)
            elseif id == "categories_menu" then
                local choice = ia.data.values[1]
                if choice and not choice:match("^none_") then
                    updatePage(ia, choice)
                end
            elseif id == "modules_menu" then
                local choice = ia.data.values[1]
                if choice and not choice:match("^none_") then
                    updatePage(ia, choice)
                end
            end
        end)
    end
}