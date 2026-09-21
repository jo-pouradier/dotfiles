local function get_sdkman_jdks()
  local sdkman_java_path = vim.fn.expand '~/.sdkman/candidates/java/'
  local jdks = {}

  local handle = io.popen('ls -1 ' .. sdkman_java_path)
  if not handle then
    return {}
  end

  local default_jdk = vim.fn.resolve(sdkman_java_path .. 'current') -- Follow symlink to default JDK

  for jdk_name in handle:lines() do
    local jdk_path = sdkman_java_path .. jdk_name
    table.insert(jdks, {
      name = jdk_name,
      path = jdk_path,
      default = (jdk_path == default_jdk), -- Check if it's the default JDK
    })
  end
  handle:close()

  return jdks
end

return {
  'mfussenegger/nvim-jdtls',
  dependencies = {
    'williamboman/mason.nvim',
    'neovim/nvim-lspconfig',
    'folke/which-key.nvim',
  },
  config = function()
    local jdtls = require 'jdtls'
    local home = os.getenv 'HOME'
    local workspace_path = home .. '/.local/share/lunarvim/jdtls-workspace/'
    local project_name = vim.fn.fnamemodify(vim.fn.getcwd(), ':p:h:t')
    local workspace_dir = workspace_path .. project_name

    local os_config = 'linux'
    if vim.fn.has 'mac' == 1 then
      os_config = 'mac'
    end

    local mason_path = vim.fn.glob(vim.fn.stdpath 'data' .. '/mason/')
    local bundles = {}
    vim.list_extend(bundles, vim.split(vim.fn.glob(mason_path .. 'packages/java-test/extension/server/*.jar'), '\n'))
    vim.list_extend(bundles, vim.split(vim.fn.glob(mason_path .. 'packages/java-debug-adapter/extension/server/com.microsoft.java.debug.plugin-*.jar'), '\n'))

    local config = {
      cmd = {
        'java',
        '-Declipse.application=org.eclipse.jdt.ls.core.id1',
        '-Dosgi.bundles.defaultStartLevel=4',
        '-Declipse.product=org.eclipse.jdt.ls.core.product',
        '-Dlog.protocol=true',
        '-Dlog.level=ALL',
        '-Xms2g',
        '--add-modules=ALL-SYSTEM',
        '--add-opens',
        'java.base/java.util=ALL-UNNAMED',
        '--add-opens',
        'java.base/java.lang=ALL-UNNAMED',
        '-jar',
        vim.fn.glob(home .. '/.local/share/nvim/mason/packages/jdtls/plugins/org.eclipse.equinox.launcher_*.jar'),
        '-configuration',
        home .. '/.local/share/nvim/mason/packages/jdtls/config_' .. os_config,
        '-data',
        workspace_dir,
      },
      root_dir = require('jdtls.setup').find_root { '.git', 'mvnw', 'gradlew', 'pom.xml', 'build.gradle' },
      capabilities = require('lspconfig').capabilities(),
      settings = {
        java = {
          signatureHelp = { enabled = true },
          eclipse = { downloadSources = true },
          configuration = {
            updateBuildConfiguration = 'interactive',
            runtimes = get_sdkman_jdks(),
          },
          maven = { downloadSources = true },
          implementationsCodeLens = { enabled = true },
          referencesCodeLens = { enabled = true },
          references = { includeDecompiledSources = true },
          inlayHints = { parameterNames = { enabled = 'all' } },
          format = { enabled = false },
        },
        extendedClientCapabilities = jdtls.extendedClientCapabilities,
      },
      init_options = { bundles = bundles },
      on_attach = function(client, bufnr)
        require('jdtls').setup_dap { hotcodereplace = 'auto' }
        require('lspconfig').on_attach(client, bufnr)
        local status_ok, jdtls_dap = pcall(require, 'jdtls.dap')
        if status_ok then
          jdtls_dap.setup_dap_main_class_configs()
        end
      end,
    }

    vim.api.nvim_create_autocmd('BufWritePost', {
      pattern = '*.java',
      callback = function()
        pcall(vim.lsp.codelens.refresh)
      end,
    })

    require('jdtls').start_or_attach(config)

    local which_key = require 'which-key'
    which_key.add({
      C = {
        name = 'Java',
        o = { "<Cmd>lua require'jdtls'.organize_imports()<CR>", 'Organize Imports' },
        v = { "<Cmd>lua require'jdtls'.extract_variable()<CR>", 'Extract Variable' },
        c = { "<Cmd>lua require'jdtls'.extract_constant()<CR>", 'Extract Constant' },
        t = { "<Cmd>lua require'jdtls'.test_nearest_method()<CR>", 'Test Method' },
        T = { "<Cmd>lua require'jdtls'.test_class()<CR>", 'Test Class' },
        u = { '<Cmd>JdtUpdateConfig<CR>', 'Update Config' },
      },
    }, { prefix = '<leader>' })

    which_key.add({
      C = {
        name = 'Java',
        v = { "<Esc><Cmd>lua require'jdtls'.extract_variable(true)<CR>", 'Extract Variable' },
        c = { "<Esc><Cmd>lua require'jdtls'.extract_constant(true)<CR>", 'Extract Constant' },
        m = { "<Esc><Cmd>lua require'jdtls'.extract_method(true)<CR>", 'Extract Method' },
      },
    }, { mode = 'v', prefix = '<leader>' })
  end,
}
