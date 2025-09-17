-- main.lua
local discordia = require("discordia")

-------------------------------------------------------------------------------------------------------------

local SECRETS = require("SECRETS")

-------------------------------------------------------------------------------------------------------------

local client = discordia.Client()

-------------------------------------------------------------------------------------------------------------

local fs = require("fs")

-------------------------------------------------------------------------------------------------------------

local dmodals = require("discordia-modals")
_G.dmodals = dmodals

-------------------------------------------------------------------------------------------------------------

require("discordia-components")

-------------------------------------------------------------------------------------------------------------

require("discordia-interactions")

-------------------------------------------------------------------------------------------------------------

local prefix = "!"

local commands = {}

-------------------------------------------------------------------------------------------------------------

_G.discordia = discordia
_G.client = client

-------------------------------------------------------------------------------------------------------------

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

for i, e in pairs(emojis) do
resolvedEmojis[i] = resolveEmoji(e)
end

_G.resolvedEmojis = resolvedEmojis
_G.resolveEmoji = resolveEmoji
_G.emojis = emojis
_G.colors = colors

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

-------------------------------------------------------------------------------------------------------------

local function loadCommands()

    local c = 0
    local cmdFolder = fs.readdirSync("./commands")
    local errors = {}

    for i, commandFileName in pairs(cmdFolder) do
        print("[CMDS] - Loading " .. commandFileName)
        local filestr, err = load(fs.readFileSync("commands/" .. commandFileName))
        if err then
            print("[CMDS] - Syntax error in " .. commandFileName .. " | " .. err)
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
                print("[CMDS] - Runtime error in " .. commandFileName .. " | " .. err)
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
                print("[CMDS] - Loaded " .. cmd.name .. " | " .. i .. "/" .. #cmdFolder)
            end
        end
    end

    _G.commands = commands
    _G.loadCommands = loadCommands

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

local function messageBuilder(message, sendMessage)
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
        channelId = message.channel.id
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

    local sentMessage = message:replyComponents({
        content = messageState.content,
        components = messageEditorCops
    })

    onComp(sentMessage, nil, nil, message.author.id, false, function(ia)
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

client:on("ready", function()
    loadCommands()

   print("Logged in as " .. client.user.username)
end)

-------------------------------------------------------------------------------------------------------------

client:on("messageCreate", function(message)
    if message.author.bot then return end

    local content = message.content:lower()
    if content:sub(1, #prefix) ~= prefix then return end
    
    local args = {}
    for word in content:sub(#prefix+1):gmatch("%S+") do
        table.insert(args, word)
    end

    local cmdName = table.remove(args, 1)
    local command = commands[cmdName]

    if command then
        command.callback(message, args)
    else
        return
    end
end)

-------------------------------------------------------------------------------------------------------------

client:run("Bot " .. SECRETS.token)