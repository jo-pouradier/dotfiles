-- Java / Spring Boot setup for Neovim 0.12+
--
-- Pieces
--   * mfussenegger/nvim-jdtls   — drives Eclipse JDT.LS (the actual Java LSP)
--   * JavaHello/spring-boot.nvim — supplies Spring Boot LS jdtls bundles
--   * Mason packages (declared in lua/plugins/lsp.lua):
--       jdtls, java-debug-adapter, java-test, spring-boot-tools
--   * Optional Lombok javaagent (auto-detected, see lombok_jar() below)
--
-- Build systems
--   Both Maven and Gradle are supported out of the box by JDT.LS — we just
--   list their root markers so single-module and multi-module projects start
--   in the right place. JDK runtimes for each LTS are pulled from SDKMAN!.

local function get_sdkman_jdks()
  local sdkman_java_path = vim.fn.expand '~/.sdkman/candidates/java/'
  if vim.fn.isdirectory(sdkman_java_path) == 0 then
    return {}
  end

  local jdks = {}
  local default_jdk = vim.fn.resolve(sdkman_java_path .. 'current')
  local handle = io.popen('ls -1 ' .. sdkman_java_path)
  if not handle then
    return {}
  end

  for jdk_name in handle:lines() do
    if jdk_name ~= 'current' then
      local jdk_path = sdkman_java_path .. jdk_name
      -- Heuristic: map an SDKMAN! identifier like "21.0.2-tem" to a JDT.LS
      -- runtime name like "JavaSE-21". JDT.LS matches runtimes by this name
      -- when a module declares `java.specification.version`.
      local major = jdk_name:match '^(%d+)'
      local name = major and ('JavaSE-' .. major) or jdk_name
      table.insert(jdks, {
        name = name,
        path = jdk_path,
        default = (jdk_path == default_jdk),
      })
    end
  end
  handle:close()

  return jdks
end

-- Look for a Lombok jar in a few well-known spots. Returns nil if not found.
local function lombok_jar()
  local candidates = {
    vim.fn.stdpath 'data' .. '/lombok.jar',
    vim.fn.stdpath 'data' .. '/mason/packages/jdtls/lombok.jar',
    vim.fn.expand '~/.local/share/eclipse/lombok.jar',
  }
  for _, p in ipairs(candidates) do
    if vim.fn.filereadable(p) == 1 then
      return p
    end
  end
end

return {
  'mfussenegger/nvim-jdtls',
  dependencies = {
    'mason-org/mason.nvim',
    'folke/which-key.nvim',
    -- Debugger — required by `jdtls.setup_dap()` and `jdtls.dap.*`.
    {
      'mfussenegger/nvim-dap',
      dependencies = {
        { 'rcarriga/nvim-dap-ui', dependencies = { 'nvim-neotest/nvim-nio' } },
        'theHamsta/nvim-dap-virtual-text',
      },
      config = function()
        local dap, dapui = require 'dap', require 'dapui'
        pcall(dapui.setup)
        pcall(function()
          require('nvim-dap-virtual-text').setup {}
        end)
        dap.listeners.before.attach.dapui_config = function()
          dapui.open()
        end
        dap.listeners.before.launch.dapui_config = function()
          dapui.open()
        end
        dap.listeners.before.event_terminated.dapui_config = function()
          dapui.close()
        end
        dap.listeners.before.event_exited.dapui_config = function()
          dapui.close()
        end

        vim.keymap.set('n', '<leader>db', dap.toggle_breakpoint, { desc = 'DAP: Toggle Breakpoint' })
        vim.keymap.set('n', '<leader>dc', dap.continue, { desc = 'DAP: Continue' })
        vim.keymap.set('n', '<leader>di', dap.step_into, { desc = 'DAP: Step Into' })
        vim.keymap.set('n', '<leader>do', dap.step_over, { desc = 'DAP: Step Over' })
        vim.keymap.set('n', '<leader>dO', dap.step_out, { desc = 'DAP: Step Out' })
        vim.keymap.set('n', '<leader>dt', dap.terminate, { desc = 'DAP: Terminate' })
        vim.keymap.set('n', '<leader>du', function()
          dapui.toggle()
        end, { desc = 'DAP: Toggle UI' })
      end,
    },
    -- Spring Boot LS — provides its jdtls bundles via
    -- `require('spring_boot').java_extensions()`.
    {
      'JavaHello/spring-boot.nvim',
      ft = { 'java', 'yaml' },
      dependencies = { 'mfussenegger/nvim-jdtls' },
      opts = {
        ls_path = vim.fn.stdpath 'data' .. '/mason/packages/vscode-spring-boot-tools/extension',
        java_cmd = 'java',
        log_file = vim.fn.stdpath 'cache' .. '/spring-boot.log',
        jdt_extensions_level = 'ALL', -- include Spring Boot jdtls extension
      },
    },
  },
  ft = { 'java' },
  config = function()
    local jdtls = require 'jdtls'
    local home = os.getenv 'HOME'
    local mason_path = vim.fn.stdpath 'data' .. '/mason/'
    local workspace_root = home .. '/.local/share/nvim/jdtls-workspace/'

    local os_config = vim.fn.has 'mac' == 1 and 'mac' or (vim.fn.has 'win32' == 1 and 'win' or 'linux')

    -- ----------------------------------------------------------------
    -- Bundles: debug + test + spring-boot extensions
    -- ----------------------------------------------------------------
    local bundles = {}
    vim.list_extend(bundles, vim.split(vim.fn.glob(mason_path .. 'packages/java-test/extension/server/*.jar', true), '\n', { trimempty = true }))
    vim.list_extend(
      bundles,
      vim.split(
        vim.fn.glob(mason_path .. 'packages/java-debug-adapter/extension/server/com.microsoft.java.debug.plugin-*.jar', true),
        '\n',
        { trimempty = true }
      )
    )
    local ok_spring, spring_boot = pcall(require, 'spring_boot')
    if ok_spring then
      vim.list_extend(bundles, spring_boot.java_extensions())
    end

    -- Build the launcher command. Lombok agent is opt-in (only if a jar exists).
    local function build_cmd(workspace_dir)
      local cmd = {
        'java',
        '-Declipse.application=org.eclipse.jdt.ls.core.id1',
        '-Dosgi.bundles.defaultStartLevel=4',
        '-Declipse.product=org.eclipse.jdt.ls.core.product',
        '-Dlog.protocol=true',
        '-Dlog.level=ALL',
        -- Memory: 2g initial / 4g max suits most Maven/Gradle Spring apps.
        '-Xms2g',
        '-Xmx4g',
        '--add-modules=ALL-SYSTEM',
        '--add-opens',
        'java.base/java.util=ALL-UNNAMED',
        '--add-opens',
        'java.base/java.lang=ALL-UNNAMED',
      }
      local lombok = lombok_jar()
      if lombok then
        table.insert(cmd, '-javaagent:' .. lombok)
      end
      vim.list_extend(cmd, {
        '-jar',
        vim.fn.glob(mason_path .. 'packages/jdtls/plugins/org.eclipse.equinox.launcher_*.jar'),
        '-configuration',
        mason_path .. 'packages/jdtls/config_' .. os_config,
        '-data',
        workspace_dir,
      })
      return cmd
    end

    -- Root markers (Maven first, then Gradle, with wrappers as final hints).
    local java_markers = {
      'pom.xml',
      'mvnw',
      'settings.gradle',
      'settings.gradle.kts',
      'build.gradle',
      'build.gradle.kts',
      'gradlew',
      '.git',
    }

    local function attach_jdtls()
      local root_dir = vim.fs.root(0, java_markers)
      if not root_dir then
        return
      end

      local project_name = vim.fn.fnamemodify(root_dir, ':p:h:t')
      local workspace_dir = workspace_root .. project_name

      local config = {
        cmd = build_cmd(workspace_dir),
        root_dir = root_dir,
        init_options = { bundles = bundles },
        settings = {
          java = {
            -- ------------- JDK / runtime -------------
            jdk = { auto_install = false },
            configuration = {
              updateBuildConfiguration = 'interactive',
              runtimes = get_sdkman_jdks(),
            },

            -- ------------- Maven & Gradle -------------
            maven = {
              downloadSources = true,
              updateSnapshots = false,
            },
            gradle = {
              enabled = true,
              wrapper = { enabled = true },
            },
            import = {
              maven = { enabled = true },
              gradle = { enabled = true, wrapper = { enabled = true } },
              exclusions = {
                '**/node_modules/**',
                '**/.metadata/**',
                '**/archetype-resources/**',
                '**/META-INF/maven/**',
              },
            },

            -- ------------- Editing experience -------------
            signatureHelp = { enabled = true, description = { enabled = true } },
            contentProvider = { preferred = 'fernflower' },
            references = { includeDecompiledSources = true },
            eclipse = { downloadSources = true },
            implementationsCodeLens = { enabled = true },
            referencesCodeLens = { enabled = true },
            inlayHints = { parameterNames = { enabled = 'all' } },
            symbols = { includeSourceMethodDeclarations = true },

            -- ------------- Code generation -------------
            -- IntelliJ-style import wildcard thresholds.
            sources = {
              organizeImports = {
                starThreshold = 9999,
                staticStarThreshold = 999,
              },
            },
            codeGeneration = {
              toString = {
                template = '${object.className}{${member.name()}=${member.value}, ${otherMembers}}',
              },
              useBlocks = true,
              hashCodeEquals = { useJava7Objects = true },
              generateComments = true,
            },
            completion = {
              favoriteStaticMembers = {
                'org.hamcrest.MatcherAssert.assertThat',
                'org.hamcrest.Matchers.*',
                'org.hamcrest.CoreMatchers.*',
                'org.junit.jupiter.api.Assertions.*',
                'org.junit.Assert.*',
                'org.mockito.Mockito.*',
                'org.mockito.ArgumentMatchers.*',
                'java.util.Objects.requireNonNull',
                'java.util.Objects.requireNonNullElse',
              },
              -- Import groups (one entry = one group, blank line between).
              -- `""` is the catch-all (com.*, org.*, …); `"#"` is static.
              -- Order matches the Mirakl/Spring convention: third-party →
              -- JDK → static.
              importOrder = { '', 'java', 'javax', '#' },
              guessMethodArguments = true,
            },
            -- IntelliJ-style formatting via an Eclipse XML profile shipped
            -- with this config. To override, drop your own export at the same
            -- path (File → Settings → Editor → Code Style → Java → "Export…
            -- → Eclipse XML Profile" in IntelliJ).
            -- JDT.LS expects a URL (file://…) here. A bare path is treated as
            -- relative to the workspace, silently falls back to the built-in
            -- Eclipse profile (which uses 8-space tabs → broken indents).
            format = {
              enabled = true,
              settings = {
                url = 'file://' .. vim.fn.stdpath 'config' .. '/formatters/intellij-java-style.xml',
                profile = 'IntelliJStyle',
              },
              insertSpaces = true,
              tabSize = 4,
              onType = { enabled = true },
            },
            -- Save-action: organize imports on save (cheap, useful in Spring).
            saveActions = { organizeImports = true },
          },
          -- ------------- Spring Boot LS -------------
          -- These keys are consumed by the Spring Boot tools server when its
          -- jdtls extension is loaded (via spring-boot.nvim).
          ['spring-boot'] = {
            ls = {
              problem = {
                application_properties = { ['unknown-property'] = 'WARNING' },
                boot2 = { ['unsupported-feature'] = 'INFO' },
                boot3 = { ['unsupported-feature'] = 'INFO' },
              },
            },
          },
        },
        flags = { allow_incremental_sync = true },
        capabilities = vim.lsp.protocol.make_client_capabilities(),
        on_attach = function(client, bufnr)
          -- DAP integration (relies on java-debug-adapter bundle above).
          pcall(function()
            require('jdtls').setup_dap { hotcodereplace = 'auto', config_overrides = {} }
          end)
          pcall(function()
            require('jdtls.dap').setup_dap_main_class_configs()
          end)

          -- Inlay hints + code-lens-as-virtual-lines (0.12 default for codelens).
          if client:supports_method(vim.lsp.protocol.Methods.textDocument_inlayHint) then
            vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })
          end
          if client:supports_method(vim.lsp.protocol.Methods.textDocument_codeLens) then
            -- NOTE: pass the function and args separately; `pcall(f(x))` would
            -- call f first and then pcall whatever it returned (often nil),
            -- giving "bad argument #1 to 'pcall' (value expected)".
            pcall(vim.lsp.codelens.enable, true, { bufnr = bufnr })
          end

        end,
        -- Extended client capabilities + Spring Boot helpers.
        ---@diagnostic disable-next-line: missing-fields
      }

      -- Merge cmp capabilities if available (matches the rest of our LSPs).
      local ok_cmp, cmp_lsp = pcall(require, 'cmp_nvim_lsp')
      if ok_cmp then
        config.capabilities = vim.tbl_deep_extend('force', config.capabilities, cmp_lsp.default_capabilities())
      end

      -- jdtls extended client capabilities (refactoring, etc).
      config.init_options.extendedClientCapabilities = jdtls.extendedClientCapabilities

      jdtls.start_or_attach(config)
    end

    -- ----------------------------------------------------------------
    -- Lifecycle autocmds
    -- ----------------------------------------------------------------
    local java_group = vim.api.nvim_create_augroup('CustomJdtlsGroup', { clear = true })

    vim.api.nvim_create_autocmd('FileType', {
      group = java_group,
      pattern = 'java',
      callback = attach_jdtls,
    })

    vim.api.nvim_create_autocmd('BufWritePost', {
      group = java_group,
      pattern = { '*.java' },
      callback = function()
        pcall(vim.lsp.codelens.enable)
      end,
    })

    -- ----------------------------------------------------------------
    -- Keymaps (active in Java buffers only — registered globally but
    -- meaningful only when jdtls has attached).
    -- ----------------------------------------------------------------
    local function jmap(mode, lhs, rhs, desc)
      vim.keymap.set(mode, lhs, rhs, { desc = desc })
    end

    -- Refactoring
    jmap('n', '<leader>gro', jdtls.organize_imports, 'Java: Organize Imports')
    jmap('n', '<leader>grv', function()
      jdtls.extract_variable()
    end, 'Java: Extract Variable')
    jmap('n', '<leader>grc', function()
      jdtls.extract_constant()
    end, 'Java: Extract Constant')
    jmap('v', '<leader>grv', function()
      jdtls.extract_variable { visual = true }
    end, 'Java: Extract Variable (visual)')
    jmap('v', '<leader>grc', function()
      jdtls.extract_constant { visual = true }
    end, 'Java: Extract Constant (visual)')
    jmap('v', '<leader>grm', function()
      jdtls.extract_method { visual = true }
    end, 'Java: Extract Method (visual)')

    -- Testing
    jmap('n', '<leader>grt', function()
      jdtls.test_nearest_method()
    end, 'Java: Test Method')
    jmap('n', '<leader>grT', function()
      jdtls.test_class()
    end, 'Java: Test Class')

    -- Project / build
    jmap('n', '<leader>gru', '<Cmd>JdtUpdateConfig<CR>', 'Java: Update Project Config (Maven/Gradle)')
    jmap('n', '<leader>grB', '<Cmd>JdtBytecode<CR>', 'Java: Show Bytecode')
    jmap('n', '<leader>grj', '<Cmd>JdtJol<CR>', 'Java: JOL (Java Object Layout)')

    -- Spring Boot helpers (no-op outside Spring projects).
    jmap('n', '<leader>grs', '<Cmd>BootRun<CR>', 'Spring: Run app')
  end,
}
