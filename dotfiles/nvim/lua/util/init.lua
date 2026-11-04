local M = {}

M.mapkey = function(keys, func, desc, mode, bufnr)
  M._mapkey(keys, func, desc, mode, "", bufnr)
end


M._mapkey = function(keys, func, desc, mode, prefix, bufnr)
  mode = mode or "n"
  if bufnr then
    vim.keymap.set(mode, keys, func, { desc = prefix .. desc, buffer = bufnr })
  else
    vim.keymap.set(mode, keys, func, { desc = prefix .. desc })
  end
end

M.mapkey_lsp = function(keys, func, desc, mode, prefix)
  M._mapkey(keys, func, desc, mode, "LSP: ")
end

--- Check if a buffer is valid
---@param bufnr? integer The buffer to check, default to current buffer
---@return boolean # Whether the buffer is valid or not
function M.is_buf_valid(bufnr)
  if not bufnr then bufnr = 0 end
  return vim.api.nvim_buf_is_valid(bufnr) and vim.bo[bufnr].buflisted
end

function M.list_insert_unique(dst, src)
  if not dst then dst = {} end
  assert(vim.islist(dst), "Provided table is not a list like table")
  local added = {}
  for _, val in ipairs(dst) do
    added[val] = true
  end
  for _, val in ipairs(src) do
    if not added[val] then
      table.insert(dst, val)
      added[val] = true
    end
  end
  return dst
end

--- Get a plugin spec from lazy
---@param plugin string The plugin to search for
---@return LazyPlugin? spec The found plugin spec from Lazy
function M.get_plugin(plugin)
  local lazy_config_avail, lazy_config = pcall(require, "lazy.core.config")
  return lazy_config_avail and lazy_config.spec.plugins[plugin] or nil
end

--- Check if a plugin is defined in lazy. Useful with lazy loading when a plugin is not necessarily loaded yet
---@param plugin string The plugin to search for
---@return boolean available Whether the plugin is available
function M.is_available(plugin) return M.get_plugin(plugin) ~= nil end

---@param name string
function M.opts(name)
  local plugin = M.get_plugin(name)
  if not plugin then
    return {}
  end
  local Plugin = require("lazy.core.plugin")
  return Plugin.values(plugin, "opts", false)
end

function M.is_loaded(name)
  local Config = require("lazy.core.config")
  return Config.plugins[name] and Config.plugins[name]._.loaded
end

--- Resolve the options table for a given plugin with lazy
---@param plugin string The plugin to search for
---@return table opts The plugin options
function M.plugin_opts(plugin)
  local spec = M.get_plugin(plugin)
  return spec and require("lazy.core.plugin").values(spec, "opts") or {}
end

function M.extend_tbl(default, opts)
  opts = opts or {}
  return default and vim.tbl_deep_extend("force", default, opts) or opts
end

---@param name string
---@param fn fun(name:string)
function M.on_load(name, fn)
  if M.is_loaded(name) then
    fn(name)
  else
    vim.api.nvim_create_autocmd("User", {
      pattern = "LazyLoad",
      callback = function(event)
        if event.data == name then
          fn(name)
          return true
        end
      end,
    })
  end
end

--- mason.nvim 的安装根目录。
---
--- **不要**用 `vim.fn.expand("$MASON/...")`：mason.nvim 只在
--- `mason-core/installer/InstallLocation.lua` 里设 `vim.env.MASON`，那是安装/卸载时
--- 才跑的代码，正常启动一次根本不会设。而 `expand` 对未设置的变量做的是**空前缀替换**：
--- 实测 `expand("$MASON/share/jdtls")` 返回 `"/share/jdtls"` —— 一个不存在、却长得像
--- 绝对路径的字符串，`fs_stat`/`glob` 静默失败，表现是「明明装好了却报没装」。
--- 更阴的是 `expand("$NOPE")`（不带后续路径）反而返回字面量 `"$NOPE"`，两种行为不一致。
--- 另外 `vim.fn.glob("$MASON/...")` 是**双重错误**：glob 根本不展开环境变量。
---
--- 解析顺序：mason.settings 的 install_root_dir（尊重自定义安装目录）
--- → `vim.env.MASON`（真设了才用）→ `stdpath("data") .. "/mason"`（默认位置，
--- 也是 lang/vue.lua 一直在用的写法）。
---@return string|nil
function M.mason_root()
  local ok, settings = pcall(require, "mason.settings")
  local dir = ok and settings.current and settings.current.install_root_dir
  if dir and dir ~= "" then
    return dir
  end
  if vim.env.MASON and vim.env.MASON ~= "" then
    return vim.env.MASON
  end
  return vim.fn.stdpath("data") .. "/mason"
end

local LazyUtil = require("lazy.core.util")
--- Override the default title for notifications.
for _, level in ipairs({ "info", "warn", "error" }) do
  M[level] = function(msg, opts)
    opts = opts or {}
    opts.title = opts.title or "NeoVim"
    return LazyUtil[level](msg, opts)
  end
end

return M
