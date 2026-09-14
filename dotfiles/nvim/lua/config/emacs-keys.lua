local map = vim.keymap.set
local del = vim.keymap.del

map("n", "<A->>", "G", { desc = "Move cursor to bottom" })
map("n", "<A-<>", "gg", { desc = "Move cursor to top" })
map("i", "<A->>", "<C-o>G", { desc = "Move cursor to bottom" })
map("i", "<A-<>", "<C-o>gg", { desc = "Move cursor to top" })
map("n", "<C-Space>", "v", { desc = "Visual select" })
map("i", "<C-f>", "<Right>", { desc = "Move cursor forward" })
map("i", "<C-b>", "<Left>", { desc = "Move cursor backward" })
map("i", "<C-n>", "<Down>", { desc = "Move cursor down" })
map("i", "<C-p>", "<Up>", { desc = "Move cursor up" })
map("i", "<c-a>", "<ESC>^i", { desc = "Move to beginning of line" })
map("i", "<c-e>", "<End>", { desc = "Move to end of line" })
map("i", "<C-d>", "<Del>", { desc = "Delete character under cursor" })
map("i", "<C-h>", "<BS>", { desc = "Delete character before cursor" })
map("i", "<C-k>", "<C-o>C", { desc = "Delete to end of line" }) -- 不起作用
map("i", "<C-y>", "<C-r>+", { desc = "Paste from clipboard" })
map("i", "<C-/>", "<C-o>u", { desc = "Undo" })
map("i", "<C-s>", function()
  vim.cmd("stopinsert")
  require("flash").jump()
end, { desc = "Flash" })

map("n", "<C-x>o", "<Esc><cmd>Yazi<cr>", { desc = "Undo" })
map("n", "<C-x>e", function()
  -- 退出编辑模式
  require("snacks").explorer()
end, { desc = "Open Snacks Explorer" })

map("i", "<A-f>", "<Esc>ea", { desc = "Move cursor forward by word" })
map("i", "<A-b>", "<C-o>b", { desc = "Move cursor backward by word" })
map("i", "<A-d>", "<C-o>diw", { desc = "Delete word after cursor" })
map("i", "<A-Backspace>", "<C-o>db", { desc = "Delete word before cursor" })

map({ "i" }, "<C-x>0", "<C-o><C-w>q", { desc = "Close current window", silent = true, remap = true })
map({ "i" }, "<C-x>1", "<C-o><C-w>o", { desc = "Close other windows", silent = true })
map({ "i" }, "<C-x>2", "<C-o><C-W>s", { desc = "Split Window Below", remap = true })
map({ "i" }, "<C-x>3", "<C-o><C-W>v", { desc = "Split Window Right", remap = true })
map({ "n" }, "<C-x>0", "<C-w>q", { desc = "Close current window" })
map({ "n" }, "<C-x>1", "<C-w>o", { desc = "Close other windows", silent = true })
map({ "n" }, "<C-x>2", "<C-W>s", { desc = "Split Window Below", remap = true })
map({ "n" }, "<C-x>3", "<C-W>v", { desc = "Split Window Right", remap = true })
map({ "i", "n" }, "<C-x>h", "<esc>ggVG", { desc = "Select All" })

map({ "n" }, "<M-x>", function()
  require("snacks").picker.commands()
end, { desc = "Snacks Commands Picker" })

map({ "i", "n" }, "<C-x><C-d>", "<esc><cmd>Dired<cr>", { desc = "Open Dired" })
map({ "i", "n" }, "<C-x>d", "<esc><cmd>Dired<cr>", { desc = "Open Dired" })
map({ "n" }, "<C-x>d", "<esc><cmd>Dired<cr>", { desc = "Open Dired" })

local function augroup(name)
  return vim.api.nvim_create_augroup("lazyvim_" .. name, { clear = true })
end
vim.api.nvim_create_autocmd("FileType", {
  group = augroup("dired_keys"),
  pattern = "dired",
  callback = function(event)
    vim.schedule(function()
      map("n", "<localleader>c", "<cmd>DiredQuit<cr>", { buffer = event.buf, silent = true, desc = "No Op" })
      map("n", "q", "<cmd>DiredQuit<cr>", { buffer = event.buf, silent = true, desc = "Quit Dired" })
      map("n", "<enter>", "<cmd>DiredEnter<cr>", { buffer = event.buf, silent = true, desc = "Enter Dir" })
      map("n", "l", "<cmd>DiredEnter<cr>", { buffer = event.buf, silent = true, desc = "Enter Dir" })
      map("n", "h", "<cmd>DiredGoUp<cr>", { buffer = event.buf, silent = true, desc = "Up Dir" })
      map("n", "+", "<cmd>DiredCreate<cr>", { buffer = event.buf, silent = true, desc = "Create File/Dir" })
      map("n", "d", "<cmd>DiredDelete<cr>", { buffer = event.buf, silent = true, desc = "Delete File/Dir" })
      map("n", "x", "<cmd>DiredMove<cr>", { buffer = event.buf, silent = true, desc = "Move File/Dir" })
      map("n", "<Tab>", "<cmd>DiredMark<cr>", { buffer = event.buf, silent = true, desc = "Mark File/Dir" })
      map("n", "p", "<cmd>DiredPaste<cr>", { buffer = event.buf, silent = true, desc = "Paste File/Dir" })
      map("n", "c", "<cmd>DiredCopy<cr>", { buffer = event.buf, silent = true, desc = "Copy File/Dir" })
    end)
  end,
})
-- Move Lines
map("n", "<C-A-j>", "<cmd>execute 'move .+' . v:count1<cr>==", { desc = "Move Down" })
map("n", "<C-A-k>", "<cmd>execute 'move .-' . (v:count1 + 1)<cr>==", { desc = "Move Up" })
map("i", "<C-A-j>", "<esc><cmd>m .+1<cr>==gi", { desc = "Move Down" })
map("i", "<C-A-k>", "<esc><cmd>m .-2<cr>==gi", { desc = "Move Up" })
map("v", "<C-A-j>", ":<C-u>execute \"'<,'>move '>+\" . v:count1<cr>gv=gv", { desc = "Move Down" })
map("v", "<C-A-k>", ":<C-u>execute \"'<,'>move '<-\" . (v:count1 + 1)<cr>gv=gv", { desc = "Move Up" })

map("i", "<C-BS>", "<C-w>", { desc = "Backward delete word" })
