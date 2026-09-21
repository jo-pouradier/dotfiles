-- Keymaps Configuration for Neovim 0.11+
-- Includes all new keymaps and features

vim.api.nvim_create_augroup('CustomAutocmd', { clear = true })

-- =============================================
-- Terminal Autocmds
-- =============================================
vim.api.nvim_create_autocmd('User', {
  group = 'CustomAutocmd',
  pattern = '<term>',
  callback = function(events)
    print('New buffer: ' .. vim.fn.expand '<afile>' .. ' super nice')
    local ft = vim.api.nvim_get_option_value('filetype', { buf = events.buf })
    print('FileType: ' .. ft .. ' ok')
  end,
})

vim.api.nvim_create_autocmd('TermOpen', {
  group = 'CustomAutocmd',
  pattern = '*',
  command = 'startinsert',
})

-- =============================================
-- Navigation
-- =============================================
vim.keymap.set('n', 'n', 'nzz')
vim.keymap.set('n', 'N', 'Nzz')

-- Terminal mode mappings
vim.keymap.set('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })
vim.keymap.set('t', '<C-x>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })
vim.keymap.set('t', '<C-d>', '<C-d><CR>', { desc = 'Kill terminal mode' })

-- =============================================
-- Yank Highlight (using 0.11 vim.hl.on_yank)
-- =============================================
vim.api.nvim_create_autocmd('TextYankPost', {
  group = vim.api.nvim_create_augroup('CustomYankGroup', { clear = true }),
  callback = function(_)
    vim.hl.on_yank { higroup = 'Visual', timeout = 500 }
  end,
})
vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>')

-- =============================================
-- Lua Specific
-- =============================================
vim.keymap.set('v', '<leader>x', ':lua<CR>', { desc = 'Execute selected lua code' })

-- =============================================
-- Buffer Operations
-- =============================================
vim.keymap.set('n', '<leader>q', ':bd<Enter>', { desc = 'e[X]it buffer', silent = true })

-- =============================================
-- Line Operations
-- =============================================
vim.keymap.set('n', 'D', 'dd', { desc = '[D]elete entire line', silent = true })

-- =============================================
-- Diagnostic Keymaps
-- =============================================
vim.keymap.set('n', '<leader>de', vim.diagnostic.open_float, { desc = '[D]iagnostic [E]rror messages' })
vim.keymap.set('n', '<leader>dq', vim.diagnostic.setloclist, { desc = '[D]iagnostic [Q]uickfix list' })
vim.keymap.set('n', '<leader>dn', function()
  vim.diagnostic.jump { count = -1, float = true }
end, { desc = '[D]iagnostic Go to [n]ext error' })
vim.keymap.set('n', '<leader>dN', function()
  vim.diagnostic.jump { count = 1, float = true }
end, { desc = '[D]iagnostic Go to [N] Previous error' })

-- =============================================
-- Tab Navigation
-- =============================================
vim.keymap.set('n', '<tab>', 'gt', { desc = 'go to next tab' })
vim.keymap.set('n', '<S-tab>', 'gT', { desc = 'go to previous tab' })

-- =============================================
-- Split Navigation and Resizing
-- =============================================
vim.keymap.set('n', '<M-<>', '<C-w>5<', { desc = 'split width -' })
vim.keymap.set('n', '<M->>', '<C-w>5>', { desc = 'split width +' })
vim.keymap.set('n', '<M-=>', '<C-w>5-', { desc = 'split height -' })
vim.keymap.set('n', '<M-+>', '<C-w>5+', { desc = 'split height +' })
vim.keymap.set('n', '<C-h>', '<C-w><C-h>', { desc = 'Move focus to the left window' })
vim.keymap.set('n', '<C-l>', '<C-w><C-l>', { desc = 'Move focus to the right window' })
vim.keymap.set('n', '<C-j>', '<C-w><C-j>', { desc = 'Move focus to the lower window' })
vim.keymap.set('n', '<C-k>', '<C-w><C-k>', { desc = 'Move focus to the upper window' })

-- =============================================
-- Comment Toggle (using Comment.api)
-- =============================================
vim.keymap.set('n', '<leader>/', function()
  require('Comment.api').toggle.linewise.current()
end, { desc = '[/] Comment' })
vim.keymap.set('x', '<leader>/', function()
  local esc = vim.api.nvim_replace_termcodes('<ESC>', true, false, true)
  vim.api.nvim_feedkeys(esc, 'nx', false)
  require('Comment.api').toggle.linewise(vim.fn.visualmode())
end)

-- =============================================
-- Quick Actions
-- =============================================

-- Better paste in visual mode (don't replace register)
vim.keymap.set('x', 'p', '"_dP', { desc = 'Paste without yanking replaced text' })

-- Better indenting (stay in visual mode)
vim.keymap.set('v', '<', '<gv', { desc = 'Indent left' })
vim.keymap.set('v', '>', '>gv', { desc = 'Indent right' })

-- =============================================
-- URL Opening (gx)
-- =============================================
-- gx opens URLs under cursor (vim.ui.open is built-in in 0.11)
vim.keymap.set('n', 'gx', function()
  local word = vim.fn.expand '<cWORD>'
  if word:match '^https?://' then
    vim.ui.open(word)
  else
    vim.cmd 'normal! gx'
  end
end, { desc = 'Open URL under cursor' })

-- =============================================
-- Quickfix/Location List Navigation
-- =============================================
vim.keymap.set('n', '<leader>cn', ':cnext<CR>', { desc = 'Quickfix [N]ext' })
vim.keymap.set('n', '<leader>cp', ':cprev<CR>', { desc = 'Quickfix [P]rev' })
vim.keymap.set('n', '<leader>co', ':copen<CR>', { desc = 'Quickfix [O]pen' })
vim.keymap.set('n', '<leader>cc', ':cclose<CR>', { desc = 'Quickfix [C]lose' })

vim.keymap.set('n', '<leader>ln', ':lnext<CR>', { desc = 'Location [N]ext' })
vim.keymap.set('n', '<leader>lp', ':lprev<CR>', { desc = 'Location [P]rev' })
vim.keymap.set('n', '<leader>lo', ':lopen<CR>', { desc = 'Location [O]pen' })
vim.keymap.set('n', '<leader>lc', ':lclose<CR>', { desc = 'Location [C]lose' })
