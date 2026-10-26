---
name: board-expert
description: 게시판 관련 이슈 처리, 무결성 검증, 데이터 마이그레이션, 파일 경로 규칙, 중복 제거(dedup) 전문가 스킬.
---

> **[안내]** 이 파일은 각 프로젝트가 복사해갈 때 프로젝트 상황에 맞게 수정하여 사용하는 템플릿이다.
> 적용 시 이 안내 문구를 제거하고 프로젝트에 맞게 내용을 수정한다.

# 게시판 전문가 스킬

사용자가 게시판 관련 이슈, 게시판 페이지 UI 불일치, 게시판 마이그레이션, 썸네일 이미지 경로, 중복 게시글 처리(dedup)를 언급하면 이 스킬을 반드시 호출한다.

## 1. 게시판 무결성 및 검증

게시판 무결성, 소장자료 검색, 연동 서비스, 개인 활동 탭 점검에 대한 스펙, 아키텍처 원칙, 설정은 해당 서브 프로젝트 PRD 문서를 참고한다.

- **PRD 스펙**: `<project-root>/sub-projects/<board-integrity>/spec.md`

## 2. 파일 저장 경로 원칙

### 2.1. 디렉토리 구분 (Directory Separation)
- **레거시 이관 파일 (Legacy Migrated Files):** `/uploads/legacy_files/` 하위 폴더에 위치. 과거 시스템에서 이관된 데이터 전용.
- **신규 업로드 파일 (New Upload Files):** `/uploads/images/` 등 백엔드 `FileUploadService`가 지정하는 폴더에 저장.

### 2.2. 데이터베이스 저장 규칙 (Database Storage Rules)
- **경로 포함 필수:** 게시판 이미지 컬럼에는 절대 파일명만 단독으로 저장(Bare Filename)해서는 안 된다. (예: `20260520-XXXX.jpg` — 절대 금지)
- 반드시 디렉토리 경로가 포함된 상대 경로(예: `/uploads/legacy_files/<category>/image.jpg`) 또는 절대 URL 형태로 저장해야 한다.

### 2.3. 환경별 파일 서빙 원칙 (Environment File Serving Rules)
- **Local (개발 환경):** 로컬 파일 시스템에 실제 레거시 파일이 없으므로, Next.js의 `rewrites` 프록시 기능을 이용해 실제 서버에서 이미지를 당겨온다. 이를 위해 프론트엔드는 상대 경로(`/uploads/...`)를 그대로 유지해야 프록시가 작동한다.
- **Test / Production (스테이징/운영 환경):** 파일이 해당 서버에 물리적으로 존재한다. 프론트엔드의 렌더링 컴포넌트는 `NEXT_PUBLIC_API_URL` 등을 참조하여 브라우저가 직접 접근할 수 있는 절대 URL(`https://.../uploads/...`)로 변환해야 한다.

### 2.4. 이관 스크립트 작성 원칙 (Migration Script Authoring Principles)
- **명시적 경로 매핑:** 과거 시스템에서 파일명만 저장되어 있던 데이터를 새 시스템으로 이관할 때는 반드시 스크립트 내부에서 올바른 디렉토리 경로를 조합하여 완전한 상대 경로로 변환한 후 저장해야 한다.
  - 게시판 카테고리별로 레거시 파일 경로를 조합하는 규칙을 스크립트에 명시한다.
  - 예: `<category-a>`, `<category-b>` → `/uploads/legacy_files/<path-a>/`, `<path-b>/` 식으로 정의.
- **예외 처리:** 데이터 값이 문자열 `'NULL'` 이거나 `''`(빈 문자열)인 경우, 반드시 실제 SQL `NULL`로 치환한다.

### 2.5. 파일 호출 함수 원칙 (File Calling Function Principles)
- **`resolveBoardImageUrl` 및 `imgSrc` 함수의 역할:** DB에 저장된 파일 경로를 클라이언트(브라우저)가 접근할 수 있는 최종 주소로 변환하는 핵심 유틸리티.
- **분기 처리 기준:** 값에 `http`가 포함되어 있으면 완전한 URL로 판단해 그대로 반환하고, `/uploads/`로 시작하면 구동 환경(`NODE_ENV`)을 확인해 Local이면 프록시가 타도록 상대 경로 유지, Prod/Test이면 절대 경로로 치환한다.

## 3. Board Dedup (게시판 중복 제거 절차)

게시판(boards) 테이블의 완전 중복 항목을 MD5 해시 비교로 탐지하고 안전하게 삭제한다.
단순 제목 중복(재모집/재공지)은 보존하고, title + detail 내용이 완전히 동일한 항목만 삭제한다.

### 3.1. 언제 호출하는가
- 게시판에 중복 항목이 보일 때
- 마이그레이션 스크립트 재실행 후 중복 여부를 점검할 때
- 주기적 DB 상태 점검 시 boards 중복 현황을 확인하고 싶을 때

### 3.2. 핵심 원칙
1. **MD5 기반 비교**: `title` 문자열 동일 + `md5(COALESCE(detail,''))` 해시 동일 → 진짜 중복
2. **보존 우선**: title만 같고 detail이 다른 항목(재공지·재모집)은 절대 삭제하지 않는다.
3. **선 탐지 후 삭제**: 반드시 `analyze` 단계로 목록을 먼저 출력하고 사용자 확인 후 삭제한다.
4. **FK 순서 준수**: `board_resources` → `boards` 순서로 삭제 (외래 키 제약 위반 방지).
5. **각 그룹에서 가장 작은 board_id(원본) 보존**, 나머지(후발 중복) 삭제.
6. **환경 순서**: 로컬 → 스테이징 → 프로덕션 순으로 처리.

### 3.3. 환경별 DSN
| 환경 | DSN |
|------|-----|
| 로컬 | `postgresql://<db-user>:<db-pass>@localhost:5432/<db-name>` |
| 스테이징 | `postgresql://<db-user>:<db-pass>@localhost:5432/<db-name-staging>` *(없으면 스킵)* |
| 프로덕션 | `postgresql://<db-user>:<db-pass>@<host-ip>:<port>/<db-name>` |

### 3.4. 실행 절차

**Step 1 — 탐지(Analyze)**
```bash
bash .agents/skills/board-expert/scripts/analyze.sh <DSN>
```
*(출력 예시: 총 삭제 대상 N건)*

**Step 2 — 삭제(Delete)**
사용자 확인 후 실행 (스크립트는 내부적으로 트랜잭션으로 감싸 실행됨):
```bash
bash .agents/skills/board-expert/scripts/delete.sh <DSN>
```

**Step 3 — 검증(Verify)**
```bash
bash .agents/skills/board-expert/scripts/verify.sh <DSN>
```
`remaining_exact_dups = 0` 이 나오면 성공.

### 3.5. 에이전트 보고 형식
작업 완료 후 아래 형식으로 보고한다:
| 환경 | 탐지 건수 | 삭제 건수 | 검증 결과 |
|------|-----------|-----------|-----------|
| 로컬 | N | N | ✅ 0 remaining |
| 스테이징 | N | N | ✅ 0 remaining |
| 프로덕션 | N | N | ✅ 0 remaining |
