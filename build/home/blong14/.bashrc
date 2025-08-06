# ~/.bashrc: executed by bash(1) for non-login shells.
# see /usr/share/doc/bash/examples/startup-files (in the package bash-doc)
# for examples

# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac

# don't put duplicate lines or lines starting with space in the history.
# See bash(1) for more options
HISTCONTROL=ignoreboth

# append to the history file, don't overwrite it
shopt -s histappend

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
HISTSIZE=1000
HISTFILESIZE=2000

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# If set, the pattern "**" used in a pathname expansion context will
# match all files and zero or more directories and subdirectories.
#shopt -s globstar

# make less more friendly for non-text input files, see lesspipe(1)
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# set variable identifying the chroot you work in (used in the prompt below)
if [ -z "${debian_chroot:-}" ] && [ -r /etc/debian_chroot ]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi

# set a fancy prompt (non-color, unless we know we "want" color)
case "$TERM" in
    xterm-color|*-256color) color_prompt=yes;;
esac

# uncomment for a colored prompt, if the terminal has the capability; turned
# off by default to not distract the user: the focus in a terminal window
# should be on the output of commands, not on the prompt
force_color_prompt=yes

if [ -n "$force_color_prompt" ]; then
    if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
	# We have color support; assume it's compliant with Ecma-48
	# (ISO/IEC-6429). (Lack of such support is extremely rare, and such
	# a case would tend to support setf rather than setaf.)
	color_prompt=yes
    else
	color_prompt=
    fi
fi

if [ "$color_prompt" = yes ]; then
    PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
else
    PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '
fi
unset color_prompt force_color_prompt

# If this is an xterm set the title to user@host:dir
case "$TERM" in
xterm*|rxvt*)
    PS1="\[\e]0;${debian_chroot:+($debian_chroot)}\u@\h: \w\a\]$PS1"
    ;;
*)
    ;;
esac

# Theme configuration
# Available themes: material, retro, tron, default
THEME=${BASH_THEME:-material}

# Theme switching function
switch_theme() {
    export BASH_THEME="$1"
    source ~/.bashrc
    echo "Switched to $1 theme"
}

# Theme definitions
theme_material() {
    local primary="\[\033[38;5;69m\]"    # Blue
    local secondary="\[\033[38;5;141m\]"  # Purple
    local accent="\[\033[38;5;208m\]"    # Orange
    local text="\[\033[38;5;252m\]"      # Light gray
    local success="\[\033[38;5;78m\]"    # Green
    local warning="\[\033[38;5;220m\]"   # Yellow
    local error="\[\033[38;5;196m\]"     # Red
    local reset="\[\033[0m\]"

    PS1="${debian_chroot:+($debian_chroot)}${primary}┌─[${success}\u${primary}@${secondary}\h${primary}]─[${text}\w${primary}]"
    
    # Add git branch if available
    if command -v git &>/dev/null; then
        PS1="${PS1}─[${accent}\$(git branch 2>/dev/null | grep '^*' | colrm 1 2)${primary}]"
    fi
    
    PS1="${PS1}\n${primary}└─╼ ${reset}$ "
}

theme_retro() {
    local green="\[\033[38;5;46m\]"      # Bright green
    local cyan="\[\033[38;5;51m\]"       # Bright cyan
    local yellow="\[\033[38;5;226m\]"    # Bright yellow
    local reset="\[\033[0m\]"

    PS1="${debian_chroot:+($debian_chroot)}${green}┌──[${cyan}\u@\h${green}]──[${yellow}\w${green}]"
    
    # Add git branch if available
    if command -v git &>/dev/null; then
        PS1="${PS1}──[${cyan}\$(git branch 2>/dev/null | grep '^*' | colrm 1 2)${green}]"
    fi
    
    PS1="${PS1}\n${green}└─> ${reset}$ "
}

theme_tron() {
    local blue="\[\033[38;5;33m\]"       # Tron blue
    local cyan="\[\033[38;5;45m\]"       # Bright cyan
    local white="\[\033[38;5;15m\]"      # Bright white
    local reset="\[\033[0m\]"

    PS1="${debian_chroot:+($debian_chroot)}${blue}┌─[ ${cyan}\u${white}@${cyan}\h ${blue}]─[ ${cyan}\w ${blue}]"
    
    # Add git branch if available
    if command -v git &>/dev/null; then
        PS1="${PS1}─[ ${white}\$(git branch 2>/dev/null | grep '^*' | colrm 1 2) ${blue}]"
    fi
    
    PS1="${PS1}\n${blue}└─╼ ${cyan}$ ${reset}"
}

theme_default() {
    if [ "$color_prompt" = yes ]; then
        PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
    else
        PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '
    fi
}

# Apply the selected theme
theme_${THEME}

# enable color support of ls and also add handy aliases
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    #alias dir='dir --color=auto'
    #alias vdir='vdir --color=auto'

    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

# colored GCC warnings and errors
export GCC_COLORS='error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01:quote=01'

# some more ls aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

# Theme switching aliases
alias theme-material='switch_theme material'
alias theme-retro='switch_theme retro'
alias theme-tron='switch_theme tron'
alias theme-default='switch_theme default'

# Development aliases
# C development
alias cmk='mkdir -p build && cd build && cmake .. && make'
alias crun='make && ./$(basename $(pwd))'
alias valg='valgrind --leak-check=full --show-leak-kinds=all --track-origins=yes'

# Go development
alias gob='go build'
alias gor='go run'
alias got='go test ./...'
alias goc='go clean'
alias gof='go fmt ./...'
alias gom='go mod tidy'
alias goi='go install'
alias gov='go version'
alias goget='go get'
alias govet='go vet'

# Python development
alias py='python3'
alias pyv='python3 -m venv venv'
alias pya='source venv/bin/activate'
alias pyi='pip install'
alias pyr='pip install -r requirements.txt'

# Zig development
alias zb='zig build'
alias zr='zig run'
alias zt='zig test'

# Add an "alert" alias for long running commands.  Use like so:
#   sleep 10; alert
alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'

# Utility functions
# Extract various compressed file types
extract() {
  if [ -f $1 ] ; then
    case $1 in
      *.tar.bz2)   tar xjf $1     ;;
      *.tar.gz)    tar xzf $1     ;;
      *.tar.xz)    tar xvf $1     ;;
      *.bz2)       bunzip2 $1     ;;
      *.rar)       unrar e $1     ;;
      *.gz)        gunzip $1      ;;
      *.tar)       tar xf $1      ;;
      *.tbz2)      tar xjf $1     ;;
      *.tgz)       tar xzf $1     ;;
      *.zip)       unzip $1       ;;
      *.Z)         uncompress $1  ;;
      *.7z)        7z x $1        ;;
      *)           echo "'$1' cannot be extracted via extract()" ;;
    esac
  else
    echo "'$1' is not a valid file"
  fi
}

# Create a new directory and enter it
mkcd() {
  mkdir -p "$1" && cd "$1"
}

# Find file by name
ff() { find . -type f -name "*$1*"; }

# Find directory by name
fd() { find . -type d -name "*$1*"; }

# Show system info
xsysinfo() {
  echo -e "\nSystem Information:"
  echo -e "-------------------"
  echo -e "Hostname: $(hostname)"
  echo -e "Kernel: $(uname -r)"
  echo -e "Uptime: $(uptime -p)"
  echo -e "Shell: $SHELL"
  echo -e "Terminal: $TERM"
  echo -e "CPU: $(grep 'model name' /proc/cpuinfo | head -1 | cut -d':' -f2 | sed 's/^ *//')"
  echo -e "Memory: $(free -h | grep Mem | awk '{print $3 " used of " $2}')"
  echo -e "Disk usage: $(df -h / | tail -1 | awk '{print $3 " used of " $2 " (" $5 ")"}')"
  echo -e "Current theme: $THEME"
  echo -e "\nTip: Run 'bashapi' to see available commands and functions"
}

# Display available bash API functions and aliases in a stylized way
bashapi() {
  local blue="\033[38;5;33m"
  local cyan="\033[38;5;45m"
  local green="\033[38;5;46m"
  local yellow="\033[38;5;226m"
  local orange="\033[38;5;208m"
  local purple="\033[38;5;141m"
  local white="\033[38;5;15m"
  local reset="\033[0m"
  local bold="\033[1m"

  clear
  echo -e "${bold}${blue}╔════════════════════════════════════════════════════════════╗${reset}"
  echo -e "${bold}${blue}║                                                            ║${reset}"
  echo -e "${bold}${blue}║  ${cyan}BASH API REFERENCE${blue}                                      ║${reset}"
  echo -e "${bold}${blue}║                                                            ║${reset}"
  echo -e "${bold}${blue}╚════════════════════════════════════════════════════════════╝${reset}"
  echo

  # Theme Management
  echo -e "${bold}${purple}┌─ THEME MANAGEMENT ${reset}"
  echo -e "${green}├─ theme-material${reset}    Switch to Material Design theme"
  echo -e "${green}├─ theme-retro${reset}       Switch to Retro computing theme"
  echo -e "${green}├─ theme-tron${reset}        Switch to Tron-inspired theme"
  echo -e "${green}└─ theme-default${reset}     Switch to default bash theme"
  echo

  # System Functions
  echo -e "${bold}${purple}┌─ SYSTEM UTILITIES ${reset}"
  echo -e "${green}├─ xsysinfo${reset}          Display system information"
  echo -e "${green}├─ welcome${reset}          Show welcome screen with system stats"
  echo -e "${green}├─ extract <file>${reset}   Extract compressed archives of various types"
  echo -e "${green}├─ mkcd <dir>${reset}       Create a directory and cd into it"
  echo -e "${green}├─ ff <pattern>${reset}     Find files by name pattern"
  echo -e "${green}└─ fd <pattern>${reset}     Find directories by name pattern"
  echo

  # Development Tools
  echo -e "${bold}${purple}┌─ C DEVELOPMENT ${reset}"
  echo -e "${green}├─ cmk${reset}              Run cmake and make in build directory"
  echo -e "${green}├─ crun${reset}             Build and run the current project"
  echo -e "${green}└─ valg${reset}             Run valgrind with memory leak detection"
  echo
  
  echo -e "${bold}${purple}┌─ GO DEVELOPMENT ${reset}"
  echo -e "${green}├─ gob${reset}              go build"
  echo -e "${green}├─ gor${reset}              go run"
  echo -e "${green}├─ got${reset}              go test ./..."
  echo -e "${green}├─ goc${reset}              go clean"
  echo -e "${green}└─ gof${reset}              go fmt ./..."
  echo
  
  echo -e "${bold}${purple}┌─ PYTHON DEVELOPMENT ${reset}"
  echo -e "${green}├─ py${reset}               python3"
  echo -e "${green}├─ pyv${reset}              Create virtual environment"
  echo -e "${green}├─ pya${reset}              Activate virtual environment"
  echo -e "${green}├─ pyi <package>${reset}    Install Python package"
  echo -e "${green}└─ pyr${reset}              Install from requirements.txt"
  echo
  
  echo -e "${bold}${purple}┌─ ZIG DEVELOPMENT ${reset}"
  echo -e "${green}├─ zb${reset}               zig build"
  echo -e "${green}├─ zr${reset}               zig run"
  echo -e "${green}└─ zt${reset}               zig test"
  echo
  
  # Navigation and File Management
  echo -e "${bold}${purple}┌─ NAVIGATION ${reset}"
  echo -e "${green}├─ ..${reset}               Go up one directory"
  echo -e "${green}├─ ...${reset}              Go up two directories"
  echo -e "${green}├─ ....${reset}             Go up three directories"
  echo -e "${green}└─ .....${reset}            Go up four directories"
  echo
  
  echo -e "${bold}${purple}┌─ FILE OPERATIONS ${reset}"
  echo -e "${green}├─ ll${reset}               Detailed directory listing"
  echo -e "${green}├─ la${reset}               List all files including hidden"
  echo -e "${green}└─ l${reset}                Simplified directory listing"
  echo
  
  # Git Commands
  echo -e "${bold}${purple}┌─ GIT COMMANDS ${reset}"
  echo -e "${green}├─ gs${reset}               git status"
  echo -e "${green}├─ ga${reset}               git add"
  echo -e "${green}├─ gc${reset}               git commit"
  echo -e "${green}├─ gp${reset}               git push"
  echo -e "${green}├─ gl${reset}               git pull"
  echo -e "${green}├─ gd${reset}               git diff"
  echo -e "${green}├─ gb${reset}               git branch"
  echo -e "${green}├─ gco${reset}              git checkout"
  echo -e "${green}└─ glog${reset}             git log with graph"
  echo
  
  # System Management
  echo -e "${bold}${purple}┌─ SYSTEM MANAGEMENT ${reset}"
  echo -e "${green}├─ update${reset}           Update and upgrade packages"
  echo -e "${green}├─ install <pkg>${reset}    Install package"
  echo -e "${green}├─ remove <pkg>${reset}     Remove package"
  echo -e "${green}└─ syspkg${reset}           Install and make system packages executable"
  echo
  
  # History Management
  echo -e "${bold}${purple}┌─ HISTORY MANAGEMENT ${reset}"
  echo -e "${green}├─ Up Arrow${reset}         Search history backward (fish-like)"
  echo -e "${green}├─ Down Arrow${reset}       Search history forward (fish-like)"
  echo -e "${green}├─ Ctrl+r${reset}           Incremental history search"
  echo -e "${green}└─ history${reset}          Show command history"
  echo
  
  echo -e "${bold}${blue}╔════════════════════════════════════════════════════════════╗${reset}"
  echo -e "${bold}${blue}║  ${cyan}Happy coding!${blue}                                          ║${reset}"
  echo -e "${bold}${blue}╚════════════════════════════════════════════════════════════╝${reset}"
}

# Display a welcome message
welcome() {
  local blue="\033[38;5;33m"
  local cyan="\033[38;5;45m"
  local green="\033[38;5;46m"
  local yellow="\033[38;5;226m"
  local reset="\033[0m"
  local bold="\033[1m"
  
  clear
  echo -e "${bold}${blue}╔════════════════════════════════════════════════════════════╗${reset}"
  echo -e "${bold}${blue}║                                                            ║${reset}"
  echo -e "${bold}${blue}║  ${cyan}Welcome back, $(whoami)!${blue}                                  ║${reset}"
  echo -e "${bold}${blue}║                                                            ║${reset}"
  echo -e "${bold}${blue}╚════════════════════════════════════════════════════════════╝${reset}"
  
  echo -e "\n${bold}${yellow}Today is $(date '+%A, %B %d %Y')${reset}"
  echo -e "${bold}${yellow}Current time: $(date '+%H:%M:%S')${reset}"
  
  echo -e "\n${green}System load:${reset} $(cat /proc/loadavg | cut -d' ' -f1-3)"
  echo -e "${green}Memory usage:${reset} $(free -h | grep Mem | awk '{print $3 " used of " $2}')"
  echo -e "${green}Disk usage:${reset} $(df -h / | tail -1 | awk '{print $3 " used of " $2 " (" $5 ")"}')"
  
  echo -e "\n${cyan}Current theme:${reset} ${bold}$THEME${reset}"
  echo -e "${cyan}Available themes:${reset} material, retro, tron, default"
  echo -e "${cyan}To switch themes, use:${reset} theme-material, theme-retro, theme-tron, theme-default"
  
  echo -e "\n${bold}${yellow}TIP:${reset} Run '${bold}bashapi${reset}' to see all available commands and functions"
  echo
}

# Run welcome message on login
welcome

# Alias definitions.
# You may want to put all your additions into a separate file like
# ~/.bash_aliases, instead of adding them here directly.
# See /usr/share/doc/bash-doc/examples in the bash-doc package.

if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi

# enable programmable completion features (you don't need to enable
# this, if it's already enabled in /etc/bash.bashrc and /etc/profile
# sources /etc/bash.bashrc).
if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
fi

# Enhanced history search with up/down arrows (fish-like behavior)
# Use the up and down arrow keys for history search
bind '"\e[A": history-search-backward'
bind '"\e[B": history-search-forward'

# Ignore duplicates in command history and increase history size
HISTCONTROL=ignoredups:erasedups
HISTSIZE=10000
HISTFILESIZE=20000

# When the shell exits, append to the history file instead of overwriting it
shopt -s histappend

# After each command, append to the history file and reread it
PROMPT_COMMAND="${PROMPT_COMMAND:+$PROMPT_COMMAND$'\n'}history -a; history -c; history -r"

# Enable incremental history search with Ctrl+r
bind '"\C-r": reverse-search-history'

# Tab completion improvements
bind "set show-all-if-ambiguous on"
bind "set completion-ignore-case on"
bind "set menu-complete-display-prefix on"

# System package management function
syspkg() {
  local action=$1
  local package=$2
  
  case "$action" in
    install)
      echo "Installing system package: $package"
      sudo apt install -y "$package"
      ;;
    make-executable|exec)
      if [ -z "$package" ]; then
        echo "Please specify a file to make executable"
        return 1
      fi
      echo "Making $package executable"
      chmod +x "$package"
      ;;
    install-home)
      if [ -z "$package" ]; then
        echo "Please specify a file to install to ~"
        return 1
      fi
      echo "Installing $package to ~"
      sudo cp -r "$package" ~
      ;;
    install-script)
      if [ -z "$package" ]; then
        echo "Please specify a script to install to /usr/local/bin"
        return 1
      fi
      echo "Installing script $package to /usr/local/bin"
      sudo cp "$package" /usr/local/bin/
      sudo chmod +x "/usr/local/bin/$(basename "$package")"
      ;;
    list)
      echo "Installed system packages:"
      dpkg --get-selections | grep -v deinstall
      ;;
    help|*)
      echo "System Package Manager Usage:"
      echo "  syspkg install <package>      - Install a system package"
      echo "  syspkg exec <file>            - Make a file executable"
      echo "  syspkg make-executable <file> - Make a file executable (same as exec)"
      echo "  syspkg install-home <file>    - Install a file to ~"
      echo "  syspkg install-script <file>  - Install a script to /usr/local/bin"
      echo "  syspkg list                   - List installed packages"
      echo "  syspkg help                   - Show this help message"
      ;;
  esac
}

if [ -f ~/.bash_secrets ]; then
    . ~/.bash_secrets
fi

# Go environment variables
export GOPATH=$HOME/go
export GOROOT=$HOME/sdk/go1.24.2

# // https://nnethercote.github.io/perf-book/build-configuration.html
export MALLOC_CONF=thp:always,metadata_thp:always

# Zig environment variables
export ZIGROOT=$HOME/sdk/zig0.13.0

export PATH=$GOPATH/bin:$GOROOT/bin:$ZIGROOT:$PATH
