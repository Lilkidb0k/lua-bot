-- sync.lua

return {
    name = "sync",
    description = "Synchronize the bot's commands.",
    aliases = {"synchronize"},
    requiredPermissions = { "DEVELOPER" },
    callback = function(message, args)

        local loadSlash = false
        local slashToLoad = nil
        local loadModules = false

        local emb = {
            description = emojis.loading .. " Synchronizing Commands...\n> -# This may take a few seconds.",
            color = colors.loading
        }

        loadSlash = args[1] == "slash"
        slashToLoad = args[2]
        loadModules = args[1] == "modules"

        if loadSlash then
            if slashToLoad then
                emb.description = emb.description .. "\n> -# `/" .. slashToLoad .. "` is being reconstructed."
            else
                emb.description = emojis.loading .. " All slash commands are being reconstructed.\n> -# This may take a few seconds..."
            end
        elseif loadModules then
            emb.description = emojis.loading .. " All modules are being synchronized.\n> -# This may take a few seconds..."
        end

        local r = message:reply({embed = emb})

        local c, errors = _G.loadCommands(loadSlash, slashToLoad, loadModules)

        if not r then return end

        emb = {
            description = emojis.success .. " **" .. c .. "** commands were synchronized successfully.",
            color = colors.success
        }

        if loadSlash then
            if slashToLoad then
                emb.description = emojis.success .. " `/" .. slashToLoad .. "` has been reconstructed."
            else
                emb.description = emojis.success .. " **All** slash commands have been reconstructed."
            end
        elseif loadModules then
            emb.description = emojis.success .. " **All modules** have been synchronized."
        end

        if #errors > 0 then
            emb.description = emb.description .. "\n\n**Errors:**\n"
            for _, err in pairs(errors) do
                local emoji = ""
                if err.errorType == "Runtime" then emoji = _G.emojis.error
                elseif err.errorType == "Syntax" then emoji = _G.emojis.warning end
                emb.description = emb.description .. ">>> - " .. emoji .. " " .. err.errorType .. " error in `" .. err.fileName .. "`: " .. err.errorMessage .. "\n"
            end
            emb.color = _G.colors.fail
        end

        r:setEmbed(emb)
    end
}