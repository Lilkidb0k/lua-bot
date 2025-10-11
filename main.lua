-- main.lua
local startTime = 0
local totalStartTime = os.clock()

local cc = {
    reset = "\27[0m",
    red = "\27[31m",
    green = "\27[32m",
    yellow = "\27[33m",
    blue = "\27[34m",
    magenta = "\27[35m",
    cyan = "\27[36m",
    white = "\27[37m",
}
_G.cc = cc

local function startupLog(name, func, color)
    color = color or cc.cyan
    io.write(color .. "[STARTUP]" .. cc.reset .. " - Initializing " .. name .. "...\n")
    startTime = os.clock()
    local result
    if func then
        result = func()
    end
    io.write(cc.green .. "[STARTUP]" .. cc.reset .. " - Initialized " .. name .. " in " .. string.format("%.4f", os.clock() - startTime) .. " seconds.\n\n")
    return result
end

print(cc.yellow .. "\n[STARTUP]" .. cc.reset .. " - Initializing application...\n")

-------------------------------------------------------------------------------------------------------------

local discordia = startupLog("discordia", function()
    return require("discordia")
end)

local SECRETS = startupLog("SECRETS", function()
    local s = require("SECRETS")
    _G.SECRETS = s
    return s
end)

local dmodals = startupLog("discordia-modals", function()
    local d = require("discordia-modals")
    _G.dmodals = d
    return d
end)

startupLog("discordia-components", function()
    require("discordia-components")
end)

startupLog("discordia-interactions", function()
    require("discordia-interactions")
end)

local dslash = startupLog("discordia-slash", function()
    local ds = require("discordia-slash")
    _G.dslash = ds
    return ds
end)

local tools = startupLog("discordia-slash tools", function()
    local t = dslash.util.tools()
    _G.tools = t
    return t
end)

startupLog("discordia.extensions()", function()
    discordia.extensions()
end)

local client = startupLog("client", function()
    local c = discordia.Client()
    c:useApplicationCommands()
    _G.client = c
    return c
end)

local fs = startupLog("fs", function()
    local f = require("fs")
    _G.fs = f
    return f
end)

local json = startupLog("json", function()
    local j = require("json")
    _G.json = j
    return j
end)

local timer = startupLog("timer", function()
    local t = require("timer")
    _G.timer = t
    return t
end)

local sqlite3 = startupLog("sqlite3", function()
    local s = require("sqlite3")
    _G.sqlite3 = s
    return s
end)

local http = startupLog("coro-http", function()
    local http = require("coro-http")
    _G.http = http
    return http
end)

startupLog("sqldb", function()
    local sqldb = require("sqldb")
    _G.sqldb = sqldb
    return sqldb
end)

startupLog("db", function()
    local db = require("db")
    _G.db = db
    return db
end)
--[[
startupLog("snowflake", function()
    local snowflake = require("snowflake")
    _G.snowflake = snowflake
    return snowflake
end)
--]]
-------------------------------------------------------------------------------------------------------------

startupLog("enums", function()
    _G.discordia = discordia
    _G.client = client
    _G.uptime = os.time()
end)

local commands = {}
local modules = {}
-------------------------------------------------------------------------------------------------------------

local assets = startupLog("assets", function()
    local emojis = {
        success = "<:success:1417593854659399722>",
        fail = "<:fail:1417593871625486448>",
        warning = "<:warning:1417593882941591653>",
        error = "<:error:1417593896078282914>",
        right = "<:right:1417641757658710126>",
        left = "<:left:1417641781230567548>",
        loading = "<a:loading:1417641823928717342>",
        channel = "<:channel:1417641871827664987>",
        document = "<:document:1417641979977924728>",
        successWhite = "<:successWhite:1417643517802577980>",
        failWhite = "<:failWhite:1417643534500106240>",
        add = "<:Add:1417643700565180437>",
        remove = "<:Remove:1417643712468488395>",
        text = "<:text:1417805385217085480>",
        paragraph = "<:paragraph:1417800211509809252>",
        edit = "<:edit:1417800671876616252>",
        image = "<:image:1417800829498294402>",
        delete = "<:delete:1417877399495770312>",
        color = "<:color:1417880278294069359>",
        setting = "<:setting:1418649947158614079>",
        module = "<:module:1418651372773179484>",
        wrench = "<:wrench:1418662249953759254>",
        tools = "<:tools:1418904621316968570>",
        variable = "<:variable:1419056037926801610>",
        user = "<:user:1419375278458802409>",
        people = "<:people:1419375344955429006>",
        clock = "<:clock:1419375394343354389>",
        folder = "<:folder:1419375706537857024>",
        moderator = "<:moderator:1420044085330186280>",
        permission = "<:permission:1420081304879370330>",
        space = " "
    }

    local colors = {
        blank = 0x37373E,
        success = 0x66FF66,
        fail = 0xFF6666,
        info = 0x5C8FFF,
        warning = 0xFFC72B,
        heavyred = 0xB51A00,
        error = 0xB51A00,
        loading = 0xF5FF82,
        yellow = 0xF5FF82,
    }

    return {emojis = emojis, colors = colors}
end)

-------------------------------------------------------------------------------------------------------------

print(cc.cyan .. "[STARTUP]" .. cc.reset .. "- Initializing helper functions...")
startTime = os.clock()

local function split(inputstr, sep)
    if sep == nil then
        sep = "%s"
    end
    local t = {}
    for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
        table.insert(t, str)
    end
    return t
end

local function resolveEmoji(emojistr)
    if (not emojistr) or (type(emojistr) ~= "string") then return end
    local emojisplit = split(emojistr, ":")
    if ((not emojisplit) or (not emojisplit[1]) or (emojisplit[1] == "") or (not emojisplit[2]) or (emojisplit[2] == "") or (not emojisplit[3]) or (emojisplit[3] == "")) then return end
        local name = emojisplit[2]
        local id = emojisplit[3]:sub(1, emojisplit[3]:len() - 1)
        local animated = emojistr:sub(2, 2) == "a"

        local resolved = {
        name = tostring(name),
        id = tostring(id),
        animated = animated,
        hash = tostring(name) .. ":" .. tostring(id),
        image = "https://cdn.discordapp.com/emojis/" .. tostring(id),
        raw = tostring(emojistr),
    }
    if animated then
        resolved.hash = "a:" .. resolved.hash
        resolved.image = resolved.image .. ".gif"
    else
        resolved.image = resolved.image .. ".png"
    end

    return resolved
end

local resolvedEmojis = {}

for i, e in pairs(assets.emojis) do
resolvedEmojis[i] = resolveEmoji(e)
end

_G.resolvedEmojis = resolvedEmojis
_G.resolveEmoji = resolveEmoji
_G.emojis = assets.emojis
_G.colors = assets.colors


print(cc.green .. "[STARTUP]" .. cc.reset .. "- Initialized helper functions in " .. (os.clock() - startTime) .. " seconds.\n")

-------------------------------------------------------------------------------------------------------------

print(cc.cyan .. "[STARTUP]" .. cc.reset .. " - Initializing main functions...")
startTime = os.clock()

local function loadCommands(loadSlash, slashToLoad, loadModules)

    local c = 0
    local cmdFolder = fs.readdirSync("./commands")
    local errors = {}

    for i, commandFileName in pairs(cmdFolder) do
        print(cc.cyan .. "\n[CMDS]" .. cc.reset .. " - Loading " .. commandFileName)
        local filestr, err = load(fs.readFileSync("commands/" .. commandFileName))
        if err then
            print(cc.yellow .. "[CMDS]" .. cc.reset .. " - Syntax error in " .. commandFileName .. " | " .. err)
            table.insert(errors, {
                fileName = commandFileName,
                errorType = "Syntax",
                errorMessage = err
            })
        else
            local cmd = nil
            local success, err = pcall(function()
                cmd = filestr()
            end)
            if err then
                print(cc.red .. "[CMDS]" .. cc.reset .. " - Runtime error in " .. commandFileName .. " | " .. err)
                table.insert(errors, {
                    fileName = commandFileName,
                    errorType = "Runtime",
                    errorMessage = err
                })
            else
                commands[cmd.name:lower()] = cmd

                if cmd.aliases then
                    for _, alias in ipairs(cmd.aliases) do
                        commands[alias] = cmd
                    end
                end
                c = c + 1
                print(cc.green .. "[CMDS]" .. cc.reset .. " - Loaded " .. cmd.name .. " | " .. i .. "/" .. #cmdFolder)
            end
        end
    end

    _G.commands = commands
    _G.loadCommands = loadCommands

    if loadSlash then
        if slashToLoad then
            print(cc.cyan .. "\n[SLASH]" .. cc.reset .. " - Loading slash command | 1 to load")
            for i, command in pairs(commands) do
                if command.name:lower() == slashToLoad:lower() then
                    if command.slashCommand then
                        print(cc.cyan .. "\n[SLASH]" .. cc.reset .. " - Loading " .. command.name)
                        local s, e = client:createGlobalApplicationCommand(command.slashCommand)
                        if e then
                            print(cc.red .. "[SLASH]" .. cc.reset .. " - Failed to create application command /" .. command.name .. " | " .. e)
                        else
                            print(cc.green .. "[SLASH]" .. cc.reset .. " - Created application command - /" .. command.name)
                        end
                    else
                        print(cc.magenta .. "[SLASH]" .. cc.reset .. " - " .. command.name .. " does not support a Slash Command")
                    end
                end
            end
        else
            print(cc.cyan .. "\n[SLASH]" .. cc.reset .. " - Loading slash commands | " .. #commands .. " to load")
            for i, command in pairs(commands) do
                if command.slashCommand then
                    print(cc.cyan .. "\n[SLASH]" .. cc.reset .. " - Loading " .. command.name)
                    local s, e = client:createGlobalApplicationCommand(command.slashCommand)
                    if e then
                        print(cc.red .. "[SLASH]" .. cc.reset .. " - Failed to create application command /" .. command.name .. " | " .. e)
                    else
                        print(cc.green .. "[SLASH]" .. cc.reset .. " - Created application command - /" .. command.name)
                    end
                else
                    print(cc.magenta .. "[SLASH]" .. cc.reset .. " - " .. command.name .. " does not support a Slash Command")
                end
            end
        end
    end

    local modulesLoaded = 0
    local moduleErrors = {}
    if loadModules then
        local modFolder = fs.readdirSync("./modules")

        print("")

        for i, moduleFileName in pairs(modFolder) do
            print(cc.cyan .. "[MOD]" .. cc.reset .. " - Loading " .. moduleFileName)
            local fileStr, err = load(fs.readFileSync("modules/" .. moduleFileName))

            if err then
                print(cc.yellow .. "[MOD]" .. cc.reset .. " - Syntax error in " .. moduleFileName .. " | " .. err)
                table.insert(moduleErrors, { fileName = moduleFileName, errorType = "Syntax", errorMessage = err })
            else
                local mod
                local success, runtimeErr = pcall(function()
                    mod = fileStr()
                end)

                if not success or runtimeErr then
                    print(cc.red .. "[MOD]" .. cc.reset .. " - Runtime error in " .. moduleFileName .. " | " .. tostring(runtimeErr))
                    table.insert(moduleErrors, { fileName = moduleFileName, errorType = "Runtime", errorMessage = runtimeErr })
                else
                    modules[mod.name:lower()] = mod

                    if mod.Start and mod.enabled ~= false then
                        local ok, startErr = pcall(mod.Start)
                        if not ok then
                            print(cc.red .. "[MOD]" .. cc.reset .. " - Failed to start " .. mod.name .. " | " .. tostring(startErr))
                            table.insert(moduleErrors, { fileName = moduleFileName, errorType = "Startup", errorMessage = startErr })
                        else
                            print(cc.green .. "[MOD]" .. cc.reset .. " - Started module " .. mod.name .. " | " .. i .. "/" .. table.count(modules) .. "\n")
                        end
                    elseif mod.enabled == false then
                        print(cc.red .. "[MOD]" .. cc.reset .. " - " .. moduleFileName .. " is disabled" .. " | " .. i .. "/" .. table.count(modules))
                    else
                        print(cc.magenta .. "[MOD]" .. cc.reset .. " - " .. mod.name .. " has no Start()")
                    end

                    modulesLoaded = modulesLoaded + 1
                end
            end
        end

        _G.modules = modules
    end

    print(cc.cyan .. "\n[SUMMARY]" .. cc.reset ..
        "\nLoaded Commands: " .. c .. "/" .. #cmdFolder ..
        "\nLoaded Modules: " .. modulesLoaded .. "/" .. table.count(modules) ..
        "\nCommand Errors: " .. #errors ..
        "\nModule Errors: " .. #moduleErrors)

    return c, errors, modulesLoaded, moduleErrors
end

-------------------------------------------------------------------------------------------------------------

local function getCommand(query)
    for i, command in pairs(commands) do
        if command.name:lower() == query then
            return command
        end

        if command.aliases then
            for _, alias in pairs(command.aliases) do
                if alias:lower() == query then
                    return command
                end
            end
        end
    end

    return nil
end

-------------------------------------------------------------------------------------------------------------

local perms = {
    ["DEVELOPER"] = function(member)
        return member.id == "445152230132154380" or member.id == "995664658038005772" or member.id == "782235114858872854"
    end,

    ["MANAGE_SERVER"] = function(member)
        return member:hasPermission("manageGuild")
    end,

    ["SETUP"] = function(member)
        if sqldb:get(member.guild.id) then
            return true
        else
            return "NOT_SETUP"
        end
    end,

    ["DISCORD_MOD"] = function(member, config)
        config = config or sqldb:get(member.guild.id)

        if member:hasPermission("manageGuild") then
            return true
        end

        if not config then
            return false
        end

        if config then
            if config.discord_manager_roles then
				for _, managerRole in pairs(config.discord_manager_roles) do
					if member:hasRole(managerRole) then
						return true
					end
				end
			end

			if config.discord_admin_roles then
				for _, adminrole in pairs(config.discord_admin_roles) do
					if member:hasRole(adminrole) then
						return true
					end
				end
			end

			if config.discord_mod_roles then
				for _, modrole in pairs(config.discord_mod_roles) do
					if member:hasRole(modrole) then
						return true
					end
				end
			else
				return "You have not configured the **Discord Moderator** permission."
			end
		else
			return "You have not configured this server."
		end

		return "You are missing the **Discord Moderator** permission."
    end,

    ["DISCORD_ADMIN"] = function(member, config)
       config = config or sqldb:get(member.guild.id)
       
        if member:hasPermission("manageGuild") then return true end
        
        if not config then
            return false
        end

        if config then
            if config.discord_manager_roles then
				for _, managerRole in pairs(config.discord_manager_roles) do
					if member:hasRole(managerRole) then
						return true
					end
				end
			end

			if config.discord_admin_roles then
				for _, adminrole in pairs(config.discord_admin_roles) do
					if member:hasRole(adminrole) then
						return true
					end
				end
            else
                return "You have not configured the **Discord Administrator** permission."
			end
		else
			return "You have not configured this server."
		end

		return "You are missing the **Discord Administrator** permission."
    end,

    ["DISCORD_MANAGER"] = function(member, config)
       config = config or sqldb:get(member.guild.id)
       
        if member:hasPermission("manageGuild") then return true end
        
        if not config then
            return false
        end

        if config then
			if config.discord_manager_roles then
				for _, managerRole in pairs(config.discord_manager_roles) do
					if member:hasRole(managerRole) then
						return true
					end
				end
            else
                return "You have not configured the **Discord Manager** permission."
			end
		else
			return "You have not configured this server."
		end

		return "You are missing the **Discord Manager** permission."
    end
}

local function hasPerms(member, perm, config, interaction, message)
	local has = perms[perm]
	if has then
        local result = has(member, config)
        if result == true then
            return true
        else
            if interaction and message ~= false then
                --interaction:fail(message or result, nil, true)
            end

            return false
        end
	else
		client:error("Failed to find permission: " .. tostring(perm))
		return false
	end
end

_G.hasPerms = hasPerms

local function permFail(interaction, command, text)
    if type(command) == "string" then
        command = {
            name = command
        }
    end
    interaction:reply({
        embed = {
            description = emojis.fail .. " " .. text,
            color = colors.fail
        }
    }, true)
    return false
end

_G.permFail = permFail

local function parsePerms(interaction, command, member)
    if (not command.requiredPermissions) then
        return true
    end
    for _, v in pairs(command.requiredPermissions) do
        local perm = perms[v]
        if not perm then
            interaction:reply(emojis.warning .. " Unknown permission: `" .. tostring(v) .. "`")
            return
        end
        local res = perm(member)

        local ns = false

        if type(res) == "string" and res:sub(1, 9) == "NOT_SETUP" then
            ns = true
        end

        if v ~= "DEVELOPER" and v ~= "SETUP" and
            ns == false then
            if member:hasPermission("manageGuild") then
                print(v .. " | Bypassed by manageGuild")
                res = true
            end
        end
        print(member.username .. " | " .. command.name .. " | " .. v .. " | " .. tostring(res))
        local config = sqldb:get(interaction.guild.id) or {}
        if res == "NOT_SETUP" then
            return permFail(interaction, command, "The bot has not been setup! Run `/setup` to get started.")
        end

        if res == false then
            return permFail(interaction, command, "You do not have the `" .. v .. "` permission to use this command!")
        end
    end

    return true
end

-------------------------------------------------------------------------------------------------------------

local function isModuleEnabled(guildId, moduleName)
    local config = sqldb:get(guildId) or {}
    return config.modules
        and config.modules[moduleName]
        and config.modules[moduleName].enabled
end

_G.isModuleEnabled = isModuleEnabled

local function canRunCommand(interaction, command)
    if command.module then
        if not isModuleEnabled(interaction.guild.id, command.module) then
            return permFail(interaction, command,
                "The `" .. command.name .. "` command is part of the **" .. string.capitalize(command.module) .. "** module, " ..
                "which is currently disabled in this server."
            )
        end
    end

    return parsePerms(interaction, command, interaction.member)
end

_G.canRunCommand = canRunCommand

print(cc.green .. "[STARTUP]" .. cc.reset .. " - Initialized main functions in " .. (os.clock() - startTime) .. " seconds.\n")

-------------------------------------------------------------------------------------------------------------

print(cc.cyan .. "[STARTUP]" .. cc.reset .. " - Initializing events...")
startTime = os.clock()

client:on("ready", function()
    loadCommands(false, nil, true)

    print(cc.yellow .. "\n[STARTUP]" .. cc.reset .. " - Initialized application in " .. (os.clock() - totalStartTime) .. " seconds.\n")
end)

-------------------------------------------------------------------------------------------------------------

client:on("messageCreate", function(message)
    if message.author.bot then
        return
    end
    if (not message.guild) or (not message.member) or (not message.member.guild) then
        return
    end

    local config = sqldb:get(message.guild.id) or {}

    local prefix = config.prefix or "!"
    local mentionPrefix = message.content:sub(1,client.user.mentionString:len() + 1) == client.user.mentionString .. " "

    if (message.content:sub(1, prefix:len()):lower() ~= prefix:lower()) and (not mentionPrefix) then
        return
    end

    local args = {}

    if mentionPrefix then
        args = split(message.content:sub(client.user.mentionString:len() + 2), " ")
    else
        args = split(message.content:sub(prefix:len() + 1), " ")
    end

    local command = getCommand(args[1]:lower())

    if not command then
        return
    end

    if config then
        local disabledcommands = config.disabledcommands or {}
        local isDisabled = false
    
        for _, c in pairs(disabledcommands) do
            if c == command.name then
                isDisabled = true
                break
            end
        end
    
        if isDisabled then
            return message:reply({
                embed = {
                    description = _G.emojis.fail .. " This command has been disabled by server management",
                    color = _G.colors.fail
                }
            })
        end

        if command.module and not isModuleEnabled(message.guild.id, command.module) then
            return message:reply({
                embed = {
                    description = _G.emojis.fail .. "The `" .. command.name .. "` command is part of the **" .. string.capitalize(command.module) .. "** module, " ..
                "which is currently disabled in this server.",
                    color = _G.colors.fail
                }
            })
        end
    end

    table.remove(args, 1)

    local canuse = parsePerms(message, command, message.member)
    if not canuse then
        return
    end

    local cmdCb = (command.hybridCallback) or (command.callback)

    local subcmd = args and args[1]
    local s, e = pcall(cmdCb, message, args, nil, subcmd)
    if not s then
        return message:reply({
            embed = {
                description = emojis.error .. " An error occured while running this command.\n> -# " .. emojis.right .. " " .. e,
                color = _G.colors.error
            },
            ephemeral = true
        })
    end
end)

client:on("slashCommandAutocomplete", function(interaction, command, focused, args)
	if
		interaction
		and interaction.id
		and interaction.guild
		and interaction.user
		and interaction.member
		and interaction.channel
		and command
		and command.name
	then
		for i, v in pairs(commands) do
			if v.name:lower() == command.name:lower() then
				if v.autocomplete then
					coroutine.wrap(pcall)(v.autocomplete, interaction, command, focused, args)
				end
			end
		end
	end
end)

client:on("slashCommand", function(interaction, command, args)
    local cmd = nil

    for i, v in pairs(commands) do
        if v.name:lower() == command.name:lower() then
            cmd = v
        end
    end

    if not cmd then
        return
    end

    local config = sqldb:get(interaction.guild.id) or {}

    if config then
        local disabledcommands = config.disabledcommands or {}
        local isDisabled = false
    
        for _, c in pairs(disabledcommands) do
            if c == command.name then
                isDisabled = true
                break
            end
        end
    
        if isDisabled then
            return interaction:reply({
                embed = {
                    description = _G.emojis.fail .. " This command has been disabled by server management.",
                    color = _G.colors.fail
                },
                ephemeral = true
            })
        end
        
        if cmd.module and not isModuleEnabled(interaction.guild.id, cmd.module) then
            return interaction:reply({
                embed = {
                    description = _G.emojis.fail .. "The `" .. command.name .. "` command is part of the **" .. string.capitalize(command.module) .. "** module, " ..
                "which is currently disabled in this server.",
                    color = _G.colors.fail
                },
                ephemeral = true
            })
        end
    end

    local canuse = parsePerms(interaction, command, interaction.member)
    if not canuse then
        return
    end

    local cmdCb = (cmd.hybridCallback) or (cmd.slashCallback)

    local _, subcmd = tools.getSubCommand(command)
    local s, e = pcall(cmdCb, interaction, args, command, subcmd)
    if not s then
        return interaction:reply({
            embed = {
                description = emojis.error .. " An error occured while running that command.\n> -# " .. emojis.right .. " " .. e
            },
            ephemeral = true
        })
    end
    local _, subcmd = tools.getSubCommand(command)
    if not interaction.user then
        return print("UNLOGGED COMMAND | interaction.user is not available?")
    end
end)

print(cc.green .. "[STARTUP]" .. cc.reset .. "- Initialized events in " .. (os.clock() - startTime) .. " seconds.\n")

-------------------------------------------------------------------------------------------------------------

client:run("Bot " .. SECRETS.token)