---@type LazySpec
return {
  {
    "zbirenbaum/copilot.lua",
    cmd = "Copilot",
    -- event = "InsertEnter",
    opts = {
      suggestion = { enabled = false },
      panel = { enabled = false },
      filetypes = {
        markdown = true,
        help = false,
      },
      -- copilot_model = "grok-code-fast-1", -- copilot/Grok Code Fast 1 (grok-code-fast-1)
    },
  },
  {
    "saghen/blink.cmp",
    optional = true,
    dependencies = {
      {
        "fang2hou/blink-copilot",
        opts = {
          max_completions = 2,
          max_attempts = 4,
          kind_name = "Copilot", ---@type string | false
          kind_icon = " ", ---@type string | false
          kind_hl = false, ---@type string | false
          debounce = 100, ---@type integer | false
          auto_refresh = {
            backward = true,
            forward = true,
          },
        },
      },
    },
    opts = {
      sources = {
        default = { "copilot" },
        providers = {
          copilot = {
            name = "copilot",
            module = "blink-copilot",
            score_offset = 100,
            async = true,
          },
        },
      },
    },
  },
  {
    "echasnovski/mini.icons",
    optional = true,
    -- Adds icon for copilot using mini.icons
    opts = function(_, opts)
      if not opts.lsp then
        opts.lsp = {}
      end
      if not opts.symbol_map then
        opts.symbol_map = {}
      end
      opts.symbol_map.copilot = { glyph = "", hl = "MiniIconsAzure" }
    end,
  },
}

-- return {
--   {
--     "copilotlsp-nvim/copilot-lsp",
--     init = function()
--       vim.g.copilot_nes_debounce = 500
--       vim.lsp.enable("copilot_ls")
--       vim.keymap.set("n", "<tab>", function()
--         local bufnr = vim.api.nvim_get_current_buf()
--         local state = vim.b[bufnr].nes_state
--         if state then
--           local _ = require("copilot-lsp.nes").walk_cursor_start_edit()
--               or (
--                 require("copilot-lsp.nes").apply_pending_nes()
--                 and require("copilot-lsp.nes").walk_cursor_end_edit()
--               )
--           return nil
--         else
--           return "<C-i>"
--         end
--       end, { desc = "Accept Copilot NES suggestion", expr = true })
--     end,
--   },
--   {
--     "saghen/blink.cmp",
--     dependencies = {
--       {
--         "fang2hou/blink-copilot",
--         opts = {
--           max_completions = 2,
--           max_attempts = 4,
--           kind_name = "Copilot", ---@type string | false
--           kind_icon = " ", ---@type string | false
--           kind_hl = false, ---@type string | false
--           debounce = 100, ---@type integer | false
--           auto_refresh = {
--             backward = true,
--             forward = true,
--           },
--         }
--
--       },
--     },
--     opts = {
--       sources = {
--         default = { "copilot" },
--         providers = {
--           copilot = {
--             name = "copilot",
--             module = "blink-copilot",
--             score_offset = 100,
--             async = true,
--           },
--         },
--       },
--       keymap = {
--         preset = "super-tab",
--         ["<Tab>"] = {
--           function(cmp)
--             if vim.b[vim.api.nvim_get_current_buf()].nes_state then
--               cmp.hide()
--               return (
--                 require("copilot-lsp.nes").apply_pending_nes()
--                 and require("copilot-lsp.nes").walk_cursor_end_edit()
--               )
--             end
--             if cmp.snippet_active() then
--               return cmp.accept()
--             else
--               return cmp.select_and_accept()
--             end
--           end,
--           "snippet_forward",
--           "fallback",
--         },
--       },
--     },
--   }
-- }
