# Aider: Your AI Assistant in the Terminal

## Overview

Aider is a command-line AI coding assistant that pairs with you to write and edit code directly in your terminal. It's designed with a deep understanding of your entire codebase, making it exceptionally powerful for complex tasks, refactoring across multiple files, and maintaining code quality.

### Key Strengths
- **Repository-wide Context**: Aider analyzes your entire git repository to understand code structure and dependencies.
- **Git Integration**: It automatically commits changes with clear, descriptive messages, integrating seamlessly into your development workflow.
- **Multi-file Changes**: Effortlessly performs complex refactoring or feature implementation across multiple files.
- **Interactive Terminal Workflow**: Allows for a continuous, conversational "pair programming" session with an AI.

## Basic Usage

To start an Aider session, simply invoke it with the files you want to work on:

```bash
aider src/main.py src/utils.py
```

Aider will add these files to the chat, and you can begin giving it instructions in plain English, such as "Refactor the `process_data` function in `utils.py` to be more efficient."

## Best Practices for Effective Use

Based on official Aider documentation, following these tips will significantly improve your results.

### 1. Be Selective with Files
- **Add only what's necessary**: Use `aider <file>` or `/add <file>` inside a session to add only the files that need changes.
- **Avoid clutter**: Don't add lots of irrelevant files. Aider already has a map of your repo for broader context.
- **Clean up the chat**: Use `/drop <file>` to remove files from the context when you're done editing them.

### 2. Work in Small, Iterative Steps
Break down large goals into smaller, manageable tasks. This allows you to guide the AI, review incremental changes, and correct its course as needed.

### 3. Plan Complex Changes
For major features or refactoring, discuss a plan with Aider first. You can do this in two ways:

- **Architect Mode**: For high-level planning sessions, start Aider with the `--architect` flag. This mode is optimized for architectural discussions and won't attempt to write code unless you explicitly ask it to.
  ```bash
  aider --architect
  ```
- **The `/ask` Command**: For a quick question within a regular coding session, use the `/ask` command to have a conversation without Aider writing code.
  - **Example**: `/ask I need to add JWT authentication to my API. What's the best approach?`

Once you're happy with the plan, state your request normally to have Aider implement it.

### 4. Creating New Files
If you want Aider to create a new file, you must first tell Aider about it:
```
/add path/to/new_file.js
```
Then, you can instruct Aider to add content to the newly created file.

### 5. Fixing Bugs and Errors
- If your code produces an error, paste the full error message directly into the chat.
- Alternatively, use the `/run` command to execute a command and share the output (including errors) with Aider automatically.
  ```
  /run npm test
  ```

## Example: Semantic Refactoring

Aider excels at changes that require understanding code, not just text. For example, you can ask it to perform a complex, project-wide refactor.

**Your Prompt**:
`replace all self.console.print() calls that contain [red] with calls to self.io.tool_error(), and remove [red] from the string`

Aider can understand this and apply the changes correctly, even with variations in formatting:

```diff
- self.console.print("[red]Files are not in a git repo.")
+ self.io.tool_error("Files are not in a git repo.")

- self.console.print(
-     f"[red]This tool will almost certainly fail to work with {main_model}"
- )
+ self.io.tool_error(f"This tool will almost certainly fail to work with {main_model}")
```

## Scripting and Automation

Aider can be scripted for non-interactive, automated tasks using command-line flags.

Use the `--message` (or `-m`) flag to provide a single instruction. Aider will apply the changes and exit.

```bash
aider src/utils.py --message "Add a descriptive docstring to the format_data function"
```

This is powerful for running bulk changes across many files:

```bash
# Add type hints to all functions in a directory
for FILE in src/**/*.py; do
    aider "$FILE" -m "Add type hints to all functions" --yes
done
```
*Note: `--yes` automatically accepts all changes, which is useful for scripts.*

## Recommended Shell Aliases

To streamline your daily workflow, add these aliases to your shell configuration (`.bashrc`, `.zshrc`, etc.).

```bash
# General alias for convenience
alias aid="aider"

# Start an architectural planning session
alias aid-arch="aider --architect"

# One-shot commands for common tasks.
# Usage: aid-review file1.py file2.js
alias aid-review="aider --message 'Review this code for issues and improvements'"
alias aid-test="aider --message 'Add comprehensive tests'"
alias aid-doc="aider --message 'Add documentation and comments'"
alias aid-fix="aider --message 'Fix any bugs or issues in this code'"
alias aid-perf="aider --message 'Optimize this code for better performance'"
```
