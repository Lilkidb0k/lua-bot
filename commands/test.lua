local slashCommand = _G.tools.slashCommand("test", "Test simple pagination")

return {
    name = "test",
    description = "Test simple pagination",
    slashCommand = slashCommand,
    hybridCallback = function(ctx, args, slash)
        local pages = {
            { description = "First page", color = 0x00ff00},
            { description = "Second page", color = 0xffff00},
            { description = "Final page", color = 0xff0000}
        }

        local owner = slash and ctx.user or ctx.author

        _G.paginate(ctx, pages, owner, { showTotalPages = true, startPage = 2 })
    end
}