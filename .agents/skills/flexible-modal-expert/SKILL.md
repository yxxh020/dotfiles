---
name: flexible-modal-expert
description: Tailwind CSS를 활용한 유연하고 반응형인 모달 레이아웃 설계 전문가 스킬.
---

# 반응형 모달 레이아웃 전문가 스킬

모달(Dialog) 레이아웃을 반응형으로, 화면을 채우도록, 다양한 모니터 크기에서 견고하게 설계·수정할 때 호출하는 스킬이다.

## 1. 핵심 원칙

사용자가 "모달을 확장해줘", "모달을 크게 해줘", "모달 높이/너비 수정" 등을 요청하면 **90% 뷰포트 규칙 + 경계값**을 적용한다.
모달은 화면 공간을 활용하되, 울트라와이드 스크린에서 너무 넓어지거나 작은 화면에서 사용 불가할 정도로 좁아지지 않아야 한다.

## 2. 표준 레이아웃 클래스

`DialogContent`(또는 모달 래퍼)에 다음 Tailwind 유틸리티 조합을 적용한다:

### 2.1 너비 제약
- `w-[90vw]`: 모달을 뷰포트 너비의 90%로 확장한다.
- `min-w-[800px]`: 모달이 800px 미만으로 줄어들지 않도록 보장한다 (내용에 따라 600px 등 조정 가능).
- `max-w-6xl`: 4K 모니터에서 과도하게 넓어지는 것을 방지한다 (약 1152px). 데이터 밀도가 높은 테이블은 `max-w-[1400px]` 사용 가능.

### 2.2 높이 제약
- `h-[90vh]`: 모달을 뷰포트 높이의 90%로 확장한다.
- `min-h-[600px]`: 레이아웃이 찌그러지지 않도록 최소 높이를 보장한다.
- `max-h-[90vh]`: (`h-[90vh]` 사용 시 암묵적으로 적용됨) 오버플로우를 방지한다.

### 2.3 Flex 레이아웃 (스크롤 처리에 필수)
- `flex flex-col`: 모달을 플렉스 컨테이너로 만들어 헤더·내용·푸터를 예측 가능하게 관리한다.

**DialogContent 예시:**
```tsx
<DialogContent className="w-[90vw] min-w-[800px] max-w-6xl h-[90vh] min-h-[600px] flex flex-col">
```

## 3. 내부 콘텐츠 관리 (ScrollArea)

모달이 목록, 테이블, 또는 스크롤이 필요한 대량 콘텐츠를 포함하는 경우:
1. 스크롤 영역을 `flex-1`과 `overflow-hidden`이 적용된 컨테이너로 감싼다.
2. 이렇게 하면 `ScrollArea`(또는 `overflow-y-auto` div)가 헤더와 푸터를 제외한 나머지 공간을 정확히 채운다.

**내부 레이아웃 예시:**
```tsx
<DialogContent className="w-[90vw] min-w-[800px] max-w-6xl h-[90vh] min-h-[600px] flex flex-col">
  <DialogTitle>제목</DialogTitle>

  {/* flex-1 컨테이너가 이 영역을 모달 크기에 맞게 늘어나도록 함 */}
  <div className="flex-1 w-full flex flex-col overflow-hidden">
    <ScrollArea className="flex-1 w-full flex flex-col">
       {/* 긴 목록 / 테이블 */}
    </ScrollArea>
  </div>

  <div className="flex-none p-4 border-t">
    {/* 푸터 / 버튼 */}
  </div>
</DialogContent>
```

## 4. 사용 시점
- 데이터 밀도가 높은 모달(선택 목록, 복잡한 폼 등)이 답답하게 느껴질 때.
- 구형 고정 크기 모달(`max-w-md`, `h-[500px]`)을 현대적 반응형 디자인으로 전환할 때.

### ⛔ 단독 결정 금지
- 프로젝트 전체 모달에 영향을 주는 z-index 기준 변경
- 모달의 Escape 키 핸들러 제거
