-- Pin tab/indent settings for Java buffers. Neovim's LSP layer reads these
-- (specifically `shiftwidth`/`tabstop`/`expandtab`) when it builds the
-- `FormattingOptions` for `textDocument/formatting` — and JDT.LS uses that
-- tabSize to OVERRIDE the formatter profile XML's `tabulation.size`. If a
-- built-in or distro ftplugin sets these to 8 for Java (a Vim tradition),
-- formatting silently produces 8-space indents regardless of the XML.
vim.opt_local.tabstop = 4
vim.opt_local.softtabstop = 4
vim.opt_local.shiftwidth = 4
vim.opt_local.expandtab = true

-- LSP-driven folding works nicely with Java method/javadoc folds; leave it
-- to the shared LspAttach in lua/plugins/lsp.lua to wire it up.

-- Buffer-local override for <leader>F. The global mapping routes through
-- conform.nvim with `lsp_format = 'fallback'`, which doesn't forward
-- `formatting_options` to the LSP request — so JDT.LS sees whatever default
-- tabSize neovim picked and may produce 8-space indents. Calling
-- vim.lsp.buf.format directly with pinned options keeps it consistent with
-- our BufWritePre save action.
vim.keymap.set('n', '<leader>F', function()
  pcall(function()
    require('jdtls').organize_imports()
  end)
  vim.lsp.buf.format {
    async = false,
    filter = function(c)
      return c.name == 'jdtls'
    end,
    formatting_options = { tabSize = 4, insertSpaces = true },
    timeout_ms = 3000,
  }
end, { buffer = true, desc = 'Java: Format (jdtls, pinned 4-space)' })
