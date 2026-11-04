return {
  {
    "nvim-treesitter/nvim-treesitter",
    optional = true,
    opts = function(_, opts)
      if opts.ensure_installed ~= "all" then
        opts.ensure_installed = utils.list_insert_unique(opts.ensure_installed, { "xml", "html" })
      end
    end,
  },
  {
    "neovim/nvim-lspconfig",
    optional = true,
    opts = function(_, opts)
      -- 必须用 list_insert_unique **追加**。utils.extend_tbl 底层是
      -- vim.tbl_deep_extend("force")，对数组是**按下标覆盖**：这么写会把
      -- opts.ensure_installed[1] 整个换成 "lemminx"，别的 lang 文件先塞进去的
      -- 第一项就被吃掉了。详见 lang/java.lua 里那段注释。
      opts.ensure_installed = utils.list_insert_unique(opts.ensure_installed or {}, { "lemminx" })
    end,
  },
}
