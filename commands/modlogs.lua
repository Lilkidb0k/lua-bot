-- modlogs.lua
local sqldb = _G.sqldb

local slashCommand = _G.tools.slashCommand("modlogs", "View the moderation logs on the given user.")
slashCommand = slashCommand:addOption(_G.tools.user("user", "The user's modlogs to view."):setRequired(false))

return {
    name = "modlogs",
    description = "View the moderation logs on the given user.",
    category = "Moderation",
    module = "discord_moderation",
    requiredPermissions = {"DISCORD_MOD"},
    slashCommand = slashCommand,
    aliases = { "cases", "ml" },
    hybridCallback = function(interaction, args, slash)
        local member = _G.getMemberFromInteraction(interaction, args, slash) or interaction.member
		local config = sqldb:get(interaction.guild.id) or {}
		local allCases = table.values(config.cases or {})

        table.sort(allCases, function(a, b)
			return a.timestamp > b.timestamp
		end)

        local userCases = {}
        for _, c in ipairs(allCases) do
            if c.member == member.id then
                table.insert(userCases, c)
            end
        end

        if #userCases == 0 then
            return interaction:reply({
                embed = {
                    description = _G.emojis.fail .. " This user has no moderation cases.",
                    color = _G.colors.fail
                }
            })
        end

        table.sort(userCases, function(a, b)
            return a.timestamp > b.timestamp
        end)

        local pages = {}
        local perPage = 5
        for i = 1, #userCases, perPage do
            local fields = {}
            for j = i, math.min(i + perPage - 1, #userCases) do
                local c = userCases[j]

                local fieldName = "Case #" .. c.caseID
                local fieldValue = ""

                fieldValue = fieldValue .. _G.emojis.right .. " **Moderator:** <@" .. c.moderator .. ">\n"

                local typeLine = _G.emojis.right .. " **Type:** " .. c.type
                if c.length then
                    typeLine = typeLine .. " (" .. c.length .. ")"
                end
                fieldValue = fieldValue .. typeLine .. "\n"

                fieldValue = fieldValue .. _G.emojis.right .. " **Reason:** " .. (c.reason or "No reason provided.")

                table.insert(fields, {
                    name = fieldName,
                    value = fieldValue,
                    inline = false
                })
            end

            table.insert(pages, {
                fields = fields,
                color = _G.colors.info
            })
        end

        _G.paginate(interaction, pages, member, { showTotalPages = true, startPage = 1 })
    end
}
