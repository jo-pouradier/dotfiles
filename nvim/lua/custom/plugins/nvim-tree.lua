local calculate_window_size = function(width_ratio, height_ratio, col_offset, margin)
  local ui_info = vim.api.nvim_list_uis()[1]
  local gwidth = ui_info.width
  local gheight = ui_info.height
  local width = math.floor(gwidth * width_ratio)
  local height = math.floor(gheight * height_ratio)
  local col = (gwidth - width) * col_offset
  print(vim.inspect(width))

  return {
    width = width,
    height = height,
    row = (gheight - height) * 0.5,
    col = col + (margin or 0),
  }
end

return {
  'nvim-tree/nvim-tree.lua',
  dependencies = {
    'nvim-tree/nvim-web-devicons',
    {
      'jo-pouradier/nvim-tree.lua-float-preview',
      branch = 'feat/enable-preview-with-key',
      lazy = true,
      -- default
      opts = {
        toggled_on = true,
        auto_preview = false,
        wrap_nvimtree_commands = true,
        scroll_lines = 20,
        window = {
          border = 'rounded',
          wrap = false,
          trim_height = false,
          open_win_config = function()
            local rect = calculate_window_size(0.25, 0.7, 0.5, 13)
            return {
              style = 'minimal',
              relative = 'editor',
              border = 'single',
              row = rect.row,
              col = rect.col,
              width = rect.width,
              height = rect.height,
            }
          end,
        },
        mapping = {
          -- scroll down float buffer
          down = { '<C-d>' },
          -- scroll up float buffer
          up = { '<C-e>', '<C-u>' },
          -- enable/disable float windows
          toggle = { '<C-x>' },
        },
        -- hooks if return false preview doesn't shown
        hooks = {
          pre_open = function(path)
            -- if file > 5 MB or not text -> not preview
            local size = require('float-preview.utils').get_size(path)
            if type(size) ~= 'number' then
              return false
            end
            local is_text = require('float-preview.utils').is_text(path)
            return size < 5 and is_text
          end,
          post_open = function(bufnr)
            return true
          end,
        },
      },
    },
  },
  -- },
  config = function()
    require('nvim-tree').setup {
      on_attach = function(bufnr)
        local api = require 'nvim-tree.api'
        local FloatPreview = require 'float-preview'
        FloatPreview.attach_nvimtree(bufnr)
        local close_wrap = FloatPreview.close_wrap

        local function opts(desc)
          return { desc = 'nvim-tree: ' .. desc, buffer = bufnr, noremap = true, silent = true, nowait = true }
        end
        api.config.mappings.default_on_attach(bufnr)

        vim.keymap.set('n', '<C-t>', close_wrap(api.node.open.tab), opts 'Open: New Tab')
        vim.keymap.set('n', '<C-v>', close_wrap(api.node.open.vertical), opts 'Open: Vertical Split')
        vim.keymap.set('n', '<C-s>', close_wrap(api.node.open.horizontal), opts 'Open: Horizontal Split')
        vim.keymap.set('n', '<CR>', close_wrap(api.node.open.edit), opts 'Open')
        vim.keymap.set('n', '<Tab>', function()
          api.node.open.preview()
          vim.cmd 'TogglePreviewFile'
        end, opts 'Open folder / preview file')
        vim.keymap.set('n', 'o', close_wrap(api.node.open.edit), opts 'Open')
        vim.keymap.set('n', 'O', close_wrap(api.node.open.no_window_picker), opts 'Open: No Window Picker')
        vim.keymap.set('n', 'a', close_wrap(api.fs.create), opts 'Create')
        vim.keymap.set('n', 'd', close_wrap(api.fs.remove), opts 'Delete')
        vim.keymap.set('n', 'r', close_wrap(api.fs.rename), opts 'Rename')
        vim.keymap.set('n', 'q', close_wrap(api.tree.close), opts 'Close')
        vim.keymap.set('n', '<ESC>', close_wrap(api.tree.close), opts 'Close')
      end,
      modified = {
        enable = true,
      },
      sort = {
        folders_first = true,
        sorter = 'case_sensitive',
      },
      view = {
        float = {
          enable = true,
          open_win_config = function()
            local rect = calculate_window_size(0.25, 0.7, 0.25)
            vim.notify(vim.inspect(rect))
            return {
              border = 'rounded',
              relative = 'editor',
              row = rect.row,
              col = rect.col,
              width = rect.width,
              height = rect.height,
            }
          end,
        },
      },
      renderer = {
        group_empty = true,
        add_trailing = true,
        highlight_git = true,
      },
      filters = {
        dotfiles = false,
        git_ignored = false,
      },
      diagnostics = {
        enable = true,
        show_on_dirs = true,
      },
      update_focused_file = {
        enable = true,
      },
    }
  end,
}
