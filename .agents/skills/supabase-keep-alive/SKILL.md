---
name: supabase-keep-alive
description: >-
  Supabase Free 티어 프로젝트가 7일 비활성 시 자동으로 일시정지되는 것을 방지하기 위해
  GitHub Actions 워크플로우(3일마다 ping)를 생성·등록·검증하는 전문가 스킬.
  KeePassXC에서 Supabase 키를 자동 탐지하고, REST API ping 방식으로 keep-alive 구성을 완전 자동화한다.
  "supabase 살려줘", "supabase keep-alive", "supabase 잠드는 거 방지", "supabase free tier 비활성화",
  "supabase 깨우기" 등의 요청 시 반드시 이 스킬을 사용한다.
---

# 🟢 Supabase Keep-Alive 전문가 스킬

Supabase Free 티어는 **7일간 활동이 없으면 자동으로 일시정지**됩니다.
이 스킬은 GitHub Actions를 활용해 **3일마다 REST API를 ping**하여 프로젝트를 항상 활성 상태로 유지합니다.

---

## 1. 전체 워크플로우

```
① KeePass에서 Supabase 키 탐지
       ↓
② DB 연결 생존 확인
       ↓
③ GitHub Secrets 등록 (SUPABASE_URL, SUPABASE_ANON_KEY)
       ↓
④ .github/workflows/keep-alive.yml 생성
       ↓
⑤ dev 브랜치 커밋 & push
       ↓
⑥ main 브랜치 cherry-pick & push  ← GitHub Actions는 기본 브랜치에서만 트리거!
       ↓
⑦ workflow_dispatch 수동 트리거 & 결과 확인
```

---

## 2. KeePass 항목 탐지

프로젝트마다 KeePass 항목명이 다르므로 아래 순서로 탐지한다:

```bash
export DBUS_SESSION_BUS_ADDRESS="${DBUS_SESSION_BUS_ADDRESS:-unix:path=/run/user/1000/bus}"

# 전체 항목 나열 후 프로젝트명으로 필터링
busctl --user call org.freedesktop.secrets /org/freedesktop/secrets/collection/login \
  org.freedesktop.DBus.Properties Get ss \
  org.freedesktop.Secret.Collection Items 2>/dev/null \
  | grep -oP '/org/freedesktop/secrets/collection/login/[a-f0-9]+' \
  | while read -r item; do
    busctl --user call org.freedesktop.secrets "$item" \
      org.freedesktop.DBus.Properties Get ss \
      org.freedesktop.Secret.Item Label 2>/dev/null \
      | sed 's/^v s //; s/^. s //'
  done | grep -i "<프로젝트명>"
```

### 항목명 패턴별 조회 방법

| 패턴 | 조회 명령 |
|---|---|
| `Title` 기반 (일반) | `secret-tool lookup Title '항목명'` |
| `URL` 속성 기반 | `secret-tool lookup Title '.env' URL '/home/hyuk/prj/<프로젝트>'` |
| production 전용 | `secret-tool lookup Title '<프로젝트>.env.production'` |

> [!TIP]
> `NEXT_PUBLIC_SUPABASE_URL`과 `NEXT_PUBLIC_SUPABASE_ANON_KEY`가 있는 항목을 찾아야 합니다.
> 개발 항목(`prokseoul.env`)에 없으면 **production 항목**(`prokseoul.env.production`)을 확인하세요.

### 키 목록 확인 (마스킹)

```bash
secret-tool lookup Title '항목명' | grep -E "SUPABASE|DATABASE_URL" | sed 's/=.*/=***마스킹***/'
```

---

## 3. DB 생존 확인

### 3-1. REST API 방식 (권장 — psql URL 파싱 문제 회피)

```bash
export DBUS_SESSION_BUS_ADDRESS="${DBUS_SESSION_BUS_ADDRESS:-unix:path=/run/user/1000/bus}"
RAW=$(secret-tool lookup Title '항목명' 2>/dev/null)
eval "$(echo "$RAW" | sed '/^$/d; /^#/d; s/^/export /')"

HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" \
  -H "apikey: $NEXT_PUBLIC_SUPABASE_ANON_KEY" \
  -H "Authorization: Bearer $NEXT_PUBLIC_SUPABASE_ANON_KEY" \
  "${NEXT_PUBLIC_SUPABASE_URL}/rest/v1/<테이블명>?select=id&limit=1")

echo "HTTP $HTTP_STATUS"
# 200/206/401/403 = 정상 (401/403은 RLS로 막혀도 서버는 활성 상태)
```

### 3-2. psql 방식 (단, 비밀번호에 `%`, `=`, `?` 포함 시 파싱 실패)

```bash
CLEAN_URL=$(echo "$DATABASE_URL" | sed 's/?pgbouncer=true//;s/&pgbouncer=true//')
psql "$CLEAN_URL" -c "SELECT 1;" -t 2>&1
```

> [!WARNING]
> **psql URL 파싱 실패 패턴**: 비밀번호에 `%`, `=`, `?` 특수문자가 포함된 경우
> `psql: error: invalid percent-encoded token` 또는 `invalid integer value` 오류 발생.
> → **REST API 방식으로 전환**하거나 DIRECT_URL을 시도한다.

---

## 4. GitHub Secrets 등록

```bash
# KeePass에서 값 주입 후
echo -n "$NEXT_PUBLIC_SUPABASE_URL" | gh secret set SUPABASE_URL --repo <org>/<repo>
echo -n "$NEXT_PUBLIC_SUPABASE_ANON_KEY" | gh secret set SUPABASE_ANON_KEY --repo <org>/<repo>
```

---

## 5. keep-alive.yml 템플릿

`ping 테이블`은 해당 프로젝트의 public 테이블 중 기본적인 것을 사용한다.
(예: `boards`, `admins`, `users`, `posts` 등 — `prisma/schema.prisma`에서 `model` 목록 확인)

```yaml
name: Keep Supabase Alive

on:
  schedule:
    # 3일마다 한 번씩 실행 (UTC 기준 매 3일 00:00)
    - cron: '0 0 */3 * *'
  workflow_dispatch: # GitHub 웹 Actions 탭에서 수동 실행 가능

jobs:
  ping:
    name: Ping Supabase REST API
    runs-on: ubuntu-latest
    steps:
      - name: Send keep-alive request
        run: |
          if [ -z "${{ secrets.SUPABASE_URL }}" ] || [ -z "${{ secrets.SUPABASE_ANON_KEY }}" ]; then
            echo "::error::SUPABASE_URL or SUPABASE_ANON_KEY secret is not configured."
            exit 1
          fi

          HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" \
            -H "apikey: ${{ secrets.SUPABASE_ANON_KEY }}" \
            -H "Authorization: Bearer ${{ secrets.SUPABASE_ANON_KEY }}" \
            "${{ secrets.SUPABASE_URL }}/rest/v1/<테이블명>?select=id&limit=1")

          echo "Response HTTP Status: $HTTP_STATUS"

          # 200(성공), 206(부분성공), 401/403(RLS 차단이라도 서버 활성 요청으로 인정)
          if [[ "$HTTP_STATUS" =~ ^(200|206|401|403)$ ]]; then
            echo "Successfully pinged Supabase to keep project active."
          else
            echo "Unexpected status code: $HTTP_STATUS"
          fi
```

---

## 6. 배포 절차 (dev → main)

> [!IMPORTANT]
> **GitHub Actions 워크플로우는 저장소의 기본 브랜치(보통 `main`)에 있어야 트리거됩니다.**
> `dev` 브랜치에만 push하면 `workflow_dispatch`나 `schedule`이 동작하지 않습니다.

```bash
# 1) dev에 커밋
git add .github/workflows/keep-alive.yml
git commit -m "chore: Supabase keep-alive GitHub Actions 워크플로우 추가 (3일마다 ping)"
git push origin dev

# 2) main에 cherry-pick
COMMIT_HASH=$(git rev-parse HEAD)
git fetch origin main && git checkout main && git pull --rebase origin main
git cherry-pick $COMMIT_HASH
git push origin main

# 3) dev로 복귀
git checkout dev
```

---

## 7. 수동 트리거 & 결과 확인

```bash
# 트리거
gh workflow run keep-alive.yml --repo <org>/<repo>

# 결과 확인 (약 10-20초 후)
gh run list --repo <org>/<repo> --workflow keep-alive.yml --limit 1
gh run view <RUN_ID> --repo <org>/<repo>
```

성공 시: `✓ Ping Supabase REST API in 5s`

---

## 8. 일괄 생존 확인 (여러 프로젝트 동시)

```bash
export DBUS_SESSION_BUS_ADDRESS="${DBUS_SESSION_BUS_ADDRESS:-unix:path=/run/user/1000/bus}"

# 프로젝트별로 병렬 확인
for PROJ in "dong-hanh.env.local" "sien" "prokseoul.env.production"; do
  RAW=$(secret-tool lookup Title "$PROJ" 2>/dev/null)
  eval "$(echo "$RAW" | sed '/^$/d; /^#/d; s/^/export /')"
  STATUS=$(curl -s -o /dev/null -w "%{http_code}" \
    -H "apikey: $NEXT_PUBLIC_SUPABASE_ANON_KEY" \
    -H "Authorization: Bearer $NEXT_PUBLIC_SUPABASE_ANON_KEY" \
    "${NEXT_PUBLIC_SUPABASE_URL}/rest/v1/boards?select=id&limit=1" 2>/dev/null)
  [[ "$STATUS" =~ ^(200|206|401|403)$ ]] && echo "✅ $PROJ" || echo "❌ $PROJ (HTTP $STATUS)"
done
```

---

## 9. 트러블슈팅

### 워크플로우가 트리거되지 않음
- **원인**: 워크플로우 파일이 기본 브랜치(`main`)에 없음
- **해결**: Section 6의 cherry-pick 절차 수행

### `SUPABASE_URL` / `SUPABASE_ANON_KEY` Secret not configured 오류
- **원인**: GitHub Secrets 등록 누락 또는 항목명 불일치
- **해결**: `gh secret list --repo <org>/<repo>`로 확인 후 Section 4 재실행

### psql: invalid percent-encoded token
- **원인**: DATABASE_URL 비밀번호에 `%`, `=`, `?` 포함
- **해결**: REST API 방식 사용 또는 `DIRECT_URL` 시도

### KeePass 항목 조회 실패
- **원인**: KeePassXC 미기동, 잠금 상태, 항목명 불일치
- **진단**: `busctl --user list | grep secrets` → keepassxc 소유 여부 확인
- **참고**: `keyring-keepass` 스킬의 진단 절차 참조

---

## 10. 이 스킬이 적용된 프로젝트 현황

| 프로젝트 | KeePass 항목 | ping 테이블 | GitHub 리포 |
|---|---|---|---|
| dong-hanh | `dong-hanh.env.local` | `boards` | `wonhyukc/dong-hanh` |
| sien | `sien` | `admins` | `wonhyukc/sien` |
| prokseoul | `prokseoul.env.production` | `boards` | `dplusCompany/prokseoul` |
