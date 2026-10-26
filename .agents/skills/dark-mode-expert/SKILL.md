---
name: dark-mode-expert
description: 라이트/다크 모드 간 시각적 일관성 구현 및 감사를 위한 2계층 수정 전략과 컴포넌트별 패턴 가이드.
---

# 다크 모드 구현 및 감사 전문가 스킬

애플리케이션 전반에 걸쳐 다크 모드 스타일링을 구현하고 감사하기 위한 규칙과 가이드라인을 정의한다. 라이트/다크 모드 간 원활한 시각적 동등성을 보장하며 눈부심을 방지한다.

---

## 0. 아키텍처 개요 — 2계층 수정 전략

### 0-1. Tailwind CSS v4 필수 설정 — 클래스 기반 다크 모드 활성화 (CRITICAL)
Tailwind CSS v4(`@import "tailwindcss";`)는 기본적으로 OS 설정(`prefers-color-scheme`) 기반으로 동작합니다. 수동 테마 토글 버튼(`.dark` 클래스 추가/제거)을 지원하려면 `globals.css`에 커스텀 변형을 반드시 선언해야 합니다:

```css
@import "tailwindcss";

/* Tailwind v4 클래스 기반 다크 모드 활성화 필수 규칙 */
@custom-variant dark (&:where(.dark, .dark *));
```

### 0-2. 프로토타입 이관 시 하이라이트/히어로 배너의 라이트·다크 2계층 분리
외부 프로토타입이나 템플릿에서 시각적 주목을 위해 어두운 그라디언트(`from-*-900 to-*-950 text-white`)로 하드코딩된 카드는 **라이트 모드에서 그대로 노출해서는 안 됩니다** (사용자에게 "라이트 모드 CSS 누락/버그"로 인식됨).

- **라이트 모드**: 산뜻한 브랜드 틴트 그라디언트 + 다크 텍스트
  - 예: `bg-gradient-to-br from-indigo-50/95 via-indigo-100/60 to-indigo-50/80 border-indigo-200/90 text-slate-900`
- **다크 모드**: 깊이 있는 다크 그라디언트 + 라이트 텍스트
  - 예: `dark:from-indigo-950/90 dark:via-indigo-900/60 dark:to-slate-900 dark:border-indigo-800/50 dark:text-white`
- **공통 글래스 카드 유틸리티 누락 점검**:
  - 프로토타입에서 쓰이는 `.glass-card` 등의 커스텀 클래스는 `globals.css`에 라이트/다크 양방향으로 반드시 선언해야 합니다.

---

다크 모드 수정은 우선순위 순서에 따라 **2계층 접근법**으로 적용해야 한다:

### 계층 1 — 전역 CSS 오버라이드 (우선 시도)
**파일: `frontend/src/app/globals.css`**

`globals.css`의 전역 `.dark` 오버라이드는 모든 `text-gray-*`와 공통 하드코딩된 hex 색상을 가독성 있는 다크 모드 값으로 자동 리매핑한다 — **개별 컴포넌트 파일을 수정하지 않고**. 다수의 파일이 같은 가독성 문제를 가질 때 가장 효과적인 수정이다.

**Current global remapping in place (text):**
```css
.dark .text-gray-900, .dark .text-gray-800 → #f1f5f9 (slate-100)
.dark .text-gray-700                        → #cbd5e1 (slate-300)
.dark .text-gray-600                        → #94a3b8 (slate-400)
.dark .text-gray-500                        → #64748b (slate-500)
.dark .text-gray-400                        → #475569 (slate-600)
.dark [class*="text-[#2E323B]"]             → #e2e8f0 (slate-200) !important
.dark [class*="text-[#414651]"]             → #cbd5e1 (slate-300) !important
.dark [class*="text-[#717680]"]             → #94a3b8 (slate-400) !important
.dark [class*="text-[#A4A7AE]"]             → #64748b (slate-500) !important
.dark [class*="text-[#585D68]"]             → #94a3b8 (slate-400) !important  ← NEW
.dark [class*="text-[#BA2628]"]             → #fb7185 (rose-400) !important   ← NEW
.dark [class*="text-[#1F2128]"]             → #f1f5f9 (slate-100) !important  ← NEW
.dark [class*="text-[#4B5563]"]             → #cbd5e1 (slate-300) !important  ← NEW
.dark [class*="text-[#129C49]"]             → #4ade80 (green-400) !important  ← NEW
.dark [class*="text-[#9D6810]"]             → #fbbf24 (amber-400) !important  ← NEW
```

**Current global remapping in place (borders):**
```css
.dark [class*="border-[#EAEAEA]"] → #334155 (slate-700) !important  ← covers 40+ files
.dark [class*="border-[#D5D7DA]"] → #334155 (slate-700) !important  ← covers 15+ files
.dark [class*="border-[#CFF2DB]"] → green-800/50 !important
.dark [class*="border-[#FCAEB7]"] → #9f1239 (rose-800) !important
```

**Current global remapping in place (backgrounds):**
```css
.dark [class*="bg-[#FAFAFA]"]  → slate-800/60 !important   ← comment boxes, FAQ, bulletin boards
.dark [class*="bg-[#FFF2F3]"] → rose-950/40 !important    ← danger buttons, bookmark active
.dark [class*="bg-[#EFFFF5]"] → green-900/30 !important   ← reserve/success buttons
.dark [class*="bg-[#FFF4E3]"] → amber-950/40 !important   ← warning banners
.dark [class*="bg-[#F5F5F5]"] → #1e293b (slate-800) !important ← placeholders, badges
.dark [class*="bg-[#D5D7DA]"] → #334155 (slate-700) !important
.dark [class*="bg-[#EAEAEA]"] → #334155 (slate-700) !important ← thumbnails
.dark [class*="bg-[#F8F8FA]"] → #0f172a (slate-900) !important ← input backgrounds
.dark [class*="bg-[#D9D9D9]"] → #334155 (slate-700) !important ← skeleton banners
```

**계층 1을 확장해야 하는 경우 (globals.css):**
- 새 하드코딩된 hex 색상이 같은 가독성 문제로 **5개 이상 파일**에서 사용될 때
- 새 배경 패턴(예: `bg-[#NEWCOLOR]`)이 dark 변형 없이 광범위하게 나타날 때
- 전역 컴포넌트 상태(로딩 스켈레톤, 배지 색상)에 범용 다크 톤이 필요할 때

**계층 1을 사용하지 않는 경우:**
- 고유한 맥락을 가진 일회성 컴포넌트
- 모든 곳에서 같은 방식으로 매핑되면 안 되는 색상

> ⚠️ **CRITICAL — Opacity Suffix Bug**: `[class*="bg-[#FAFAFA]"]` selector does **NOT** match `bg-[#FAFAFA]/50` (with opacity suffix). If an element uses `bg-[#fafafa]/50` or `bg-white/50`, the Layer 1 selector silently fails. **Always add an explicit `dark:bg-*` class in JSX** for any opacity-suffixed colour.
> ```tsx
> // ❌ Layer 1 won't cover this:
> className="bg-[#fafafa]/50"     // selector [class*="bg-[#FAFAFA]"] doesn't match
> className="bg-white/50"         // Layer 1 has no white rule either
>
> // ✅ Must add dark: explicitly:
> className="bg-[#fafafa]/50 dark:bg-slate-800/60"
> className="bg-white/50 dark:bg-slate-800/60"
> ```

### 계층 2 — 컴포넌트 수준 `dark:` 클래스 (보조, 고유 케이스용)
컴포넌트가 전역 매핑과 다른 특정 다크 처리가 필요할 때 사용한다. `dark:text-slate-*`, `dark:bg-slate-*`, `dark:border-slate-*` 등을 `className`에 직접 적용한다.

> ⚠️ **Rule**: Layer 1 does NOT need `!important` for `dark:text-*` classes — explicit `dark:` utilities in JSX take precedence in the CSS cascade because they appear later. Only hardcoded `text-[#hex]` overrides need `!important`.

---

## 1. 시각 사양 기준

스타일을 리뷰하거나 작성할 때 프로젝트 브랜드 UI 스펙을 준수해야 한다. 아래는 권장 기준값이며, 프로젝트에 맞게 조정한다:
- **Global Background**: 다크 모드 배경은 `slate-950` 계열을 권장한다.
- **Card & Container Background**: 다크 모드 카드·사이드바·서브패널은 `slate-900` 계열을 권장한다.
- **Brand Accents**: 프로젝트 브랜드 컬러를 주요 액션, 포커스 링, 활성 표시선에 일관되게 적용한다.
- **Text Contrast (reference mapping)**:

| Light colour | Dark equivalent | Use case |
|---|---|---|
| `text-gray-900` / `text-gray-800` | `slate-100` (#f1f5f9) | Primary headings |
| `text-gray-700` | `slate-300` (#cbd5e1) | Body text |
| `text-gray-600` | `slate-400` (#94a3b8) | Secondary labels |
| `text-gray-500` | `slate-500` (#64748b) | Captions, placeholders |
| `text-gray-400` | `slate-600` (#475569) | Muted/disabled |
| `text-[#2E323B]` | `slate-200` (#e2e8f0) | Legacy hex headings |
| `text-[#414651]` | `slate-300` (#cbd5e1) | Legacy hex body |
| `text-[#717680]` | `slate-400` (#94a3b8) | Legacy hex secondary |
| `text-[#A4A7AE]` | `slate-500` (#64748b) | Legacy hex muted |
| `text-[#3A4050]` | `slate-300` (#cbd5e1) | Deep slate body (mission-values) |
| `text-[#7A8190]` | `slate-400` (#94a3b8) | Medium slate muted |
| `text-[#404040]` | `slate-200` (#e2e8f0) | Near-black body (FAQ answers) |

---

## 2. 엄격한 안티패턴 규칙 (반드시 강제)

### 2.1 배경용 인라인 스타일 금지
- **규칙**: UI 컴포넌트에서 배경용으로 인라인 스타일이나 커스텀 props(`style={{ backgroundColor: ... }}` 또는 `dataCellsBackgroundColor="#FFFFFF"` 등)를 사용하는 것은 **엄격히 금지**한다.
- **조치**: 해당 props와 스타일을 모두 제거하고 Tailwind `className` 표준 유틸리티로 완전히 전환하여 `dark:` 클래스가 올바르게 오버라이드할 수 있게 한다.

### 2.2 깊은 컴포넌트 트리 추적
- **규칙**: 최상위 Page나 Layout 컴포넌트(`app/[locale]/...`)에서 멈추지 않는다.
- **조치**: 페이지/레이아웃 레벨부터 모든 중첩 공통 컴포넌트(`src/components/...`)까지 Import 트리를 반드시 추적해야 한다. 트리의 모든 재사용 컴포넌트(.tsx)를 개별적으로 열어 다크 모드 완전성을 교차 검증한다.

### 2.3 종합적인 헥스 코드 검색
- **규칙**: `bg-white`나 특정 오프-화이트 회색만 검색하지 않는다. 커스텀 로딩 스켈레톤 색상(예: `#D4D4D4`, `#E8E8E8`)이나 색상 상태 배지(예: `#EAF4EE` 초록, `#FFFBEB` 노랑) 때문에 많은 누락이 발생한다.
- **조치**: 감사 시 전체 코드베이스(`src/components`와 `src/app`)에서 모든 배경 헥스 코드 패턴을 종합적으로 `grep_search` 해야 한다:
  - 정규식 대상: `bg-\[#[0-9a-fA-F]{3,6}\]`
  - 모든 인스턴스에 대응하는 `dark:bg-...` 클래스가 있는지 확인한다. (예: `bg-[#EAF4EE]` 초록은 `dark:bg-green-900/20`이 있어야 함).

### 2.4 깊은 Props, 함수, 배열 (숨겨진 클래스)
- **규칙**: 클래스가 항상 단순한 `className="..."` 문자열에 있는 것이 아니다. 설정 객체 내부의 함수나 props(예: `cellClassName: () => "bg-[#FFFCF8]"`), 또는 배열에서 동적으로 매핑되는 경우(예: `const summaryCardStyles = [{ bgClass: "bg-[#FBF8FF]" }]`)도 있다.
- **조치**: 단순한 정규식 텍스트 매칭에만 의존하지 않는다. 페이지 감사 시 테이블이나 목록에 전달된 실제 데이터 구조, 컬럼 정의, 배열 맵을 검사하여 숨겨진 배경 클래스 주입을 찾아야 한다.

### 2.5 스켈레톤 로더와 배지
- **규칙**: 로딩 상태(`animate-pulse`)와 상태 배지(알림, 태그)는 항상 화이트 테마에는 어울리지만 다크 모드에서는 눈부신 연한 배경색을 사용한다.
- **조치**: `animate-pulse`를 명시적으로 검색하여 해당 div에 `dark:bg-slate-700` 또는 `dark:bg-slate-800`이 있는지 확인한다. 색상 배지를 검색하고 불투명도가 낮은 다크 배경을 적용한다(예: `dark:bg-yellow-900/30`).

### 2.6 표시 레이블의 HTML 엔티티 디코딩
- **규칙**: API에서 가져온 카테고리 이름과 레이블에 HTML 인코딩 문자(예: `&`대신 `&amp;`)가 포함되어 있을 수 있다. 이는 UI에서 잘못 표시된다.
- **조치**: API 데이터에서 동적 레이블을 렌더링할 때(예: 분류 태그, 카테고리 칩), 항상 다음과 같은 헬퍼로 HTML 엔티티를 디코딩한다:
  ```ts
  const decodeHtml = (str: string) => {
    if (typeof document === "undefined") return str;
    const txt = document.createElement("textarea");
    txt.innerHTML = str;
    return txt.value;
  };
  ```
  JSX에서 API 소스 문자열을 렌더링하기 전에 적용한다.

### 2.7 앵커(`<a>`) 태그 — 자주 누락됨
- **규칙**: 외부 URL로 연결되는 일반 `<a>` 요소(예: 기사 링크, "기사 보기")는 대부분 명시적인 텍스트 색상이 없어 브라우저 기본값을 상속한다. 다크 모드에서 상속된 색상이 거의 보이지 않을 수 있다.
- **조치**: 모든 `<a>` 요소에 명시적인 `text-*`와 `dark:text-*` 클래스를 항상 추가한다. 표준 패턴:
  ```tsx
  // 주요 기사 링크
  className="text-gray-900 dark:text-slate-100 hover:underline"
  // 보조 헬퍼 링크
  className="text-[#717680] dark:text-slate-400 hover:text-blue-600 dark:hover:text-blue-400"
  ```

### 2.8 감정/인터랙션 상태 색상 (북마크/좋아요 버튼)
- **규칙**: 북마크와 좋아요 버튼은 브랜드 특화 파스텔 배경(`bg-[#FFF2F3]`, `border-[#FFC9CF]`)을 사용하는데, 다크 모드에서는 보이지 않거나 눈에 거슬린다. 특히 "활성" 상태가 이에 취약하다.
- **조치**: 불투명도가 낮은 깊은 색조를 사용하여 다크 동등 색상을 적용한다:
  ```tsx
  // 북마크됨 / 활성 상태
  className="bg-[#FFF2F3] dark:bg-rose-950/40 border border-[#FFC9CF] dark:border-rose-800 hover:bg-transparent dark:hover:bg-rose-950/20"
  // 활성 상태 내부 텍스트
  className="text-[#781718] dark:text-rose-400"
  // 비활성 상태
  className="bg-secondary dark:bg-slate-800 border border-(--button-normal-tab-bg) dark:border-slate-700"
  // 비활성 상태 내부 아이콘
  className="text-gray-600 dark:text-slate-400"
  ```

---

## 3. 공유 컴포넌트 및 DataTable 가이드라인

공유 UI 컴포넌트 내에 하드코딩된 라이트 모드 요소는 엄격히 금지한다. 다음 변환을 적용해야 한다:

### 3.1 테이블 헤더와 그리드 테두리
- **헤더**: `bg-[#F5F5F5]` → `bg-[#F5F5F5] dark:bg-slate-900` 또는 `dark:bg-slate-900/80`로 전환한다.
- **텍스트**: `text-gray-700` → `text-gray-700 dark:text-slate-300`으로 매핑한다.
- **테두리 영구분선**: `border-gray-200` 또는 `divide-gray-200`의 모든 인스턴스를 `border-gray-200 dark:border-slate-800`과 `divide-gray-200 dark:divide-slate-800`로 교체한다.

### 3.2 행 클래스명 덮어쓰기 (`rowClassName` 우회)
- 커스텀 `rowClassName`이 일반 컨테이너나 테이블 행에 전달되면(예: 회원 목록에 `rowClassName="bg-[#FFFCF8]"`), 다크 모드 배경색을 라이트 모드 색상으로 **덮어쓰면 안 된다**.
- **규칙**: `rowClassName`을 행에 그대로 전달한다 — 일반 컴포넌트 내부에서 `dark:bg-*`를 추가하지 않는다. 대신, `rowClassName` 자체에 호출 페이지에서 전달할 때 다크 변형이 포함되어 있어야 한다.
- **중요**: `DataTable` 컴포넌트는 이전에 className 템플릿에 추가하는 방식으로 `dark:bg-slate-900/40`을 이중 적용했다. 이는 수정됨 — 이제 `rowClassName`은 수정 없이 전달된다.

### 3.3 리치 텍스트, HTML 렌더링, 타이포그래피 (`prose` / `rich-content`)
- **규칙**: Tailwind의 `prose` 클래스를 사용하여 HTML 콘텐츠(예: TipTap 출력)를 렌더링할 때, 텍스트가 기본적으로 어두운 텍스트로 설정되어 다크 모드에서 보이지 않게 된다.
- **조치**: `prose` 사용 시 반드시 `dark:prose-invert`를 적용해야 한다. 또한 prose 내부에 테이블과 같은 커스텀 중첩 요소가 있으면(예: `[&_td]:border-gray-300`), 해당 다크 클래스도 추가해야 한다.

**`rich-content` 유틸리티 클래스** — `prose`가 사용되지 않는 `dangerouslySetInnerHTML` 콘텐츠용:
- **규칙**: 요소가 `prose` 클래스 없이 API의 raw HTML(FAQ 답변, 어드민 CMS 텍스트 등)을 렌더링하면, 내부 HTML 요소(`<p>`, `<a>`, `<strong>`, `<td>`, 헤딩)에 다크 모드 스타일이 없다.
- **조치**: 컨테이너에 `rich-content` CSS 유틸리티 클래스를 추가한다. 이 클래스는 `globals.css`에 정의되어 모든 자식 요소에 다크 텍스트 색상을 자동으로 적용한다:
  ```tsx
  // 이전
  <div
    className="text-sm text-[#404040] leading-relaxed"
    dangerouslySetInnerHTML={{ __html: decodeHtmlEntities(faq.answer) }}
  />

  // 이후
  <div
    className="text-sm text-[#404040] dark:text-slate-200 leading-relaxed rich-content"
    dangerouslySetInnerHTML={{ __html: decodeHtmlEntities(faq.answer) }}
  />
  ```
  `globals.css`의 `rich-content` 클래스는 `.dark .rich-content p/li/span/div/strong/a/h1-h6/td/th`에 `color: #e2e8f0 !important`을, 링크에 `color: #4ade80 !important`를 적용한다.

### 3.4 상태 호버를 차단하는 셀 배경 (Tailwind `group`)
- **규칙**: `<td>`에 자체 배경색(예: `bg-[#FFFCF8]`)이 있으면, 자식이 부모 위에 렌더링되기 때문에 `<tr>`의 호버 배경(예: `hover:bg-gray-50 dark:hover:bg-slate-800/40`)이 시각적으로 차단된다.
- **조치**: 테이블 컴포넌트(`DynamicTable` 등)에서 `<tr>`에 `group` 클래스를 추가하고, `<td>`에 `group-hover:bg-transparent dark:group-hover:bg-transparent`를 추가해야 한다. 이는 사용자가 행에 호버할 때 셀의 불투명 배경이 라이트/다크 모드 모두에서 투명해지게 하여, 행의 호버 색상이 제대로 보이게 한다.

### 3.5 RoundedTabHeader (둥근 탭 네비게이션)
- **활성 탭**: `bg-white text-[#2E323B] border-[#2E323B]` → `dark:bg-slate-800 dark:text-slate-100 dark:border-slate-500` 추가
- **비활성 탭**: `text-[#717680] border-[#D5D7DA]` → `dark:text-slate-400 dark:border-slate-700 dark:hover:bg-slate-800/60` 추가
- **하단 구분선**: `border-[#A4A7AE]` → `dark:border-slate-700` 추가

### 3.6 검색 컴포넌트 (필터 칩) — CategoriesSelector 패턴
- **컨테이너**: `bg-secondary` / `bg-gray-50` → `dark:bg-slate-800/50` 추가
- **검색 아이콘 버튼**: `text-gray-400 hover:text-gray-600` → `dark:text-slate-500 dark:hover:text-slate-300` 추가
- **카테고리 칩 (선택 안 됨)**: `bg-white` → `dark:bg-slate-800 text-gray-700 dark:text-slate-300 hover:bg-gray-100 dark:hover:bg-slate-700`
- **카테고리 칩 (선택됨)**: `bg-[#D5D7DA]` → `dark:bg-slate-600 text-gray-900 dark:text-slate-100 border-transparent`
- **중요**: 칩에 라이트와 다크 텍스트 모두 명시해야 한다. `bg-[#D5D7DA]`만 있으면 다크 모드에서 거의 보이지 않고 텍스트 색상을 제공하지 않는다.

### 3.7 DataTable 확장 행 콘텐츠
- **확장 행 패널 배경**: `bg-gray-50 border-t border-gray-200` → `dark:bg-slate-900 dark:border-slate-800` 추가
- **확장 버튼**: `bg-[#F4EBFF]` → `dark:bg-slate-700/60` 추가

### 3.8 SingleDatePicker (팝오버 캘린더) — 공통 컴포넌트
`SingleDatePicker`는 4개 이상 위치(스크랙 페이지, admin/data-management, admin/statistics, search-bar-modal)에서 사용된다.
여기에서의 수정은 모든 곳에 자동으로 전파된다.

**트리거 버튼:**
```tsx
className={cn(
  "bg-white dark:bg-slate-800 border border-gray-300 dark:border-slate-700 hover:bg-gray-50 dark:hover:bg-slate-700",
  className
)}
// 날짜 텍스트
className="text-[#414651] dark:text-slate-200 text-sm font-semibold"
// 캘린더 아이콘
className="text-gray-400 dark:text-slate-500"
```

**팝오버 캘린더 내부:**
```tsx
// 월 헤더 텍스트
className="text-lg font-semibold text-[#414651] dark:text-slate-200"
// 탐색 버튼 (이전/다음 월)
className="p-1 hover:bg-gray-100 dark:hover:bg-slate-700 rounded cursor-pointer"
// 탐색 아이콘
className="h-4 w-4 text-gray-600 dark:text-slate-400"
// 요일 헤더
className="text-center text-xs font-medium text-gray-600 dark:text-slate-400 py-1"
// 날짜 버튼 — 현재 월 외부
!isCurrentMonth && "text-gray-300 dark:text-slate-600"
// 날짜 버튼 — 범위 내부 (범위 선택기 모드)
inRange && "bg-[#E0F2FE] dark:bg-blue-900/40 text-gray-900 dark:text-slate-100"
// 날짜 버튼 — 선택/시작/끝
(isSelected || isStart || isEnd) && "bg-[#664AD7] dark:bg-violet-600 text-white"
// 날짜 버튼 — 일반 현재 월
"text-gray-900 dark:text-slate-200 hover:bg-gray-100 dark:hover:bg-slate-700"
// 액션 버튼 구분선
className="border-t dark:border-slate-700"
```

### 3.9 이미지 플레이스홀더 (이미지 없음 폴백)
이미지가 로드에 실패하거나 없으면 폴백 컨테이너가 표시된다:
```tsx
// 이전 (라이트만)
className="flex items-center justify-center bg-[#F5F5F5] rounded ..."
// 아이콘
className="text-[#A1A6B0]"

// 이후 (다크 모드 추가)
className="flex items-center justify-center bg-[#F5F5F5] dark:bg-slate-800 rounded ..."
className="text-[#A1A6B0] dark:text-slate-500"
```
외부 이미지를 렌더링하는 모든 카드(SubjectCard, 도서 카드 등)에서 이 패턴이 반복된다.

---

## 4. 컴포넌트별 패턴 (자주 사용)

### 4.1 Summary Pill / Stats Box
Pattern: `bg-[#F5F5F5] border border-[#D5D7DA]`
```tsx
// Correct
className="bg-[#F5F5F5] dark:bg-slate-800/60 border border-[#D5D7DA] dark:border-slate-700"
// Text inside
className="text-[#414651] dark:text-slate-300 font-medium text-sm"
// Numeric values get extra emphasis
className="font-bold text-gray-800 dark:text-slate-100"
```

### 4.2 Category Filter Chip (Selected State)
Old pattern: `bg-[#D5D7DA]` (light gray, invisible in dark)
```tsx
// Correct selected chip
className={`... ${isSelected
  ? "bg-slate-700 dark:bg-slate-600 border border-slate-600 dark:border-slate-500"
  : "bg-transparent border border-[#D5D7DA] dark:border-slate-700 hover:bg-gray-100 dark:hover:bg-slate-800"
}`}
// Selected count badge
className={isSelected
  ? "bg-slate-500/60 dark:bg-slate-500/50 text-slate-100"
  : "bg-[#EFFFF5] dark:bg-green-900/30 text-[#129C49] dark:text-green-400"
}
```

### 4.3 Content Cards (Resource/Collection/Board)
```tsx
// Card container
className="bg-white dark:bg-slate-900 border border-[#EAEAEA] dark:border-slate-800/80"
// Title
className="text-gray-700 dark:text-slate-200 font-bold"
// Subtitle/description
className="text-gray-700 dark:text-slate-400"
// Keyword tag
className="text-[#785AEF] dark:text-violet-400"
```

### 4.4 News/Scrap Article Card (SubjectCard)
New in this session — applies to `components/cards/subject.tsx` and any similar news list cards:
```tsx
// Card border
className="border border-[#EAEAEA] dark:border-slate-700"
// Article title link
className="font-medium text-gray-900 dark:text-slate-100 hover:underline"
// Location · Date metadata
className="text-[#414651] dark:text-slate-400 text-[10px] sm:text-xs"
// "기사 보기" helper link
className="text-[#717680] dark:text-slate-400 hover:text-blue-600 dark:hover:text-blue-400"
// Bookmark button — active
className="bg-[#FFF2F3] dark:bg-rose-950/40 border border-[#FFC9CF] dark:border-rose-800"
// Bookmark button — inactive
className="bg-secondary dark:bg-slate-800 border dark:border-slate-700"
// Bookmark text — active
className="text-[#781718] dark:text-rose-400"
// Bookmark text/icon — inactive
className="text-[#585D68] dark:text-slate-400"
```

### 4.5 Social Reference Comment Box
```tsx
// Comment display box
className="bg-[#FAFAFA] dark:bg-slate-800/60 border border-transparent dark:border-slate-700/50 py-4 px-5 rounded-lg"
// Comment text
className="text-sm text-[#2E323B] dark:text-slate-300 whitespace-pre-line"
// Edit textarea container
className="bg-[#FAFAFA] dark:bg-slate-800/60 py-4 px-5 rounded-lg"
```

### 4.6 Amber/Warning Banner
Pattern: `bg-[#FFF4E3] border-[#F9CF8A] text-[#9D6810]` (eye-searing in dark mode)
```tsx
className="bg-[#FFF4E3] dark:bg-amber-950/40 border border-[#F9CF8A] dark:border-amber-800/60"
// Text inside
className="text-[#9D6810] dark:text-amber-400 font-medium text-sm"
```

### 4.7 Q & A Content Blocks (References Page)
```tsx
// Outer question/answer block border
className="border border-[#A4A7AE] dark:border-slate-700"
// Title text
className="text-[#414651] dark:text-slate-100"
// Author/date text
className="text-[#717680] dark:text-slate-400"
className="text-[#A4A7AE] dark:text-slate-500"
// Content inner box
className="bg-secondary dark:bg-slate-800/50 border border-[var(--button-normal-tab-bg)] dark:border-slate-700"
// prose body
className="prose dark:prose-invert max-w-none"
```

### 4.8 Delete Confirmation Dialog
```tsx
// DialogContent
className="dark:bg-slate-900 dark:border-slate-700"
// Dialog title
className="text-[#2E323B] dark:text-slate-100"
// Dialog description
className="text-[#585D68] dark:text-slate-400"
```

### 4.9 Image Fade Gradient (Card with Image Right/Bottom)
When a card has an image with a fade-to-white gradient overlay (to blend with white card background), the gradient breaks in dark mode:
```tsx
// Before — white bleed visible in dark mode
<div className="hidden md:block absolute inset-y-0 left-0 w-8 bg-gradient-to-r from-white to-transparent" />
<div className="md:hidden absolute inset-x-0 top-0 h-8 bg-gradient-to-b from-white to-transparent" />

// After — matches card background in dark mode
<div className="hidden md:block absolute inset-y-0 left-0 w-8 bg-gradient-to-r from-white dark:from-slate-800 to-transparent" />
<div className="md:hidden absolute inset-x-0 top-0 h-8 bg-gradient-to-b from-white dark:from-slate-800 to-transparent" />
```
Always check `from-white` → add `dark:from-slate-800` (or `dark:from-slate-900` if the card bg is slate-900).

### 4.10 Plain Table with `bg-gray-100` Header
For `<table>` elements (not DataTable/shadcn) that use raw Tailwind:
```tsx
// thead row
<tr className="bg-gray-100 dark:bg-slate-800">
  <th className="text-gray-700 dark:text-slate-300">...</th>
</tr>
// tbody rows
<tr className="border-b border-gray-100 dark:border-slate-800 hover:bg-gray-50 dark:hover:bg-slate-800/50">
  <td className="text-gray-700 dark:text-slate-300">...</td>
  <td className="text-gray-500 dark:text-slate-400">...</td>
</tr>
// Skeleton loading row
<tr className="border-b border-gray-100 dark:border-slate-800">
  <td><div className="h-4 bg-gray-200 dark:bg-slate-700 rounded animate-pulse" /></td>
</tr>
```

### 4.11 Pagination Buttons (Custom, not shadcn)
```tsx
// Previous / Next buttons
className="px-3 py-1.5 text-sm rounded border border-gray-300 dark:border-slate-600
           text-gray-600 dark:text-slate-400 hover:bg-gray-100 dark:hover:bg-slate-700
           disabled:opacity-40 cursor-pointer transition-colors"

// Page number buttons — inactive
className="border-gray-300 dark:border-slate-600 text-gray-600 dark:text-slate-400
           hover:bg-gray-100 dark:hover:bg-slate-700"
// Page number buttons — active
className="bg-green-700 text-white border-green-700"  // no dark: needed
```

### 4.12 Cancel / Secondary Buttons (`bg-gray-200`)
```tsx
// Before
className="bg-gray-200 hover:bg-gray-300 text-gray-700"

// After
className="bg-gray-200 dark:bg-slate-700 hover:bg-gray-300 dark:hover:bg-slate-600
           text-gray-700 dark:text-slate-200"
```

### 4.13 Write Form / Input Fields (replace `bg-[#fafafa]/50`)
Input fields that use `bg-[#fafafa]/50` must use explicit dark: since opacity suffix breaks Layer 1:
```tsx
// Before
className="border border-gray-200 rounded-lg text-sm bg-[#fafafa]/50
           focus:ring-green-500 focus:border-green-500"

// After
className="border border-gray-200 dark:border-slate-600 rounded-lg
           text-sm text-gray-900 dark:text-slate-100
           bg-white dark:bg-slate-900
           placeholder:text-gray-400 dark:placeholder:text-slate-500
           focus:ring-green-500 dark:focus:ring-green-400
           focus:border-green-500 dark:focus:border-green-400"
```

---

## 5. 감사 및 디버깅 체크리스트

페이지의 다크 모드 이슈(눈부신 흰색 배경 또는 보이지 않는 텍스트 등)를 감사할 때:

**Step 0 — globals.css가 이미 커버하는지 확인:**
- 문제 클래스(예: `text-gray-600`)를 영향받는 모든 파일에서 grep으로 검색한다.
- 해당 클래스가 5개 이상 파일에 나타나면, `globals.css`에 전역 규칙을 추가한다 (Layer 1).
- 독립적인 경우, 컴포넌트에 직접 `dark:` 클래스를 추가한다 (Layer 2).

**Step 1 — 트리 추적**: 페이지에서 import하는 모든 커스텀 컴포넌트를 매핑한다.

**Step 2 — 라이트 모드 하드코딩 grep**: `bg-white`, `bg-transparent`(흰색 컴포넌트 래핑 시), `bg-[#FAFAFA]`, `bg-[#FFFCF8]`, `bg-[#EAEAEA]`, `bg-gray-50`, `bg-gray-100`을 검색하고 대응하는 `dark:bg-...` 클래스가 없는지 확인한다.

**Step 3 — 테두리 색상 검사**: `border-gray-200`, `border-gray-300`, `border-[#D5D7DA]`, `border-[#A4A7AE]`, `border-[#EAEAEA]` 등 하드코딩된 헥스 테두리를 검색한다. `dark:border-slate-800` 또는 `dark:border-slate-700`이 포함되어 있는지 확인한다.

**Step 4 — 인터랙티브 입력 검증**: 표준 입력(`<Input>`, `<Select>`)이 `dark:bg-slate-950 dark:border-slate-800 dark:text-slate-100`과 브랜드 그린 포커스 링을 활용하는 입력 스타일 가이드라인에 맞는지 확인한다.

**Step 5 — 다이얼로그 & 모달 검사**: `<DialogContent>`가 `dark:bg-slate-900 dark:border-slate-700`을 사용하는지 확인한다.

**Step 6 — prose 영역 검증**: 모든 `className="prose ..."`에 `dark:prose-invert`도 있어야 한다.

**Step 7 — 탭 컴포넌트 확인**: `RoundedTabHeader`와 유사한 탭 바는 활성/비활성 상태와 하단 구분선에 다크 변형이 있어야 한다.

**Step 8 — 검색/필터 컴포넌트 확인**: `CategoriesSelector` / `Search` 컴포넌트의 컨테이너(`bg-secondary`/`bg-gray-50`), 입력(`bg-white`), 칩 태그(`bg-white` / `bg-[#D5D7DA]`) 모두 선택됨/선택 안 됨 상태 모두에 다크 변형이 있어야 한다.

**Step 9 — API 소스 레이블의 HTML 엔티티 인코딩 확인**: API의 카테고리 이름에 `&amp;`, `&lt;` 등이 사용될 수 있다. 렌더링 전 항상 `decodeHtml()`을 통과시킨다.

**Step 10 — 팝오버 / DatePicker 컴포넌트 확인**: 날짜 선택에 사용되는 모든 `<Popover>`를 확인한다:
  - 트리거 버튼 배경 (`bg-white` → `dark:bg-slate-800`)
  - 캘린더 헤더 텍스트와 탐색 아이콘
  - 일 버튼: 월 외부, 호버, 선택됨, 범위
  - 액션 버튼 구분선 (`border-t` → `dark:border-slate-700`)

**Step 11 — 북마크 / 좋아요 / 반응 버튼 확인**: 파스텔 활성 상태(`bg-[#FFF2F3]` 등)는 항상 라이트 전용이다. 활성 상태에 깊은 불투명도 변형(`dark:bg-rose-950/40`, `dark:border-rose-800`)을 적용한다.

**Step 12 — 이미지 폴백 플레이스홀더 확인**: 이미지 없음 플레이스홀더로 사용되는 모든 `<div>`(`bg-[#F5F5F5]` + 아이콘)에 `dark:bg-slate-800`이 필요하고 아이콘에는 `dark:text-slate-500`이 필요하다.

**Step 13 — 일반 `<a>` 링크 색상 확인**: 명시적인 텍스트 색상 클래스 없는 앵커 태그는 브라우저 기본값을 상속하여 보이지 않게 된다. `text-gray-900 dark:text-slate-100`(주요) 또는 `dark:text-slate-400`(보조)를 명시적으로 추가한다.

**Step 14 — `pnpm tsc --noEmit` 실행**: TypeScript 오류가 도입되지 않았는지 확인한다. 커밋 전 모든 오류를 수정한다.

**Step 15 — 전체 코드베이스 갭 스캔 (주기적 감사)**: 다음 명령을 주기적으로(또는 다크 모드 이슈 종료 전) 실행하여 `dark:` 변형 없는 남은 하드코딩 회색 클래스를 감지한다:
```bash
# 남은 총 갭 수 세기
grep -rnE "text-gray-[4-9]00|bg-gray-[1-3]00|border-gray-[1-3]00|(text|bg|border)-\[#[0-9a-fA-F]{3,6}\]" \
  --include="*.tsx" frontend/src --exclude-dir=node_modules \
  | grep -v "dark:" | wc -l

# 갭 수 순으로 영향받은 파일 목록
grep -rnE "text-gray-[4-9]00|bg-gray-[1-3]00|border-gray-[1-3]00|(text|bg|border)-\[#[0-9a-fA-F]{3,6}\]" \
  --include="*.tsx" frontend/src --exclude-dir=node_modules \
  | grep -v "dark:" | awk -F: '{print $1}' | sort | uniq -c | sort -rn | head -20
```
목표는 **남은 줄 0개**이다.

> ⚠️ **갭이 재발하는 이유**: 새 기능이 다크 모드 인식 없이 자주 추가되며, Layer 1 (globals.css)은 웨이브 수정 이후 추가된 컴포넌트 레벨 클래스를 잡아내지 못한다. 다크 모드 관련 PR 종료 전 이 스캔을 실행하는 것은 필수이다.

---

## 6. 다크 모드 주의 파일 목록

> 다크 모드 감사·수정을 완료한 파일은 프로젝트별로 직접 이 표에 기록한다. (라이브러리 기본값은 비어 있음)

| 파일 | 적용된 주요 다크 모드 수정 |
|---|---|

---

## 7. 반복적 갭 방지

새 기능이 다크 모드 인식 없이 추가되면 다크 모드 회귀가 발생한다. 다음 안전장치를 적용한다:

### 7.1 스캔 명령 (다크 모드 이슈 종료 전 실행)
```bash
# 남은 총 갭 줄 수
grep -rnE "text-gray-[4-9]00|bg-gray-[1-3]00|border-gray-[1-3]00|(text|bg|border)-\[#[0-9a-fA-F]{3,6}\]" \
  --include="*.tsx" frontend/src --exclude-dir=node_modules \
  | grep -v "dark:" | wc -l
```

### 7.2 Pre-commit 훅 패턴 (권장)
`.husky/pre-commit` 또는 lint-staged 규칙으로 추가한다:
```bash
#!/bin/bash
COUNT=$(git diff --cached --name-only | xargs grep -lE "text-gray-[4-9]00|bg-gray-[1-3]00|(text|bg|border)-\[#[0-9a-fA-F]{3,6}\]" 2>/dev/null | xargs grep -L "dark:" 2>/dev/null | wc -l)
if [ "$COUNT" -gt 0 ]; then
  echo "⚠️  다크 모드 갭 감지: 스테이징된 파일에 dark: 변형 없는 회색 클래스 또는 하드코딩 헥스 색상이 있다."
  echo "    실행: grep -rnE 'text-gray-[4-9]00|bg-gray-[1-3]00|border-gray-[1-3]00|(text|bg|border)-\\[#[0-9a-fA-F]{3,6}\\]' --include='*.tsx' frontend/src | grep -v 'dark:'"
  exit 1
fi
```

### 7.3 컴포넌트 작성 체크리스트
새 컴포넌트를 작성할 때 항상 모든 회색 클래스와 쌍을 이룬다:

| 라이트 클래스 | 필수 다크 쌍 |
|---|---|
| `text-gray-700` | `dark:text-gray-200` 또는 `dark:text-slate-300` |
| `text-gray-500` | `dark:text-gray-400` 또는 `dark:text-slate-400` |
| `bg-gray-100` | `dark:bg-gray-700` 또는 `dark:bg-slate-800` |
| `bg-gray-200` | `dark:bg-slate-700` |
| `hover:bg-gray-100` | `dark:hover:bg-gray-700` |
| `border-gray-200` | `dark:border-slate-700` |
| `border-gray-300` | `dark:border-slate-600` |
\n### 7.4 커스텀 색상(Tailwind v4) 유의사항\nTailwind v4에서는 `slate-850` 같은 비표준 색상 클래스가 기본 제공되지 않으므로, `dark:bg-slate-850`를 사용할 경우 다크모드에서 스타일이 무시되고 라이트모드 배경(예: `bg-slate-50`)이 그대로 노출되는 치명적인 버그(눈부신 흰색 배경)가 발생한다.\n프로젝트에서 `slate-850`을 사용하려면 반드시 `globals.css`의 `@theme` 안에 `--color-slate-850: #172033;`와 같이 정의해야 한다. 가급적 기본 제공되는 `slate-800` 또는 `slate-900`을 사용하는 것을 권장한다.
