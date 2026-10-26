---
name: list-navigation-expert
description: An expert skill for implementing list/board navigation with arrow keys and preserving the selected row state via URL parameters when navigating back (Esc/Back).
---

# 목록 탐색 전문가 스킬

This skill is invoked when designing and implementing keyboard navigation for data tables, lists, or board pages where users can select items and navigate to detail pages.

## 1. Core Concept

For long data lists (e.g., posts, reports, items), users should be able to:
1. Navigate the list using **Arrow Up/Down** keys.
2. Open the selected item's detail page using **Space** or **Enter**.
3. When returning from the detail page (via **Esc** or Back button), directly **return to the previously selected row** (auto-scroll).

## 2. Implementation Pattern

### 2.1 List Page: Keyboard Navigation & State Initialization

On the list page, use `useSearchParams` to read the previously selected ID. Initialize the local `selectedId` state and use `useRef` for auto-scrolling.

```tsx
"use client";
import { useEffect, useState, useRef } from "react";
import { useRouter, useSearchParams } from "next/navigation";

export default function ListPage() {
  const router = useRouter();
  const searchParams = useSearchParams();

  // 1. Initialize selectedId from URL if available
  const [selectedId, setSelectedId] = useState<number | null>(
    searchParams?.get("id") ? Number(searchParams.get("id")) : null
  );
  const itemRefs = useRef<Record<number, HTMLTableRowElement | null>>({});

  // 2. Set default selection if none is selected
  useEffect(() => {
    if (items.length > 0 && selectedId === null) {
      setSelectedId(items[0].id);
    }
  }, [items, selectedId]);

  // 3. Keyboard Event Listener
  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      // Prevent shortcut if typing in an input
      if (
        document.activeElement?.tagName === "INPUT" ||
        document.activeElement?.tagName === "TEXTAREA"
      ) {
        return;
      }
      if (items.length === 0) return;

      if (e.key === "ArrowDown") {
        e.preventDefault();
        setSelectedId((prev) => {
          const currentIndex = items.findIndex((item) => item.id === prev);
          const nextIndex = currentIndex < items.length - 1 ? currentIndex + 1 : currentIndex;
          return items[nextIndex]?.id || prev;
        });
      } else if (e.key === "ArrowUp") {
        e.preventDefault();
        setSelectedId((prev) => {
          const currentIndex = items.findIndex((item) => item.id === prev);
          const nextIndex = currentIndex > 0 ? currentIndex - 1 : 0;
          return items[nextIndex]?.id || prev;
        });
      }

      if (e.key === "Enter" || e.key === " ") {
        if (selectedId) {
          e.preventDefault();
          router.push(`/<locale>/items/${selectedId}`);
        }
      }
    };

    window.addEventListener("keydown", handleKeyDown);
    return () => window.removeEventListener("keydown", handleKeyDown);
  }, [items, selectedId, router]);

  // 4. Auto-scroll to selected row
  useEffect(() => {
    if (selectedId && itemRefs.current[selectedId]) {
      itemRefs.current[selectedId]?.scrollIntoView({ behavior: "smooth", block: "nearest" });
    }
  }, [selectedId]);

  return (
    <tbody>
      {items.map((item) => (
        <tr
          key={item.id}
          ref={(el) => {
            if (el) itemRefs.current[item.id] = el;
          }}
          className={`cursor-pointer transition-colors ${
            selectedId === item.id ? "bg-emerald-50 ring-2 ring-inset ring-emerald-500/50" : ""
          }`}
          onClick={() => {
            setSelectedId(item.id);
            router.push(`/<locale>/items/${item.id}`);
          }}
        >
          {/* Row content */}
        </tr>
      ))}
    </tbody>
  );
}
```

### 2.2 Detail Page: URL Parameter Passing on Exit

On the detail page, when going back to the list page (via the Esc shortcut or the "Back" button), append `?id={currentId}` to the URL.

```tsx
import { useRouter } from "next/navigation";

export default function DetailPage({ item }) {
  const router = useRouter();

  // Escape shortcut (implement with your project's keyboard shortcut hook)
  // onEscape: () => router.push(`/<locale>/items?id=${item.id}`)

  return (
    <button onClick={() => router.push(`/<locale>/items?id=${item.id}`)}>
      Back to List
    </button>
  );
}
```

## 3. Filter-Aware Prev/Next Navigation

**문제:** 목록 페이지에 필터(상태, 카테고리 등)가 적용된 상태에서 상세 페이지로 진입하면, 이전/다음 버튼이 **필터 무시하고 전체 목록 기준**으로 동작하는 버그.

**원인:** 상세 페이지가 API 전체 결과를 그대로 사용하고, 필터 조건을 모름.

**해결 원칙:** URL `?status=` 파라미터를 상세 페이지로 전파하고, 상세 페이지에서 동일한 필터를 적용한 `filteredItems`로 prev/next를 계산한다.

### 3.1 목록 페이지 → 상세 페이지 URL 파라미터 전파

```tsx
// 목록에서 상세 클릭 시
onClick={() => {
  const statusParam = activeStatuses ? [...activeStatuses].join(",") : "";
  router.push(`/<locale>/items/${item.id}?status=${statusParam}`);
}}
```

### 3.2 상세 페이지: filteredItems 파생 및 prev/next 계산

```tsx
import { useSearchParams } from "next/navigation";
import { useMemo } from "react";

const searchParams = useSearchParams();
const statusParam = searchParams?.get("status") ?? "";

const activeStatuses = useMemo<Set<string>>(() => {
  if (!statusParam) return new Set(["OPEN", "IN_PROGRESS"]);
  const parsed = statusParam.split(",").filter((s) => ALL_STATUSES.includes(s as any));
  return parsed.length > 0 ? new Set(parsed) : new Set(["OPEN", "IN_PROGRESS"]);
}, [statusParam]);

const filteredItems = useMemo(
  () => items.filter((i) => activeStatuses.has(i.status)),
  [items, activeStatuses]
);

const currentIndex = currentItem ? filteredItems.findIndex((i) => i.id === currentItem.id) : -1;
const hasPrev = currentIndex > 0;
const hasNext = currentIndex !== -1 && currentIndex < filteredItems.length - 1;
const prevId = hasPrev ? filteredItems[currentIndex - 1].id : null;
const nextId = hasNext ? filteredItems[currentIndex + 1].id : null;
```

### 3.3 URL 빌더 — 모든 이동에서 파라미터 전파

```tsx
/** 목록으로 돌아갈 때: 기존 status 파라미터 유지 */
const buildListUrl = (overrideId?: string | number) => {
  const targetId = overrideId ?? id;
  let url = `/<locale>/items?id=${targetId}`;
  if (statusParam) url += `&status=${statusParam}`;
  return url;
};

/** 이전/다음 상세 이동: status 파라미터 전파 */
const buildDetailUrl = (targetId: number) => {
  let url = `/<locale>/items/${targetId}`;
  if (statusParam) url += `?status=${statusParam}`;
  return url;
};
```

### 3.4 핵심 주의사항

| 항목 | 규칙 |
|------|------|
| **currentIndex 기준** | 전체 배열이 아닌 `filteredItems` 기준으로 계산 |
| **파라미터 없을 때 폴백** | `statusParam`이 빈 문자열이면 기본 필터를 적용 |
| **URL 빌더 함수화** | 하드코딩 금지. `buildListUrl` / `buildDetailUrl` 함수를 항상 사용 |

---

## 사용법 및 실행

- Apply this pattern whenever you create or modify a list/table page where rapid keyboard inspection is needed.
- Differentiate from `keyboard-selection-expert` (used for small modals/dropdowns with 1-9/a-z keys). This skill is for main page lists where the URL state coordinates the back-navigation.

---

## 참고

| 스킬 | 연관 상황 |
|------|-----------|
| [`url-state-sync-expert`](../url-state-sync-expert/SKILL.md) | 목록 필터 상태를 URL에 저장해야 할 때. url-state-sync가 직렬화하면, 이 스킬이 상세 페이지에서 동일 파라미터를 읽어 filteredItems 기준으로 이전/다음을 계산한다. |
| [`keyboard-selection-expert`](../keyboard-selection-expert/SKILL.md) | 방향키 이동에 더해 숫자/알파벳 단축키로 목록 항목을 직접 선택해야 할 때 |

---

## 하네스 연동

### 단계 0 — 레슨 로드
Before starting any task with this skill, read:
- `.agents/learnings/general.md`
- `.agents/learnings/list-navigation-expert.md`

### 단계 5 — 레슨 기록
After completing a significant task, add a lesson if applicable.
