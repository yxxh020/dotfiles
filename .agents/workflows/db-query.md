---
description: GLOBAL-로컬 DB 클라이언트(psql, sqlcmd)를 통해 데이터베이스 스키마 및 데이터를 빠르게 조회한다.
---

# 로컬 DB CLI 기반 쿼리 워크플로우
이 워크플로우는 `psql` (Postgres) 또는 `sqlcmd` (MSSQL)를 터미널에서 직접 실행하여 DB를 조회한다.

1. 사용자의 요청(스키마 확인, 특정 테이블 레코드 조회 등)을 파악한다.
2. id, pw는 .env* 에서 찾다. 없다면 사용자에게 필요한 정보를 요청한다.
3. 알맞은 SQL 쿼리를 작성하고, 타겟 데이터베이스에 맞춰 다음 명령을 `run_command`로 실행해라.
   * Postgres 예시: `psql -d mydatabase -c "작성한 쿼리"`
   * MSSQL 예시: `sqlcmd -S localhost -U sa -P password -Q "작성한 쿼리"`
4. 조회된 결과를 마크다운 표 형식으로 깔끔하게 정리하여 출력해라.