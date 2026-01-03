# Practical Workflow Examples: Aider + Avante

## Real-World Development Scenarios

### Scenario 1: Building a REST API Authentication System

#### Step 1: Planning & Architecture (Aider)
```bash
# Start architectural discussion
aider --architect

# Conversation example:
# You: "I need to add JWT authentication to my Express.js API. What's the best approach?"
# Aider will analyze your codebase and suggest:
# - File structure for auth middleware
# - Database schema changes needed
# - Routes to modify
# - Security considerations
```

#### Step 2: File Creation & Boilerplate (Aider)
```bash
# Create the auth system files
aider --message "Create JWT authentication system with middleware, routes, and models"

# Aider will create:
# - middleware/auth.js
# - routes/auth.js  
# - models/User.js
# - utils/jwt.js
```

#### Step 3: Implementation Details (Avante)
Open each file in Neovim and use Avante for detailed implementation:

**In `middleware/auth.js`:**
- Position cursor and press `<leader>aa`
- Ask: "Implement JWT verification middleware with error handling"
- Avante provides context-aware implementation

**In `routes/auth.js`:**
- Select function stub and press `<leader>ae`
- Ask: "Add login route with bcrypt password verification"
- Review diff and accept changes

#### Step 4: Integration & Testing (Aider)
```bash
# Back to Aider for integration
aider middleware/auth.js routes/auth.js app.js

# Message: "Integrate the auth middleware into the main app and add protected routes"
```

### Scenario 2: Refactoring Legacy Code

#### Step 1: Code Analysis (Aider)
```bash
# Analyze problematic code
aider legacy-module.js utils.js

# Ask: "This code has performance issues and is hard to maintain. 
#      What refactoring approach would you recommend?"
```

#### Step 2: Incremental Refactoring (Avante)
For each function that needs refactoring:
- Open in Neovim
- Select the function
- Use `<leader>ae` with prompt: "Refactor this function for better performance and readability"
- Review each change carefully before accepting

#### Step 3: Extract Common Patterns (Aider)
```bash
# After individual function improvements
aider src/

# Ask: "Extract common patterns into reusable utilities and update imports"
```

### Scenario 3: Bug Investigation & Fix

#### Step 1: Bug Analysis (Aider)
```bash
# Include relevant files in context
aider components/UserProfile.js services/api.js utils/validation.js

# Describe the bug: "Users report that profile updates aren't saving. 
#                   The form submits but data doesn't persist."
```

#### Step 2: Targeted Fix (Avante)
Once Aider identifies the issue location:
- Open the problematic file in Neovim
- Navigate to the specific function
- Use `<leader>aa`: "Fix the async/await handling in this function"
- Apply the suggested fix

#### Step 3: Verification (Aider)
```bash
# Verify the fix doesn't break anything else
aider --message "Check if the profile update fix affects other parts of the codebase"
```

## Advanced Workflow Patterns

### Pattern 1: Feature Branch Development

```bash
# 1. Create feature branch
git checkout -b feature/user-notifications

# 2. Architecture planning with Aider
aider --architect
# Plan the notification system architecture

# 3. Create file structure with Aider
aider --message "Set up notification system files and basic structure"

# 4. Implement components with Avante
# Open each file in Neovim and implement details

# 5. Integration testing with Aider
aider --message "Add comprehensive tests for the notification system"

# 6. Final review and optimization with Aider
aider --message "Review and optimize the notification system code"
```

### Pattern 2: Code Review Workflow

#### Before Code Review (Self-Review)
```bash
# Use Aider to review your own changes
aider $(git diff --name-only HEAD~1)

# Ask: "Review these changes for potential issues, performance problems, 
#      and code quality improvements"
```

#### During Code Review (Addressing Feedback)
For each review comment:
- Open file in Neovim
- Navigate to the commented line
- Use Avante with context: "Address this code review feedback: [paste comment]"

### Pattern 3: Performance Optimization

#### Step 1: Identify Bottlenecks (Aider)
```bash
aider --message "Analyze this codebase for performance bottlenecks and suggest optimizations"
```

#### Step 2: Implement Optimizations (Avante)
For each identified issue:
- Open in Neovim
- Select the problematic code
- Use `<leader>ae`: "Optimize this code for better performance"

#### Step 3: Validate Changes (Aider)
```bash
aider --message "Verify that performance optimizations don't introduce bugs"
```

## Daily Development Routines

### Morning Routine: Project Setup
```bash
# 1. Start with Aider for daily planning
aider --message "What should I work on today based on recent commits and TODO comments?"

# 2. Review overnight changes
aider $(git log --since="yesterday" --name-only --pretty=format: | sort | uniq)
```

### During Development: Context Switching
```bash
# When switching between features
# 1. Commit current work with Aider
aider --message "Clean up and commit current progress"

# 2. Switch context
git checkout feature/different-feature

# 3. Get back up to speed with Aider
aider --message "Remind me what I was working on in this feature"
```

### End of Day: Code Cleanup
```bash
# Final review and cleanup
aider --message "Review today's changes and suggest any cleanup or improvements"
```

## Keyboard Shortcuts & Efficiency Tips

### Neovim + Avante Shortcuts
```lua
-- Add to your Neovim config for maximum efficiency
vim.keymap.set("n", "<leader>ap", function() 
  require("avante.api").ask("Explain this code and suggest improvements") 
end, { desc = "Avante: Explain & improve" })

vim.keymap.set("v", "<leader>af", function() 
  require("avante.api").edit("Fix any issues in this code") 
end, { desc = "Avante: Quick fix" })

vim.keymap.set("n", "<leader>at", function() 
  require("avante.api").ask("Add comprehensive tests for this function") 
end, { desc = "Avante: Add tests" })

vim.keymap.set("n", "<leader>ad", function() 
  require("avante.api").ask("Add detailed documentation for this code") 
end, { desc = "Avante: Add docs" })
```

### Shell Aliases for Aider
```bash
# Add to ~/.bashrc or ~/.zshrc
alias aid-plan="aider --architect"
alias aid-review="aider --message 'Review this code for issues and improvements'"
alias aid-test="aider --message 'Add comprehensive tests'"
alias aid-doc="aider --message 'Add documentation and comments'"
alias aid-fix="aider --message 'Fix any bugs or issues in this code'"
alias aid-perf="aider --message 'Optimize this code for better performance'"
```

## Troubleshooting Common Workflow Issues

### Issue 1: Context Overload
**Problem**: Too much context slows down responses
**Solution**: 
- Use `.aiderignore` to exclude irrelevant files
- Be specific about which files to include in Aider sessions
- Use Avante for focused, single-file work

### Issue 2: Inconsistent Suggestions
**Problem**: Aider and Avante give conflicting advice
**Solution**:
- Ensure both tools use the same model (Claude Sonnet)
- Be explicit about coding standards and preferences
- Use consistent prompting patterns

### Issue 3: Git Conflicts
**Problem**: Automatic commits from Aider conflict with manual workflow
**Solution**:
- Configure Aider's auto-commit behavior
- Use feature branches for Aider sessions
- Review commits before pushing

## Performance Optimization Tips

### For Large Codebases
```bash
# Limit Aider's context with specific file patterns
aider src/components/*.js --exclude="*.test.js"

# Use Avante for focused work on specific files
# Configure smaller context windows in Avante
```

### For Slow Connections
```bash
# Disable streaming in Aider
aider --no-stream

# Increase Avante debounce in your config
-- In your Avante setup:
suggestion = {
  debounce = 2000,  -- Increase for slower connections
  throttle = 2000,
}
```

## Integration with Other Tools

### VS Code Users
If you also use VS Code, you can complement this workflow:
- Use Aider for terminal-based work
- Use GitHub Copilot in VS Code for different perspectives
- Use Avante in Neovim for focused editing

### CI/CD Integration
```yaml
# Example GitHub Action for Aider code review
name: AI Code Review
on: [pull_request]
jobs:
  ai-review:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Run Aider Review
        run: |
          aider --message "Review this PR for potential issues" \
                --no-auto-commits \
                $(git diff --name-only origin/main)
```

This comprehensive workflow guide should give you practical, actionable ways to combine Aider and Avante for maximum development efficiency!

