---
name: equal-height-grid-cards
description: 그리드(Grid) 레이아웃 내에서 카드 컴포넌트들의 높이를 균일하게 맞추는(Equal Height) UI 패턴 스킬.
---

# 균일한 높이의 그리드 카드 스킬

Tailwind CSS의 `grid` 레이아웃 안에서 카드 컴포넌트를 나열할 때, 각 카드의 내용(텍스트 길이, 설명 유무 등)이 다르면 높이가 들쭉날쭉해지는 문제가 발생한다. 이를 방지하고 항상 균일한 높이를 유지하기 위한 UI 표준 패턴이다.

## 원인

- `grid` 시스템은 기본적으로 row(행)의 높이를 가장 내용이 많은 자식 요소에 맞춘다(`align-items: stretch`).
- 하지만 자식 요소 내부에 래퍼(wrapper) `div`나 `Card` 컴포넌트가 있을 경우, 해당 요소들이 부모(grid 셀)의 높이를 채우지 않으면 내용은 위로 몰리고 아래쪽 여백이 비어 보이게 된다.

## 해결 방법

### 1. 그리드 아이템 래퍼에 `h-full` 적용

컴포넌트를 감싸는 `div` 컨테이너가 있다면 반드시 `h-full`을 추가하여 그리드 셀의 전체 높이를 차지하게 한다.

```tsx
<div className="grid grid-cols-4 gap-4">
  {items.map(item => (
    <div key={item.id} className="cursor-pointer h-full"> {/* ← 중요: h-full */}
      <CardComponent data={item} />
    </div>
  ))}
</div>
```

### 2. 카드 컴포넌트 최상단에 `h-full` 및 `flex-col` 적용

카드 컴포넌트 자체도 부모의 100% 높이를 가지도록 `h-full`을 선언하고, 내부 요소를 수직으로 배치하기 위해 `flex flex-col`을 사용한다.

```tsx
export const CardComponent = ({ data }) => {
  return (
    <Card className="w-full h-full flex flex-col p-4 border rounded-lg"> {/* ← 중요: h-full flex flex-col */}
      <div>{data.title}</div>
      <p>{data.description}</p>

      {/* 빈 공간을 밀어내고 하단에 고정하고 싶은 요소에 mt-auto 적용 */}
      <div className="flex justify-end mt-auto pt-4">
        <button>액션</button>
      </div>
    </Card>
  );
};
```

## 핵심 규칙 요약

| 클래스 | 역할 |
|--------|------|
| `h-full` | 그리드의 stretch된 높이를 자식 요소 끝까지 전달하기 위해 필수 |
| `flex flex-col` | 카드 내부 레이아웃 구성 (세로 방향 배치) |
| `mt-auto` | 카드 높이가 길어질 때 하단 영역(버튼, 날짜, 아이콘 등)을 항상 맨 아래로 고정 |

## 적용 체크리스트

- [ ] 그리드 아이템 래퍼 `div`에 `h-full`이 적용되어 있는가?
- [ ] 카드 컴포넌트 루트 요소에 `h-full flex flex-col`이 적용되어 있는가?
- [ ] 하단 고정이 필요한 요소(버튼, 날짜 등)에 `mt-auto`가 적용되어 있는가?
- [ ] 다양한 텍스트 길이로 테스트하여 높이 균일성을 확인했는가?
