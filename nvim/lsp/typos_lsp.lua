---@type vim.lsp.Config
return {
  cmd = { 'typos-lsp' },
  filetypes = { 'markdown', 'text', 'gitcommit' },
  root_markers = { '.git' },
  init_options = {
    diagnosticSeverity = 'Warning',
  },
}
