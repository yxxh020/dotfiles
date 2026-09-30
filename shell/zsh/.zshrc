# ==============================================================================
# macOS Zsh Configuration (.zshrc) - Modular Entrypoint
# ==============================================================================

# 1. Homebrew Environment
if [ -x "/opt/homebrew/bin/brew" ]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [ -x "/usr/local/bin/brew" ]; then
  eval "$(/usr/local/bin/brew shellenv)"
fi

# 2. Path & Core Environment Variables
export PATH="/Applications/Visual Studio Code.app/Contents/Resources/app/bin:$HOME/.local/bin:$HOME/bin:$PATH"
export LANG="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"
export EDITOR="code --wait"

# 3. Oh My Zsh Configuration
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="agnoster"

# agnoster 테마에서 사용자명@호스트명(user@macbook)을 숨기고 깔끔하게 표시 (SSH 접속 시에만 표시)
DEFAULT_USER="$(whoami)"

plugins=(
  git
  zsh-autosuggestions
  zsh-syntax-highlighting
)

if [ -f "$ZSH/oh-my-zsh.sh" ]; then
  source "$ZSH/oh-my-zsh.sh"
fi

# 4. Source Modular Dotfiles Configs
DOTFILES_SHELL_DIR="${${(%):-%x}:A:h}"
if [ -d "$DOTFILES_SHELL_DIR" ]; then
  [ -f "$DOTFILES_SHELL_DIR/env.zsh" ] && source "$DOTFILES_SHELL_DIR/env.zsh"
  [ -f "$DOTFILES_SHELL_DIR/aliases.zsh" ] && source "$DOTFILES_SHELL_DIR/aliases.zsh"
  [ -f "$DOTFILES_SHELL_DIR/functions.zsh" ] && source "$DOTFILES_SHELL_DIR/functions.zsh"
fi

# 5. Local Override Configuration (머신별 독립 설정)
if [ -f "$HOME/.zshrc.local" ]; then
  source "$HOME/.zshrc.local"
fi
# The following lines have been added by Docker Desktop to enable Docker CLI completions.
fpath=(/Users/hwang/.docker/completions $fpath)
autoload -Uz compinit
(( ${+_comps[docker]} )) || compinit
# End of Docker CLI completions
