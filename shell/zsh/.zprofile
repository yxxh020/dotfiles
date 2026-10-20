# ==============================================================================
# Zsh Profile (.zprofile) - 로그인 셸 초기화
# ==============================================================================

# Homebrew 환경 로드 (Apple Silicon / Intel 자동 감지)
if [ -x "/opt/homebrew/bin/brew" ]; then
  eval "$(/opt/homebrew/bin/brew shellenv zsh)"
elif [ -x "/usr/local/bin/brew" ]; then
  eval "$(/usr/local/bin/brew shellenv zsh)"
fi
