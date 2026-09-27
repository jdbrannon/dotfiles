return {
	"nvim-treesitter/nvim-treesitter",
	build = ":TSUpdate",
	opts = function(_, opts)
		opts.ensure_installed = opts.ensure_installed or {}

		vim.list_extend(opts.ensure_installed, {
			"lua",
			"bibtex",
			"latex",
		})

		opts.highlight = opts.highlight or {}
		opts.highlight.enable = true

		opts.indent = opts.indent or {}
		opts.indent.enable = true

		opts.autotag = opts.autotag or {}
		opts.autotag.enable = true

		opts.auto_install = false
	end,
}
