vim.g.mapleader = ' '
vim.g.maplocalleader = '\\'

-- Avoid relying on the OS temp dir for the nvim runtime dir (used by
-- serverstart(), e.g. fzf-lua): it lives under /var/folders/.../T and can
-- occasionally fail to be (re)created, causing "Failed to start server".
do
  local runtime_dir = vim.fn.expand '~/.cache/nvim/run'
  vim.fn.mkdir(runtime_dir, 'p', '0700')
  vim.env.XDG_RUNTIME_DIR = runtime_dir
end

require 'config.lazy'
require 'config.options'
require 'config.keymaps'

-- Setup lazy.nvim
require('lazy').setup {
  spec = {
    { import = 'plugins.lsp' },
    { import = 'plugins' },
  },
  -- Configure any other settings here. See the documentation for more details.
  -- colorscheme that will be used when installing plugins.
  install = { colorscheme = { 'habamax' } },
  -- automatically check for plugin updates
  checker = { enabled = true },
  change_detection = { notify = false },
}

require 'config.colorscheme'
