return {
  "NickvanDyke/opencode.nvim",
  dependencies = {
    {
      "folke/snacks.nvim",
      opts = { input = { enabled = true }, picker = { enabled = true }, terminal = { enabled = true } },
    },
  },
  specs = {
    {
      "folke/which-key.nvim",
      optional = true,
      opts = function(_, opts)
      end,
    },
  },
  config = function()
    local prefix = "<Leader>O"
    local map = function(keys, func, desc, mode)
      mode = mode or "n"
      vim.keymap.set(mode, keys, func, { desc = "OpenCode: " .. desc })
    end
    map(prefix .. "<cr>", function() require("opencode").toggle() end, "Toggle embedded")
    map(prefix .. "a", function() require("opencode").prompt "@buffer" end, "Add buffer to opencode", { "n", "v" })
    map(prefix .. "e", function() require("opencode").ask("@this: ", { submit = true }) end, "Ask about this",
      { "n", "x" })
    map(prefix .. "s", function() require("opencode").select() end, "Select prompt", { "n", "x" })
    vim.keymap.set("n", "<S-C-u>", function() require("opencode").command("session.half.page.up") end,
      { desc = "opencode half page up" })
    vim.keymap.set("n", "<S-C-d>", function() require("opencode").command("session.half.page.down") end,
      { desc = "opencode half page down" })

    vim.api.nvim_create_autocmd("User", {
      pattern = "OpencodeEvent:*", -- Optionally filter event types
      callback = function(args)
        ---@type opencode.cli.client.jjEvent
        local event = args.data.event
        ---@type number
        local port = args.data.port

        -- See the available event types and their properties
        -- vim.notify(vim.inspect(event))
        -- Do something useful
        if event.type == "session.idle" then
          vim.notify("`opencode` finished responding")
        end
      end,
    })
  end,
}
