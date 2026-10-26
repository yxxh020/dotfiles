---
name: bug-report-sync-expert
description: 로컬(local), 테스트(test), 운영(prod) 환경의 버그 제보(bug_reports) 데이터를 통합 관리 및 동기화하고, 프론트엔드 캡처 모달의 동작 검증 및 뼈대 수정을 담당하는 스킬이다.
---

# Bug Report Sync Expert Skill

이 스킬은 **버그 제보 시스템(BugReportModal 및 /api/bug-report)**의 설계 정합성을 모니터링하고, 여러 환경 간의 버그 제보 레코드 정합성을 유지하기 위한 에이전트 행동 지침이다.

---

## 1. 프론트엔드 버그 캡처 핵심 규칙 (Frontend Capture Rules)

- **구현 컴포넌트**: `src/components/bug-report-modal.tsx`
- **백엔드 API**: `src/app/api/bug-report/route.ts`
- **헤더 진입점**: `src/components/layout/header.tsx` (Bug 아이콘 → 검색 버튼 좌측)

버그 제보 모달이나 캡처 방식을 수정/보완할 때 반드시 아래 규칙을 준수해야 합니다:

### 규칙 1 — 스크린샷 기본 자동 캡처 (Default Auto-Capture)
- **체크박스 기본값**: `includeScreenshot` 체크박스는 **기본 ON(체크 상태)** 이어야 한다.
- **자동 캡처**: 모달이 열리는 즉시(약 400ms 딜레이 후) `html-to-image`를 사용하여 현재 화면을 자동으로 캡처한다.
- **체크 해제 옵션**: 사용자가 체크를 해제하면 캡처된 스크린샷을 즉시 제거하고, 텍스트 내용만 전송한다.
- **다시 캡처**: 캡처 완료 후에도 "다시 캡처" 버튼으로 재캡처가 가능해야 한다.

### 규칙 2 — 캡처 실패 시 안내 메시지 (Failure Guidance)
- **즉시 안내**: 캡처 실패 시 "화면 캡처 첨부 체크를 해제한 후 제출해 주세요" 에러 메시지를 표시한다.
- **반복 실패 안내**: 제출이 2회 이상 연속 실패하면 상세 가이드를 표시합니다:
  1. 체크박스 해제 후 텍스트만 전송 시도 안내
  2. 그래도 실패 시 F12 콘솔 탭 캡처 → 담당자 전달 안내
- **실패 카운트**: `submitFailureCount` 상태로 관리하며, 성공 시 초기화한다.

### 규칙 3 — 스크린샷 캡처 시 제외 요소 (Capture Filter)
- **이유**: `html-to-image`를 통해 화면(body)을 캡처할 때, 버그 제보 모달 UI가 그대로 캡처되면 실제 에러가 발생한 화면을 가리게 됩니다.
- **필터 대상**:
  1. `data-radix-portal` 속성을 가진 Radix UI Portal 레이어 전체
  2. 모달 자체 (`#bug-report-modal-overlay`, `#bug-report-modal-content`, `modalRef`)
  3. 토스트 레이아웃 `#hot-toast-container`
  4. `iframe` 요소 (유튜브 등 CORS 보안 오류 방지)
  5. 외부 도메인 이미지 (`src`가 `http`로 시작하면서 현재 호스트와 다른 경우)

### 규칙 4 — 발생 위치 URL 필드 (URL Field)
- **자동 입력**: 모달이 열리는 시점에 `window.location.href` 값을 URL 필드에 자동 주입한다.
- **수정 가능**: 사용자가 URL을 수동으로 변경할 수 있도록 input 필드로 제공한다.
- **절대 경로**: 단순 경로명이 아닌 절대 경로 URL을 사용하여 환경(local/test/prod)을 식별한다.
- **안내 텍스트**: 필드 하단에 "현재 브라우저의 URL이 자동으로 입력되었다." 안내를 표시한다.

### 규칙 5 — 환경 정보 자동 수집 및 표시 (Environment Info)
- **자동 수집**: `navigator.userAgent`를 모달 마운트 시 자동 획득한다.
- **파싱 표시**: UserAgent 문자열을 파싱하여 **브라우저**(Chrome/Edge/Firefox/Safari + 버전)와 **운영체제**(Windows/macOS/Linux/Android/iOS + 버전)를 사람이 읽기 쉬운 형태로 UI에 표시한다.
- **읽기 전용 영역**: "환경 정보 (자동 수집)" 라벨과 함께 2칸 그리드로 브라우저/OS를 표시한다.
- **백엔드 전송**: 원본 `userAgent` 문자열도 함께 API로 전송하여 상세 디버깅에 활용한다.

### 규칙 6 — 간편 제출 UX (Minimal Submission)
- **상세 내용은 선택**: 라벨에 `(선택)` 표기를 명시한다.
- **placeholder 안내**: 상세 내용 textarea의 placeholder에 "제목만 적어도 충분합니다. URL과 화면 캡처가 자동으로 첨부되어 오류를 쉽게 파악할 수 있습니다." 문구를 표시하여, 사용자가 부담 없이 제목만으로도 제출할 수 있음을 안내한다.
- **필수 필드**: 제목(`title`)만 필수이며, 나머지(상세 내용, 스크린샷)는 모두 선택이다.

### 규칙 7 — basePath 안전 호출 (API Fetch)
- **필수**: `fetch()` 대신 `apiFetch()`(`@/lib/api-helpers`)를 사용하여 `basePath`가 자동으로 포함되도록 한다.
- **이유**: Next.js `basePath` 설정 시 `fetch("/api/...")`는 `basePath`를 자동으로 붙이지 않아 404 HTML 응답 → JSON 파싱 에러가 발생한다.

### 규칙 8 — Zod 스키마 nullable 처리 (API Validation)
- **필수**: `description`과 `screenshot` 필드는 Zod 스키마에서 `.nullable().optional()`로 정의해야 한다.
- **이유**: 프론트엔드에서 빈 값을 `null`로 전송하는데, `.optional()`만으로는 `undefined`만 허용하고 `null`은 거부하여 `"expected string, received null"` 에러가 발생한다.

### 규칙 9 — 헤더 진입점 (Header Entry Point)
- **위치**: 메인 헤더(`header.tsx`)의 **검색(🔍) 버튼 바로 왼쪽**에 Bug 아이콘 버튼을 배치한다.
- **데스크탑/모바일 동시 지원**: 데스크탑과 모바일 헤더 영역 모두에 Bug 버튼을 배치한다.
- **호버 색상**: `hover:text-red-500`으로 시각적 구분한다.
- **전역 접근**: 어느 페이지에서든 상단 헤더를 통해 바로 버그 제보가 가능해야 한다.

### 규칙 10 — 캡처 성능 및 페이로드 용량 최적화 (Performance & Payload Optimization)
- **포맷**: 무손실 `toPng` 대신 `toJpeg` (quality: 0.7)를 사용하여 연산 속도와 이미지 용량을 최적화한다.
- **폰트 임베딩 스킵 (skipFonts: true)**: `html-to-image`가 웹폰트 파일들을 다운로드하고 base64 변환하는 동기적 폰트 임베딩 과정이 최대 병목(3초~10초 지연)을 유발하므로, `skipFonts: true`를 필수 지정하여 캡처 시간을 **0.05초(50ms)** 이하로 즉시 단축한다.
- **뷰포트 한정**: 전체 페이지(`document.body`) 스크롤 영역 대신 현재 화면 뷰포트 크기(`width: window.innerWidth`, `height: window.innerHeight`)로 캡처 대상을 한정한다.
- **캔버스 해상도 스케일링**: `canvasWidth` / `canvasHeight`를 최대 1280px / 960px 이하로 제어하여 Base64 페이로드가 300KB를 초과하지 않도록 보장한다.
- **이유**: `toPng(document.body)` 전체 DOM 트래버스 시 수초~수십초 캡처 지연 및 Base64 페이로드 거대화(5MB~15MB+)로 인한 HTTP 413 Payload Too Large / Network Error 저장 실패를 원천 방지한다.

### 규칙 11 — 어드민 스크린샷 원본 라이트박스 팝업 (Admin Screenshot Lightbox Viewer)
- **문제점**: 어드민 모달 안에서 스크린샷을 작은 썸네일/상자에 고정할 경우 글씨를 식별할 수 없는 가독성 저하가 발생한다.
- **해결책**:
  1. 이미지 클릭 시 화면 가득(90vw x 90vh) 확대되는 **전역 라이트박스 팝업 모달 (`zoomImage`)**을 띄웁니다.
  2. 🔍 원본 크게 보기 (팝업) 버튼과 새 탭에서 원본 열기 ↗ 링크를 동시에 제공한다.
  3. 이미지 호버 시 `cursor-zoom-in` 및 확대 툴팁 오버레이를 표시한다.

---

## 2. 데이터베이스 동기화 및 관리 규칙 (Sync Rules)

1. **환경별 DATABASE_URL 파악**:
   - `.env.production` (운영), `.env.test` (테스트), `.env` (로컬)의 DB 접속 문자열을 확인한다.
2. **제보 데이터 병합**:
   - 운영 서버와 테스트 서버에 산재되어 쌓인 `bug_reports` 테이블 행(row) 데이터를 추출하여 고유 ID 및 생성시점 기준 단일 셋으로 병합한다.
3. **로컬 환경 이미지 복원**:
   - 병합된 데이터를 local DB에 복사(`pg_restore` 등)할 때, 스크린샷 이미지 경로(`screenshot`)가 로컬에 존재하지 않아 404가 발생할 수 있다.
   - 이 경우 스크린샷 경로를 운영 도메인의 절대 주소(예: `https://<운영도메인>/uploads/bug-reports/...`)로 변경하는 `UPDATE` 쿼리를 수행하여 로컬에서도 이미지가 깨지지 않고 보이도록 조치한다.
