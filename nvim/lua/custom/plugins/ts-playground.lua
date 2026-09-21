return {
  'nvim-treesitter/playground',
  cmd = { 'TSPlaygroundToggle', 'TSHighlightCapturesUnderCursor' },
  keys = {
    { '<leader>tp', '<cmd>TSPlaygroundToggle<CR>', desc = 'Toggle TS Playground' },
  },
  config = function()
    vim.keymap.set('n', '<leader>tp', '<cmd>TSPlaygroundToggle<CR>', { desc = 'Toggle TS Playground' })
  end,
}
