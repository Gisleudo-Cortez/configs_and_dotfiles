return {
    "folke/which-key.nvim",
    event = "VeryLazy",
    opts = {
        plugins = {
            marks = true,  -- Show :marks usage
            registers = true,  -- Show :registers usage
            spelling = {
                enabled = true,
                suggestions = 20,
            },
            presets = {
                operators = true,
                motions = true,
                text_objects = true,
                windows = true,
                nav = true,
                z = true,
                g = true,
            },
        },
        win = {  -- ✅ Changed from window to win (v3)
            border = "rounded",
            padding = { 1, 2 },
            title = true,
            zindex = 1000,
        },
        layout = {
            height = { min = 4, max = 25 },
            width = { min = 20, max = 50 },
            spacing = 3,
        },
        icons = {
            breadcrumb = "»",
            group = "+",
            separator = "➜",
        },
    },
}
