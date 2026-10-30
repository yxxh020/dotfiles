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
├── .agents/                # 글로벌 AI 에이전트 스킬 및 워크플로우 라이브러리
│   ├── skills/             # 160개 글로벌 AI 스킬 (~/.gemini/config/skills 링크)
│   └── workflows/          # 21개 단계별 워크플로우 가이드 (~/.gemini/config/workflows 링크)
├── AGENTS.md               # 요구사항 정의서(PRD) 및 AI 에이전트 지침 (단일 진실 공급원)
├── bin/                    # 공용 커스텀 CLI 바이너리 (~/.local/bin 링크)
│   ├── agy-switch          # Antigravity CLI 계정 스위처 (as p / as o)
│   └── chrome-profiles     # Google Chrome 프로필 조회 및 실행 도구
├── docs/                   # 기능별 상세 가이드
│   ├── touch-id.md         # macOS 터미널 Touch ID sudo 연동 가이드
│   ├── agy-switch-guide.md # Antigravity CLI 멀티 계정 스위칭 가이드
│   ├── subagent-usage-guide.md    # 하위 에이전트 사용 원칙 및 9개 스킬 기본 동작 가이드
│   ├── development-workflow.md    # 개발 환경(비밀값·DB·Git훅·배포·보안) 작업 흐름
│   ├── subagent-token-cost.md     # 하위 에이전트 토큰 비용 분석 및 절약 팁
│   └── testing-strategy.md        # 초경량 3계층 자동화 테스트 전략 평가 보고서
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

## 🧠 글로벌 AI 에이전트 스킬 & 워크플로우 (`.agents/`)

Gemini, Antigravity, Claude Code 등 AI 코딩 어시스턴트에서 전역으로 자동 로드되어 일관된 개발 표준과 안전 가드레일을 적용하는 **160개 스킬** 및 **21개 워크플로우** 라이브러리입니다.

* **동기화 경로**: `~/.gemini/config/skills` ➔ `dotfiles/.agents/skills`
* **동기화 경로**: `~/.gemini/config/workflows` ➔ `dotfiles/.agents/workflows`

### 1. 🛡️ 안전 가드 & 프로젝트 운영 (Safety & Ops)
| 스킬 | 용도 및 설명 |
| :--- | :--- |
| `prod-server-guard` | 운영 서버(SSH/SCP/Docker/운영 DB) 접근 및 위험 명령 전 경고 및 명시적 확인 요구 |
| `push-guard` | `dev`, `main` 등 배포 브랜치 push 전 버전 bump 확인 및 사용자 승인 가드 |
| `version-expert` | 시맨틱 버저닝(SemVer) 기반 패치/마이너 버전 bump, Git 태그 및 UI 반영 자동화 |
| `github-issue` | GitHub CLI(`gh`) 한국어 표준 템플릿 이슈 생성, 라벨 및 계층 관리 |
| `issues-plan-and-resolve` | 열린 GitHub 이슈 전수 분석 ➔ 계획 댓글 등록 ➔ 의존 순서 일괄 해결 |
| `bug-fix-workflow` | 버그 제보 트리아지 ➔ 이슈 연동 ➔ 버전 bump 및 종료 전주기 워크플로우 |
| `bug-report-sync-expert`| 로컬/테스트/운영 환경 간 `bug_reports` 데이터 동기화 및 캡처 모달 검증 |
| `merge-worktree` | 워크트리 작업 완료 후 클린 커밋 ➔ 메인 브랜치 머지 ➔ 디렉토리 정리 |
| `github-invite` | 저장소 공동 작업자(Collaborator) 초대 및 권한 설정 |
| `telegram-bug-report-bot` | 텔레그램 버그 제보 알림 봇 연동 |

### 2. 🎨 프론트엔드 & UI/UX 고도화 (Frontend & Design)
| 스킬 | 용도 및 설명 |
| :--- | :--- |
| `frontend-design` | 템플릿 느낌을 탈피한 고유하고 세련된 비주얼 및 타이포그래피 디자인 가이드 |
| `canvas-design` | Canvas 기반 시각 디자인 및 아트워크 생성 |
| `dark-mode-expert` | 라이트/다크 모드 시각적 일관성 구현 및 2계층 감사 전략 |
| `verify-header-style` | 전체 페이지 대상 다크모드/반응형 헤더 배너 스타일 스크린샷 전수 검증 |
| `sticky-table-header` | 모달/패널 내 스크롤 시 테이블 헤더(`thead`/`th`) 고정 버그 해결 |
| `flexible-modal-expert`| Tailwind CSS 기반 유연한 반응형 모달 레이아웃 설계 |
| `pill-toggle-filter-expert` | 알약(Pill) 모양 토글 필터, 전체선택/해제, URL 쿼리 파라미터 연동 |
| `ctrl-click-multi-select-expert` | 단일 선택과 Ctrl+클릭 다중 선택 인터페이스 동시 지원 |
| `pagination-expert` | 수천 페이지에서도 깨지지 않는 윈도우드 페이징 (`1 2 3 ... 3900`) |
| `phone-input-expert` | 010 자동 채움, 하이픈 제어, 중간 수정 보존 등 한국 휴대폰 UX |
| `ui-shortcut-expert` | 프리미엄 UI 단축키, GNB 탐색 및 모달 포커스 트랩 해결 |
| `list-navigation-expert` | 화살표 키 목록 탐색 및 뒤로가기 시 선택 행 복원 |
| `form-persistence-expert` | 새로고침 시 입력 손실 방지를 위한 sessionStorage 폼 복원 |
| `admin-tab-count-expert` | 어드민 레이아웃 탭별 동적 카운트 최적화 렌더링 |
| `category-block-header` | 카테고리 그룹 헤더 배경 블록 + 하단선 일관 디자인 |
| `equal-height-grid-cards` | 그리드 레이아웃 내 카드 컴포넌트 균일 높이 패턴 |

### 3. ⚙️ 백엔드, DB & 클라우드 인프라 (Backend & Infra)
| 스킬 | 용도 및 설명 |
| :--- | :--- |
| `db-migrate` | 레거시 DB(MSSQL/MySQL) 데이터를 PostgreSQL로 정제·추출·적재(ELT) |
| `sql-query-expert` | 안전하고 최적화된 DB 쿼리 생성 가이드 |
| `erd-expert` | 실제 DB 스키마 분석 및 대화형 클릭 조회 ERD 문서 생성 |
| `nextjs-prisma-expert` | Prisma ORM 및 Zod 기반 Next.js API 라우트 표준 |
| `nestjs-expert` | NestJS 모듈러 아키텍처, JWT 인증 및 ServiceResponse 패턴 |
| `keyring-keepass` | `.env` 파일 없이 KeePassXC 시크릿을 셸 메모리로 직접 주입 |
| `cloudflare-deploy` | Next.js 프로젝트의 Cloudflare Workers(OpenNext) 빌드·배포 |
| `vercel-branch-deploy` | 브랜치별 Vercel 빌드 스킵 및 배포 환경 제어 |
| `supabase-keep-alive` | Supabase Free 티어 일시정지 방지 자동 ping 워크플로우 구성 |
| `prisma-docker-deploy-expert` | 프로덕션 Docker 환경 Prisma 마이그레이션/시드 설정 |
| `node-start-expert` | Node.js 개발 서버 구동, DB 컨테이너 검증 및 포트 충돌 해소 |
| `password-reset-expert` | Bcrypt 해싱 기반 안전한 비밀번호 초기화 및 복구 흐름 |

### 4. 🧪 테스트 & QA 품질 보증 (Testing & QA)
| 스킬 | 용도 및 설명 |
| :--- | :--- |
| `test-driven-development` | 실패하는 테스트 선행 작성 ➔ 최소 구현 ➔ 리팩토링 TDD 사이클 |
| `webapp-testing` | Playwright 기반 프론트엔드 기능, UI 동작 및 스크린샷 검증 |
| `qa-automation-expert` | BDD/TDD 방법론 기반 E2E 자동화 테스트 파이프라인 |
| `playwright-safe-setup` | 시스템 Chrome 프로필 무간섭(Zero-Interference) 독립 테스트 환경 |
| `playwright-user-data-dir` | 프로젝트별 전용 Chrome 세션 분리 및 계정 로그인 보존 |
| `qa-e2e-optimization` | Playwright E2E 속도 최적화 및 오버레이 가림 방지 |
| `ralph-loop` | 빌드/테스트 실패 시 성공(Green)할 때까지 가설-수정 자율 루프 |
| `invite-tester` | 개발자 에이전트와 비판적 QA 에이전트 간 2인 교차 검증 루프 |
| `design-qa-inspector` | 적대적 디자인/QA 검수자 — 실제 DOM·스크린샷 기반 라이트/다크모드·z-index·반응형 검증 |
| `provide-test-for-human` | 사용자가 직접 브라우저에서 검증할 수 있는 테스트 데이터셋 표 제공 |
| `rubric-generator` / `ai-grader` | 객관적 과제 채점 루브릭 생성 및 CoT 추론 기반 자동 채점 |

### 5. 📄 문서 생성 & 오피스 처리 (Documents & Media)
| 스킬 | 용도 및 설명 |
| :--- | :--- |
| `docx` | Word 문서(.docx, .dotx) 생성, 서식 적용 및 내용 추출 |
| `pptx` | 발표용 슬라이드 덱(.pptx) 레이아웃, 테마, 차트 생성 및 편집 |
| `xlsx` | Excel 스프레드시트 수식, 차트, 데이터 정제 및 변환 |
| `pdf` | PDF 텍스트/표 추출, 병합, 분할, 폼 입력 및 OCR 처리 |
| `create-markdown` | 마크다운 렌더링 버그 방지 및 이미지 캡처 통합 품질 표준 |
| `doc2md` | Word/오피스 문서를 깨짐 없는 고품질 마크다운으로 변환 |
| `use-mermaid` | 아키텍처, 흐름도, 시퀀스 다이어그램 Mermaid 시각화 |
| `marp-layout` | Marp 프레젠테이션 슬라이드 텍스트 잘림 방지 레이아웃 가이드 |
| `html-render-expert` | DB/CMS의 HTML 문자열을 프론트엔드에서 안전하게 렌더링 |
| `theme-factory` | 문서, 슬라이드, 웹 아티팩트에 적용 가능한 10대 테마 팔레트 |

### 6. 🤖 AI 에이전트 & 메타 개발 워크플로우 (Agentic Development)
| 스킬 | 용도 및 설명 |
| :--- | :--- |
| `superpowers` | 작업 맥락에 맞는 최적의 스킬을 자동 탐색하고 호출 강제 |
| `socratic-spec` | 코드 작성 전 소크라테스식 문답으로 기획/요구사항 모호성 제거 |
| `socratic-spec-dev` | 아키텍처, 데이터 모델, API 설계 수준의 기술 합의 도출 |
| `brainstorming` | 새로운 기능/컴포넌트 설계 전 요구사항 탐색 및 디자인 발산 |
| `subagent-driven-development` | 독립 태스크를 병렬 서브에이전트에게 위임하고 단계별 검증 |
| `dispatching-parallel-agents` | 2개 이상의 독립 태스크 동시 병렬 디스패치 |
| `systematic-debugging` | 임의 수정 방지, 근본 원인 규명 및 체계적 4단계 디버깅 |
| `karpathy-guidelines` | LLM 코딩 실수를 줄이기 위한 외과적 변경 및 과잉 설계 방지 지침 |
| `executing-plans` / `writing-plans` | 다단계 실행 계획 작성 및 단계별 검토 체크포인트 실행 |
| `agentmemory-*` | `remember`, `recall`, `forget`, `recap` 등 세션 간 장기 지식 보존 |
| `ai-add-skill` / `skill-creator` | 새 커스텀 AI 스킬 설계, 등록 및 성능 최적화 |
| `multi-agent-init` | Antigravity, Claude Code, Gemini 공존 환경 SSOT 초기화 |

### 7. 🔍 코드 분석 & 시스템 관리 (Codebase & Maintenance)
| 스킬 | 용도 및 설명 |
| :--- | :--- |
| `understand-*` | 대규모 코드베이스 지식 그래프 분석, 온보딩 가이드 및 도메인 흐름 추출 |
| `code-review` | P0(치명적)~P3(사소함) 심각도 분류 기반 정밀 코드 리뷰 |
| `refactor` | 기존 동작을 보존하는 안전한 5단계 점진적 코드 리팩토링 |
| `codebase-metrics-expert` | 라인 수, 파일 수, 테스트 수 등 5대 코드베이스 메트릭 일별 추적 |
| `disk-cleaner` / `disk-analyzer` | 패키지 캐시, 저널 로그 안전 정리 및 디스크 사용량 분석 |
| `system-doctor` | 시스템/OS/패키지 오류 진단 및 해결 가이드 |
| `dotfiles-reviewer` | 닷파일 저장소의 구조, 보안 및 머신별 격리 상태 점검 |
| `git-hooks-setup` | 커밋 메시지 컨벤션을 강제하는 Git Hook 자동 설치 |

---

## 🔒 보안 원칙 (Security First)

- **비밀번호 금고(`.kdbx`), 개인키(`id_ed25519`), `.env` 파일은 절대 Git에 커밋하지 않습니다.**
- 보안 시크릿은 KeePassXC 및 암호화된 백업(`keesync`)을 통해서만 기기 간에 안전하게 동기화합니다.
