#!/usr/bin/env bash
# ==============================================================================
# macOS Complete App & Tool Installer (install-apps.sh)
# 새 맥북에서 이 스크립트 하나로 모든 필수 도구가 설치됩니다.
# ==============================================================================
set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

OS_TYPE="$(uname -s)"

echo "========================================"
if [ "$OS_TYPE" = "Darwin" ]; then
  echo "  🍏 macOS 개발 환경 자동 설치 시작"
else
  echo "  🐧 Linux (Ubuntu) 개발 환경 자동 설치 시작"
fi
echo "========================================"

if [ "$OS_TYPE" = "Darwin" ]; then
  # Homebrew 환경변수 로드 (Apple Silicon & Intel)
  if [ -x "/opt/homebrew/bin/brew" ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [ -x "/usr/local/bin/brew" ]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi

  # ---------- [1/6] Homebrew ----------
  echo ""
  echo "🍺 [1/6] Homebrew 설치 확인..."
  if ! command -v brew &>/dev/null; then
    echo "Homebrew가 없어 설치를 시작합니다..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    if [ -x "/opt/homebrew/bin/brew" ]; then
      eval "$(/opt/homebrew/bin/brew shellenv)"
    fi
  else
    echo "✅ Homebrew가 이미 설치되어 있습니다."
  fi

  # ---------- [2/6] Brewfile 기반 일괄 설치 ----------
  echo ""
  echo "📦 [2/6] Brewfile 기반 도구 및 앱 일괄 설치..."
  brew bundle --file="$DOTFILES_DIR/Brewfile"
else
  # ---------- [Linux 1/3] 필수 패키지 관리 (apt) ----------
  echo ""
  echo "📦 [1/3] Linux 시스템 패키지 확인 (apt)..."
  if command -v apt-get &>/dev/null; then
    if sudo -n true 2>/dev/null; then
      echo "sudo 권한 확인 완료, 기본 패키지 설치를 진행합니다..."
      sudo apt update -y
      sudo apt install -y git gh zsh curl build-essential tmux fzf ripgrep fd-find bat eza zoxide keepassxc rclone podman podman-compose 2>/dev/null || true
    else
      echo "ℹ️ sudo 패스워드가 필요합니다. 시스템 패키지(zsh, git, gh 등) 설치는 아래 명령어로 실행하실 수 있습니다:"
      echo "   sudo apt update && sudo apt install -y git gh zsh curl build-essential tmux fzf ripgrep fd-find bat eza zoxide keepassxc rclone podman podman-compose"
    fi
  fi

  # ---------- [Linux 2/3] Modern CLI & 개발 도구 설치 (~/.local/bin) ----------
  echo ""
  echo "🛠️ [2/3] Modern CLI 및 에디터 설치 (~/.local/bin)..."
  mkdir -p "$HOME/.local/bin" "$HOME/.local/opt"

  # Neovim
  if ! command -v nvim &>/dev/null; then
    echo "   -> Neovim 설치 중..."
    curl -fsSL https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz | tar -xz -C "$HOME/.local/opt/"
    ln -sf "$HOME/.local/opt/nvim-linux-x86_64/bin/nvim" "$HOME/.local/bin/nvim"
  else
    echo "   ✅ Neovim이 이미 설치되어 있습니다: $(nvim --version | head -n 1)"
  fi

  # fzf
  if ! command -v fzf &>/dev/null; then
    echo "   -> fzf 설치 중..."
    [ ! -d "$HOME/.fzf" ] && git clone --depth 1 https://github.com/junegunn/fzf.git "$HOME/.fzf"
    "$HOME/.fzf/install" --bin >/dev/null 2>&1 || true
    ln -sf "$HOME/.fzf/bin/fzf" "$HOME/.local/bin/fzf"
  else
    echo "   ✅ fzf가 이미 설치되어 있습니다: $(fzf --version)"
  fi

  # zoxide
  if ! command -v zoxide &>/dev/null; then
    echo "   -> zoxide 설치 중..."
    curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh >/dev/null 2>&1 || true
  else
    echo "   ✅ zoxide가 이미 설치되어 있습니다: $(zoxide --version)"
  fi

  # ripgrep (rg)
  if ! command -v rg &>/dev/null; then
    echo "   -> ripgrep (rg) 설치 중..."
    curl -fsSL https://github.com/BurntSushi/ripgrep/releases/download/15.2.0/ripgrep-15.2.0-x86_64-unknown-linux-musl.tar.gz | tar -xz -C /tmp/
    cp /tmp/ripgrep-15.2.0-x86_64-unknown-linux-musl/rg "$HOME/.local/bin/"
    rm -rf /tmp/ripgrep-15.2.0-x86_64-unknown-linux-musl
  else
    echo "   ✅ ripgrep(rg)이 이미 설치되어 있습니다: $(rg --version | head -n 1)"
  fi

  # fd
  if ! command -v fd &>/dev/null; then
    echo "   -> fd 설치 중..."
    curl -fsSL https://github.com/sharkdp/fd/releases/download/v10.5.0/fd-v10.5.0-x86_64-unknown-linux-musl.tar.gz | tar -xz -C /tmp/
    cp /tmp/fd-v10.5.0-x86_64-unknown-linux-musl/fd "$HOME/.local/bin/"
    rm -rf /tmp/fd-v10.5.0-x86_64-unknown-linux-musl
  else
    echo "   ✅ fd가 이미 설치되어 있습니다: $(fd --version)"
  fi

  # bat
  if ! command -v bat &>/dev/null; then
    echo "   -> bat 설치 중..."
    curl -fsSL https://github.com/sharkdp/bat/releases/download/v0.26.1/bat-v0.26.1-x86_64-unknown-linux-musl.tar.gz | tar -xz -C /tmp/
    cp /tmp/bat-v0.26.1-x86_64-unknown-linux-musl/bat "$HOME/.local/bin/"
    rm -rf /tmp/bat-v0.26.1-x86_64-unknown-linux-musl
  else
    echo "   ✅ bat이 이미 설치되어 있습니다: $(bat --version)"
  fi

  # eza
  if ! command -v eza &>/dev/null; then
    echo "   -> eza 설치 중..."
    curl -fsSL https://github.com/eza-community/eza/releases/download/v0.23.4/eza_x86_64-unknown-linux-musl.tar.gz | tar -xz -C "$HOME/.local/bin/" || true
  else
    echo "   ✅ eza가 이미 설치되어 있습니다: $(eza --version | head -n 1)"
  fi

  # tmux (static binary)
  if ! command -v tmux &>/dev/null; then
    echo "   -> tmux 설치 중..."
    curl -fsSL https://github.com/pythops/tmux-linux-binary/releases/download/v3.6b/tmux-linux-x86_64 -o "$HOME/.local/bin/tmux"
    chmod +x "$HOME/.local/bin/tmux"
  else
    echo "   ✅ tmux가 이미 설치되어 있습니다: $(tmux -V)"
  fi

  # TPM (tmux plugin manager)
  if [ ! -d "$HOME/.tmux/plugins/tpm" ]; then
    echo "   -> TPM (Tmux Plugin Manager) 설치 중..."
    git clone https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
  else
    echo "   ✅ TPM이 이미 준비되어 있습니다."
  fi

  # KeePassXC
  if ! command -v keepassxc &>/dev/null; then
    echo "   -> KeePassXC 설치 중..."
    mkdir -p /tmp/keepassxc-dl "$HOME/.local/opt" "$HOME/.local/share/applications" "$HOME/.local/share/icons/hicolor/scalable/apps"
    curl -fsSL "https://github.com/keepassxreboot/keepassxc/releases/download/2.7.9/KeePassXC-2.7.9-x86_64.AppImage" -o /tmp/keepassxc-dl/KeePassXC.AppImage
    chmod +x /tmp/keepassxc-dl/KeePassXC.AppImage
    (cd /tmp/keepassxc-dl && ./KeePassXC.AppImage --appimage-extract >/dev/null 2>&1)
    rm -rf "$HOME/.local/opt/keepassxc"
    mv /tmp/keepassxc-dl/squashfs-root "$HOME/.local/opt/keepassxc"
    rm -rf /tmp/keepassxc-dl
    cat << 'KP_EOF' > "$HOME/.local/bin/keepassxc"
#!/usr/bin/env bash
exec "$HOME/.local/opt/keepassxc/AppRun" "$@"
KP_EOF
    chmod +x "$HOME/.local/bin/keepassxc"
    cat << 'KP_EOF' > "$HOME/.local/bin/keepassxc-cli"
#!/usr/bin/env bash
exec "$HOME/.local/opt/keepassxc/AppRun" keepassxc-cli "$@"
KP_EOF
    chmod +x "$HOME/.local/bin/keepassxc-cli"
    sed "s|Exec=keepassxc|Exec=$HOME/.local/bin/keepassxc|g" "$HOME/.local/opt/keepassxc/org.keepassxc.KeePassXC.desktop" > "$HOME/.local/share/applications/org.keepassxc.KeePassXC.desktop"
    cp "$HOME/.local/opt/keepassxc/usr/share/icons/hicolor/scalable/apps/keepassxc.svg" "$HOME/.local/share/icons/hicolor/scalable/apps/" 2>/dev/null || true
    update-desktop-database "$HOME/.local/share/applications" 2>/dev/null || true
  else
    echo "   ✅ KeePassXC가 이미 설치되어 있습니다: $(keepassxc --version 2>&1 | tail -n 1)"
  fi

  # DBeaver Community
  if ! command -v dbeaver &>/dev/null; then
    echo "   -> DBeaver Community 설치 중..."
    mkdir -p "$HOME/.local/opt" "$HOME/.local/bin" "$HOME/.local/share/applications"
    curl -fsSL "https://github.com/dbeaver/dbeaver/releases/download/26.2.1/dbeaver-ce-26.2.1-linux-x86_64.tar.gz" | tar -xz -C "$HOME/.local/opt/"
    ln -sf "$HOME/.local/opt/dbeaver/dbeaver" "$HOME/.local/bin/dbeaver"
    cat << 'DB_EOF' > "$HOME/.local/share/applications/dbeaver-ce.desktop"
[Desktop Entry]
Version=1.0
Type=Application
Terminal=false
Name=DBeaver Community
GenericName=Universal Database Manager
Comment=Universal Database Manager and SQL Client.
Path=/home/hwang/.local/opt/dbeaver/
Exec=/home/hwang/.local/opt/dbeaver/dbeaver %U
Icon=/home/hwang/.local/opt/dbeaver/dbeaver.png
Categories=IDE;Development;Database;
StartupWMClass=DBeaver
StartupNotify=true
Keywords=Database;SQL;IDE;JDBC;ODBC;MySQL;PostgreSQL;Oracle;DB2;MariaDB;MSSQL;SQLServer;
MimeType=application/sql;
DB_EOF
    update-desktop-database "$HOME/.local/share/applications" 2>/dev/null || true
  else
    echo "   ✅ DBeaver가 이미 설치되어 있습니다: $(which dbeaver)"
  fi
fi

# ---------- [3/6] Node.js & 패키지 매니저 ----------
echo ""
echo "⚡ [3/6] Node.js LTS 및 글로벌 패키지 매니저(pnpm, bun) 설치..."
if command -v fnm &>/dev/null; then
  fnm install --lts
  fnm default lts-latest
  eval "$(fnm env --use-on-cd --shell bash)"
  npm install -g pnpm bun || true
fi

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

if [ "$OS_TYPE" = "Darwin" ]; then
  # Orca 데스크톱 자동 설치
  if ! brew list --cask orca &>/dev/null; then
    echo "Orca 데스크톱 설치 중..."
    brew tap stablyai/orca
    brew install --cask stablyai/orca/orca || true
  else
    echo "✅ Orca가 이미 설치되어 있습니다."
  fi
fi

# ---------- [5/6] Podman 컨테이너 머신 초기화 ----------
echo ""
echo "🐳 [5/6] Podman 컨테이너 상태 확인..."
if command -v podman &>/dev/null; then
  if [ "$OS_TYPE" = "Darwin" ]; then
    if ! podman machine list --noheading 2>/dev/null | grep -q "podman-machine-default"; then
      echo "Podman 가상 머신(VM)을 초기화하고 시작합니다..."
      podman machine init || true
      podman machine start || true
    else
      echo "✅ Podman 가상 머신이 이미 준비되어 있습니다."
    fi
  else
    echo "✅ Linux 네이티브 Podman 사용 가능: $(podman --version)"
  fi
fi

# ---------- [6/6] 작업 디렉토리 생성 ----------
echo ""
echo "📂 [6/6] 기본 작업 디렉토리 생성..."
mkdir -p "$HOME/personal" "$HOME/orca"

echo ""
echo "========================================"
if [ "$OS_TYPE" = "Darwin" ]; then
  echo "  🎉 macOS 개발 환경 설치 완료!"
else
  echo "  🎉 Linux 개발 환경 설치 완료!"
fi
echo "========================================"
echo ""
echo "📋 다음 단계를 진행하세요:"
echo "  1) bash install.sh          ← Git/셸 설정 심볼릭 링크 연결"
echo "  2) gh auth login -u yxxh020 ← 개인 GitHub 계정 로그인"
echo "  3) gh auth login -u YiranHwang ← 회사 GitHub 계정 로그인"
echo ""
echo "💡 설치된 주요 도구:"
if [ "$OS_TYPE" = "Darwin" ]; then
  echo "  컨테이너  : docker (Docker Desktop) + podman (무료 대안)"
  echo "  DB 쿼리   : Azure Data Studio (SSMS 대체) + DBeaver"
  echo "  원격 접속  : Windows App (RDCMan 대체 RDP 클라이언트)"
  echo "  M365/업무 : Teams, Outlook, OneDrive, Office, Edge, Company Portal"
  echo "  지식 관리  : Obsidian"
  echo "  생산성     : AltTab + Rectangle + Raycast"
else
  echo "  에디터/도구 : Neovim, Tmux, fzf, zoxide, ripgrep, fd, bat, eza"
  echo "  런타임     : Node.js (fnm), pnpm, bun"
  echo "  AI 도구    : Antigravity CLI (agy)"
  echo "  M365/업무  : Linux 환경은 브라우저(PWA) 또는 teams-for-linux / Edge 사용"
fi
