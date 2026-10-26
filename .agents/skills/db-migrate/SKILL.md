---
name: db-migrate
description: 레거시 DB 마이그레이션 스킬. 레거시 MSSQL/MySQL 데이터를 PostgreSQL로 추출·변환·적재(ELT)하며, 고아 데이터 방지·데이터 클렌징·롤백 전략을 보장한다.
---

# DB 마이그레이션 스킬

레거시 데이터베이스에서 새 PostgreSQL 스키마로 데이터를 안전하고 정확하게 마이그레이션하는 스킬이다.

> **[사용 시 안내]** 이 스킬은 범용 템플릿이다. 적용 시 `<legacy-table>`, `<target-table>`, `<project-root>` 등 플레이스홀더를 프로젝트 실제 값으로 교체하고, 불필요한 섹션은 삭제한다.

## 핵심 규칙

1. **진실 공급원 확인**: 레거시 시스템에서 어느 테이블이 마스터 데이터인지 먼저 확인한다.
   - 임시 테이블·중간 집계 테이블을 원본으로 착각하지 않는다.
   - 이미지/파일 등 바이너리 데이터의 주요 소스가 어느 테이블인지 명확히 정의한다.

2. **고아 방지**: 참조 무결성이 깨지는 이관 순서를 피한다.
   - 예: 대출 이력은 복본(copy) 및 사용자(user) 레코드가 먼저 존재해야 한다.
   - 이관 전 `<source-table>`이 `<target-table>` 전체 레코드를 커버하는지 검증한다.

3. **데이터 클렌징 (ELT 패턴)**: 최종 테이블에 직접 삽입하지 않는다. PostgreSQL에 **스테이징 영역**을 구현한다.
   - **추출 및 적재**: CSV 데이터를 "있는 그대로" `legacy_raw_<entity>` 스테이징 테이블에 가져온다.
   - **변환**: SQL 스크립트로 데이터를 클렌징한다. 여러 소스가 있을 경우 우선순위를 명확히 정의한다.
     - 예: 소스 A가 절대 우선. 소스 B는 A에 레코드가 없을 때만 보조 소스로 사용.
   - **삽입**: 클렌징된 데이터를 스테이징 테이블에서 최종 대상 테이블로 이동한다.

4. **실행 파이프라인**: 스크립트를 번호로 순서화하여 단계별로 명확하게 구분한다.
   ```
   01_create_<entity>_view.sql      ─ 레거시 DB에 추출용 뷰 생성
   02_export_<entity>_csv.sh        ─ CSV 내보내기
   03_import_<entity>_staging.sh    ─ 스테이징 테이블로 가져오기
   04_transform_<entity>.sql        ─ 데이터 클렌징 및 최종 테이블 삽입
   ...
   NN_fill_<assets>.sh              ─ 이미지/파일 등 바이너리 자산 후처리
   ```
   - 레거시 DB 대상 뷰 생성 스크립트와 PostgreSQL 대상 변환 스크립트를 분리한다.
   - 각 단계 실행 경로: `<project-root>/scripts/`

5. **롤백 전략**: 실행 중 실패 시 명확한 롤백 지침이 있어야 한다.
   - `down` 스크립트 또는 명시적 명령(`TRUNCATE TABLE`, `DROP VIEW`)으로 이전 상태를 복원한다.

6. **멱등성**: 모든 마이그레이션 스크립트는 반드시 멱등성을 보장해야 한다.
   - 스크립트를 여러 번 연속 실행해도 중복 레코드가 발생하면 안 된다.
   - `INSERT ON CONFLICT DO UPDATE (UPSERT)` 또는 삽입 전 대상 테이블 완전 비우기로 처리한다.

7. **바이너리 자산 보존**: DB 재생성 시 이전에 채워진 이미지/파일이 삭제되지 않도록 한다.
   - 바이너리 자산 채우기 단계를 엔티티 이관 이후에 반드시 실행한다.
   - **레거시 이미지 소스 (MSSQL 바이너리 블롭)**: 프로젝트에 맞는 테이블·컬럼 정의.
   - **외부 API 보완**: 레거시에 없지만 유효한 식별자(ISBN 등)가 있는 항목은 외부 API로 채운다.

8. **비대화형 TTY 환경에서의 마이그레이션 관리**: 대화형 TTY 입력이 제한된 에이전트 환경에서 `prisma migrate dev` 실행 시 에러가 발생할 수 있다.
   - `prisma migrate diff`로 DB와 `schema.prisma` 간의 차이점을 SQL로 추출(DB에만 존재하는 불필요한 DROP 구문 등은 제거)하여 마이그레이션 SQL 파일을 수동 생성하고, `prisma migrate deploy`를 통해 비대화형으로 안전하게 실행한다.
   - DB 스키마 구조는 정상이나 마이그레이션 이력이 꼬여 배포가 차단된 경우, `prisma migrate resolve --applied <migration_name>`을 사용하여 이력을 강제 동기화하고 차단을 해제할 수 있다.

9. **Legacy NULL 문자열 방어 (필수)**: 레거시 DB(MySQL, MSSQL)에서 추출한 데이터에는 실제 SQL NULL 대신 **문자열 `'NULL'`**이 들어있는 경우가 매우 흔하다. 이를 방어하지 않으면 문자열 결합(concatenation) 시 쓰레기 값이 생긴다.
   - **모든 문자열 컬럼**에서 `CASE WHEN` 또는 `NULLIF`로 문자열 `'NULL'`을 실제 NULL로 변환해야 한다:
     ```sql
     -- ❌ 금지: NULL 문자열이 경로에 붙음
     '/uploads/' || t.path_val

     -- ✅ 필수: 문자열 'NULL'과 빈 문자열을 실제 NULL로 변환
     CASE WHEN t.path_val IS NOT NULL
               AND t.path_val <> ''
               AND UPPER(TRIM(t.path_val)) <> 'NULL'
          THEN '/uploads/' || t.path_val
          ELSE NULL END
     ```

10. **이중 인코딩(Double Encoding) 탐지 및 복원 (필수)**: MySQL/MSSQL → PostgreSQL 마이그레이션 시 UTF-8 데이터가 Latin-1(ISO-8859-1)으로 잘못 해석되어 다시 UTF-8로 저장되는 이중 인코딩이 매우 흔하다.
    - **탐지**: 한글 이름이 `ê¹`, `ì´`, `ë°±` 등 라틴 문자 조합으로 보이면 이중 인코딩을 의심한다.
      ```sql
      -- 정상 UTF-8 한글: byte/char 비율 ≈ 3 (3바이트/글자)
      -- 이중 인코딩: byte/char 비율 ≈ 2 (Latin-1 문자가 2바이트 UTF-8로 저장)
      SELECT count(*) FROM <table>
      WHERE octet_length(name) = length(name) * 2;
      ```
    - **복원 (안전한 PL/pgSQL 패턴)**: `convert_from(convert_to(name, 'LATIN1'), 'UTF8')`로 역변환하되, 정상 레코드에서 에러가 발생하므로 반드시 exception 블록으로 감싼다:
      ```sql
      DO $$
      DECLARE r RECORD; fixed TEXT; fix_count INT := 0;
      BEGIN
        FOR r IN SELECT id, name FROM <table> LOOP
          BEGIN
            fixed := convert_from(convert_to(r.name, 'LATIN1'), 'UTF8');
            IF fixed != r.name THEN
              UPDATE <table> SET name = fixed WHERE id = r.id;
              fix_count := fix_count + 1;
            END IF;
          EXCEPTION WHEN OTHERS THEN NULL;
          END;
        END LOOP;
        RAISE NOTICE 'Fixed % records', fix_count;
      END $$;
      ```
    - **잘린(truncated) 바이트 보정**: 이중 인코딩 중 바이트가 잘려 `convert_to(LATIN1)` 자체가 실패하는 레코드는 다른 테이블(예: `users.name`)의 정상 데이터에서 이름을 복사한다.
    - **마이그레이션 후 검증 필수**: 이관 완료 직후 `octet_length = length * 2` 조건으로 이중 인코딩 잔존 여부를 반드시 검증한다.

11. **ID 매핑 하드코딩 시 실제 JOIN 경로 검증 (필수)**: 테이블 간 ID 매핑(예: `person_id`, `timothy_id`)을 스크립트에 하드코딩할 때 절대 추측하지 않는다.
    - 반드시 실제 DB에서 JOIN 쿼리를 실행하여 매핑 값을 검증한 후 코드에 반영한다.
    - 서로 다른 테이블의 같은 이름 컬럼(예: `users.timothy_id` vs `hyanglin_members.timothy_id`)이 서로 다른 값 체계를 가질 수 있음을 항상 유의한다.
    - 검증 쿼리 예시:
      ```sql
      SELECT u.timothy_id AS user_tid, hm.timothy_id AS hm_tid, hm.person_id
      FROM users u
      JOIN hyanglin_members hm ON hm.timothy_id = u.timothy_id
      WHERE u.name = '대상자 이름';
      ```

## 실행 절차

마이그레이션 실행 요청 시:
1. **사용자/회원 이관 (ELT)**: 사용자 스크립트(`01`~`04`)를 실행하여 스테이징에 적재하고 변환을 실행한다.
2. **엔티티 뷰 정의 적용**: 레거시 DB에 추출용 뷰를 생성한다.
3. **엔티티 CSV 내보내기**: `bash <project-root>/scripts/06_export_<entity>_csv.sh`
4. **가져오기 및 변환**: 스테이징 import 스크립트 실행 후 transform SQL 적용.
5. **관계 데이터 이관 (ELT)**: 대출/이력 등 관계 데이터를 적재하고 변환한다.
6. **바이너리 자산 채우기**: 레거시 이미지 추출 후 나머지는 외부 API로 채운다. **(필수 — 생략하면 모든 이미지가 NULL)**
7. **무결성 검증**: 스테이징 테이블을 최종 테이블과 대조하여 고아 데이터가 0건인지 확인한다.

## 하네스 연동

### Phase 0 — 레슨 로드
이 스킬을 사용하는 작업을 시작하기 전에 다음을 읽는다:
- `.agents/learnings/general.md`
- `.agents/learnings/db-migrate.md`

관련 레슨을 먼저 적용한 뒤 진행한다.

### Phase 5 — 레슨 기록
중요한 작업 완료 후, 다음 경우에 해당하면 `.agents/learnings/db-migrate.md`에 레슨을 추가한다:
- 예상보다 어려웠던 부분이 있었을 때
- 반복될 패턴이 발견되었을 때
- 다음에 방지해야 할 실수를 했을 때
- 사용자가 출력 결과를 의미 있게 수정했을 때

> 레슨이 **3회 이상** 반복되면 → `rules-project.md` 또는 프로젝트 규칙 반영 후보로 승격한다.
