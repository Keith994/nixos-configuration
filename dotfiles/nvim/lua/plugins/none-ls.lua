return {
  "nvimtools/none-ls.nvim",
  main = "null-ls",
  specs = {
    { "nvim-lua/plenary.nvim", lazy = true },
  },
  dependencies = {
    "mason-org/mason.nvim",
  },
  event = "VeryLazy",
  opts = function(_, opts)
    utils.mapkey("<Leader>ln", "<Cmd>NullLsInfo<CR>", "Null-ls information")
    local nls = require("null-ls")
    opts.root_dir = opts.root_dir
        or require("null-ls.utils").root_pattern(".null-ls-root", ".neoconf.json", "Makefile", ".git")
  end,
}
