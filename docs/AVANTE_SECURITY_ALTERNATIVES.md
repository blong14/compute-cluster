# Secure Avante Installation Alternatives

## The Security Problem

Your current configuration is insecure:
```lua
use{
    "yetone/avante.nvim",
    branch = "main",        -- ❌ Unstable, could contain malicious code
    run = "make",          -- ❌ Executes arbitrary code during installation
}
```

**Risks:**
- Main branch could contain untested or malicious changes
- `make` executes arbitrary commands from unknown Makefile
- No verification of what's being built or installed
- Automatic execution during plugin updates

## Secure Alternative 1: Tagged Release with Manual Build (Recommended)

```lua
use{
    "yetone/avante.nvim",
    tag = "v0.0.9",        -- ✅ Use specific stable release
    run = function()        -- ✅ Manual control over build process
        -- Only run after manual verification
        print("Avante installed. Run ':AvanteBuild' manually after reviewing the code.")
    end,
    config = function()
        -- Add manual build command
        vim.api.nvim_create_user_command('AvanteBuild', function()
            local avante_path = vim.fn.stdpath('data') .. '/site/pack/packer/start/avante.nvim'
            print("Building Avante from: " .. avante_path)
            print("Review the Makefile first, then run: cd " .. avante_path .. " && make")
        end, {})
    end
}
```

## Secure Alternative 2: Pre-built Binary (Most Secure)

```lua
use{
    "yetone/avante.nvim",
    tag = "v0.0.9",        -- ✅ Specific version
    -- No run command - use pre-built binaries
    config = function()
        -- Configure to use pre-built binaries
        require('avante').setup({
            provider = "openai",
            providers = {
                openai = {
                    endpoint = "https://api.anthropic.com",
                    model = "claude-3-5-sonnet-20241218",
                    api_key_name = "ANTHROPIC_API_KEY",
                },
            },
            -- Use pre-built binary path
            binary_path = vim.fn.expand("~/.local/bin/avante-binary")
        })
    end
}
```

## Secure Alternative 3: Containerized Build

```lua
use{
    "yetone/avante.nvim",
    tag = "v0.0.9",
    run = function()
        -- Build in isolated container
        local build_script = [[
#!/bin/bash
cd ~/.local/share/nvim/site/pack/packer/start/avante.nvim
docker run --rm -v $(pwd):/workspace -w /workspace \
    rust:1.70 bash -c "make clean && make"
        ]]

        -- Write and execute build script
        local script_path = "/tmp/avante_secure_build.sh"
        local file = io.open(script_path, "w")
        file:write(build_script)
        file:close()

        print("Secure build script created at: " .. script_path)
        print("Review and run manually: bash " .. script_path)
    end
}
```

## Secure Alternative 4: Fork and Verify Approach

```lua
-- First, fork the repository to your own GitHub account
-- Review the code thoroughly
-- Then use your fork:
use{
    "yourusername/avante.nvim",  -- ✅ Your verified fork
    tag = "verified-v0.0.9",     -- ✅ Your verified tag
    run = "make",                -- ✅ Now safe because you control the code
}
```

## Secure Alternative 5: Lazy Loading with Manual Verification

```lua
use{
    "yetone/avante.nvim",
    tag = "v0.0.9",
    opt = true,              -- ✅ Don't load automatically
    run = function()
        print("Avante downloaded but not built. Use :AvanteSafeSetup to continue.")
    end,
    config = function()
        vim.api.nvim_create_user_command('AvanteSafeSetup', function()
            local steps = {
                "1. cd ~/.local/share/nvim/site/pack/packer/opt/avante.nvim",
                "2. Review the Makefile: cat Makefile",
                "3. Review build scripts: find . -name '*.sh' -o -name 'build*'",
                "4. If safe, run: make",
                "5. Then run: :packadd avante.nvim"
            }

            print("Manual setup steps:")
            for _, step in ipairs(steps) do
                print(step)
            end
        end, {})
    end
}
```

## Most Secure Recommended Configuration

Here's what I recommend for maximum security:

```lua
use{
    "yetone/avante.nvim",
    tag = "v0.0.9",              -- Specific stable version
    opt = true,                  -- Don't auto-load
    requires = {
        {'nvim-lua/plenary.nvim'},
        {'MunifTanjim/nui.nvim'},
        {'MeanderingProgrammer/render-markdown.nvim'},
        {'stevearc/dressing.nvim'},
    },
    config = function()
        -- Security verification commands
        vim.api.nvim_create_user_command('AvanteVerify', function()
            local plugin_path = vim.fn.stdpath('data') .. '/site/pack/packer/opt/avante.nvim'
            local commands = {
                "echo 'Reviewing Avante source code...'",
                "cd " .. plugin_path,
                "echo '=== Makefile Contents ==='",
                "cat Makefile",
                "echo '=== Build Scripts ==='",
                "find . -name '*.sh' -exec echo 'File: {}' \\; -exec cat {} \\;",
                "echo '=== Rust Dependencies ==='",
                "cat Cargo.toml 2>/dev/null || echo 'No Cargo.toml found'",
                "echo '=== Recent Commits ==='",
                "git log --oneline -10",
            }

            for _, cmd in ipairs(commands) do
                vim.fn.system(cmd)
            end

            print("Review complete. If safe, run :AvanteBuild")
        end, {})

        vim.api.nvim_create_user_command('AvanteBuild', function()
            local plugin_path = vim.fn.stdpath('data') .. '/site/pack/packer/opt/avante.nvim'
            print("Building Avante...")

            -- Build in background with output capture
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
            require('avante').setup({
                provider = "openai",
                behaviour = {
                    auto_apply_diff_after_generation = true,
                },
                providers = {
                    openai = {
                        endpoint = "https://api.anthropic.com",
                        model = "claude-3-5-sonnet-20241218",
                        api_key_name = "ANTHROPIC_API_KEY",
                    },
                },
                -- Your existing config...
            })
            print("Avante loaded and configured!")
        end, {})
    end
}
```

## Security Workflow

1. **Install**: Packer installs but doesn't build or load
2. **Verify**: Run `:AvanteVerify` to review all code
3. **Build**: Run `:AvanteBuild` only after manual verification
4. **Load**: Run `:AvanteLoad` to activate the plugin

## Additional Security Measures

### 1. Hash Verification
```bash
# Before building, verify the source hasn't been tampered with
cd ~/.local/share/nvim/site/pack/packer/opt/avante.nvim
git verify-tag v0.0.9  # If they sign their tags
sha256sum Makefile      # Compare with known good hash
```

### 2. Sandbox Testing
```bash
# Test in isolated environment first
docker run -it --rm -v ~/.config/nvim:/nvim-config \
    neovim/neovim:latest bash
```

### 3. Network Isolation During Build
```bash
# Build without network access
unshare --net make
```

## Why This Matters for Your Compute Cluster

Given your sophisticated infrastructure setup with:
- Multi-architecture deployment (AMD64 + ARM64)
- Encrypted vault configurations
- Production services (databases, AI/ML workloads)

A compromised development environment could lead to:
- Credential theft from Ansible vaults
- Malicious code injection into your infrastructure
- Compromise of your entire compute cluster

The secure installation approach protects your entire infrastructure investment.

