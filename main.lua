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

local sqldb = startupLog("sqldb", function()
    local s = require("sqldb")
    _G.sqldb = s
    return s
end)

-------------------------------------------------------------------------------------------------------------

startupLog("enums", function()
    _G.discordia = discordia
    _G.client = client
end)

local commands = {}
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
        color = "<:color:1417880278294069359>"
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

-------------------------------------------------------------------------------------------------------------

local junkletters = { "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T",
    "U", "V", "W", "X", "Y", "Z" }
local junknums = { "1", "2", "3", "4", "5", "6", "7", "8", "9", "0" }

local function junkStr(len)
    local str = ""
    
    for i = 1, len do
        local letornum = math.random(1, 2)
        if letornum == 1 then
            local randomlet = junkletters[math.random(1, #junkletters)]
            local caporlow = math.random(1, 2)
            if caporlow == 1 then
                str = str .. randomlet
            else
                str = str .. randomlet:lower()
            end
        else
            local randomnum = junknums[math.random(1, #junknums)]
            str = str .. randomnum
        end
    end

    return str
end

_G.junkStr = junkStr

print(cc.green .. "[STARTUP]" .. cc.reset .. "- Initialized helper functions in " .. (os.clock() - startTime) .. " seconds.\n")

-------------------------------------------------------------------------------------------------------------

print(cc.cyan .. "[STARTUP]" .. cc.reset .. " - Initializing main functions...")
startTime = os.clock()

local function loadCommands(loadSlash, slashToLoad)

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

    return c, errors
end

-------------------------------------------------------------------------------------------------------------

local function onComp(msg, comptype, compid, userid, once, callback)
    if not msg then
        client:error("onComp | No message was provided")
        return
    elseif type(msg) ~= "table" then
        client:error("onComp | Message type is not table")
        return
    elseif (not msg.reply) then
        client:error("onComp | Message is not replyable")
        return
    elseif (not msg.channel) then
        client:error("onComp | Message does not contain a channel")
        return
    elseif (not msg.components) then
        client:error("onComp | Message does not contain components")
        return
    end

    coroutine.wrap(function()
        while true do
            local _, ia = msg:waitComponent(comptype, compid)
            local ui = userid or ia.user.id
            if ia.user.id == ui then
                local breakloop = coroutine.wrap(callback)(ia)
                if once or breakloop then
                    break
                end
            else
                ia:reply({
                    embed = {
                        description = emojis.fail .. " Only <@" .. userid .. "> can interact with this message!",
                        color = colors.fail
                    }
                }, true)
            end
        end
    end)()
end

_G.onComp = onComp

local function prompt(ia, title, questions, callback, defer)
    local newModalData = {}

    newModalData.title = title
    newModalData.id = _G.junkStr(25)

    local responseMap = {}
    
    for _, question in pairs(questions) do
        table.insert(newModalData, {
            id = _G.junkStr(25),
            label = question.question:sub(1,45),
            placeholder = question.placeholder:sub(1,100),
            style = question.style,
            required = question.required,
            value = question.default,
            min_length = question.min,
            max_length = question.max
        })

        responseMap[question.question] = ""
    end

    if not ia then return responseMap end

    local modal = discordia.Modal(newModalData)

    if not modal then return responseMap end

    ia:modal(modal)

    local _, mia = client:waitModal(newModalData.id, ia.user.id)

    if (not mia) then return end

    for _, componentObject in pairs((mia.data and mia.data.components) or {}) do
        if componentObject.components and componentObject.components[1] then
            local questionObject = nil
            
            for _, q in pairs(newModalData) do
                if (type(q) == "table") and (q.id == componentObject.components[1].custom_id) then
                    questionObject = q
                end
            end

            if questionObject then
                responseMap[questionObject.label] = componentObject.components[1].value

                if (questionObject.required == false) and ((not componentObject.components[1].value) or (componentObject.components[1].value == "")) then
                    responseMap[questionObject.label] = nil
                end
            end
        end
    end

    if defer then
        mia:updateDeferred(true)
    end

    return callback(mia, responseMap)
end

_G.prompt = prompt

-------------------------------------------------------------------------------------------------------------

local function embedBuilder(triggerMessage, initialState, callback, triggerInteraction)
    local components = discordia.Components()
    :selectMenu{
        id = "editproperty",
        placeholder = "Edit this message...",
        actionRow = 1,
        min_values = 0,
        max_values = 1,
        options = {
            {
                label = "Edit Title",
                value = "title",
                emoji = resolvedEmojis.text
            },
            {
                label = "Edit Description",
                value = "description",
                emoji = resolvedEmojis.text
            },
            {
                label = "Edit Author",
                value = "author",
                emoji = resolvedEmojis.text
            },
            {
                label = "Edit Footer",
                value = "footer",
                emoji = resolvedEmojis.text
            },
            {
                label = "Add Field",
                value = "add_field",
                emoji = resolvedEmojis.paragraph
            },
            {
                label = "Edit Field",
                value = "edit_field",
                emoji = resolvedEmojis.paragraph
            },
            {
                label = "Remove Field",
                value = "remove_field",
                emoji = resolvedEmojis.paragraph
            },
            {
                label = "Edit Thumbnail",
                value = "thumbnail",
                emoji = resolvedEmojis.image
            },
            {
                label = "Edit Banner",
                value = "banner",
                emoji = resolvedEmojis.image
            },
            {
                label = "Edit Color",
                value = "color",
                emoji = resolvedEmojis.color
            }
        }
    }
    :button{
        id = "embed_savebutton",
        label = "Save",
        emoji = resolvedEmojis.successWhite,
        style = "success"
    }

    local embed = initialState or {
        title = emojis.document .. " Embed Builder",
        description = "",
        color = colors.info,
        fields = {},
        footer = { text = "" },
        author = { name = "" },
        thumbnail = { url = "" },
        image = { url = "" }
    }

    local function safeUpdateLocal(state)
        embed = state
    end

    local eb = triggerInteraction:reply({
        embed = embed,
        components = components:raw()
    }, true)
    if not eb then return end

    local function updateEditor()
        if triggerInteraction.editReply then
            triggerInteraction:editReply({
                embed = embed,
                components = components:raw()
            }, eb.id)
        elseif eb.update then
            eb:update({
                embed = embed,
                components = components:raw()
            })
        end
    end

    onComp(eb, nil, nil, triggerInteraction.user.id, false, function(ia)
        local id = ia.data.custom_id
        local selected = ia.data.values and ia.data.values[1]

        if id == "editproperty" then
            if selected == "title" then
                prompt(ia, "Edit Title", {
                    {
                        question = "Title",
                        placeholder = "Enter embed title...",
                        style = "short",
                        default = embed.title,
                        required = true,
                        max = 256
                    }
                }, function(mia, responses)
                    embed.title = responses["Title"]
                    updateEditor()
                end, true)

            elseif selected == "description" then
                local defaultText = embed.description or ""
                if #defaultText < 1 then
                    defaultText = " "
                elseif #defaultText > 4000 then
                    defaultText = defaultText:sub(1, 4000)
                end

                prompt(ia, "Edit Description", {
                    {
                        question = "Description",
                        placeholder = "Enter embed description...",
                        style = "paragraph",
                        default = defaultText,
                        required = false,
                        max = 4000
                    }
                }, function(mia, responses)
                    embed.description = responses["Description"]
                    updateEditor()
                end, true)

            elseif selected == "author" then
                prompt(ia, "Edit Author", {
                    {
                        question = "Author Name",
                        placeholder = "The small text on the top of the embed.",
                        default = (embed.author and embed.author.name and #embed.author.name > 0) and embed.author.name or " ",
                        required = false,
                        max = 256
                    },
                    {
                        question = "Author Icon",
                        placeholder = "The image URL for the icon next to the author name.",
                        default = (embed.author and embed.author.icon_url and #embed.author.icon_url > 0) and embed.author.icon_url or " ",
                        required = false
                    }
                }, function(mia, responses)
                    if responses["Author Icon"] and not responses["Author Name"] then
                        responses["Author Icon"] = ""
                    end

                    embed.author = {
                        name = responses["Author Name"] or "",
                        icon_url = responses["Author Icon"] or ""
                    }

                    updateEditor()
                end, true)

            elseif selected == "footer" then
                prompt(ia, "Edit Footer", {
                    {
                        question = "Footer Text",
                        placeholder = "The small text on the bottom of the embed.",
                        default = (embed.footer and embed.footer.text and #embed.footer.text > 0) and embed.footer.text or " ",
                        required = false,
                        max = 256
                    },
                    {
                        question = "Footer Icon",
                        placeholder = "The image URL for the icon next to the footer text.",
                        default = (embed.footer and embed.footer.icon_url and #embed.footer.icon_url > 0) and embed.footer.icon_url or " ",
                        required = false,
                        max = 256
                    }
                }, function(mia, responses)
                    if responses["Footer Icon"] and not responses["Footer Text"] then
                        responses["Footer Icon"] = ""
                    end

                    embed.footer = {
                        text = responses["Footer Text"] or "",
                        icon_url = responses["Footer Icon"] or ""
                    }

                    updateEditor()
                end, true)

            elseif selected == "add_field" then
                prompt(ia, "Add Field", {
                    {
                        question = "Field Name",
                        placeholder = "Enter field title...",
                        style = "short",
                        required = true,
                        max = 256
                    },
                    {
                        question = "Field Value",
                        placeholder = "Enter field content...",
                        style = "paragraph",
                        required = true,
                        max = 1024
                    },
                    {
                        question = "Inline",
                        placeholder = "y/n",
                        style = "short",
                        required = false,
                        max = 1
                    }
                }, function(mia, responses)
                    table.insert(embed.fields, {
                        name = responses["Field Name"],
                        value = responses["Field Value"],
                        inline = (responses["Inline"] and responses["Inline"]:lower() == "y") or false
                    })
                    updateEditor()
                end, true)

            elseif selected == "edit_field" then
                if #embed.fields == 0 then
                    ia:reply("No fields to edit!", true)
                    return
                end

                local options = {}
                for i, field in ipairs(embed.fields) do
                    table.insert(options, {
                        label = field.name or ("Field " .. i),
                        value = tostring(i),
                        description = (field.value and #field.value > 50) and field.value:sub(1,50).."..." or field.value,
                        emoji = resolvedEmojis.edit
                    })
                end

                local menu = discordia.SelectMenu({
                    id = "editfield_" .. _G.junkStr(10),
                    placeholder = "Select a field to edit...",
                    actionRow = 1,
                    min_values = 1,
                    max_values = 1,
                    options = options
                })

                local r = ia:reply({
                    components = discordia.Components():selectMenu(menu):raw(),
                    ephemeral = true
                })

                onComp(r, nil, nil, ia.user.id, true, function(cia)
                    local idx = tonumber(cia.data.values and cia.data.values[1])
                    if idx and embed.fields[idx] then
                        local field = embed.fields[idx]
                        prompt(cia, "Edit Field", {
                            {
                                question = "Field Name",
                                placeholder = "Enter field title...",
                                style = "short",
                                default = field.name,
                                required = true,
                                max = 256
                            },
                            {
                                question = "Field Value",
                                placeholder = "Enter field content...",
                                style = "paragraph",
                                default = field.value,
                                required = true,
                                max = 1024
                            },
                            {
                                question = "Inline",
                                placeholder = "y/n",
                                style = "short",
                                required = false,
                                max = 1
                            }
                        }, function(mia2, responses)
                            embed.fields[idx] = {
                                name = responses["Field Name"],
                                value = responses["Field Value"],
                                inline = (responses["Inline"] and responses["Inline"]:lower() == "y") or false
                            }
                            updateEditor()
                            cia:deleteReply(r.id)
                        end, true)
                    end
                end)

            elseif selected == "remove_field" then
                if #embed.fields == 0 then
                    ia:reply("No fields to remove!", true)
                    return
                end

                local options = {}
                for i, field in ipairs(embed.fields) do
                    table.insert(options, {
                        label = field.name or ("Field " .. i),
                        value = tostring(i),
                        description = (field.value and #field.value > 50) and field.value:sub(1,50).."..." or field.value,
                        emoji = resolvedEmojis.delete
                    })
                end

                local menu = discordia.SelectMenu({
                    id = "removefield_" .. _G.junkStr(10),
                    placeholder = "Select a field to remove...",
                    actionRow = 1,
                    min_values = 1,
                    max_values = 1,
                    options = options
                })

                local r = ia:reply({
                    components = discordia.Components():selectMenu(menu):raw(),
                    ephemeral = true
                })

                onComp(r, nil, nil, ia.user.id, true, function(cia)
                    local idx = tonumber(cia.data.values and cia.data.values[1])
                    if idx and embed.fields[idx] then
                        table.remove(embed.fields, idx)
                        updateEditor()
                        cia:updateDeferred(true)
                        cia:deleteReply(r.id)
                    end
                end)

            elseif selected == "thumbnail" then
                prompt(ia, "Edit Thumbnail", {
                    {
                        question = "Thumbnail URL",
                        placeholder = "The image URL of the thumbnail.",
                        style = "short",
                        default = (embed.thumbnail and embed.thumbnail.url and #embed.thumbnail.url > 0) and embed.thumbnail.url or " ",
                        required = false,
                        max = 256
                    }
                }, function(mia, responses)
                    embed.thumbnail = { url = responses["Thumbnail URL"] or "" }
                    
                    updateEditor()
                end, true)
            
            elseif selected == "banner" then
                prompt(ia, "Edit Banner", {
                    {
                        question = "Banner URL",
                        placeholder = "The image URL of the banner.",
                        style = "short",
                        default = (embed.image and embed.image.url and #embed.image.url > 0) and embed.image.url or " ",
                        required = false,
                        max = 256
                    }
                }, function(mia, responses)
                    embed.image = { url = responses["Banner URL"] or ""}
                    
                    updateEditor()
                end, true)

            elseif selected == "color" then
                prompt(ia, "Edit Color", {
                    {
                        question = "Edit Color",
                        placeholder = "Enter a valid color hex code...",
                        default = ("#" .. embed.color) or " ",
                        style = "short",
                        required = false,
                        max = 8
                    }
                }, function(mia, responses)
                    embed.color = responses["Edit Color"] and
                                (colors[tostring(responses["Edit Color"])] or (discordia.Color.fromHex(responses["Edit Color"]) and discordia.Color.fromHex(responses["Edit Color"]).value))

                    updateEditor()
                end, true)
            end
        elseif id == "embed_savebutton" then
            ia:updateDeferred(true)
            ia:deleteReply(eb.id)
            if callback then
                callback(embed, true)
            end
        end
    end)
end

_G.embedBuilder = embedBuilder

local function messageBuilder(source, sendMessage)
    local isInteraction = source and source.reply and not source.content
    local messageEditorCops = discordia.Components()
        :selectMenu{
            id = "editproperty",
            placeholder = "Edit this message...",
            actionRow = 1,
            min_values = 0,
            max_values = 1,
            options = {
                {
                    label = "Edit Content",
                    value = "content",
                    emoji = resolvedEmojis.text
                },
                {
                    label = "Edit Embed",
                    value = "embed",
                    emoji = resolvedEmojis.document
                },
                {
                    label = "Edit Channel",
                    value = "channel",
                    emoji = resolvedEmojis.channel
                }
            }
        }
        :button{
            id = "message_savebutton",
            label = "Save",
            emoji = resolvedEmojis.successWhite,
            style = "success"
        }

    local messageState = {
        content = "Welcome to the " .. emojis.document .. " **Message Builder**. You can edit this message using the dropdown menu below. Once you are finished editing your message, click " .. emojis.successWhite .. " **Save**.",
        embed = nil,
        channelId = (source.channel and source.channel.id) or (source.channel_id)
    }

    local function updateDisplay(msg, state)
        local previewContent
        if (not state.content or state.content == "") and not state.embed then
            previewContent = " "
        else
            previewContent = state.content
        end

        msg:setContent(previewContent)
        msg:setEmbed(state.embed or nil)
    end

    local sentMessage
    if isInteraction then
        sentMessage = source:reply({
            content = messageState.content,
            components = messageEditorCops
        })
    else
        sentMessage = source:replyComponents({
            content = messageState.content,
            components = messageEditorCops
        })
    end

    onComp(sentMessage, nil, nil, source.author and source.author.id or source.user.id, false, function(ia)
        local id = ia.data.custom_id
        local selected = ia.data.values and ia.data.values[1]

        if id == "editproperty" then
            if selected == "content" then
                prompt(ia, "Message Builder", {
                    {
                        question = "Message Content",
                        placeholder = "Type your message content here...",
                        style = "paragraph",
                        default = messageState.content,
                        required = false,
                        max = 2000
                    }
                }, function(mia, responses)
                    local content = responses["Message Content"]
                    if content then
                        messageState.content = content
                        updateDisplay(sentMessage, messageState)
                    else
                        messageState.content = ""
                        updateDisplay(sentMessage, messageState)
                    end
                end, true)

            elseif selected == "channel" then
                local selectMenu = discordia.SelectMenu({
                    id = "channelselect_" .. _G.junkStr(10),
                    type = 8,
                    placeholder = "Select a channel...",
                    actionRow = 1,
                    min_values = 1,
                    max_values = 1
                })

                local r = ia:reply({
                    components = discordia.Components():selectMenu(selectMenu):raw(),
                    ephemeral = true
                })

                onComp(r, nil, nil, ia.user.id, true, function(cia)
                    local selectedChannelId = cia.data.values and cia.data.values[1]
                    if selectedChannelId then
                        messageState.channelId = selectedChannelId
                        ia:deleteReply(r.id)
                    else
                        cia:reply({
                            embed = {
                                description = emojis.fail .. " No channel selected.",
                                color = colors.fail
                            }
                        }, true)
                    end
                end)

            elseif selected == "embed" then
                ia:updateDeferred(true)
                embedBuilder(sentMessage, messageState.embed, function(newEmbedState, finalized)
                messageState.embed = newEmbedState
                updateDisplay(sentMessage, messageState)
                end, ia)
            end

        elseif id == "message_savebutton" then
            local channel = client:getChannel(messageState.channelId)
            if channel then
                ia:updateDeferred(true)

                if sendMessage then
                    if messageState.embed and next(messageState.embed) then
                        channel:send({
                            content = (messageState.content and #messageState.content > 0) and messageState.content or nil,
                            embed = messageState.embed
                        })
                    else
                        if messageState.content and #messageState.content > 0 then
                            channel:send(messageState.content)
                        else
                            ia:reply({
                                embed = {
                                    description = emojis.fail .. " Cannot send an empty message with no embed or content!",
                                    color = colors.fail
                                }
                            }, true)
                            return
                        end
                    end
                end

                sentMessage:delete()
            else
                ia:reply({
                    embed = {
                        description = emojis.fail .. " Selected channel is invalid!",
                        color = colors.fail
                    }
                }, true)
            end
        end
    end)

    return messageState
end

_G.messageBuilder = messageBuilder

-------------------------------------------------------------------------------------------------------------



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
        return member.id == "445152230132154380" or member.id == "995664658038005772"
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
    end
}

local function hasPerms(member, perm)
    local permFunction = perms[perm]
    if permFunction then
        return true
    else
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
        print(member.username .. " | " .. v .. " | " .. tostring(res))
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

print(cc.green .. "[STARTUP]" .. cc.reset .. " - Initialized main functions in " .. (os.clock() - startTime) .. " seconds.\n")

-------------------------------------------------------------------------------------------------------------

print(cc.cyan .. "[STARTUP]" .. cc.reset .. " - Initializing events...")
startTime = os.clock()

client:on("ready", function()
    loadCommands(false, nil)

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
    if interaction and interaction.id and interaction.guild and interaction.user and interaction.member and interaction.channel and command and command.name then
        local cmd = nil

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