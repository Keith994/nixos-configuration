return {
  "stevearc/aerial.nvim",
  event = "VeryLazy",
  opts = function(_, opts)
    utils.mapkey("<Leader>cb", function() require("aerial").toggle() end, "Symbols outline")
    opts = utils.extend_tbl(opts, {
      attach_mode = "global",
      backends = { "lsp", "treesitter", "markdown", "man" },
      layout = { min_width = 28 },
      show_guides = true,
      filter_kind = false,
      guides = {
        mid_item = "├ ",
        last_item = "└ ",
        nested_top = "│ ",
        whitespace = "  ",
      },
      keymaps = {
        ["[y"] = "actions.prev",
        ["]y"] = "actions.next",
        ["[Y"] = "actions.prev_up",
        ["]Y"] = "actions.next_up",
        ["{"] = false,
        ["}"] = false,
        ["[["] = false,
        ["]]"] = false,
      },
      on_attach = function(bufnr)
        utils.mapkey("]y", function() require("aerial").next(vim.v.count1) end, "Next symbol", "n", bufnr)
        utils.mapkey("[y", function() require("aerial").prev(vim.v.count1) end, "Previous symbol", "n", bufnr)
        utils.mapkey("]Y", function() require("aerial").next_up(vim.v.count1) end, "Next symbol upwards", "n", bufnr)
        utils.mapkey("[Y", function() require("aerial").prev_up(vim.v.count1) end, "Previous symbol upwards", "n", bufnr)
      end,
    })

    return opts
  end,
}
