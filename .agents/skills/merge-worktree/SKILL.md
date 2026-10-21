---
name: merge-worktree
description: >-
  워크트리 작업 완료 후 clean commit → 원 브랜치 머지 → 워크트리 폴더 삭제까지 3단계를 순서대로 수행하는 워크트리 마무리 워크플로우.
  "머지하고 워크트리 정리해줘", "merge-worktree", "워크트리 마무리" 등의 요청 시 발동한다.
---

# merge-worktree 워크플로우

워크트리에서 작업을 마친 뒤 **커밋 → 머지 → 워크트리 삭제**를 안전하게 순서대로 수행한다.

---

## 사전 상태 파악

워크플로우 시작 전 현재 상태를 확인한다.

```bash
# 현재 워크트리 브랜치 및 경로 파악
git branch --show-current
git worktree list
```

확인 후 다음 정보를 메모한다:
- **현재 브랜치** (워크트리 브랜치): 작업 중인 브랜치명
- **워크트리 경로**: 삭제할 폴더 절대 경로
- **원 브랜치** (머지 대상): 사용자에게 확인 (보통 `main`, `dev`, `master` 중 하나)

> [!IMPORTANT]
> 원 브랜치가 불명확하면 **반드시 사용자에게 확인**한다.
> ```
> 어느 브랜치에 머지할까요? (예: main / dev / master)
> ```

---

## Step 1. Clean Commit

```bash
# 1-1. 변경 파일 확인
git status

# 1-2. 미커밋 변경사항이 있으면 논리 단위로 나눠 커밋
#      (git add . 금지 — 파일명 명시 필수)
git add <파일1> <파일2>
git commit -m "<타입>: #<이슈번호> <설명>"

# 1-3. 커밋 후 깨끗한 상태 확인
git status   # → "nothing to commit, working tree clean" 이어야 함
```

**체크포인트**: `git status`가 clean이 아니면 Step 2로 넘어가지 않는다.

> [!CAUTION]
> - `git add .` 또는 `git add -A` 사용 금지
> - Push 금지 (사용자가 명시적으로 요청하지 않는 한)

---

## Step 2. 원 브랜치에 머지

```bash
# 2-1. 원 브랜치로 이동 (워크트리 내부가 아닌 메인 체크아웃에서 실행)
git checkout <원 브랜치>

# 2-2. 워크트리 브랜치를 머지
git merge --no-ff <워크트리 브랜치> -m "merge: #<이슈번호> <워크트리 브랜치명> 작업 통합"

# 2-3. 머지 결과 확인
git log --oneline -5
```

> [!IMPORTANT]
> - `--no-ff` 옵션을 사용하여 머지 커밋을 명시적으로 남긴다 (fast-forward 방지).
> - 충돌 발생 시 **즉시 중단**하고 사용자에게 알린다. 독단으로 충돌을 해결하지 않는다.

**충돌 발생 시 보고 형식**:
```
⚠️ 머지 충돌이 발생했습니다.
충돌 파일: <파일 목록>
git mergetool 또는 수동으로 해결 후 진행해 주세요.
```

---

## Step 3. 워크트리 삭제 (폴더 포함)

```bash
# 3-1. 워크트리 등록 해제 (git이 추적하는 메타데이터 제거)
git worktree remove <워크트리 경로> --force

# 3-2. 폴더가 남아있으면 강제 삭제
rm -rf <워크트리 경로>

# 3-3. 워크트리 목록에서 제거되었는지 확인
git worktree list

# 3-4. (선택) 워크트리 브랜치 삭제 여부 확인
```

Step 3-4에서 **브랜치 삭제는 사용자에게 확인** 후 진행한다:
```
워크트리 브랜치 '<브랜치명>'도 삭제할까요?
  → 삭제: git branch -d <브랜치명>
  → 유지: 생략
```

---

## 완료 보고 형식

```
✅ merge-worktree 완료

1. 커밋: <커밋 해시 앞 7자리> — <커밋 메시지>
2. 머지: <워크트리 브랜치> → <원 브랜치> (--no-ff)
3. 워크트리 삭제: <삭제된 경로>
4. 브랜치: <삭제됨 / 유지됨>
```

---

## 빠른 참조 — 전체 명령 순서

```bash
# [상태 파악]
git branch --show-current
git worktree list

# [Step 1: Clean Commit]
git status
git add <파일>
git commit -m "<타입>: #<N> <설명>"
git status  # clean 확인

# [Step 2: 머지]
git checkout <원 브랜치>
git merge --no-ff <워크트리 브랜치> -m "merge: #<N> <브랜치명> 작업 통합"
git log --oneline -5

# [Step 3: 워크트리 삭제]
git worktree remove <경로> --force
rm -rf <경로>
git worktree list  # 제거 확인

# [Step 4: 브랜치 삭제 (사용자 확인 후)]
git branch -d <워크트리 브랜치>
```

---

## 독단 금지 요약

| 금지 행위 |
| :--- |
| 원 브랜치 불명확 시 임의로 선택하여 머지 |
| `git add .` 사용 |
| Push 수행 (사용자 명시 요청 없이) |
| 충돌 상태에서 독단으로 해결 후 진행 |
| 워크트리 브랜치를 사용자 확인 없이 삭제 |
