---@type vim.lsp.Config
return {
  cmd = { 'vue-language-server', '--stdio' },
  filetypes = { 'vue' },
  root_markers = { 'vue.config.js', 'nuxt.config.js', 'package.json', '.git' },
  init_options = {
    vue = {
      hybridMode = false,
    },
  },
}
