if not vim.g.vscode then
  return {}
end -- don't do anything in non-vscode instances

vim.notify = require("vscode").notify
local enabled = {}
vim.tbl_map(function(plugin)
  enabled[plugin] = true
end, {
  -- core plugins
  "lazy.nvim",
  "nvim-treesitter",
  "nvim-ts-autotag",
  "nvim-treesitter-textobjects",
  "nvim-ts-context-commentstring",
  -- more known working
  "flash.nvim",
  "mini.ai",
  "mini.comment",
  "mini.move",
  "mini.pairs",
  "mini.surround",
  "ts-comments.nvim",
  -- feel free to open PRs to add more support!
})

local Config = require("lazy.core.config")
-- disable plugin update checking
Config.options.checker.enabled = false
Config.options.change_detection.enabled = false
-- replace the default `cond`
Config.options.defaults.cond = function(plugin)
  return enabled[plugin.name]
end

local map = vim.keymap.set
map("n", "<leader>qq", "<cmd>q<cr>", { desc = "Quit" })
map("n", "<localleader>w", function()
  require("vscode").action("workbench.action.files.save")
end, { desc = "Write Buffer", silent = true })
map("n", "<leader>fn", function()
  require("vscode").action("welcome.showNewFileEntries")
end, { desc = "New File" })

map("n", "<leader>\\", function()
  require("vscode").action("workbench.action.splitEditorDown")
end, { desc = "Split Window Below", remap = true })
map("n", "<leader>|", function()
  require("vscode").action("workbench.action.splitEditor")
end, { desc = "Split Window Right", remap = true })

map("n", "<C-h>", function()
  require("vscode").action("workbench.action.navigateLeft")
end, { desc = "Go to Left Window", remap = true })
--stylua: ignore
map("n", "<C-j>", function()
    require("vscode").action("workbench.action.navigateDown")
  end,
  { desc = "Go to Lower Window", remap = true })
--stylua: ignore
map("n", "<C-k>", function()
  require("vscode").action("workbench.action.navigateUp")
end, { desc = "Go to Upper Window", remap = true })
--stylua: ignore
map("n", "<C-l>", function()
    require("vscode").action("workbench.action.navigateRight")
  end,
  { desc = "Go to Right Window", remap = true })

map("n", "<c-/>", function()
  require("vscode").action("workbench.action.terminal.toggleTerminal")
end, { desc = "Terminal (Root Dir)" })
map("t", "<c-/>", function()
  require("vscode").action("workbench.action.terminal.toggleTerminal")
end, { desc = "Terminal (Root Dir)" })
map("n", "[b", "<Cmd>Tabprevious<CR>", { desc = "Prev Buffer" })
map("n", "]b", "<Cmd>Tabnext<CR>", { desc = "Next Buffer" })
map("n", "<localleader>c", "<cmd>Tabclose<cr>", { desc = "Delete Buffer and Window", silent = true })

map("n", "<leader>e", function()
  require("vscode").action("workbench.files.action.focusFilesExplorer")
end, { desc = "Explorer" })
map("n", "<leader>o", function()
  require("vscode").action("yazi-vscode.toggle")
end, { desc = "Yazi Explorer" })

map("v", "<", function()
  require("vscode").action("editor.action.outdentLines")
end)
map("v", ">", function()
  require("vscode").action("editor.action.indentLines")
end)

map("n", "]d", function()
  require("vscode").action("editor.action.marker.nextInFiles")
end, { desc = "Next Diagnostic" })
map("n", "[d", function()
  require("vscode").action("editor.action.marker.prevInFiles")
end, { desc = "Prev Diagnostic" })
map("n", "<leader>sC", function()
  require("vscode").action("workbench.action.showCommands")
end, { desc = "Commands" })
map("n", "<leader>fr", function()
  require("vscode").action("workbench.action.openRecent")
end, { desc = "Recent" })

map("n", "<leader>sw", function()
  require("vscode").action("workbench.action.findInFiles", { args = { query = vim.fn.expand("<cword>") } })
end, { desc = "Grep (Root Dir)" })
map("n", "<leader>sg", function()
  require("vscode").action("workbench.action.findInFiles", { args = { query = vim.fn.expand("<cword>") } })
end, { desc = "Grep (Root Dir)" })
map("n", "<leader>sq", function()
  require("vscode").action("workbench.action.quickFix")
end, { desc = "Quickfix List" })
map("n", "<leader><leader>", function()
  require("vscode").action("workbench.action.quickOpen")
end, { desc = "Quickfix List" })

map("n", "<leader>uC", function()
  require("vscode").action("workbench.action.selectTheme")
end, { desc = "Colorschemes" })
map("n", "<leader>n", function()
  require("vscode").action("notifications.showList")
end, { desc = "Notification History" })
map("n", "<localleader>f", function()
  require("vscode").action("editor.action.formatDocument")
end, { desc = "Format" })

map("n", "<leader>gg", function()
  require("vscode").action("lazygit.openLazygit")
end, { desc = "LazyGit" })

local maplsp = utils.mapkey_lsp

maplsp("gy", function()
  require("vscode").action("editor.action.showHover")
end, "Hover Symbol Details")
maplsp("gd", function()
  require("vscode").action("editor.action.revealDefinition")
end, "Defnition")
maplsp("gI", function()
  require("vscode").action("editor.action.goToImplementation")
end, "Implementations")
maplsp("gr", function()
  require("vscode").action("editor.action.goToReferences")
end, "Refereences Of Current Symbol")
maplsp("gD", function()
  require("vscode").action("editor.action.goToTypeDefinition")
end, "Type Defnition")

maplsp("<Leader>cs", function()
  require("vscode").action("workbench.action.gotoSymbol")
end, "Symbols")
maplsp("<Leader>cS", function()
  require("vscode").action("workbench.action.showAllSymbols")
end, "Workspace Symbols")

maplsp("gR", function()
  require("vscode").action("editor.action.rename")
end, "Rename Current Symbol")
---@type LazySpec
return {
  -- disable treesitter highlighting
  { "nvim-treesitter/nvim-treesitter", opts = { highlight = { enable = false } } },
}
