# ==============================================================================
# Zsh Environment (.zshenv) - 비대화형 서브쉘 포함 상시 로드
# ==============================================================================

# 비대화형 서브쉘에서도 alias 확장 활성화
setopt aliases

# Git 단축키 (비대화형 서브쉘 완벽 호환을 위해 함수 및 alias 병행 정의)
gl()  { git pull --rebase "$@"; }
gL()  { git pull --rebase "$@"; }
gp()  { git push "$@"; }
gst() { git status "$@"; }
gb()  { git branch "$@"; }
grb() { git rebase "$@"; }

alias gl="git pull --rebase"
alias gL="git pull --rebase"
alias gp="git push"
alias gst="git status"
alias gb="git branch"
alias grb="git rebase"
