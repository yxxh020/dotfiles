---
name: ui-shortcut-expert
description: 프리미엄 UI 단축키 시스템 설계·구현 전문가 스킬. 오버레이 토글, 계층적 GNB 탐색, 모달 충돌 차단, 포커스 트랩 해결 패턴을 제공한다.
---

> **[안내]** 이 파일은 각 프로젝트가 복사해갈 때 프로젝트 상황에 맞게 수정하여 사용하는 스킬 템플릿이다.
> 특히 §3(계층적 단축키 시스템)의 섹션 키, §6.1(예약 키 목록), 구현 파일 경로는 프로젝트에 맞게 교체한다.
> 적용 시 이 안내 문구를 제거하고 내용을 수정한다.

# UI 단축키 전문가

프리미엄 버블 단축키 시스템을 설계·구현하는 전문 스킬이다. 사용자의 인지 부하를 최소화하고 화면의 심미성을 극대화하는 단축키 오버레이 설계를 우선시한다.

## 1. 역할과 전문성

최상위 UI/UX 설계자이자 사용자 경험 전문가이다.
사용자의 인지 부하를 최소화하고 화면의 심미성을 극대화하는 '단축키 오버레이' 설계를 우선시한다.

## 2. 디자인 기준

- **프리미엄 Kbd 버블**: 다크모드 기반, 광택 효과, 미세한 그림자, monospace 폰트(`font-mono`) 적용.
- **카운터 vs 단축키 시각 분리**:
  - UX 혼동 방지를 위해 항목 수(count)에 뱃지 스타일 시각 요소를 절대 사용하지 않는다.
  - 항목 수는 레이블 옆에 괄호로 감싼 평문으로 표시한다 (예: `(5)`).
  - 버블 뱃지(`ShortcutBubble`)는 키보드 단축키 힌트(keycap 스타일)에만 사용한다.
- **전역 토글**: 단일 `Alt` 키(또는 `Ctrl+/` 폴백)로 화면 전체의 단축키 힌트를 토글하며, 활성 상태에서 단일 키 입력(`1`, `f` 등)으로 150ms 이내에 즉각 반응한다.
- **응답성 & 스냅**: 높은 강성의 애니메이션으로 불필요한 바운싱 없이 스냅감을 제공한다.

## 3. 계층적 단축키 시스템 (2단계 GNB 탐색)

GNB(전역 내비게이션 바)는 **2단계 계층적 단축키** 시스템을 사용한다.

### 1단계 — 섹션 키 (Q, W, E, R, T, Y, U 등)

단축키 오버레이 활성 상태에서 GNB 섹션 키를 누르면 첫 번째 하위 링크로 직접 이동하지 않고 해당 드롭다운 메뉴를 연다.

- 섹션이 열려 있는 동안(`openSectionIndex !== null`) 오버레이 자동 닫힘 타이머가 **일시 정지**된다.
- `Escape`로 열린 드롭다운을 닫으면 **1단계 오버레이 상태로 돌아간다** (오버레이를 완전히 닫지 않음).

### 2단계 — 숫자 키 (1, 2, 3 ... 9)

섹션의 드롭다운이 열리면 숫자 키로 해당 하위 링크로 이동하고 드롭다운과 오버레이를 모두 닫는다.

```
Alt / Ctrl+/
  → 오버레이 ON (GNB 버블 표시)

  → [Q] 눌림 (예: 첫 번째 섹션)
      → 드롭다운 열림 + 하위 항목에 번호 버블 1, 2, 3... 표시
      → [1] → 첫 번째 하위 항목
      → [2] → 두 번째 하위 항목
      → [Escape] → 드롭다운 닫기, 오버레이 유지

  → [L] → 로그인/로그아웃
  → [F] → 검색 입력 포커스
  → [Escape] → 오버레이 OFF
```

### 구현 파일 구조 예시

| 파일 | 담당 역할 |
| :--- | :--- |
| `src/store/use-shortcut-store.ts` | 전역 상태: `isOverlayOpen`, `openSectionIndex`, `modalOpenCount`, `openModal`, `closeModal` |
| `src/hooks/use-shortcut-overlay.ts` | 2단계 키보드 이벤트 핸들러 |
| `src/components/nav.tsx` | `subMenus` 배열 구성; 드롭다운 내 `ShortcutBubble` 렌더링 |
| `src/components/ui/shortcut-bubble.tsx` | `isOverlayOpen` 상태일 때 keycap 버블 렌더링 |

### 훅 API 예시

```ts
// 전역 상태 인터페이스
interface ShortcutState {
  isOverlayOpen: boolean;
  openSectionIndex: number | null;
  modalOpenCount: number;     // 0 이상. 0보다 크면 모든 훅에서 Alt 토글/단축키 차단
  openModal: () => void;      // isOverlayOpen을 즉시 false로 닫고 카운터 +1
  closeModal: () => void;     // 카운터 -1 (최소 0)
  isAnyModalOpen: () => boolean;
}

// 훅 API
useShortcutOverlay(
  actions: ShortcutAction[],
  subMenus?: SubMenuAction[],
  isModalOpen?: boolean   // true이면 openModal() 호출 → 모든 훅 차단
)
```

## 4. 모달/다이얼로그 단축키 차단 (핵심 패턴)

**모달이 열릴 때 배경 단축키를 완전히 차단**해야 한다. 반드시 아래 패턴을 따른다.

### 왜 단순 `disabled` prop으로는 부족한가

`useShortcutOverlay`는 여러 컴포넌트(사이드바, 각 페이지)에서 **각자** `window`에 리스너를 등록한다.
특정 페이지의 훅에만 `disabled=true`를 전달하면 사이드바 등 다른 훅 인스턴스의 리스너가 여전히 살아있어 Alt를 누르면 모달 뒤에 오버레이가 다시 나타난다.

### 올바른 구현 — Store 기반 전역 차단

```
✅ 올바른 구조:
   store.modalOpenCount 가 0보다 크면
   모든 훅 인스턴스의 handleKeyDown 첫 줄에서 return
   → 사이드바 포함 어떤 훅도 Alt / 단축키에 반응하지 않음
```

```tsx
// 부모 페이지
const [showModal, setShowModal] = useState(false);

// isModalOpen 전달 → 내부에서 openModal() / closeModal() 자동 호출
useShortcutOverlay(pageShortcuts, [], showModal);
```

```ts
// use-shortcut-overlay.ts 내부
useEffect(() => {
  if (isModalOpen) {
    openModal();
    return () => closeModal();
  }
}, [isModalOpen, openModal, closeModal]);

const handleKeyDown = useCallback((e: KeyboardEvent) => {
  if (modalOpenCount > 0) return; // 모든 훅 인스턴스가 여기서 차단됨
  // ... 이하 기존 로직
}, [modalOpenCount, ...]);
```

### 체크리스트

- [ ] 모달을 여는 모든 페이지에서 `useShortcutOverlay(..., [], isModalOpen)` 전달
- [ ] 모달 내부 컴포넌트가 `useShortcutOverlay`를 직접 사용하는 경우 → `isModalOpen=false`(기본값)로 두어 모달 내 단축키 정상 동작
- [ ] **절대로** 페이지 단독으로만 `disabled`/`isModalOpen` 처리하지 말 것 — 사이드바 등 다른 훅 인스턴스까지 차단해야 하므로 반드시 store 카운터를 경유

## 5. 계층적 단축키 할당 규칙

페이지 또는 메뉴에 단축키를 할당할 때, 최상위 GNB/LNB 탭에만 제한하지 않는다.
하위 탭, 필터 버튼, 주요 액션 버튼을 포함하여 모든 하위 수준 컨트롤 요소에 포괄적으로 단축키를 할당한다.

키 할당 시 충돌 방지:

- **자주 사용하는 주요 동작** — 직관적인 영문자:
  - 검색/찾기 입력: `"F"` (Focus/Find)
  - 저장/제출/확인 버튼: `"S"` (Save/Submit)
  - 취소/지우기/닫기 버튼: `"C"` (Cancel/Close/Clear)
  - 신규/추가 동작: `"N"` (New/Add)
- **일회성 또는 페이지별 컨트롤** — 시각적 레이아웃 순서대로 `"1"`부터 순차 숫자.
- **컨트롤이 10개를 초과하는 경우**: `"0"` 이후 직관적인 알파벳으로 폴백.

### 부모-자식 단축키 충돌 해결 원칙

> [!IMPORTANT]
> **레이아웃 탭에도 반드시 단축키를 부여한다.**
> 탭 단축키를 생략하면 키보드 탐색이 불완전해진다.

| 상황 | 해결 전략 |
| :--- | :--- |
| 부모 레이아웃 탭이 1/2/3/4 사용, 자식 내부 탭도 1/2/3 필요 | **자식 탭을 알파벳으로** (예: A/O/R) |
| 자식 페이지 컨트롤이 1/2/3/4 사용, 부모 탭도 1/2 필요 | **부모 탭을 수열 연장**으로 (예: 5/6) |
| 충돌 키가 없는 경우 | 양쪽 모두 순서대로 숫자 할당 |

## 6. 관리자 사이드바 단축키 충돌 — 의무 게이트

> [!CAUTION]
> **어드민 하위 페이지에 단축키를 추가·수정할 때 반드시 거쳐야 하는 의무 검증이다.**
> 아래 예약 키를 페이지 레이어에서 사용하면 사이드바와 페이지 리스너가 동시에 실행되어 의도하지 않은 페이지 이동이 발생한다.

### 6.1 예약 키 목록 정의 방법

프로젝트의 관리자 사이드바(`sidebar.tsx` 등)가 전역 점유하는 키 목록을 명시적으로 정의한다.
예시:
```
ADMIN_RESERVED_KEYS = D, L, K, I, C, M, S, T, H, Q, B
```

### 6.2 안전한 대체 키 (Safe Alternatives)

예약 키와 충돌할 때 아래 우선순위에서 대체 키를 선택한다:

| 대체 키 | 연상 의미 |
| :--- | :--- |
| `R` | Resolve / Reset |
| `V` | saVe / View |
| `A` | Apply / Approve |
| `O` | Open / Options |
| `X` | eXit / eXecute |
| `G` | Go / Get |
| `E` | Edit / Expand |
| `W` | Write / Wrap |

### 6.3 예외: 모달 내부에서의 사용

> [!NOTE]
> 예약 키를 사용할 수 있는 **유일한 예외**는 해당 컴포넌트가 **모달(`isModalOpen=true`) 안에 마운트**되는 경우이다.
> 모달이 열리면 `modalOpenCount > 0`이 되어 사이드바 리스너가 차단되므로 충돌하지 않는다.

## 7. 운영 지침

> [!IMPORTANT]
> **어드민 하위 페이지(`/admin/**`)에 단축키를 추가할 때, 사전에 반드시 예약 키 충돌 검증(§6.1)을 수행해야 한다.**

0. **[사전 검증] 예약 키 충돌 확인** — 할당하려는 키가 예약 키 목록에 포함되는지 확인한다. 충돌 발견 시 §6.2의 대체 키를 선택한다.
1. 기존 단축키 시스템(`shortcuts.md` 등)과 충돌 여부를 확인한다.
2. GNB 탐색 단축키는 항상 2단계 시스템을 사용한다 — 첫 번째 키 입력에서 직접 이동하지 않는다.
3. 상위 수준과 하위 수준 메뉴/필터 단축키가 구현 설계에 빠짐없이 포함되어야 한다.
4. `shortcuts.md`에 새로운 단축키 할당을 반드시 업데이트한다.
5. **모달을 열거나 다이얼로그를 표시하는 모든 페이지는 반드시 §4의 Modal Blocking 패턴을 적용한다.**

## 8. 단축키 충돌 & 포커스 트랩 해결 (모범 사례)

### 활성화 조건

다음 상황에서 이 섹션의 로직을 적용한다:
- 사용자가 "단축키 충돌"을 보고할 때.
- 사용자가 "포커스 갇힘" 또는 입력 필드 안에 갇혀 단축키가 동작하지 않는다고 할 때.
- 전역 `keydown` 이벤트 리스너에 입력 검증이 누락된 것을 발견했을 때.
- 모달 뒤에 배경 단축키 버블이 보인다고 보고받을 때.

### 세 가지 핵심 원칙

1. **"포커스 트랩" 회피 (조기 반환 안티패턴)**
   전역 keydown 리스너 최상단에 `if (document.activeElement.tagName === 'INPUT') return;`을 맹목적으로 배치하지 않는다.
   이 패턴은 입력 필드에 포커스가 있을 때 `Alt`(메뉴 열기), `Escape`(닫기) 같은 시스템 수준 단축키까지 차단한다.

2. **"단축키 모드" 중 타이핑보다 단축키 우선**
   단축키 오버레이가 열려 있는 동안 유효한 단축키 키를 누르면 동작을 실행하고 즉시 `e.preventDefault()`를 호출한다.
   이렇게 하면 포커스된 검색바/입력 필드에 키가 입력되지 않는다.

3. **비활성화 시 전역 상태 리셋**
   이벤트 리스너를 제거하는 것만으로는 부족하다 — `isOverlayOpen` 상태가 남아 ShortcutBubble이 계속 렌더링된다.
   `disabled` 상태를 감시하는 전용 `useEffect`에서 반드시 `setOverlay(false)`를 호출한다.

## 9. 오버레이 노출 패턴 (Alt 활성 시 UI 자동 노출)

Alt 오버레이가 켜지는 순간, 사용자가 어떤 단축키가 있는지 한 눈에 파악할 수 있도록 관련 UI 요소를 능동적으로 노출한다.

### 패턴 A — 드롭다운 자동 열기

**대상**: Radix UI `Select`, Combobox 등 숨겨진 옵션 목록이 있는 컨트롤

```tsx
const { isOverlayOpen } = useShortcutStore();
const [isSelectOpen, setIsSelectOpen] = useState(false);

useEffect(() => {
  setIsSelectOpen(isOverlayOpen);
}, [isOverlayOpen]);

<Select
  open={isSelectOpen}
  onOpenChange={setIsSelectOpen}
  onValueChange={(value) => {
    handleChange(value);
    setIsSelectOpen(false);
  }}
>
  <SelectContent>
    {options.map((opt, idx) => (
      <SelectItem key={opt.id} value={opt.id}>
        <div className="flex items-center justify-between gap-4 w-full">
          <span>{opt.label}</span>
          <ShortcutBubble shortcut={(idx + 1).toString()} />
        </div>
      </SelectItem>
    ))}
  </SelectContent>
</Select>
```

### 패턴 B — 탭 그룹 링 하이라이트

**대상**: `TabGroup` 등 항상 화면에 노출되는 탭 바

```tsx
const isOverlayOpen = useShortcutStore((state) => state.isOverlayOpen);

<button
  className={`... transition-all ${
    isOverlayOpen && tab.shortcutKey
      ? "ring-2 ring-offset-1 ring-indigo-400 dark:ring-indigo-500"
      : ""
  }`}
>
  <span>{tab.label}</span>
  {tab.shortcutKey && <ShortcutBubble shortcut={tab.shortcutKey} />}
</button>
```

### 패턴 선택 기준

| 상황 | 적용 패턴 |
| :--- | :--- |
| 옵션이 드롭다운/팝업 안에 숨어 있음 | **Pattern A** — Select 자동 열기 |
| 탭/버튼이 항상 화면에 보임 | **Pattern B** — Ring 하이라이트 |
| 모달 내 컨트롤 | 모달 차단 규칙(§4) 우선 적용 후 패턴 선택 |

### 구현 체크리스트

- [ ] `useShortcutStore`를 직접 구독 (`useShortcutOverlay` 훅 경유 불필요)
- [ ] 오버레이 OFF 시 자동으로 닫히거나 하이라이트 해제되는지 확인
- [ ] 옵션 선택/탭 클릭 시 오버레이도 닫히는지 확인 (`setOverlay(false)` or `onOpenChange(false)`)
- [ ] `ShortcutBubble`이 드롭다운 내부에서 정렬 깨지지 않는지 확인 (`flex items-center justify-between`)

## 관련 스킬

| 스킬 | 연관 상황 |
|------|-----------|
| [`keyboard-selection-expert`](../keyboard-selection-expert/SKILL.md) | 모달/드롭다운 내부 목록의 숫자·알파벳 단축키 선택 |
| [`show-bottom-tip`](../show-bottom-tip/SKILL.md) | 화면 하단 단축키 안내 팁의 표준 시각 스타일 |

### ⛔ 단독 결정 금지

- 이미 시스템이 사용 중인 키보드 단축키 재정의
- 활성 모달 내 포커스 트랩 동작 변경

## 10. 프로젝트별 구현 참조

### 서울노회 (prokseoul)

- **단축키 정의 문서 (SSOT)**: `docs/shortcuts.md`
- **구현 파일**:

| 파일 | 역할 |
| :--- | :--- |
| `src/store/use-shortcut-store.ts` | Zustand 전역 상태 (오버레이, 섹션 인덱스, 모달 카운터) |
| `src/hooks/use-shortcut-overlay.ts` | 2단계 키보드 이벤트 핸들러 훅 |
| `src/lib/shortcut-utils.ts` | 한/영 IME 물리키 매핑 유틸 (`matchShortcutKey`) |
| `src/components/ui/shortcut-bubble.tsx` | Framer Motion 애니메이션 버블 뱃지 |
| `src/components/mode-toggle.tsx` | J키 다크모드 토글 연동 |
| `src/components/layout/header.tsx` | F키 검색 모달 연동, 모달 차단 |

### 느티나무 도서관 (project) — 원본 참조

- **단축키 정의 문서 (SSOT)**: `sub-tasks/000-ui/shortcuts.md`
- **구현 파일**:

| 파일 | 역할 |
| :--- | :--- |
| `frontend/src/store/use-shortcut-store.ts` | Zustand 전역 상태 |
| `frontend/src/hooks/use-shortcut-overlay.ts` | 2단계 키보드 이벤트 핸들러 훅 |
| `frontend/src/lib/utils.ts` → `matchShortcutKey()` | 한/영 IME 물리키 매핑 유틸 |
| `frontend/src/components/ui/shortcut-bubble.tsx` | Framer Motion 애니메이션 버블 뱃지 |
| `frontend/src/components/theme-toggle.tsx` | J키 다크모드 토글 연동 |
| `frontend/src/components/nav.tsx` | F키 검색 + GNB 2단계 subMenus 연동 |
