--require("copilot").setup({})
local config = function()
  -- Security verification commands
  vim.api.nvim_create_user_command('AvanteVerify', function()
    local plugin_path = vim.fn.stdpath('data') .. '/site/pack/packer/opt/avante.nvim'
    print("Reviewing Avante source code at: " .. plugin_path)
    print("Please manually review:")
    print("1. cd " .. plugin_path)
    print("2. cat Makefile")
    print("3. find . -name '*.sh' -exec cat {} \\;")
    print("4. git log --oneline -10")
    print("If safe, run :AvanteBuild")
  end, {})

  vim.api.nvim_create_user_command('AvanteBuild', function()
    local plugin_path = vim.fn.stdpath('data') .. '/site/pack/packer/opt/avante.nvim'
    print("Building Avante...")

    vim.fn.jobstart({'make'}, {
      cwd = plugin_path,
      on_stdout = function(_, data)
        for _, line in ipairs(data) do
          if line ~= "" then print("Build: " .. line) end
        end
      end,

      on_exit = function(_, exit_code)
        if exit_code == 0 then
          print("Build successful! Run :AvanteLoad to activate.")
        else
          print("Build failed with exit code: " .. exit_code)
        end
      end
    })
  end, {})

  vim.api.nvim_create_user_command('AvanteLoad', function()
    vim.cmd('packadd avante.nvim')
    require("avante_lib").load()
     require('avante').setup({
       provider = "claude",
       behaviour = {
         auto_apply_diff_after_generation = true,
         auto_set_highlight_group = true,
         auto_set_keymaps = true,
       },
       auto_suggestions_provider = "claude",
       suggestion = {
         debounce = 1200,
         throttle = 1200,
       },
       providers = {
         claude = {
           endpoint = "https://api.anthropic.com",
           model = "claude-sonnet-4-20250514",
           extra_request_body = {
             temperature = 0.75,
             max_tokens = 4096,
           },
         },
       },
     })
     print("Avante loaded and configured!")
  end, {})
end

config()
