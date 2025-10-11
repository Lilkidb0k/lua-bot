-- test.lua
return {
	name = "test",
	description = "Test simple pagination",
	callback = function(message, args, slash)
		local msg = message:reply({
			embed = {
				description = emojis.loading .. " Waiting to be updated..."
			}
		})

		local updatedEmbed = {
			description = emojis.success .. " Updated successfully.",
            color = colors.success
		}

		msg:update({
			embeds = {updatedEmbed}
		})
	end
}