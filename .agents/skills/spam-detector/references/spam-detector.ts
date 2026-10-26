/**
 * spam-detector — 휴리스틱 스팸 점수 계산기
 *
 * DB 스키마 변경 없이 JS/TS 런타임에서 게시글의 스팸 가능성을 점수로 산출한다.
 * Next.js App Router (서버/클라이언트 컴포넌트 양쪽에서 사용 가능)
 *
 * 사용법:
 *   import { calcSpamScore, SPAM_THRESHOLD, sortBySpam } from "./spam-detector"
 */

export const SPAM_THRESHOLD = 3

export interface SpamTarget {
  title: string
  content: string
  viewCount: number
  _count: { comments: number }
}

/**
 * 스팸 점수 계산
 * @returns number — 높을수록 스팸 가능성 높음
 */
export function calcSpamScore(post: SpamTarget): number {
  let score = 0
  const title = post.title ?? ""
  const content = post.content ?? ""
  // HTML 태그 제거 후 순수 텍스트 추출
  const plainText = content.replace(/<[^>]+>/g, "")

  // 제목에 URL 포함
  if (/https?:\/\/|www\./i.test(title)) score += 3

  // 제목 한글 비율 20% 미만 (5자 이상 제목에만 적용)
  if (title.length >= 5) {
    const koreanChars = (title.match(/[가-힣]/g) || []).length
    if (koreanChars / title.length < 0.2) score += 2
  }

  // 제목 너무 짧음
  if (title.length < 5) score += 2

  // 본문 순수 텍스트 너무 짧음
  if (plainText.length < 30) score += 2

  // 본문 외부 URL 3개 이상
  const urlMatches = content.match(/https?:\/\//gi) || []
  if (urlMatches.length >= 3) score += 3

  // 본문 전화번호 패턴 3개 이상
  const phoneMatches = content.match(/\d{2,4}-\d{3,4}-\d{4}/g) || []
  if (phoneMatches.length >= 3) score += 2

  // 조회수 · 댓글 모두 0 (저신뢰도 보조 지표)
  if (post.viewCount === 0 && post._count.comments === 0) score += 1

  return score
}

/**
 * 스팸 의심 여부
 */
export function isSuspectedSpam(post: SpamTarget, threshold = SPAM_THRESHOLD): boolean {
  return calcSpamScore(post) >= threshold
}

/**
 * 목록을 스팸 의심 글 우선으로 정렬 (원본 배열 불변)
 */
export function sortBySpam<T extends SpamTarget>(
  items: T[],
  threshold = SPAM_THRESHOLD
): Array<{ item: T; spamScore: number }> {
  return items
    .map((item) => ({ item, spamScore: calcSpamScore(item) }))
    .sort((a, b) => {
      const aFlag = a.spamScore >= threshold ? 1 : 0
      const bFlag = b.spamScore >= threshold ? 1 : 0
      return bFlag - aFlag
    })
}
