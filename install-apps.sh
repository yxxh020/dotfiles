#!/usr/bin/env bash
# ==============================================================================
# macOS Complete App & Tool Installer (install-apps.sh)
# ==============================================================================
set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "🍺 [1/5] Homebrew 설치 확인 및 설치..."
if ! command -v brew &>/dev/null; then
  echo "Homebrew가 없어 설치를 시작합니다..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  eval "$(/opt/homebrew/bin/brew shellenv)"
else
  echo "✅ Homebrew가 이미 설치되어 있습니다."
fi

echo "📦 [2/5] Brewfile 기반 필수 애플리케이션 및 CLI 일괄 설치..."
# VS Code, Docker, KeePassXC, Azure Data Studio(SSMS 대체), DBeaver, Ghostty 등
brew bundle --file="$DOTFILES_DIR/Brewfile"

echo "⚡ [3/5] Node.js LTS 및 글로벌 패키지 매니저(pnpm, bun) 설치..."
eval "$(fnm env --use-on-cd 2>/dev/null || true)"
fnm install --lts
fnm default lts-latest
npm install -g pnpm bun

echo "🤖 [4/5] AI 도구 설치..."
# 1) Antigravity CLI 설치 (공식 curl 인스톨러 사용 시)
if ! command -v agy &>/dev/null; then
  echo "Antigravity CLI 설치 중..."
  curl -fsSL https://antigravity.google/install.sh 2>/dev/null | bash || true
fi

# 2) Orca 데스크톱 다운로드 안내
echo "ℹ️ Orca 데스크톱은 https://onorca.dev 에서 macOS(Apple Silicon/Intel) 버전을 다운로드할 수 있습니다."

echo ""
echo "🎉 모든 애플리케이션 및 개발 환경 설치가 완료되었습니다!"
echo "👉 데이터베이스 작업은 SSMS 대체인 'Azure Data Studio' 또는 'DBeaver'를 실행하세요."
