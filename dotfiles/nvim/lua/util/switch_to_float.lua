local M = setmetatable({
  float_ind_id = 0,
}, {
  __call = function(m, ...)
    m.switch_to_float()
  end,
})

function M.switch_to_float()
  local float_win_id = tonumber(M.float_win_id)
  if float_win_id and float_win_id ~= 0 then
    pcall(vim.api.nvim_set_current_win, float_win_id)
  end
end

-- 定义一个函数来打印浮动窗口消息
function M.print_floating_window_message()
  -- 获取当前窗口的类型
  local win_type = vim.fn.win_gettype()

  -- 检查是否是浮动窗口
  if win_type == "popup" or win_type == "floating" then
    -- 获取当前缓冲区的名称和类型
    local bufname = vim.fn.bufname(0) -- 0 表示当前缓冲区
    local buftype = vim.bo.buftype    -- vim.bo 是 buffer options 的快捷方式

    if buftype == "nofile" then
      M.float_win_id = vim.fn.win_getid()
    end
  end
end

-- 创建自动命令组
vim.api.nvim_create_augroup("FloatingWindowMessageLua", { clear = true })

-- 定义自动命令
vim.api.nvim_create_autocmd("BufWinEnter", {
  group = "FloatingWindowMessageLua",
  pattern = "*",
  callback = M.print_floating_window_message, -- 直接调用 Lua 函数
  desc = "在新的浮动窗口创建时打印消息",
})

return M
