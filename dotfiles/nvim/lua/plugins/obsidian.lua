return {
  "obsidian-nvim/obsidian.nvim",
  -- the obsidian vault in this default config  ~/obsidian-vault
  -- If you want to use the home shortcut '~' here you need to call 'vim.fn.expand':
  -- event = { "bufreadpre " .. vim.fn.expand "~" .. "/my-vault/**.md" },
  event = { "BufReadPre  */obsidian-notes/*.md" },

  dependencies = {
    "nvim-lua/plenary.nvim",
    { "hrsh7th/nvim-cmp", optional = true },
  },
  opts = function(_, opts)
    return utils.extend_tbl(opts, {
      ui = { enable = false },
      workspaces = {
        {
          path = vim.env.HOME .. "/obsidian-notes", -- specify the vault location. no need to call 'vim.fn.expand' here
        },
      },
      open = {
        use_advanced_uri = true,
      },
      finder = (utils.is_available "snacks.pick" and "snacks.pick")
          or (utils.is_available "telescope.nvim" and "telescope.nvim")
          or (utils.is_available "fzf-lua" and "fzf-lua")
          or (utils.is_available "mini.pick" and "mini.pick"),

      templates = {
        subdir = "templates",
        date_format = "%Y-%m-%d-%a",
        time_format = "%H:%M",
      },
      daily_notes = {
        folder = "daily",
      },
      completion = {
        nvim_cmp = utils.is_available "nvim-cmp",
        blink = utils.is_available "blink",
      },

      note_frontmatter_func = function(note)
        -- This is equivalent to the default frontmatter function.
        local out = { id = note.id, aliases = note.aliases, tags = note.tags }
        -- `note.metadata` contains any manually added fields in the frontmatter.
        -- So here we just make sure those fields are kept in the frontmatter.
        if note.metadata ~= nil and not vim.tbl_isempty(note.metadata) then
          for k, v in pairs(note.metadata) do
            out[k] = v
          end
        end
        return out
      end,

      -- Optional, by default when you use `:ObsidianFollowLink` on a link to an external
      -- URL it will be ignored but you can customize this behavior here.
      follow_url_func = vim.ui.open,
    })
  end,
  config = function(_, opts)
    require("obsidian").setup(opts)

    vim.keymap.set("n", "gof",
      function()
        return "<CMD>Obsidian follow_link<CR>"
      end, { desc = "Obsidian Follow Link", expr = true })

    vim.keymap.set("n", "gof",
      function()
        return "<CMD>Obsidian tody<CR>"
      end, { desc = "Open daily", expr = true })

    vim.keymap.set("n", "goo",
      function()
        return "<CMD>Obsidian open<CR>"
      end, { desc = "Open obsidian", expr = true })

    vim.keymap.set("n", "gob",
      function()
        return "<CMD>Obsidian backlinks<CR>"
      end, { desc = "Open obsidian", expr = true })
  end,
}
