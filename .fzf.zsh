# Setup fzf
# ---------
if [[ ! "$PATH" == */home/anton/apps/fzf/bin* ]]; then
  PATH="${PATH:+${PATH}:}/home/anton/apps/fzf/bin"
fi

source <(fzf --zsh)
