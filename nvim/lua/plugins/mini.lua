return {
  'echasnovski/mini.nvim',
  config = function()
    -- Add/delete/replace surroundings (brackets, quotes, etc.)
    -- - saiw) - [S]urround [A]dd [I]nner [W]ord [)]Paren
    -- - sd'   - [S]urround [D]elete [']quotes
    -- - sr)'  - [S]urround [R]eplace [)] [']
    -- be fast when typing
    require('mini.surround').setup {}
    -- split or join object with gS
    require('mini.splitjoin').setup {}
    require('mini.pairs').setup {}
    -- Simple and easy statusline.
    local statusline = require 'mini.statusline'
    statusline.setup { use_icons = vim.g.have_nerd_font }
    ---@diagnostic disable-next-line: duplicate-set-field
    statusline.section_location = function()
      return '%2l:%-2v %p%%'
    end

    require('mini.cursorword').setup {}

  end,
}
