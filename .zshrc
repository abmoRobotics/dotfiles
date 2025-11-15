# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH

# Path to your oh-my-zsh installation.
  export ZSH=~/.oh-my-zsh

# Set name of the theme to load. Optionally, if you set this to "random"
# it'll load a random theme each time that oh-my-zsh is loaded.
# See https://github.com/robbyrussell/oh-my-zsh/wiki/Themes
#ZSH_THEME="pixegami-agnoster"
ZSH_THEME="powerlevel10k/powerlevel10k"

# Set list of themes to load
# Setting this variable when ZSH_THEME=random
# cause zsh load theme from this variable instead of
# looking in ~/.oh-my-zsh/themes/
# An empty array have no effect
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion. Case
# sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment the following line to disable bi-weekly auto-update checks.
# DISABLE_AUTO_UPDATE="true"

# Uncomment the following line to change how often to auto-update (in days).
# export UPDATE_ZSH_DAYS=13

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# The optional three formats: "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load? (plugins can be found in ~/.oh-my-zsh/plugins/*)
# Custom plugins may be added to ~/.oh-my-zsh/custom/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(
  git
  zsh-syntax-highlighting
  zsh-autosuggestions
)

source $ZSH/oh-my-zsh.sh

# User configuration

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='mvim'
# fi

# Compilation flags
# export ARCHFLAGS="-arch x86_64"

# ssh
# export SSH_KEY_PATH="~/.ssh/rsa_id"

# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"
# read "use_conda?Do you want to initialize conda? (y/n): "

# if [ "$use_conda" = "y" ]; then
#     __conda_setup="$('/home/anton/anaconda3/bin/conda' 'shell.zsh' 'hook' 2> /dev/null)"
#     if [ $? -eq 0 ]; then
#         eval "$__conda_setup"
#     else
#         if [ -f "/home/anton/anaconda3/etc/profile.d/conda.sh" ]; then
#             . "/home/anton/anaconda3/etc/profile.d/conda.sh"
#         else
#             export PATH="/home/anton/anaconda3/bin:$PATH"
#         fi
#     fi
#     unset __conda_setup
# else
#     if [ -f "/home/anton/anaconda3/etc/profile.d/conda.sh" ]; then
#         . "/home/anton/anaconda3/etc/profile.d/conda.sh"
#     fi
#     source /opt/ros/humble/setup.zsh
#     echo "ROS 2 Humble sourced."
# fi


[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# Function to initialize conda
function c() {
    __conda_setup="$('/home/anton/anaconda3/bin/conda' 'shell.zsh' 'hook' 2> /dev/null)"
    if [ $? -eq 0 ]; then
        eval "$__conda_setup"
    else
        if [ -f "/home/anton/anaconda3/etc/profile.d/conda.sh" ]; then
            . "/home/anton/anaconda3/etc/profile.d/conda.sh"
        else
            export PATH="/home/anton/anaconda3/bin:$PATH"
        fi
    fi
    unset __conda_setup
}

# Function to source ROS environment
function r() {
    if [ -d "./install" ]; then
        source ./install/setup.zsh
    else
        if [ -n "$ROS_DISTRO" ] && [ -f "/opt/ros/$ROS_DISTRO/setup.zsh" ]; then
            # Use currently selected ROS 2 distro
            source "/opt/ros/$ROS_DISTRO/setup.zsh"
        elif [ -f "/opt/ros/humble/setup.zsh" ]; then
            # Fallback to humble
            source /opt/ros/humble/setup.zsh
        elif [ -f "/opt/ros/iron/setup.zsh" ]; then
            source /opt/ros/iron/setup.zsh
        elif [ -f "/opt/ros/jazzy/setup.zsh" ]; then
            source /opt/ros/jazzy/setup.zsh
        else
            echo "No ROS 2 installation found under /opt/ros."
        fi
    fi
    echo "ROS 2 sourced."
}

# Function to build ROS 2 workspace
function rb() {
    r
    colcon build
    if [ -f "./install/setup.zsh" ]; then
        source ./install/setup.zsh
        echo "Build complete and local workspace sourced."
    else
        echo "Build complete, but no local 'install/setup.zsh' found to source."
    fi
}



# . "$HOME/.cargo/env"
# alias yazi='/home/anton/apps/yazi/target/release/yazi'

# function y() {
#     local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
#     yazi "$@" --cwd-file="$tmp"
#     if cwd="$(command cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
#         builtin cd -- "$cwd"
#     fi
#     rm -f -- "$tmp"
# }



eval "$(zoxide init posix --hook prompt)"
eval "$(zoxide init zsh)"

# [ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
alias e='exit && exit'
alias fd='fdfind'
# eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.

# export FZF_DEFAULT_COMMAND='fdfind --type f'
# export FZF_DEFAULT_OPTS="--layout=reverse --inline-info --height=80%"
# export FZF_DEFAULT_COMMAND="fd . $HOME"
# export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
# export FZF_ALT_C_COMMAND="fd -t d . $HOME"

#typeset -g POWERLEVEL9K_INSTANT_PROMPT=off
# Custom Zsh startup message for AAU SPACE ROBOTICS

# Colors for styling
YELLOW="\033[1;33m"
BLUE="\033[1;34m"
CYAN="\033[1;36m"
RESET="\033[0m"

# Function to fetch system details
fetch_system_info() {
    # CONDA status
    CONDA_STATUS="deactivated"
    
    # ROS2 Version
    ROS2_VERSION=$(ros2 --version 2>/dev/null || echo "ROS2 not installed")
    
    # Operating System
    OS_NAME=$(uname -o)
    
    # Kernel version
    KERNEL_VERSION=$(uname -r)
    
    # Terminal type
    TERMINAL_TYPE=$TERM
    
    # Terminal font (if set)
    TERMINAL_FONT=$(fc-match monospace | cut -d: -f1)
    
    # CPU Info
    CPU_MODEL=$(lscpu | grep "Model name:" | sed 's/Model name:\s*//')
    
    # GPU Info
    GPU_MODEL=$(lspci | grep VGA | cut -d: -f3 | head -n 1 || echo "No GPU detected")
    
    # Memory info (total)
    MEMORY_TOTAL=$(free -h | grep "Mem:" | awk '{print $2}')
}
#typeset -g POWERLEVEL9K_INSTANT_PROMPT=quiet

# Call the function to populate system info variables
# Function for custom startup message
custom_startup_message() {
    # Colors for styling
    YELLOW="\033[1;33m"
    BLUE="\033[1;34m"
    CYAN="\033[1;36m"
    RESET="\033[0m"

    # Function to fetch system details
    fetch_system_info() {
        # CONDA status
        CONDA_STATUS="deactivated"
        
        # ROS2 Version
        ROS2_VERSION=$(ros2 --version 2>/dev/null || echo "ROS2 not installed")
        
        # Operating System
        OS_NAME=$(uname -o)
        
        # Kernel version
        KERNEL_VERSION=$(uname -r)
        
        # Terminal type
        TERMINAL_TYPE=$TERM
        
        # Terminal font (if set)
        TERMINAL_FONT=$(fc-match monospace | cut -d: -f1)
        
        # CPU Info
        CPU_MODEL=$(lscpu | grep "Model name:" |sed 's/Model name:\s*//')
        
        # GPU Info
        GPU_MODEL=$(lspci | grep VGA | cut -d: -f3 | head -n 1 || echo "No GPU detected")
        
        # Memory info (total)
        MEMORY_TOTAL=$(free -h | grep "Mem:" | awk '{print $2}')
    }

    # Call the function to populate system info variables
    fetch_system_info

    # Display custom startup message
    echo -e "${YELLOW}========================================${RESET}"
    echo -e "${CYAN}           AAU SPACE ROBOTICS           ${RESET}"
    echo -e "${CYAN}           AALBORG UNIVERSITY           ${RESET}"
    echo -e "${CYAN}                 PHD                    ${RESET}"
    echo -e "${CYAN}        Anton Bjørndahl Mortensen       ${RESET}"
    echo -e "${YELLOW}========================================${RESET}"
    echo -e "${BLUE}CONDA Status:        ${RESET}${CONDA_STATUS}"
    echo -e "${BLUE}ROS2 Version:        ${RESET}${ROS2_VERSION}"
    echo -e "${YELLOW}----------------------------------------${RESET}"
    echo -e "${BLUE}Operating System:    ${RESET}${OS_NAME}"
    echo -e "${BLUE}Kernel Version:      ${RESET}${KERNEL_VERSION}"
    echo -e "${YELLOW}----------------------------------------${RESET}"
    echo -e "${BLUE}Terminal:            ${RESET}${TERMINAL_TYPE}"
    echo -e "${BLUE}Terminal Font:       ${RESET}${TERMINAL_FONT}"
    echo -e "${YELLOW}----------------------------------------${RESET}"
    echo -e "${BLUE}CPU Model:           ${RESET}${CPU_MODEL}"
    echo -e "${BLUE}GPU Model:           ${RESET}${GPU_MODEL}"
    echo -e "${BLUE}Total Memory:        ${RESET}${MEMORY_TOTAL}"
    echo -e "${YELLOW}========================================${RESET}"
}

# Call custom startup message function after prompt setup
#custom_startup_message
export PATH=~/usdview/scripts/:$PATH

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
eval $(keychain --eval --quiet id_ed25519)
#export SSH_AUTH_SOCK="$XDG_RUNTIME_DIR/ssh-agent.socket"

# --- Global Python virtual environment ---
GLOBAL_VENV="$HOME/.global-venv"
if command -v python3 >/dev/null 2>&1; then
    if [ ! -d "$GLOBAL_VENV" ]; then
        python3 -m venv "$GLOBAL_VENV" 2>/dev/null || true
    fi
    if [ -f "$GLOBAL_VENV/bin/activate" ]; then
        . "$GLOBAL_VENV/bin/activate"
    fi
fi

# Function to activate global Python virtual environment
function p() {
    local GLOBAL_VENV="$HOME/.global-venv"

    if [ ! -d "$GLOBAL_VENV" ]; then
        echo "Global venv not found at $GLOBAL_VENV. Creating it..."
        if command -v python3 >/dev/null 2>&1; then
            python3 -m venv "$GLOBAL_VENV" || {
                echo "Failed to create global venv."; return 1; }
        else
            echo "python3 not found. Cannot create global venv."; return 1
        fi
    fi

    if [ -f "$GLOBAL_VENV/bin/activate" ]; then
        . "$GLOBAL_VENV/bin/activate"
        echo "Activated global venv at $GLOBAL_VENV."
    else
        echo "Activate script not found in $GLOBAL_VENV/bin/activate."
        return 1
    fi
}
