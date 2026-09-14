return {
  {
    "nvim-treesitter/nvim-treesitter",
    optional = true,
    opts = function(_, opts)
      if opts.ensure_installed ~= "all" then
        opts.ensure_installed = utils.list_insert_unique(opts.ensure_installed, { "nix" })
      end
    end,
  },

  {
    "neovim/nvim-lspconfig",
    optional = true,
    opts = function(_, opts)
      vim.lsp.enable("nil_ls", true)
      local ret = {
        ensure_installed = { "nixd" },
        servers = {
          nil_ls = {},
        },
      }
      return utils.extend_tbl(opts, ret)
    end,
  },
  {
    "mfussenegger/nvim-lint",
    optional = true,
    opts = {
      linters_by_ft = {
        nix = { "statix", "deadnix" },
      },
    },
  },
  {
    "stevearc/conform.nvim",
    optional = true,
    opts = {
      formatters_by_ft = {
        nix = { "nixfmt" },
      },
    },
  },
}
