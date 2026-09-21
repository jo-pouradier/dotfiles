-- Improve performance of editing big files
return {
  'LunarVim/bigfile.nvim',
  event = 'BufReadPre',
  opts = {
    filesize = 2, -- size of the file in MiB, the plugin round file sizes to the closest MiB
    pattern = { '*' },
    features = { -- features to disable if necessary
      -- 'indent_blankline',
      -- 'illuminate',
      -- 'lsp',
      -- 'treesitter',
      -- 'syntax',
      -- 'matchparen',
      -- 'vimopts',
      -- 'filetype',
    },
  },
  config = function(_, opts)
    require('bigfile').setup(opts)
  end,
}
