-- Layout: screen split into quarters (Q1..Q4) horizontally; tree in Q2,
-- preview in Q3.
--   Wide (>= NARROW_SCREEN_WIDTH):
--     +----+----------------+----------------+----+
--     | Q1 | nvim-tree (Q2) | float-preview  | Q4 |
--     |    |                | (Q3)           |    |
--     +----+----------------+----------------+----+
--   Narrow (< NARROW_SCREEN_WIDTH): tree/preview split the screen in half.
--     +----------------+----------------+
--     | nvim-tree      | float-preview  |
--     +----------------+----------------+
-- Height is 3/4 of the screen, vertically centered. Shrinks gracefully on
-- narrow/short terminals.

local WINDOW_MARGIN = 0 -- blank columns between the tree's and preview's borders
local BORDER_WIDTH = 1 -- 'rounded' border is drawn outside col/width, 1 col per side
local MIN_WIDTH = 20
local MIN_ROW = 1
local NARROW_SCREEN_WIDTH = 100 -- below this width, use a half/half split instead of quarters

local function ui()
  return vim.api.nvim_list_uis()[1] or { width = vim.o.columns, height = vim.o.lines }
end

local function layout()
  local u = ui()
  local gap = WINDOW_MARGIN + 2 * BORDER_WIDTH

  local height = math.max(10, math.floor(u.height * 0.75))
  local row = math.max(MIN_ROW, math.floor((u.height - height) / 2))

  local tree_col, preview_col, segment_width
  if u.width < NARROW_SCREEN_WIDTH then
    segment_width = math.floor(u.width / 2)
    tree_col = BORDER_WIDTH -- leave room for the tree's left border at col 0
    preview_col = segment_width
  else
    segment_width = math.floor(u.width / 4)
    tree_col = segment_width
    preview_col = 2 * segment_width
  end

  return {
    tree = {
      relative = 'editor',
      row = row,
      col = tree_col,
      width = math.max(MIN_WIDTH, segment_width - gap),
      height = height,
    },
    preview = {
      relative = 'editor',
      row = row,
      col = preview_col,
      width = math.max(MIN_WIDTH, segment_width),
      height = height,
    },
  }
end

local function tree_rect()
  return layout().tree
end

local function preview_rect()
  return layout().preview
end

return {
  'nvim-tree/nvim-tree.lua',
  lazy = false,
  cmd = { 'NvimTreeOpen', 'NvimTreeToggle', 'NvimTreeFocus', 'NvimTreeFindFile' },
  keys = {
    { '<leader>e', '<cmd>NvimTreeToggle<CR>', desc = 'Toggle Nvim Tree' },
  },
  dependencies = {
    'nvim-tree/nvim-web-devicons',
    {
      'jo-pouradier/nvim-tree.lua-float-preview',
      branch = 'feat/enable-preview-with-key',
      lazy = true,
    },
  },
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
        api.map.on_attach.default(bufnr)

        vim.keymap.set('n', '<C-h>', api.tree.toggle_help, opts 'Help')
        vim.keymap.set('n', '<C-t>', close_wrap(api.node.open.tab), opts 'Open: New Tab')
        vim.keymap.set('n', '<C-v>', close_wrap(api.node.open.vertical), opts 'Open: Vertical Split')
        vim.keymap.set('n', '<C-s>', close_wrap(api.node.open.horizontal), opts 'Open: Horizontal Split')
        vim.keymap.set('n', '<CR>', close_wrap(api.node.open.edit), opts 'Open')
        vim.keymap.set('n', '<Tab>', function()
          local node = api.tree.get_node_under_cursor()
          if node and node.type ~= 'file' then
            api.node.open.edit() -- expand/collapse folder
          else
            vim.cmd 'TogglePreviewFile' -- preview only, don't open the file
          end
        end, opts 'Open folder / preview file')
        vim.keymap.set('n', 'o', close_wrap(api.node.open.edit), opts 'Open')
        vim.keymap.set('n', 'O', close_wrap(api.node.open.no_window_picker), opts 'Open: No Window Picker')
        vim.keymap.set('n', 'a', close_wrap(api.fs.create), opts 'Create')
        vim.keymap.set('n', 'd', close_wrap(api.fs.remove), opts 'Delete')
        vim.keymap.set('n', 'r', close_wrap(api.fs.rename), opts 'Rename')
        vim.keymap.set('n', 'q', close_wrap(api.tree.close), opts 'Close')
        vim.keymap.set('n', '<ESC>', close_wrap(api.tree.close), opts 'Close')
      end,
      modified = { enable = true },
      sort = {
        folders_first = true,
        sorter = 'case_sensitive',
      },
      view = {
        float = {
          enable = true,
          open_win_config = function()
            local r = tree_rect()
            return {
              border = 'rounded',
              relative = r.relative,
              row = r.row,
              col = r.col,
              width = r.width,
              height = r.height,
            }
          end,
        },
      },
      renderer = {
        group_empty = true,
        add_trailing = true,
        highlight_git = 'all',
      },
      filters = {
        dotfiles = false,
        git_ignored = false,
      },
      diagnostics = {
        enable = true,
        show_on_dirs = true,
      },
      update_focused_file = { enable = true },
    }

    -- Must run after nvim-tree's setup: float-preview snapshots nvim-tree.api
    -- functions at require-time, and nvim-tree only hydrates the real
    -- implementations (replacing the "setup not called" stubs) once its own
    -- setup() has run.
    require('float-preview').setup {
      toggled_on = true,
      auto_preview = false,
      wrap_nvimtree_commands = false, -- on_attach already wraps node/fs commands with close_wrap
      scroll_lines = 20,
      window = {
        style = 'minimal',
        border = 'rounded',
        wrap = false,
        trim_height = false,
        open_win_config = function()
          local r = preview_rect()
          return {
            style = 'minimal',
            relative = r.relative,
            border = 'rounded',
            row = r.row,
            col = r.col,
            width = r.width,
            height = r.height,
          }
        end,
      },
      mapping = {
        down = { '<C-d>' },
        up = { '<C-e>', '<C-u>' },
        toggle = { '<C-x>' },
      },
      hooks = {
        pre_open = function(path)
          local size = require('float-preview.utils').get_size(path)
          if type(size) ~= 'number' then
            return false
          end
          local is_text = require('float-preview.utils').is_text(path)
          return size < 5 and is_text
        end,
        post_open = function(_)
          return true
        end,
      },
    }
  end,
}
