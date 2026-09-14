return {
  {
    "nvim-treesitter/nvim-treesitter",
    optional = true,
    opts = function(_, opts)
      if opts.ensure_installed ~= "all" then
        opts.ensure_installed = utils.list_insert_unique(opts.ensure_installed, { "nu" })
      end
    end,
  },
  {
    "neovim/nvim-lspconfig",
    optional = true,
    opts = function()
      vim.lsp.enable("nushell")
    end,
  },
  {
    "stevearc/conform.nvim",
    optional = true,
    opts = {
      formatters_by_ft = {
        nu = { "nufmt", lsp_format = "last" },
      },
    },
  },
}
