#!/bin/bash
# Install system packages that can't be installed via pip

# Detect if running as root or with sudo capability
if [ "$EUID" -eq 0 ]; then
    # Running as root (during Docker build)
    APT_CMD="apt"
else
    # Running as agent user (runtime)
    APT_CMD="sudo apt"
fi

echo "Installing system packages..."
$APT_CMD update
$APT_CMD install -y neofetch ranger fzf bat tmux htop bash-completion silversearcher-ag git curl wget xz-utils build-essential

# Ensure Go is in PATH before installing Go packages
export GOPATH=$HOME/go
export GOROOT=$HOME/sdk/go1.24.4
export PATH=$GOROOT/bin:$GOPATH/bin:$PATH

# Install Go packages (only if Go is installed)
if command -v go &> /dev/null; then
    echo "Installing Go packages..."
    go install golang.org/x/tools/gopls@latest
else
    echo "Go not found, skipping Go package installation"
fi

echo "All system packages installed successfully!"
echo "You can now run 'source ~/.bashrc' to apply all changes"

