return { -- Fuzzy Finder (files, lsp, etc)
  'nvim-telescope/telescope.nvim',
  event = 'VimEnter',
  -- Use master branch for Neovim 0.11+ compatibility (0.1.x uses deprecated ft_to_lang)
  dependencies = {
    'sharkdp/fd',
    {
      'junegunn/fzf',
      build = './install --bin', -- this is what fzf#install() does
    },
    {
      'junegunn/fzf.vim',
      dependencies = { 'junegunn/fzf' },
    },
    'nvim-lua/plenary.nvim',
    { -- If encountering errors, see telescope-fzf-native README for installation instructions
      'nvim-telescope/telescope-fzf-native.nvim',

      -- `build` is used to run some command when the plugin is installed/updated.
      -- This is only run then, not every time Neovim starts up.
      build = 'make',

      -- `cond` is a condition used to determine whether this plugin should be
      -- installed and loaded.
      cond = function()
        return vim.fn.executable 'make' == 1
      end,
    },
    { 'nvim-telescope/telescope-ui-select.nvim' },
    { 'nvim-tree/nvim-web-devicons', enabled = vim.g.have_nerd_font },
    'andrewberty/telescope-themes',
  "radyz/telescope-gitsigns",
  },
  config = function()
    require('telescope').setup {
      defaults = {
        -- Show filename first, then the (possibly truncated) directory.
        -- Great for deep Java package paths.
        path_display = {
          filename_first = { reverse_directories = false },
          truncate = 3, -- keep the last 3 chars worth of room for the right pane
        },
        dynamic_preview_title = true,
        mappings = {
          i = { -- inside telescope
            ['<C-h>'] = 'which_key',
          },

          n = { -- inside telescope
            ['<C-h>'] = 'which_key',
          },
        },
        -- NOTE: these are Lua patterns, not globs. `**/lib/` does NOT mean
        -- "anywhere"; it matches the literal char `*` plus `/lib/`, which is
        -- effectively the same as `/lib/`. That blanket-matches Java package
        -- paths like `src/main/java/com/foo/lib/Foo.java` and hides the file.
        -- Keep patterns anchored to project-root build outputs only.
        file_ignore_patterns = {
          '%.git/',
          'node_modules/',
          '^target/', -- Maven output (project root only)
          '/target/classes/',
          '/target/test%-classes/',
          '/target/generated%-sources/',
          '^build/', -- Gradle output (project root only)
          '/build/classes/',
          '/build/libs/',
          '/build/tmp/',
          '%.class$',
        },
      },
      -- pickers = {}
      extensions = {
        fzf = {},
        ['ui-select'] = {
          require('telescope.themes').get_dropdown(),
        },
        themes = {
          ignore = {},
          enable_previewer = true,
          enable_live_preview = true,
          layout_config = {
            horizontal = {
              width = 0.8,
              height = 0.9,
            },
          },
          persist = {
            enabled = true,
            path = vim.fn.stdpath 'config' .. '/lua/config/colorscheme.lua',
          },
          mappings = {
            down = '<C-n>',
            up = '<C-p>',
            accept = '<CR>',
          },
        },
      },
    }

    require('telescope').load_extension 'fzf'
    require('telescope').load_extension 'themes'
    require('telescope').load_extension 'ui-select'

    local builtin = require 'telescope.builtin'
    vim.keymap.set('n', '<leader>sH', builtin.help_tags, { desc = '[S]earch [H]elp' })
    vim.keymap.set('n', '<leader>sk', builtin.keymaps, { desc = '[S]earch [K]eymaps' })
    vim.keymap.set('n', '<leader>sf', builtin.find_files, { desc = '[S]earch [F]iles' })
    vim.keymap.set('n', '<leader>ss', builtin.lsp_workspace_symbols, { desc = '[S]earch [S]elect Telescope' })
    vim.keymap.set('n', '<leader>sS', builtin.spell_suggest, { desc = '[S]earch [S]pell suggestions' })
    vim.keymap.set('n', '<C-s>', builtin.spell_suggest, { desc = '[S]earch [S]pell suggestions' })
    vim.keymap.set('n', '<leader>sb', builtin.builtin, { desc = '[S]earch [B]uiltin Telescope' })
    vim.keymap.set('n', '<leader>sw', builtin.grep_string, { desc = '[S]earch current [W]ord' })
    vim.keymap.set('n', '<leader>sg', builtin.live_grep, { desc = '[S]earch by [G]rep' })
    vim.keymap.set('n', '<leader>sd', builtin.diagnostics, { desc = '[S]earch [D]iagnostics' })
    vim.keymap.set('n', '<leader>sr', builtin.registers, { desc = '[S]earch [R]egisters' })
    vim.keymap.set('n', '<leader>sq', builtin.quickfix, { desc = '[S]earch [Q]uickfix' })
    vim.keymap.set('n', '<leader>s.', builtin.oldfiles, { desc = '[S]earch Recent Files ("." for repeat)' })
    vim.keymap.set('n', '<leader>sT', ':Telescope themes<CR>', { desc = '[S]earch [T]hemes', silent = true })
    vim.keymap.set('n', '<leader>sc', ':TodoTelescope<CR>', { desc = '[S]earch all hilighted [C]omments' })
    vim.keymap.set('n', '<leader><leader>', function()
      builtin.buffers { sort_lastused = true, sort_mru = true, ignore_current_buffer = true }
    end, { desc = '[ ] Find existing buffers' })

    vim.keymap.set('n', '<leader>s/', function()
      builtin.live_grep {
        grep_open_files = true,
        prompt_title = 'Live Grep in Open Files',
      }
    end, { desc = '[S]earch [/] in Open Files' })

    -- Shortcut for searching your Neovim configuration files
    vim.keymap.set('n', '<leader>sn', function()
      builtin.find_files { cwd = vim.fn.stdpath 'config' }
    end, { desc = '[S]earch [N]eovim files' })
  end,
}
