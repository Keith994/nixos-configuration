local map = vim.keymap.set
local del = vim.keymap.del

map("n", "q", "<nop>")
map("n", "Q", "q", { noremap = true, silent = true })
-- localleader
map("n", "<localleader>p", function()
  local str = vim.fn.expand("%:p:f")
  utils.info("当前文件路径：" .. str)
end, { desc = "Current Path" })
map("n", "<localleader>c", function()
  Snacks.bufdelete.delete()
end, { desc = "Delete Buffer and Window", silent = true })
map("n", "<localleader>w", "<cmd>:w<cr>", { desc = "Write Buffer", silent = true })

map("n", "<S-h>", "0", { desc = "Line Head" })
map("n", "<S-l>", "$", { desc = "Line Tail" })
local switch_to_float = require("util.switch_to_float")
map("n", "<C-W>w", function()
  switch_to_float()
end, { desc = "Switch To Float", silent = true })

-- command line
map("c", "<c-a>", "<HOME>")
map("c", "<c-e>", "<End>")
map("c", "<c-f>", "<right>")
map("c", "<c-b>", "<left>")
map("c", "<c-h>", "<bs>")
map("c", "<c-d>", "<del>")
map("c", "<c-t>", [[<C-R>=expand("%:p:h") . "/" <CR>]])

-- Open ComandLine
map("n", ";", ":", { desc = "Open ComandLine", remap = true })
-- quit
map("n", "<leader>qq", "<cmd>q<cr>", { desc = "Quit" })
map("n", "<leader>qa", "<cmd>qa<cr>", { desc = "Quit All" })
-- highlights under cursor
map("n", "<leader>ui", vim.show_pos, { desc = "Inspect Pos" })
map("n", "<leader>uI", function()
  vim.treesitter.inspect_tree()
  vim.api.nvim_input("I")
end, { desc = "Inspect Tree" })

-- floating terminal
local root = require("util.root")
map("n", "<leader>fT", function()
  require("snacks").terminal.open()
end, { desc = "Terminal (cwd)" })
map("n", "<leader>ft", function()
  require("snacks").terminal.open()
end, { desc = "Terminal (Root Dir)" })
map("n", "<c-/>", function()
  require("snacks").terminal.open()
end, { desc = "Terminal (Root Dir)" })
map("n", "<c-_>", function()
  require("snacks").terminal.open()
end, { desc = "Terminal (Root Dir)" })
map("t", "<C-/>", "<cmd>close<cr>", { desc = "Hide Terminal" })
map("t", "<C-_>", "<cmd>close<cr>", { desc = "Hide Terminal" })

-- better up/down
map({ "n", "x" }, "j", "v:count == 0 ? 'gj' : 'j'", { desc = "Down", expr = true, silent = true })
map({ "n", "x" }, "<Down>", "v:count == 0 ? 'gj' : 'j'", { desc = "Down", expr = true, silent = true })
map({ "n", "x" }, "k", "v:count == 0 ? 'gk' : 'k'", { desc = "Up", expr = true, silent = true })
map({ "n", "x" }, "<Up>", "v:count == 0 ? 'gk' : 'k'", { desc = "Up", expr = true, silent = true })

--stylua: ignore
-- Move to window using the <ctrl> hjkl keys
map("n", "<C-h>", function() require("smart-splits").move_cursor_left() end, { desc = "Go to Left Window"})
--stylua: ignore
map("n", "<C-j>", function() require("smart-splits").move_cursor_down() end,
  { desc = "Go to Lower Window"})
--stylua: ignore
map("n", "<C-k>", function() require("smart-splits").move_cursor_up() end, { desc = "Go to Upper Window"})
--stylua: ignore
map("n", "<C-l>", function() require("smart-splits").move_cursor_right() end,
  { desc = "Go to Right Window"})
--stylua: ignore
-- Resize window using <ctrl> arrow keys
map("n", "<C-Up>", function() require("smart-splits").resize_up() end, { desc = "Increase Window Height" })
--stylua: ignore
map("n", "<C-Down>", function() require("smart-splits").resize_down() end, { desc = "Decrease Window Height" })
--stylua: ignore
map("n", "<C-Right>", function() require("smart-splits").resize_right() end, { desc = "Decrease Window Width" })
--stylua: ignore
map("n", "<C-Left>", function() require("smart-splits").resize_left() end, { desc = "Increase Window Width" })

-- buffers
map("n", "<S-j>", "<cmd>BufferLineCyclePrev<cr>", { desc = "Prev Buffer" })
map("n", "<S-k>", "<cmd>BufferLineCycleNext<cr>", { desc = "Next Buffer" })
map("n", "[b", "<cmd>BufferLineCyclePrev<cr>", { desc = "Prev Buffer" })
map("n", "]b", "<cmd>BufferLineCycleNext<cr>", { desc = "Next Buffer" })
map("n", "<leader>bb", function()
  require("snacks").picker.buffers()
end, { desc = "Select Buffer From Picker" })
map("n", "<leader>bo", "<cmd>e #<cr>", { desc = "Switch to Other Buffer" })
map("n", "<leader>bd", "<cmd>:bd<cr>", { desc = "Delete Buffer and Window" })
--stylua: ignore
map("n", "<leader>bc", function() Snacks.bufdelete.other() end, { desc = "Delete Other Buffers" })

-- Clear search and stop snippet on escape
map({ "i", "n", "s" }, "<esc>", function()
  vim.cmd("noh")
  -- require("copilot-lsp.nes").clear()
  return "<esc>"
end, { expr = true, desc = "Escape and Clear hlsearch" })

-- Clear search, diff update and redraw
-- taken from runtime/lua/_editor.lua
map(
  "n",
  "<leader>ur",
  "<Cmd>nohlsearch<Bar>diffupdate<Bar>normal! <C-L><CR>",
  { desc = "Redraw / Clear hlsearch / Diff Update" }
)

-- https://github.com/mhinz/vim-galore#saner-behavior-of-n-and-n
map("n", "n", "'Nn'[v:searchforward].'zv'", { expr = true, desc = "Next Search Result" })
map("x", "n", "'Nn'[v:searchforward]", { expr = true, desc = "Next Search Result" })
map("o", "n", "'Nn'[v:searchforward]", { expr = true, desc = "Next Search Result" })
map("n", "N", "'nN'[v:searchforward].'zv'", { expr = true, desc = "Prev Search Result" })
map("x", "N", "'nN'[v:searchforward]", { expr = true, desc = "Prev Search Result" })
map("o", "N", "'nN'[v:searchforward]", { expr = true, desc = "Prev Search Result" })

-- better indenting
map("v", "<", "<gv")
map("v", ">", ">gv")

-- commenting
map("n", "gco", "o<esc>Vcx<esc><cmd>normal gcc<cr>fxa<bs>", { desc = "Add Comment Below" })
map("n", "gcO", "O<esc>Vcx<esc><cmd>normal gcc<cr>fxa<bs>", { desc = "Add Comment Above" })

-- lazy
map("n", "<leader>ll", "<cmd>Lazy<cr>", { desc = "Lazy" })
map("n", "<leader>lm", "<cmd>Mason<cr>", { desc = "Mason" })

-- new file
map("n", "<leader>fn", "<cmd>enew<cr>", { desc = "New File" })

map("n", "<leader>xl", function()
  local success, err = pcall(vim.fn.getloclist(0, { winid = 0 }).winid ~= 0 and vim.cmd.lclose or vim.cmd.lopen)
  if not success and err then
    vim.notify(err, vim.log.levels.ERROR)
  end
end, { desc = "Location List" })

-- quickfix list
map("n", "<leader>xq", function()
  local success, err = pcall(vim.fn.getqflist({ winid = 0 }).winid ~= 0 and vim.cmd.cclose or vim.cmd.copen)
  if not success and err then
    vim.notify(err, vim.log.levels.ERROR)
  end
end, { desc = "Quickfix List" })

map("n", "[q", vim.cmd.cprev, { desc = "Previous Quickfix" })
map("n", "]q", vim.cmd.cnext, { desc = "Next Quickfix" })

-- diagnostic
local diagnostic_goto = function(next, severity)
  local go = next and vim.diagnostic.goto_next or vim.diagnostic.goto_prev
  severity = severity and vim.diagnostic.severity[severity] or nil
  return function()
    go({ severity = severity })
  end
end
map("n", "<leader>cd", vim.diagnostic.open_float, { desc = "Line Diagnostics" })
map("n", "]d", diagnostic_goto(true), { desc = "Next Diagnostic" })
map("n", "[d", diagnostic_goto(false), { desc = "Prev Diagnostic" })
map("n", "]e", diagnostic_goto(true, "ERROR"), { desc = "Next Error" })
map("n", "[e", diagnostic_goto(false, "ERROR"), { desc = "Prev Error" })
map("n", "]w", diagnostic_goto(true, "WARN"), { desc = "Next Warning" })
map("n", "[w", diagnostic_goto(false, "WARN"), { desc = "Prev Warning" })


-- stylua: ignore start

map("n", "<leader>e", function() require("snacks").explorer() end, { desc = "Explorer" })
map("n", "<leader>,", function() require("snacks").picker.buffers() end, { desc = "Buffers" })
map("n", "<leader>/", function() require("snacks").picker.grep() end, { desc = "Grep (Root Dir)" })
map("n", "<leader><space>", function() require("snacks").picker.files() end, { desc = "Find Files (Root Dir)" })
map("n", "<leader>n", function() require("snacks").picker.notifications() end, { desc = "Notification History" })
-- find
map("n", "<leader>fb", function() require("snacks").picker.buffers() end, { desc = "Buffers" })
map("n", "<leader>fB", function() require("snacks").picker.buffers({ hidden = true, nofile = true }) end,
  { desc = "Buffers (all)" })
map("n", "<leader>fc", function() require("snacks").picker.config() end, { desc = "Find Config File" })
map("n", "<leader>ff", function() require("snacks").picker.files() end, { desc = "Find Files (Root Dir)" })
map("n", "<leader>fF", function() require("snacks").picker.files({ root = false }) end, { desc = "Find Files (cwd)" })
map("n", "<leader>fg", function() require("snacks").picker.git_files() end, { desc = "Find Files (git-files)" })
map("n", "<leader>fr", function() require("snacks").picker.recent() end, { desc = "Recent" })
map("n", "<leader>fR", function() require("snacks").picker.recent({ filter = { cwd = true } }) end,
  { desc = "Recent (cwd)" })
map("n", "<leader>fp", function() require("snacks").picker.projects() end, { desc = "Projects" })
-- git
map("n", "<leader>gd", function() require("snacks").picker.git_diff() end, { desc = "Git Diff (hunks)" })
map("n", "<leader>gs", function() require("snacks").picker.git_status() end, { desc = "Git Status" })
map("n", "<leader>gS", function() require("snacks").picker.git_stash() end, { desc = "Git Stash" })
map("n", "<leader>gg", function() require("snacks").lazygit({ cwd = root.git() }) end, { desc = "Lazygit (Root Dir)" })
map("n", "<leader>gG", function() require("snacks").lazygit() end, { desc = "Lazygit (cwd)" })
map("n", "<leader>gf", function() require("snacks").picker.git_log_file() end, { desc = "Git Current File History" })
map("n", "<leader>gl", function() require("snacks").picker.git_log({ cwd = root.git() }) end, { desc = "Git Log" })
map("n", "<leader>gb", "<cmd>Gitsigns blame_line<cr>", { desc = "Git Blame" })
map("n", "gb", "<cmd>Gitsigns blame_line<cr>", { desc = "Git Blame" })
map("n", "<leader>gL", function() require("snacks").picker.git_log() end, { desc = "Git Log (cwd)" })
-- map("n", "<leader>gb", function() require("snacks").picker.git_log_line() end, { desc = "Git Blame Line" })
map({ "n", "x" }, "<leader>gB", "<cmd>BlameToggle<cr>", { desc = "Git Blame File" })
map("n", "gB", "<cmd>BlameToggle<cr>", { desc = "Git blame File" })
map({ "n", "x" }, "<leader>gY", function()
  require("snacks").gitbrowse({ open = function(url) vim.fn.setreg("+", url) end, notify = false })
end, { desc = "Git Browse (copy)" })
-- Grep
map("n", "<leader>sb", function() require("snacks").picker.lines() end, { desc = "Buffer Lines" })
map("n", "<leader>sB", function() require("snacks").picker.grep_buffers() end, { desc = "Grep Open Buffers" })
map("n", "<leader>sg", function() require("snacks").picker.grep() end, { desc = "Grep (Root Dir)" })
map("n", "<leader>sG", function() require("snacks").picker.grep({ root = false }) end, { desc = "Grep (cwd)" })
map("n", "<leader>sp", function() require("snacks").picker.lazy() end, { desc = "Search for Plugin Spec" })
map("n", "<leader>sw", function() require("snacks").picker.grep_word() end,
  { desc = "Visual selection or word (Root Dir)" })
map("x", "<leader>sw", function() require("snacks").picker.grep_word() end,
  { desc = "Visual selection or word (Root Dir)" })
map("n", "<leader>sW", function() require("snacks").picker.grep_word({ root = false }) end,
  { desc = "Visual selection or word (cwd)" })
map("x", "<leader>sW", function() require("snacks").picker.grep_word({ root = false }) end,
  { desc = "Visual selection or word (cwd)" })
-- search
map("n", "<leader>s'", function() require("snacks").picker.registers() end, { desc = "Registers" })
map("n", "<leader>s/", function() require("snacks").picker.search_history() end, { desc = "Search History" })
map("n", "<leader>sa", function() require("snacks").picker.autocmds() end, { desc = "Autocmds" })
map("n", "<leader>sc", function() require("snacks").picker.command_history() end, { desc = "Command History" })
map("n", "<leader>sC", function() require("snacks").picker.commands() end, { desc = "Commands" })
map("n", "<leader>sd", function() require("snacks").picker.diagnostics() end, { desc = "Diagnostics" })
map("n", "<leader>sD", function() require("snacks").picker.diagnostics_buffer() end, { desc = "Buffer Diagnostics" })
map("n", "<leader>sh", function() require("snacks").picker.help() end, { desc = "Help Pages" })
map("n", "<leader>sH", function() require("snacks").picker.highlights() end, { desc = "Highlights" })
map("n", "<leader>si", function() require("snacks").picker.icons() end, { desc = "Icons" })
map("n", "<leader>sj", function() require("snacks").picker.jumps() end, { desc = "Jumps" })
map("n", "<leader>sk", function() require("snacks").picker.keymaps() end, { desc = "Keymaps" })
map("n", "<leader>sl", function() require("snacks").picker.loclist() end, { desc = "Location List" })
map("n", "<leader>sM", function() require("snacks").picker.man() end, { desc = "Man Pages" })
map("n", "<leader>sm", function() require("snacks").picker.marks() end, { desc = "Marks" })
map("n", "<leader>sR", function() require("snacks").picker.resume() end, { desc = "Resume" })
map("n", "<leader>sq", function() require("snacks").picker.qflist() end, { desc = "Quickfix List" })
map("n", "<leader>su", function() require("snacks").picker.undo() end, { desc = "Undotree" })
-- ui
map("n", "<leader>uC", function() require("snacks").picker.colorschemes() end, { desc = "Colorschemes" })
map("n", "]]", function() require("snacks").words.jump(vim.v.count1) end, { desc = "Next reference" })
map("n", "[[", function() require("snacks").words.jump(-vim.v.count1) end, { desc = "Previous reference" })

--tabs
map("n", "<leader><tab>l", "<cmd>tablast<cr>", { desc = "Last Tab" })
map("n", "<leader><tab>f", "<cmd>tabfirst<cr>", { desc = "First Tab" })
map("n", "<leader><tab>o", "<cmd>tabonly<cr>", { desc = "Close Other Tabs" })
map("n", "<leader><tab>n", "<cmd>tabnew<cr>", { desc = "New Tab" })
map("n", "<leader><tab><tab>", "<cmd>tabnew<cr>", { desc = "New Tab" })
map("n", "<leader><tab>]", "<cmd>tabnext<cr>", { desc = "Next Tab" })
map("n", "<leader><tab>[", "<cmd>tabprevious<cr>", { desc = "Previous Tab" })
map("n", "]<tab>", "<cmd>tabnext<cr>", { desc = "Next Tab" })
map("n", "<leader><tab>d", "<cmd>tabclose<cr>", { desc = "Close Tab" })
map("n", "[<tab>", "<cmd>tabprevious<cr>", { desc = "Previous Tab" })

-- neotest
local get_file_path = function() return vim.fn.expand "%" end
local get_project_path = function() return vim.fn.getcwd() end
local prefix = "<leader>t"
map("n", prefix .. "r", function() require("neotest").run.run() end, { desc = "Run test" })
map("n", prefix .. "d", function() require("neotest").run.run {vim.fn.expand("%"), strategy = "dap" } end, { desc = "Debug test" })
map("n", prefix .. "f", function() require("neotest").run.run(get_project_path()) end, { desc = "Run all tests in file" })
map("n", prefix .. "p", function() require("neotest").run.run(get_project_path()) end,
  { desc = "Run all tests in project" })
map("n", prefix .. "<CR>", function() require("neotest").summary.toggle() end, { desc = "Test Summary" })
map("n", prefix .. "o", function() require("neotest").output.open() end, { desc = "Output hover" })
map("n", prefix .. "O", function() require("neotest").output_panel.toggle() end, { desc = "Output window" })
map("n", "]T", function() require("neotest").jump.next() end, { desc = "Next test" })
map("n", "[T", function() require("neotest").jump.prev() end, { desc = "Previous test" })

map("n", "<leader>Tt", "<cmd>ExecutorRun<cr>", { desc = "Task Run" })
map("n", "<leader>Tr", "<cmd>ExecutorRun<cr>", { desc = "Task Run" })
map("n", "<leader>Tl", "<cmd>ExecutorShowDetail<cr>", { desc = "Task Detail" })
local watch_prefix = prefix .. "W"
map("n", watch_prefix .. "t", function() require("neotest").watch.toggle() end, { desc = "Toggle watch test" })
map("n", watch_prefix .. "f", function() require("neotest").watch.toggle(get_file_path()) end,
  { desc = "Toggle watch all test in file" })
map("n", watch_prefix .. "p", function() require("neotest").watch.toggle(get_project_path()) end,
  { desc = "Toggle watch all tests in project" })
map("n", watch_prefix .. "S", function() require("neotest").watch.stop() end, { desc = "Stop all watches" })

-- Better paste
-- remap "p" in visual mode to delete the highlighted text without overwriting your yanked/copied text, and then paste the content from the unnamed register.
map("v", "p", '"_dP', { silent = true })

-- Fix Spell checking
map("n", "z0", "1z=", {
  desc = "Fix world under cursor",
})

-- Close all fold except the current one.
map("n", "zv", "zMzvzz", {
  desc = "Close all folds except the current one",
})

-- Close current fold when open. Always open next fold.
map("n", "zj", "zcjzOzz", {
  desc = "Close current fold when open. Always open next fold.",
})

-- Close current fold when open. Always open previous fold.
map("n", "zk", "zckzOzz", {
  desc = "Close current fold when open. Always open previous fold.",
})

-- Select all text in buffer with Alt-a
map("n", "<C-A-a>", "ggVG", { noremap = true, silent = true, desc = "Select all" })

local create_command = vim.api.nvim_create_user_command
create_command("Markdown", function()
  vim.bo.filetype = "markdown"
  vim.schedule(function()
    vim.cmd.LspStart()
  end)
end, { desc = "markdown filetype" })
create_command("Yaml", function()
  vim.bo.filetype = "yaml"
  vim.schedule(function()
    vim.cmd.LspStart()
  end)
end, { desc = "markdown filetype" })
create_command("Json", function()
  vim.bo.filetype = "json"
  vim.schedule(function()
    vim.cmd.LspStart()
  end)
end, { desc = "json filetype" })
create_command("Sql", function()
  vim.bo.filetype = "sql"
  vim.schedule(function()
    vim.cmd.LspStart()
  end)
end, { desc = "sql filetype" })
create_command("Xml", function()
  vim.bo.filetype = "xml"
  vim.schedule(function()
    vim.cmd.LspStart()
  end)
end, { desc = "xml filetype" })
create_command("Md", function()
  vim.bo.filetype = "markdown"
end, { desc = "markdown filetype" })
-----
create_command("Run", function()
  vim.schedule(function()
    vim.cmd("RustLsp run")
  end)
end, { desc = "Run Rust" })
