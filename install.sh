#!/usr/bin/env bash
# ==============================================================================
# macOS Dotfiles Installation & Symlink Script
# ==============================================================================
set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "🚀 [1/7] 기본 작업 디렉토리 생성 (~/personal, ~/orca)..."
mkdir -p "$HOME/personal" "$HOME/orca"

echo "🔗 [2/7] Git 설정 심볼릭 링크 연결..."
ln -sf "$DOTFILES_DIR/git/.gitconfig" "$HOME/.gitconfig"
ln -sf "$DOTFILES_DIR/git/.gitconfig-personal" "$HOME/.gitconfig-personal"
ln -sf "$DOTFILES_DIR/git/.gitconfig-orca" "$HOME/.gitconfig-orca"

echo "🐚 [3/7] Oh My Zsh 및 추천 플러그인 확인..."
if command -v zsh &>/dev/null; then
    if [ ! -d "$HOME/.oh-my-zsh" ]; then
        echo "   -> Oh My Zsh 설치 중..."
        RUNZSH=no KEEP_ZSHRC=yes sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" || true
    fi
    ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
    if [ -d "$HOME/.oh-my-zsh" ]; then
        if [ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]; then
            git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
        fi
        if [ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]; then
            git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
        fi
    fi
else
    echo "   ⚠️ zsh가 설치되어 있지 않아 Oh My Zsh 설치를 건너뜁니다. (sudo apt install -y zsh 후 다시 실행 가능)"
fi

echo "🐚 [4/7] Zsh 셸 설정(.zshrc) 심볼릭 링크 연결..."
if [ -f "$HOME/.zshrc" ] && [ ! -L "$HOME/.zshrc" ]; then
    echo "⚠️ 기존 ~/.zshrc 파일을 ~/.zshrc.backup으로 백업합니다."
    mv "$HOME/.zshrc" "$HOME/.zshrc.backup"
fi
ln -sf "$DOTFILES_DIR/shell/zsh/.zshrc" "$HOME/.zshrc"

echo "🛠️ [5/7] 커스텀 CLI 바이너리 도구 (~/.local/bin) 심볼릭 링크 연결..."
mkdir -p "$HOME/.local/bin"
if [ -d "$DOTFILES_DIR/bin" ]; then
    for bin_file in "$DOTFILES_DIR/bin"/*; do
        if [ -f "$bin_file" ]; then
            chmod +x "$bin_file"
            ln -sf "$bin_file" "$HOME/.local/bin/$(basename "$bin_file")"
            echo "   -> $(basename "$bin_file") 연결 완료"
        fi
    done
fi

echo "🤖 [6/7] Gemini & Antigravity 전역 작업 규칙 (~/.gemini/GEMINI.md) 연결..."
mkdir -p "$HOME/.gemini" "$HOME/.gemini/config"
if [ -f "$DOTFILES_DIR/.gemini/GEMINI.md" ]; then
    ln -sf "$DOTFILES_DIR/.gemini/GEMINI.md" "$HOME/.gemini/GEMINI.md"
    ln -sf "$DOTFILES_DIR/.gemini/GEMINI.md" "$HOME/.gemini/config/GEMINI.md"
    echo "   -> ~/.gemini/GEMINI.md 및 ~/.gemini/config/GEMINI.md 연결 완료"
fi

echo "🔑 [7/9] SSH 디렉토리 확인..."
mkdir -p "$HOME/.ssh"
chmod 700 "$HOME/.ssh"
if [ ! -f "$HOME/.ssh/config" ]; then
    cp "$DOTFILES_DIR/ssh/config.example" "$HOME/.ssh/config"
    chmod 600 "$HOME/.ssh/config"
    echo "ℹ️ ~/.ssh/config 템플릿을 생성했습니다."
fi

echo "🪟 [8/9] Tmux 및 Vim/Neovim 설정 심볼릭 링크 연결..."
if [ -f "$DOTFILES_DIR/tmux/.tmux.conf" ]; then
    ln -sf "$DOTFILES_DIR/tmux/.tmux.conf" "$HOME/.tmux.conf"
    echo "   -> ~/.tmux.conf 연결 완료"
fi
if [ -f "$DOTFILES_DIR/vim/.vimrc" ]; then
    ln -sf "$DOTFILES_DIR/vim/.vimrc" "$HOME/.vimrc"
    echo "   -> ~/.vimrc 연결 완료"
fi
if [ -d "$DOTFILES_DIR/nvim" ]; then
    mkdir -p "$HOME/.config"
    ln -sfn "$DOTFILES_DIR/nvim" "$HOME/.config/nvim"
    echo "   -> ~/.config/nvim 연결 완료"
fi

echo "🐚 [9/9] Bash 셸 통합 설정 (~/.bash_aliases) 확인..."
if [ ! -f "$HOME/.bash_aliases" ] || ! grep -q "Dotfiles Bash Integration" "$HOME/.bash_aliases"; then
    cat << 'EOF' > "$HOME/.bash_aliases"
# Dotfiles Bash Integration
export PATH="$HOME/.local/bin:$PATH"

if [ -f "$HOME/personal/dotfiles/shell/zsh/aliases.zsh" ]; then
    . "$HOME/personal/dotfiles/shell/zsh/aliases.zsh"
fi

if [ -f "$HOME/personal/dotfiles/shell/zsh/functions.zsh" ]; then
    . "$HOME/personal/dotfiles/shell/zsh/functions.zsh"
fi

if command -v zoxide &>/dev/null; then
    eval "$(zoxide init bash --cmd cd)"
fi

if command -v fzf &>/dev/null; then
    eval "$(fzf --bash 2>/dev/null || true)"
    if command -v fd &>/dev/null; then
        export FZF_DEFAULT_COMMAND='fd --type f --hidden --exclude .git .'
        export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
        export FZF_ALT_C_COMMAND='fd --type d --hidden --exclude .git .'
    fi
fi

if [ -f "$HOME/.dir_colors" ]; then
    eval "$(dircolors "$HOME/.dir_colors")"
fi
EOF
    echo "   -> ~/.bash_aliases 생성 및 연동 완료"
fi

echo ""
echo "✅ Dotfiles 설치 및 심볼릭 링크 연결이 완료되었습니다!"
echo "👉 새 터미널을 열거나 'source ~/.zshrc'를 실행하세요."
echo "👉 'gh auth login'으로 GitHub 계정들을 로그인하세요."
