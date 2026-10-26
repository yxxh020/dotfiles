---
name: ui-screenshot-automation
description: Puppeteer를 활용하여 인증이 필요한 웹 페이지에서 다크 모드 등 특정 상태를 강제한 뒤 대량의 UI 스크린샷을 자동 캡처하여 시각적 일관성을 전수 검사하는 스킬.
---

# UI 스크린샷 자동화 스킬

다수의 페이지에 걸쳐 헤더 디자인, 다크 모드 일관성, 특정 컴포넌트 레이아웃 등 UI의 시각적 정합성을 검증해야 할 때 사용한다. 인증이 필요한 페이지나 로드 타임아웃이 발생하기 쉬운 렌더링 환경에서 신뢰할 수 있는 스크린샷 자동화 방식을 정의한다.

## 1. 목적

- 전체 페이지에 공통으로 적용된 스타일 가이드가 빠짐없이 적용되었는지 확인
- 사람이 일일이 페이지를 방문하지 않고도 스크린샷 결과를 보고할 수 있도록 보조
- 인증 처리(JWT / 로그인)를 우회하여 시각 검사를 수행

## 2. 사용 시기

- "모든 메뉴의 UI를 검증해줘" 또는 "다크 모드가 잘 적용되었는지 전체 스크린샷으로 확인해"와 같은 요청
- 대규모 컴포넌트 교체 후 각 페이지별 레이아웃 붕괴 여부를 확인할 때

## 3. 핵심 자동화 전략

Puppeteer Node.js 스크립트를 작성하여 프로젝트의 `tmp/` 디렉터리에서 실행한다.

### 3.1. 로그인 인증 우회

페이지 접속 전에 `page.evaluateOnNewDocument()`를 활용하여 로컬 스토리지에 인증 플래그를 설정하거나 앱의 렌더링 상태를 조작하여 리다이렉션을 방지한다.

```javascript
await page.evaluateOnNewDocument(() => {
  localStorage.setItem('auth-override', 'true');
});
```

> **프로젝트별 조정 필요**: 인증 우회 방식은 애플리케이션의 인증 구현에 따라 다르다. JWT 토큰 주입, 쿠키 설정, 또는 테스트 전용 엔드포인트 활용 등 프로젝트에 맞게 수정한다.

### 3.2. 상태 및 테마 강제

다크 모드를 검증할 때는 탐색 후 DOM 조작을 통해 클래스를 강제 삽입한다.

```javascript
await page.goto(url, { waitUntil: 'load', timeout: 30000 });
await page.evaluate(() => {
  document.documentElement.classList.add('dark');
  localStorage.setItem('theme', 'dark');
});
```

### 3.3. 대기열 및 선택자 처리

단순 타임아웃 대기 대신, 명시적인 선택자 대기나 Promise 래퍼를 사용한다.

```javascript
try {
  await page.waitForSelector('.target-element', { timeout: 5000 });
} catch(e) {
  // 선택자가 없을 수 있으므로 무시하고 진행
}
await new Promise(r => setTimeout(r, 1000));
```

### 3.4. 스크린샷 저장

스크린샷은 프로젝트의 `tmp/screenshots/` 디렉터리에 저장한다.
특정 요소만 캡처할 때는 `element.screenshot()`을 활용하고, 오류 시에는 전체 페이지 캡처를 남긴다.

```javascript
const outputDir = 'tmp/screenshots';
const slug = url.replace(/[^a-z0-9]/gi, '-');

const targetElement = await page.$('.target-element');
if (targetElement) {
  await targetElement.screenshot({ path: `${outputDir}/element_${slug}.png` });
} else {
  await page.screenshot({ path: `${outputDir}/error_${slug}.png` });
}
```

## 4. 실패 대처

- **ERR_ABORTED / Navigation Timeout**: 탭을 재사용(단일 page 객체)하여 순차적으로 `goto()`를 수행한다.
- **Protocol Error (DOM.resolveNode)**: `waitForSelector` 직후 캡처하거나 대기 로직을 조정한다.
- 스크립트 실행 후 생성된 이미지들을 마크다운으로 모아서 보여주면 완벽한 보고가 된다.
