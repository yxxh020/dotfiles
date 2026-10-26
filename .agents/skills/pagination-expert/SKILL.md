---
name: pagination-expert
description: >
  React/Next.js 기반에서 대용량 데이터 및 전체 페이지 수가 많을 때 UI 가로 나열 깨짐을 방지하는 윈도우드 페이징(Windowed Pagination) 전문가 스킬.
  `1 2 3 ... 3900` 패턴과 같이 첫 페이지, 현재 페이지 주변 윈도우, 줄임표(...), 마지막 페이지를 조합하여 항상 일정한 개수의 버튼만 렌더링한다.
---

> **[안내]** 이 파일은 각 프로젝트가 복사해갈 때 프로젝트 상황에 맞게 수정하여 사용하는 템플릿이다.

# Pagination Expert — 윈도우드 페이징 UI 전문가 스킬

전체 페이지 수(`totalPages`)가 늘어나더라도 페이징 버튼이 `1 2 3 4 5 6 7 8 9 10 11 12 13 14` 와 같이 무분별하게 가로로 길게 늘어져 화면 레이아웃이 깨지거나 잘리는 현상을 방지하고, 항상 일정 개수 이내의 버튼만 깔끔하게 렌더링하는 **윈도우드 페이징(Windowed Pagination)** 패턴 가이드이다.

---

## 1. 안티패턴 vs 모범 사례

### ❌ 안티패턴 (전체 페이지 나열)
```tsx
// ❌ totalPages 수만큼 배열을 만들어 모두 렌더링하면 14개, 100개씩 버튼이 늘어나 레이아웃이 깨짐
{Array.from({ length: totalPages }, (_, i) => i + 1).map((page) => (
  <button key={page}>{page}</button>
))}
```

### ✅ 모범 사례 (`1 2 3 ... 3900` 윈도우드 패턴)
* **최대 버튼 수 제한**: 현재 페이지 주변에 3~5개만 노출 (`maxPagesToShow = 5` 또는 `3`)
* **양끝 페이지 보장**: 첫 페이지(`1`)와 마지막 페이지(`totalPages`)는 항시 접근 가능하도록 노출
* **줄임표(`...`) 삽입**: 첫/마지막 페이지와 윈도우 구간 사이에 간격이 있을 경우 `...` 삽입

---

## 2. 윈도우드 페이징 표준 계산 로직 (React / Next.js)

```tsx
import React from 'react';

interface PaginationProps {
  currentPage: number;
  totalPages: number;
  onPageChange: (page: number) => void;
  maxPagesToShow?: number; // 기본값 5
}

export function WindowedPagination({
  currentPage,
  totalPages,
  onPageChange,
  maxPagesToShow = 5,
}: PaginationProps) {
  if (totalPages <= 1) return null;

  // 1. 윈도우 시작/끝 범위 계산
  let startPage = Math.max(1, currentPage - Math.floor(maxPagesToShow / 2));
  let endPage = startPage + maxPagesToShow - 1;

  if (endPage > totalPages) {
    endPage = totalPages;
    startPage = Math.max(1, endPage - maxPagesToShow + 1);
  }

  // 2. 페이지 요소 배열 생성 (숫자 및 '...')
  const pages: (number | string)[] = [];

  if (startPage > 1) {
    pages.push(1);
    if (startPage > 2) pages.push('...');
  }

  for (let i = startPage; i <= endPage; i++) {
    pages.push(i);
  }

  if (endPage < totalPages) {
    if (endPage < totalPages - 1) pages.push('...');
    pages.push(totalPages);
  }

  return (
    <div className="flex items-center gap-1">
      {/* 이전 페이지 버튼 */}
      <button
        onClick={() => onPageChange(currentPage - 1)}
        disabled={currentPage === 1}
        className="px-3 py-1 text-sm border rounded disabled:opacity-40"
      >
        &lt;
      </button>

      {/* 페이지 번호 및 ... 버튼 */}
      {pages.map((page, index) =>
        typeof page === 'string' ? (
          <span key={`ellipsis-${index}`} className="px-2 text-gray-400 select-none">
            ...
          </span>
        ) : (
          <button
            key={`page-${page}`}
            onClick={() => onPageChange(page)}
            className={`px-3 py-1 text-sm border rounded ${
              page === currentPage
                ? 'bg-blue-600 text-white font-bold border-blue-600'
                : 'hover:bg-gray-100 dark:hover:bg-slate-800'
            }`}
          >
            {page}
          </button>
        )
      )}

      {/* 다음 페이지 버튼 */}
      <button
        onClick={() => onPageChange(currentPage + 1)}
        disabled={currentPage === totalPages}
        className="px-3 py-1 text-sm border rounded disabled:opacity-40"
      >
        &gt;
      </button>
    </div>
  );
}
```

---

## 3. 출력 예시

* **초반 (currentPage = 1, totalPages = 3900)**: `[ 1 ] 2 3 4 5 ... 3900`
* **중간 (currentPage = 100, totalPages = 3900)**: `1 ... 98 99 [ 100 ] 101 102 ... 3900`
* **후반 (currentPage = 3900, totalPages = 3900)**: `1 ... 3896 3897 3898 3899 [ 3900 ]`

---

## 4. UI/UX 모범 사례 검수 항목

- [ ] `totalPages`가 20, 100, 3900 등 대용량 데이터일 때도 버튼 수가 가로로 길게 늘어지지 않는가?
- [ ] 첫 페이지와 마지막 페이지로 즉시 이동할 수 있는가?
- [ ] `...` 요소는 클릭 불가능한 `span` 처리로 불필요한 이벤트 호출을 차단했는가?
- [ ] 현재 선택된 페이지의 시각적 강조(배경색, 볼드)가 명확한가?
