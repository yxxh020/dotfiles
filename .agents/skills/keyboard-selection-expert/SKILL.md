---
name: keyboard-selection-expert
description: 모달이나 드롭다운에서 1-9, a-z 단축키와 화살표 키를 조합한 고속 키보드 선택 목록 구현 전문가 스킬.
---

# 키보드 선택 전문가 스킬

사용자 선택 모달, 콤보박스, 드롭다운 메뉴 등 고속 키보드 접근이 가능한 선택 목록을 설계·구현할 때 호출하는 스킬이다.

## 1. 핵심 개념

마우스 없이 빠른 선택이 필요한 목록에 표준화된 키보드 단축키 시스템을 적용한다:
- **인덱스 0-8 (1~9번째 항목):** 숫자 키 `1`~`9` 사용.
- **인덱스 9-34 (10~35번째 항목):** 알파벳 키 `a`~`z` 사용.
- **화살표 키:** `ArrowUp`과 `ArrowDown`으로 목록 위/아래 탐색.
- **Enter/Esc:** `Enter`로 선택 확인, `Esc`로 모달 닫기.

## 2. 구현 패턴

이 스킬을 적용할 때 대상 컴포넌트에 다음 로직이 구현되어야 한다:

### 2.1 Keydown 이벤트 리스너 (전역 또는 범위 지정)
단축키를 안전하게 처리하는 keydown 이벤트 리스너를 연결한다. **중요:** `ArrowDown`이 'a'로 시작하여 `a-z` 로직을 트리거하는 것을 방지하기 위해 항상 `key.length === 1`을 확인한다.

```typescript
useEffect(() => {
  const handleKeyDown = (e: KeyboardEvent) => {
    if (items.length === 0) return;

    // 1. 1-9 단축키 처리
    if (e.key >= "1" && e.key <= "9") {
      const index = parseInt(e.key, 10) - 1;
      if (index >= 0 && index < items.length) {
        e.preventDefault();
        onSelect(items[index].id);
        return;
      }
    }

    // 2. a-z 단축키 처리
    const key = e.key.toLowerCase();
    if (key.length === 1 && key >= "a" && key <= "z") {
      const index = key.charCodeAt(0) - 97 + 9;
      if (index >= 9 && index < items.length) {
        e.preventDefault();
        onSelect(items[index].id);
        return;
      }
    }

    // 3. 화살표 키 처리
    if (e.key === "ArrowDown") {
      e.preventDefault();
      setSelectedItem((prev) => /* 다음 인덱스 로직 */);
    } else if (e.key === "ArrowUp") {
      e.preventDefault();
      setSelectedItem((prev) => /* 이전 인덱스 로직 */);
    }

    // 4. Enter 처리
    if (e.key === "Enter") {
      e.preventDefault();
      // selectedItem에 대해 확인 트리거
    }
  };

  window.addEventListener("keydown", handleKeyDown);
  return () => window.removeEventListener("keydown", handleKeyDown);
}, [items, onSelect]);
```

### 2.2 시각적 단서 (배지)
항목 라벨 옆에 단축키를 나타내는 작은 배지를 렌더링한다.
```tsx
{index < 35 && (
  <div className="flex-none w-5 h-5 rounded flex items-center justify-center bg-gray-200 dark:bg-gray-600 text-xs font-bold mr-2">
    {index < 9 ? index + 1 : String.fromCharCode(97 + index - 9)}
  </div>
)}
```

### 2.3 자동 스크롤
화살표 키 사용 시 선택된 항목이 화면에 보이도록 자동 스크롤한다.
```tsx
itemRefs.current[selectedId]?.scrollIntoView({ behavior: "smooth", block: "nearest" });
```

### 2.4 도움말 텍스트
모달/목록 하단에 단축키 안내 텍스트를 항상 렌더링한다.
> 💡 팁: 리스트 앞의 **번호/알파벳**을 눌러 바로 선택할 수 있어요.
> 💡 팁: **방향키(↑, ↓)**로 이동 후 **엔터(Enter)**로 선택하거나, **Esc**로 창을 닫을 수 있어요.

## 3. 사용법 및 실행
- 사용자가 "키보드 선택 적용" 또는 "목록에 단축키 추가"를 요청하면 즉시 이 패턴을 적용한다.
- `ArrowDown` 버그를 방지하기 위해 `key.length === 1` 검사가 **항상** 포함되어야 한다.

## 관련 스킬

| 스킬 | 연관 상황 |
|------|-----------|
| [`ui-shortcut-expert`](../ui-shortcut-expert/SKILL.md) | 전역·계층적(GNB) 단축키 시스템 설계, 모달 단축키 충돌 차단 |
| [`show-bottom-tip`](../show-bottom-tip/SKILL.md) | 하단 단축키 안내 텍스트(§2.4)의 표준 시각 스타일 |
| [`list-navigation-expert`](../list-navigation-expert/SKILL.md) | 방향키 목록 탐색 + URL 파라미터로 선택 상태 보존 |
