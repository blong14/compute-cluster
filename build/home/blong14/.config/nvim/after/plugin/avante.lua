--[[
  Avante.nvim Configuration

  This file configures the Avante plugin for Neovim, which provides AI-powered
  code assistance and chat functionality. The configuration includes:
  - Provider selection based on operating system
  - AI model configurations for Claude and Gemini
  - Custom templates for different interaction types
  - Behavior settings and key mappings
  - Window layout and appearance settings
  - Custom shortcuts for common AI tasks

  Author: Configuration for compute-cluster project
  Last Updated: 2026-02-25
--]]

-- Optional: Load Avante library components
-- These are commented out as they may not be needed for basic functionality
--vim.cmd('packadd avante.nvim')
-- require('avante_lib').load()

-- Provider Selection Logic
-- Determines which AI provider to use based on the operating system
-- This allows for different configurations on macOS vs Linux/other systems

---@type string The primary AI provider for main interactions
local provider

---@type string The provider for auto-suggestions feature
local auto_suggestions_provider

-- OS-specific provider configuration
-- macOS: Uses Gemini for main provider, Copilot for suggestions
-- Other OS: Uses Claude for both main provider and suggestions
if vim.loop.os_uname().sysname == "Darwin" then
  provider = "gemini"
  auto_suggestions_provider = "copilot"
else
  provider = "claude"
  auto_suggestions_provider = "claude"
end

-- Main Avante plugin setup
-- This configures the core functionality and provider settings
require('avante').setup({
  -- Build command to compile Avante components
  build = ":AvanteBuild",

  -- Set the primary provider based on OS detection above
  provider = provider,

  -- Set the auto-suggestions provider based on OS detection above
  auto_suggestions_provider = auto_suggestions_provider,

  -- AI Provider Configurations
  -- Each provider has specific settings for API endpoints, models, and parameters
  providers = {
    -- Anthropic Claude Configuration
    claude = {
      -- Official Anthropic API endpoint
      endpoint = "https://api.anthropic.com",

      -- Current model: Claude Sonnet 4 (latest stable version)
      model = "claude-sonnet-4-20250514",
      -- Alternative model option (commented out)
      --model = "claude-4-5-sonnet-20250922",

      -- Request timeout in milliseconds (60 seconds)
      timeout = 60000,

      -- Additional parameters sent with each API request
      extra_request_body = {
        max_tokens = 8192,    -- Maximum tokens in response
        temperature = 0.1,    -- Low temperature for more focused responses
      },
    },

    -- Google Gemini Configuration
    gemini = {
      -- Gemini 2.5 Pro model (latest version)
      model = "gemini-2.5-pro",

      -- Gemini-specific request parameters
      extra_request_body = {
        temperature = 0.75,   -- Higher temperature for more creative responses
        max_tokens = 4096,    -- Token limit for Gemini responses
      },
    },
  },

  -- AI Interaction Templates
  -- These templates define the system and user prompts for different interaction modes
  -- Each template includes placeholders that get replaced with actual content
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

  -- Plugin Behavior Configuration
  -- Controls how Avante behaves during various operations
  behaviour = {
    auto_suggestions = false,                    -- Disabled for stability and performance
    auto_set_highlight_group = true,             -- Automatically set syntax highlighting
    auto_set_keymaps = true,                     -- Enable default key mappings
    auto_apply_diff_after_generation = false,    -- Manual control for safety - user must approve changes
    support_paste_from_clipboard = true,         -- Allow pasting from system clipboard
    minimize_diff = true,                        -- Show minimal diff output for clarity
    enable_token_counting = true,                -- Track API token usage
    auto_add_current_file = true,                -- Automatically include current file in context
    auto_approve_tool_permissions = false,       -- Security: require manual approval for tool usage
    confirmation_ui_style = "inline_buttons",    -- Use inline buttons for confirmations
  },

  -- Key Mapping Configuration
  -- Defines keyboard shortcuts for various Avante operations
  mappings = {
    -- Diff navigation and resolution mappings
    diff = {
      ours = "co",        -- Accept our version (current/local changes)
      theirs = "ct",      -- Accept their version (incoming/AI changes)
      all_theirs = "ca",  -- Accept all incoming changes
      both = "cb",        -- Keep both versions (merge)
      cursor = "cc",      -- Apply change at cursor position
      next = "]x",        -- Navigate to next diff hunk
      prev = "[x",        -- Navigate to previous diff hunk
    },
    -- AI suggestion interaction mappings
    suggestion = {
      accept = "<M-l>",   -- Alt+L: Accept current suggestion
      next = "<M-]>",     -- Alt+]: Move to next suggestion
      prev = "<M-[>",     -- Alt+[: Move to previous suggestion
      dismiss = "<C-]>",  -- Ctrl+]: Dismiss current suggestion
    },
    -- Input submission mappings
    submit = {
      normal = "<CR>",    -- Enter: Submit in normal mode
      insert = "<C-s>",   -- Ctrl+S: Submit in insert mode
    },
    -- Sidebar interaction mappings
    sidebar = {
      apply_all = "A",                    -- Apply all suggested changes
      apply_cursor = "a",                 -- Apply change at cursor
      retry_user_request = "r",           -- Retry the last request
      edit_user_request = "e",            -- Edit the user's request
      switch_windows = "<Tab>",           -- Switch between windows
      reverse_switch_windows = "<S-Tab>", -- Reverse window switching
      remove_file = "d",                  -- Remove file from context
      add_file = "@",                     -- Add file to context
      close = { "<Esc>", "q" },          -- Close sidebar (Escape or q)
    },
  },
  -- Window Layout Configuration
  -- Controls the appearance and behavior of Avante windows
  windows = {
    position = "right",                         -- Position sidebar on the right side
    wrap = true,                                -- Enable text wrapping in windows
    width = 40,                                 -- Increased width for better display
    -- Sidebar header configuration
    sidebar_header = {
      enabled = true,                           -- Show header in sidebar
      align = "center",                         -- Center-align header text
      rounded = true,                           -- Use rounded corners for header
    },
    -- Input window configuration
    input = {
      prefix = "> ",                            -- Prompt prefix for input
      height = 10,                              -- Increased height for better input area
    },
    -- Edit mode window configuration
    edit = {
      border = "rounded",                       -- Use rounded borders
      start_insert = true,                      -- Start in insert mode
    },
    -- Ask mode window configuration
    ask = {
      floating = false,                         -- Use split window instead of floating
      start_insert = true,                      -- Start in insert mode
      border = "rounded",                       -- Use rounded borders
      focus_on_apply = "ours",                  -- Focus on our changes when applying
    },
  },

  -- Diff Display Settings
  -- Controls how code differences are shown and navigated
  diff = {
    autojump = true,                            -- Automatically jump to first diff
    list_opener = "copen",                      -- Command to open quickfix list
    override_timeoutlen = 500,                  -- Override timeout for diff operations (ms)
  },

  -- AI Suggestion Settings
  -- Controls timing and behavior of AI suggestions
  suggestion = {
    debounce = 1200,                            -- Delay before showing suggestions (ms)
    throttle = 1200,                            -- Minimum time between suggestions (ms)
  },

  -- UI Provider Configuration
  -- Configures input and selection interfaces
  input = {
    provider = "dressing",                      -- Use dressing.nvim for input UI
    provider_opts = {
      title = "Avante Input",                   -- Title for input dialogs
      relative = "editor",                      -- Position relative to editor
    },
  },

  selector = {
    provider = "native",                        -- Use native Neovim selector
    provider_opts = {},                         -- No additional options for native provider
  },

  -- Custom Shortcuts Configuration
  -- Predefined shortcuts for common AI-assisted development tasks
  -- Each shortcut includes a name, description, details, and prompt template
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
    {
      name = "review",
      description = "Review git diff vs main branch",
      details = "Reviews the git diff of the current branch against the main branch and provides suggestions for improvement without editing the code.",
      prompt = "Please review the git diff of the current branch against the main branch. Provide suggestions for improvement on code quality, potential bugs, and adherence to best practices. DO NOT provide any code edits or diffs, only written suggestions in a list format.\n\n```diff\n{{!git diff main...HEAD}}\n```"
    },
  },
})

-- Custom Key Mappings for Avante
-- These provide additional shortcuts beyond the default mappings
-- All mappings use the <leader> key (typically space or backslash)

-- Ask mode keymaps - for general questions and assistance
vim.keymap.set("n", "<leader>aa", function() require("avante.api").ask() end, {
  desc = "avante: ask - Open AI assistant for questions"
})
vim.keymap.set("v", "<leader>aa", function() require("avante.api").ask() end, {
  desc = "avante: ask - Ask about selected text"
})

-- Refresh keymap - reload or refresh current AI interaction
vim.keymap.set("n", "<leader>ar", function() require("avante.api").refresh() end, {
  desc = "avante: refresh - Refresh current AI interaction"
})

-- Edit mode keymap - for code modification requests
vim.keymap.set("n", "<leader>ae", function() require("avante.api").edit() end, {
  desc = "avante: edit - Request AI code modifications"
})

--[[
  TODO: Additional Documentation Tasks

  HIGH PRIORITY:
  - [ ] Create a separate README.md file documenting Avante configuration
  - [ ] Add usage examples for each shortcut and keymap
  - [ ] Document environment variables and API key setup
  - [ ] Create troubleshooting guide for common issues

  MEDIUM PRIORITY:
  - [ ] Add JSDoc-style comments for complex configuration objects
  - [ ] Document the relationship between providers and auto-suggestions
  - [ ] Create a configuration migration guide for version updates
  - [ ] Add performance tuning recommendations
  - [ ] Document security considerations and best practices

  LOW PRIORITY:
  - [ ] Create visual diagrams showing the plugin workflow
  - [ ] Add configuration validation functions
  - [ ] Document integration with other Neovim plugins
  - [ ] Create automated tests for configuration validation
  - [ ] Add configuration templates for different use cases
  - [ ] Document customization options for themes and UI
  - [ ] Create a glossary of AI/ML terms used in configuration
  - [ ] Add links to relevant Avante.nvim documentation
  - [ ] Document backup and restore procedures for configurations
  - [ ] Create a changelog for configuration updates

  FUTURE ENHANCEMENTS:
  - [ ] Add configuration schema validation
  - [ ] Create interactive configuration wizard
  - [ ] Add telemetry and usage analytics documentation
  - [ ] Document plugin performance metrics and monitoring
  - [ ] Create configuration diff tools for comparing setups
--]]
