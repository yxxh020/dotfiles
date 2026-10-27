---
description: GitHub 이슈 전체를 분석하여 계획 댓글을 달고, 승인 후 순차적으로 해결한다.
skill: issues-plan-and-resolve
---

# 워크플로우: 이슈 계획 및 순차 해결

열린 이슈 전체를 분석하여 **이슈별 실행 계획을 댓글로 등록**하고, 승인 후 **의존성 순서대로 해결**한다.

**핵심 원칙:**
- 분석은 병렬, 구현은 순차.
- 같은 파일을 수정하는 이슈가 여럿이면 실행 순서를 엄격히 결정한다.
- 커밋 게이트는 테스트 러너의 종료 코드로만 결정한다.

이 워크플로우는 두 단계로 나뉘어 호출될 수 있다:
1. **"계획 댓글 달아줘"**: Phase 2까지 실행 후 중단.
2. **"이슈 전부 처리해줘"**: Phase 3~5 실행 (계획 댓글이 이미 있으면 분석 생략).

---

## Phase 1: 이슈 수집 및 병렬 분석

- [ ] `gh issue list --state open --json number,title,body`로 열린 이슈 전체를 가져온다.
- [ ] **(선택적) Jev 착수 적합성 판정 (Readiness Gate)**: `command -v jev` 확인 시, 이슈별 즉시 착수 가능 여부(-y)를 고속 판정하여 보류할 이슈와 진행할 이슈를 즉시 분리한다.
  ```bash
  IS_READY=$(gh issue view $ISSUE_NUM --json body -q .body | \
    jev -y "Is this issue actionable immediately without external dependencies, credentials, or undecided specs?" -q)
  ```
- [ ] 관련 파일/모듈이 겹치는 이슈를 그룹화한다.

---

## Phase 2: 계획 댓글 등록

각 이슈에 `gh issue comment N --body-file`로 계획 댓글을 작성한다:

```
**접근 방식**: 핵심 계획 및 구현 방향 (file:line 참조 포함)
**영향 파일**: 수정할 파일 목록
**단계**: 상세 계획 (3-5 단계)
**의존성**: 선행 이슈 또는 같은 파일을 건드리는 다른 이슈
**복잡도**: S/M/L
```

> **(선택적) Jev 복잡도 추정**: `gh issue view $ISSUE_NUM --json body -q .body | jev -c "S,M,L" -i "Estimate the implementation complexity of this issue." -q`

- [ ] 의존성 그래프와 권장 작업 순서를 사용자에게 보고한다.
- [ ] 계획만 요청한 경우 **여기서 중단**한다. 명시적 승인 없이 Phase 3으로 넘어가지 않는다.

---

## Phase 3: 셋업 및 실행 준비

- [ ] 전용 실행 브랜치를 생성한다.
- [ ] 실행 순서 규칙:
  1. 테스트 인프라 → 2. 단순 수정 → 3. 의존성 순서 → 4. 독립 이슈 → 5. 대규모 리팩토링 → 6. 문서 동기화 (항상 마지막)

---

## Phase 4: 이슈 해결 루프

각 이슈를 순차적으로 처리:

1. **RED**: 버그를 재현하거나 새 기능을 검증하는 실패 테스트 작성
2. **GREEN**: 테스트를 통과하기 위한 최소 코드 구현
3. **코드 변경 안전성 검증 (Surgical Gate)**: 수정 후 diff가 목표 파일에만 한정되었는지 확인
   ```bash
   git diff --stat | jev -y "Does this diff modify only the necessary files directly related to the issue without touching unrelated configs or modules?" -q
   ```
4. **커밋 게이트**: 테스트 러너 직접 실행. **종료 코드가 0일 때만 커밋**
   - Jev 기반 커밋 타입 및 메시지 규격 검증:
     ```bash
     TYPE=$(git diff --cached --stat | jev -c "feat,fix,docs,refactor,test,chore,style,perf" -q)
     IS_VALID_MSG=$(jev "$COMMIT_MSG" -y "Does this commit message strictly follow '<type>: #<issue> <desc>' format?" -q)
     ```
5. **이슈 종료**: `gh issue close N`에 검증 요약, 테스트 결과, 커밋 해시 포함
6. ⚡ **실시간 브리핑 및 자동 진행 (Auto-Continue)**:
   - 각 이슈 처리 완료 시 아래 항목을 실시간 브리핑하고, 사용자 입력 대기 없이 즉시 다음 이슈로 자동 진행한다:
     - 🔍 **이슈 내용 및 결함 요약** (이슈 번호, 제목, 현상)
     - 🛠 **수정 조치 리스트** (수정 파일 및 변경 내용)
     - 💡 **원인 분석 및 설명** (발생 배경 및 해결 전략)
     - ⏩ **다음 단계** (다음 순차 이슈 착수 안내)
7. **에러 복구**: 실패 시 1회 재시도. 2회 실패 시 실패 기록 후 다음 이슈로 자동 진행

---

## Phase 5: 마무리

- [ ] 전체 테스트 스위트 실행
- [ ] 요약 테이블 출력 (이슈, 상태, 커밋, 성공/실패 카운트)
- [ ] 사용자 요청 시에만 push

---

## 흔한 실수 방지

| 실수 | 방지 |
|---|---|
| 커밋 전 해시 플레이스홀더 남김 | 커밋 후 `git log -1 --format=%h`로 실제 해시 추출 |
| 파이프 명령으로 종료 코드 가려짐 | 테스트 러너 직접 실행 또는 `; echo "EXIT=$?"` |
| 같은 파일 수정 이슈를 순서 없이 처리 | Phase 2에서 겹치는 파일 식별 후 순차 큐잉 |
| 코드 안정화 전 문서 동기화 | 문서 이슈는 반드시 마지막 |
