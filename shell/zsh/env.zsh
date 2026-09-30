# ==============================================================================
# Zsh Environment & Runtimes (env.zsh)
# ==============================================================================

# 1. Node.js (fnm)
if command -v fnm &>/dev/null; then
  eval "$(fnm env --use-on-cd --shell zsh)"
fi

# 2. zoxide (Smart cd)
if command -v zoxide &>/dev/null; then
  eval "$(zoxide init zsh --cmd cd)"
fi

# 3. fzf 기본 검색 엔진 (fd 활용)
if command -v fd &>/dev/null; then
  export FZF_DEFAULT_COMMAND='fd --type f --hidden --exclude .git .'
  export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
fi

# 4. direnv 자동 훅
if command -v direnv &>/dev/null; then
  eval "$(direnv hook zsh)"
fi

# 5. eza 색상 테마
export EZA_COLORS="*.old=38;5;242:tm=38;5;242"

# 6. 키 바인딩 및 히스토리
HISTFILE="$HOME/.zsh_history"
HISTSIZE=10000
SAVEHIST=10000
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_REDUCE_BLANKS
setopt SHARE_HISTORY
