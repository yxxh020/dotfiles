# ==============================================================================
# macOS Zsh Configuration (.zshrc)
# ==============================================================================

# 1. Path & Environment Variables
export PATH="/Applications/Visual Studio Code.app/Contents/Resources/app/bin:$HOME/.local/bin:$HOME/bin:/opt/homebrew/bin:$PATH"
export LANG="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"
export EDITOR="code --wait"

# 2. Node.js (fnm) Init
if command -v fnm &>/dev/null; then
  eval "$(fnm env --use-on-cd)"
fi

# 3. Oh My Posh / Starship Prompt (선택)
if command -v oh-my-posh &>/dev/null; then
  eval "$(oh-my-posh init zsh)"
fi

# ------------------------------------------------------------------------------
# 4. GitHub CLI (gh) 디렉토리별 계정 자동 전환 래퍼
# ------------------------------------------------------------------------------
gh() {
  local target_user=""
  if [[ "$PWD" == "$HOME/personal"* ]]; then
    target_user="yxxh020"
  elif [[ "$PWD" == "$HOME/orca"* ]]; then
    target_user="YiranHwang"
  fi

  if [[ -n "$target_user" && "$1" != "auth" ]]; then
    local token
    token=$(command gh auth token --user "$target_user" 2>/dev/null)
    if [[ -n "$token" ]]; then
      GH_TOKEN="$token" command gh "$@"
      return
    fi
  fi

  command gh "$@"
}

# ------------------------------------------------------------------------------
# 5. Git Aliases (Oh My Zsh 호환)
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
alias gpl="git pull"
alias glg="git log --stat"
alias glo="git log --oneline --decorate"
alias c="clear"

# ------------------------------------------------------------------------------
# 6. Container Aliases (Docker -> Podman Drop-in Replacement)
# ------------------------------------------------------------------------------
alias docker="podman"
alias docker-compose="podman compose"
