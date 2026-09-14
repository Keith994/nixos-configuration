return { {
  'nvim-orgmode/orgmode',
  event = 'VeryLazy',
  ft = { 'org' },
  dependencies = {
    'nvim-orgmode/org-bullets.nvim',
    'Saghen/blink.cmp'
  },
  config = function()
    -- Setup orgmode
    require('orgmode').setup({
      org_agenda_files = '~/org/**/*',
      org_default_notes_file = '~/org/todo.org',
    })
    require('org-bullets').setup()
    require('blink.cmp').setup({})

    -- Experimental LSP support
    vim.lsp.enable('org')
  end,
},
  {
    "akinsho/org-bullets.nvim",
    config = function()
      require("org-bullets").setup {
        concealcursor = false, -- If false then when the cursor is on a line underlying characters are visible
        symbols = {
          -- list symbol
          list = "•",
          -- headlines can be a list
          headlines = { "◉", "○", "✸", "✿" },
          -- or a function that receives the defaults and returns a list
          headlines = function(default_list)
            table.insert(default_list, "♥")
            return default_list
          end,
          -- or false to disable the symbol. Works for all symbols
          headlines = false,
          -- or a table of tables that provide a name
          -- and (optional) highlight group for each headline level
          headlines = {
            { "◉", "MyBulletL1" },
            { "○", "MyBulletL2" },
            { "✸", "MyBulletL3" },
            { "✿", "MyBulletL4" },
          },
          checkboxes = {
            half = { "", "@org.checkbox.halfchecked" },
            done = { "✓", "@org.keyword.done" },
            todo = { "˟", "@org.keyword.todo" },
          },
        }
      }
    end
  },
  {
    "chipsenkbeil/org-roam.nvim",
    tag = "0.2.0",
    dependencies = {
      {
        "nvim-orgmode/orgmode",
        tag = "0.7.0",
      },
    },
    config = function()
      require("org-roam").setup({
        directory = "~/org_roam_files",
        -- optional
        org_files = {
          "~/another_org_dir",
          "~/some/folder/*.org",
          "~/a/single/org_file.org",
        }
      })
    end
  }
  -- {
  --   "lukas-reineke/headlines.nvim",
  --   dependencies = "nvim-treesitter/nvim-treesitter",
  --   config = true,     -- or `opts = {}`
  -- }
}
