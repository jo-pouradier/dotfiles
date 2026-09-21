---@type vim.lsp.Config
return {
  cmd = { 'lua-language-server' },
  filetypes = { 'lua' },
  root_markers = { '.luarc.json', '.luarc.jsonc', 'stylua.toml', '.git' },
  settings = {
    Lua = {
      completion = { callSnippet = 'Replace' },
      hint = {
        enable = true,
        paramName = 'All',
        paramType = true,
      },
      diagnostics = {
        globals = { 'vim' },
      },
    },
  },
}
