---
name: url-state-sync-expert
description: Next.js App Router에서 UI 상태(탭, 필터 등)를 URL 쿼리 파라미터와 동기화하여 고유 URL을 생성하고 누락된 동기화 지점을 감지하는 전문가 스킬.
---

# URL 상태 동기화 전문가 스킬

Next.js App Router 환경에서 버튼 클릭 시(예: 탭, 필터, 페이지네이션) UI 상태를 URL 쿼리 파라미터와 동기화하여 고유 URL을 생성하고 상태를 유지하는 스킬이다. 페이지 내에서 **누락된 상태 동기화(고유 URL) 요소를 진단·감지하는 분석 기능**도 포함한다.

## 사용 시점
- 사용자가 "버튼 클릭 시 고유 URL 생성", "특정 탭/상태/모달을 URL에 반영", "페이지 새로고침 후에도 선택한 탭 유지"를 요청할 때.
- 사용자가 "이 페이지에서 누락된 URL 동기화 지점 찾아줘" 또는 "고유 URL 매핑이 필요한 버튼/모달 감지"를 요청할 때.
- 관리자 또는 사용자 페이지(예: 모달, 다이얼로그, 탭, 필터)에서 누락된 상태 공유를 감지·동기화할 때.

---

## 1. 누락 동기화 감지 및 감사

페이지나 컴포넌트 내에서 누락된 고유 URL 동기화 지점을 찾으려면 다음을 분석한다:

1. **로컬 상태(`useState`) 검사**
   - `useState`가 UI 활성 상태, 탭, 또는 필터 조건 변경에 사용되는지 확인한다.
   - 예: `const [activeTab, setActiveTab] = useState('summary')`
   - 이 상태가 새로고침 시 초기화되거나 URL에 반영되지 않으면 → **누락된 동기화 대상**.

2. **UI 컨트롤 요소 검사**
   - `<button>`, `<a>`, `<Tabs>`, `<Select>` 등이 로컬 상태 변경만 수행하는 `onClick` 또는 `onValueChange` 핸들러를 가지는지 확인한다.
   - 예: `onClick={() => setCategory(item.id)}` (URL 변경 코드 없음 → **누락된 동기화 대상**)

3. **`next/navigation` 모듈 사용 여부 확인**
   - `useSearchParams`, `useRouter`, `usePathname` 훅이 임포트되어 사용되는지 확인한다.
   - 중요한 인터랙션(탭/필터)이 있으나 이 훅을 임포트하지 않은 파일 → **잠재적 누락 동기화 대상**.

---

## 2. 구현 지침 (Next.js App Router)

1. **URL 쿼리로 상태 관리 (`useSearchParams`, `usePathname`, `useRouter`)**
   - 클라이언트 컴포넌트(`"use client"`)에서 `next/navigation`의 훅을 사용한다.

2. **`createQueryString` 유틸 함수 사용**
   ```typescript
   import { useCallback } from 'react';
   import { usePathname, useRouter, useSearchParams } from 'next/navigation';

   const router = useRouter();
   const pathname = usePathname();
   const searchParams = useSearchParams();

   const createQueryString = useCallback(
     (name: string, value: string) => {
       const params = new URLSearchParams(searchParams.toString());
       if (value) {
         params.set(name, value);
       } else {
         params.delete(name);
       }
       return params.toString();
     },
     [searchParams]
   );
   ```

3. **이벤트 핸들러 (버튼 클릭 시 URL 변경)**
   ```typescript
   const handleTabClick = (tabId: string) => {
     router.push(`${pathname}?${createQueryString('tab', tabId)}`, { scroll: false });
   };
   ```

4. **초기 상태 렌더링**
   ```typescript
   const currentTab = searchParams.get('tab') || 'defaultTab';
   ```

---

## 3. 에이전트 실행 프로세스

1. **Step 1: 스캔 & 감사** — 지정된 컴포넌트나 디렉터리 내 파일을 읽고 `useState` 사용, 버튼 이벤트 리스너, 탭 라이브러리 사용 등을 분석한다. 고유 URL 동기화가 누락된 버튼/탭을 근거와 함께 보고한다.
2. **Step 2: 설계 & 승인** — 감지된 누락 동기화 지점에 할당할 쿼리 파라미터 이름(예: `tab`, `filter`, `page`)을 설계하고 사용자에게 먼저 제시한다.
3. **Step 3: `next/navigation` 훅 도입 & 리팩터링** — 승인된 설계대로 `useState` 기반 코드를 `useSearchParams` 기반으로 리팩터링한다.
4. **Step 4: 결과 검증** — 변경 사항을 저장하고 브라우저에서 해당 버튼 클릭 시 URL이 동적으로 변경되는지 확인한다.

## 참고 사항
- 쿼리 파라미터 변경 시 불필요한 스크롤 방지를 위해 `router.push(..., { scroll: false })` 옵션 사용을 강력 권장한다.
- 서버 컴포넌트(`page.tsx`)에서 쿼리 파라미터를 받아 클라이언트 컴포넌트에 초기 props로 전달하는 패턴도 상황에 따라 유용하다. (Next.js 15+에서 `searchParams`는 Promise일 수 있음)

---

## 4. 고급 패턴 — 탭 동기화

### 초기 로드 (URL → 상태)

```typescript
const searchParams = useSearchParams();
const initialTab = searchParams.get('tab') || 'default-tab';
const [activeTab, setActiveTab] = useState<string>(initialTab);
```

### 상태 변경 (상태 → URL)

```typescript
const handleTabChange = (tabId: string) => {
  setActiveTab(tabId);
  const params = new URLSearchParams(searchParams.toString());
  params.set('tab', tabId);
  // 탭 히스토리 앞/뒤 이동이 필요하면 router.push, 히스토리 오염 방지는 router.replace
  router.push(`${pathname}?${params.toString()}`, { scroll: false });
};
```

### `useEffect`를 통한 동기화 (선택 사항, 권장)

브라우저 앞으로/뒤로 버튼으로 URL이 변경될 때 로컬 상태도 반영한다.

```typescript
useEffect(() => {
  const currentTab = searchParams.get('tab') || 'default-tab';
  if (currentTab !== activeTab) {
    setActiveTab(currentTab);
  }
}, [searchParams, activeTab]);
```

---

## 5. 다중 선택 필터 (`Set<string>`) 동기화 패턴

여러 항목을 동시에 켜고 끄는 **토글 pill / 체크박스 필터**를 URL과 동기화할 때 사용한다.
쉼표(`,`) 구분 문자열로 직렬화한다. (예: `?status=OPEN,IN_PROGRESS,ON_HOLD`)

### 5-1. URL 파라미터 형식

```
?status=OPEN,IN_PROGRESS,ON_HOLD
```

- 복수 값은 쉼표(`,`) 구분, 순서 무관
- 파라미터 없으면 기본값 사용
- 유효하지 않은 값은 파싱 시 자동 제거

### 5-2. 파서 헬퍼 (컴포넌트 외부에 선언)

```typescript
const ALL_STATUSES = ["OPEN", "IN_PROGRESS", "ON_HOLD", "CLOSED"] as const;
const DEFAULT_ACTIVE_STATUSES = ["OPEN", "IN_PROGRESS", "ON_HOLD"];

/** URL ?status= 문자열 → Set<string>. 유효하지 않은 값 자동 제거 */
function parseStatusParam(param: string | null): Set<string> {
  if (!param) return new Set(DEFAULT_ACTIVE_STATUSES);
  const parsed = param.split(",").filter((s) => (ALL_STATUSES as readonly string[]).includes(s));
  return parsed.length > 0 ? new Set(parsed) : new Set(DEFAULT_ACTIVE_STATUSES);
}
```

### 5-3. 컴포넌트 내부 전체 패턴

```typescript
// ① 초기값: URL 파라미터에서 읽기 (lazy initializer)
const [activeStatuses, setActiveStatuses] = useState<Set<string>>(
  () => parseStatusParam(searchParams?.get("status"))
);

// ② 브라우저 뒤로가기 등으로 URL이 바뀌면 상태 동기화
useEffect(() => {
  setActiveStatuses(parseStatusParam(searchParams?.get("status")));
}, [searchParams]);

// ③ Set → URL 업데이트 헬퍼 (기존 파라미터 보존)
const pushStatusToUrl = useCallback(
  (next: Set<string>) => {
    const params = new URLSearchParams(searchParams.toString());
    params.set("status", [...next].join(","));
    router.replace(`${pathname}?${params.toString()}`, { scroll: false });
  },
  [searchParams, pathname, router]
);

// ④ 토글 핸들러 — setState 콜백 안에서 직접 URL push하지 않음 (React strict mode double-invoke 방지)
const toggleStatus = (status: string) => {
  setActiveStatuses((prev) => {
    if (prev.has(status) && prev.size === 1) return prev; // 마지막 하나 해제 불가
    const next = new Set(prev);
    if (next.has(status)) {
      next.delete(status);
    } else {
      next.add(status);
    }
    setTimeout(() => pushStatusToUrl(next), 0); // microtask 이후 URL 갱신
    return next;
  });
};

// ⑤ 전체 선택 / 초기화 버튼
const isAllSelected = activeStatuses.size === ALL_STATUSES.length;

const handleToggleAll = () => {
  const next = isAllSelected
    ? new Set<string>(DEFAULT_ACTIVE_STATUSES)
    : new Set<string>(ALL_STATUSES);
  setActiveStatuses(next);
  pushStatusToUrl(next);
};
```

### 5-4. 핵심 주의사항

| 항목 | 규칙 |
|------|------|
| **setState 콜백 내 URL push** | `setTimeout(() => pushStatusToUrl(next), 0)` 패턴 사용. 콜백 내부에서 직접 호출하면 React strict mode에서 이중 실행 가능 |
| **setState 밖에서 URL push** | 직접 `pushStatusToUrl(next)` 호출 가능 (전체/초기화 버튼 등) |
| **최소 선택 보장** | `prev.size === 1`일 때 해제 시도 → `return prev` (URL 갱신 없음) |
| **router.replace vs push** | 필터 토글은 히스토리 스택 오염을 막기 위해 **`replace`** 사용 |
| **파라미터 보존** | `new URLSearchParams(searchParams.toString())`으로 기존 파라미터(`tab`, `id` 등)를 유지한 채 타겟 파라미터만 갱신 |

---

## 관련 스킬

| 스킬 | 연관 상황 |
|------|-----------| 
| `list-navigation-expert` | URL 필터 파라미터가 적용된 상태에서 상세 페이지의 이전/다음 네비게이션이 필터를 존중해야 할 때 |

### ⛔ 단독 결정 금지

- 기존에 북마크된 URL을 깨뜨릴 수 있는 URL 쿼리 파라미터 추가
- 검토 없이 히스토리 push/replace 전략 변경
