vim.api.nvim_set_option("number", true)
vim.api.nvim_set_option("numberwidth", 5)
vim.api.nvim_set_option("foldmethod", "indent")
vim.api.nvim_set_option("foldnestmax", 10)
vim.api.nvim_set_option("foldlevel", 2)

-- Make it obvious where 80 characters is
vim.opt.colorcolumn = "+1"
vim.opt.expandtab = true
vim.opt.guicursor = ""
vim.opt.hlsearch = false
vim.opt.incsearch = true
vim.opt.shiftwidth = 4
vim.opt.smartindent = true
vim.opt.tabstop = 4
vim.opt.textwidth = 80
vim.opt.wrap = false

-- https://github.com/doom-neovim/doom-nvim/blob/d878cd9a69eb86ad10177d3f974410317ab9f2fe/lua/doom/modules/features/netrw/init.lua
-- turning off netrw in favor of nerdtree... for now. above is examples of netrw config

-- styles
vim.g.material_style = "oceanic"
vim.cmd "colorscheme material"

