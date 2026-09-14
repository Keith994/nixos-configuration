local prefix = "<Leader>a"
return {
  {
    "yetone/avante.nvim",
    -- build = vim.fn.has("win32") == 1 and "powershell -ExecutionPolicy Bypass -File Build.ps1 -BuildFromSource false"
    --   or "make",
    event = "BufReadPost", -- load on file open because Avante manages it's own bindings
    enabled = false,
    cmd = {
      "AvanteAsk",
      "AvanteBuild",
      "AvanteEdit",
      "AvanteRefresh",
      "AvanteSwitchProvider",
      "AvanteShowRepoMap",
      "AvanteModels",
      "AvanteChat",
      "AvanteToggle",
      "AvanteClear",
      "AvanteFocus",
      "AvanteStop",
    },
    dependencies = {
      { "stevearc/dressing.nvim", optional = true },
      "nvim-lua/plenary.nvim",
      "MunifTanjim/nui.nvim",
    },
    opts = {
      provider = "copilot",
      -- provider = "openrouter",
      auto_suggestions_provider = "deepseek_cmp",
      suggestion = {
        debounce = 500,
        throttle = 500,
      },
      providers = {
        openrouter = {
          __inherited_from = "openai",
          endpoint = "https://openrouter.ai/api/v1",
          api_key_name = "OPENROUTER_API_KEY",
          model = "google/gemini-2.5-flash",
        },
        deepseek_cmp = {
          __inherited_from = "openai",
          endpoint = "https://api.deepseek.com/beta",
          api_key_name = "DEEPSEEK_API_KEY",
          model = "deepseek-coder",
          extra_request_body = {
            temperature = 0,
            max_tokens = 4096,
          },
        },
        deepseek = {
          __inherited_from = "openai",
          endpoint = "https://api.deepseek.com",
          api_key_name = "DEEPSEEK_API_KEY",
          model = "deepseek-chat",
          extra_request_body = {
            temperature = 0,
            max_tokens = 4096,
          },
        },
      },
      behaviour = {
        auto_suggestions = false,     -- Experimental stage
        auto_add_current_file = true, -- 打开新聊天时是否自动添加当前文件。
        enable_cursor_planning_mode = true,
        ---@type "popup" | "inline_buttons"
        confirmation_ui_style = "popup",
        -- auto_set_highlight_group = true,
        -- auto_set_keymaps = true,
        -- auto_apply_diff_after_generation = false,
        -- support_paste_from_clipboard = false,
        -- minimize_diff = true,                  -- Whether to remove unchanged lines when applying a code block
        -- enable_token_counting = true,          -- Whether to enable token counting. Default to true.
        -- auto_approve_tool_permissions = false, -- Default: show permission prompts for all tools
      },
      input = {
        provider = "snacks",
        provider_opts = {
          -- Additional snacks.input options
          title = "Avante Input",
          icon = " ",
        },
      },
      mappings = {
        -- Main interaction mappings
        ask = prefix .. "<CR>",         -- Ask Avante about current context
        new_ask = prefix .. "n",        -- Start a new ask session
        edit = prefix .. "e",           -- Edit the current prompt
        refresh = prefix .. "r",        -- Refresh/regenerate the response
        -- focus = prefix .. "f",          -- Focus on the Avante window
        focus = nil,
        select_model = prefix .. "?",   -- Select AI model to use
        stop = prefix .. "S",           -- Stop current generation
        select_history = prefix .. "h", -- Select from conversation history

        -- Toggle various UI elements and modes
        toggle = {
          -- default = prefix .. "t",    -- Toggle Avante sidebar
          -- debug = prefix .. "d",      -- Toggle debug mode
          hint = prefix .. "h",       -- Toggle hints display
          -- suggestion = prefix .. "s", -- Toggle suggestions
          repomap = prefix .. "R",    -- Toggle repository map

          default = nil,
          debug = nil,
          suggestion = nil,
        },

        -- Navigation in diff view
        diff = {
          next = "]c", -- Go to next diff hunk
          prev = "[c", -- Go to previous diff hunk
        },

        -- File management
        files = {
          add_current = prefix .. ".",     -- Add current file to context
          add_all_buffers = prefix .. "B", -- Add all open buffers to context
        },

        -- Cancel/close operations
        cancel = {
          normal = { "<C-c>", "<C-g>", "<Esc>", "q" }, -- Cancel in normal mode
          insert = { "<C-c>", "<C-g>" },               -- Cancel in insert mode
        },

        -- Sidebar-specific mappings
        sidebar = {
          apply_all = "A",                         -- Apply all suggested changes
          apply_cursor = "a",                      -- Apply change at cursor position
          retry_user_request = "r",                -- Retry the user's request
          edit_user_request = "e",                 -- Edit the user's request
          switch_windows = "<Tab>",                -- Switch between sidebar windows
          reverse_switch_windows = "<S-Tab>",      -- Reverse switch direction
          remove_file = "d",                       -- Remove file from context
          add_file = "@",                          -- Add file to context
          close = { "<Esc>", "q" },                -- Close sidebar
          close_from_input = { insert = "<C-g>" }, -- Close from input mode
        },
      },
    },
    specs = { -- configure optional plugins
      {
        "folke/which-key.nvim",
        optional = true,
        opts = function(_, opts)
          return utils.extend_tbl(opts, {
            spec = {
              {
                { "<leader>a", group = "avante", icon = { icon = " " } },
              },
            },
          })
        end,
      },
      { -- if copilot.lua is available, default to copilot provider
        "zbirenbaum/copilot.lua",
        optional = true,
        specs = {
          {
            "yetone/avante.nvim",
            opts = {
              -- provider = "copilot",
              -- auto_suggestions_provider = "copilot",
            },
          },
        },
      },
      {
        -- make sure `Avante` is added as a filetype
        "MeanderingProgrammer/render-markdown.nvim",
        optional = true,
        opts = function(_, opts)
          if not opts.file_types then
            opts.file_types = { "markdown" }
          end
          opts.file_types = utils.list_insert_unique(opts.file_types, { "Avante" })
        end,
      },
      {
        -- make sure `Avante` is added as a filetype
        "OXY2DEV/markview.nvim",
        optional = true,
        opts = function(_, opts)
          if not opts.filetypes then
            opts.filetypes = { "markdown", "quarto", "rmd" }
          end
          opts.filetypes = utils.list_insert_unique(opts.filetypes, { "Avante" })
        end,
      },
      {
        "folke/snacks.nvim",
        optional = true,
        specs = {
          {
            "yetone/avante.nvim",
            opts = {
              selector = {
                provider = "snacks",
              },
            },
          },
        },
      },
    },
  },

}
