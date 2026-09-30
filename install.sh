#!/usr/bin/env bash
# ==============================================================================
# macOS Dotfiles Installation & Symlink Script
# ==============================================================================
set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "🚀 [1/4] macOS 기본 작업 디렉토리 생성 (~/personal, ~/orca)..."
mkdir -p "$HOME/personal" "$HOME/orca"

echo "🔗 [2/4] Git 설정 심볼릭 링크 연결..."
ln -sf "$DOTFILES_DIR/git/.gitconfig" "$HOME/.gitconfig"
ln -sf "$DOTFILES_DIR/git/.gitconfig-personal" "$HOME/.gitconfig-personal"
ln -sf "$DOTFILES_DIR/git/.gitconfig-orca" "$HOME/.gitconfig-orca"

echo "🐚 [3/4] Zsh 셸 설정(.zshrc) 심볼릭 링크 연결..."
if [ -f "$HOME/.zshrc" ] && [ ! -L "$HOME/.zshrc" ]; then
    echo "⚠️ 기존 ~/.zshrc 파일을 ~/.zshrc.backup으로 백업합니다."
    mv "$HOME/.zshrc" "$HOME/.zshrc.backup"
fi
ln -sf "$DOTFILES_DIR/shell/zsh/.zshrc" "$HOME/.zshrc"

echo "🔑 [4/4] SSH 디렉토리 확인..."
mkdir -p "$HOME/.ssh"
chmod 700 "$HOME/.ssh"
if [ ! -f "$HOME/.ssh/config" ]; then
    cp "$DOTFILES_DIR/ssh/config.example" "$HOME/.ssh/config"
    chmod 600 "$HOME/.ssh/config"
    echo "ℹ️ ~/.ssh/config 템플릿을 생성했습니다."
fi

echo ""
echo "✅ macOS Dotfiles 설치가 완료되었습니다!"
echo "👉 새 터미널을 열거나 'source ~/.zshrc'를 실행하세요."
echo "👉 'gh auth login'으로 GitHub 계정들을 로그인하세요."
