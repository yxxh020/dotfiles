---
name: skill-promote
description: >
  특정 프로젝트의 .agents/skills/ 에서 스킬을 선정하여 도메인 특화 내용을 범용 템플릿으로
  정제한 뒤 ai-agent-configs/library/skills/ 에 추가하고 README.md를 동기화하는 스킬 이관 전문가 스킬.
  또한 '글로벌 스킬 생성/만들어줘' 요청 시 처음부터 ai-agent-configs에 직접 생성하고
  ~/.gemini/config/skills/ 에 심볼릭 링크를 걸어 즉시 활성화하는 워크플로우도 포함한다.
---

# skill-promote — 스킬 이관 및 글로벌 스킬 생성 전문가

임의의 프로젝트에서 성숙한 스킬을 `ai-agent-configs` 범용 라이브러리로 승격(promote)하거나,
처음부터 글로벌 스킬을 `ai-agent-configs`에 직접 생성하여 심볼릭 링크로 활성화하는 절차를 정의한다.

## 언제 사용하나?

**A. 프로젝트 스킬 승격 (기존)**:
- "<프로젝트>에서 만든 스킬을 ai-agent-configs에 반영하고 싶어"
- "프로젝트 스킬을 범용화해서 다른 프로젝트에서도 쓸 수 있게 해줘"
- "글로벌 스킬에 등록해줘" / "글로벌 스킬로 승격해줘"

**B. 글로벌 스킬 신규 생성**:
- "글로벌 스킬 생성해줘" / "글로벌 스킬 만들어줘"
- "이 패턴을 스킬로 만들어줘" (프로젝트 종속 아닌 범용 패턴)
- "새 스킬 만들어줘" (현재 프로젝트의 .agents/skills가 아닌 범용 목적)

## 경로 기본 설정 및 스캔 금지 규칙

- **`~/prj` 전체 디렉터리 스캔 금지**: 스킬 실행 시 `~/prj` 하위 디렉터리나 전체 프로젝트 목록을 스캔/탐색하지 않는다.
- **글로벌 스킬 원본 경로**: `~/ai-agent-configs/library/skills/<skill-name>/SKILL.md`
- **글로벌 스킬 활성화 링크**: `~/.gemini/config/skills/<skill-name>` → (심볼릭 링크) → 원본 경로
- **절대 `~/.gemini/config/skills/`에 직접 파일을 생성하지 않는다** — 반드시 `~/ai-agent-configs/library/skills/`에 원본 생성 후 심볼릭 링크.
- **소스 프로젝트 경로** (승격 시):
  - 사용자가 특정 프로젝트를 지정하지 않은 경우: **현재 작업 중인 워크스페이스**의 `.agents/skills/`를 기본 소스로 자동 지정한다.
  - 사용자가 특정 프로젝트명을 지정한 경우: 해당 프로젝트 경로만 명시적으로 접근한다.

---

## 글로벌 스킬 신규 생성 워크플로우 (경로 B)

"글로벌 스킬 생성/만들어줘" 요청 시 이 경로를 따른다.

### B-1. 스킬 내용 작성

`skill-creator` 스킬의 작성 가이드(Capture Intent → Interview → Write SKILL.md)를 참고하여 스킬을 작성한다.

### B-2. 원본 파일 생성 (ai-agent-configs)

```bash
# 원본 생성 위치 (절대 ~/.gemini/config/skills/ 에 직접 생성하지 않는다)
~/ai-agent-configs/library/skills/<skill-name>/SKILL.md
```

### B-3. 심볼릭 링크 생성 (.gemini → ai-agent-configs)

```bash
ln -s /home/<user>/ai-agent-configs/library/skills/<skill-name> \
      /home/<user>/.gemini/config/skills/<skill-name>
```

### B-4. README.md 동기화

Phase 4(아래)를 따라 `~/ai-agent-configs/library/README.md` 스킬 표에 추가하고 카운트를 갱신한다.

### B-5. ai-agent-configs 커밋

Phase 6(아래)을 따라 커밋한다.

---

## Phase 0 — 사전 파일 확인 (필수 읽기)

시작 전 `~/ai-agent-configs`로 바로 직행하여 다음 파일들을 읽는다:

```bash
# ai-agent-configs 운영 규칙
cat ~/ai-agent-configs/AGENT.md

# 현재 스킬 목록 및 카탈로그 구조
cat ~/ai-agent-configs/library/README.md
```

**핵심 확인 사항**:
- `library/README.md`의 스킬 섹션 헤딩 구조 (카테고리명, 표 형식)
- `AGENT.md`의 문서 품질 규칙 (§ 문서 품질 규칙)

---

## Phase 1 — 인벤토리 비교

### 1-1. 소스 프로젝트 스킬 목록 수집

`~/prj` 전체를 스캔하지 않고, 현재 작업 중인 워크스페이스(또는 명시된 특정 프로젝트)의 스킬만 수집한다.

```bash
ls <source-project>/.agents/skills/
```

### 1-2. ai-agent-configs 현재 스킬 목록 수집

`~/ai-agent-configs` 경로로 직행하여 스킬 목록을 수집한다.

```bash
ls ~/ai-agent-configs/library/skills/
```

### 1-3. 차집합 계산 및 분류표 제시

소스에만 있고 ai-agent-configs에 없는 스킬을 추출하여 아래 형식의 표로 **사용자에게 보여준다**.

각 스킬을 아래 기준으로 분류한다:

| 분류 | 기준 |
|------|------|
| **✅ 범용** | 특정 도메인 지식 없이 다른 프로젝트에서도 쓸 수 있음 |
| **🔧 정제 후 가능** | 도메인 예시가 섞여 있지만 핵심 규칙은 범용 |
| **❌ 이관 불필요** | 특정 DB 스키마·도메인 모델·설정에 완전 종속 |

**범용 판별 체크리스트** (각 스킬 SKILL.md를 읽은 뒤 판단):
- 특정 테이블명·컬럼명이 핵심 내용에 포함 → ❌
- 특정 서비스명·도메인 용어가 없으면 의미 없음 → ❌
- 다른 프로젝트에서 그대로 또는 약간 수정해 쓸 수 있음 → ✅
- AI 에이전트 행동 규칙(경고, 안전 가드, 패턴 준수) → ✅

### 1-4. 사용자 선택 대기 (⛔ 이 단계 없이 Phase 2 진행 금지)

표를 제시한 뒤 **반드시 사용자가 이관할 스킬을 선택할 때까지 기다린다.**

```
위 목록 중 이관할 스킬을 선택해라.
예: "prod-server-guard, html-render-expert 이관해줘"
```

- 차집합 전체를 자동으로 이관하지 않는다.
- 사용자가 명시적으로 지정한 스킬만 Phase 2로 진행한다.
- "전부 다"라고 하더라도 ❌ 항목은 제외하고 다시 확인한다.

---

## Phase 2 — 개별 스킬 정제

승인된 스킬 각각에 대해 순서대로 수행한다.

### 2-1. 원본 SKILL.md 읽기

```bash
view_file <source-project>/.agents/skills/<skill-name>/SKILL.md
```

### 2-2. 민감/도메인 특화 요소 식별 및 정제

SKILL.md를 읽으면서 아래 항목을 찾아 **모두 정제**한다.

#### 🔴 민감 데이터 (반드시 제거)

| 요소 | 예시 | 처리 방법 |
|------|------|-----------|
| IP 주소 / 호스트명 | `192.168.1.10`, `prod.example.com` | 제거 또는 `<host-ip>` 플레이스홀더 |
| 포트 번호 (비표준) | `:5433`, `:8088` | `<port>` 플레이스홀더 |
| DB 이름·사용자명 | `myapp_db`, `myapp_user` | `<db-name>`, `<db-user>` 플레이스홀더 |
| 환경 변수 값 | `DATABASE_URL=postgres://...` | 키 이름만 남기고 값 제거 |
| 실제 파일시스템 경로 | `/home/user/prj/myapp/...` | `<project-root>/...` 일반화 |
| API 키·토큰 패턴 | `sk-...`, `Bearer ...` | 완전 제거 |

#### 🟡 도메인 특화 요소 (범용화)

| 요소 | 예시 | 처리 방법 |
|------|------|-----------|
| 프로젝트·서비스명 | `my-finance`, `myapp` | `<your-project>` 플레이스홀더 또는 제거 |
| 특정 테이블명·컬럼명 | `expense_report`, `department_id` | `<table>`, `<column>` 플레이스홀더 |
| 특정 파일 경로 | `web/src/components/nav.tsx` | `<project-root>/src/...` 일반화 |
| 특정 이슈 번호 | `이슈 #123`, `#42` | 제거하거나 `[관련 이슈 번호]`로 변경 |
| 특정 날짜·수치 데이터 | `(2026-06-05 조사)`, `1,234건` | 제거하거나 `[조사 시점]`, `[N건]`으로 추상화 |
| Harness 경로 | `.agents/learnings/<project>-*.md` | `.agents/learnings/<skill-name>.md`로 일반화 |

#### 🟢 보존 대상 (건드리지 않는다)

- 스킬의 핵심 판단 규칙·체크리스트
- 코드 블록 안의 기술 용어 (함수명, CLI 명령어, HTTP 메서드 등)
- frontmatter의 `name` 필드 (kebab-case 그대로)
- 일반적인 예시 코드 (`<placeholder>` 기반)

### 2-3. 정제 원칙

1. **한글 등록 원칙**: 스킬 설명(description), README 카탈로그 문구, 안내 메시지 및 정제된 설명 등은 **한글로 작성하여 등록**한다. (단, frontmatter의 `name`이나 코드 용어 등 영문 표준 식별자는 예외)
2. **핵심 규칙은 그대로** — 패턴, 판단 기준, 체크리스트는 보존한다.
3. **예시는 범용화** — 도메인 특화 예시는 일반적인 예시로 교체한다.
4. **플레이스홀더 명명 규칙**: `<kebab-case-placeholder>` 형식 사용.
5. **frontmatter 언어**: `description`은 한글로 작성하여 등록한다.
6. **안내 문구 추가**: 커스터마이징이 필요한 스킬에는 파일 최상단에 아래를 추가한다:
   ```
   > **[안내]** 이 파일은 각 프로젝트가 복사해갈 때 프로젝트 상황에 맞게 수정하여 사용하는 템플릿이다.
   > 적용 시 이 안내 문구를 제거하고 프로젝트에 맞게 내용을 수정한다.
   ```
7. **Harness Integration 섹션 처리**:
   - Phase 0/5 패턴은 그대로 유지 (범용 하네스 패턴)
   - 프로젝트 특화 경로만 플레이스홀더로 교체

### 2-4. 정제된 내용을 사용자에게 미리 보여주고 확인

스킬별로 정제 전/후 주요 변경 사항을 요약하여 사용자에게 제시한다.
사용자가 "진행", "ok", "좋아" 등으로 승인하면 파일을 생성한다.

---

## Phase 3 — 파일 생성

### 3-1. 스킬 디렉터리 및 SKILL.md 생성

```bash
# 디렉터리 구조
<ai-agent-configs>/library/skills/<skill-name>/SKILL.md

# 보조 파일이 있는 경우
<ai-agent-configs>/library/skills/<skill-name>/references/<file>
<ai-agent-configs>/library/skills/<skill-name>/scripts/<file>
```

### 3-2. frontmatter 품질 검증

생성 후 반드시 확인:

```bash
# name 필드 존재 확인
grep '^name:' <ai-agent-configs>/library/skills/<skill-name>/SKILL.md

# description 필드 존재 확인
grep '^description:' <ai-agent-configs>/library/skills/<skill-name>/SKILL.md

# 절대 경로 사용 여부 확인 (있으면 안 됨)
grep 'file:///home' <ai-agent-configs>/library/skills/<skill-name>/SKILL.md
```

---

## Phase 4 — README.md 동기화

`library/README.md`의 스킬 표에 신규 스킬을 추가한다.

### 4-1. 카테고리 판별

| 스킬 성격 | 카테고리 |
|-----------|----------|
| Git, 커밋, 버전 관리 | 코드 품질 & 개발 |
| GitHub, PR, 이슈 | GitHub & 이슈 관리 |
| UI 컴포넌트, CSS, UX 패턴 | UI/UX & 프론트엔드 |
| DB, 문서, 마크다운 | 데이터 & 문서 |
| 에이전트 구조, 하네스, 스킬 관리 | AI 에이전트 운영 |
| 서버 접근, 배포 안전, 인프라 | 시스템 & 인프라 |
| 기획, 번역, 커뮤니케이션 | 기획 & 문서화 |

### 4-2. 표 행 추가 형식

```markdown
| [<skill-name>](./skills/<skill-name>/SKILL.md) | <한 문장 목적 설명> |
```

### 4-3. 스킬 카운트 업데이트

`## 🛠️ 스킬 (N개)` 헤딩의 숫자를 실제 개수로 갱신한다.

---

## Phase 5 — 품질 검증

모든 스킬 생성 후 일괄 검증한다:

```bash
# frontmatter 누락 검사
for f in <ai-agent-configs>/library/skills/*/SKILL.md; do
  grep -q '^name:' "$f" || echo "[name 누락] $f"
  grep -q '^description:' "$f" || echo "[description 누락] $f"
done

# 절대 경로 사용 검사
grep -rn 'file:///home' <ai-agent-configs>/library/ --include='*.md'

# README 스킬 카운트 vs 실제 디렉터리 수 비교
echo "README 카운트: $(grep '## 🛠️ 스킬' <ai-agent-configs>/library/README.md)"
echo "실제 디렉터리 수: $(ls <ai-agent-configs>/library/skills/ | wc -l)"
```

---

## Phase 6 — 커밋

검증 통과 후 커밋한다:

```bash
# 신규 스킬 파일만 스테이징
git add library/skills/<skill-name>/
git add library/README.md

# 커밋 메시지 형식
git commit -m "feat: library/skills/<skill-name> 신규 스킬 추가 — <한 줄 목적>"

# 여러 스킬을 한 번에 이관한 경우
git commit -m "feat: library/skills/ <N>개 스킬 승격 이관 — <스킬명 목록>"
```

**커밋 규칙**:
- 이슈 번호 없어도 됨 (`feat:` / `chore:` 접두어만 필수)
- description 생략 금지
- `git push` 금지 — 커밋까지만 진행

---

## 절대 규칙

1. **Phase 1 분류 결과를 사용자에게 먼저 보여준다** — 사용자 승인 없이 파일을 생성하지 않는다.
2. **도메인 특화 내용을 그대로 복사하지 않는다** — 반드시 정제 후 이관한다.
3. **README.md를 반드시 업데이트한다** — 파일만 추가하고 목록을 빠뜨리면 카탈로그가 깨진다.
4. **스킬 카운트를 반드시 갱신한다** — 숫자가 틀리면 신뢰도가 떨어진다.
5. **한 번에 하나씩 사용자에게 확인받는다** — 일괄 생성 후 사후 보고하지 않는다.
6. **`~/prj` 전체 디렉터리 스캔 금지 & `~/ai-agent-configs` 직행**: 경로 확인/스캔 목적으로 `~/prj` 아래 모든 프로젝트 디렉터리를 탐색하지 않는다. 대상 경로는 `~/ai-agent-configs`로 바로 접근하고, 소스 경로는 현재 작업 중인 워크스페이스(또는 명시된 특정 프로젝트)만 지정해서 바로 사용한다.
