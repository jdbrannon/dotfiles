return {
    'nvim-treesitter/nvim-treesitter',
    lazy = false,
    build = ':TSUpdate',
    config = function()
        local ts = require("nvim-treesitter")
        ts.setup({
            highlight = {
                enable = true,
            },
            indent = { enable = true },
            autotage = { enable = true },
            ensure_installed = {
                "lua",
            },
            auto_install = false
        })
    end
}
