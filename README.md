# 🛠️ Dotfiles

macOS 및 Windows 환경에서 일관된 개발 경험을 제공하기 위한 개인 Dotfiles 저장소입니다.

Git 다중 계정(개인/회사) 자동 분기, GitHub CLI(`gh`) 디렉토리별 계정 스위칭 래퍼, Antigravity CLI 계정 스위처(`as`), 생산성을 위한 셸 모듈화 설정 및 KeePassXC 3-way 동기화 엔진을 관리합니다.

---

## 📁 저장소 구조

```text
dotfiles/
├── .gitignore              # .kdbx, 개인키, .env 등 민감 정보 차단
├── README.md               # 설치 및 사용 가이드
├── Brewfile                # Homebrew 선언적 패키지 및 Mac 앱 정의
├── install.sh              # macOS 원클릭 자동 설치 스크립트 (심볼릭 링크)
├── install-apps.sh         # macOS 필수 앱 & 개발 도구 일괄 설치 스크립트
├── install.ps1             # Windows 자동 설치 스크립트
├── .gemini/                # AI 코딩 에이전트(Gemini/Antigravity) 전역 규칙
│   └── GEMINI.md           # 대화, 커밋, 태스크 관리 및 추론 예산 워크플로우
├── bin/                    # 공용 커스텀 CLI 바이너리 (~/.local/bin 링크)
│   ├── agy-switch          # Antigravity CLI 계정 스위처 (as p / as o)
│   └── chrome-profiles     # Google Chrome 프로필 조회 및 실행 도구
├── docs/                   # 기능별 상세 가이드
│   ├── touch-id.md         # macOS 터미널 Touch ID sudo 연동 가이드
│   └── agy-switch-guide.md # Antigravity CLI 멀티 계정 스위칭 가이드
├── git/
│   ├── .gitconfig          # 크로스 플랫폼 includeIf 다중 계정 분기
│   ├── .gitconfig-personal # 개인 계정 (yxxh020)
│   └── .gitconfig-orca     # 회사 계정 (YiranHwang)
├── ssh/
│   └── config.example      # SSH 호스트 템플릿
├── tasks/                  # 프로젝트 및 자동화 엔진
│   └── keepass-gdrive-sync # KeePassXC ↔ Google Drive 3-Way 동기화 엔진
└── shell/
    ├── zsh/                # macOS Zsh 모듈형 설정
    │   ├── .zshrc          # 메인 엔트리포인트
    │   ├── env.zsh         # PATH, fnm, zoxide, fzf 등 런타임 환경
    │   ├── aliases.zsh     # Git, Podman/Docker, eza, as 단축어
    │   └── functions.zsh   # gh 래퍼, killport, chro, keesync 등
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

# 2. 필수 앱 및 개발 도구 일괄 다운로드 & 설치 (Brewfile 기반)
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

## ⚡ 주요 내장 생산성 도구

1. **Antigravity CLI 계정 스위처 (`as`)**:
   - `as` : 등록된 계정 상태 확인
   - `as p` : 개인(`personal`) 계정으로 즉시 전환
   - `as o` : 회사(`orca`) 계정으로 즉시 전환
   - 상세 매뉴얼: [`docs/agy-switch-guide.md`](docs/agy-switch-guide.md)

2. **포트 충돌 해결사 (`killport`)**:
   - `killport 3000` : 특정 로컬 포트를 점유한 프로세스를 즉시 확인 후 안전하게 종료

3. **KeePassXC Google Drive 3-Way 동기화 (`keesync`)**:
   - `keesync` : 로컬 금고와 Google Drive 금고 간 3-way 충돌 방지 안전 동기화
   - `keestat` : 동기화 상태 및 MD5 해시 분석

4. **Chrome 멀티 프로필 브라우저 실행 (`chro`, `chls`)**:
   - `chls` : 등록된 Chrome 프로필 목록 조회
   - `chro 0` / `chro 1` : 번호별 Chrome 프로필 창 즉시 실행

---

## 🔒 보안 원칙 (Security First)

- **비밀번호 금고(`.kdbx`), 개인키(`id_ed25519`), `.env` 파일은 절대 Git에 커밋하지 않습니다.**
- 보안 시크릿은 KeePassXC 및 암호화된 백업(`keesync`)을 통해서만 기기 간에 안전하게 동기화합니다.
