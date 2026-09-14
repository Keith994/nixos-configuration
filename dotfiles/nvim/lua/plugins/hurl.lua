local prefix = "<Leader>h"

return {
  "jellydn/hurl.nvim",
  ft = "hurl",
  dependencies = {
    "MunifTanjim/nui.nvim",
    "nvim-lua/plenary.nvim",
    {
      "nvim-treesitter/nvim-treesitter",
      opts = function(_, opts)
        if opts.ensure_installed ~= "all" then
          opts.ensure_installed = utils.list_insert_unique(opts.ensure_installed, { "hurl" })
        end
      end,
    },
    {
      "WhoIsSethDaniel/mason-tool-installer.nvim",
      optional = true,
      opts = function(_, opts)
        opts.ensure_installed = utils.list_insert_unique(opts.ensure_installed, { "jq", "prettier" })
      end,
    },
  },
  opts = function(_, opts)
    local mapkey = utils.mapkey
    mapkey(prefix .. "R", "<cmd>HurlRunner<cr>", "Run all requests in the file")
    mapkey(prefix .. "m", "<cmd>HurlManageVariable<cr>", "Open Varialbles")
    mapkey(prefix .. "r", "<cmd>HurlRunnerAt<cr>", "Run request under the cursor")
    mapkey(prefix .. "e", "<cmd>HurlRunnerToEntry<cr>", "Run request to the entry")
    mapkey(prefix .. "E", "<cmd>HurlRunnerToEnd<cr>", "Run all request to the end")
    mapkey(prefix .. "l", "<cmd>HurlShowLastResponse<cr>", "Toggle Last Reponse Panel")
    mapkey(prefix .. "v", "<cmd>HurlVerbose<cr>", "Toggle verbose mode")
    mapkey(prefix .. "V", "<cmd>HurlVeryVerbose<cr>", "Toggle very verbose mode")
    return opts
  end,
}
