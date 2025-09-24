-- warn.lua
local db = _G.db
local tools = _G.tools

local slashCommand = tools.slashCommand("warn", "Warn a user.")
local option = tools.user("user", "The user to warn."):setRequired(true)
slashCommand = slashCommand:addOption(option)
local option = tools.string("reason", "The reason for the warning."):setRequired(true)
slashCommand = slashCommand:addOption(option)

return {
    name = "warn",
    description = "Issue a warning to a member.",
    slashCommand = slashCommand,
    module = "discord_moderation",
    category = "Moderation",
    requiredPermissions = { "DISCORD_MOD" },
    hybridCallback = function(interaction, args, slash)
        local member = getMemberFromInteraction(interaction, args, slash)

        if not member then
            return interaction:reply({
                embed = {
                    description = _G.emojis.fail .. " You did not provide a member to warn.",
                    color = _G.colors.fail
                },
                ephemeral = true
            })
        end

        if _G.hasPerms(member, "DISCORD_MOD") == true then
            return interaction:reply({
                embed = {
                    description = _G.emojis.fail .. " You cannot moderate other moderators/administrators.",
                    color = _G.colors.fail
                },
                ephemeral = true
            })
        end

        local reason = (slash and args and args.reason) or ((not slash) and table.remove(args, 1) and table.concat(args, " ") ~= "" and table.concat(args, " "))

        if not reason then
            return interaction:reply({
                embed = {
                    description = _G.emojis.fail .. " You did not provide a reason.",
                    color = _G.colors.fail
                },
                ephemeral = true
            })
        end

        local case = db:case(member, interaction.member, "Warning", reason)

        if case then
            interaction:reply({
                embed = {
                    description = _G.emojis.success .. " **@" .. member.name .. "** has been warned for **" .. reason .. "**.",
                    color = _G.colors.success
                },
                ephemeral = true
            })
        else
            interaction:reply({
                embed = {
                    description = _G.emojis.fail .. " An error occured when trying to warn **@" .. member.name .. "**.",
                    color = _G.colors.fail
                },
                ephemeral = true
            })
        end

        local invites = interaction.guild:getInvites()
        local firstInvite

        for _, invite in pairs(invites) do
            firstInvite = invite
            break
        end
        local inviteUrl = firstInvite and "https://discord.gg/" .. firstInvite.code
                 or "https://discord.com/channels/" .. interaction.guild.id

        local serverLinkButton = discordia.Button({
            label = interaction.guild.name,
            style = "link",
            url = inviteUrl
        })

        member:send({
            embed = {
                description = _G.emojis.warning .. " You have been warned in **" .. interaction.guild.name .. "** for **" .. reason .. "**.",
                color = _G.colors.warning
            },
            components = discordia.Components({ serverLinkButton }):raw()
        })

        db:send(interaction.guild, "modules.discord_moderation.moderation_logs_channel", {
            embed = {
                title = _G.emojis.warning .. " Member Warned",
                description = 
                    _G.emojis.right .. " **Member:** " .. member.mentionString .. " (`" .. member.id .. "`)\n" ..
                    _G.emojis.right .. " **Moderator:** " .. interaction.member.mentionString .. " (`" .. interaction.member.id .. "`)\n" ..
                    _G.emojis.right .. " **Reason:** " .. (case.reason or "No reason provided.") .. "\n" ..
                    _G.emojis.right .. " **Date:** <t:" .. case.timestamp .. ":F>\n" ..
                    _G.emojis.right .. " **Case ID:** `" .. tostring(case.caseID) .. "`",
                color = _G.colors.warning
            }
        })
    end
}