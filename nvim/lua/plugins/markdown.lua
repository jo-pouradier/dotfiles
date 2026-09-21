return {
  'mzlogin/vim-markdown-toc',
  {
    'MeanderingProgrammer/render-markdown.nvim',
    dependencies = { 'nvim-treesitter/nvim-treesitter', 'echasnovski/mini.nvim' }, -- if you use the mini.nvim suite
    -- dependencies = { 'nvim-treesitter/nvim-treesitter', 'nvim-tree/nvim-web-devicons' }, -- if you prefer nvim-web-devicons
    config = function(_, opts)
      require('render-markdown').setup(opts)
      local ok, cmp = pcall(require, 'cmp')
      if ok then
        cmp.setup.filetype('markdown', {
          sources = cmp.config.sources({
            { name = 'render-markdown' },
          }, {
            { name = 'buffer' },
          }),
        })
      end
    end,
    ---@type render.md.UserConfig
    opts = {
      completions = { lsp = { enabled = true } },
    },
  },
}
