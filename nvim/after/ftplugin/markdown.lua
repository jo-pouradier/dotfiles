vim.opt_local.wrap = true
vim.opt_local.conceallevel = 2
vim.opt_local.foldmethod = 'expr'
vim.opt_local.foldexpr = "v:lua.vim.treesitter.foldexpr()"
vim.opt_local.foldlevel = 1

-- Keymaps for formatting
local map = vim.keymap.set
local opts = { buffer = true, noremap = true, silent = true }

map("n", "<leader>md", function()
  local date = os.date("%Y-%m-%d %H:%M")
  vim.api.nvim_put({ date }, 'c', true, true)
end, opts)

map("n", "<leader>mx", function()
  local line = vim.fn.getline(".")
  if line:match("%- %[ %]") then
    vim.fn.setline(".", line:gsub("%- %[ %]", "- [x]", 1))
  elseif line:match("%- %[x%]") then
    vim.fn.setline(".", line:gsub("%- %[x%]", "- [ ]", 1))
  end
end, opts)

-- Generate or update TOC (requires markdown-toc plugin)
map("n", "<leader>mt", ":GenTocGFM<CR>", opts)
map("n", "<leader>mT", ":UpdateToc<CR>", opts)
map("n", "<leader>gt", ":GoTocGFM<CR>", opts)

-- Optional: Continue lists automatically
vim.cmd [[
  inoremap <buffer> <CR> <CR><C-r>=getline('.') =~ '^\\s*[-*+]\\s' ? repeat(matchstr(getline('.'), '^\\s*[-*+]\\s'), '') : ''<CR>
]]

vim.api.nvim_create_autocmd("FileType", {
  pattern = "markdown",
  callback = function()
    vim.b.text_lsp_parse = true
  end,
})
