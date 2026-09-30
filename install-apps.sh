#!/usr/bin/env bash
# ==============================================================================
# macOS Complete App & Tool Installer (install-apps.sh)
# 새 맥북에서 이 스크립트 하나로 모든 필수 도구가 설치됩니다.
# ==============================================================================
set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "========================================"
echo "  🍏 macOS 개발 환경 자동 설치 시작"
echo "========================================"

# ---------- [1/6] Homebrew ----------
echo ""
echo "🍺 [1/6] Homebrew 설치 확인..."
if ! command -v brew &>/dev/null; then
  echo "Homebrew가 없어 설치를 시작합니다..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  eval "$(/opt/homebrew/bin/brew shellenv)"
else
  echo "✅ Homebrew가 이미 설치되어 있습니다."
fi

# ---------- [2/6] Brewfile 기반 일괄 설치 ----------
echo ""
echo "📦 [2/6] Brewfile 기반 도구 및 앱 일괄 설치..."
echo "   (Git, gh, VS Code, Docker, Podman, KeePassXC, Ghostty,"
echo "    Azure Data Studio, DBeaver, Obsidian, AltTab, Rectangle, Raycast...)"
brew bundle --file="$DOTFILES_DIR/Brewfile"

# ---------- [3/6] Node.js & 패키지 매니저 ----------
echo ""
echo "⚡ [3/6] Node.js LTS 및 글로벌 패키지 매니저(pnpm, bun) 설치..."
eval "$(fnm env --use-on-cd 2>/dev/null || true)"
fnm install --lts
fnm default lts-latest
npm install -g pnpm bun

# ---------- [4/6] AI 코딩 에이전트 & IDE ----------
echo ""
echo "🤖 [4/6] AI 코딩 도구 설치 (Antigravity & Orca)..."
# Antigravity CLI (agy)
if ! command -v agy &>/dev/null; then
  echo "Antigravity CLI 설치 중..."
  brew install antigravity-cli 2>/dev/null || curl -fsSL https://antigravity.google/cli/install.sh | bash || true
else
  echo "✅ Antigravity CLI(agy)가 이미 설치되어 있습니다."
fi

# Antigravity IDE (GUI 앱)
if ! brew list --cask antigravity-ide &>/dev/null; then
  echo "Antigravity IDE 설치 중..."
  brew install --cask antigravity-ide || true
else
  echo "✅ Antigravity IDE가 이미 설치되어 있습니다."
fi

# Orca 데스크톱 자동 설치
if ! brew list --cask orca &>/dev/null; then
  echo "Orca 데스크톱 설치 중..."
  brew tap stablyai/orca
  brew install --cask stablyai/orca/orca || true
else
  echo "✅ Orca가 이미 설치되어 있습니다."
fi

# ---------- [5/6] Podman 컨테이너 머신 초기화 ----------
echo ""
echo "🐳 [5/6] Podman 컨테이너 머신 초기화..."
if command -v podman &>/dev/null; then
  if ! podman machine list --noheading 2>/dev/null | grep -q "podman-machine-default"; then
    echo "Podman 가상 머신(VM)을 초기화하고 시작합니다..."
    podman machine init || true
    podman machine start || true
  else
    echo "✅ Podman 가상 머신이 이미 준비되어 있습니다."
  fi
fi

# ---------- [6/6] 작업 디렉토리 생성 ----------
echo ""
echo "📂 [6/6] 기본 작업 디렉토리 생성..."
mkdir -p "$HOME/personal" "$HOME/orca"

echo ""
echo "========================================"
echo "  🎉 macOS 개발 환경 설치 완료!"
echo "========================================"
echo ""
echo "📋 다음 단계를 진행하세요:"
echo "  1) bash install.sh          ← Git/셸 설정 심볼릭 링크 연결"
echo "  2) gh auth login -u yxxh020 ← 개인 GitHub 계정 로그인"
echo "  3) gh auth login -u YiranHwang ← 회사 GitHub 계정 로그인"
echo ""
echo "💡 설치된 주요 도구:"
echo "  컨테이너  : docker (Docker Desktop) + podman (무료 대안)"
echo "  DB 쿼리   : Azure Data Studio (SSMS 대체) + DBeaver"
echo "  원격 접속  : Windows App (RDCMan 대체 RDP 클라이언트)"
echo "  지식 관리  : Obsidian"
echo "  생산성     : AltTab + Rectangle + Raycast"
