return {
  {
    "ThePrimeagen/harpoon",
    branch = "harpoon2",
    dependencies = {
      "nvim-lua/plenary.nvim"
    },
    config = function()
      local harpoon = require("harpoon")

      harpoon:setup()
      vim.keymap.set("n", "<leader>ha", function() harpoon:list():add() end, { desc = "Harpoon add file" })
      vim.keymap.set("n", "<leader>hr", function() harpoon:list():remove() end, { desc = "Harpoon remove file" })
      vim.keymap.set("n", "<leader>ho", function() harpoon.ui:toggle_quick_menu(harpoon:list()) end,
        { desc = "Open Harpoon Menu" })
      vim.keymap.set("n", "<leader>hp", function() harpoon:list():prev() end, { desc = "Harpoon previous file" })
      vim.keymap.set("n", "<leader>hn", function() harpoon:list():next() end, { desc = "Harpoon next file" })

      vim.keymap.set("n", "<leader>hf", function()
        local conf = require("telescope.config").values
        local themes = require("telescope.themes")
        local file_paths = {}
        for _, item in ipairs(harpoon:list().items) do
          table.insert(file_paths, item.value)
        end
        require("telescope.pickers").new(themes.get_ivy({ prompt_title = "Working List" }), {
          finder = require("telescope.finders").new_table({ results = file_paths }),
          previewer = conf.file_previewer({}),
          sorter = conf.generic_sorter({}),
        }):find()
      end, { desc = "Open harpoon window" })
    end,
  },
  {
    "folke/which-key.nvim",
    opts = {
      spec = {
        { "<leader>h", group = "Harpoon" },
      },
    },
  },
}
