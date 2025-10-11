local utils = {
    name = "utils",
    description = "Storage for global utility functionsso updates can occur without having to reboot!"
}

local startTime = os.clock()

utils.Start = function()
    print(cc.cyan .. "[UTILS]" .. cc.reset .. "- Initializing utility functions...")
    startTime = os.clock()

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

    local function paginate(interaction, pages, user, options)
        options = options or {}
        local pageIndex = options.startPage or 1
        local showTotalPages = options.showTotalPages
        local msg

        local function buildComponents()
            local currentPage = pages[pageIndex]
            local comps = discordia.Components()
            comps:button({ id = "previous", emoji = resolvedEmojis.left, style = "secondary" })

            local teleportLabel
            if currentPage.title then
                teleportLabel = currentPage.title
                if showTotalPages then
                    teleportLabel = teleportLabel .. " (" .. pageIndex .. "/" .. #pages .. ")"
                end
            else
                teleportLabel = showTotalPages and (pageIndex .. "/" .. #pages) or (pageIndex)
            end

            comps:button({
                id = "teleporter",
                label = teleportLabel,
                emoji = currentPage.emoji,
                style = "secondary"
            })

            comps:button({ id = "next", emoji = resolvedEmojis.right, style = "secondary" })
            return comps:raw()
        end

        msg = interaction:reply({
            embed = pages[pageIndex],
            components = buildComponents()
        }, false)

        local function update()
            local currentPage = pages[pageIndex]
            local success, err = msg:update({
                embed = currentPage,
                components = buildComponents()
            })
            if not success then
                print("Failed to update pagination:", err)
            end
        end

        onComp(msg, nil, nil, user.id, false, function(ia)
            local id = ia.data.custom_id
            if id == "previous" then
                pageIndex = pageIndex - 1
                if pageIndex < 1 then pageIndex = #pages end
                ia:updateDeferred(true)
                update()

            elseif id == "next" then
                pageIndex = pageIndex + 1
                if pageIndex > #pages then pageIndex = 1 end
                ia:updateDeferred(true)
                update()

            elseif id == "teleporter" then
                local optionsList = {}
                for i, page in ipairs(pages) do
                    table.insert(optionsList, {
                        label = page.title or ("Page " .. i),
                        value = tostring(i),
                        emoji = page.emoji
                    })
                end

                local menu = ia:reply({
                    components = discordia.Components():selectMenu({
                        id = "pageselect",
                        placeholder = "Select a page...",
                        options = optionsList
                    }):raw()
                }, true)

                onComp(menu, nil, nil, ia.user.id, false, function(tia)
                    local first = tia.data.values and tia.data.values[1]
                    if first then
                        pageIndex = tonumber(first)
                        tia:updateDeferred(true)
                        ia:deleteReply(menu.id)
                        update()
                    end
                end)
            end
        end)
    end

    _G.paginate = paginate

    -------------------------------------------------------------------------------------------------------------

    local function embedBuilder(triggerMessage, initialState, callback, triggerInteraction, variableList)
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
        :button{
            id = "embed_variable_list",
            label = "Variables",
            emoji = resolvedEmojis.variable,
            style = "secondary"
        }

        local embed = initialState or {
            title = emojis.document .. " Embed Builder",
            description = emojis.right .. " Welcome to the " .. emojis.document .. " **Embed Editor**. Use the dropdown menu below to customize your embed, once you are done click " .. emojis.successWhite .. " **Save**.",
            color = colors.info,
            fields = {},
            footer = { text = "" },
            author = { name = "" },
            thumbnail = { url = "" },
            image = { url = "" }
        }

        local function formatVariables(varTable)
            if not varTable or next(varTable) == nil then
                return emojis.right .. " *There are no variables available for this embed.*"
            end

            local lines = {}
            for name, desc in pairs(varTable) do
                table.insert(lines, string.format("> " .. emojis.right .. " **`{%s}`:** %s", name, desc))
            end
            table.sort(lines)
            return table.concat(lines, "\n")
        end

        local variableEmbed = {
            title = emojis.variable .. " Variable List",
            description = formatVariables(variableList),
            color = colors.blank,
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

            elseif id == "embed_variable_list" then
                ia:reply({
                    embed = variableEmbed
                }, true)
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

    local function loadMembers(guild)
        local total = guild.totalMemberCount or 0

        if table.count(guild.members) == total then
            return true
        end

        guild:requestMembers()

        local maxTime = 5
        local startTime = os.time()

        while table.count(guild.members) < total and os.time() - startTime <= maxTime do
            timer.sleep(100)
        end

        return true
    end

    _G.loadMembers = loadMembers

    local function getMemberFromInteraction(interaction, args, slash, userArgName)
        userArgName = userArgName or "user"
        local user
        local member

        if not interaction then return end

        if not args or ((slash and not args[userArgName]) and not args[1]) then return end

        if slash and args[userArgName] then
            user = args[userArgName]
            member = user and interaction.guild:getMember(user.id)
        elseif tonumber(args[1]) then
            user = client:getUser(args[1])
            member = interaction.guild:getMember(args[1])
        else
            user = interaction.mentionedUsers and interaction.mentionedUsers.first
            member = user and interaction.guild:getMember(user.id)

            if (not user) and args[1] and args[1] ~= "" then
                loadMembers(interaction.guild)

                for _, v in pairs(interaction.guild.members) do
                    if v.name:lower():find(args[1]:lower()) or v.user.username:lower():find(args[1]:lower()) or v.id == tostring(args[1]) then
                        user = v.user
                        member = v
                    end
                end
            end
        end

        return member, user
    end

    _G.getMemberFromInteraction = getMemberFromInteraction

    -------------------------------------------------------------------------------------------------------------

    local function channelSelect(ia, opts, callback)
        local defaultValues = {}
        if opts.defaults then
            if type(opts.defaults) == "table" then
                for _, id in ipairs(opts.defaults) do
                    table.insert(defaultValues, { id = id, type = "channel" })
                end
            else
                defaultValues = { { id = opts.defaults, type = "channel" } }
            end
        end

        local selectMenu = discordia.SelectMenu({
            id = "channelselect_" .. _G.junkStr(10),
            type = 8,
            placeholder = opts.placeholder or "Select a channel...",
            actionRow = 1,
            min_values = opts.min or 0,
            max_values = opts.max or 1,
            default_values = defaultValues
        })

        local reply = ia:reply({
            components = discordia.Components():selectMenu(selectMenu):raw(),
            ephemeral = true
        })

        onComp(reply, nil, nil, ia.user.id, true, function(cia)
            local selected = cia.data.values or {}
            ia:deleteReply(reply.id)

            if callback then
                callback(selected, cia)
            end
        end)
    end

    _G.channelSelect = channelSelect

    local function roleSelect(ia, opts, callback)
        local defaultValues = {}
    if opts.defaults then
            if type(opts.defaults) == "table" then
                for _, id in ipairs(opts.defaults) do
                    table.insert(defaultValues, { id = id, type = "role" })
                end
            else
                defaultValues = { { id = opts.defaults, type = "role" } }
            end
        end

        local selectMenu = discordia.SelectMenu({
            id = "roleselect_" .. _G.junkStr(10),
            type = 6,
            placeholder = opts.placeholder or "Select a role...",
            actionRow = 1,
            min_values = opts.min or 0,
            max_values = opts.max or 1,
            default_values = defaultValues
        })

        local reply = ia:reply({
            components = discordia.Components():selectMenu(selectMenu):raw(),
            ephemeral = true
        })

        onComp(reply, nil, nil, ia.user.id, true, function(cia)
            local selected = cia.data.values or {}
            ia:deleteReply(reply.id)

            if callback then
                callback(selected, cia)
            end
        end)
    end

    _G.roleSelect = roleSelect

    local function mentionableSelect(ia, name, cb, defer, min, max, defaults)
		min = min or 0
		max = max or 1

		local default_values = nil
		if defaults and type(defaults) == "table" then
			default_values = {}
			for _, default_id in ipairs(defaults) do
				local type = nil
				if ia.guild:getRole(default_id) then
					type = "role"
				else
					type = "user"
				end
				table.insert(default_values, {
					id = default_id,
					type = type
				})
			end
		elseif defaults then
			local type = nil
			if ia.guild:getRole(defaults) then
				type = "role"
			else
				type = "user"
			end
			default_values = {
				{
					id = defaults,
					type = type
				}
			}
		end

		local comps = discordia.SelectMenu({
			id = _G.junkStr(5),
			placeholder = name,
			type = "mentionable",
			actionRow = 1,
			min_values = min,
			max_values = max,
			default_values = default_values
		})

		local r = ia:reply({
			components = discordia.Components({
				comps:raw()
			}):raw()
		}, true)

		if r then
			onComp(r, nil, nil, ia.user.id, defer, function(mia)
				local selection = mia.data and mia.data.values

				if (type(selection) == "table") and (not selection[1]) then selection = nil end

				cb(selection)
				if defer then
					mia:updateDeferred(true)
					ia:deleteReply(r.id)
				end
			end)
		end
	end

	_G.mentionableSelect = mentionableSelect

    local function optionsSelect(ia, name, cb, defer, options, max, defaults, single)
		local optionsTable = table.deepcopy(options)

		if defaults then
			for _, option in pairs(optionsTable) do
				if option and type(option) == "table" and table.find(defaults, option.value) then
					option.default = true
				end
			end
		end

		local min_values = single and nil or 0
		local max_values = single and nil or (max or table.count(optionsTable))

		local selectMenu = discordia.SelectMenu({
			id = _G.junkStr(5),
			placeholder = name,
			min_values = min_values,
			max_values = max_values,
			options = optionsTable,
			actionRow = 1
		})

		local r, err = ia:reply({
			components = discordia.Components():selectMenu(selectMenu):raw()
		}, true)

		if not r then
			return client:error("optionsSelect failed, name: " .. name .. ", error: " .. err)
		end

		onComp(r, nil, nil, ia.user.id, defer, function(cia)
			local selections = cia.data and cia.data.values

			if type(selections) == "table" and not selections[1] then
				selections = nil
			end

			if single and type(selections) == "table" then
				selections = selections[1]
			end

			cb(selections, cia, r)

			if defer then
				cia:updateDeferred(true)
				ia:deleteReply(r.id)
			end
		end)
	end

	_G.optionsSelect = optionsSelect
    
    -------------------------------------------------------------------------------------------------------------

    print(cc.green .. "[UTILS]" .. cc.reset .. "- Initialized utility functions in " .. (os.clock() - startTime) .. " seconds.")
end

utils.Stop = function()
end

return utils