# ==============================================================================
# Zsh Aliases (aliases.zsh)
# ==============================================================================

# ------------------------------------------------------------------------------
# 1. 일반 유틸리티 & 시스템
# ------------------------------------------------------------------------------
alias c="clear"
alias cls="clear"
alias refresh="source ~/.zshrc"
alias myip="curl -4 -s ifconfig.me"

# modern ls (eza가 설치되어 있으면 사용)
if command -v eza &>/dev/null; then
  alias ls="eza --icons --sort=name"
  alias l="eza --icons --sort=name"
  alias ll="eza -la --icons --sort=name"
  alias lR="eza -R --icons --sort=name"
  alias llR="eza -laR --icons --sort=name"
fi

# modern cat (bat이 설치되어 있으면 사용)
if command -v bat &>/dev/null; then
  alias cat="bat"
fi

# ------------------------------------------------------------------------------
# 2. Git Aliases (Oh My Zsh 호환)
# ------------------------------------------------------------------------------
alias g="git"
alias gst="git status"
alias gss="git status -s"
alias gd="git diff"
alias gds="git diff --staged"
alias ga="git add"
alias gaa="git add --all"
alias gc="git commit -v"
alias gcm="git commit -m"
alias gca="git commit -v -a"
alias gcam="git commit -a -m"
alias gb="git branch"
alias gba="git branch -a"
alias gco="git checkout"
alias gcb="git checkout -b"
alias gsw="git switch"
alias gswc="git switch -c"
alias gp="git push"
alias gl="git pull"
alias gpl="git pull"
alias glg="git log --stat"
alias glo="git log --oneline --decorate"
alias glog="git log --oneline --decorate --graph"

# ------------------------------------------------------------------------------
# 3. 컨테이너 (Podman이 있을 경우에만 Docker Drop-in Replacement 적용)
# ------------------------------------------------------------------------------
if command -v podman &>/dev/null; then
  alias docker="podman"
  alias docker-compose="podman compose"
  alias pdps='podman ps -a --format "table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}"'
  alias pdls="pdps"
  alias pdlg="podman logs -tf"
  alias pdim="podman images -a"
  alias pdst="podman restart"
  alias pdsp="podman stop"
  alias pdrm="podman rm"
  alias pdri="podman image rm"
fi

# ------------------------------------------------------------------------------
# 4. Antigravity & AI 도구
# ------------------------------------------------------------------------------
alias as="agy-switch"
alias asw="agy-switch"

# ------------------------------------------------------------------------------
# 5. 브라우저 & 프로필
# ------------------------------------------------------------------------------
alias chls="chrome-profiles"
alias chn="chro new"

# ------------------------------------------------------------------------------
# 6. 보안 및 비밀번호 (KeePassXC)
# ------------------------------------------------------------------------------
if [ -d "/Applications/KeePassXC.app" ]; then
  alias keepassxc-cli="/Applications/KeePassXC.app/Contents/MacOS/keepassxc-cli"
fi

# ------------------------------------------------------------------------------
# 7. Neovim & 편집기 (Neovim manual 2212)
# ------------------------------------------------------------------------------
if command -v nvim &>/dev/null; then
  alias vim='nvim'
  alias vi='nvim'
  alias nv='nvim'
  alias vimdiff="nvim -d"
fi

# ------------------------------------------------------------------------------
# 8. Tmux 멀티플렉서 (tmux manual 2309)
# ------------------------------------------------------------------------------
alias tmls='tmux ls'
alias tmrs='tmux attach-session'
alias tmpg='tmux attach-session -t pgsql'
alias tmdl='tmux attach-session -t dlight'
alias tmun='tmux attach-session -t uxn'
alias tmpy='tmux attach-session -t python'

