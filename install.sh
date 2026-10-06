#!/usr/bin/env bash
# ==============================================================================
# Cross-Platform Dotfiles Installation & Symlink Script (macOS & Linux)
# ==============================================================================
set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OS_TYPE="$(uname -s)"

echo "🔍 감지된 운영체제: $OS_TYPE"

# ------------------------------------------------------------------------------
# 1. OS별 필수 시스템 패키지 설치 함수
# ------------------------------------------------------------------------------
install_system_packages() {
    if [ "$OS_TYPE" = "Linux" ]; then
        echo "🐧 [Linux] 표준 사용자 폴더 영문 고정 (Desktop, Downloads 등)..."
        mkdir -p "$HOME/.config"
        echo "enabled=False" > "$HOME/.config/user-dirs.conf"
        echo "en_US" > "$HOME/.config/user-dirs.locale"
        if command -v xdg-user-dirs-update &>/dev/null; then
            LC_ALL=C xdg-user-dirs-update --force
        fi

        if command -v apt-get &>/dev/null; then
            REQUIRED_PACKAGES=(zsh curl git tmux vim neovim fzf docker.io remmina remmina-plugin-rdp)
            MISSING_PACKAGES=()
            for pkg in "${REQUIRED_PACKAGES[@]}"; do
                case "$pkg" in
                    docker.io) check_cmd="docker" ;;
                    remmina) check_cmd="remmina" ;;
                    *) check_cmd="$pkg" ;;
                esac
                if ! command -v "$check_cmd" &>/dev/null; then
                    MISSING_PACKAGES+=("$pkg")
                fi
            done

            if [ ${#MISSING_PACKAGES[@]} -gt 0 ]; then
                echo "📦 [Linux/APT] 누락된 패키지(${MISSING_PACKAGES[*]}) 설치 진행 중..."
                sudo apt-get update
                sudo DEBIAN_FRONTEND=noninteractive apt-get install -y "${MISSING_PACKAGES[@]}" fd-find || true
            else
                echo "✅ [Linux/APT] 필수 패키지가 이미 모두 설치되어 있습니다."
            fi

            # Docker 그룹 권한 확인 및 추가
            if getent group docker &>/dev/null && ! id -nG "$USER" | grep -qw docker; then
                echo "🐳 docker 그룹에 $USER 추가 중..."
                sudo usermod -aG docker "$USER" || true
            fi
        elif command -v dnf &>/dev/null; then
            echo "📦 [Linux/DNF] 필수 패키지 설치 확인 중..."
            sudo dnf install -y zsh curl git tmux vim neovim fzf docker || true
        elif command -v pacman &>/dev/null; then
            echo "📦 [Linux/Pacman] 필수 패키지 설치 확인 중..."
            sudo pacman -Sy --noconfirm zsh curl git tmux vim neovim fzf docker || true
        fi

        # 기본 셸이 zsh가 아닌 경우 변경 시도
        if command -v zsh &>/dev/null; then
            CURRENT_SHELL="$(getent passwd "$USER" | cut -d: -f7 || echo "$SHELL")"
            ZSH_PATH="$(which zsh)"
            if [ "$CURRENT_SHELL" != "$ZSH_PATH" ]; then
                echo "🐚 [Linux] 기본 로그인 셸을 zsh로 설정 중..."
                chsh -s "$ZSH_PATH" || sudo chsh -s "$ZSH_PATH" "$USER" || true
            fi
        fi

    elif [ "$OS_TYPE" = "Darwin" ]; then
        echo "🍎 [macOS] 환경 설정 확인..."
        if command -v brew &>/dev/null; then
            echo "📦 [macOS/Homebrew] 필수 도구 설치 확인..."
            brew install zsh fzf tmux neovim git || true
        else
            echo "ℹ️ Homebrew가 설치되어 있지 않습니다. 필요 시 https://brew.sh 에서 설치하세요."
        fi
    fi
}

# ------------------------------------------------------------------------------
# 'install-apps' 옵션 단독 실행 지원
# ------------------------------------------------------------------------------
if [ "$1" = "install-apps" ]; then
    echo "📦 시스템 앱(패키지) 단독 설치 모드로 실행합니다..."
    install_system_packages
    echo ""
    echo "✅ 필수 시스템 앱 설치가 완료되었습니다!"
    exit 0
fi

# 일반 실행 시에도 패키지 설치를 자동으로 먼저 진행
install_system_packages

# ------------------------------------------------------------------------------
# 2. 기본 작업 디렉토리 생성 및 레거시 경로 호환 심볼릭 링크
# ------------------------------------------------------------------------------
echo "🚀 [1/8] 기본 작업 디렉토리 생성 (~/personal, ~/orca)..."
mkdir -p "$HOME/personal" "$HOME/orca"

# ~/personal/dotfiles 경로를 참조하는 기존 설정 및 스크립트와의 호환성 유지
if [ "$DOTFILES_DIR" != "$HOME/personal/dotfiles" ] && [ ! -d "$HOME/personal/dotfiles" ]; then
    ln -sfn "$DOTFILES_DIR" "$HOME/personal/dotfiles"
fi

# ------------------------------------------------------------------------------
# 3. Git 설정 심볼릭 링크 연결
# ------------------------------------------------------------------------------
echo "🔗 [2/8] Git 설정 심볼릭 링크 연결..."
ln -sf "$DOTFILES_DIR/git/.gitconfig" "$HOME/.gitconfig"
ln -sf "$DOTFILES_DIR/git/.gitconfig-personal" "$HOME/.gitconfig-personal"
ln -sf "$DOTFILES_DIR/git/.gitconfig-orca" "$HOME/.gitconfig-orca"

# ------------------------------------------------------------------------------
# 4. Oh My Zsh 및 플러그인 (autosuggestions, syntax-highlighting) 설치
# ------------------------------------------------------------------------------
echo "🐚 [3/8] Oh My Zsh 및 추천 플러그인 확인..."
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    echo "   -> Oh My Zsh 설치 중..."
    RUNZSH=no KEEP_ZSHRC=yes sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended || true
fi

ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
if [ -d "$HOME/.oh-my-zsh" ]; then
    if [ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]; then
        echo "   -> zsh-autosuggestions 플러그인 다운로드 중..."
        git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
    fi
    if [ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]; then
        echo "   -> zsh-syntax-highlighting 플러그인 다운로드 중..."
        git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
    fi
fi

# ------------------------------------------------------------------------------
# 5. Zsh 설정(.zshrc) 심볼릭 링크 연결
# ------------------------------------------------------------------------------
echo "🐚 [4/8] Zsh 셸 설정(.zshrc) 심볼릭 링크 연결..."
if [ -f "$HOME/.zshrc" ] && [ ! -L "$HOME/.zshrc" ]; then
    echo "⚠️ 기존 ~/.zshrc 파일을 ~/.zshrc.backup으로 백업합니다."
    mv "$HOME/.zshrc" "$HOME/.zshrc.backup"
fi
ln -sf "$DOTFILES_DIR/shell/zsh/.zshrc" "$HOME/.zshrc"

# Bash 히스토리가 있고 Zsh 히스토리가 없다면 자동 복사
if [ -f "$HOME/.bash_history" ] && [ ! -s "$HOME/.zsh_history" ]; then
    cp "$HOME/.bash_history" "$HOME/.zsh_history"
fi

# ------------------------------------------------------------------------------
# 6. 커스텀 CLI 바이너리 도구 (~/.local/bin) 심볼릭 링크 연결
# ------------------------------------------------------------------------------
echo "🛠️ [5/8] 커스텀 CLI 바이너리 도구 (~/.local/bin) 심볼릭 링크 연결..."
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

# ------------------------------------------------------------------------------
# 7. Gemini & Antigravity 전역 작업 규칙 연결
# ------------------------------------------------------------------------------
echo "🤖 [6/8] Gemini & Antigravity 전역 작업 규칙 (~/.gemini/GEMINI.md) 연결..."
mkdir -p "$HOME/.gemini" "$HOME/.gemini/config"
if [ -f "$DOTFILES_DIR/.gemini/GEMINI.md" ]; then
    ln -sf "$DOTFILES_DIR/.gemini/GEMINI.md" "$HOME/.gemini/GEMINI.md"
    ln -sf "$DOTFILES_DIR/.gemini/GEMINI.md" "$HOME/.gemini/config/GEMINI.md"
    echo "   -> ~/.gemini/GEMINI.md 및 ~/.gemini/config/GEMINI.md 연결 완료"
fi

# ------------------------------------------------------------------------------
# 8. SSH, Tmux, Vim/Neovim 설정 연결
# ------------------------------------------------------------------------------
echo "🔑 [7/8] SSH 디렉토리 확인..."
mkdir -p "$HOME/.ssh"
chmod 700 "$HOME/.ssh"
if [ ! -f "$HOME/.ssh/config" ]; then
    cp "$DOTFILES_DIR/ssh/config.example" "$HOME/.ssh/config"
    chmod 600 "$HOME/.ssh/config"
    echo "ℹ️ ~/.ssh/config 템플릿을 생성했습니다."
fi

echo "🪟 [8/8] Tmux 및 Vim/Neovim 설정 심볼릭 링크 연결..."
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

# ------------------------------------------------------------------------------
# 9. Bash 셸 통합 설정 (~/.bash_aliases) - 동적 경로 바인딩
# ------------------------------------------------------------------------------
echo "🐚 Bash 셸 호환 설정 (~/.bash_aliases) 동기화..."
cat << EOF > "$HOME/.bash_aliases"
# Dotfiles Bash Integration
export PATH="\$HOME/.local/bin:\$PATH"

if [ -f "$DOTFILES_DIR/shell/zsh/aliases.zsh" ]; then
    . "$DOTFILES_DIR/shell/zsh/aliases.zsh"
fi

if [ -f "$DOTFILES_DIR/shell/zsh/functions.zsh" ]; then
    . "$DOTFILES_DIR/shell/zsh/functions.zsh"
fi

if command -v zoxide &>/dev/null; then
    eval "\$(zoxide init bash --cmd cd)"
fi

if command -v fzf &>/dev/null; then
    eval "\$(fzf --bash 2>/dev/null || true)"
    if command -v fd &>/dev/null; then
        export FZF_DEFAULT_COMMAND='fd --type f --hidden --exclude .git .'
        export FZF_CTRL_T_COMMAND="\$FZF_DEFAULT_COMMAND"
        export FZF_ALT_C_COMMAND='fd --type d --hidden --exclude .git .'
    fi
fi

if [ -f "\$HOME/.dir_colors" ]; then
    eval "\$(dircolors "\$HOME/.dir_colors")"
fi
EOF

echo ""
echo "✅ Dotfiles 설치 및 심볼릭 링크 연결이 완벽하게 완료되었습니다!"
echo "👉 새 터미널 창을 열면 zsh 및 zsh-autosuggestions 자동 완성이 즉시 적용됩니다."
echo "👉 'gh auth login'으로 GitHub 계정 로그인을 진행하세요."
