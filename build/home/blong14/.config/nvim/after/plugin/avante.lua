vim.cmd('packadd avante.nvim')
require('avante_lib').load()
require('avante').setup({
  build = ":AvanteBuild",
  provider = "claude",
  auto_suggestions_provider = "claude",

  providers = {
    claude = {
      endpoint = "https://api.anthropic.com",
      model = "claude-sonnet-4-20250514",
      --model = "claude-4-5-sonnet-20250922",
      timeout = 60000,
      max_tokens = 8192,
      temperature = 0.1,
    },
  },

  -- Templates for AI interactions
  templates = {
    ask = {
      system_prompt = "You are an expert software developer. Always use best practices when coding. Respect and use existing conventions, libraries, etc that are already present in the code base.",
      user_prompt = "{{question}}",
    },
    edit = {
      system_prompt = "You are an expert software developer. Always use best practices when coding. Respect and use existing conventions, libraries, etc that are already present in the code base. Take requests for changes to the supplied code. If the request is ambiguous, ask questions.",
      user_prompt = "{{question}}\n\nHere is the code:\n```{{filetype}}\n{{content}}\n```",
    },
    chat = {
      system_prompt = "You are an expert software developer. Always use best practices when coding. Respect and use existing conventions, libraries, etc that are already present in the code base.",
      user_prompt = "{{question}}",
    },
  },

  -- Behavior settings
  behaviour = {
    auto_suggestions = false, -- Disable for stability
    auto_set_highlight_group = true,
    auto_set_keymaps = true,
    auto_apply_diff_after_generation = false, -- Manual control for safety
    support_paste_from_clipboard = true,
    minimize_diff = true,
    enable_token_counting = true,
    auto_add_current_file = true,
    auto_approve_tool_permissions = false, -- Security
    confirmation_ui_style = "inline_buttons",
  },

  -- Key mappings
  mappings = {
    diff = {
      ours = "co",
      theirs = "ct",
      all_theirs = "ca",
      both = "cb",
      cursor = "cc",
      next = "]x",
      prev = "[x",
    },
    suggestion = {
      accept = "<M-l>",
      next = "<M-]>",
      prev = "<M-[>",
      dismiss = "<C-]>",
    },
    submit = {
      normal = "<CR>",
      insert = "<C-s>",
    },
    sidebar = {
      apply_all = "A",
      apply_cursor = "a",
      retry_user_request = "r",
      edit_user_request = "e",
      switch_windows = "<Tab>",
      reverse_switch_windows = "<S-Tab>",
      remove_file = "d",
      add_file = "@",
      close = { "<Esc>", "q" },
    },
  },
  
  -- Window configuration
  windows = {
    position = "right",
    wrap = true,
    width = 40, -- Increased width for better display
    sidebar_header = {
      enabled = true,
      align = "center",
      rounded = true,
    },
    input = {
      prefix = "> ",
      height = 10, -- Increased height for better input area
    },
    edit = {
      border = "rounded",
      start_insert = true,
    },
    ask = {
      floating = false,
      start_insert = true,
      border = "rounded",
      focus_on_apply = "ours",
    },
  },
  
  -- Diff settings
  diff = {
    autojump = true,
    list_opener = "copen",
    override_timeoutlen = 500,
  },
  
  -- Suggestion settings
  suggestion = {
    debounce = 1200,
    throttle = 1200,
  },
  
  -- Input and selector providers
  input = {
    provider = "dressing",
    provider_opts = {
      title = "Avante Input",
      relative = "editor",
    },
  },
  
  selector = {
    provider = "native",
    provider_opts = {},
  },

  -- Custom shortcuts for quick access to common prompts
  shortcuts = {
    {
      name = "refactor",
      description = "Refactor code with best practices",
      details = "Automatically refactor code to improve readability, maintainability, and follow best practices while preserving functionality",
      prompt = "Please refactor this code following best practices, improving readability and maintainability while preserving functionality. Include a todo list of any additional improvements that could be made."
    },
    {
      name = "test",
      description = "Generate unit tests",
      details = "Create comprehensive unit tests covering edge cases, error scenarios, and various input conditions",
      prompt = "Please generate comprehensive unit tests for this code, covering edge cases and error scenarios. Include a todo list of additional test cases that should be considered."
    },
    {
      name = "optimize",
      description = "Optimize code performance",
      details = "Analyze and optimize code for better performance and efficiency",
      prompt = "Please analyze this code for performance optimizations and suggest improvements. Include a todo list of performance monitoring and testing tasks."
    },
    {
      name = "document",
      description = "Add documentation and comments",
      details = "Add comprehensive documentation, comments, and type annotations",
      prompt = "Please add comprehensive documentation, comments, and type annotations to this code. Include a todo list of additional documentation tasks."
    },
  },
})

-- Optional: Add custom keymaps for Avante
vim.keymap.set("n", "<leader>aa", function() require("avante.api").ask() end, { desc = "avante: ask" })
vim.keymap.set("v", "<leader>aa", function() require("avante.api").ask() end, { desc = "avante: ask" })
vim.keymap.set("n", "<leader>ar", function() require("avante.api").refresh() end, { desc = "avante: refresh" })
vim.keymap.set("n", "<leader>ae", function() require("avante.api").edit() end, { desc = "avante: edit" })
