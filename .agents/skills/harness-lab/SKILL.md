---
name: harness-lab
description: AI 에이전트 하네스 설계·실행 스킬. 일상 업무, 학습 과제, 문서 작업, 개발 프로젝트를 Agent/Skill/Orchestrator/Test/Evolution 구조로 설계하고 실행 하네스를 생성 또는 점검할 때 사용한다. Antigravity와 Claude Code 모두 지원.
---

# Harness Lab

**출처 저장소**: [https://github.com/jikime/harness-lab](https://github.com/jikime/harness-lab)

## 역할

이 스킬은 사용자의 일을 AI 에이전트 하네스 구조로 바꾸는 과정을 안내한다.

명확하고 간결하게 안내한다.

## 플랫폼별 파일 구조

하네스를 구성하는 파일의 위치는 사용하는 AI 플랫폼에 따라 다르다. 설계 방법론(Phase 0-7)은 동일하되, 최종 파일 배치만 아래 표를 따른다.

| 구성 요소 | Antigravity (Gemini) | Claude Code |
|-----------|---------------------|-------------|
| **스킬 파일** | `~/.gemini/config/skills/이름/SKILL.md` | `.claude/skills/이름/SKILL.md` |
| **에이전트 정의** | `~/.gemini/config/agents/이름.md` | `.claude/agents/이름.md` |
| **프로젝트 진입점** | 불필요 (스킬 `description` 필드로 자동 탐색) | `CLAUDE.md` (프로젝트 루트) |
| **자연어 라우팅** | 스킬 `description`에 트리거 키워드 기재 | `CLAUDE.md`에 라우팅 규칙 기재 |
| **오케스트레이터** | 일반 스킬 내부에 실행 흐름을 순서대로 기술 | `-orchestrator` 접미사 스킬로 분리 |
| **서브에이전트 호출** | `invoke_subagent` 도구 사용 | `@agent-이름` 멘션 또는 서브에이전트 직접 호출 |

## 기본 원칙

- Phase 이름과 번호는 항상 Phase 0부터 Phase 7까지로 고정한다.
- 파일 구조와 역할을 간결하게 함께 제시한다.
- 기존 스킬/에이전트 파일이 있으면 먼저 읽고, 덮어쓰기 전에 변경 범위를 분명히 한다.
  - **Antigravity**: `~/.gemini/config/skills/`, `~/.gemini/config/agents/` 확인
  - **Claude Code**: `.claude/agents`, `.claude/skills`, `CLAUDE.md` 확인
- 실행 하네스 생성 시에는 현재 플랫폼에 맞는 파일 구조를 기준으로 구성한다.
- **Claude Code 전용 규칙**:
  - Orchestrator 역할을 하는 Skill은 폴더명과 frontmatter `name`이 반드시 `-orchestrator`로 끝나야 한다. 예: `.claude/skills/trip-planning-orchestrator/SKILL.md`.
  - `CLAUDE.md`에 자연어 라우팅 규칙을 남긴다.
- **Antigravity 전용 규칙**:
  - 스킬의 `description` 필드에 트리거 키워드를 충분히 기재하면 에이전트가 자동으로 매칭한다.
  - 오케스트레이터는 별도 스킬로 분리하지 않고, 하나의 스킬 안에서 실행 순서를 기술한다.
  - 일반 작업 Skill에는 `-orchestrator` 접미사를 쓰지 않는다.

## 진행 방식

아래 순서를 기본 흐름으로 사용한다.

1. Phase 0. 현재 상황 확인: 사용자의 목표, 경험 수준, 기존 파일을 확인한다.
2. Phase 1. 일상 언어로 풀어보기: 사용자의 일을 사람이 하는 절차로 풀어쓴다.
3. Phase 2. 산출물 정의: 마지막에 무엇이 나오면 성공인지 정한다.
4. Phase 3. 팀 패턴 선택: 순차, 병렬, 작성-검토, 감독형 등 적절한 협업 방식을 고른다.
5. Phase 4. Agent 설계: 누가 어떤 역할을 맡을지 정한다.
6. Phase 5. Skill 설계: 각 역할이 어떤 작업법을 따를지 정한다.
7. Phase 6. Orchestrator 설계: 작업 순서, 전달물, 실패 시 대응을 묶는다.
8. Phase 7. 테스트와 개선: 테스트 프롬프트와 개선 기록을 만든다.

자세한 단계별 질문과 산출물은 `references/phase-guide.md`를 읽는다.

## 사용 경로

사용자의 요청은 승인 기반 2단계 흐름으로 처리한다.

- 의견, 구성, 방향을 물으면 설계 의견과 예시를 중심으로 답한다.
- "하네스를 만들어줘", "설계해줘", "구성해줘" 같은 기본 요청은 먼저 청사진을 만든다.
- 청사진 응답을 시작할 때는 "청사진부터 만들겠습니다"처럼 자연스럽게 말한다. "이번에는 실제 파일을 만들지 않고" 같은 방어적인 표현은 쓰지 않는다.
- 청사진에는 사람의 작업 절차, Agent 역할표, Skill 목록, Orchestrator 흐름, 테스트 프롬프트를 포함한다.
- 청사진 끝에는 "이 구조로 실행 가능한 하네스를 구성해드릴까요?"처럼 자연스러운 표현으로 사용자 승인을 요청한다.
- 사용자가 "좋아", "진행해", "이 구조로 만들어줘", "실제로 사용할 수 있게 만들어줘"처럼 승인하면 실행 하네스 생성으로 넘어간다.
- 실행 하네스 생성 단계에서는 사용자가 내부 파일 구조나 스킬명을 직접 말하지 않아도 의도를 판단한다. 현재 플랫폼에 맞는 기존 파일을 확인한 뒤 필요한 Agent, Skill, 오케스트레이터 초안을 만들고, 사용 흐름을 안내한다.
- 기존 하네스 개선을 원하면 먼저 현재 구조, 중복, 빠진 테스트, 문서 드리프트를 점검한다.

## 참조 문서

필요한 경우에만 아래 문서를 읽는다.

- `references/phase-guide.md`: Phase 0-7의 질문, 산출물, 점검 기준이 필요할 때
- `references/everyday-examples.md`: 일상 업무 예시가 필요할 때
- `references/pattern-catalog.md`: 팀 패턴을 골라야 할 때
- `references/templates.md`: 플랫폼별 파일 초안이 필요할 때
- `references/testing-improvement.md`: 테스트 프롬프트, 비교 실험, 개선 기록이 필요할 때

## 품질 기준

- 설명은 "왜 필요한가"를 먼저 말하고 "어떻게 만드는가"로 이어간다.
- 한 번에 너무 많은 에이전트를 만들지 않는다. 첫 실습은 3-4개 역할이 적당하다.
- 각 Agent에는 책임, 입력, 출력, 하지 말아야 할 일을 포함한다.
- 각 Skill에는 트리거, 절차, 산출물 형식, 품질 체크를 포함한다.
- Orchestrator에는 작업 순서, 파일 기반 산출물, 실패 시 재시도 또는 사람 확인 조건을 포함한다.
- 실행 하네스를 만들면, 생성된 파일의 역할을 팀원 카드, 작업 매뉴얼, 전체 진행표, 프로젝트 안내판처럼 일상 언어로 함께 설명한다.
- 테스트는 최소 3개를 만든다: 정상 사례, 애매한 사례, 실패하기 쉬운 사례.
- 마지막에는 사용자가 자기 일에 적용할 수 있는 작은 다음 행동을 제안한다.

### 플랫폼별 추가 품질 기준

**Antigravity:**
- 스킬의 `description` 필드가 에이전트의 자동 매칭에 직접 영향을 주므로, 트리거 키워드를 구체적이고 풍부하게 작성한다.
- 오케스트레이터 흐름은 스킬 본문 안에 "실행 절차" 섹션으로 기술한다.

**Claude Code:**
- Orchestrator Skill 이름은 `{하네스-이름}-orchestrator` 형식으로 만든다.
- `CLAUDE.md`에는 자연어 요청을 Orchestrator Skill로 우선 연결하는 규칙과 예시를 포함한다.
- 특정 subagent가 특정 Skill을 항상 알아야 한다면 Agent frontmatter의 `skills` 필드를 제안한다.

## 피해야 할 것

- 하네스가 모든 문제의 정답인 것처럼 설명하지 않는다.
- 생성된 파일을 검토 없이 정답처럼 제시하지 않는다.
- Phase 번호, 명령 이름, 버전 설명을 문서마다 다르게 쓰지 않는다.
- 처음부터 디렉터리 구조와 YAML만 보여주지 않는다.
