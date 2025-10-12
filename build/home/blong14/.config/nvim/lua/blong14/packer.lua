-- This file can be loaded by calling `lua require('plugins')` from your init.vim
local ensure_packer = function()
  local fn = vim.fn
  local install_path = fn.stdpath('data')..'/site/pack/packer/start/packer.nvim'
  if fn.empty(fn.glob(install_path)) > 0 then
    fn.system({'git', 'clone', '--depth', '1', 'https://github.com/wbthomason/packer.nvim', install_path})
    vim.cmd [[packadd packer.nvim]]
    return true
  end
  return false
end

local packer_bootstrap = ensure_packer()

return require('packer').startup(function(use)
  -- Packer can manage itself
  use 'wbthomason/packer.nvim'

  use {
	  'nvim-telescope/telescope.nvim', tag = '0.1.4',
	  -- or                            , branch = '0.1.x',
	  requires = { {'nvim-lua/plenary.nvim'} }
  }

  use('nvim-treesitter/nvim-treesitter', {run = ':TSUpdate'})
  use('nvim-treesitter/playground')

  use('theprimeagen/harpoon')
  use {
      'VonHeikemen/lsp-zero.nvim',
      branch = 'v3.x',
      requires = {
        --- Uncomment these if you want to manage LSP servers from neovim
        {'williamboman/mason.nvim'},
        {'williamboman/mason-lspconfig.nvim'},
        -- LSP Support
        {'neovim/nvim-lspconfig'},
        -- Autocompletion
        {'hrsh7th/nvim-cmp'},
        {'hrsh7th/cmp-nvim-lsp'},
        {'L3MON4D3/LuaSnip'},
      }
  }

  use("folke/zen-mode.nvim")

  use("ziglang/zig.vim")

  use("marko-cerovac/material.nvim")

  use("nvim-lualine/lualine.nvim")

  -- AI related tools

  -- avante __
  use("nvim-lua/plenary.nvim")
  use("MunifTanjim/nui.nvim")
  use("MeanderingProgrammer/render-markdown.nvim")
  use("stevearc/dressing.nvim")
  use("preservim/nerdtree")
  use("ryanoasis/vim-devicons")
  -- use("github/copilot.vim")
  use{
      "yetone/avante.nvim",
      tag = "v0.0.9",              -- Use specific stable version instead of main
      opt = true,                  -- Don't auto-load for security
      requires = {
        {'nvim-lua/plenary.nvim'},
        {'MunifTanjim/nui.nvim'},
        {'MeanderingProgrammer/render-markdown.nvim'},
        {'stevearc/dressing.nvim'},
      },
  }

end)
