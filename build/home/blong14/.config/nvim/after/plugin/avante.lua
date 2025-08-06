--require("copilot").setup({})
require("avante_lib").load()
require("avante").setup({
  ---@alias Provider "claude" | "openai" | "azure" | "gemini" | "cohere" | "copilot" | string
  provider = "copilot", -- The provider used in Aider mode or in the planning phase of Cursor Planning Mode
  behaviour = {
    auto_apply_diff_after_generation = true,
  },
  suggestion = {
    debounce = 1200,
    throttle = 1200,
  },
})

