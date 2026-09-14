return {
  {
    "EdenEast/nightfox.nvim",
    opts = {
      options = {
        module_default = false,
        modules = {
          aerial = true,
          cmp = true,
          ["dap-ui"] = true,
          dashboard = true,
          diagnostic = true,
          gitsigns = true,
          native_lsp = true,
          neotree = true,
          notify = true,
          symbol_outline = true,
          telescope = true,
          treesitter = true,
          whichkey = true,
        },
      },
      groups = { all = { NormalFloat = { link = "Normal" } } },
    },
  },
  { "rose-pine/neovim", enabled = false, name = "rose-pine", opts = {} },
  {
    "scottmckendry/cyberdream.nvim",
    lazy = false,
    priority = 1000,
    opts = {
      transparent = true,
      italic_comments = true,
      hide_fillchars = true,
      borderless_pickers = false,
      terminal_colors = true,
      saturation = 0.80,
      colors = {
        dark = {
          -- fg = "#1efeee",
          fg = "#eeeeee",
        },
      },
    },
  },
  {
    "catppuccin/nvim",
    enabled = false,
    name = "catppuccin",
    ---@type CatppuccinOptions
    opts = {
      integrations = {
        aerial = true,
        alpha = true,
        blink_cmp = true,
        cmp = true,
        dap = true,
        dap_ui = true,
        gitsigns = true,
        illuminate = true,
        indent_blankline = true,
        markdown = true,
        mason = true,
        native_lsp = { enabled = true },
        neotree = true,
        notify = true,
        semantic_tokens = true,
        symbols_outline = true,
        telescope = true,
        treesitter = true,
        ts_rainbow = false,
        ufo = true,
        which_key = true,
        window_picker = true,
        colorful_winsep = { enabled = true, color = "lavender" },
        snacks = {
          enabled = true,
          indent_scope_color = "lavender",
        },
      },
    },
    specs = {
      {
        "akinsho/bufferline.nvim",
        optional = true,
        opts = {},
        -- opts = function(_, opts)
        --   return utils.extend_tbl(opts, {
        --     highlights = require("catppuccin.groups.integrations.bufferline").get(),
        --   })
        -- end,
      },
      {
        "nvim-telescope/telescope.nvim",
        optional = true,
        opts = {
          highlight = {
            enable = true,
            additional_vim_regex_highlighting = false,
          },
        },
      },
    },
  },
}
