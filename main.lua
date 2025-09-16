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
    for _, file in ipairs(fs.readdirSync("./commands")) do
        if file:match("%.lua$") then
            local command = require("./commands/" .. file:gsub("%.lua$", ""))
            commands[command.name] = command
            print("[CMDS] - Loaded command: " .. command.name)
        end
    end
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

local function messageBuilder(message)
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
            id = "savebutton",
            label = "Save",
            emoji = resolvedEmojis.successWhite,
            style = "success"
        }

    local messageState = {
        content = "Welcome to the " .. emojis.document .. " **Message Builder**. You can edit this message using the dropdown menu below. Once you are finished editing your message, click " .. emojis.successWhite .. " **Save**.",
        channelId = message.channel.id
    }

    local function updateDisplay(msg, state, appendChannel)
        local channel = client:getChannel(state.channelId)
        local display = state.content ~= "" and state.content or "_Empty_"
        if appendChannel and channel then
            display = display .. "\n\n-# " .. emojis.right .. " " .. channel.mentionString
        end
        msg:setContent(display)
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
                        required = true,
                        max = 2000
                    }
                }, function(mia, responses)
                    local content = responses["Message Content"]
                    if content then
                        messageState.content = content
                        updateDisplay(sentMessage, messageState, false)
                    else
                        mia:reply("No content provided!", true)
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
                        updateDisplay(sentMessage, messageState, true)
                        ia:deleteReply(r.id)
                    else
                        cia:reply("No channel selected.", true)
                    end
                end)
            end

        elseif id == "savebutton" then
            local channel = client:getChannel(messageState.channelId)
            if channel then
                channel:send(messageState.content)
                sentMessage:delete()
                ia:updateDeferred(true)
            else
                ia:reply("Selected channel is invalid!", true)
            end
        end
    end)
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