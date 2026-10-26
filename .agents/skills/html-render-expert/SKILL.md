---
name: html-render-expert
description: >
  프론트엔드에서 DB/API로부터 가져온 HTML 문자열(rich text, CMS 콘텐츠, 레거시 데이터)을
  안전하고 일관되게 렌더링하는 방법을 규정하는 전문가 스킬.
  사용 시점: description, content, body 등 DB 저장 HTML 문자열을 JSX에서 렌더링하는 모든 작업에 적용.
---

> **[안내]** 이 파일은 각 프로젝트가 복사해갈 때 프로젝트 상황에 맞게 수정하여 사용하는 템플릿이다.
> 적용 시 이 안내 문구를 제거하고 프로젝트에 맞게 내용을 수정한다.

# HTML 렌더 전문가

## 1. 문제 배경

DB에 리치텍스트(CKEditor 등 WYSIWYG 에디터)로 저장된 HTML 문자열을 JSX에서
`{value}` 로 그냥 출력하면 `<br />`, `<span style="...">` 등 HTML 태그가
화면에 코드 형태로 노출된다.

---

## 2. 렌더링 케이스 판단 트리

```
DB HTML 문자열을 JSX에서 표시해야 한다
│
├── 단순 텍스트 미리보기 (목록 카드, 요약, line-clamp)
│   └── → stripHtmlTags(value)  ← 무조건 이것 사용
│
├── 풍부한 HTML 포맷팅이 필요한 본문 (게시판 본문, FAQ 답변 등)
│   └── dangerouslySetInnerHTML={{ __html: sanitizeRichHtml(decodeHtmlEntities(value)) }}
│
└── 정적 i18n 번역 문자열에 포함된 HTML
    └── dangerouslySetInnerHTML={{ __html: t.some_html_key }}  (번역 파일에서만 허용)
```

---

## 3. 유틸 함수 SSOT (`<project-root>/src/lib/utils.ts`)

| 함수 | 역할 | 사용처 |
|---|---|---|
| `stripHtmlTags(html)` | HTML 전체 제거 → 순수 텍스트 반환 | 카드 description, 검색결과 snippet, line-clamp 미리보기 |
| `decodeHtmlEntities(html)` | `&lt;` `&amp;` 등 HTML 엔티티 디코딩 | sanitizeRichHtml 호출 전 전처리, 제목 표시 |
| `sanitizeRichHtml(html)` | 위험 태그 제거 + max-width 등 안전 속성 주입 | 게시판 본문, CMS 콘텐츠 렌더링 |

---

## 4. 강제 적용 규칙

### ✅ 허용 패턴

```tsx
// 카드, 목록, 미리보기 — 항상 stripHtmlTags
<p className="line-clamp-2">{stripHtmlTags(item.description)}</p>

// 본문 전체 — sanitizeRichHtml + decodeHtmlEntities 조합
<div dangerouslySetInnerHTML={{ __html: sanitizeRichHtml(decodeHtmlEntities(item.content)) }} />

// i18n 번역에서만 — 허용하되 주석 필수
<li dangerouslySetInnerHTML={{ __html: t.step_html }} /> {/* i18n string, safe */}
```

### ❌ 금지 패턴

```tsx
// 직접 렌더링 — HTML 태그가 코드로 노출됨
<p>{item.description}</p>

// sanitize 없이 dangerouslySetInnerHTML — XSS 위험
<div dangerouslySetInnerHTML={{ __html: item.description }} />

// decodeHtmlEntities 없이 dangerouslySetInnerHTML — 이중 인코딩 표시
<div dangerouslySetInnerHTML={{ __html: sanitizeRichHtml(item.content) }} />
```

---

## 5. 새 컴포넌트 작성 체크리스트

DB에서 가져온 HTML 문자열을 렌더링하는 컴포넌트를 만들 때:

- [ ] 단순 미리보기/카드 → `stripHtmlTags` 적용 확인
- [ ] 본문 전체 렌더링 → `sanitizeRichHtml(decodeHtmlEntities(value))` 경유 확인
- [ ] `<p>{rawHtml}</p>` 패턴 절대 사용 금지
- [ ] `dangerouslySetInnerHTML={{ __html: rawHtml }}` (sanitize 없이) 절대 사용 금지
- [ ] import 누락 없는지 확인: `stripHtmlTags`, `sanitizeRichHtml`, `decodeHtmlEntities` from `@/lib/utils`

---

## 6. 기존 코드 감사 패턴 (Audit)

```bash
# raw description 렌더링 (HTML 노출 위험)
grep -rn "\.description}" <project-root>/src --include="*.tsx"

# sanitize 없는 dangerouslySetInnerHTML (XSS 위험)
grep -rn "dangerouslySetInnerHTML" <project-root>/src --include="*.tsx" \
  | grep -v "sanitizeRichHtml\|decodeHtmlEntities\|t\.\|i18n"
```

---

## 하네스 연동

### 단계 0 — 레슨 로드
이 스킬을 사용하는 작업을 시작하기 전에 다음을 읽는다:
- `.agents/learnings/general.md`
- `.agents/learnings/html-render-expert.md` (없으면 생성 후 진행)

관련 레슨을 먼저 적용한 뒤 진행한다.

### 단계 5 — 레슨 기록
작업 완료 후, 다음 경우에 해당하면 `.agents/learnings/html-render-expert.md`에 레슨을 추가한다:
- 새로운 HTML 노출 패턴 발견
- sanitize 누락으로 인한 버그 수정
- 새 유틸 함수 추가 또는 기존 함수 동작 변경

> 레슨이 **3회 이상** 반복되면 → `rules-project.md` 또는 프로젝트 규칙 반영 후보로 승격한다.

### ⛔ 혼자 결정하면 안 되는 사항
- `sanitizeRichHtml` 함수의 정규식 로직 변경 (다수 콘포넌트에 영향)
- `dangerouslySetInnerHTML` 허용 범위 확대 (보안 정책 변경)
