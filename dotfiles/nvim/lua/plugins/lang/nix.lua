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
      -- ensure_installed 要**追加**而不是塞进 ret 交给 extend_tbl：后者对数组是
      -- 按下标覆盖，会冲掉别的 lang 文件已经塞进去的项。详见 lang/java.lua 的注释。
      opts.ensure_installed = utils.list_insert_unique(opts.ensure_installed or {}, { "statix" })
      return utils.extend_tbl(opts, {
        servers = {
          nil_ls = {},
        },
      })
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
