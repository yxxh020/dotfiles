# **Work Rules for Gemini & Antigravity**

### **1. Language & Communication**

All conversations are conducted in Korean. This includes documents, execution plans, implementation plans, and everything else.

However, all commit messages must be written in the following order:

1. English  
2. 한글

### **2. Documentation Workflow**

Work must be based on the following specific files. Do not create additional documents unless there is a special reason or explicit approval.

**1prd.md** (Project Requirements Document)

* Defines the scope and goals of the project.  
* Specifies what needs to be done.

**2todo.md** (Task List)

* Contains actionable detailed items to achieve the goals defined in 1prd.md.  
* MECE Principle: Items must be Mutually Independent and Collectively Exhaustive.  
* Do not duplicate tasks (e.g., a task in todo 1 should not appear again in todo 2).  
* Dynamic Updates: New tasks discovered during work must be immediately added to this list.  
* Priority: Tasks with the highest priority must be at the top.  
* Completion Status: Completed tasks are marked with `x` for consistency.

**3history.md** (Progress Log)

* Records the results of executing items from 2todo.md.  
* Sorting: The most recent entries must be at the top.  
* Format:  
  `YYMMDD HH:MM [Title from 2todo.md]`  
  `[Detailed description of work performed]`  
* Manuals: When detailed manuals are needed, create them in the specific subfolder where work is in progress, not in the root.
* Technical Guides: Technical suggestions or advice are recorded in separate md files within the `docs` directory, and special notes or plans are written in the `docs/planN` directory.

### **3. Workspace & Context Management**

**Sub-tasks / Individual Task Folders**

* Large-scale Tasks: If a task is large enough to be considered a separate unit, create a subfolder or numbered task folder.  
  Example) 001-environment, 002-UI, 003-member, 004-books, 005-loan  
* Execution: All sub-tasks are performed within their respective folders.  
* Modularization: When tasks are separated, create separate `1prd.md`, `2todo.md`, and `3history.md` files within that folder (e.g., `001-ui`) for management.
* Purpose: This is strictly applied to effectively manage the context window (token limits) and prevent memory overflow.

### **4. Korean Language**

* Implementation plans and all documents should be shown in Korean in the final version.  
* Always update plans in 1prd.md and 2todo.md.

### **5. AI Collaboration & Response Style**

* Interactive Code Writing: When writing code, proceed thoroughly in an interactive manner. Rather than completing everything at once, proceed step by step with confirmation.  
* No Arbitrary Assumptions: If there are blank areas or uncertain parts in plans or implementation, do not arbitrarily assume, write, or create. Always ask the user.  
* **Clarification Required**: When instructions contain ambiguity, contradictions, or gaps, do not fill them with imagination or assumptions. Always ask the user for clarification before proceeding.
* **Proactive Suggestions**: When a better approach or method exists, proactively suggest it along with the reasoning, even if the user's request can be fulfilled as-is. Help the user make informed decisions by presenting alternatives and best practices.
* Suggestions and Options: When asking questions, do not just ask simple questions. Propose Best Practices for the situation or available options along with recommended methods and reasons to help the user make decisions.
* Question Rules: For effective progress, ask questions one at a time, in a follow-up manner.
* **Planning Requests**: When the user requests to "create a plan" or "make a plan" (e.g., "계획을 세워줘"), do not write any code. Only provide planning, analysis, and documentation. Code implementation should only occur after explicit implementation requests.

### **6. Implementation & Quality Management**

* **Sequential Implementation**: Implement sequentially from the top task in `2todo.md`.
* **Quality Principles**: Write unit tests when possible before implementation, and apply design patterns and clean code. When adding code, always review the reuse of existing methods.
* **Verification & Deployment**: After each task completion, verify operation through testing and app execution. If there are no issues and the user has explicitly requested, proceed with Git commit.

### **7. Gemini 3.8 Reasoning Budget Workflow (Quota Optimization)**

Gemini 3.8 단일 모델 환경에서는 작업의 성격과 추론 요구량(Reasoning Budget)에 따라 최적화된 파이프라인으로 역할을 분담합니다.

* **1. Research & Planning (High)**: 코드베이스 전반 탐색, 의존성 및 부작용 분석, 스펙 및 아키텍처 설계
* **2. Code Implementation (Medium)**: 확정된 스펙 기반 코드 및 소스 인접 테스트 구현 (복잡한 트랜잭션/비즈니스 로직 시 조건부 High 승격)
* **3. Fast Test Gate (Tool Gate)**: 코드 리뷰 전 `linter` 및 단위 테스트(`pnpm test`)를 자동 실행하여 단순 문법/타입 에러 조기 차단
* **4. Code Review (High)**: 프로젝트 전역 규칙 및 보안, 엣지 케이스, 동시성 이슈 심층 검증
* **5. Commit & Task Clean-up (Low)**: `git diff` 분석, 커밋 메시지 작성 및 완료 태스크 정리 (가장 가볍고 빠른 처리)

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

## **C. Coding Conventions**
* Korean Sorting: When Korean string sorting is needed (especially for names, titles, etc.), always use `string.localeCompare(other, 'ko-KR')` instead of simple comparison operators (<, >) to ensure accurate character order and grouping.

## **D. Commits and Version Control**
* Execution: Perform commits only when explicitly requested by the user.
* Suggestion: If direct execution is not possible or not requested, suggest an appropriate commit message.
* Message Rules:
  * Use Conventional Commits prefixes (feat, fix, docs, style, refactor, perf, test, chore, etc.).
  * Format: 1-line title + up to 3 lines of detailed description.
  * **Spacing Rule**: Do not leave a blank line between English and Korean descriptions; write them on consecutive lines.

* **Command Writing Tip**:
  * Repeating the `-m` option creates blank lines. To include line breaks, use Bash syntax `$''` with `\n`.
  * Example: `git commit -m $'EnTitle\nKoTitle' -m $'EnDesc\nKoDesc'`

[Writing Example]
<Prefix>: One-line title (English)
<Prefix>: 한글 제목 (Korean)

[Optional] Detailed description (English)
[선택] 상세 설명 (Korean) - *Write directly below the English description without a blank line*
