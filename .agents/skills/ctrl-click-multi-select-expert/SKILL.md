---
name: ctrl-click-multi-select-expert
description: 필터 목록에서 단일 선택과 Ctrl+클릭 다중 선택(Pill UI 버튼)을 지원하는 고급 필터 인터페이스 구현 전문가 스킬.
---

# Ctrl-Click Multi-Select UI Pattern

이 스킬은 데이터 목록 필터링 시 단일 `<Select>` 드롭다운 대신, 여러 개의 알약(Pill) 형태 버튼을 나열하여 `단일 클릭`과 `Ctrl+Click (다중 선택)`을 지원하는 고급 필터 UI를 구현하기 위한 표준 패턴을 제공합니다.

## 1. 프론트엔드 UI (React / Next.js)

다중 선택 필터를 위한 상태 관리 및 URL 쿼리 파라미터 동기화 패턴입니다.

```tsx
// 1. 상태 상수 및 파싱 함수 정의
const ALL_STATUSES = ["STATUS_A", "STATUS_B", "STATUS_C"] as const;
const DEFAULT_ACTIVE_STATUSES = ["STATUS_A", "STATUS_B"]; // 전체 대신 필요한 기본값 설정 가능

function parseStatusParam(param: string | null): Set<string> {
  if (param === null) return new Set(DEFAULT_ACTIVE_STATUSES);
  if (param === "") return new Set();
  const parsed = param.split(",").filter((s) => (ALL_STATUSES as readonly string[]).includes(s));
  return new Set(parsed);
}

// 2. 상태 색상 맵핑 정의 (Tailwind)
const statusColorMap: Record<string, { active: string; inactive: string }> = {
  STATUS_A: {
    active: "bg-blue-500 text-white border-blue-500 shadow-blue-200 dark:shadow-blue-900/40",
    inactive: "bg-white dark:bg-gray-800 text-blue-600 dark:text-blue-400 border-blue-300 dark:border-blue-700 hover:bg-blue-50 dark:hover:bg-blue-950/30",
  },
  // ...
};

// 3. 컴포넌트 내부 상태 및 동기화 구현
const [activeStatuses, setActiveStatuses] = useState<Set<string>>(() => parseStatusParam(searchParams.get("status")));

useEffect(() => {
  const param = searchParams.get("status");
  setActiveStatuses(parseStatusParam(param));
}, [searchParams]);

const pushStatusToUrl = useCallback((next: Set<string>) => {
  const params = new URLSearchParams(searchParams.toString());
  if (next.size === 0) {
    params.set("status", "");
  } else {
    params.set("status", [...next].join(","));
  }
  params.set("page", "1"); // 필터 변경 시 페이지 초기화
  router.push(`${pathname}?${params.toString()}`, { scroll: false });
}, [searchParams, pathname, router]);

const toggleStatus = (status: string, isMultiSelect?: boolean) => {
  setActiveStatuses((prev) => {
    let next: Set<string>;
    if (isMultiSelect) {
      if (prev.has(status) && prev.size === 1) return prev; // 하나는 무조건 유지되도록
      const nextSet = new Set(prev);
      if (nextSet.has(status)) nextSet.delete(status);
      else nextSet.add(status);
      next = nextSet;
    } else {
      next = new Set([status]);
    }
    setTimeout(() => pushStatusToUrl(next), 0);
    return next;
  });
};

const isAllSelected = activeStatuses.size === ALL_STATUSES.length;
```

## 2. 백엔드 (NestJS + Prisma)

백엔드에서는 콤마로 구분된 상태 문자열을 배열로 파싱하여 쿼리에 적용해야 합니다.

```typescript
// 1. Controller / DTO
@ApiProperty({
  description: '상태 콤마 분리 다중 선택 가능 (예: STATUS_A,STATUS_B)',
  example: 'STATUS_A,STATUS_B',
})
status?: string;

// 2. Service
let statusArray: number[] | undefined;
if (query.status) {
  statusArray = query.status.split(',').map(s => parseToEnumOrNumber(s));
}

// 3. Repository
const where = {
  status: statusArray !== undefined
    ? Array.isArray(statusArray) ? { in: statusArray } : statusArray
    : { notIn: [EXCLUDED_STATUS] }
};
```

이 패턴을 통해 목록 화면에서 명시적이고 직관적인 필터링을 사용자에게 제공할 수 있습니다.
