return {
  {
    "rebelot/heirline.nvim",
    event = "BufEnter",
    dependencies = {
      "echasnovski/mini.icons",
      {
        "Zeioth/heirline-components.nvim",
        opts = function()
          local icons = require("util.icons")
          local ret = {
            icons = {
              DiagnosticError = icons.diagnostics.Error,
              DiagnosticHint = icons.diagnostics.Hint,
              DiagnosticInfo = icons.diagnostics.Info,
              DiagnosticWarn = icons.diagnostics.Warn,
              PathSeparator = icons.misc.separator,

              GitBranch = icons.git.branch,
              GitAdd = icons.git.added,
              GitChange = icons.git.modified,
              GitDelete = icons.git.removed,
              BreadcrumbSeparator = icons.misc.separator,
              VimIcon = icons.misc.VimIcon,
            },
          }
          return ret
        end,
        config = function(_, opts)
          require("heirline-components").setup(opts)
          -- injects custom icon
          local sep = require("heirline-components.core.env").separators
          require("heirline-components.core.env").separators = utils.extend_tbl(sep, require("util.icons").separators)
        end,
      },
    },
    opts = function()
      local lib = require("heirline-components.all")
      -- local function bufnr(opts)
      --   opts = utils.extend_tbl({}, opts)
      --   return function(self)
      --     return lib.utils.stylize(
      --       tostring(self and self.bufnr or vim.api.nvim_get_current_buf()) .. (opts.suffix or " "),
      --       opts
      --     )
      --   end
      -- end
      -- local tabline_buffers = function(opts)
      --   local hl = lib.hl
      --   local condition = lib.condition
      --   local buf_utils = require("heirline-components.buffer")
      --   local extend_tbl = utils.extend_tbl
      --
      --   local file_info_table = lib.component.file_info(extend_tbl({
      --     file_icon = {
      --       condition = function(self)
      --         return not self._show_picker
      --       end,
      --       hl = hl.file_icon("tabline"),
      --     },
      --     filename = {},
      --     filetype = false,
      --     file_modified = {
      --       padding = { left = 1, right = 1 },
      --       condition = condition.is_file,
      --     },
      --     unique_path = {
      --       hl = function(self)
      --         return hl.get_attributes(self.tab_type .. "_path")
      --       end,
      --     },
      --     close_button = {
      --       hl = function(self)
      --         return hl.get_attributes(self.tab_type .. "_close")
      --       end,
      --       padding = { left = 1, right = 1 },
      --       on_click = {
      --         callback = function(_, minwid)
      --           buf_utils.close(minwid)
      --         end,
      --         minwid = function(self)
      --           return self.bufnr
      --         end,
      --         name = "heirline_tabline_close_buffer_callback",
      --       },
      --     },
      --     padding = { left = 1, right = 1 },
      --     hl = function(self)
      --       local tab_type = self.tab_type
      --       if self._show_picker and self.tab_type ~= "buffer_active" then
      --         tab_type = "buffer_visible"
      --       end
      --       return hl.get_attributes(tab_type)
      --     end,
      --     surround = false,
      --   }, opts))
      --
      --   table.insert(file_info_table, 3, {
      --     provider = bufnr({ suffix = ":" }),
      --   })
      --
      --   return require("heirline-components.core.heirline").make_buflist(file_info_table)
      -- end

      -- local path_func = lib.provider.filename({ modify = ":.:h", fallback = "" })
      -- Rose Pine Moon palette
      local rp = {
        surface  = "#2a273f",
        overlay  = "#393552",
        muted    = "#6e6a86",
        text     = "#e0def4",
        love     = "#eb6f92",
        gold     = "#f6c177",
        rose     = "#ea9a97",
        pine     = "#3e8fb0",
        foam     = "#9ccfd8",
        iris     = "#c4a7e7",
      }
      local bg = rp.overlay
      return {
        statusline = {
          hl = { fg = rp.muted, bg = rp.surface },
          lib.component.mode({
            mode_text = { icon = { kind = "VimIcon", padding = { right = 0, left = 1 } } },
            surround = {
              separator = "left",
              color = lib.hl.mode_bg,
              update = {
                "ModeChanged",
                pattern = "*:*",
              },
            },
          }),
          lib.component.file_info({
            filename = {
              fallback = "",
              fname = function(nr)
                local path = vim.fn.expand("%:p:h")
                -- 分割路径
                local parts = {}
                for part in path:gsub("^/", ""):gmatch("[^/]+") do
                  table.insert(parts, part)
                end

                -- 只取最后三层（如果不足三层就取全部）
                local start_idx = math.max(1, #parts - 2)
                local result_parts = {}
                for i = start_idx, #parts do
                  table.insert(result_parts, parts[i])
                end

                -- 用点连接
                return table.concat(result_parts, ".")
              end,
              padding = { left = 1, right = 1 },
            },
            filetype = false,
            file_icon = false,
            file_modified = false,
            file_read_only = false,
            surround = { separator = "left", color = rp.surface },
          }),
          -- lib.component.git_branch({
          --   git_branch = { icon = { padding = { left = 1 } } },
          --   surround = { separator = "left", color = bg },
          -- }),
          lib.component.git_diff({
            surround = { separator = "left", color = bg },
          }),
          lib.component.diagnostics {
            surround = { separator = "right", color = bg },
          },
          lib.component.fill(),
          lib.component.cmd_info(),
          lib.component.lsp({
            lsp_progress = false,
            surround = { separator = "right", color = bg },
          }),
          lib.component.builder(lib.utils.setup_providers({
            ruler = {},
            percentage = { padding = { left = 1, right = 1 } },
            surround = { separator = "right", color = bg },
            hl = lib.hl.get_attributes("nav"),
            update = { "CursorMoved", "CursorMovedI", "BufEnter" },
          }, { "ruler", "percentage" })),
          lib.component.file_info({
            filename = {
              fallback = "",
              fname = function(nr)
                local buf_enc = vim.bo[vim.api.nvim_get_current_buf() or 0].fenc
                buf_enc = string.upper(buf_enc ~= "" and buf_enc or vim.o.enc)
                return buf_enc
              end,
              padding = { left = 1, right = 1 },
            },
            filetype = false,
            hl = lib.hl.get_attributes("mode"),
            file_icon = false,
            file_modified = false,
            file_read_only = false,
            surround = {
              separator = "right",
              color = lib.hl.mode_bg,
              update = {
                "ModeChanged",
                pattern = "*:*",
              },
            },
          }),
        },
        --stylua: ignore
        -- winbar = {
        --   init = function(self) self.bufnr = vim.api.nvim_get_current_buf() end,
        --   fallthrough = false,
        --   {
        --     condition = function() return not lib.condition.is_active() end,
        --     lib.component.separated_path(),
        --     lib.component.file_info {
        --       file_icon = { hl = lib.hl.file_icon "winbar", padding = { left = 0 } },
        --       filename = {},
        --       filetype = false,
        --       file_read_only = false,
        --       hl = lib.hl.get_attributes("winbarnc", true),
        --       surround = false,
        --       update = { "BufEnter", "BufFilePost" },
        --     },
        --   },
        --   -- active winbar
        --   {
        --     -- show the path to the file relative to the working directory
        --     lib.component.separated_path { path_func = path_func },
        --     -- add the file name and icon
        --     lib.component.file_info { -- add file_info to breadcrumbs
        --       file_icon = { hl = lib.hl.filetype_color, padding = { left = 0 } },
        --       filename = {},
        --       filetype = false,
        --       file_modified = false,
        --       file_read_only = false,
        --       hl = lib.hl.get_attributes("winbar", true),
        --       surround = false,
        --       update = "BufEnter",
        --     },
        --     -- show the breadcrumbs
        --     lib.component.breadcrumbs {
        --       icon = { hl = true },
        --       hl = lib.hl.get_attributes("winbar", true),
        --       prefix = true,
        --       padding = { left = 0 },
        --     },
        --   },
        -- },
        -- tabline = {
        --   lib.component.tabline_conditional_padding(),
        --   tabline_buffers(),
        --   lib.component.fill({ hl = { bg = "tabline_bg" } }), -- fill the rest of the tabline with background color
        --   lib.component.tabline_tabpages(),
        -- },
        statuscolumn = {
          init = function(self)
            self.bufnr = vim.api.nvim_get_current_buf()
          end,
          lib.component.foldcolumn(),
          lib.component.numbercolumn(),
          lib.component.signcolumn(),
        },
      }
    end,
    config = function(_, opts)
      local heirline = require("heirline")
      local lib = require("heirline-components.all")

      -- Set HeirlineNormal/Insert/... vim hl groups so get_colors() picks them up.
      local function apply_rp_hl()
        vim.api.nvim_set_hl(0, "HeirlineNormal",   { bg = "#9ccfd8" }) -- foam
        vim.api.nvim_set_hl(0, "HeirlineInsert",   { bg = "#f6c177" }) -- gold
        vim.api.nvim_set_hl(0, "HeirlineVisual",   { bg = "#c4a7e7" }) -- iris
        vim.api.nvim_set_hl(0, "HeirlineReplace",  { bg = "#eb6f92" }) -- love
        vim.api.nvim_set_hl(0, "HeirlineCommand",  { bg = "#ea9a97" }) -- rose
        vim.api.nvim_set_hl(0, "HeirlineTerminal", { bg = "#3e8fb0" }) -- pine
      end
      apply_rp_hl()

      -- subscribe_to_events() registers a ColorScheme autocmd that calls
      -- on_colorscheme(get_colors()), which resets mode_fg to "NONE" (cyberdream
      -- transparent → StatusLine.bg = nil). Register our patch AFTER so it
      -- runs last in FIFO order and overwrites mode_fg.
      lib.init.subscribe_to_events()
      vim.api.nvim_create_autocmd("ColorScheme", {
        desc = "Patch Rose Pine Moon mode_fg after heirline-components reset",
        callback = function()
          apply_rp_hl()
          heirline.load_colors({ mode_fg = "#232136", inactive = "#393552" })
        end,
      })

      heirline.load_colors(utils.extend_tbl(lib.hl.get_colors(), {
        inactive = "#393552",  -- overlay
        mode_fg  = "#232136",  -- rose pine base: dark text on mode-colored surround
      }))
      heirline.setup(opts)
    end,
  },
  {
    "Bekaboo/dropbar.nvim",
    event = "UIEnter",
    opts = {
      sources = {
        path = {
          max_depth = 1,
        },
        lsp = {
          max_depth = 3,
        },
        treesitter = {
          max_depth = 3,
        },
      },
    },
    specs = {
      {
        "rebelot/heirline.nvim",
        optional = true,
        opts = function(_, opts)
          opts.winbar = nil
        end,
      },
      {
        "catppuccin",
        optional = true,
        opts = { integrations = { dropbar = { enabled = true } } },
      },
    },
  },

  {
    "akinsho/bufferline.nvim",
    event = "VeryLazy",
    keys = {
      { "<leader>bp", "<Cmd>BufferLineTogglePin<CR>",            desc = "Toggle Pin" },
      { "<leader>bP", "<Cmd>BufferLineGroupClose ungrouped<CR>", desc = "Delete Non-Pinned Buffers" },
      { "<leader>br", "<Cmd>BufferLineCloseRight<CR>",           desc = "Delete Buffers to the Right" },
      { "<leader>bl", "<Cmd>BufferLineCloseLeft<CR>",            desc = "Delete Buffers to the Left" },
      { "[b",         "<cmd>BufferLineCyclePrev<cr>",            desc = "Prev Buffer" },
      { "]b",         "<cmd>BufferLineCycleNext<cr>",            desc = "Next Buffer" },
      { "<b",         "<cmd>BufferLineMovePrev<cr>",             desc = "Move buffer prev" },
      { ">B",         "<cmd>BufferLineMoveNext<cr>",             desc = "Move buffer next" },
    },
    opts = {
      options = {
        -- stylua: ignore
        close_command = function(n) Snacks.bufdelete(n) end,
        -- stylua: ignore
        right_mouse_command = function(n) Snacks.bufdelete(n) end,
        diagnostics = false,
        always_show_bufferline = true,
        diagnostics_indicator = function(_, _, diag)
          local icons = require("util.icons")
          local ret = (diag.error and icons.diagnostics.Error .. diag.error .. " " or "")
              .. (diag.warning and icons.diagnostics.Warn .. diag.warning or "")
          return vim.trim(ret)
        end,
        offsets = {
          {
            filetype = "neo-tree",
            text = "Neo-tree",
            highlight = "Directory",
            text_align = "left",
          },
          {
            filetype = "snacks_layout_box",
          },
        },
        separator_style = "thin",
        ---@param opts bufferline.IconFetcherOpts
        get_element_icon = function(opts)
          local icons = require("util.icons")
          return icons.ft[opts.filetype]
        end,
        numbers = function(opts)
          return string.format("%s", opts.id)
        end,
      },
    },
    config = function(_, opts)
      require("bufferline").setup(opts)

      require("bufferline.groups").builtin.pinned:with({ icon = "" })
      -- Rose Pine Moon: visible bufs → foam, background bufs → muted
      vim.cmd("hi BufferLineBufferVisible guifg=#9ccfd8")
      vim.cmd("hi BufferLineBackground guifg=#6e6a86")
      -- Fix bufferline when restoring a session
      vim.api.nvim_create_autocmd({ "BufAdd", "BufDelete" }, {
        callback = function()
          vim.schedule(function()
            pcall(nvim_bufferline)
          end)
        end,
      })
    end,
  },
}
