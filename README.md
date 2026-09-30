# 🛠️ Dotfiles

macOS 및 Windows 환경에서 일관된 개발 경험을 제공하기 위한 개인 Dotfiles 저장소입니다.

Git 다중 계정(개인/회사) 자동 분기, GitHub CLI(`gh`) 디렉토리별 계정 스위칭 래퍼, 생산성을 위한 Git 단축어(Aliases) 등을 관리합니다.

---

## 📁 저장소 구조

```text
dotfiles/
├── .gitignore              # .kdbx, 개인키, .env 등 민감 정보 차단
├── README.md               # 설치 및 사용 가이드
├── install.sh              # macOS 원클릭 자동 설치 스크립트
├── install.ps1             # Windows 자동 설치 스크립트
├── git/
│   ├── .gitconfig          # 크로스 플랫폼 includeIf 다중 계정 분기
│   ├── .gitconfig-personal # 계정1
│   └── .gitconfig-orca     # 계정2
├── ssh/
│   └── config.example      # SSH 호스트 템플릿
└── shell/
    ├── zsh/
    │   └── .zshrc          # macOS용 zsh 설정 및 gh 래퍼 함수
    └── powershell/
        └── Microsoft.PowerShell_profile.ps1 # Windows PowerShell 프로필
```

---

## 🚀 빠른 시작 (Quick Start)

### 🍏 새 맥북(macOS)에서 복원할 때

```bash
# 1. 저장소 클론
git clone https://github.com/yxxh020/dotfiles.git ~/dotfiles
cd ~/dotfiles

# 2. 필수 앱 및 개발 도구 일괄 다운로드 & 설치 (VS Code, Docker, SSMS 대체품 등)
bash install-apps.sh

# 3. Git 및 셸 환경 설정 심볼릭 링크 연결
bash install.sh

# 4. GitHub CLI 멀티 계정 로그인
gh auth login -u yxxh020
gh auth login -u YiranHwang
```

### 🪟 Windows PC에서 복원할 때

```powershell
# 1. 저장소 클론
git clone https://github.com/yxxh020/dotfiles.git $HOME\dotfiles

# 2. 파워쉘 설치 스크립트 실행
cd $HOME\dotfiles
.\install.ps1
```

---

## 🔒 보안 원칙 (Security First)

- **비밀번호 금고(`.kdbx`), 개인키(`id_ed25519`), `.env` 파일은 절대 Git에 커밋하지 않습니다.**
- 보안 시크릿은 KeePassXC 및 암호화된 백업을 통해서만 기기 간에 수동/안전 이전합니다.
