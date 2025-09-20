-- lua.lua
local client = _G.client
local emojis = _G.emojis
local colors = _G.colors
local resolveEmoji = _G.resolveEmoji

local function prettyLine(...)
    local ret = {}
    for i = 1, select('#', ...) do
        local arg = tostring(select(i, ...))
        table.insert(ret, arg)
    end
    return table.concat(ret, '\t')
end

local function printLine(...)
    local ret = {}
    for i = 1, select('#', ...) do
        local arg = tostring(select(i, ...))
        table.insert(ret, arg)
    end
    return table.concat(ret, '\t')
end

return {
    name = "lua",
    description = "Execute lua code.",
    requiredPermissions = { "DEVELOPER" },
    callback = function(message, args)

        local toexec = table.concat(args, " ")
        if toexec == "" or toexec == " " then return print("No code to execute.") end

        toexec = toexec:gsub('```\n?', ''):gsub("“", '"'):gsub("”", '"')

        local lines = {}
        local sandbox = {}

        sandbox.print = function(...) table.insert(lines, printLine(...)) end
        sandbox.p = function(...) table.insert(lines, prettyLine(...)) end

        sandbox.message = message
        sandbox.msg = message
        sandbox.client = client
        sandbox.me = message.member
        sandbox.guild = message.guild
        sandbox.channel = message.channel
        sandbox._G = _G
        sandbox.args = args
        sandbox.dia = _G.discordia
        sandbox.discordia = _G.discordia
        sandbox.os = os
        sandbox.io = io
        sandbox.coroutine = coroutine
        sandbox.math = math
        sandbox.string = string
        sandbox.table = table
        sandbox.tostring = tostring
        sandbox.tonumber = tonumber
        sandbox.pairs = pairs
        sandbox.type = type
        sandbox.require = require
        sandbox.emojis = _G.emojis
        sandbox.resolveEmoji = _G.resolveEmoji
        sandbox.colors = _G.colors
        sandbox.junkStr = _G.junkStr
        sandbox.you = message.referencedMessage and message.referencedMessage.member
        sandbox.ref = message.referencedMessage
        sandbox.sqldb = _G.sqldb
        sandbox.sqlite3 = _G.sqlite3
        sandbox.fs = _G.fs

        sandbox.embed = nil

        sandbox.allemojis = function()
            local emojistrings = {}
            local emojistr = ""
            local c = 0
        
            if not _G.emojis then
                return sandbox.msg:reply("Error: No emojis found in _G.emojis.")
            end
        
            local emojiNames = {}
            for k in pairs(_G.emojis) do
                table.insert(emojiNames, k)
            end
        
            table.sort(emojiNames, function(a, b) return a:lower() < b:lower() end)
        
            for _, emojiName in pairs(emojiNames) do
                c = c + 1
                local emoji = _G.emojis[emojiName]
        
                local emojiId = emoji:match(":(%d+)>")
                
                if emojiId then
                    emojistr = emojistr .. emoji .. " - " .. "`" .. emoji .. "`\n"
                else
                    emojistr = emojistr .. emoji .. " - Unknown ID\n"
                end
        
                if emojistr:len() >= 1500 or c >= #emojiNames then
                    table.insert(emojistrings, emojistr)
                    emojistr = ""
                end
            end
        
            for _, emj in pairs(emojistrings) do
                sandbox.msg:reply(emj)
            end
        end
        
        sandbox.allcolors = function()
            local colorStrings = {}
            local colorStr = ""
            local count = 0
        
            if not _G.colors then
                return sandbox.msg:reply("Error: No colors found in _G.colors.")
            end
        
            local colorNames = {}
            for k in pairs(_G.colors) do
                table.insert(colorNames, k)
            end
        
            table.sort(colorNames, function(a, b) return a:lower() < b:lower() end)
        
            for _, colorName in pairs(colorNames) do
                count = count + 1
                local color = _G.colors[colorName]
                colorStr = colorStr .. "**" .. colorName .. "** - `#" .. string.format("%06X", color) .. "`\n"
        
                if colorStr:len() >= 1500 or count >= #colorNames then
                    table.insert(colorStrings, colorStr)
                    colorStr = ""
                end
            end
        
            for _, clr in pairs(colorStrings) do
                sandbox.msg:reply(clr)
            end
        end
        

        sandbox.deepreply = function(content)
            local ref = message.referencedMessage
            if ref then
                message:delete()
                ref:reply(content, true, true)
            end
        end

        local fn, syntaxError = load(toexec, 'Sandbox', 't', sandbox)
        if not fn then
            return message:reply({
                embed = {
                    description = emojis.warning .. " Syntax error in the code.",
                    fields = {
                        { name = "Code:", value = "```lua\n" .. toexec .. "```" },
                        { name = "Error:", value = "```" .. syntaxError .. "```" }
                    },
                    color = colors.warning
                }
            })
        end

        local success, runtimeError = pcall(fn)
        if not success then
            return message:reply({
                embed = {
                    description = emojis.error .. " Runtime error occurred.",
                    fields = {
                        { name = "Code:", value = "```lua\n" .. toexec .. "```" },
                        { name = "Error:", value = "```" .. runtimeError .. "```" }
                    },
                    color = colors.error
                }
            })
        end

        local output = table.concat(lines, '\n')
        local sendAsFile = #output > 1900

        if sandbox.embed and type(sandbox.embed) == "table" and next(sandbox.embed) then
            message:addReaction(resolveEmoji(emojis.success).hash)
            return message.channel:send({ embed = sandbox.embed })
        end

        local response = message:reply({
            embed = {
                description = emojis.loading .. " The following code is being executed...\n```lua\n" .. toexec .. "```",
                color = colors.blank,
                author = {
                    name = message.member.name,
                    icon_url = message.member.avatarURL
                }
            }
        })

        local tosendlines = table.concat(lines, '\n')
        local sendasfile = #tosendlines > 1900

        timer.sleep(50)

        if #lines ~= 0 then
            if sendasfile then
                response:update({
                    embed = {
                        description = emojis.success .. " Executed successfully.\n-# " .. emojis.document ..
                            " Output (" .. #lines .. " lines, " .. #tosendlines .. " characters):",
                        color = colors.success,
                        author = {
                            name = message.member.name,
                            icon_url = message.member.avatarURL
                        }
                    }
                })

                response.channel:send({
                    files = { { "output.txt", tosendlines } }
                })
            else
                response:update({
                    embed = {
                        description = emojis.success .. " Executed successfully.\n-# " .. emojis.document ..
                            " Output (" .. #lines .. " lines, " .. #tosendlines .. " characters):\n```\n" ..
                            tosendlines .. "```",
                        color = colors.success,
                        author = {
                            name = message.member.name,
                            icon_url = message.member.avatarURL
                        }
                    }
                })
            end
        else
            response:update({
                embed = {
                    description = emojis.success .. " Executed successfully.",
                    color = colors.success,
                    author = {
                        name = message.member.name,
                        icon_url = message.member.avatarURL
                    }
                }
            })
        end
    end
}