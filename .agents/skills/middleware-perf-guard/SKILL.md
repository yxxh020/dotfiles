---
name: middleware-perf-guard
description: >
  Next.js 미들웨어에서 불필요한 인증(예: Supabase auth.getUser()) 호출 및
  DB 쿼리로 인한 페이지 지연을 탐지하고 수정하는 성능 가드 스킬.
  공개 페이지가 느리거나 미들웨어 리디렉션 이슈 의심 시 발동한다.
---

# Middleware Performance Guard Skill

## 언제 이 스킬을 발동하는가

- 특정 공개 접근 가능한 페이지가 유독 느리다는 보고를 받았을 때
- "리디렉션 루프" 또는 "페이지 이동 지연" 관련 질문이 있을 때
- `middleware.ts` 수정 작업 시 성능 영향 검토가 필요할 때
- 새 라우트 추가 시 미들웨어 매처/권한 구조 검토 요청 시

---

## ⚡ Step 0: 먼저 TTFB를 측정하라 (가장 중요)

**페이지가 느리다고 바로 미들웨어를 의심하지 마십시오.**  
반드시 curl로 페이지와 API 응답 시간을 분리 측정한 뒤 원인을 파악한다.

```bash
# 페이지 TTFB 측정
for path in "/" "/dashboard" "/profile" "/login"; do
  result=$(curl -s -o /dev/null -w "%{http_code} | TTFB: %{time_starttransfer}s" http://localhost:3000$path)
  echo "  $path → $result"
done

# API 응답시간 측정 (별도로!)
for path in "/api/data" "/api/users"; do
  result=$(curl -s -o /dev/null -w "%{http_code} | TTFB: %{time_starttransfer}s" http://localhost:3000$path)
  echo "  $path → $result"
done
```

### 결과 해석

| 상황 | 원인 | 해결 |
|------|------|------|
| 페이지 TTFB 느림 (200ms+) | 미들웨어의 불필요한 네트워크 왕복 | 원칙 1~3 적용 |
| API TTFB 느림 (1초+) | 외부 서비스 미설정 또는 DB 쿼리 병목 | 원칙 4 적용 |
| 페이지 빠른데 브라우저에서 느림 | 클라이언트 렌더링 또는 fetch 지연 | API TTFB 및 클라이언트 코드 측정 |

---

## 성능 최적화 4원칙 (Next.js + 외부 인증/DB)

### 원칙 1: `/api/*` 는 matcher에서 제외

```ts
// ✅ 올바른 패턴 (Next.js 미들웨어 matcher)
'/((?!api/|_next/static|_next/image|favicon.ico|.*\\.(?:svg|png|jpg|jpeg|gif|webp)$).*)'

// ❌ 잘못된 패턴 (API 호출마다 미들웨어가 매번 실행됨)
'/((?!_next/static|_next/image|favicon.ico|.*\\.(?:svg|png|jpg|jpeg|gif|webp)$).*)'
```
**이유**: 클라이언트에서 `fetch('/api/data')` 등을 호출할 때마다 미들웨어가 개입하면, 각 API 호출마다 무거운 세션 검증 네트워크 왕복이 추가로 발생한다.

---

### 원칙 2: 공개 라우트 early return (인증 왕복 방지)

```ts
// ✅ 올바른 패턴
const isProtected = PROTECTED_ROUTES.some((r) => pathname.startsWith(r));

if (!isProtected) {
  return response; // 인증 세션 네트워크 왕복 없이 즉시 통과
}

// 세션 검증은 반드시 필요한 보호된 라우트에서만 실행
const { data: { user } } = await auth.getUser();
```
**이유**: 세션 검증 API(예: Supabase의 `auth.getUser()`)는 매 호출마다 외부 서버로 네트워크 요청을 보냅니다. 공개 페이지에서 이 왕복이 발생하면 50~200ms 이상의 불필요한 지연이 누적됩니다.

---

### 원칙 3: 추가 DB 쿼리는 특정 역할 라우트에서만 제한적으로

```ts
// ✅ 올바른 패턴
if (isRoleRequiredRoute && user) {
  // DB 쿼리 실행 (필요한 경우에만)
  const profile = await db.selectProfile(user.id);
}

// ❌ 잘못된 패턴 (로그인 사용자가 모든 일반 페이지를 이동할 때마다 DB 조회)
if (user) {
  const profile = await db.selectProfile(user.id); // 버그 수준의 성능 저하 유발
}
```
**이유**: 미들웨어는 엣지 또는 서버리스 환경에서 실행되므로, 매 페이지 요청마다 추가 데이터베이스 쿼리가 수행되면 심각한 병목을 유발한다.

---

### 원칙 4: 로컬/테스트 환경에서 자격증명 미설정 시 즉시 fallback

**자격증명(예: API Key, DB URL)이 플레이스홀더 상태일 때, 외부 네트워크 타임아웃으로 인한 지연(수 초)을 방지해야 한다.**

```ts
// ✅ API 클라이언트 팩토리 패턴 예시
export function isCredentialsConfigured(): boolean {
  const url = process.env.API_URL ?? '';
  return url !== '' && !url.includes('placeholder') && url.startsWith('https://');
}

export async function createClient() {
  if (!isCredentialsConfigured()) {
    throw new Error('NOT_CONFIGURED'); // 즉시 throw → 타임아웃 방지
  }
  // 정상 클라이언트 초기화...
}

// ✅ API GET 핸들러 패턴 (Mock fallback 적용)
export async function GET(request: NextRequest) {
  try {
    const client = await createClient();
    const data = await client.getData();
    return NextResponse.json({ data });
  } catch (err) {
    // 설정 오류 시 즉시 빈 데이터 또는 Mock 반환
    return NextResponse.json({ data: [] });
  }
}
```

---

## 진단 체크리스트

페이지 성능 지연 신고 시 반드시 다음 체크리스트를 순서대로 수행합니다:

```bash
# Step 1: 페이지 vs API TTFB 분리 측정
curl -s -o /dev/null -w "페이지: %{time_starttransfer}s\n" http://localhost:3000/dashboard
curl -s -o /dev/null -w "API:    %{time_starttransfer}s\n" http://localhost:3000/api/data

# Step 2: API가 느리면 환경변수 유효성 확인
grep "API_URL" .env.local

# Step 3: 페이지가 느리면 미들웨어 구현부 확인
grep -n "matcher" middleware.ts
grep -n "isProtected" middleware.ts
```

---

## 수정 후 검증 절차

```bash
# 1. 빌드 성공 여부 확인
npm run build   # 또는 pnpm run build

# 2. TTFB 재측정을 통한 성능 향상 확인
curl -s -o /dev/null -w "TTFB: %{time_starttransfer}s\n" http://localhost:3000/dashboard
# 기대값: 페이지 < 200ms, API(공개) < 50ms

# 3. 권한/인증 가드 동작 확인
# 세션이 없는 상태에서 /protected 경로 접속 시 /login 리디렉션 확인
```
