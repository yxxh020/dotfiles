---
name: vercel-branch-deploy
description: Vercel 배포 시 특정 브랜치(main 전용 배포, dev 스킵 등)만 배포되도록 Ignored Build Step 및 환경을 제어하는 가이드 스킬.
---

# Vercel 브랜치 배포 제어 (Ignored Build Step)

Vercel에서 모든 브랜치 푸시마다 불필요하게 빌드/배포되는 것을 방지하고, 특정 브랜치(예: `main`)만 프로덕션 배포되도록 빌드 단계를 제어하는 표준 가이드이다.

---

## 1. 언제 이 스킬을 사용하는가? (트리거 조건)

- Vercel에서 `main` 브랜치만 배포하고 `dev`나 feature 브랜치는 배포를 건너뛰고 싶을 때
- 특정 브랜치(예: `dev`)의 빌드/배포만 비활성화하고 싶을 때
- Vercel 대시보드의 **Ignored Build Step** 설정을 구성하거나 안내할 때
- Vercel 빌드 크레딧/시간을 절약하기 위해 불필요한 Preview 배포를 차단할 때

---

## 2. Vercel Ignored Build Step 동작 원리

Vercel은 빌드 시작 전 **Ignored Build Step**에 정의된 셸 스크립트를 먼저 실행합니다:

| 종료 코드 (Exit Code) | Vercel 동작 | 설명 |
| :--- | :--- | :--- |
| **`0`** | **빌드 취소 (Ignored / Canceled)** | 빌드를 진행하지 않고 스킵함 (정상 종료로 간주) |
| **`1`** (또는 0이 아닌 값) | **빌드 진행 (Proceed with build)** | 실제 빌드 및 배포 단계로 넘어감 |

> ⚠️ 일반 셸 스크립트의 성공(`0`)/실패(`1`) 개념과 반대로, **`exit 0`이 빌드 스킵(무시)**이라는 점에 주의해야 한다.

---

## 3. 설정 방법 및 URL 구조 (★필수 규칙)

> ⭐️ **Vercel 메뉴 안내 필수 규칙**:
> Vercel 대시보드 메뉴나 설정을 사용자에게 설명/제시할 때는 **반드시 클릭 가능한 직접 링크를 함께 제공**해야 한다.
> 
> - **프로젝트 기본 대시보드**: `https://vercel.com/wonhyukc-s-projects/dong-hanh`
> - **Git / Ignored Build Step 설정**: [Vercel Git Settings](https://vercel.com/wonhyukc-s-projects/dong-hanh/settings/git) (`https://vercel.com/wonhyukc-s-projects/dong-hanh/settings/git`)
> - **환경 변수 설정**: [Vercel Environment Variables](https://vercel.com/wonhyukc-s-projects/dong-hanh/settings/environment-variables) (`https://vercel.com/wonhyukc-s-projects/dong-hanh/settings/environment-variables`)
> - **배포 목록 (Deployments)**: [Vercel Deployments](https://vercel.com/wonhyukc-s-projects/dong-hanh/deployments) (`https://vercel.com/wonhyukc-s-projects/dong-hanh/deployments`)

### 방법 1. `vercel.json` 파일로 코드베이스에서 직접 제어 (★가장 권장)
프로젝트 루트에 `vercel.json`을 작성하면 대시보드 UI를 찾을 필요 없이 가장 확실하게 적용됩니다:

```json
{
  "$schema": "https://openapi.vercel.sh/vercel.json",
  "ignoreCommand": "if [ \"$VERCEL_GIT_COMMIT_REF\" = \"main\" ]; then exit 1; else exit 0; fi"
}
```

### 방법 2. 대시보드 웹 UI에서 직접 설정
1. [Vercel Git Settings](https://vercel.com/wonhyukc-s-projects/dong-hanh/settings/git) 접속
2. **Ignored Build Step** 섹션으로 이동
3. **Command** 라디오 버튼 선택 후 조건에 맞는 명령어 입력 및 **Save**

---

## 4. 권장 명령어 프리셋

### 옵션 A. `main` 브랜치만 배포하고 다른 모든 브랜치는 스킵 (가장 권장)

`main` 브랜치 푸시 시에만 빌드를 진행하고(`exit 1`), `dev` 등 다른 모든 브랜치는 빌드를 건너뜁니다(`exit 0`).

```bash
if [ "$VERCEL_GIT_COMMIT_REF" = "main" ]; then exit 1; else exit 0; fi
```
*한 줄 축약형:*
```bash
[[ "$VERCEL_GIT_COMMIT_REF" == "main" ]] && exit 1 || exit 0
```

---

### 옵션 B. `dev` 브랜치만 배포를 건너뛰고, 나머지는 정상 배포

`dev` 브랜치 푸시만 빌드를 스킵하고(`exit 0`), `main` 및 PR 프리뷰는 정상 빌드합니다(`exit 1`).

```bash
if [ "$VERCEL_GIT_COMMIT_REF" = "dev" ]; then exit 0; else exit 1; fi
```

---

### 옵션 C. 특정 태그 또는 특정 패턴 브랜치만 배포

```bash
if [[ "$VERCEL_GIT_COMMIT_REF" =~ ^release/ || "$VERCEL_GIT_COMMIT_REF" == "main" ]]; then exit 1; else exit 0; fi
```

---

## 5. 주요 Vercel 환경 변수 참조

- `$VERCEL_GIT_COMMIT_REF`: 현재 배포를 트리거한 브랜치명 (예: `main`, `dev`, `feature/login`)
- `$VERCEL_ENV`: 배포 환경 (`production`, `preview`, `development`)
- `$VERCEL_GIT_COMMIT_MESSAGE`: 커밋 메시지 (특정 문구 포함 시 스킵 로직 등에 활용 가능)
