return {
	"lervag/vimtex",
	lazy = false, -- lazy-loading will disable inverse search
	config = function()
		vim.g.vimtex_mappings_disable = { ["n"] = { "K" } } -- disable `K` as it conflicts with LSP hover
		vim.g.vimtex_quickfix_method = vim.fn.executable("pplatex") == 1 and "pplatex" or "latexlog"
		vim.g.vimtex_view_method = "zathura_simple"

		-- Auto forward search so zathura highlights the line you're on
		vim.opt.updatetime = 500
		vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
			pattern = "*.tex",
			callback = function()
				local state = vim.b.vimtex
				if not state then
					return
				end
				-- Only forward-search if zathura already has this PDF open (never launch a new one)
				local name = vim.fn.fnamemodify(state.tex, ":t:r") .. ".pdf"
				local regex = name:gsub("[%.%-%+%[%]%(%)%*%?%^%$]", "\\%0")
				vim.system({ "pgrep", "-f", "zathura.*" .. regex }, {}, function(res)
					if res.code == 0 then
						vim.schedule(function()
							vim.cmd("silent! VimtexView")
						end)
					end
				end)
			end,
		})
	end,
	keys = {
		{ "<localLeader>l", "", desc = "+vimtex", ft = "tex" },
	},
}
