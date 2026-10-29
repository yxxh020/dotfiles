# **Work Rules for Gemini & Antigravity**

### **1. Language & Communication**

All conversations are conducted in Korean. This includes documents, execution plans, implementation plans, and everything else.

All commit messages must be written in Korean only (한글 단독 작성).

### **2. Documentation Workflow (Unified AGENTS.md)**

기존의 `1prd.md`, `2todo.md`, `3history.md` 분절 방식은 전면 폐기되었으며, 모든 요구사항 명세(PRD), 작업 지침 및 실행 계획은 **`AGENTS.md`** 단일 파일로 일원화하여 관리합니다.

* **Single Source of Truth (`AGENTS.md`)**:
  * **PRD 역할 흡수**: 프로젝트의 목표, 범위, 요구사항 명세(기존 `1prd.md`)를 `AGENTS.md`에 명확히 정의합니다.
  * **에이전트 지침 및 컨텍스트**: 환경 감지 기준, 아키텍처, 코딩 컨벤션, 검증 방법을 포함하여 AI 에이전트가 최적의 결정을 내릴 수 있도록 돕습니다.
  * 불필요한 다중 문서 분할을 지양하여 문서 간 동기화 불일치를 방지하고 컨텍스트 윈도우(토큰)를 최적화합니다.
* **태스크 및 진행 관리**:
  * 진행할 작업 목록은 `AGENTS.md` 내 태스크 목록/체크리스트 또는 대화 기반 실행 계획으로 관리하며 순차적으로 진행합니다.
  * 작업 이력은 Git 커밋 로그(`git log`) 및 버전 제어로 투명하게 관리하므로, 중복 기록용 히스토리 파일(`3history.md`)은 생성하지 않습니다.
* **상세 기술 문서**:
  * 영구 보관이나 심화 설명이 필요한 아키텍처/기술 가이드는 `docs/` 디렉토리 하위에 주제별 마크다운 파일로 관리합니다.

### **3. Workspace & Context Management (Single Root AGENTS.md)**

* **루트 단일화 원칙**: 하위 디렉토리/작업 폴더마다 개별 `AGENTS.md`를 분산 생성하지 않습니다. 프로젝트 루트의 단일 `AGENTS.md` 내에서 도메인 및 모듈별 섹션(`## [Module] <이름>` 등)으로 구조화하여 관리합니다.
* **단일 진실 공급원(SSOT)**: 에이전트는 루트 `AGENTS.md` 하나만 참조하여 전체 프로젝트 아키텍처와 세부 모듈 요구사항을 파악할 수 있어야 하며, 문서 파편화 및 동기화 불일치를 방지합니다.
* **서브태스크 작업 단위**: 대규모 작업이라도 별도 문서 파일을 남발하지 않으며, 작업 분할이 필요한 경우 루트 `AGENTS.md`의 태스크 섹션 또는 대화 세션의 실행 계획을 통해 순차 진행합니다.

### **4. Korean Language**

* Implementation plans and all documents should be shown in Korean in the final version.  
* Always update specifications and plans in `AGENTS.md`.

### **5. AI Collaboration & Response Style**

* Interactive Code Writing: When writing code, proceed thoroughly in an interactive manner. Rather than completing everything at once, proceed step by step with confirmation.  
* No Arbitrary Assumptions: If there are blank areas or uncertain parts in plans or implementation, do not arbitrarily assume, write, or create. Always ask the user.  
* **Clarification Required**: When instructions contain ambiguity, contradictions, or gaps, do not fill them with imagination or assumptions. Always ask the user for clarification before proceeding.
* **Proactive Suggestions**: When a better approach or method exists, proactively suggest it along with the reasoning, even if the user's request can be fulfilled as-is. Help the user make informed decisions by presenting alternatives and best practices.
* Suggestions and Options: When asking questions, do not just ask simple questions. Propose Best Practices for the situation or available options along with recommended methods and reasons to help the user make decisions.
* Question Rules: For effective progress, ask questions one at a time, in a follow-up manner.
* **Planning Requests**: When the user requests to "create a plan" or "make a plan" (e.g., "계획을 세워줘"), do not write any code. Only provide planning, analysis, and documentation. Code implementation should only occur after explicit implementation requests.

### **6. Implementation & Quality Management**

* **Sequential Implementation**: Implement sequentially based on the defined tasks/steps in `AGENTS.md` or the agreed plan.
* **Quality Principles**: Write unit tests when possible before implementation, and apply design patterns and clean code. When adding code, always review the reuse of existing methods.
* **Verification & Deployment**: After each task completion, verify operation through testing and app execution. If there are no issues and the user has explicitly requested, proceed with Git commit.

### **7. Gemini 3.8 Reasoning Budget Workflow (Quota Optimization)**

Gemini 3.8 단일 모델 환경에서는 작업의 성격과 추론 요구량(Reasoning Budget)에 따라 최적화된 파이프라인으로 역할을 분담합니다.

* **1. Research & Planning (High)**: 코드베이스 전반 탐색, 의존성 및 부작용 분석, 스펙 및 아키텍처 설계
* **2. Code Implementation (Medium)**: 확정된 스펙 기반 코드 및 소스 인접 테스트 구현 (복잡한 트랜잭션/비즈니스 로직 시 조건부 High 승격)
* **3. Fast Test Gate (Tool Gate)**: 코드 리뷰 전 `linter` 및 단위 테스트(`pnpm test`)를 자동 실행하여 단순 문법/타입 에러 조기 차단
* **4. Code Review (High)**: 프로젝트 전역 규칙 및 보안, 엣지 케이스, 동시성 이슈 심층 검증
* **5. Commit & Task Clean-up (Low)**: `git diff` 분석, 커밋 메시지 작성 및 완료 태스크 정리 (가장 가볍고 빠른 처리)

### **8. Agent Persistent Memory (agentmemory)**

에이전트는 `agentmemory` MCP 서버를 통해 세션 간 유지되는 장기 지속성 메모리를 활용합니다. (주요 도구: `memory_recall`, `memory_smart_search`, `memory_save`, `memory_sessions`)

* **컨텍스트 로드**: 새로운 작업이나 세션 시작 시, 과거 결정 사항, 트러블슈팅 이력 및 사용자 선호도를 확인하기 위해 `memory_recall` 또는 `memory_smart_search`를 활용합니다.
* **영구 지식 보존**: 중요한 아키텍처 결정, 해결 패턴(Gotcha), 규칙 변경, 사용자 선호도가 확정되었을 때 `memory_save`를 통해 핵심 사실을 간결하게 저장합니다.
* **재도출 최소화**: 이미 학습된 지식을 재도출하지 않고 메모리를 우선 참조하며, 전체 대화록 대신 재사용 가능한 팩트 단위로 관리합니다.

## **A. Environment Detection Criteria**

**macOS Native Mode (Primary):**
* Running on macOS (Darwin).
* Shell: Zsh / Bash.
* Package Manager: Homebrew (`/opt/homebrew` on Apple Silicon, `/usr/local` on Intel).
* Use macOS native tools, open command, and standard POSIX paths (`/Users/...`).

**Windows Native Mode:**
* Terminal: PowerShell.
* Path format: `C:\Users\...`
* Use tools directly installed on Windows. Do not mix with WSL commands.
* Ensure UTF-8 Korean encoding does not break in terminal output.

**WSL / Linux Mode:**
* Terminal: Bash or Zsh.
* Path format: `/home/...`
* Use native Linux tools installed inside the environment.

## **B. Core Principles**
* Python Virtual Environment: When working with Python, always use **venv**.
* For Node.js, use **pnpm** unless otherwise specified.
* Multi-account Git: Respect directory-specific configurations (`~/personal` vs `~/orca`).
* Bug Reporting & Workflow: 버그 제보 시스템 및 캡처 모달은 `bug-report-sync-expert` 규칙(자동 캡처 기본값, 폰트 임베딩 스킵 최적화, Zod nullable, 환경별 DB 동기화)을 따르고, 버그 트리아지 및 해결 파이프라인은 `bug-fix-workflow`(prod 데이터 전용 접근, GitHub 이슈 연동 댓글, 패치 버전 bump, 처리완료 라벨 및 안내 댓글)를 준수합니다.

## **C. Coding Conventions**
* Korean Sorting: When Korean string sorting is needed (especially for names, titles, etc.), always use `string.localeCompare(other, 'ko-KR')` instead of simple comparison operators (<, >) to ensure accurate character order and grouping.

## **D. Commits and Version Control**
* Execution: Perform commits only when explicitly requested by the user.
* Suggestion: If direct execution is not possible or not requested, suggest an appropriate commit message.
* Message Rules:
  * Use Conventional Commits prefixes (feat, fix, docs, style, refactor, perf, test, chore, etc.).
  * Language: Write commit messages in Korean only (영어 병기 없이 한글 단독 작성).
  * Format: 1-line title + up to 3 lines of detailed description.

* **Command Writing Tip**:
  * Repeating the `-m` option creates blank lines. To include line breaks, use Bash syntax `$''` with `\n` or standard multi `-m` flags.
  * Example: `git commit -m '<Prefix>: 한글 제목' -m '<선택> 한글 상세 설명'`

[Writing Example]
<Prefix>: 한글 한 줄 제목

[선택] 상세 설명 (한글)
