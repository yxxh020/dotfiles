---
name: header-layout-expert
description: 아카이브형 서비스(목록/상세 페이지)의 헤더 레이아웃 표준과 클릭 가능한 히어로 컨테이너 인터랙션 패턴을 정의하는 UI/UX 레이아웃 스킬.
---

> **[안내]** 이 파일은 각 프로젝트가 복사해갈 때 프로젝트 상황에 맞게 수정하여 사용하는 스킬 템플릿이다.
> 색상값, 브랜드 컬러, 참조 파일 경로 등을 프로젝트에 맞게 교체하고, 이 안내 문구는 적용 후 제거한다.

# 헤더 레이아웃 & 인터랙션 규격 스킬

아카이브형 서비스(Q&A, 참고 서비스, 게시판 등)의 목록 및 상세 페이지 상단 헤더 레이아웃을 최적화하고, 돌아가기/닫기 인터랙션이 활성화될 때 클릭 가능한 전체 폭(Full-Width) 컨테이너 규칙을 제어한다.

---

## 1. 헤더 레이아웃 최적화 규칙

목록 화면의 가로/세로 공간을 효율적으로 사용하고, 제목이 명확하게 눈에 띄도록 **전체 폭 배경 박스 패턴**을 적용한다.

### 1.1 제목 & 설명 가로 배치 + 배경 박스

- **규칙**: 제목(Title)과 설명문(GuideText)을 가로로 병렬 배치(`md:flex-row items-center justify-between`)하고, 영역 전체를 하나의 부드러운 색상 박스로 감싸 가독성을 극대화한다.
- **스타일 예시**:

```tsx
<div className="w-full flex flex-col md:flex-row items-start md:items-center justify-between mb-8 gap-4 md:gap-8 p-5 md:p-6 bg-<brand>-50 dark:bg-<brand>-900/40 border border-<brand>-200 dark:border-<brand>-700/50 rounded-2xl">
  {/* 텍스트 영역 (제목 & 설명) */}
  <div className="flex flex-col gap-2 flex-1">
    <div className="flex flex-row items-center gap-2 sm:gap-3 shrink-0">
      <h1 className="text-2xl md:text-3xl font-bold text-<brand>-600 dark:text-<brand>-400 whitespace-nowrap">
        {title}
      </h1>
    </div>
    <div className="flex-1 max-w-2xl text-left">
      <p className="text-justify text-sm text-gray-700 dark:text-slate-300 leading-relaxed whitespace-pre-wrap">
        {description}
      </p>
    </div>
  </div>

  {/* 주요 액션 버튼 (단축키 + 호버 효과 포함) */}
  <Button
    onClick={onAction}
    className="relative flex items-center gap-2 sm:gap-3 py-3 sm:py-4 px-5 sm:px-6 bg-<brand>-600 dark:bg-<brand>-600 border border-transparent rounded-xl font-semibold cursor-pointer hover:bg-<brand>-700 hover:scale-105 transition-all w-full md:w-auto justify-center shadow-sm shrink-0"
  >
    <p className="text-white text-sm sm:text-base font-bold">액션 버튼</p>
    <ActionIcon className="w-5 h-5 sm:w-6 sm:h-6 text-white" />
    {/* 단축키 힌트 버블 (선택 사항) */}
    {/* <ShortcutBubble shortcut="Q" /> */}
  </Button>
</div>
```

### 1.2 검색 컴포넌트 & 필터 행 단일 정렬

- **규칙**: 데스크탑 환경에서는 검색 폼 영역(Select + Search)과 카테고리 필터 칩을 하나의 단일 행(`lg:flex-row justify-between`)으로 묶어 배치한다.
- **배치**: 좌측에 검색 폼, 우측에 카테고리 필터 칩. 모바일에서는 `flex-col`로 상하 분리.
- **스타일 예시**:

```tsx
<div className="mb-3 flex flex-col lg:flex-row items-start lg:items-center justify-between gap-3 lg:gap-4 w-full">
  {/* 검색 바 (데스크탑 좌측, 모바일 상단) */}
  <div className="w-full lg:w-auto flex flex-col sm:flex-row items-center gap-2 shrink-0">
    <Select ... />
    <div className="w-full sm:w-[300px]">
      <SearchInput ... />
    </div>
  </div>

  {/* 필터 칩 (데스크탑 우측, 모바일 하단) */}
  <div className="w-full flex flex-row items-center gap-2 overflow-x-auto pb-2 lg:pb-0 scrollbar-hide justify-start lg:justify-end">
    <Button variant="primary" className="rounded-full">전체</Button>
    <Button variant="outline" className="rounded-full">2026년</Button>
    {/* 추가 필터 칩... */}
  </div>
</div>
```

---

## 2. 클릭 가능한 전체 폭 히어로 컨테이너

상세 페이지나 필터 활성화 상태에서 헤더 영역을 클릭해 이전 목록으로 돌아가거나 상세 뷰를 닫는 기능(Back/Close Navigation)이 연결될 때 다음 디자인을 적용한다:

- **전체 폭 상호작용 박스**: 컨테이너 전체에 `onClick`, `cursor-pointer`, `group` 속성을 부여하고 마우스 오버 시 배경색을 한 단계 진하게 변경한다.

```tsx
// 클릭 가능한 컨테이너
<div
  onClick={onBack}
  className="w-full flex flex-col md:flex-row items-start md:items-center justify-between mb-8 gap-4 md:gap-8 p-5 md:p-6 bg-<brand>-50 dark:bg-<brand>-900/40 border border-<brand>-200 dark:border-<brand>-700/50 rounded-2xl cursor-pointer group hover:bg-<brand>-100 dark:hover:bg-<brand>-800/50 transition-colors"
>
  {/* 제목 — group-hover 시 색상 강조 */}
  <h1 className="... group-hover:text-<brand>-700 dark:group-hover:text-<brand>-300 transition-colors px-1">
    {title}
  </h1>

  {/* 설명 — group-hover 시 색상 강조 */}
  <p className="... group-hover:text-gray-900 dark:group-hover:text-slate-200 transition-colors">
    {description}
  </p>
</div>
```

- **텍스트 호버 트랜지션**: 전체 컨테이너에 마우스를 올렸을 때(`group-hover`), 제목과 설명 텍스트도 살짝 색상이 짙어져 클릭 가능함을 명확히 전달한다.

---

## 3. 핵심 준수 요건 체크리스트

- [ ] 제목과 설명이 가로 배치(`md:flex-row`)되며 전체 폭 배경 박스로 감싸여 있는가?
- [ ] 검색 바와 필터 칩이 데스크탑에서 단일 행으로 정렬되어 있는가?
- [ ] 모바일(`flex-col`)에서 상하 분리가 올바르게 동작하는가?
- [ ] 클릭 가능한 컨테이너에 `group`, `cursor-pointer`, `hover:` 클래스가 적용되어 있는가?
- [ ] `group-hover:` 클래스로 내부 텍스트의 호버 트랜지션이 구현되어 있는가?

### ⛔ 단독 결정 금지

- 전체 서비스 헤더 레이아웃의 기준 색상/간격 체계 변경
- 히어로 클릭 동작을 다른 네비게이션 패턴으로 교체
