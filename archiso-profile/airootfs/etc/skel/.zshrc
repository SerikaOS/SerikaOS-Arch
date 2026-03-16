# SerikaOS — Default .zshrc
# Premium Zsh experience

# ── Prompt ──
autoload -U colors && colors
PROMPT='%F{#e8a0bf}%n%F{#6a6a8a}@%F{#5cc6d0}%m %F{#d4a853}%~ %F{#e8a0bf}❯%f '
RPROMPT='%F{#3a3b4e}%*%f'

# ── Completion ──
autoload -Uz compinit
compinit
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"

# ── History ──
HISTSIZE=10000
SAVEHIST=10000
HISTFILE=~/.zsh_history
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE
setopt SHARE_HISTORY
setopt APPEND_HISTORY

# ── Key bindings ──
bindkey -e
bindkey '^[[A' history-search-backward
bindkey '^[[B' history-search-forward
bindkey '^[[H' beginning-of-line
bindkey '^[[F' end-of-line
bindkey '^[[3~' delete-char

# ── Aliases ──
alias ls='ls --color=auto'
alias ll='ls -lah --color=auto'
alias la='ls -A --color=auto'
alias grep='grep --color=auto'
alias diff='diff --color=auto'
alias cp='cp -iv'
alias mv='mv -iv'
alias rm='rm -Iv'
alias mkdir='mkdir -pv'

# Package management
alias pac='sudo pacman -S'
alias pacs='pacman -Ss'
alias pacu='sudo pacman -Syu'
alias pacr='sudo pacman -Rns'

# System
alias sysinfo='fastfetch'
alias update='sudo pacman -Syu'

# ── Environment ──
export EDITOR=nano
export VISUAL=nano
export PAGER=less

# ── Plugins (if installed) ──
[[ -f /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh ]] && \
    source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
[[ -f /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]] && \
    source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# ── Fastfetch on first terminal ──
if [[ -z "$SERIKAOS_FETCHED" ]] && command -v fastfetch &>/dev/null; then
    export SERIKAOS_FETCHED=1
    fastfetch
fi
