-- sync.lua

return {
    name = "sync",
    description = "Synchronize the bot's commands.",
    aliases = {"synchronize"},
	requiredPermissions = { "DEVELOPER" },
	callback = function(message, args)

		local loadSlash = false
		local slashToLoad = nil

		local emb = {
			description = emojis.loading .. " Synchronzing Commands...\n> -# This may take a few seconds.",
			color = colors.loading
		}

		loadSlash, slashToLoad = args[1] == "slash", args[2]
		if loadSlash then
			if slashToLoad then
				emb.description = emb.description .. "\n> -# `/" .. slashToLoad .. "` is being reconstructed."
			else
				emb.description = emojis.loading .. " All slash commands are being reconstructed.\n> -# This may take a few seconds..."
			end
		end
		
		local r = message:reply({embed = emb})
		
		local c, errors = _G.loadCommands(loadSlash, slashToLoad)
		
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
		end
		
		if #errors > 0 then
			emb.description = emb.description .. "\n\n**Errors:**\n"
			for _, err in pairs(errors) do
				local emoji = ""
				if err.errorType == "Runtime" then emoji = _G.emojis.error elseif err.errorType == "Syntax" then emoji = _G.emojis.warning end
				emb.description = emb.description .. ">>> - " .. emoji .. " " .. err.errorType .. " error in `" .. err.fileName .. "`: " .. err.errorMessage .. "\n"
			end
			emb.color = _G.colors.fail
		end
		
		r:setEmbed(emb)
	end
}