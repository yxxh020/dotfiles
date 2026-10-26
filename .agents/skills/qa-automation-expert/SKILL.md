---
name: qa-automation-expert
description: >
  Playwright를 사용하여 TDD/BDD 방법론 기반으로 E2E 및 통합 테스트를 작성하고, 모든 테스트가 통과할 때까지 피드백 루프를 반복하는 QA 자동화 전문가 스킬.
  오버레이/위젯 가림 회피 및 타겟 요소 중심 스크린샷 캡처 규정을 포함한다.
---

> **[안내]** 이 파일은 각 프로젝트가 복사해갈 때 프로젝트 상황에 맞게 수정하여 사용하는 템플릿이다.

# QA 자동화 전문가 스킬

프로젝트의 QA 명세 문서(예: `TEST.md`, `qa-spec.md`)와 테스트 디렉터리(예: `qa-automation/`, `e2e/`) 기반으로 테스트 코드를 작성하고, 모든 테스트가 완벽하게 통과할 때까지 피드백 루프를 반복하는 스킬이다.

## 1. 역할과 전문성

Playwright 테스트 프레임워크와 TDD/BDD 방법론에 숙달된 시니어 QA 엔지니어 역할을 수행한다.
주어진 테스트 케이스를 분석하여 견고한 E2E 또는 통합 테스트를 작성해야 한다.

## 2. 표준 & 루프 시스템

### 참조 문서
- 프로젝트의 QA 명세 문서(예: `TEST.md`)와 테스트 디렉터리 내 서브 문서를 기반으로 작업한다.
- 테스트 설계서에 명시된 모든 엣지 케이스를 빠짐없이 커버한다.

### 자동 루프 수정 (Auto-Loop Rectification)
테스트 코드를 생성한 후 터미널에서 직접 테스트를 실행하고, 에러가 발생하면 원인을 파악하여 소스/테스트 코드를 수정하는 루프를 **"모두 통과(All Pass)"**할 때까지 반복한다.

## 3. 운영 지침

테스트 코드를 추가하거나 생성할 때 다음을 반드시 수행합니다:

1. 환경 의존 설정(예: `playwright.config.ts`)과 타겟 URL(스테이징 또는 localhost)을 확인한다.
2. 취약한 XPath 셀렉터 대신 `data-testid` 또는 resilient 셀렉터를 사용한다.
3. 테스트 로직을 깔끔하고 유지보수 가능하게 유지하며, 명세된 엣지 케이스 요구사항과 일치시킵니다.
4. UI 관련 테스트 실패 또는 증거 제출 시 반드시 스크린샷을 캡처한다.
5. **오버레이/위젯 가림 방지**: 스크린샷 촬영 시 검증 영역이 피드백 위젯이나 오버레이에 가려지지 않도록 CSS 주입, 네트워크 차단, DOM 노드 제거 기법을 적용한다.
6. **타겟 요소 중심 캡처**: 전체 페이지 캡처(`fullPage: true`) 대신 타겟 컴포넌트중심의 로케이터 캡처(`locator.screenshot()`)를 사용하여 노이즈를 제거한다.

## 3.5 Playwright OOM 방지 및 실행 규칙

### 규칙 1: E2E는 반드시 production 서버로 실행

> **실전 사례**: Next.js 16 Turbopack dev 서버가 Rust 네이티브 메모리로 **VM 35GB**를 할당하여 30GB RAM 시스템 전체를 OOM kill시킴.
> `NODE_OPTIONS --max-old-space-size`는 V8 힙만 제한하고 **Turbopack(Rust)에는 무효**.

| 서버 | 메모리 | E2E 적합성 |
|------|--------|-----------|
| `pnpm dev` (Turbopack) | **35GB VM** 🔴 | ❌ OOM 위험 |
| `pnpm start` (production) | **~200MB** | ✅ 안전 |

```typescript
// ❌ 절대 금지 — dev 서버로 E2E 실행
webServer: {
  command: 'pnpm run dev',  // Turbopack → OOM
}

// ✅ 필수 — production 빌드 후 실행
webServer: {
  command: 'pnpm start',    // 정적 서빙 → ~200MB
}
```

E2E 실행 전 반드시 `pnpm build`를 수행한다.

### 규칙 2: `npx` 대신 `pnpm exec` 사용

> **실전 사례**: `npx playwright test` 실행 시 시스템 글로벌 playwright가 잡혀서 프로젝트 내 `@playwright/test`와 버전 충돌 → `test.describe() not expected here` 에러 발생.

```bash
# ❌ 금지 — 글로벌 playwright가 잡혀 버전 충돌
npx playwright test

# ✅ 필수 — 프로젝트 내 패키지만 사용
pnpm exec playwright test --reporter=line
```

### 규칙 3: 환경변수 주입 (direnv/KeePass 프로젝트)

Playwright의 webServer 자식 프로세스는 direnv/KeePassXC 환경을 자동 상속받지 못한다.

```typescript
webServer: {
  // direnv로 DATABASE_URL 등을 주입
  command: 'eval "$(direnv export bash 2>/dev/null)" && pnpm start',
}
```

### 규칙 4: workers 제한

| 설정 | 권장값 | 이유 |
|------|--------|------|
| `fullyParallel` | `false` | 파일 내 테스트 순차 실행 |
| `workers` | `1` | Chromium 1개만 동시 실행 |
| 모바일 프로젝트 | `grep: /@mobile/` | 기본 실행에서 제외 |

### ✅ 최종 안전 템플릿

```typescript
import { defineConfig, devices } from '@playwright/test';

export default defineConfig({
  testDir: './tests',
  fullyParallel: false,
  workers: 1,
  reporter: process.env.CI ? 'github' : 'html',
  use: {
    baseURL: 'http://localhost:3000',
    trace: 'on-first-retry',
  },
  projects: [
    { name: 'chromium', use: { ...devices['Desktop Chrome'] } },
    { name: 'Mobile Chrome', use: { ...devices['Pixel 5'] }, grep: /@mobile/ },
  ],
  webServer: {
    command: 'eval "$(direnv export bash 2>/dev/null)" && pnpm start',
    url: 'http://localhost:3000',
    reuseExistingServer: !process.env.CI,
    timeout: 30 * 1000,
    stdout: 'pipe',
    stderr: 'pipe',
  },
});
```

### E2E 실행 커맨드

```bash
cd frontend
eval "$(direnv export bash 2>/dev/null)"
NODE_ENV=production pnpm build
pnpm exec playwright test --reporter=line 2>&1 | tee ../tmp/e2e-result.txt
```

> `/tmp`는 재부팅 시 삭제되므로 프로젝트의 `tmp/` 폴더에 로그를 보존한다.

---

## 4. 테스트 작성 원칙

```typescript
// ✅ 좋은 예: data-testid 기반 셀렉터
const loginButton = page.getByTestId('login-submit-btn');

// ❌ 나쁜 예: 취약한 XPath
const loginButton = page.locator('//button[contains(@class, "btn-primary")]');
```

```typescript
// ✅ 좋은 예: 빈 데이터 조기 스킵 및 타임아웃 예방
const firstRow = page.locator('table tbody tr').first();
await expect(firstRow).toBeVisible({ timeout: 20_000 });
const noResults = page.getByText('데이터가 없다.');
if (await noResults.isVisible()) {
  test.skip('데이터 없음, 테스트 스킵');
  return;
}
```

```typescript
// ✅ 좋은 예: 요소 중심 캡처 및 뷰포트 스크롤
const targetComponent = page.locator('.target-widget-container');
await targetComponent.scrollIntoViewIfNeeded();
await expect(targetComponent).toBeVisible();
await targetComponent.screenshot({ path: 'target-test.png' });
```

---

## ⛔ 단독 결정 금지

- 여전히 실패하는 테스트가 있는데 테스트 스위트를 통과로 표시
- 기존 Playwright 테스트 무단 삭제
- UI 관련 테스트 실패 시 스크린샷 캡처 생략
- 위젯/오버레이에 검증 타겟이 가려진 스크린샷을 방치
