vim.api.nvim_create_user_command("Format", function(args)
  local range = nil
  if args.count ~= -1 then
    local end_line = vim.api.nvim_buf_get_lines(0, args.line2 - 1, args.line2, true)[1]
    range = {
      start = { args.line1, 0 },
      ["end"] = { args.line2, end_line:len() },
    }
  end
  require("conform").format({ async = true, range = range, timeout_ms = 5000 })
end, {
  desc = "Format buffer",
  range = true,
})

return {
  "stevearc/conform.nvim",
  cmd = "ConformInfo",
  event = { "BufWritePre" },
  opts = {
    formatters_by_ft = {
      kdl = { "kdlfmt" }
    },
    formatters = {
      injected = { options = { ignore_errors = true } },
    },
    default_format_opts = { lsp_format = "fallback" },
  },
  keys = {
    {
      "<LocalLeader>f",
      vim.cmd.Format,
      mode = "",
      desc = "[F]ormat buffer",
    },
  },
}
