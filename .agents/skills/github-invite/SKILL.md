---
name: github-invite
description: GitHub CLI(gh) 및 API를 사용하여 현재 저장소에 협업자(Collaborator)를 초대하고 권한을 설정하는 스킬.
---

# GitHub 협업자 초대 스킬 (github-invite)

당신은 GitHub CLI(`gh`)와 GitHub REST API를 활용하여 **현재 작업 중인 저장소**에 다른 사용자를 협업자(Collaborator)로 초대하고, 초대 현황을 조회하거나 취소하는 작업을 수행하는 `github-invite` 전문가이다.

> **범위 제한**: 이 스킬은 현재 로컬 Git 저장소(`git remote -v`로 확인된 `origin`)를 대상으로 동작한다. 작업 전 반드시 대상 저장소를 확인한다.

## 핵심 기능

1. **협업자 초대**: 현재 저장소에 유저네임을 지정하여 협업자 초대를 진행하고 권한을 부여한다.
2. **초대 현황 조회**: 현재 저장소의 대기 중인 협업자 초대 목록을 조회한다.
3. **초대 취소**: 특정 사용자에 대한 초대를 취소한다.
4. **안전성 검증**: 명령어 실행 전 CLI 로그인 상태 및 타겟 저장소를 확인한다.

## 실행 지침

### 1. 사전 확인

```bash
# 현재 로그인 계정 확인
gh auth status

# 현재 작업 저장소 확인
gh repo view --json owner,name
```

> 타겟 저장소가 의도한 저장소인지 확인 후 진행한다.

### 2. 협업자 초대

```bash
# 초대 (권한: pull / push / admin / maintain / triage)
gh api -X PUT \
  /repos/<OWNER>/<REPO>/collaborators/<USERNAME> \
  -f permission=push
```

- `<OWNER>/<REPO>`는 `gh repo view --json owner,name`으로 확인한 값을 사용한다.
- 권한 레벨 기본값: `push` (읽기·쓰기)

### 3. 대기 중인 초대 조회

```bash
gh api /repos/<OWNER>/<REPO>/invitations
```

### 4. 초대 취소

```bash
gh api -X DELETE \
  /repos/<OWNER>/<REPO>/collaborators/<USERNAME>
```

## 주의 사항
- 초대 전 대상 사용자의 GitHub 아이디를 정확히 확인한다.
- `admin` 권한 부여는 신중히 결정한다.
- 초대된 사용자가 수락해야 협업자로 활성화됩니다.
