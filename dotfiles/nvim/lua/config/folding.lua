-- Folding Utilities
--
-- Helper functions for configuring folding in Neovim
local M = {}

local config = {
  enabled = function(bufnr)
    if not bufnr then
      bufnr = 0
    end
    return vim.api.nvim_buf_is_valid(bufnr) and vim.bo[bufnr].buflisted
  end,
  methods = { "lsp", "treesitter", "indent" },
}

M.is_setup = false
M.lsp_bufs = {}
M.ts_bufs = {}

local fold_methods = {
  lsp = function(lnum, bufnr)
    if M.lsp_bufs[bufnr or vim.api.nvim_get_current_buf()] then
      return vim.lsp.foldexpr(lnum)
    end
  end,
  treesitter = function(lnum, bufnr)
    if M.ts_bufs[bufnr] == nil then
      if not utils.is_available("nvim-treesitter") or package.loaded["nvim-treesitter"] then
        M.ts_bufs[bufnr] = vim.bo.filetype and pcall(vim.treesitter.get_parser, bufnr)
      end
    end
    if M.ts_bufs[bufnr] then
      return vim.treesitter.foldexpr(lnum)
    end
  end,
  indent = function(lnum, bufnr)
    if not lnum then
      lnum = vim.v.lnum
    end
    if not bufnr then
      bufnr = vim.api.nvim_get_current_buf()
    end
    return vim.api.nvim_buf_get_lines(bufnr, lnum - 1, lnum, false)[1]:match("^%s*$") and "="
      or math.floor(vim.fn.indent(lnum) / vim.bo[bufnr].shiftwidth)
  end,
}

--- Check if folding is enabled for a buffer
---@param bufnr integer The buffer to check (defaults to current buffer)
---@return boolean enabled whether or not the buffer is enabled for folding
function M.is_enabled(bufnr)
  local enabled = config and config.enabled
  if type(enabled) == "function" then
    enabled = enabled(bufnr or vim.api.nvim_get_current_buf())
  end
  return enabled == true
end

--- A fold expression for doing LSP and Treesitter based folding
---@param lnum? integer the current line number
---@return string foldlevel the calculated fold level
function M.foldexpr(lnum)
  if not M.is_setup then
    M.setup()
  end
  local bufnr = vim.api.nvim_get_current_buf()
  if M.is_enabled(bufnr) then
    for _, method in ipairs(config and config.methods or {}) do
      local fold_method = fold_methods[method]
      if fold_method then
        local fold = fold_method(lnum, bufnr)
        if fold then
          return fold
        end
      end
    end
  end
  -- fallback to no folds
  return "0"
end

--- Get the current folding status of a given buffer
---@param bufnr? integer the buffer to check the folding status for
function M.info(bufnr)
  if not bufnr then
    bufnr = vim.api.nvim_get_current_buf()
  end
  local lines = {}
  local enabled = M.is_enabled(bufnr)
  table.insert(lines, "Buffer folding is **" .. (enabled and "Enabled" or "Disabled") .. "**\n")
  local methods = config and config.methods or {}
  for _, method in pairs(methods) do
    local fold_method = fold_methods[method]
    local available = "Unavailable"
    local surround = ""
    if not fold_method then
      available = "*Invalid*"
    elseif fold_method(1, bufnr) then
      available = "Available"
      if enabled then
        surround = "**"
        enabled = false
      end
    end
    table.insert(lines, ("%s`%s`: %s%s"):format(surround, method, available, surround))
  end
  table.insert(lines, "```lua")
  table.insert(lines, "methods = " .. vim.inspect(methods))
  table.insert(lines, "```")
  utils.info(table.concat(lines, "\n"))
end

function M.setup()
  vim.api.nvim_create_user_command("FoldInfo", function()
    M.info()
  end, { desc = "Display folding information" })
  local augroup = vim.api.nvim_create_augroup("foldexpr", { clear = true })
  vim.api.nvim_create_autocmd("LspAttach", {
    desc = "Monitor attached LSP clients with fold providers",
    group = augroup,
    callback = function(args)
      local client = assert(vim.lsp.get_client_by_id(args.data.client_id))
      if client:supports_method("textDocument/foldingRange", args.buf) then
        M.lsp_bufs[args.buf] = true
      end
    end,
  })
  vim.api.nvim_create_autocmd("LspDetach", {
    group = augroup,
    desc = "Safely remove LSP folding providers when language servers detach",
    callback = function(args)
      if not vim.api.nvim_buf_is_valid(args.buf) then
        return
      end
      for _, client in pairs(vim.lsp.get_clients({ bufnr = args.buf })) do
        if client.id ~= args.data.client_id and client:supports_method("textDocument/foldingRange", args.buf) then
          return
        end
      end
      M.lsp_bufs[args.buf] = nil
    end,
  })
  M.is_setup = true
end

return M
