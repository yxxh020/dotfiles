---
name: date-format-expert
description: UI에서 로케일(한국어/영어)에 따라 날짜 포맷을 올바르게 처리하는 전문가 스킬.
---

# 날짜 포맷 전문가 스킬

UI에 표시되는 모든 날짜가 로케일별 포맷 규칙을 올바르게 따르도록 보장하는 `date-format-expert`이다.

## 핵심 규칙

1. **한국어 로케일 (`kr` / `ko`)**:
   - 날짜는 반드시 `YYYY.MM.DD` (년.월.일) 형식으로 표시한다. 예: `1994.05.09` 또는 `1994. 5. 9.`
   - 연, 월, 일 모두 표기하며 구분자는 점(`.`)을 사용한다.

2. **영어 로케일 (`en`)**:
   - 현재 형식을 유지한다 (예: `M/D/YYYY` → `5/9/1994` 또는 표준 형식).

3. **날짜 입력 폼 기본값 및 포커스 지침 (Form Auto-fill & Focus)**:
   - 별도의 명시적 지정이 없는 한, 날짜 입력 폼 생성/오픈 시 **시작일 및 종료일 기본값은 모두 오늘 날짜 및 현재 시각**(`YYYY-MM-DD` 또는 `YYYY.MM.DD`)으로 자동 세팅한다.
   - 모달이나 입력 폼이 렌더링될 때 **날짜 입력 란(시작일 input)에 자동으로 커서(Focus)**가 위치하도록 설정한다.

4. **날짜 입력 UX (8자리 숫자 입력 & 달력 위젯 마우스 선택 동시 지원)**:
   - 키보드로 입력 시 점(`.`) 없이 **숫자 8자리(예: `20260724`)**만 타이핑하면 자동으로 `2026.07.24`로 변환된다.
   - 인풋 우측의 **달력 아이콘(📅)**을 클릭하면 마우스로 날짜를 클릭할 수 있는 **달력 피커 팝업(Date Picker Widget)**이 표시되어 시각적 선택도 동시에 지원한다 (`SmartDatePicker` 패턴).

5. **날짜 무결성 자동 보정 (종료일 ≥ 시작일)**:
   - 시작일이 변경될 때 종료일이 미설정 상태이거나 시작일보다 이전 날짜이면 종료일을 시작일과 동일하게 자동 변경한다.
   - 종료일을 시작일보다 이전 날짜로 선택/입력하려 할 경우 시작일과 동일한 날짜로 자동 교정하여 날짜 역전 현상을 방지한다.

## 실행 지침

- 사용자가 날짜 표시 문제를 수정하거나 리뷰하도록 요청하면, 먼저 해당 페이지의 현재 로케일을 확인한다.
- Next.js App Router에서 `next-intl`을 사용하는 경우, `params` 또는 i18n 훅에서 제공하는 `locale`을 기준으로 포맷 로직을 결정한다.
- 변경 사항이 기존 UI 레이아웃이나 hydration을 깨뜨리지 않는지 반드시 확인한다.

## 구현 예시

```typescript
function formatDate(date: Date | string, locale: string): string {
  const d = new Date(date);
  if (locale === 'kr' || locale === 'ko') {
    const year = d.getFullYear();
    const month = String(d.getMonth() + 1).padStart(2, '0');
    const day = String(d.getDate()).padStart(2, '0');
    return `${year}.${month}.${day}`;
  }
  // 영어 로케일: M/D/YYYY 형식
  return `${d.getMonth() + 1}/${d.getDate()}/${d.getFullYear()}`;
}
```

### ⛔ 단독 결정 금지

- 로케일 폴백 순서 변경 (kr → en 우선순위)
- 프로젝트에 없는 새로운 날짜 형식 패턴 도입
