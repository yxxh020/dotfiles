---
name: find-skills
description: 외부 오픈 에이전트 스킬 생태계(skills.sh, GitHub)에서 스킬을 탐색하고, 현재 Antigravity 환경과의 중복·적합성을 리뷰한 후 도입 여부를 판단하여 설치한다. "스킬 찾아줘", "X 하는 스킬 있어?", "find a skill for X" 등의 요청 시 트리거.
---

# Find Skills

외부 오픈 에이전트 스킬 생태계에서 스킬을 탐색하고, Antigravity 환경에 적합한지 리뷰한 뒤 도입하는 스킬.

## When to Use This Skill

- 사용자가 "X 하는 스킬 있어?", "find a skill for X" 라고 물을 때
- "how do I do X" — 기존 스킬로 커버되지 않는 작업일 때
- 외부 저장소(GitHub)에서 스킬을 가져오라는 요청을 받았을 때
- 에이전트 기능 확장에 관심을 표현할 때

## Step 1: 스킬 탐색

다음 두 가지 방법으로 외부 스킬을 검색한다:

### 방법 A: skills.sh 리더보드

[skills.sh](https://skills.sh/)에서 도메인별 인기 스킬을 확인한다.
설치 수 기준으로 정렬되어 있어 검증된 스킬을 빠르게 찾을 수 있다.

### 방법 B: GitHub 키워드 검색

skills.sh에 원하는 스킬이 없으면 GitHub에서 직접 검색한다:
- 저장소 내 `SKILL.md` 파일이 있는지 확인
- `skills/` 디렉터리 구조를 따르는 저장소인지 확인
- README에서 스킬 설명과 사용 사례를 파악

**인기 스킬 저장소 예시:**
- `vercel-labs/skills` — find-skills, React best practices
- `anthropics/skills` — Frontend design, document processing
- `obra/superpowers` — brainstorming, systematic-debugging, TDD
- `multica-ai/andrej-karpathy-skills` — LLM 코딩 실수 방지 가이드라인

## Step 2: Antigravity 적합성 리뷰

외부 스킬을 발견하면, 도입 전에 반드시 다음을 리뷰한다:

### 2-1. 기존 스킬 중복 확인

```
현재 등록된 스킬 목록: ~/.gemini/config/skills/
라이브러리 원본:       ~/ai-agent-configs/library/skills/
```

- 동일하거나 유사한 기능의 스킬이 이미 있는지 확인
- 있다면: 기존 스킬과의 **섹션별 비교**를 수행하여 차이점만 보고
- 없다면: 새 스킬로 도입 가치 평가 진행

### 2-2. 적합성 평가 기준

| 기준 | 체크 |
|---|---|
| **기존 커버리지** | 기존 스킬/룰/워크플로로 이미 커버되는가? |
| **품질 신호** | 설치 수 1K+? GitHub Stars? 보안 감사 통과? |
| **Antigravity 호환성** | Antigravity 도구(서브에이전트, 워크스페이스 등)와 자연스럽게 통합되는가? |
| **언어/문화 적합** | 한글 번역이 필요한가? 기존 한글 스킬과 일관성이 유지되는가? |
| **유지보수 부담** | upstream 변경을 추적해야 하는가? 일회성 가져오기로 충분한가? |

### 2-3. 판단 결과 보고

리뷰 결과를 사용자에게 다음 형식으로 보고한다:

```
| superpowers 스킬      | 기존 로컬 스킬           | 판정    |
|----------------------|------------------------|---------|
| systematic-debugging | systematic-debug (워크플로) | ⚠️ 중복  |
| brainstorming        | socratic-spec           | ⚠️ 유사  |
| receiving-code-review| (없음)                   | ✅ 도입  |
```

## Step 3: 도입 실행

사용자 승인 후 다음 절차로 도입한다:

### 3-1. GitHub API로 SKILL.md 원본 가져오기

```
https://api.github.com/repos/<owner>/<repo>/contents/skills/<skill-name>/SKILL.md
```

Base64 인코딩된 content 필드를 디코딩하여 원본을 확보한다.

### 3-2. ai-agent-configs에 등록

```bash
# 원본 생성
~/ai-agent-configs/library/skills/<skill-name>/SKILL.md

# 글로벌 심링크 연결
ln -s ~/ai-agent-configs/library/skills/<skill-name> ~/.gemini/config/skills/<skill-name>
```

### 3-3. 검증

```bash
# 심링크 해석 확인
test -e ~/.gemini/config/skills/<skill-name>/SKILL.md && echo "OK"
```

### 3-4. 한글화 (선택)

기존 스킬이 한글로 관리되고 있다면, 의미를 유지하며 한글 번역본으로 교체한다.
원본 출처 링크를 `**출처 저장소**:` 라인으로 명시한다.

## Quality Signals

외부 스킬 평가 시 참고하는 품질 지표:

- ✅ **1K+ installs** on skills.sh — 검증된 스킬
- ✅ **Verified organization** on GitHub
- ✅ **Passed security audits** (Gen Agent Trust Hub, Socket, Snyk)
- ✅ **Active maintenance** — 최근 커밋 존재
- ⚠️ **Low install count** — 미검증 또는 니치 스킬
- ⚠️ **No security audit** — 리뷰되지 않은 스킬
