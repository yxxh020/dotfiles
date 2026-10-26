---
name: admin-tab-count-expert
description: UI 혼동이나 API 병목 없이 어드민 레이아웃의 탭별 동적 항목 수를 렌더링하는 성능 & UI 전문가 스킬.
---

# 탭 카운트 렌더링 전문가 스킬

어드민 레이아웃에서 탭별 항목 수(count)를 동적으로 렌더링할 때 UI 차단, 성능 저하(N+1 쿼리), 단축키 뱃지와의 UX 혼동을 방지하는 전문 스킬이다.

## 1. 역할과 전문성

성능 및 UI 최적화 전문가이다. 탭 항목 수를 표시하는 과정이 초기 페이지 로드 속도를 저하시키지 않도록, 그리고 카운트 시각 표현이 키보드 단축키 뱃지와 혼동되지 않도록 보장한다.

## 2. 핵심 원칙

### 2.1 비동기 렌더링 & 지연 로딩

- **UI 차단 금지**: 탭 카운트를 기다리며 페이지 초기 렌더를 절대 차단하지 않는다. UI를 즉시 렌더링한다.
- **지연 렌더링**: 카운트를 가져오는 데 시간이 걸리면(예: 무거운 백엔드 쿼리), 초기 카운트 값은 `undefined`로 둔다. 데이터가 도착한 후에만 UI에 카운트를 추가한다.
- **N+1 쿼리 방지**: 무거운 데이터 탭의 카운트를 비활성 상태에서 동시에 가져오지 않는다. 개별 API 호출이 필요한 경우 **활성 탭**의 카운트만 가져오거나, 경량 집계 메타데이터 API를 통해 일괄 처리한다.
- **하드코딩 금지**: 동적 데이터 목록의 카운트를 매직 넘버로 절대 하드코딩하지 않는다.

### 2.2 시각적 분리 (Anti-Confusion UI)

- **괄호 전용**: 항목 수는 반드시 레이블 옆에 괄호로 감싼 평문으로 표시한다 (예: `(5)`).
- **뱃지 금지**: 항목 수를 표시할 때 시각적 뱃지, 원형, 컬러 pill을 절대 사용하지 않는다. 이 요소들은 키보드 단축키 힌트 컴포넌트(예: `ShortcutBubble`)와 심각한 UX 혼동을 일으킨다.

## 3. 운영 지침

1. 데이터 페칭 전략(예: `useSWR`)을 확인한다. `data`가 `undefined`(로딩 중)이면 `count`를 `undefined`로 유지한다.
2. 데이터 페칭 완료 후 `count: data.length` 또는 `count: data.totalCount`를 할당한다.
3. `TabGroup` 또는 내비게이션 컴포넌트가 카운트를 괄호로 렌더링하는지 확인한다 (예: `({tab.count})`).

## 4. 구현 예시

```tsx
// 탭 정의 예시
const tabs = [
  { id: 'active', label: '활성', count: undefined as number | undefined },
  { id: 'pending', label: '대기 중', count: undefined as number | undefined },
];

// useSWR로 비동기 카운트 로드
const { data } = useSWR('/api/items/counts');

// 데이터 도착 후 카운트 반영
const tabsWithCount = tabs.map(tab => ({
  ...tab,
  count: data?.[tab.id],
}));

// 렌더링 — 반드시 괄호 평문 사용
<TabGroup tabs={tabsWithCount.map(tab => ({
  ...tab,
  label: tab.count !== undefined ? `${tab.label} (${tab.count})` : tab.label,
}))} />
```

### ⛔ 단독 결정 금지

- 어떤 역할에 어떤 탭을 표시/숨길지 결정
- 청구나 규정 준수 보고서에 영향을 주는 카운팅 로직 변경
