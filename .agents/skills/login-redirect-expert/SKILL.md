---
name: login-redirect-expert
description: 로그인 성공 후 이전에 보던 페이지로 복귀하는 기능을 구현·유지보수하는 Next.js App Router 전문가 스킬. redirect 파라미터 주입, 보안 검증, 특수 케이스 오버라이드를 다룬다.
---

> **[안내]** 이 파일은 각 프로젝트가 복사해갈 때 프로젝트 상황에 맞게 수정하여 사용하는 템플릿이다.
> 적용 시 이 안내 문구를 제거하고 프로젝트에 맞게 내용을 수정한다.

# login-redirect-expert Skill

로그인 성공 후 이전에 보던 페이지로 복귀하는 기능을 구현·유지보수하는 전문가 스킬.
Next.js App Router 환경의 `?redirect=` 파라미터 흐름 전체를 다룬다.

## 사용 시점

- "로그인 하면 랜딩 페이지로 가지 말고 이전 페이지로 돌려줘"
- "세션 만료 후 다시 로그인하면 원래 보던 페이지로 가야 해"
- "특정 페이지에서 로그인 버튼을 눌렀을 때 `?redirect=` 가 전달되지 않아"
- "`?redirect=` 파라미터가 외부 URL을 허용하는 보안 취약점이 있어"
- "특정 페이지에서 로그인하면 다른 페이지로 보내줘" 같은 특수 케이스

---

## 아키텍처 개요

```
[사용자가 로그인 진입점 클릭]
        │
        ▼
  ?redirect=encodeURIComponent(pathname)  ← 진입점에서 주입
        │
        ▼
  /<locale>/login?redirect=...
        │
        ▼
  login/page.tsx  →  getRedirectPath()   ← 복귀 경로 결정
        │
        ├─ 외부 URL? → /<locale> (보안)
        ├─ /admin?   → 어드민 전용 검증
        ├─ 랜딩 페이지? → /<locale>/<default-landing>
        └─ 그 외     → redirectPath 그대로
```

### 핵심 파일 목록

| 파일 | 역할 |
|------|------|
| `<project-root>/src/app/[locale]/(auth)/login/page.tsx` | `getRedirectPath()` — 복귀 경로 최종 결정 로직 |
| `<project-root>/src/components/nav.tsx` | 로그인 Link — `?redirect=` 주입 |
| `<project-root>/src/components/login-modal.tsx` | 로그인 모달 → 로그인 페이지 이동 시 `?redirect=` 주입 |
| `<project-root>/src/store/session-renewal-store.ts` | 세션 만료 로그아웃 시 `?redirect=` 주입 |
| `<project-root>/src/middleware.ts` | 미들웨어 — 보호된 경로 접근 시 `?redirect=` 자동 추가 |

---

## 구현 규칙

### 규칙 1: redirect 파라미터 주입 (로그인 진입점)

모든 "로그인 페이지로 이동" 코드에 다음 패턴을 적용한다.

```typescript
// ✅ 올바른 패턴
import { usePathname } from "next/navigation";

const pathname = usePathname();

// router.push 방식
router.push(`/${locale}/login?redirect=${encodeURIComponent(pathname)}`);

// Link 방식
<Link href={`/${locale}/login?redirect=${encodeURIComponent(pathname)}`}>
  로그인
</Link>

// window.location (훅 외부)
const currentPath = window.location.pathname;
window.location.href = `/${locale}/login?redirect=${encodeURIComponent(currentPath)}`;
```

```typescript
// ❌ 잘못된 패턴 (redirect 없음)
router.push(`/${locale}/login`);
window.location.href = `/${locale}/login`;
```

### 규칙 2: 보안 검증 (login/page.tsx getRedirectPath)

`?redirect=` 파라미터 수신 시 반드시 상대 경로 검증을 수행한다 (오픈 리다이렉트 방어).

```typescript
const isRelativePath =
  redirectPath.startsWith("/") &&
  !redirectPath.startsWith("//") &&
  !redirectPath.startsWith("http://") &&
  !redirectPath.startsWith("https://");

if (!isRelativePath) return `/${locale}`; // 외부 URL → 홈으로 폴백
```

### 규칙 3: 특수 케이스 오버라이드

랜딩 페이지(`/${locale}` 또는 `/`)에서 로그인하면 기본 랜딩 페이지로 보낸다.

```typescript
const isLandingPage = redirectPath === `/${locale}` || redirectPath === "/";
if (isLandingPage && !isAdmin) {
  return `/${locale}/<default-landing>`;
}
```

`redirect` 파라미터가 없는 경우 (직접 `/login` 진입):
- 일반 사용자 → `/${locale}/<default-landing>`
- 어드민 → `/${locale}/admin/dashboard`

### 규칙 4: 어드민 경로 접근 제어

```typescript
if (redirectPath.includes("/admin")) {
  if (isAdmin) return redirectPath;
  return `/${locale}`; // 비어드민은 홈으로
}
```

---

## 에이전트 실행 절차

### 신규 로그인 진입점 추가 시

1. **파일 스캔**: `router.push` / `window.location.href` / `<Link href=` 중 `/login`으로 이동하는 코드 탐색
2. **`usePathname` 추가**: 해당 컴포넌트에 `import { usePathname } from "next/navigation"` 추가
3. **`?redirect=` 주입**: `encodeURIComponent(pathname)` 패턴으로 URL 수정
4. **`login/page.tsx` 확인**: `getRedirectPath()`가 해당 경로를 올바르게 처리하는지 검증
5. **TypeScript 체크**: `npx tsc --noEmit`로 타입 오류 없음 확인

---

## 점검 체크리스트

새 컴포넌트나 페이지에 로그인 유도 코드가 있을 때 다음을 점검한다.

- [ ] `router.push(…/login)` → `?redirect=` 포함 여부
- [ ] `window.location.href = …/login` → `?redirect=` 포함 여부
- [ ] `<Link href="…/login">` → `?redirect=` 포함 여부
- [ ] `getRedirectPath()`에 보안 검증 (`isRelativePath`) 존재 여부
- [ ] 랜딩 페이지 특수 케이스 처리 여부
- [ ] `encodeURIComponent()` 미적용으로 인한 URL 파싱 오류 없음 여부

---

## 하네스 연동

### 단계 0 — 레슨 로드
이 스킬을 사용하는 작업을 시작하기 전에 다음을 읽는다:
- `.agents/learnings/general.md`
- `.agents/learnings/login-redirect-expert.md`

관련 레슨을 먼저 적용한 뒤 진행한다.

### 단계 5 — 레슨 기록
중요한 작업 완료 후, 다음 경우에 해당하면 `.agents/learnings/login-redirect-expert.md`에 레슨을 추가한다:
- `?redirect=`가 누락된 새 로그인 진입점이 발견되었을 때
- 특수 케이스 리다이렉트 규칙이 추가되었을 때
- 오픈 리다이렉트 관련 보안 이슈가 발견되었을 때

> 레슨이 **3회 이상** 반복되면 → `rules-project.md` 또는 프로젝트 규칙 반영 후보로 승격한다.

### ⛔ 혼자 결정하면 안 되는 사항
- 사용자 승인 없이 미인증 사용자의 기본 리다이렉트 목적지 변경
- 사용자 검토 없이 특수 케이스 리다이렉트 오버라이드 추가 또는 수정
- `isRelativePath` 보안 검사 제거
