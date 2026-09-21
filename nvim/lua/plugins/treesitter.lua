-- Treesitter Configuration for Neovim 0.12+
-- Uses nvim-treesitter main branch (incompatible rewrite, requires nvim 0.12)
-- Highlighting queries come from this plugin; nvim handles the actual rendering
-- Use :InspectTree and :EditQuery for debugging (built-in since 0.9)

return {
  {
    'nvim-treesitter/nvim-treesitter',
    branch = 'main',
    lazy = false, -- main branch does not support lazy-loading
    build = ':TSUpdate',
    config = function()
      local parsers = {
        'lua',
        'sql',
        'markdown',
        'markdown_inline',
        'python',
        'java',
        'javascript',
        'typescript',
        'html',
        'css',
        'bash',
        'json',
        'yaml',
        'toml',
        'vim',
        'vimdoc',
        'go',
        'vue',
        'dockerfile',
      }

      local ts = require 'nvim-treesitter'

      -- Install missing parsers on startup
      local installed = ts.get_installed()
      local to_install = {}
      for _, parser in ipairs(parsers) do
        if not vim.tbl_contains(installed, parser) then
          table.insert(to_install, parser)
        end
      end
      if #to_install > 0 then
        ts.install(to_install)
      end

      -- Enable treesitter highlighting for all normal buffers
      -- (nvim 0.12 handles common filetypes natively, this covers the rest)
      vim.api.nvim_create_autocmd('FileType', {
        callback = function(args)
          local buf = args.buf
          if vim.bo[buf].buftype ~= '' then
            return
          end
          local ok, stats = pcall(vim.uv.fs_stat, vim.api.nvim_buf_get_name(buf))
          if ok and stats and stats.size > 5 * 1024 * 1024 then
            return
          end
          pcall(vim.treesitter.start, buf)
        end,
      })
    end,
  },
}
