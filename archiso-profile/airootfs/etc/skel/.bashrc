# SerikaOS — Default .bashrc
# Premium shell experience

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

# ── Prompt ──
PS1='\[\033[38;2;232;160;191m\]\u\[\033[38;2;106;106;138m\]@\[\033[38;2;92;198;208m\]\h \[\033[38;2;212;168;83m\]\w \[\033[38;2;232;160;191m\]❯\[\033[0m\] '

# ── Aliases ──
alias ls='ls --color=auto'
alias ll='ls -lah --color=auto'
alias la='ls -A --color=auto'
alias l='ls -CF --color=auto'
alias grep='grep --color=auto'
alias diff='diff --color=auto'
alias ip='ip -color=auto'
alias cp='cp -iv'
alias mv='mv -iv'
alias rm='rm -Iv'
alias mkdir='mkdir -pv'

# Package management
alias pac='sudo pacman -S'
alias pacs='pacman -Ss'
alias pacu='sudo pacman -Syu'
alias pacr='sudo pacman -Rns'
alias pacq='pacman -Q'

# System
alias sysinfo='fastfetch'
alias update='sudo pacman -Syu'
alias cleanup='sudo pacman -Rns $(pacman -Qdtq) 2>/dev/null; sudo pacman -Sc --noconfirm'

# ── Environment ──
export EDITOR=nano
export VISUAL=nano
export PAGER=less
export LESS='-R --mouse'

# ── History ──
HISTSIZE=10000
HISTFILESIZE=20000
HISTCONTROL=ignoreboth:erasedups
shopt -s histappend

# ── Shell options ──
shopt -s checkwinsize
shopt -s globstar 2>/dev/null
shopt -s autocd 2>/dev/null

# ── Fastfetch on first terminal ──
if [[ -z "$SERIKAOS_FETCHED" ]] && command -v fastfetch &>/dev/null; then
    export SERIKAOS_FETCHED=1
    fastfetch
fi
