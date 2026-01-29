local lsp_zero = require('lsp-zero')

lsp_zero.on_attach(function(client, bufnr)
  -- see :help lsp-zero-keybindings
  -- to learn the available actions
  lsp_zero.default_keymaps({buffer = bufnr})
end)

local servers = {
  "bashls",
  "clangd",
  "gopls",
  "jedi_language_server",
  "lua_ls",
  "postgres_lsp",
  "ruff",
  "terraformls",
  "ts_ls",
  "vimls",
  'zls',
}

-- see :help lsp-zero-guide:integrate-with-mason-nvim
-- to learn how to use mason.nvim with lsp-zero
require('mason').setup({})
require('mason-lspconfig').setup({
  ensure_installed = servers,
  handlers = {
    lsp_zero.default_setup,
  },
})
