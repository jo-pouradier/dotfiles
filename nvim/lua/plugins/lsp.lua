-- LSP Configuration for Neovim 0.12+
-- Server specs live in `<config>/lsp/<server>.lua` and are auto-discovered by
-- Neovim via runtimepath. This file only handles:
--   * Mason (server installation)
--   * Shared defaults via vim.lsp.config('*', ...)
--   * LspAttach buffer-local keymaps and features
--   * Diagnostic UI
--   * vim.lsp.enable() of the servers we want active

return {
  {
    'mason-org/mason.nvim',
    lazy = false,
    config = true,
  },
  {
    'mason-org/mason-lspconfig.nvim',
    lazy = false,
    dependencies = { 'mason-org/mason.nvim' },
    opts = {
      -- We manage enabling ourselves below.
      automatic_enable = false,
    },
  },
  {
    'WhoIsSethDaniel/mason-tool-installer.nvim',
    lazy = false,
    dependencies = { 'mason-org/mason.nvim' },
    opts = {
      ensure_installed = {
        -- LSP servers
        'lua-language-server',
        'pyright',
        'gopls',
        'vtsls',
        'typescript-language-server',
        'vue-language-server',
        'css-lsp',
        'html-lsp',
        'bash-language-server',
        'dockerfile-language-server',
        'docker-compose-language-service',
        'eslint-lsp',
        'typos-lsp',
        -- Java toolchain
        'jdtls',
        'java-debug-adapter',
        'java-test',
        'vscode-spring-boot-tools',
        -- Formatters
        'stylua',
        'prettier',
        'black',
        'isort',
        'shfmt',
        'jq',
      },
    },
  },
  {
    -- Lazydev for Lua development
    'folke/lazydev.nvim',
    ft = 'lua',
    opts = {
      library = {
        { path = 'luvit-meta/library', words = { 'vim%.uv' } },
      },
    },
  },
  {
    -- Fidget for LSP progress
    'j-hui/fidget.nvim',
    event = 'LspAttach',
    opts = {},
  },
  {
    -- nvim-cmp LSP source
    'hrsh7th/cmp-nvim-lsp',
    lazy = true,
  },
  {
    -- nvim-lspconfig in 0.12 is essentially a bundle of `lsp/<server>.lua`
    -- files Neovim discovers via runtimepath. We keep it as a fallback set
    -- of server defaults; our own `lsp/<server>.lua` files override it.
    -- This spec also owns the shared LSP wiring (capabilities, LspAttach,
    -- diagnostics, vim.lsp.enable).
    'neovim/nvim-lspconfig',
    event = { 'BufReadPre', 'BufNewFile' },
    dependencies = {
      'mason-org/mason.nvim',
      'mason-org/mason-lspconfig.nvim',
      'hrsh7th/cmp-nvim-lsp',
      'folke/lazydev.nvim',
    },
    config = function()
      -- ---------------------------------------------------------------
      -- Shared defaults applied to every server (vim.lsp.config('*', ...))
      -- ---------------------------------------------------------------
      local capabilities = vim.lsp.protocol.make_client_capabilities()
      local ok_cmp, cmp_lsp = pcall(require, 'cmp_nvim_lsp')
      if ok_cmp then
        capabilities = vim.tbl_deep_extend('force', capabilities, cmp_lsp.default_capabilities())
      end

      vim.lsp.config('*', {
        capabilities = capabilities,
        root_markers = { '.git' },
      })

      -- ---------------------------------------------------------------
      -- LspAttach: buffer-local keymaps & per-capability features
      -- ---------------------------------------------------------------
      vim.api.nvim_create_autocmd('LspAttach', {
        group = vim.api.nvim_create_augroup('CustomLspGroup', { clear = true }),
        callback = function(event)
          local map = function(keys, func, desc, mode)
            mode = mode or 'n'
            vim.keymap.set(mode, keys, func, { buffer = event.buf, desc = 'LSP: ' .. desc })
          end

          local function on_list(options)
            vim.fn.setqflist({}, ' ', options)
            vim.cmd.cfirst()
          end

          local client = vim.lsp.get_client_by_id(event.data.client_id)
          if not client then
            return
          end

          -- Core Navigation. 0.11+ ships default `grn`, `gra`, `gri`, `grr`,
          -- `gO`, `<C-s>` (insert) — we keep our older bindings on top.
          map('gd', function()
            vim.lsp.buf.definition { on_list = on_list }
          end, '[G]oto [D]efinition')
          map('gD', vim.lsp.buf.declaration, '[G]oto [D]eclaration')
          map('gr', require('telescope.builtin').lsp_references, '[G]oto [R]eferences')
          map('gI', require('telescope.builtin').lsp_implementations, '[G]oto [I]mplementation')
          map('<leader>D', require('telescope.builtin').lsp_type_definitions, 'Type [D]efinition')
          map('<leader>ds', require('telescope.builtin').lsp_document_symbols, '[D]ocument [S]ymbols')
          map('<leader>ws', require('telescope.builtin').lsp_dynamic_workspace_symbols, '[W]orkspace [S]ymbols')
          map('<leader>rn', vim.lsp.buf.rename, '[R]e[n]ame')
          map('<leader>ca', ':FzfLua lsp_code_actions<CR>', '[C]ode [A]ction', { 'n', 'x' })

          -- LSP-driven folding (new in 0.12).
          if client:supports_method(vim.lsp.protocol.Methods.textDocument_foldingRange) then
            local win = vim.api.nvim_get_current_win()
            vim.wo[win][0].foldexpr = 'v:lua.vim.lsp.foldexpr()'
            vim.wo[win][0].foldmethod = 'expr'
            if vim.lsp.foldtext then
              vim.wo[win][0].foldtext = 'v:lua.vim.lsp.foldtext()'
            end
          end

          -- Document highlighting on CursorHold.
          if client:supports_method(vim.lsp.protocol.Methods.textDocument_documentHighlight) then
            local highlight_augroup = vim.api.nvim_create_augroup('CustomLspHighlightGroup', { clear = false })
            vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI' }, {
              buffer = event.buf,
              group = highlight_augroup,
              callback = vim.lsp.buf.document_highlight,
            })
            vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
              buffer = event.buf,
              group = highlight_augroup,
              callback = vim.lsp.buf.clear_references,
            })
            vim.api.nvim_create_autocmd('LspDetach', {
              group = vim.api.nvim_create_augroup('CustomLspDetachGroup', { clear = true }),
              callback = function(event2)
                vim.lsp.buf.clear_references()
                vim.api.nvim_clear_autocmds { group = 'CustomLspHighlightGroup', buffer = event2.buf }
              end,
            })
          end

          -- Inlay hints toggle.
          if client:supports_method(vim.lsp.protocol.Methods.textDocument_inlayHint) then
            map('<leader>th', function()
              vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled { bufnr = event.buf })
            end, '[T]oggle Inlay [H]ints')
          end
        end,
      })

      -- ---------------------------------------------------------------
      -- Diagnostics
      -- ---------------------------------------------------------------
      if vim.g.have_nerd_font then
        local signs = { ERROR = '', WARN = '', INFO = '', HINT = '' }
        local diagnostic_signs = {}
        for type, icon in pairs(signs) do
          diagnostic_signs[vim.diagnostic.severity[type]] = icon
        end
        vim.diagnostic.config {
          signs = { text = diagnostic_signs },
          virtual_text = {
            prefix = '●',
            source = 'if_many',
          },
          float = {
            border = 'rounded',
            source = true,
            header = '',
            prefix = '',
          },
          severity_sort = true,
          update_in_insert = false,
        }
      end

      -- ---------------------------------------------------------------
      -- Enable servers (specs live in `<config>/lsp/<name>.lua`)
      -- ---------------------------------------------------------------
      vim.lsp.enable {
        'lua_ls',
        'pyright',
        'gopls',
        'vtsls',
        'vue_ls',
        'cssls',
        'html',
        'bashls',
        'dockerls',
        'docker_compose_language_service',
        'eslint',
        'typos_lsp',
      }
    end,
  },
  {
    -- Angular helpers (no LSP wiring; uses ng plugin commands)
    'joeveiga/ng.nvim',
    ft = { 'typescript', 'html' },
    config = function()
      local opts = { noremap = true, silent = true }
      local ng = require 'ng'
      vim.keymap.set('n', '<leader>gh', ng.goto_template_for_component, opts)
      vim.keymap.set('n', '<leader>gc', ng.goto_component_with_template_file, opts)
      vim.keymap.set('n', '<leader>gT', ng.get_template_tcb, opts)
    end,
  },
}
