return {
  'tpope/vim-sleuth',
  {
    'stevearc/conform.nvim',
    -- event = { 'BufWritePre' },
    cmd = { 'ConformInfo' },
    keys = {
      {
        '<leader>F',
        function()
          require('conform').format { async = true, lsp_format = 'fallback' }
        end,
        mode = '',
        desc = '[F]ormat buffer',
      },
    },
    opts = {
      notify_on_error = true,
      -- format_on_save = function(bufnr)
      --
      --   local disable_filetypes = { c = true, cpp = true, java = true, sql = true }
      --   local lsp_format_opt
      --   if disable_filetypes[vim.bo[bufnr].filetype] then
      --     lsp_format_opt = 'never'
      --   else
      --     lsp_format_opt = 'fallback'
      --   end
      --   return {
      --     timeout_ms = 500,
      --     lsp_format = lsp_format_opt,
      --   }
      -- end,
      format_on_save = false,
      formatters_by_ft = {
        lua = { 'stylua' },
        python = { 'black', 'isort' },
        javascript = { 'eslint', 'prettierd', 'prettier', stop_after_first = true },
        typescript = { 'eslint', 'prettierd', 'prettier', stop_after_first = true },
        sh = { 'shfmt' },
        bash = { 'shfmt' },
        json = { 'jq' },
        jsonc = { 'jq' },
        -- java = { 'google-java-format' },
      },
      formatters = {
        ['google-java-format'] = {
          prepend_args = { '--aosp' }, -- Ensure 4-space indentation
        },
      },
    },
  },
}
