---
name: stakeholder-csv-integration
description: CSV/Excel 대량 다운로드, 파싱 미리보기 테이블, 임포트 옵션(추가 vs 덮어쓰기) 구현을 위한 아키텍처 가이드라인 및 코드 패턴 스킬.
---

# CSV/Excel 일괄 연동 패턴 스킬

데이터 일괄 CSV/Excel 다운로드, 미리보기 표 렌더링, 업로드 옵션(덮어쓰기 vs. 유지하며 수정/추가)의 백엔드 및 프론트엔드 연동 표준 아키텍처 가이드라인.

---

## 1. 백엔드 아키텍처 패턴

### 1-1. DTO 및 쿼리 유연화

복수 카테고리의 데이터를 한 번에 처리해야 하는 경우, DTO의 유효성 검사를 유연하게 설계하여 쉼표 구분 문자열이나 특수 키워드를 수용하고, 서비스 레이어에서 배열로 매핑한다.

```typescript
export class DataQueryDto {
  @IsString()
  @IsOptional()
  type?: string; // 쉼표 구분 문자열 또는 그룹 키워드 수용
}
```

### 1-2. 서비스 레이어 필터링

키워드 쿼리를 숫자 ID 배열로 변환한 뒤, 레포지토리에 배열 형태로 위임하여 단 한 번의 DB 조회로 모든 대상 데이터를 가져온다.

```typescript
private parseType(typeParam?: string): number | number[] | undefined {
  if (!typeParam) return undefined;
  if (typeParam.toUpperCase() === 'ALL_GROUP') {
    return [1001, 1002, 1003]; // 그룹에 속한 모든 타입
  }
  return typeParam.split(',').map(Number);
}
```

### 1-3. 레포지토리 복수 조회

`type` 파라미터가 단일 숫자 또는 숫자 배열일 수 있도록 파라미터 타입을 유연하게 하고, 배열일 경우 `IN` 쿼리로 조회한다.

```typescript
async findAll(page = 1, limit = 10, type?: number | number[]) {
  const where = type
    ? Array.isArray(type) ? { type: { in: type } } : { type }
    : {};
  // DB 조회...
}
```

### 1-4. 업로드 저장 모드 (추가 vs 덮어쓰기)

기존 데이터 보호를 위해 두 가지 모드를 강제 구현한다:

- **덮어쓰기 (`overwrite`)**: 해당 섹션의 기존 데이터를 일괄 삭제한 뒤 새로 등록한다.
- **유지하며 수정/추가 (`append`)**: 기존 데이터를 메모리에 맵 구조로 조회한 뒤, 파일 내용을 순회하며 동일 키가 있는 경우 변경 사항이 있을 때만 `update`, 없는 경우 신규 `create`를 실행한다.

---

## 2. 프론트엔드 연동 패턴

### 2-1. 공통 CSV 액션 레이아웃

개별 탭 내에 중복된 파일 업로드 컴포넌트를 두지 말고, 페이지 상단에 정형화된 공통 CSV 컨트롤 패널을 배치한다:
- **CSV 다운로드**: 현재 선택된 필터 정보를 바탕으로 다운로드 API를 연동한다.
- **파일 선택 및 CSV 업로드**: 파일이 선택되면 미리보기 모달을 띄운다.

### 2-2. 미리보기 다이얼로그 및 모드 선택기

미리보기 모달은 사용자 실수를 막기 위해 다음 레이아웃을 준수한다:
1. **모드 선택기**: 라디오 버튼으로 "유지하며 수정/추가"(기본값)와 "덮어쓰기"(위험 경고 스타일) 옵션을 제공한다.
2. **미리보기 표**: 파싱 결과를 카테고리별 직관적인 테이블로 렌더링한다.
3. **업로드 실행 버튼**: 최종 확인 후 선택한 모드 파라미터(`?mode=append` 또는 `?mode=overwrite`)를 담아 업로드 API를 호출한다.
