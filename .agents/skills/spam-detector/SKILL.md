---
name: spam-detector
description: 어드민 게시판·댓글에서 DB 스키마 변경 없이 휴리스틱 점수 계산으로 스팸 의심 게시글을 자동 탐지·상단 정렬·강조 표시하는 스킬. Next.js + Prisma 환경에 최적화되어 있으며 다른 스택에도 로직이 재사용 가능하다.
---

# 스팸 탐지 전문가 스킬 (spam-detector)

사용자가 다음 상황을 언급하면 이 스킬을 참조한다:

- 어드민 게시물/댓글 관리 페이지에 스팸 감지 기능을 추가하고 싶다
- 스팸 의심 게시글을 상단에 노출하거나 강조 표시하고 싶다
- DB 컬럼 추가 없이 스팸을 필터링하고 싶다

---

## 1. 핵심 원칙

1. **No-schema 원칙**: DB에 `spamScore` 컬럼을 추가하지 않는다. 데이터를 가져온 뒤 JS/TS로 점수를 계산한다.
2. **휴리스틱 기반**: ML 모델 없이 규칙 기반 점수를 사용한다. 빠르고, 배포 부담이 없으며, 프로젝트 맥락에 맞게 가중치를 조정할 수 있다.
3. **낮은 오탐 우선**: 오탐(정상 글을 스팸으로 분류) 비율을 낮추기 위해 임계값(threshold)을 충분히 높게 설정한다. 기본값 3점.
4. **UI 통합**: 스팸 의심 글은 목록 **상단 정렬** + 주황 배경 + 뱃지로 표시한다. 자동 삭제는 하지 않는다.

---

## 2. 기본 휴리스틱 점수표

`content`는 HTML 태그를 제거한 순수 텍스트 기준으로 계산한다.

| 조건 | 기본 점수 | 조정 가이드 |
|---|---|---|
| 제목에 URL 포함 (`http`, `www`) | **+3** | 교회·공공 사이트는 +2로 낮춰도 무방 |
| 제목 한글 비율 20% 미만 (5자 이상 제목 한정) | **+2** | 영어 중심 커뮤니티라면 비활성화 |
| 제목 5자 미만 | **+2** | 단어형 제목이 허용되는 게시판은 비활성화 |
| 본문 순수 텍스트 30자 미만 | **+2** | 한줄 공지 게시판은 비활성화 |
| 본문 외부 URL 3개 이상 | **+3** | 링크 모음 게시판이면 비활성화 |
| 본문 전화번호 패턴 3개 이상 (`\d{2,4}-\d{3,4}-\d{4}`) | **+2** | — |
| 조회수·댓글 모두 0 (저신뢰도 보조 지표) | **+1** | 단독으로는 스팸 판단 금지 |

**임계값 기본값: 3점**

> 커뮤니티 특성에 따라 임계값을 4~5점으로 올려 오탐을 줄일 수 있다.

---

### 2-1. (선택적) Jev 초고속 스팸 점수 평가 (`--score`)
배치 스크립트나 백엔드 파이프라인에서 `jev` CLI가 활성화되어 있을 경우, 정규식 휴리스틱 외에 0.0 - 1.0 점수 평가를 단일 패스로 병행할 수 있다:

```bash
SPAM_SCORE=$(jev "$TITLE: $PLAIN_TEXT" -s "Evaluate spam likelihood from 0 to 1" -q)
# 예: 0.8 이상이면 스팸 의심으로 분류
```

---

## 3. 참조 구현 (TypeScript)

전체 구현 예시는 [`references/spam-detector.ts`](./references/spam-detector.ts)를 참조한다.

```ts
const SPAM_THRESHOLD = 3

function calcSpamScore(post: { title: string; content: string; viewCount: number; _count: { comments: number } }): number {
  let score = 0
  const title = post.title ?? ""
  const content = post.content ?? ""
  const plainText = content.replace(/<[^>]+>/g, "")

  if (/https?:\/\/|www\./i.test(title)) score += 3
  if (title.length >= 5) {
    const koreanChars = (title.match(/[가-힣]/g) || []).length
    if (koreanChars / title.length < 0.2) score += 2
  }
  if (title.length < 5) score += 2
  if (plainText.length < 30) score += 2
  const urlMatches = content.match(/https?:\/\//gi) || []
  if (urlMatches.length >= 3) score += 3
  const phoneMatches = content.match(/\d{2,4}-\d{3,4}-\d{4}/g) || []
  if (phoneMatches.length >= 3) score += 2
  if (post.viewCount === 0 && post._count.comments === 0) score += 1

  return score
}
```

---

## 4. 정렬 패턴

```ts
const scoredPosts = posts
  .map(p => ({ post: p, spamScore: calcSpamScore(p) }))
  .sort((a, b) => {
    const aIsSpam = a.spamScore >= SPAM_THRESHOLD ? 1 : 0
    const bIsSpam = b.spamScore >= SPAM_THRESHOLD ? 1 : 0
    return bIsSpam - aIsSpam  // 스팸 의심 먼저
  })
```

---

## 5. UI 패턴

### 5-1. 경고 배너 (목록 상단)

```tsx
{spamCount > 0 && (
  <div className="mb-3 flex items-center gap-2 rounded-md bg-orange-50 dark:bg-orange-950/40 px-3 py-2 text-sm text-orange-700 dark:text-orange-300">
    <AlertTriangle className="h-4 w-4 shrink-0" />
    <span>
      <strong>{spamCount}건</strong>의 스팸 의심 게시글이 상단에 표시됩니다. 확인 후 삭제 또는 숨김 처리해라.
    </span>
  </div>
)}
```

### 5-2. 행 강조

```tsx
const rowBg = isSpam
  ? "bg-orange-50 dark:bg-orange-950/30 hover:bg-orange-100 dark:hover:bg-orange-950/50"
  : "hover:bg-muted/50"
```

### 5-3. 뱃지

```tsx
{isSpam && (
  <Badge className="gap-0.5 bg-orange-100 text-orange-700 dark:bg-orange-900 dark:text-orange-300 text-[10px] px-1 py-0">
    <AlertTriangle className="h-2.5 w-2.5" />
    스팸의심
  </Badge>
)}
```

---

## 6. 데이터 조회 시 주의사항

- 스팸 점수 계산에 `content` 필드가 필요하므로 Prisma `select`에 반드시 포함한다.
- 서버 컴포넌트 → 클라이언트 컴포넌트로 전달 시 `Date` 타입을 `.toISOString()`으로 직렬화한다.

```ts
// ✅ 올바른 select 예시
const posts = await prisma.post.findMany({
  where: { isDeleted: false },
  select: {
    id: true,
    title: true,
    content: true,       // ← 스팸 탐지용 필수
    viewCount: true,
    _count: { select: { comments: { where: { isDeleted: false } } } },
    createdAt: true,
    isPublic: true,
    isPinned: true,
    board: { select: { name: true, slug: true } },
    author: { select: { name: true } },
  },
  orderBy: { createdAt: "desc" },
  take: 100,
})
```

---

## 7. 확장 아이디어

| 아이디어 | 설명 |
|---|---|
| 작성자 신뢰도 가중치 | 가입 7일 미만 + 첫 글이면 +1 |
| IP 반복 작성 탐지 | 동일 IP에서 24h 이내 5건 이상 → +3 |
| 형태소 기반 키워드 필터 | "대출", "홍보", "클릭" 등 도메인 특화 단어 포함 시 +2 |
| 신고 누적 가중치 | 사용자 신고 3건 이상 → +3 (isReported 컬럼 필요) |
| 스팸 학습 피드백 루프 | 관리자가 "스팸 아님" 확인 클릭 → 해당 패턴 예외 목록에 추가 |
