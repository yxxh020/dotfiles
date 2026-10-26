---
name: telegram-bug-report-bot
description: >
  텔레그램 버그 제보 봇(bug_report_wonhyukc_bot)을 새 프로젝트에 연결한다.
  KeePassXC 항목 등록, 환경변수 설정, telegram.ts 라이브러리 이식, API 라우트 연동까지
  전체 연결 절차를 단계별로 수행한다.
  트리거: "버그 제보 봇 연결", "텔레그램 알림 연결", "bug report bot", "telegram bot 이식"
---

# 텔레그램 버그 제보 봇 연결 스킬 (telegram-bug-report-bot)

이 스킬은 **`bug_report_wonhyukc_bot`** 텔레그램 봇을 새 Next.js 프로젝트에 연결하는 전체 절차를 규정한다.
봇은 이미 생성·운영 중이므로, 새 레포에서는 **연결만** 하면 된다.

---

## 전제 조건 확인

작업 전 아래를 먼저 확인한다.

```bash
# KeePass 항목이 이미 등록되어 있는지 확인
secret-tool search Title 'bug-report-bot.telegram' 2>/dev/null
```

- 출력에 `TELEGRAM_API=` 줄이 나오면 → **Step 1 생략**, Step 2부터 진행
- 아무것도 나오지 않으면 → Step 1부터 순서대로 진행

---

## Step 1. KeePassXC에 봇 정보 등록

> [!IMPORTANT]
> 이 항목은 **머신 1회만** 등록한다. 이미 등록된 경우 절대 중복 등록하지 않는다.

### 1-1. KeePassXC GUI에서 항목 생성

KeePassXC를 열고 아래 정보로 항목을 추가한다.

| 필드 | 값 |
|------|-----|
| **Title** | `bug-report-bot.telegram` |
| **Username** | `bug_report_wonhyukc_bot` |
| **Password** | (봇 토큰 — 보안상 직접 확인) |
| **Notes** | 아래 형식으로 추가 속성 기입 |

**Notes 내용** (secret-tool 조회 시 파싱되는 값):
```
TELEGRAM_BOT=bug_report_wonhyukc_bot
TELEGRAM_API=<봇 토큰 전체>
TELEGRAM_CHAT_ID=299448597
```

### 1-2. Secret Service에 등록 (CLI 방식)

KeePassXC가 Secret Service 통합을 활성화했다면 아래 명령으로 등록 가능하다.

```bash
# 주의: 실제 토큰은 마스킹하여 노출하지 말 것 — KeePassXC GUI에서 직접 입력 권장
secret-tool store \
  --label="bug-report-bot.telegram" \
  Title "bug-report-bot.telegram"
# 프롬프트가 나오면 Notes 내용을 그대로 붙여넣기
```

### 1-3. 등록 검증

```bash
secret-tool lookup Title 'bug-report-bot.telegram'
# 출력 예시:
# TELEGRAM_BOT=bug_report_wonhyukc_bot
# TELEGRAM_API=8633324535:AAEW*** (마스킹)
# TELEGRAM_CHAT_ID=299448597
```

---

## Step 2. 라이브러리 파일 이식

### 2-1. `src/lib/telegram.ts` 복사

`next-coach-2610` 레포의 [`src/lib/telegram.ts`](file:///home/hyuk/prj/next-coach-2610/src/lib/telegram.ts)를 새 레포의 동일 경로에 복사한다.

```bash
cp /home/hyuk/prj/next-coach-2610/src/lib/telegram.ts ./src/lib/telegram.ts
```

이 파일이 제공하는 주요 함수:

| 함수 | 역할 |
|------|------|
| `sendBugReportTelegramNotification(report)` | 텔레그램으로 버그 제보 알림 발송 |
| `formatBugReportTelegramMessage(report)` | HTML 형식 메시지 본문 생성 |
| `escapeHtml(str)` | 텔레그램 HTML 모드용 특수문자 이스케이프 |

> [!NOTE]
> 이 파일은 외부 패키지 의존성 없이 Node.js 내장 `child_process`만 사용한다.
> `node:child_process`가 `import` 되어 있으므로 Edge Runtime에서는 사용 불가 — **Node.js Runtime API Route에서만 호출**할 것.

### 2-2. `BugReportNotificationPayload` 타입

```typescript
export interface BugReportNotificationPayload {
  id?: string;
  title: string;
  description: string;
  category?: "BUG" | "IMPROVEMENT" | string;
  priority?: "HIGH" | "MEDIUM" | "LOW" | string;
  reporter?: string;
  role?: string;
  device?: string;
  url?: string;
  created_at?: string;
}
```

---

## Step 3. 환경변수 설정

### 로컬 개발 환경

KeePassXC Secret Service를 통해 **자동 조회**되므로 `.env.local`에 별도 설정 불필요.

### 운영(배포) 환경

Vercel / Docker / 서버 환경변수에 아래를 추가한다.

```bash
# 필수
TELEGRAM_BOT_TOKEN=<봇 토큰>

# 선택 (미설정 시 기본값 299448597 사용)
TELEGRAM_CHAT_ID=299448597

# 관리자 버튼 링크 생성용
NEXT_PUBLIC_APP_URL=https://your-app-domain.com
```

> [!TIP]
> `TELEGRAM_BOT_TOKEN` 또는 `TELEGRAM_API` 환경변수 중 하나만 있으면 동작한다.
> KeePass → 환경변수 순으로 우선순위가 적용된다.

---

## Step 4. API Route에서 알림 호출

버그 제보 POST 처리 후 아래 패턴으로 알림을 발송한다.

```typescript
// src/app/api/bug-reports/route.ts (또는 유사 경로)
import { sendBugReportTelegramNotification } from "@/lib/telegram";

// DB 저장 성공 후 알림 발송 (실패해도 저장은 유지)
try {
  await sendBugReportTelegramNotification({
    id: String(created.id),
    title: created.title,
    description: created.description,
    category: created.category ?? "BUG",
    priority: created.priority,
    reporter: created.reporter,
    role: created.role,
    device: created.device,
    url: created.url ?? undefined,
    created_at: created.createdAt.toISOString(),
  });
} catch {
  // 알림 실패는 무시 — DB 저장 성공이 우선
}
```

> [!IMPORTANT]
> `try/catch`로 반드시 감싼다. 텔레그램 API 실패가 버그 제보 저장까지 롤백시켜선 안 된다.

---

## Step 5. 연결 테스트

### 5-1. 로컬에서 직접 테스트

```bash
# 프로젝트 루트에서 실행 (ts-node 또는 tsx 필요)
npx tsx -e "
import { sendBugReportTelegramNotification } from './src/lib/telegram';
sendBugReportTelegramNotification({
  title: '[테스트] 연결 확인',
  description: '새 레포에서 텔레그램 버그 제보 봇 연결 테스트입니다.',
  category: 'BUG',
  priority: 'LOW',
  reporter: '개발자',
}).then(console.log);
"
```

### 5-2. 기대 결과

- 텔레그램 `bug_report_wonhyukc_bot` 채팅창에 메시지 수신
- 메시지 하단에 **📄 관리자 버그 목록 확인** 버튼 표시
- 반환값: `{ success: true, messageId: <숫자> }`

### 5-3. 실패 시 체크리스트

```bash
# 1. KeePass 항목 확인
secret-tool lookup Title 'bug-report-bot.telegram'

# 2. 환경변수 확인 (운영)
echo "TOKEN: ${TELEGRAM_BOT_TOKEN:0:10}***"
echo "CHAT_ID: $TELEGRAM_CHAT_ID"

# 3. 텔레그램 API 직접 확인
curl -s "https://api.telegram.org/bot<토큰>/getMe" | jq .ok
```

---

## 봇 정보 요약

| 항목 | 값 |
|------|-----|
| **봇 이름** | `bug_report_wonhyukc_bot` |
| **기본 수신자** | wonhyukc 님 개인 DM |
| **기본 Chat ID** | `299448597` |
| **KeePass 항목명** | `bug-report-bot.telegram` |
| **KeePass 조회 키** | `Title` = `bug-report-bot.telegram` |
| **원본 구현 레포** | `next-coach-2610` |

---

## 범용 알림 발송 (Bug Report 외 용도)

이 봇은 버그 제보 외에도 **범용 1:1 알림 채널**로 재활용할 수 있다.
별도 봇을 새로 만들지 않고, 아래 curl 패턴으로 임의의 텍스트 알림을 발송한다.

```bash
BOT_TOKEN=$(secret-tool lookup Title 'bug-report-bot.telegram' | grep 'TELEGRAM_API=' | cut -d= -f2)
CHAT_ID="299448597"

curl -sf -X POST \
  "https://api.telegram.org/bot${BOT_TOKEN}/sendMessage" \
  -H "Content-Type: application/json" \
  -d "$(jq -n \
    --arg chat_id "$CHAT_ID" \
    --arg text "알림 메시지 본문" \
    '{chat_id: $chat_id, text: $text, parse_mode: "HTML"}')"
```

**활용 사례**: GitHub Actions cron 알림, 배포 리마인더, 장시간 작업 완료 알림 등.

---

## 레퍼런스 파일

| 파일 | 설명 |
|------|------|
| [`src/lib/telegram.ts`](file:///home/hyuk/prj/next-coach-2610/src/lib/telegram.ts) | 핵심 텔레그램 전송 라이브러리 |
| [`src/app/api/bug-reports/route.ts`](file:///home/hyuk/prj/next-coach-2610/src/app/api/bug-reports/route.ts) | API Route 연동 예시 |
| [`src/components/modals/bug-report-modal.tsx`](file:///home/hyuk/prj/next-coach-2610/src/components/modals/bug-report-modal.tsx) | 프론트엔드 제보 모달 UI |

