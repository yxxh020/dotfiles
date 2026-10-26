---
name: keyring-keepass
description: >
  KeePassXC와 Secret Service(secret-tool)를 활용해 민감한 설정 정보를 .env 파일 없이 셸 메모리로 주입하는 보안 스킬.
  목표: 모든 .env 파일 제거 + Keyring 중복 저장 금지.
  Use when: CI/CD 토큰, GitHub PAT, DB 패스워드, API 키 등 비밀값이 필요한 모든 상황.
  또는 secret-tool 조회 실패/타임아웃/빈 결과 등 KeePassXC 연동 문제를 진단할 때.
---

# 🔐 Keyring + KeePassXC 시크릿 관리 스킬

> **상세 설치·운영 가이드(SSOT)**: `~/dotfiles/docs/security/keepass-secrets-guide.md`
> 이 스킬은 AI 에이전트가 알아야 할 규칙·패턴·진단 절차의 요약본이다.

## 핵심 목표 (GOALS)

1. **`.env` 파일 완전 제거** — 디스크에 평문 비밀이 기록되면 안 된다.
2. **KeePassXC 단일 소스(SSOT)** — 모든 비밀값은 금고(`~/dotfiles/login.kdbx`)에만 존재한다.
3. **벌크 주입(Bulk Injection)** — `.env` 내용 전체를 항목 하나의 **Password 필드**에 저장하고, `.envrc`에서 1회 조회로 파싱·주입한다.

---

## 🎯 핵심 규칙 (Strict Policy)

1. **`.env*` 파일 사용 금지 (예외: `.env.example`, `.env.development`)**
   - `.env.example`: KeePass에 입력할 키 목록 템플릿 (실제 값 없음, git 추적)
   - `.env.development`: 비민감·머신별 값만 (PORT, 컨테이너 이름 등, git 미추적)
   - 그 외 실제 비밀값이 든 `.env`, `.env.local`, `.env.production` 등은 절대 생성 금지
2. **KeePassXC 항목 명명 규칙**: Title을 전역에서 고유하게 — `프로젝트명 .env.환경` 또는 `프로젝트명.env.환경`
   (예: `project .env.local`, `brain.env.production`) **Title 오타는 무음 실패를 일으키므로 정확히.**
3. **Connection URI 및 특수문자 저장 표준 (따옴표 불필요 원칙)**:
   - 데이터베이스 연결 주소(Connection URI)는 이미 특수문자를 URL 인코딩하여 표현한다. (예: `@` → `%40`, `/` → `%2F`, `:` → `%3A`)
   - 따라서 따옴표로 감싸지 않아도 파싱에 아무런 문제가 없으며, **순수 값만 저장**하는 것이 표준이다.
     - ❌ 비권장: `DATABASE_URL="postgresql://postgres.xxx:pass@aws-0.supabase.com:6543/postgres?pgbouncer=true"`
     - ✅ 권장: `DATABASE_URL=postgresql://postgres.xxx:pass@aws-0.supabase.com:6543/postgres?pgbouncer=true`
4. **AI 행동 지침**:
   - **`.env` 제안 금지**: 새 환경변수가 필요하면 사용자가 KeePassXC 항목의 Password 블록에 해당 키를 추가하도록 안내
   - **리팩토링 제안**: `.env` 파일을 로드하는 코드 발견 시 이 스킬의 패턴으로 전환 제안
   - **`secret-tool store` 실행 전** KeePassXC에 동일 항목이 있는지 먼저 확인 (중복 저장 금지)
5. **환경변수 키 명명 규칙 (언더스코어 강제, 하이픈 절대 금지)**:
   - KeePassXC 항목에 환경변수를 등록할 때 키 이름에 **하이픈(`-`) 사용을 엄격히 금지**한다.
     - ❌ 오류 발생: `TELEGRAM-BOT=...`, `API-KEY=...` (bash `eval ... export` 시 `export: not a valid identifier` 구문 에러 발생)
     - ✅ 올바른 표준: `TELEGRAM_BOT=...`, `API_KEY=...` (반드시 언더스코어 `_` 사용)
6. **KeePassXC 잠금 해제 요청 절대 금지 (GUI 상시 운영 전제)**:
   - KeePassXC는 항상 GUI 모드로 열려 있다고 가정한다.
   - `secret-tool` 조회가 빈 결과를 반환하면 **잠금 상태를 의심하거나 잠금 해제를 요청하지 않는다.**
   - 대신 아래 순서로 원인을 조사한다:
     1. Title 불일치 (오타, 공백 차이)
     2. FdoSecrets 노출 대상 데이터베이스 설정
     3. FdoSecrets Enabled=false 여부
   - "KeePassXC를 잠금 해제해 주세요", "금고가 잠겨 있는 것 같습니다" 등의 발언은 절대 금지

---

## 시스템 아키텍처

```
[KeePassXC 금고 ~/dotfiles/login.kdbx] → secret-tool → direnv(.envrc) → 환경변수 → 앱
          (암호화)                        (D-Bus)        (셸 훅)         (메모리만)
```

| 구성 요소 | 상태/위치 |
|------|------|
| 금고 파일 | `~/dotfiles/login.kdbx` — **파일명이 `login`이어야 go-keyring 앱 호환** (D-Bus 컬렉션명이 파일명에서 유래) |
| D-Bus 서비스 | `/usr/share/dbus-1/services/org.freedesktop.secrets.service` → `Exec=/usr/bin/keepassxc` |
| gnome-keyring | PAM·autostart에서 비활성화됨 (D-Bus 선점 방지) |
| login alias 스크립트 | `~/dotfiles/.bin/keepass-fdosecrets-alias.sh` (autostart, KeePassXC 등록 대기 후 `SetAlias login` 설정) |
| FdoSecrets 설정 | `~/.config/keepassxc/keepassxc.ini` `[FdoSecrets] Enabled=true`, `ConfirmAccessItem=false` |

### secret-tool이 매칭 가능한 속성 (실측 검증)

KeePassXC FdoSecrets는 항목마다 다음 속성을 **자동 노출**한다 (커스텀 속성 등록 불필요):

| 속성 | 값 형식 | 비고 |
|------|--------|------|
| `Title` | 항목 제목 | 주류 전략: Title을 고유하게 |
| `Path` | `/그룹/제목` (금고 폴더 구조에서 자동 유래) | 예: `/프로젝트/project .env.local` |
| `URL` | URL 필드 | 동일 Title 구분용 보조 키 |
| `UserName`, `Notes`, `Uuid` | 각 필드 값 | Notes도 속성으로 노출됨 (search 시 내용 보임) |

- `secret-tool lookup`은 지정한 **모든 key-value가 정확히 일치**하는 항목의 **Password 필드만** 반환
- Notes 필드는 lookup으로 반환 불가 → 벌크 블록은 반드시 **Password 필드**에

---

## `secret_lookup` 헬퍼 — prefix-matchable 조회 패턴

`secret-tool lookup`은 exact match만 지원하므로, Title이 조금만 달라도 무음 실패한다.
아래 헬퍼를 `.envrc` 또는 `.bin/` 스크립트에 정의하면 **exact → prefix fallback** 체인으로 안정적으로 동작한다.

```bash
# secret_lookup <prefix>
# 1단계: exact match (Title == prefix)
# 2단계: prefix match (Title이 prefix로 시작하는 첫 번째 항목)
# 출력: Password 값 (없으면 빈 문자열)
secret_lookup() {
  local prefix="$1"
  local result

  # 1단계: exact match
  result=$(secret-tool lookup Title "$prefix" 2>/dev/null)
  if [ -n "$result" ]; then
    echo "$result"
    return 0
  fi

  # 2단계: prefix match — busctl로 전체 항목 열거 후 Title 필터링
  local collection="/org/freedesktop/secrets/collection/login"
  local service="org.freedesktop.secrets"

  local items
  items=$(busctl --user call "$service" "$collection" \
    org.freedesktop.DBus.Properties Get ss \
    org.freedesktop.Secret.Collection Items 2>/dev/null \
    | grep -oP '/org/freedesktop/secrets/collection/login/[a-f0-9]+')

  if [ -z "$items" ]; then
    return 1
  fi

  local matched_title=""
  while IFS= read -r item; do
    local label
    label=$(busctl --user call "$service" "$item" \
      org.freedesktop.DBus.Properties Get ss \
      org.freedesktop.Secret.Item Label 2>/dev/null \
      | sed "s/^v s '//;s/'$//;s/^v s //")
    if [[ "$label" == "$prefix"* ]]; then
      matched_title="$label"
      break
    fi
  done <<< "$items"

  if [ -z "$matched_title" ]; then
    return 1
  fi

  # 매칭된 정확한 Title로 재조회
  secret-tool lookup Title "$matched_title" 2>/dev/null
}
```

> [!TIP]
> **언제 쓰나**: Title에 버전·날짜·suffix가 붙어 명명 규칙이 조금씩 달라지는 프로젝트.
> 예) `myproj.env.local` → `myproj .env.local` → `myproj.env.local.v2` 등 변형이 있을 때.

> [!WARNING]
> prefix가 여러 항목에 걸리면 **첫 번째만** 반환한다. 모호하지 않도록 prefix를 충분히 길게 지정할 것.

---

## 표준 `.envrc` 패턴 (검증 완료)

```bash
# 백그라운드/에이전트 환경에서도 D-Bus 세션 주소 보장
export DBUS_SESSION_BUS_ADDRESS="${DBUS_SESSION_BUS_ADDRESS:-unix:path=/run/user/1000/bus}"

# ── secret_lookup 헬퍼 정의 (exact → prefix fallback) ──────────────────
secret_lookup() {
  local prefix="$1" result="" collection="/org/freedesktop/secrets/collection/login"
  local svc="org.freedesktop.secrets" items="" matched_title=""
  result=$(secret-tool lookup Title "$prefix" 2>/dev/null)
  if [ -n "$result" ]; then echo "$result"; return 0; fi
  items=$(busctl --user call "$svc" "$collection" \
    org.freedesktop.DBus.Properties Get ss \
    org.freedesktop.Secret.Collection Items 2>/dev/null \
    | grep -oP '/org/freedesktop/secrets/collection/login/[a-f0-9]+')
  while IFS= read -r item; do
    local lbl
    lbl=$(busctl --user call "$svc" "$item" \
      org.freedesktop.DBus.Properties Get ss \
      org.freedesktop.Secret.Item Label 2>/dev/null \
      | sed "s/^v s '//;s/'$//;s/^v s //")
    if [[ "$lbl" == "$prefix"* ]]; then matched_title="$lbl"; break; fi
  done <<< "$items"
  [ -z "$matched_title" ] && return 1
  secret-tool lookup Title "$matched_title" 2>/dev/null
}
# ────────────────────────────────────────────────────────────────────────

# KeePassXC에서 민감 변수 조회 (이미 로드된 경우 중복 팝업 방지)
if [ -z "$MYPROJ_ENV_LOADED" ]; then
  RAW_ENV=$(secret_lookup '프로젝트명.env.환경' 2>/dev/null)
  if [ -n "$RAW_ENV" ]; then
    eval "$(echo "$RAW_ENV" | sed '/^$/d; /^#/d; s/^/export /')"
    export MYPROJ_ENV_LOADED=true
  else
    echo "❌ secret_lookup 조회 실패 — Title 오타 또는 KeePassXC 미기동/잠김 확인"
  fi
fi

# 비민감/머신별 설정 병합 (KeePassXC 값을 덮어씀)
if [ -f .env.development ]; then
  dotenv .env.development
fi
```

**필수 요소 6가지** — ① 가드 변수(`*_LOADED`, 재평가 시 팝업 방지) ② `sed`로 빈 줄·주석 제거 ③ `eval "$(...)"`  큰따옴표 ④ `DBUS_SESSION_BUS_ADDRESS` 기본값 ⑤ 빈 결과 검사(무음 실패 대비) ⑥ `secret_lookup` 헬퍼(exact → prefix fallback)

개별 조회가 필요한 단일 키는:
```bash
export GOOGLE_CREDS_JSON="$(secret_lookup 'drive-api' 2>/dev/null)"
export GH_TOKEN="$(gh auth token 2>/dev/null)"
```

---

## 🛡️ 심층 방어 (Defense in Depth) 정제 아키텍처

KeePassXC Password 필드에는 따옴표 없이 순수 값을 저장하는 것이 원칙이지만, 사용자의 입력 실수나 복사-붙여넣기 차이에 대비하여 **3중 방어선**을 구축해 둡니다.

```
[KeePassXC] (따옴표 유/무 무관)
     │
     ├── 1️⃣ Layer 1 (Shell / .envrc / .bin/run-dev.sh): 따옴표, 공백, CRLF(\r) 1차 정제 및 export
     │
     ├── 2️⃣ Layer 2 (Runtime / App - prisma.ts): cleanConnectionString()으로 앞뒤 따옴표 2차 방어
     │
     └── 3️⃣ Layer 3 (CLI / Migration - prisma.config.ts): CLI 실행 환경에서도 자동 정제
```

### 1. Shell / Script 계층 정제
`.bin/run-dev.sh` 또는 `.envrc`에서 export 시 불필요한 따옴표(`"`, `'`), 공백, 윈도우 줄바꿈(`\r`)을 제거:
```bash
# 예시: 변수 정제 유틸 함수
clean_val() {
  echo "$1" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' -e 's/^["'\'']//' -e 's/["'\'']$//' -e $'s/\r$//'
}
```

### 2. Node.js / App 런타임 계층 정제
`frontend/src/lib/prisma.ts` 등 DB 클라이언트 초기화 코드에서 연결 문자열 정제:
```typescript
function cleanConnectionString(url: string | undefined): string | undefined {
  if (!url) return url;
  return url.trim().replace(/^["']|["']$/g, '');
}
```

### 3. CLI / Migration 계층 정제
`frontend/prisma.config.ts` 등 Prisma CLI 및 마이그레이션 도구 설정에서도 동일하게 정제 적용:
```typescript
const databaseUrl = process.env.DATABASE_URL?.trim().replace(/^["']|["']$/g, '');
```

---

## 🩺 진단 절차 (조회 실패 시 순서대로)

```bash
# 1. Secret Service 소유자 확인 — keepassxc가 소유해야 정상
busctl --user list | grep secrets
#    "(activatable)"로만 표시 = KeePassXC가 서비스 미노출 → 2번으로
#    keepassxc 소유 = 서비스 정상 → 4번으로

# 2. FdoSecrets 활성화 여부 확인
grep -A3 '\[FdoSecrets\]' ~/.config/keepassxc/keepassxc.ini
#    Enabled=false 발견 시 (모든 프로젝트가 일제히 실패하는 원인):
pkill -x keepassxc && sleep 2      # 반드시 완전 종료 후 수정 (종료 시 ini 덮어쓰기 함정)
sed -i '/^\[FdoSecrets\]/,/^\[/{s/^Enabled=false/Enabled=true/}' ~/.config/keepassxc/keepassxc.ini
keepassxc ~/dotfiles/login.kdbx >/dev/null 2>&1 &   # 재시작 → 사용자에게 마스터 암호 입력 요청

# 3. 금고 잠금 상태 확인
busctl --user call org.freedesktop.secrets /org/freedesktop/secrets/collection/login \
  org.freedesktop.DBus.Properties Get ss org.freedesktop.Secret.Collection Locked
#    "v b true" = 잠김 → Title 불일치·FdoSecrets 설정 등 다른 원인 조사 (잠금 해제 요청 금지)

# 4. 조회 테스트 — 빈 결과이면 Title 불일치 (lookup은 못 찾아도 에러 없이 exit 0)
secret-tool lookup Title 'project .env.local' | wc -c

# 5. 전체 항목 제목 나열로 실제 Title 확인 (오타 탐지 / prefix 탐색)
busctl --user call org.freedesktop.secrets /org/freedesktop/secrets/collection/login \
  org.freedesktop.DBus.Properties Get ss org.freedesktop.Secret.Collection Items \
 | grep -oP '/org/freedesktop/secrets/collection/login/[a-f0-9]+' | while read -r item; do
  busctl --user call org.freedesktop.secrets "$item" \
    org.freedesktop.DBus.Properties Get ss org.freedesktop.Secret.Item Label | sed 's/^v s //'
done
#    (zsh는 for x in $VAR로 공백 분리를 하지 않음 → while read 파이프 필수)

# 6. prefix 탐색 — 5번 결과를 접두어로 필터링 (secret_lookup 헬퍼가 이 로직을 자동화함)
# 예: 'myproj'로 시작하는 항목 확인
# (위 busctl while 루프 안에서 if [[ "$label" == "myproj"* ]] 조건 추가)

# 7. 제목 오타 발견 시 D-Bus로 즉시 수정 (금고에 바로 저장됨)
busctl --user set-property org.freedesktop.secrets \
  /org/freedesktop/secrets/collection/login/<항목ID> \
  org.freedesktop.Secret.Item Label s "올바른제목"
```

**⚠️ 진단 시 비밀값 노출 금지**: `secret-tool search --all`이나 Attributes 조회는 Notes·Password 내용을 화면에 출력한다. 항상 `| wc -c`(길이만), Label만 추출 등으로 값 자체를 출력하지 말 것.

---

## 중요 규칙 & 트러블슈팅

### 1. KeePassXC 설정 파일 덮어쓰기 함정 (실제 장애 사례)
- KeePassXC는 **종료 시점에 런타임 설정을 `keepassxc.ini`에 전체 덮어씁니다**.
- 실행 중에 ini를 고치면 종료 시 원복됨 → **반드시 `pkill -x keepassxc`로 완전 종료 후 수정**.
- 이 함정으로 `[FdoSecrets] Enabled=false`가 저장되면, 다음 기동부터 **모든 프로젝트의 secret-tool이 타임아웃** — "어제는 됐는데 오늘은 안 됨"의 대표 원인.

### 2. 팝업 반복 문제 (PID 단위 접근 제어)
- KeePassXC의 접근 승인은 프로세스(PID) 단위 → `secret-tool`은 호출마다 새 PID라 매번 팝업.
- **해결 ①**: `keepassxc.ini` `[FdoSecrets] ConfirmAccessItem=false` (= GUI의 "Confirm when passwords are retrieved by clients" 해제). 백그라운드 프로세스(go-keyring 등)는 팝업을 못 띄우고 `IsLocked` 에러로 즉사하므로 이 옵션 해제가 필수.
- **해결 ②**: `.envrc` 가드 변수로 폴더 진입 시 1회만 조회 (위 표준 패턴).
- 스크립트(Node/Python)는 환경변수를 우선 사용하고, 없을 때만 `secret-tool` 폴백.

### 3. go-keyring 앱 (Antigravity language_server 등) 호환
- go-keyring은 D-Bus 경로 `/org/freedesktop/secrets/collection/login`을 **하드코딩** 참조.
- 대응 (본 환경은 둘 다 적용): ① 금고 파일명을 `login.kdbx`로 유지 ② autostart 스크립트 `keepass-fdosecrets-alias.sh`가 default 컬렉션에 `login` alias를 자동 설정.

### 4. Electron 앱 키링 팝업
- Electron 앱이 세션 암호화 키 저장을 위해 키링 접근 시도 → 단순 툴은 `--password-store=basic` 플래그로 우회 가능 (예: `antigravity --no-sandbox --password-store=basic`).
- 단, VS Code 등 주력 IDE에는 금지 — 확장 로그인 세션이 유실됨.

### 5. gnome-keyring의 D-Bus 선점 탈환
```bash
pkill -f gnome-keyring-daemon
pkill -x keepassxc
keepassxc ~/dotfiles/login.kdbx >/dev/null 2>&1 &
# → 마스터 암호 입력으로 금고 오픈
```

### 6. 새 항목 추가 후 검색 안 됨
- FdoSecrets가 금고 오픈 시 항목을 캐싱 → **Database > Lock (Ctrl+L) 후 재잠금해제**.

---

## direnv 스코프 이해 (중요)

- `.envrc`로 주입된 변수는 **해당 프로젝트 폴더(및 하위) 안의 셸에서만** 보인다. 폴더를 벗어나면 direnv가 자동 언로드.
- 반면 `secret-tool lookup` 자체는 **어느 디렉터리에서든** 동일하게 동작한다 (D-Bus 전역 서비스).
- 따라서 "다른 폴더에서 변수가 안 보임"은 정상 동작이고, "해당 폴더에서도 안 보임"이 장애다.

---

## .env → Keyring 마이그레이션 체크리스트

```
[ ] 1. 기존 .env 파일 내용 확인, 비민감·머신별 값은 .env.development로 분리
[ ] 2. KeePassXC에 항목 생성: Title='프로젝트명.env.환경' (고유하게, 오타 주의),
       Password 필드에 .env 내용 전체 붙여넣기
[ ] 3. Ctrl+L로 금고 재잠금해제 (FdoSecrets 캐시 갱신)
[ ] 4. secret-tool lookup Title '...' | wc -c 로 조회 확인 (0이면 Title 재확인)
[ ] 5. .envrc를 표준 패턴(secret_lookup 헬퍼 포함)으로 작성 → direnv allow
[ ] 6. direnv exec . sh -c 'echo ${KEY:+set}' 로 주입 검증 (값 출력 금지)
[ ] 7. 평문 .env 파일 삭제
```

---

## 축적된 교훈

- `secret-tool lookup`은 못 찾아도 **에러 없이 빈 출력** (무음 실패) → `.envrc`에서 반드시 `-n` 검사
- 항목 제목 오타 실제 사례: `brain..env.production` (점 2개) → 조회 코드와 한 글자 차이로 장기간 실패
- `Path` 속성은 커스텀 등록 없이 자동 노출됨 (`/그룹/제목`) — "Path는 등록해야 동작한다"는 오답
- KeePassXC ini는 종료 시 덮어쓰기 → 실행 중 수정 금지
- zsh에서 `for x in $VAR`는 공백 분리 안 함 → 스크립트에서 `while read` 사용
- `gh auth login` 토큰은 `hosts.yml` 저장, 세션 만료 시 재인증 필요 → `.envrc`에서 `gh auth token`으로 캐시
- gnome-keyring과 KeePassXC 동시 실행 시 FdoSecrets=false면 독립 동작 → 중복 저장 위험
- AI가 `secret-tool store`를 제안하기 전에 KeePassXC 동일 항목 존재 여부 먼저 확인
- **DB Connection URI 따옴표**: URI는 이미 URL 인코딩되므로 KeePassXC에 따옴표 없이 저장 권장. 사용자 오입력/복붙 차이에 대비해 Shell, Runtime, CLI 3계층에서 따옴표를 자동 정제하는 심층 방어(Defense in Depth) 구축 필수
- **`secret_lookup` 헬퍼 사용 권장**: exact match(`secret-tool lookup`) 단독 의존 시 Title 한 글자 차이로 무음 실패. `secret_lookup` 헬퍼를 `.envrc`에 항상 정의하고 사용하면 prefix fallback으로 안정성이 크게 향상됨
- **KeePassXC 한글 UI 메뉴 공식 명칭**: 영문 `Merge into database...`의 한글 공식 명칭은 "다른 데이터베이스와 병합"이 아니라 **`데이터베이스(D) → 데이터베이스에서 합치기(M)...`**이다. 직역 안내로 인한 사용자 혼선 절대 금지.
- **KeePassXC 병합 화면 충돌 판독 기준**:
  - `Password, History`: 실제 패스워드 값이 변경된 진짜 충돌/수정 대상.
  - `History (Add new modifications to existing entry)`: 접근/수정 시간 메타데이터만 갱신된 것이므로 실제 데이터 유실 우려 없음.
- **GitHub 원격 저장소 프로토콜 우선순위 (SSH vs HTTPS/PAT)**:
  - KeePassXC의 `GITHUB_TOKEN`은 `gh` CLI 명령(이슈, PR, API 조회 등)용으로 완벽하게 동작하지만, git push/pull 시에는 HTTPS PAT의 `workflow` 스코프 누락으로 인해 `.github/workflows/` 파일 푸시가 거부될 수 있음.
  - 따라서 로컬 git 레포의 `origin`은 항상 **SSH (`git@github.com:조직/레포.git`)** 방식을 우선 사용하는 것이 표준이다.
  - `gh repo create` 사용 시 기본 등록되는 HTTPS 대신 즉시 SSH URL로 전환하거나, `git remote set-url origin git@github.com:...`을 적용한다.


