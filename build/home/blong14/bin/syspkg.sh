#!/bin/bash
# Install system packages that can't be installed via pip

echo "Installing system packages..."
sudo apt update
sudo apt install -y neofetch ranger fzf bat tmux golang-go htop bash-completion silversearcher-ag

# Install Go packages
echo "Installing Go packages..."
go install golang.org/x/tools/gopls@latest

echo "All system packages installed successfully!"
echo "You can now run 'source ~/.bashrc' to apply all changes"

