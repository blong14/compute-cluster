# Quick navigation
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'
alias ~='cd ~'

# Better defaults
alias cp='cp -i'                          # Confirm before overwriting
alias mv='mv -i'                          # Confirm before overwriting
alias rm='rm -i'                          # Confirm before removing
alias mkdir='mkdir -p'                    # Create parent directories
alias df='df -h'                          # Human-readable sizes
alias du='du -h'                          # Human-readable sizes
alias free='free -h'                      # Human-readable sizes

# Git shortcuts
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git pull'
alias gd='git diff'
alias gb='git branch'
alias gco='git checkout'
alias glog='git log --oneline --graph --decorate'

# Network
alias myip='curl -s https://ipinfo.io/ip'
alias ports='netstat -tulanp'
alias ping='ping -c 5'

# System
alias update='sudo apt update && sudo apt upgrade -y'
alias install='sudo apt install'
alias remove='sudo apt remove'
alias sysinfo='echo -e "CPU: $(grep "model name" /proc/cpuinfo | head -1 | cut -d ":" -f2)\nMemory: $(free -h | grep Mem | awk "{print \$3\" / \"\$2}")\nDisk: $(df -h / | tail -1 | awk "{print \$3\" / \"\$2\" (\"\$5\")\"})"'
