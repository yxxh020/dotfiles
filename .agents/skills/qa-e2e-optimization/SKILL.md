---
name: qa-e2e-optimization
description: >
  Playwright E2E 테스트 성능 최적화, 스크린샷 오버레이 가림 방지, 타겟 중심 캡처 및 Next.js SSR webpack/jsdom 환경 에러 트러블슈팅 가이드라인 스킬.
---

> **[안내]** 이 파일은 각 프로젝트가 복사해갈 때 프로젝트 상황에 맞게 수정하여 사용하는 템플릿이다.

# E2E 테스트 성능 & 호환성 최적화 가이드

빠르고, 안정적이며, 견고한 Playwright E2E 테스트를 작성하기 위한 표준 가이드라인과 트러블슈팅 절차를 제공한다. 테스트 행(hang), 빈 DB에서의 자동 대기 타임아웃 감소, SSR 특화 파일시스템 매핑 에러 해결 및 시각적 스크린샷 노이즈 방지 방법을 다룹니다.

---

## 1. 빈 데이터베이스에서 조기 감지 & 스킵

Playwright는 불안정성 해소를 위해 **Auto-Waiting**을 사용한다. 빈 상태에서 셀렉터(예: `locator('table tbody tr').first()`)나 값 추출(예: `innerText()`)을 검사 없이 실행하면, Playwright는 기본 타임아웃(보통 30초)까지 요소가 나타나기를 기다립니다.

### 모범 사례 (즉시 스킵)

컬럼 특정 assertion을 시도하기 전에 먼저 목록이 비어있는지 확인한다.

```typescript
const firstRow = page.locator('table tbody tr').first();
await expect(firstRow).toBeVisible({ timeout: 20_000 });

// 1. 빈 결과 플레이스홀더를 즉시 확인
const noResults = page.getByText('데이터가 없다.');
if (await noResults.isVisible()) {
  test.skip('데이터 없음, 테스트 스킵');
  return;
}

// 2. 특정 인덱스를 타겟팅하기 전에 최소 셀 수 확인
const cellCount = await firstRow.locator('td').count();
if (cellCount < 5) {
  test.skip('유효한 컬럼 없음, 테스트 스킵');
  return;
}
```

---

## 2. SSR 환경 에러 트러블슈팅 (예: `isomorphic-dompurify` + `jsdom`)

### 문제 상황

Next.js 서버 사이드 렌더링(SSR) 중에 브라우저 DOM을 에뮬레이션하려는 라이브러리가 정적 레이아웃 에셋 해석에 실패하여 `ENOENT` 에러가 발생할 수 있다.

### 해결 방법

1. **인프라 우회 (빠른 로컬 수정)**: 로컬 개발/E2E 테스트 실행 중 `open` 호출을 만족시키기 위해 대상 경로에 더미 파일을 생성한다.
   ```bash
   mkdir -p <project-root>/.next/browser
   touch <project-root>/.next/browser/default-stylesheet.css
   ```
2. **코드 격리 (권장 리팩터링)**: 브라우저 전용 패키지를 서버 사이드 렌더링 시 실행되지 않도록 `typeof window !== 'undefined'`로 방어 코드를 작성한다.

---

## 3. 스크린샷 내 오버레이/위젯 가림 현상 방지

E2E 시각적 검증 과정에서 피드백 수집기, 챗봇, 알림 모달 등의 외부 위젯이 동적으로 타겟 요소를 덮어씌워 스크린샷 상의 중요 검증 영역을 가리는 문제를 해결하는 3가지 기법이다.

### 1. CSS Injection (CSS 주입을 통한 강제 숨김)
```typescript
await page.addStyleTag({
  content: '.bug-report-widget, #marker-widget-root, [class*="feedback-widget"] { display: none !important; }'
});
```

### 2. Aborting Network Requests (외부 네트워크 요청 차단)
```typescript
await page.route('**/*widget-domain*', route => route.abort());
```

### 3. Absolute DOM Element Removal (DOM 엘리먼트 강제 제거)
```typescript
await page.evaluate(() => {
  const widget = document.getElementById('widget-root');
  if (widget) widget.remove();
});
```

---

## 4. 타겟 요소 중심 스크린샷 (Target-Focused Screenshots)

전체 페이지 스크린샷(`fullPage: true`)을 무분별하게 사용하면 개발 인디케이터나 플로팅 배지 등 불필요한 UI 노이즈가 포함됩니다. 특정 요소(Locator)에 집중하여 스크린샷을 촬영해라.

```typescript
// 모범 사례: 타겟 요소 지정 및 뷰포트 스크롤 후 캡처
const targetComponent = page.locator('.target-widget-container');
await targetComponent.scrollIntoViewIfNeeded();
await expect(targetComponent).toBeVisible();
await targetComponent.screenshot({ path: 'target-component.png' });
```

---

## 5. 테스트 성능 모범 사례

- **스토리지 상태 재사용**: 사용자 로그인 쿠키/토큰을 임시 파일(예: `.auth/admin.json`)에 캐시하여 테스트 케이스 간 공유한다.
- **프로덕션 빌드 테스트**: 개발 모드(`npm run dev`) 대신 프로덕션 빌드(`npm run build && npm start`)로 E2E 테스트를 실행하여 Lazy Compilation 병목을 피한다.
- **단일 워커 직렬 실행**: 동시 API 요청이 레이트 리미터를 트리거하는 경우 워커를 제한합니다(`--workers=1`).
