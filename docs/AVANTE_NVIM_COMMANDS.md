# Avante.nvim Usage Summary

This document provides a concise summary of how to use `avante.nvim`, focusing on commands and key bindings as described on the project's GitHub page.

## Key Bindings

| Key Binding                      | Description                            |
| -------------------------------- | -------------------------------------- |
| **Sidebar**                      |                                        |
| `]]p`                            | next prompt                            |
| `[[p`                            | previous prompt                        |
| `A`                              | apply all                              |
| `a`                              | apply cursor                           |
| `r`                              | retry user request                     |
| `e`                              | edit user request                      |
| `<Tab>`                          | switch windows                         |
| `<S-Tab>`                        | reverse switch windows                 |
| `d`                              | remove file                            |
| `@`                              | add file                               |
| `q`                              | close sidebar                          |
| `<Leader>aa`                     | show sidebar                           |
| `<Leader>at`                     | toggle sidebar visibility              |
| `<Leader>ar`                     | refresh sidebar                        |
| `<Leader>af`                     | switch sidebar focus                   |
| **Suggestion**                   |                                        |
| `<Leader>a?`                     | select model                           |
| `<Leader>an`                     | new ask                                |
| `<Leader>ae`                     | edit selected blocks                   |
| `<Leader>aS`                     | stop current AI request                |
| `<Leader>ah`                     | select between chat histories          |
| `<M-l>`                          | accept suggestion                      |
| `<M-]>`                          | next suggestion                        |
| `<M-[>`                          | previous suggestion                    |
| `<C-]>`                          | dismiss suggestion                     |
| `<Leader>ad`                     | toggle debug mode                      |
| `<Leader>as`                     | toggle suggestion display              |
| `<Leader>aR`                     | toggle repomap                         |
| **Files**                        |                                        |
| `<Leader>ac`                     | add current buffer to selected files   |
| `<Leader>aB`                     | add all buffer files to selected files |
| **Diff**                         |                                        |
| `co`                             | choose ours                            |
| `ct`                             | choose theirs                          |
| `ca`                             | choose all theirs                      |
| `cb`                             | choose both                            |
| `cc`                             | choose cursor                          |
| `]x`                             | move to next conflict                  |
| `[x`                             | move to previous conflict              |
| **Confirm**                      |                                        |
| `<Ctrl>wf`                       | focus confirm window                   |
| `c`                              | confirm code                           |
| `r`                              | confirm response                       |
| `i`                              | confirm input                          |

## Commands

| Command                           | Description                                                                                                 | Examples                                            |
| --------------------------------- | ----------------------------------------------------------------------------------------------------------- | --------------------------------------------------- |
| `:AvanteAsk [question] [position]`  | Ask AI about your code. Optional `position` set window position and `ask` enable/disable direct asking mode | `:AvanteAsk position=right Refactor this code here` |
| `:AvanteBuild`                    | Build dependencies for the project                                                                          |                                                     |
| `:AvanteChat`                     | Start a chat session with AI about your codebase. Default is `ask`=false                                    |                                                     |
| `:AvanteChatNew`                  | Start a new chat session. The current chat can be re-opened with the chat session selector                  |                                                     |
| `:AvanteHistory`                  | Opens a picker for your previous chat sessions                                                              |                                                     |
| `:AvanteClear`                    | Clear the chat history for your current chat session                                                        |                                                     |
| `:AvanteEdit`                     | Edit the selected code blocks                                                                               |                                                     |
| `:AvanteFocus`                    | Switch focus to/from the sidebar                                                                            |                                                     |
| `:AvanteRefresh`                  | Refresh all Avante windows                                                                                  |                                                     |
| `:AvanteStop`                     | Stop the current AI request                                                                                 |                                                     |
| `:AvanteSwitchProvider`           | Switch AI provider (e.g. openai)                                                                            |                                                     |
| `:AvanteShowRepoMap`              | Show repo map for project's structure                                                                       |                                                     |
| `:AvanteToggle`                   | Toggle the Avante sidebar                                                                                   |                                                     |
| `:AvanteModels`                   | Show model list                                                                                             |                                                     |
| `:AvanteSwitchSelectorProvider`   | Switch avante selector provider (e.g. native, telescope, fzf_lua, mini_pick, snacks)                        |                                                     |

## Chat Triggers

### Mentions (`@` trigger)

Quickly reference features or add files to the chat context:

-   `@codebase` - Enable project context and repository mapping
-   `@diagnostics` - Enable diagnostics information
-   `@file` - Open file selector to add files to chat context
-   `@quickfix` - Add files from quickfix list to chat context
-   `@buffers` - Add open buffers to chat context

### Slash Commands (`/` trigger)

Built-in commands for common operations:

-   `/help` - Show help message with available commands
-   `/init` - Initialize AGENTS.md based on a
-   `/clear` - Clear chat history
-   `/new` - Start a new chat
-   `/compact` - Compact history messages to save tokens
-   `/lines <start>-<end> <question>` - Ask about specific lines
-   `/commit` - Generate commit message for changes

### Shortcuts (`#` trigger)

Access predefined prompt templates (customizable in your config). Examples:

-   `#refactor`: Refactor code with best practices.
-   `#test`: Generate unit tests.
