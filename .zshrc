# Source from https://github.com/dreamsofautonomy/zensh/blob/main/.zshrc

# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

if [[ -f "/opt/homebrew/bin/brew" ]] then
  # If you're using macOS, you'll want this enabled
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# Set the directory we want to store zinit and plugins
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"

# Download Zinit, if it's not there yet
if [ ! -d "$ZINIT_HOME" ]; then
   mkdir -p "$(dirname $ZINIT_HOME)"
   git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
fi

# Source/Load zinit
source "${ZINIT_HOME}/zinit.zsh"

# Add in Powerlevel10k
zinit ice depth=1; zinit light romkatv/powerlevel10k

# Add in zsh plugins
zinit light zsh-users/zsh-syntax-highlighting
zinit light zsh-users/zsh-completions
zinit light zsh-users/zsh-autosuggestions
zinit light Aloxaf/fzf-tab

# Add in snippets
zinit snippet OMZL::git.zsh
zinit snippet OMZP::git
zinit snippet OMZP::sudo
zinit snippet OMZP::archlinux
zinit snippet OMZP::aws
zinit snippet OMZP::kubectl
zinit snippet OMZP::kubectx
zinit snippet OMZP::command-not-found

# Load completions
autoload -Uz compinit && compinit

zinit cdreplay -q

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# Keybindings
bindkey -e
bindkey '^p' history-search-backward
bindkey '^n' history-search-forward
bindkey '^[w' kill-region
bindkey ' ' magic-space

# Standard navigation keys (Home, End, Delete)
bindkey "${terminfo[khome]}" beginning-of-line      # Home
bindkey "^[[H"               beginning-of-line      # Home (fallback)
bindkey "^[OH"               beginning-of-line      # Home (xterm fallback)
bindkey "^[[1~"              beginning-of-line      # Home (vt fallback)
bindkey "^[[7~"              beginning-of-line      # Home (urxvt fallback)

bindkey "${terminfo[kend]}"  end-of-line            # End
bindkey "^[[F"               end-of-line            # End (fallback)
bindkey "^[OF"               end-of-line            # End (xterm fallback)
bindkey "^[[4~"              end-of-line            # End (vt fallback)
bindkey "^[[8~"              end-of-line            # End (urxvt fallback)

bindkey "${terminfo[kdch1]}" delete-char            # Delete
bindkey "^[[3~"              delete-char            # Delete (fallback)

# Word jumps with Ctrl+Left / Ctrl+Right (Optional bonus)
bindkey "^[[1;5C"            forward-word           # Ctrl+Right
bindkey "^[[1;5D"            backward-word          # Ctrl+Left


# History
HISTSIZE=5000
HISTFILE=~/.zsh_history
SAVEHIST=$HISTSIZE
HISTDUP=erase
setopt appendhistory
setopt sharehistory
setopt hist_ignore_space
setopt hist_ignore_all_dups
setopt hist_save_no_dups
setopt hist_ignore_dups
setopt hist_find_no_dups

# Completion styling
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' menu no
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls --color $realpath'
zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'ls --color $realpath'

# Open buffer line in editor
autoload -Uz edit-command-line
zle -N edit-command-line
bindkey '^X^E' edit-command-line

# Dotfiles
alias dots='/usr/bin/git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME'
compdef _git dots
alias ldots='lazygit --git-dir=$HOME/.dotfiles --work-tree=$HOME'
bindkey -M emacs -s 'cdots' 'dots commit -m ""\C-b'

# Aliases
alias ls='exa'
alias vim='nvim'
alias c='clear'

# Suffix Aliases
alias -s md="bat"
alias -s mov="open"
alias -s png="open"
alias -s mp4="open"
alias -s go="$EDITOR"
alias -s js="$EDITOR"
alias -s ts="$EDITOR"
alias -s yaml="$EDITOR"
alias -s yml="$EDITOR"
alias -s json="jless"

# Shell integrations
eval "$(fzf --zsh)"
eval "$(zoxide init --cmd cd zsh)"

# Editor
export VISUAL=/usr/bin/nvim
export EDITOR=/usr/bin/nvim

# Clear screen, keep buffer
clear-keep-buffer() {
  zle clear-screen
}
zle -N clear-keep-buffer
bindkey '^XL' clear-keep-buffer

# Copy current command to clipboard
copy-command() {
  echo -n $BUFFER | pbcopy
  zle -M "Copied to clipboard"
}
zle -N copy-command
bindkey '^XC' copy-command

# Skip comments
setopt interactive_comments

