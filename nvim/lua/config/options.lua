vim.g.have_nerd_font = true

vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

-- =============================================
-- Basic Editor Options
-- =============================================
vim.opt.number = true
vim.opt.relativenumber = true

-- Enable mouse mode
vim.opt.mouse = 'a'

-- Don't show mode (shown in statusline)
vim.opt.showmode = false

-- Sync clipboard between OS and Neovim
vim.schedule(function()
  vim.opt.clipboard = 'unnamedplus'
end)

-- Enable break indent
vim.opt.breakindent = true

-- Save undo history
vim.opt.undofile = true

-- Case-insensitive searching UNLESS \C or capital letters
vim.opt.ignorecase = true
vim.opt.smartcase = true

-- Keep signcolumn on by default
vim.opt.signcolumn = 'yes'

-- Decrease update time
vim.opt.updatetime = 250

-- Decrease mapped sequence wait time
vim.opt.timeoutlen = 300

-- Configure new splits
vim.opt.splitright = true
vim.opt.splitbelow = true

-- Whitespace characters display
vim.opt.list = true
vim.opt.listchars = { tab = '» ', trail = '·', nbsp = '␣' }

-- Tab settings
vim.opt.tabstop = 4
vim.opt.softtabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true

-- Preview substitutions live
vim.opt.inccommand = 'split'

-- Show cursor line
vim.opt.cursorline = true

-- Folding (native treesitter fold expression, 0.12+)
vim.opt.foldmethod = 'expr'
vim.opt.foldexpr = 'v:lua.vim.treesitter.foldexpr()'
vim.opt.foldenable = false
vim.opt.foldlevel = 99

-- Vertical lines
vim.opt.colorcolumn = '80,100,120'

-- Window border style for floating windows (new in 0.11)
vim.opt.winborder = 'single'

-- Enhanced diff options with inline diff (0.11+)
vim.opt.diffopt:append 'indent-heuristic'
pcall(function()
  vim.opt.diffopt:append 'inline:char'
end)

-- Improved scrollback maximum
vim.opt.scrollback = 100000

-- =============================================
-- Completion Options
-- =============================================

vim.opt.completeopt = { 'menu', 'menuone', 'noinsert', 'preview' }

-- =============================================
-- Performance Options
-- =============================================

-- shelltemp false for better performance
vim.opt.shelltemp = false

