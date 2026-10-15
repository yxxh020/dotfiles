# Dotfiles 프로젝트 요구사항 명세 및 에이전트 가이드 (AGENTS.md)

## 1. 개요 및 목적 (PRD)

본 저장소(`dotfiles`)는 macOS, Windows 및 Linux(Ubuntu) 환경에서 일관되고 자동화된 개발 환경을 구축하고 유지관리하기 위한 개인 Dotfiles 시스템입니다.
기존의 분절된 `1prd.md`, `2todo.md`, `3history.md` 문서를 폐기하고, 본 `AGENTS.md` 문서를 **Single Source of Truth(단일 진실 공급원)**로 삼아 프로젝트 요구사항과 개발/운영 지침을 일원화하여 관리합니다.

### 핵심 목표
1. **크로스 플랫폼 자동화**: 단일 설치 명령(`bash install.sh`, `install.ps1`)으로 셸, 패키지, 심볼릭 링크 및 전역 설정을 자동화.
2. **다중 Git/CLI 계정 격리**: 개인(`personal` / `yxxh020`)과 회사(`orca` / `YiranHwang`) 계정을 디렉토리 기반(`includeIf`) 및 래퍼 스크립트(`gh`, `as`)로 완벽 분리.
3. **보안 제일주의**: 민감 정보(`.kdbx`, 개인키, `.env` 등)의 Git 유출을 원천 차단하고 KeePassXC 3-Way 동기화 엔진으로 기기간 안전한 암호화 동기화 제공.
4. **AI 에이전트 전역 규칙 동기화**: Antigravity 및 Gemini 전역 규칙(`~/.gemini/GEMINI.md`)을 중앙 관리하여 모든 프로젝트에서 일관된 협업 워크플로우 보장.

---

## 2. 아키텍처 및 디렉토리 구조

```text
dotfiles/
├── .gemini/
│   └── GEMINI.md           # Antigravity & Gemini 전역 작업 규칙 (~/.gemini/ 링크)
├── AGENTS.md               # [본 문서] 요구사항 정의서(PRD) 및 에이전트 지침
├── README.md               # 사용자 관점 빠른 시작 및 도구 안내 가이드
├── Brewfile                # macOS Homebrew 패키지/cask 선언
├── install.sh              # macOS/Linux 자동 설치 및 심볼릭 링크 구성
├── install-apps.sh         # macOS 애플리케이션 및 CLI 일괄 설치
├── install.ps1             # Windows 자동 구성 스크립트
├── bin/                    # ~/.local/bin 심볼릭 링크 CLI 바이너리
│   ├── agy-switch          # Antigravity CLI 계정 스위처 (`as`)
│   └── chrome-profiles     # Google Chrome 프로필 런처 (`chro`, `chls`)
├── docs/                   # 기능별 영구 기술 매뉴얼
├── git/                    # Git 다중 계정 분기 설정
│   ├── .gitconfig          # includeIf 기반 조건부 분기 메인 설정
│   ├── .gitconfig-personal # 개인 계정 설정
│   └── .gitconfig-orca     # 회사 계정 설정
├── tasks/                  # 프로젝트 및 자동화 유틸리티
│   └── keepass-gdrive-sync # KeePassXC 3-Way Google Drive 동기화 엔진
└── shell/                  # 셸 환경 설정
    ├── zsh/                # Zsh 모듈형 스크립트 (env, aliases, functions, .zshrc)
    └── powershell/         # PowerShell 프로필
```

---

## 3. 핵심 규칙 및 제약 조건

### 3.1 보안 및 기밀 보호
* `.kdbx` 파일, SSH 개인키, API 키, 토큰 및 자격 증명 파일은 절대 커밋하지 않습니다.
* `.gitignore`에 선언된 규칙을 항상 준수합니다.

### 3.2 심볼릭 링크 및 호환성
* 파일 링크 시 항상 원본 파일 경로를 보존하고, 파괴적인 덮어쓰기 전 기존 설정 파일이 손상되지 않도록 유의합니다.
* macOS(Darwin), Linux, Windows 간 환경 차이를 고려하여 크로스 플랫폼 코드를 작성합니다.

### 3.3 커밋 메시지 규칙
* 모든 커밋은 사용자의 명시적 요청 시에만 수행합니다.
* 형식: 1줄 요약 + 상세 설명 (영어 우선, 바로 다음 줄에 한글 병기, 빈 줄 없이 배치).

---

## 4. 에이전트 작업 지침 (Work Guidelines)

1. **단일 문서 원칙 (Single AGENTS.md)**: 하위 폴더마다 별도 `AGENTS.md`를 생성하지 않으며, 신규 모듈/기능 명세는 아래의 '5. 도메인 및 모듈별 세부 명세' 섹션에 추가하여 관리합니다.
2. **상호작용 기반 진행**: 모든 코드 변경이나 스크립트 수정은 사용자 확인을 거치며 단계별로 진행합니다.
3. **가역성 보장**: 시스템 설정 파일 수정 시 복구 가능성(백업 또는 롤백 스크립트)을 확보합니다.

---

## 5. 도메인 및 모듈별 세부 명세 ([Module] Specs)

### 5.1 [Module] Git 다중 계정 분기 (`git/`)
* **목표**: 디렉토리 경로에 따라 개인 계정(`~/personal`)과 회사 계정(`~/orca`)의 커밋 작성자, 이메일, 서명 키 자동 분기.
* **핵심 파일**: `git/.gitconfig`, `git/.gitconfig-personal`, `git/.gitconfig-orca`.
* **주의사항**: `includeIf` 경로 매핑 시 트레일링 슬래시(`/`) 필수 준수.

### 5.2 [Module] 셸 모듈화 및 환경 (`shell/zsh/`)
* **목표**: 터미널 기동 속도 최적화 및 유지보수 편의를 위해 Zsh 환경을 기능별로 분리(env, aliases, functions).
* **핵심 유틸리티**: `myip`(로컬/공인 IP 동시 출력), `killport`(포트 점유 프로세스 해제), `as`(Antigravity 계정 스위칭 래퍼).
* **크로스 플랫폼**: macOS(Homebrew `/opt/homebrew`) 및 Linux 경로 호환성 체크.

### 5.3 [Module] CLI 바이너리 도구 (`bin/`)
* **`bin/agy-switch` (`as`)**: Antigravity CLI의 개인/회사 인증 토큰 및 설정을 즉시 스위칭.
* **`bin/chrome-profiles` (`chro`, `chls`)**: 등록된 Google Chrome 사용자 프로필을 독립된 창으로 즉시 실행.

### 5.4 [Module] KeePassXC 3-Way 동기화 엔진 (`tasks/keepass-gdrive-sync/`)
* **목표**: 로컬 금고, Google Drive 클라우드 금고, 백업 금고 간 3-Way 비교 및 충돌 없는 동기화 보장.
* **검증**: `sync_keebox.py` 실행 전 단위 테스트(`test_sync_keebox.py`) 및 MD5 해시 비교 검증 필수.
