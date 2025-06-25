vim.g.mapleader = " "

vim.keymap.set("n", "<leader>pv", vim.cmd.Ex)
vim.keymap.set("n", "<leader>nt", vim.cmd.NERDTreeToggle)

-- Use The Silver Searcher https://github.com/ggreer/the_silver_searcher             
if vim.fn.executable('ag') == 1 then
    -- Use Ag over Grep
    vim.opt.grepprg = "ag --nogroup --nocolor"

    -- Use ag in fzf for listing files. Lightning fast and respects .gitignore
    vim.env.FZF_DEFAULT_COMMAND = 'ag --literal --files-with-matches --nocolor --hidden -g ""'
    if vim.fn.exists(":Ag") == 0 then
        vim.api.nvim_create_user_command('Ag', function(opts)
            vim.cmd('silent! grep! ' .. opts.args .. ' | cwindow | redraw!')
        end, { nargs = '+', complete = 'file' })
        vim.keymap.set('n', '<leader>pg', function()
            vim.cmd.Ag(vim.fn.input("🏄 Ag > "))
        end)
    end
end

