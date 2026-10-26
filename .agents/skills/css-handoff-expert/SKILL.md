---
name: css-handoff-expert
description: 사용자가 제공한 임의의 웹사이트 URL로부터 CSS 토큰 및 UI 컴포넌트 스타일을 추출하여 디자이너-개발자 핸드오프용 디자인 시스템 CSS와 사용 가이드 MD 문서를 생성하는 범용 전문가 스킬.
---

# 범용 웹사이트 CSS 추출 및 디자이너-개발자 핸드오프 전문가 (css-handoff-expert)

임의의 웹사이트 URL이나 스타일시트를 입력받아 디자인 토큰을 정밀 추출하고, 디자이너가 개발자에게 전달하는 목적의 **디자인 시스템 CSS(`tmp/design-system.css`)** 및 **핸드오프 가이드(`tmp/design-system-guide.md`)**를 생성하는 표준 워크플로우를 제공한다.

## 1. 발동 시점
- 사용자가 웹사이트 URL(예: `https://example.com`)을 전달하며 CSS 추출, 디자인 시스템 추출, 디자인 토큰 추출, 디자이너-개발자 전달용 CSS/가이드 작성을 요청할 때
- 기존 웹 서비스의 스타일을 분석하여 표준 CSS 및 가이드 문서로 리버스 엔지니어링할 때

## 2. 표준 작업 절차 (5단계 파이프라인)

### 1단계: 타깃 사이트 에셋 탐색 및 다운로드
1. 대상 URL로 HTTP 요청을 보내 HTML을 수집하고, 포함된 모든 CSS 링크(`<link rel="stylesheet">`, Next.js `_next/static/chunks/*.css`, 외부 폰트 등)를 탐색한다.
2. 추출된 CSS 파일들을 임시 디렉터리(`tmp/`)로 다운로드한다. (프로젝트 루트에 직접 파일 생성 금지)

```bash
# 예시: HTML 및 CSS 다운로드
curl -sL "<타깃 URL>" > tmp/target_page.html
curl -sL "<CSS 파일 URL>" > tmp/target_style.css
```

### 2단계: 디자인 토큰 및 클래스 패턴 파싱 (Python/CLI 활용)
1. **디자인 토큰 분석**:
   - `:root` 및 `.dark` (또는 테마 클래스)에 정의된 CSS Custom Properties(`--*`) 전수 수집
   - 브랜드 메인 컬러, 보조 컬러, 경고/성공/정보 시맨틱 컬러, 텍스트 계층 컬러(`text-main`, `text-body`, `text-sub`, `text-muted`), 배경/카드/테두리 색상 분류
   - 폰트 패밀리, 폰트 크기/줄간격 스케일, 모서리 곡률(`border-radius`), 그림자(`box-shadow`) 추출
2. **DOM 클래스 및 컴포넌트 패턴 분석**:
   - HTML 마크업에서 버튼, 폼/입력창, 배지/태그, 카드, 테이블, 탭/필터, 모달, 헤더/내비게이션, 리치 텍스트 서식 클래스 추출

### 3단계: 표준 디자인 시스템 CSS 생성 (`tmp/design-system.css`)
- 프레임워크에 독립적인 순수 CSS로 작성 (Vanilla HTML, React, Vue, Svelte, Tailwind 등 모든 환경 호환)
- **섹션 구성**:
  1. `:root` 디자인 토큰 (라이트 모드)
  2. `.dark` 디자인 토큰 (다크 모드 1:1 대칭 매핑)
  3. 기본 베이스 및 타이포그래피 스케일 (`.text-h1` ~ `.text-caption`)
  4. 공통 UI 컴포넌트 스타일셋:
     - 버튼: `.btn` 기반 크기(`.btn-sm`, `.btn-md`, `.btn-lg`) 및 변형(`.btn-primary`, `.btn-primary-outlined`, `.btn-secondary`, `.btn-destructive`, `.btn-tab` 등)
     - 폼 컨트롤: `.form-group`, `.form-label`, `.input-field`, `.select-field`, `.form-error`
     - 상태 배지: `.badge-success`, `.badge-destructive`, `.badge-warning`, `.badge-info`, `.badge-neutral`
     - 카드/패널: `.card`, `.card-interactive`, `.card-header`, `.card-body`, `.card-footer`
     - 데이터 테이블: `.table-container`, `.table-base`, 행 호버 스타일
     - 탭 & 필터 바: `.tab-list`, `.pill-filter-group`
     - 모달 대화상자: `.modal-backdrop`, `.modal-content`, `.modal-header`, `.modal-body`, `.modal-footer`
     - 본문 리치 텍스트: `.rich-content`

### 4단계: 디자이너-개발자 핸드오프 가이드(MD) 생성 (`tmp/design-system-guide.md`)
- 수강생 및 비개발자 친화적인 명확한 어조로 작성 (개발자 은어 배제, 복사용 마크업 제공)
- **가이드 필수 포함 내용**:
  1. **디자인 시스템 개요 및 브랜드 무드/컬러 컨셉**
  2. **디자인 토큰 상세 명세표**: 라이트/다크 모드 HEX 코드 대조표, 타이포그래피 스케일 표, 반경/그림자 값
  3. **컴포넌트 카탈로그**: 즉시 복사하여 쓸 수 있는 순수 HTML 마크업 예제
  4. **개발자 프레임워크 연동 가이드**:
     - HTML/CSS 직접 임포트 방법
     - React / Next.js 전역 CSS 적용
     - Tailwind CSS v3(`tailwind.config.js`) 및 v4(`@theme`) 매핑 설정 코드
     - 다크 모드 토글 스크립트
  5. **디자이너-개발자 협업 및 웹 접근성(A11y) 체크리스트**

### 5단계: 무결성 검증
1. 생성된 모든 파일에 대해 UTF-8 인코딩 검증을 실행합니다:
   ```bash
   python3 -c "open('tmp/design-system.css','rb').read().decode('utf-8')" && echo "CSS UTF-8 OK"
   python3 -c "open('tmp/design-system-guide.md','rb').read().decode('utf-8')" && echo "MD UTF-8 OK"
   ```
2. 저장소 루트에 임시 파일이 남지 않았는지 확인하고 `tmp/` 폴더 내에 정상 저장되었는지 점검한다.
