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
	  'nvim-telescope/telescope.nvim', version = '*',
	  requires = { {'nvim-lua/plenary.nvim'} }
  }

  use {'nvim-treesitter/nvim-treesitter',
    lazy = true,
    build = ':TSUpdate',
    config = function ()
      local treesitter = require("nvim-treesitter")
      treesitter.setup()
    end
 }

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

  -- avante dependencies
  use("nvim-lua/plenary.nvim")
  use("MunifTanjim/nui.nvim")
  use("stevearc/dressing.nvim")
  use("preservim/nerdtree")
  use("ryanoasis/vim-devicons")
  use("github/copilot.vim")
  
  -- Enhanced markdown rendering for avante
  use{
    "MeanderingProgrammer/render-markdown.nvim",
    config = function()
      require('render-markdown').setup({
        file_types = { "markdown", "Avante" },
      })
    end,
    ft = { "markdown", "Avante" },
  }
  
  -- Image clipboard support for avante
  use{
    "HakonHarnes/img-clip.nvim",
    config = function()
      require('img-clip').setup({
        default = {
          embed_image_as_base64 = false,
          prompt_for_file_name = false,
          drag_and_drop = {
            insert_mode = true,
          },
          use_absolute_path = true,
        },
      })
    end,
  }

  -- Main avante plugin
  use{
      "yetone/avante.nvim",
      commit = "a45acbf56a3129dcf35249783330a463c076a546",
      --branch = "main",
      run = "build",
      config = function()
        -- Configuration is handled in after/plugin/avante.lua
      end,
      requires = {
        {'nvim-lua/plenary.nvim'},
        {'MunifTanjim/nui.nvim'},
        {'MeanderingProgrammer/render-markdown.nvim'},
        {'stevearc/dressing.nvim'},
        {'HakonHarnes/img-clip.nvim'},
        {'github/copilot.vim'},
      },
  }

end)
