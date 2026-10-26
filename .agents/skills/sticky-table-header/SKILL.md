---
name: sticky-table-header
description: 모달이나 패널 안의 테이블에서 스크롤 시 헤더(thead/th)가 상단에 고정(sticky)되도록 구현하는 스킬. Table UI 컴포넌트의 overflow 래퍼가 sticky를 무력화하는 문제를 진단하고 해결한다. Use when: "테이블 헤더 고정", "sticky header", "스크롤 헤더 고정", "thead 고정", "분류 관리 헤더" 등을 언급할 때.
---

# Sticky Table Header (테이블 헤더 스크롤 고정)

모달이나 사이드 패널 안의 긴 테이블 목록에서 스크롤 시 헤더 행(순서, 분류명 등)이 상단에 고정되도록 구현하는 패턴입니다.

## 핵심 문제: `<Table>` UI 컴포넌트의 overflow 트랩

Shadcn UI 스타일의 `<Table>` 컴포넌트(`components/ui/table.tsx`)는 내부적으로 `<table>`을 `<div class="overflow-x-auto">`로 감쌉니다:

```tsx
// components/ui/table.tsx — Table 컴포넌트 내부 구조
function Table({ className, ...props }) {
  return (
    <div className="relative w-full overflow-x-auto">  {/* ← 이것이 문제 */}
      <table className={cn("w-full caption-bottom text-sm", className)} {...props} />
    </div>
  );
}
```

**CSS 스펙상 `overflow-x: auto`를 설정하면 `overflow-y`도 자동으로 `auto`로 계산됩니다.**
이로 인해 중간에 **새로운 스크롤 컨텍스트**가 생성되어, `<th>`에 적용한 `sticky top-0`이 바깥 스크롤 컨테이너와 단절되어 작동하지 않습니다.

## 해결 방법

### 1단계: `<Table>` 대신 원시 `<table>` 사용

중간 래퍼 `<div>`를 제거하기 위해, 해당 모달/패널에서만 `<Table>` 컴포넌트 대신 원시 `<table>` 태그를 직접 사용합니다.

```tsx
// ❌ 잘못된 방법 — Table 컴포넌트 사용 시 sticky 무력화
<Table className="min-w-[640px]">

// ✅ 올바른 방법 — 원시 table 태그 직접 사용
<table className="w-full caption-bottom text-sm min-w-[640px]">
```

> **참고**: `<TableHeader>`, `<TableBody>`, `<TableRow>`, `<TableHead>`, `<TableCell>` 등 하위 컴포넌트들은 단순 스타일 래퍼이므로 그대로 사용해도 무방합니다. 문제는 오직 최상위 `<Table>` 컴포넌트의 래퍼 `<div>`뿐입니다.

### 2단계: 모달 레이아웃 구조 (flex 기반)

모달 전체가 스크롤되면 헤더도 같이 밀려 올라갑니다. 반드시 **테이블 영역만 독립적으로 스크롤**되도록 flex 레이아웃을 구성해야 합니다.

```tsx
{/* 모달 바디: overflow-hidden으로 자체 스크롤 차단 */}
<DialogContent className="... max-h-[85vh] overflow-hidden flex flex-col">

  {/* 고정 영역: 제목, 버튼 등 */}
  <DialogHeader>...</DialogHeader>
  <div className="flex flex-col flex-1 min-h-0">
    <div>액션 버튼 영역</div>

    {/* 스크롤 영역: 테이블만 스크롤 */}
    <div className="border ... flex-1 min-h-0 flex flex-col">
      <div className="overflow-y-auto flex-1 min-h-0">
        <table className="w-full caption-bottom text-sm min-w-[640px]">
          <TableHeader>
            <TableRow>
              <TableHead className="sticky top-0 z-10 bg-[#F5F5F5] dark:bg-slate-800
                shadow-[inset_0_-1px_0_rgba(229,231,235,1)]
                dark:shadow-[inset_0_-1px_0_rgba(51,65,85,1)]">
                헤더1
              </TableHead>
              {/* ... */}
            </TableRow>
          </TableHeader>
          <TableBody>
            {/* 데이터 행들 */}
          </TableBody>
        </table>
      </div>
    </div>
  </div>
</DialogContent>
```

### 3단계: `<th>` sticky 스타일 적용

각 `<TableHead>` (`<th>`)에 아래 클래스를 적용합니다:

```
sticky top-0 z-10 bg-[#F5F5F5] dark:bg-slate-800
shadow-[inset_0_-1px_0_rgba(229,231,235,1)]
dark:shadow-[inset_0_-1px_0_rgba(51,65,85,1)]
```

| 클래스 | 역할 |
|--------|------|
| `sticky top-0` | 스크롤 시 상단에 고정 |
| `z-10` | 데이터 행 위에 겹치도록 z-index 설정 |
| `bg-[#F5F5F5] dark:bg-slate-800` | 불투명 배경으로 아래 행이 비치지 않도록 |
| `shadow-[inset_0_-1px_0_...]` | 헤더와 데이터 경계를 시각적으로 구분하는 하단 보더 효과 |

## 체크리스트

- [ ] `<Table>` 대신 원시 `<table>` 태그를 사용했는가?
- [ ] 모달의 `<DialogContent>`에 `overflow-hidden`이 적용되어 있는가? (`overflow-y-auto` ❌)
- [ ] 테이블을 감싸는 스크롤 영역 `<div>`에 `overflow-y-auto flex-1 min-h-0`이 적용되어 있는가?
- [ ] 각 `<TableHead>`에 `sticky top-0 z-10`과 불투명 배경색이 적용되어 있는가?
- [ ] 라이트 모드와 다크 모드 모두에서 헤더 배경이 불투명하게 보이는가?

## ⛔ 주의사항

- **`<Table>` 컴포넌트 자체를 수정하지 마세요.** 프로젝트 전역에서 사용되므로 사이드 이펙트가 큽니다. sticky가 필요한 모달에서만 원시 `<table>`을 사용하세요.
- `<thead>`에 `sticky`를 걸어도 작동하지 않을 수 있습니다. **반드시 `<th>` (TableHead) 개별 셀에 적용**해야 크로스 브라우저 호환이 보장됩니다.
- `min-h-0`을 flex 자식에 빠뜨리면 flex 컨테이너가 내용물을 수축하지 못해 스크롤이 생기지 않습니다.

## See Also

| 스킬 | 연관 상황 |
|------|-----------|
| `dark-mode-expert` | sticky 헤더의 다크 모드 배경색 토큰 결정 시 |
| `equal-height-grid-cards` | 그리드 레이아웃 내 높이 균일화 패턴 |
