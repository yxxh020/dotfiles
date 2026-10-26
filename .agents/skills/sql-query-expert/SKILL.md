---
name: sql-query-expert
description: 데이터베이스 쿼리 생성 전문가 스킬. 명시적으로 언급하지 않는 한 로컬 PostgreSQL을 기본으로 사용하며, 레거시 MSSQL 또는 MySQL은 명시적 요청 시에만 생성한다.
---

# SQL 쿼리 전문가 스킬

사용자의 요구사항에 따라 정확하게 데이터베이스 쿼리를 생성하고 설명하는 `sql-query-expert`로서 행동한다.

## 핵심 지침

1. **기본 데이터베이스 (PostgreSQL — 로컬)**
   - 사용자가 데이터베이스 유형이나 환경을 지정하지 않으면 **항상 로컬 PostgreSQL(`pgsql`)을 기본으로 한다**.
   - PostgreSQL 표준 문법, 함수, 관례를 사용한다 (예: `CURRENT_TIMESTAMP`, `INTERVAL`, `JSONB` 연산자, `RETURNING` 절).

2. **레거시 데이터베이스 (MSSQL / MySQL)**
   - 사용자가 "legacy", "mssql", "mysql" 또는 해당 컨텍스트에서 특정 레거시 테이블 접두어를 **명시적으로 언급할 때에만** MSSQL 또는 MySQL 쿼리를 생성한다.
   - MSSQL 쿼리 생성 시 MSSQL 전용 함수를 사용한다 (예: `GETDATE()`, `TOP N`, `ISNULL()`).
   - MySQL 쿼리 생성 시 MySQL 전용 함수를 사용한다 (예: `NOW()`, `LIMIT`, `IFNULL()`).

3. **쿼리 구조 및 설명**
   - 마크다운 코드 블록(` ```sql `) 안에 raw SQL 쿼리를 제공한다.
   - 쿼리에 사용된 핵심 조건과 로직을 간략히 설명한다.
   - PostgreSQL 쿼리의 경우, 프로젝트가 Prisma를 사용한다면 Prisma의 PostgreSQL 관례와의 호환성을 보장한다.

## 실행 예시

**사용자 입력:** "예약 대기 만료 목록 쿼리 제시해줘"
**동작:** 특정 DB 명시 없음 → 로컬 PostgreSQL 쿼리 생성.

**사용자 입력:** "레거시 mssql 기준으로 만료 조회 쿼리 만들어줘"
**동작:** "mssql" 감지 → `GETDATE()`와 `TOP`을 사용한 MSSQL 쿼리 생성.

---

## 하네스 연동

### 단계 0 — 레슨 로드
이 스킬로 쿼리 생성 작업을 시작하기 전에 다음을 읽는다:
- `.agents/learnings/general.md`
- `.agents/learnings/sql-query-expert.md` (있으면)

### 단계 5 — 레슨 기록
복잡한 쿼리를 생성하거나 새로운 쿼리 패턴을 발견하면 `.agents/learnings/sql-query-expert.md`에 레슨을 기록한다.
