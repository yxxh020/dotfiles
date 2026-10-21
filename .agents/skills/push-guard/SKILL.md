---
name: push-guard
description: 배포 브랜치(dev, main 등)에 push할 때 버전 정보 변경 여부를 확인하고, 사용자 승인 후 push를 진행하는 가드 스킬.
---

# Push Guard — 배포 브랜치 Push 전 버전 확인 스킬

## 언제 이 스킬을 사용하는가 (When to Invoke)

다음 조건을 **모두** 만족할 때 이 스킬을 **반드시** 실행합니다:

- 사용자가 배포 브랜치(`dev`, `main`, `release` 등)에 **push**를 요청하거나, push를 포함하는 작업을 수행할 때
- 구체적으로: `git push`, `gp`, merge 후 push, 또는 "dev에 반영해줘", "배포해줘" 등의 요청

> **예외**: 개인 작업 브랜치(feature, hotfix 등)로의 push에는 적용하지 않습니다.

## 실행 절차 (Procedure)

### Step 1: 현재 브랜치 확인

push 대상이 배포 브랜치인지 확인합니다.
해당하지 않으면 이 스킬을 건너뛰고 바로 push합니다.

### Step 2: 현재 버전 정보 조회

프로젝트의 버전 관리 파일에서 현재 버전을 조회합니다:

```bash
# 단일 package.json 프로젝트
grep '"version"' package.json | head -1

# 모노레포 (필요 시)
for pkg in $(find . -name "package.json" -maxdepth 3 -not -path "*/node_modules/*"); do
  echo "$pkg: $(grep '"version"' $pkg | head -1)"
done

# Python 프로젝트
grep 'version' pyproject.toml setup.cfg setup.py 2>/dev/null | head -5
```

### Step 3: 사용자에게 확인 질문

`ask_question` 도구를 사용하여 다음과 같이 질문합니다:

**질문 내용:**
```
현재 버전: v{버전}

배포 브랜치에 push합니다. 버전 정보를 변경했나요?
```

**선택지:**
1. "네, 현재 버전 그대로 push합니다"
2. "버전을 올려주세요 (patch: x.y.Z+1)"
3. "버전을 올려주세요 (minor: x.Y+1.0)"
4. "push를 취소합니다"

### Step 4: 응답에 따른 처리

| 응답 | 동작 |
|------|------|
| 그대로 push | 즉시 push 진행 |
| patch 버전 올림 | 버전 파일의 version을 patch 올림 → 커밋 → push |
| minor 버전 올림 | version을 minor 올림 → 커밋 → push |
| 취소 | push 중단, 사용자에게 알림 |

### Step 5: 버전 변경 시 커밋 형식

```
chore: bump version to {새 버전}
버전 {새 버전}으로 변경
```

- 모노레포의 경우 관련 패키지들의 버전을 **동일하게** 맞춥니다.

## 중요 규칙

1. **절대 건너뛰지 않기**: 배포 브랜치 push 시 이 스킬은 반드시 실행합니다. "빨리 해달라"는 요청에도 질문을 생략하지 않습니다.
2. **버전 동기화**: 모노레포 내 관련 패키지의 버전은 항상 동일하게 유지합니다.
3. **커밋 분리**: 버전 변경 커밋은 기능 커밋과 분리합니다.


### ⛔ 독단적 결정 금지 (Do NOT Decide Alone)
- 버전 정보가 변경되었을 때 사용자의 확인 없이 배포 브랜치로 push하는 행위 금지
- 버전 bump 검증 단계를 우회하는 행위 금지
