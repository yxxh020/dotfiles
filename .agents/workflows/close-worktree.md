---
description: 완료된 워크트리 브랜치를 main에 머지하고, 워크트리를 삭제하고, 관련 이슈를 종료한다.
skills: [github-issue, push-guard]
---

현재 워크트리 브랜치의 작업이 완료되었을 때 아래 절차를 순서대로 실행한다.

## 사전 확인

1. `git status`로 커밋되지 않은 변경이 없는지 확인한다. 있으면 먼저 커밋하거나 사용자에게 알린다.
2. `git log --oneline main..HEAD`로 머지할 커밋 목록을 사용자에게 보여준다.
3. `git worktree list`로 현재 워크트리 경로와 메인 저장소 경로를 파악한다.

## 실행 절차

### Step 1: main에 머지

```bash
BRANCH=$(git branch --show-current)
MAIN_REPO=$(git worktree list | head -1 | awk '{print $1}')

# main 브랜치에서 현재 브랜치를 머지 (메인 저장소에서 실행)
git -C "$MAIN_REPO" merge "$BRANCH"
```

### Step 2: 원격 push

```bash
git -C "$MAIN_REPO" push origin main
```

- push-guard 스킬 규칙에 따라 main push 전 사용자 확인을 받는다.
- `.github/workflows/` 변경이 포함된 경우 SSH URL 우회를 고려한다.

### Step 3: 워크트리 및 브랜치 삭제

```bash
WORKTREE_PATH=$(pwd)
cd "$MAIN_REPO"
git worktree remove "$WORKTREE_PATH"
git branch -d "$BRANCH"
```

- `git worktree remove`가 실패하면 `--force` 옵션 사용 여부를 사용자에게 묻는다.
- 브랜치 삭제 시 `-d` (safe delete)를 먼저 시도하고, 머지 확인 실패 시 사용자에게 알린다.

### Step 4: 원격 브랜치 삭제

```bash
git push origin --delete "$BRANCH" 2>/dev/null || true
```

### Step 5: 관련 이슈 종료

- 커밋 메시지에서 `Closes #N`, `Fixes #N`, `#N` 패턴으로 이슈 번호를 추출한다.
- push로 자동 종료되지 않은 이슈가 있으면 `gh issue close <번호> --comment "워크트리 브랜치 머지 완료"` 로 수동 종료한다.
- `gh issue view <번호> --json state`로 종료 상태를 확인한다.

## 완료 보고

모든 단계 완료 후 아래 형식으로 사용자에게 보고한다:

| 항목 | 결과 |
|---|---|
| 머지된 브랜치 | `<브랜치명>` |
| 커밋 수 | N개 |
| 종료된 이슈 | #N |
| 삭제된 워크트리 | `<경로>` |
| main push | ✅ |
