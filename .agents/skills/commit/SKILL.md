---
name: commit
description: 이번 세션에서 수정한 파일만 선택적으로, 관련 단위로 묶어 커밋한다. 푸시하지 않는다.
---

# 커밋 스킬 (세션 파일 한정)

현재 세션에서 완료한 작업을 커밋할 때 이 스킬의 제약 사항을 준수한다. 변경 사항을 작고 논리적인 단위로 묶어 커밋하며, 원격 저장소에 푸시하지 않다.

## 규칙

- **Fast-Path (문서 및 사소한 유지보수)**:
  - `docs`(문서/위키), `style`, 단순 `chore`(사소한 설정/패키지/정리)는 GitHub 이슈를 검색하거나 생성하지 않고 즉시 `<타입>: <설명>` 형식으로 커밋한다. (이슈 번호 생략 허용)
- **Normal-Path (GitHub 이슈 연동 필수 대상)**:
  - 기능 개발(`feat`), 버그 수정(`fix`), 리팩토링(`refactor`), 아키텍처/스키마 변경 등 추적이 필요한 작업은 반드시 GitHub 이슈와 연동한다 (`<타입>: #<이슈번호> <설명>`).
  - **이슈 검색 제한**: 이슈 조회는 `gh issue list --state open --limit 10` 1회로 한정하며, 키워드 검색(`--search`)을 여러 번 반복하지 않는다. 목록에 없으면 즉시 [github-issue](../github-issue/SKILL.md) 스킬로 1회 생성한다.
- **테스트 확인 필수**: `src/utils/`, `src/lib/`, `src/app/api/` 등 로직 파일을 수정했다면, 반드시 관련된 테스트 코드(`src/__tests__/`)도 작성되었는지 확인한다. 만약 누락되었다면 사용자에게 **"관련 테스트 코드도 함께 작성해서 커밋할까?"**라고 먼저 물어봅니다.
- **선택적 커밋**: 이번 세션에서 수정한 파일만 커밋한다. 전체 작업 트리를 커밋해야 하는 상황이면 `commit-all` 스킬을 활용한다.
- **논리적 분리**: 관련 변경 사항을 하나의 커밋으로 묶는다. (기능/수정 단위로 1커밋)
- **`git add .` 금지**: `git add .` 또는 `git add -A` 사용을 금지한다. 파일명을 명시해서 스테이징한다. (`git add <파일>`)
- **Push 금지**: 사용자가 명시적으로 요청하지 않는 한 절대 푸시하지 않는다.
- **버전 체크 전면 중지 (상시 질문 금지)**: 커밋 시 버전 체크나 버전 업(Bump) 질문을 일체 하지 않고 항상 스킵한다. 버전 업데이트 및 태그 생성은 오직 사용자가 채팅창에서 명시적으로 지시했을 때만 수행한다.

## 커밋 메시지 형식

```
<타입>: #<이슈번호> <설명>      (feat, fix, refactor 등)
<타입>: <설명>                 (docs, style, chore 등 Fast-Path)
```

허용 타입: `feat`, `fix`, `docs`, `refactor`, `test`, `chore`, `style`, `perf`

> **주의**: `type(#issue):` 형식(괄호 안에 이슈 번호)은 커밋 훅에서 거부될 수 있으므로 반드시 `type: #issue` 형식을 사용한다.

> **설명은 필수** — 절대 생략하지 않는다.

템플릿:
```
feat: #<N> <무엇을 왜 추가했는지>
fix: #<N> <무엇이 문제였고 어떻게 고쳤는지>
refactor: #<N> <무엇을 왜 리팩토링했는지>
docs: <무엇을 문서화했는지>              ← 이슈 번호 생략 가능 (Fast-Path)
chore: <어떤 유지보수 작업을 했는지>      ← 이슈 번호 생략 가능 (Fast-Path)
```

## 절차 (가이드라인)

1. `git status` — 수정된 파일 확인
2. 이슈가 없으면 [github-issue](../github-issue/SKILL.md)로 생성
3. 파일을 논리 단위로 묶기 (예: API 변경끼리, 문서 변경끼리)
4. 각 그룹별:
   - 파일 스테이징: `git add <파일1> <파일2>`
   - **(선택적) Jev 기반 커밋 타입 자동 판정**: `jev` CLI가 환경에 있을 경우 고속으로 타입을 분류한다.
     ```bash
     TYPE=$(git diff --cached --stat | jev -c "feat,fix,docs,refactor,test,chore,style,perf" -q)
     ```
   - 커밋 메시지 작성: `<타입>: #<이슈번호> <설명>`
   - **(선택적) Jev 기반 메시지 형식 검증**:
     ```bash
     IS_VALID=$(jev "$COMMIT_MSG" -y "Does this commit message strictly follow '<type>: #<issue> <desc>' format?" -q)
     ```
   - 커밋 실행: `git commit -m "<타입>: #<이슈번호> <설명>"`
5. 확인: `git log --oneline -5`

> **Jev Graceful Fallback**: `jev` 명령어가 없거나 Keyring 조회가 안 되는 환경에서는 에러를 내지 않고 기본 룰 기반(인간/AI 직접 판단)으로 자연스럽게 진행한다.
