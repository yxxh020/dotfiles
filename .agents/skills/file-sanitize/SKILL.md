---
name: file-sanitize
description: >
  모든 파일 업로드 시 파일명을 안전하게 정제(sanitize)하는 표준 규칙과 구현 위치를 정의한다.
  한글·괄호·특수문자를 포함한 파일명, 확장자 오인식, MIME 타입 불일치 등의 문제를 방지한다.
---

> **[안내]** 이 파일은 각 프로젝트가 복사해갈 때 프로젝트 상황에 맞게 수정하여 사용하는 템플릿이다.
> 적용 시 이 안내 문구를 제거하고 프로젝트에 맞게 내용을 수정한다.

# file-sanitize

## 언제 사용하나? (When to invoke)

다음 상황에서 이 skill을 먼저 확인하세요:

- 파일 업로드 관련 버그(이미지 깨짐, Content-Type 오류 등)를 수정할 때
- 새로운 파일 업로드 엔드포인트를 추가할 때
- 파일 업로드 서비스(`FileUploadService` 등)를 수정할 때
- multer/busboy 등 파일 필터 설정을 변경할 때

---

## 핵심 설계 원칙 (Core Design)

### 1. 확장자는 MIME 타입에서만 추출한다

> **원본 파일명의 확장자를 절대 신뢰하지 않는다.**

`path.extname(file.originalname)`은 다음 상황에서 오동작한다:
- `6월 공지사항(배너)` → `.6월 공지사항(배너)` (이미지 아님)
- `파일명` (확장자 없음) → `` (빈 문자열)
- `report.xlsx.csv` → `.csv` (잘못된 확장자)

**올바른 방법**: `file.mimetype`을 기준으로 확장자를 결정한다.

### 2. 파일명 stem(이름 부분)도 정제한다

원본 파일명 보존(`preserveOriginalName: true`) 시:

| 단계 | 처리 내용 |
|------|-----------|
| 괄호류 제거 | `()[]{}` → 제거 |
| 특수문자 제거 | `^`, `*`, `!` 등 → 제거 (영숫자·한글·공백·하이픈만 허용) |
| 공백 → `_` | 연속 공백 포함하여 언더스코어로 변환 |
| 연속 구분자 정리 | `__` → `_` |
| 앞뒤 구분자 제거 | 앞뒤 `_`, `-` 제거 |
| 최대 80자 | 초과 시 잘라냄 |
| 빈 결과 fallback | 정제 후 빈 문자열이면 UUID로 대체 |

### 3. 지원되지 않는 MIME 타입은 즉시 거부한다

MIME_TO_EXT 맵에 없는 타입은 `BadRequestException`(또는 400 에러)을 반환한다.

---

## 구현 패턴 (Implementation Pattern)

### MIME 타입 → 확장자 매핑 (허용 목록)

```typescript
const MIME_TO_EXT: Record<string, string> = {
  'image/jpeg': '.jpg',
  'image/png':  '.png',
  'image/gif':  '.gif',
  'image/webp': '.webp',
  'application/pdf': '.pdf',
  'application/msword': '.doc',
  'application/vnd.openxmlformats-officedocument.wordprocessingml.document': '.docx',
  'application/vnd.ms-excel': '.xls',
  'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet': '.xlsx',
  'text/csv': '.csv',
};
```

### 파일명 stem 정제 로직

```typescript
const safeStem = stem
  .replace(/()[[\]{}<>]/g, '')    // 괄호류 제거
  .replace(/[^\w\s가-힣-]/g, '')  // 허용: 영숫자, 공백, 한글, 하이픈
  .trim()
  .replace(/\s+/g, '_')           // 공백 → 언더스코어
  .replace(/_{2,}/g, '_')         // 연속 언더스코어 정리
  .replace(/^[_-]+|[_-]+$/g, '')  // 앞뒤 구분자 제거
  .slice(0, 80)                   // 최대 80자
  || fileId;                      // 빈 결과 fallback
```

---

## multer fileFilter와의 관계

multer의 `fileFilter`는 **원본 파일명 확장자** 기반으로 1차 필터링한다.
이는 MIME 스푸핑 방어가 아니라 UX 목적의 빠른 사전 거부다.

업로드 서비스의 MIME 타입 기반 처리가 **2차 방어선**이자 **확장자 결정의 SSOT**다.

---

## 새 파일 업로드 엔드포인트 추가 시 체크리스트

- [ ] 허용할 파일 형식 확인 (fileFilter 또는 accept 설정)
- [ ] 업로드 서비스를 반드시 경유하도록 구현
- [ ] 절대로 `path.extname(file.originalname)`으로 저장 확장자를 결정하지 않는다
- [ ] 저장된 URL을 DB에 넣기 전 경로 형식 확인
- [ ] MIME 타입 허용 목록에 없는 타입이 필요하면 `MIME_TO_EXT`에 추가 후 fileFilter도 동기화

---

## 하네스 연동

### 단계 0 — 레슨 로드
- `.agents/learnings/file-sanitize.md` 확인 후 적용

### 단계 5 — 레슨 기록
- 파일명 관련 버그 수정 시 `.agents/learnings/file-sanitize.md`에 기록
