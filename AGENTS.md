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

### 3.3 커밋 및 버전 제어 규칙
* **전역 규칙 준수**: 커밋 작성 규칙, 언어 규칙(한글 단독 작성) 및 Conventional Commits 프리픽스는 전역 규칙([`.gemini/GEMINI.md`](file:///.gemini/GEMINI.md))을 전적으로 준용합니다.
* **명시적 요청 시 커밋**: 모든 커밋은 사용자의 명시적 요청이 있을 때만 수행합니다.

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

### 5.5 [Module] 글로벌 AI 스킬 및 워크플로우 라이브러리 (`.agents/skills/`, `.agents/workflows/`)
* **목표**: 프로젝트 독립적인 범용 AI 에이전트 스킬(160개) 및 워크플로우(20개)를 중앙 관리하여, 모든 프로젝트에서 일관된 워크플로우와 가드레일을 적용.
* **설계 원칙**: 단일 SSOT, DRY(중복 방지), KISS(단순성 유지).
* **동기화 경로**: `dotfiles/.agents/skills` → `~/.gemini/config/skills` (전역 AI 에이전트 자동 로드).

#### 1) 핵심 가드 & 표준 스킬 (Core 15)
| 스킬명 | 용도 |
|--------|------|
| `docs-audit` | 문서 감사 및 최적화 (현재 상태 집중, 중복 제거, git 위임) |
| `github-issue` | GitHub 이슈/PR 한국어 표준 템플릿 관리 (중복 방지, 라벨, 계층 구조) |
| `issues-plan-and-resolve` | 열린 이슈 전수 분석 → 계획 댓글 → 의존 순서 일괄 해결 파이프라인 |
| `push-guard` | 배포 브랜치 push 전 버전 확인 가드 |
| `prod-server-guard` | 프로덕션 서버 접근 경고 및 명시적 승인 가드 |
| `refactor` | 안전한 5단계 점진적 리팩토링 (동작 보존, 이중 안전망) |
| `socratic-spec` | 소크라테스적 질문으로 숨겨진 가정/모호함 제거 (코드 작성 금지) |
| `version-expert` | 버전 bump, 커밋, Git 태그 생성 자동화 |
| `ai-add-skill` | 새 커스텀 AI 스킬 설계 및 등록 (DRY/KISS/SSOT 원칙) |
| `multi-agent-init` | 다중 AI 도구 공존 구조 초기화 (SSOT + 얇은 래퍼) |
| `superpowers` | 스킬 자동 발견 및 강제 호출 메타 스킬 |
| `code-review` | P0-P3 심각도 분류 코드 리뷰 및 계층 이슈 생성 워크플로우 |
| `merge-worktree` | 워크트리 커밋 → 머지 → 삭제 3단계 마무리 워크플로우 |
| `bug-report-sync-expert` | 버그 제보(bug_reports) 환경별 동기화 및 프론트 캡처 모달 검증/수정 스킬 |
| `bug-fix-workflow` | 버그 트리아지 → GitHub 이슈 연동 → 패치 버전 bump 및 완료 처리 전주기 워크플로우 |

#### 2) 확장 스킬 라이브러리 카테고리 (총 160개 스킬)
* **프론트엔드 & UI/UX**: `frontend-design`, `canvas-design`, `dark-mode-expert`, `sticky-table-header`, `flexible-modal-expert`, `pill-toggle-filter-expert`, `pagination-expert`, `ctrl-click-multi-select-expert`, `url-state-sync-expert`, `ui-shortcut-expert` 등
* **백엔드 & 데이터베이스**: `db-migrate`, `sql-query-expert`, `add-dbeaver-connection`, `nextjs-prisma-expert`, `nestjs-expert`, `supabase-keep-alive`, `prisma-docker-deploy-expert` 등
* **테스트 & 품질 보증(QA)**: `test-driven-development`, `webapp-testing`, `qa-automation-expert`, `qa-e2e-optimization`, `playwright-safe-setup`, `playwright-user-data-dir` 등
* **문서 & 오피스 처리**: `docx`, `pptx`, `xlsx`, `pdf`, `doc2md`, `create-markdown`, `html-render-expert`, `use-mermaid` 등
* **AI 개발 & 메타 에이전트**: `subagent-driven-development`, `systematic-debugging`, `executing-plans`, `writing-plans`, `dispatching-parallel-agents`, `agentmemory-*`, `ralph-loop` 등
* **인프라 & 배포**: `cloudflare-deploy`, `vercel-branch-deploy`, `disk-cleaner`, `disk-analyzer`, `system-doctor`, `git-hooks-setup`, `using-git-worktrees` 등

#### 3) 워크플로우 템플릿 (`.agents/workflows/`, 21개)
`tdd.md`, `invite-tester.md`, `systematic-debug.md`, `project-enhancement-cycle.md`, `close-worktree.md`, `dev-tester.md`, `ralph-loop.md` 등 단계별 가이드 문서 구비.

---

## 6. 태스크 진행 현황 (Tasks & Roadmap)

본 섹션은 기존 `2todo.md`의 역할을 흡수하여, 현재 진행 중이거나 향후 예정된 핵심 작업 목록을 관리하는 단일 슬롯입니다.

- [x] **문서 워크플로우 단일화**: `1prd/2todo/3history` 분절 체계 폐기 및 루트 단일 `AGENTS.md` 통합 (완료)
- [x] **전역 규칙 개정**: `.gemini/GEMINI.md` 내 단일 진실 공급원(SSOT) 규칙 정립 (완료)
- [x] **컨테이너 도구 최적화**: Docker Desktop 제거 및 lazydocker(macOS/Linux) 추가 및 셸 단축어(`lzd`) 반영 (완료)
- [x] **글로벌 AI 스킬 & 워크플로우 라이브러리 확장**: `.agents/skills/`(160개 스킬) 및 `.agents/workflows/`(20개 워크플로우) 등록 및 심볼릭 링크 완료 (완료)
- [ ] **정기 점검 및 유지보수**:
  - [ ] macOS/Linux `install.sh` 심볼릭 링크 및 패키지 설치 무결성 테스트
  - [ ] `Brewfile` 패키지 최신화 및 미사용 cask 정리
  - [ ] KeePassXC 동기화 엔진 예외 케이스 점검

