---
name: codebase-metrics-expert
description: 프로젝트 코드베이스 메트릭(파일 수, 라인 수, 용량, 테스트 수)을 5대 카테고리별로 측정·추적하고 DB 테이블 및 마크다운 문서에 일별로 자동 기록하는 전문가 스킬.
---

# Codebase Metrics Expert (`codebase-metrics-expert`)

> **[안내]** 이 파일은 각 프로젝트가 복사해갈 때 프로젝트 상황에 맞게 수정하여 사용하는 템플릿이다.
> 적용 시 이 안내 문구를 제거하고 프로젝트에 맞게 내용을 수정한다.

프로젝트 전체의 코드 및 문서 통계를 측정하고, 크론(Cron) 작업을 통해 데이터베이스(PostgreSQL 등) 및 마크다운 문서에 일별로 자동 수집·적재하는 표준 체계를 정의한다.

## 1. 역할 및 핵심 책임

1. **측정 (Measurement)**: Git 추적 파일(`git ls-files`)을 5대 카테고리로 분류하고 라인 수, 파일 수, 바이트 용량을 계산.
2. **데이터베이스 적재 (DB Ingestion)**: 수집된 통계를 RDBMS 테이블(`daily_codebase_metrics`, `codebase_folder_metrics`)에 업서트(UPSERT).
3. **문서 동기화 (Documentation Sync)**: `docs/project-metrics.md`와 같은 프로젝트 통계 문서 테이블을 최신 상태로 유지.
4. **자동화 유지관리 (Cron Automation)**: 매일 정해진 새벽 시간(예: 04:30)에 백그라운드 크론 작업으로 누락 없이 자동 실행.

## 2. 5대 표준 카테고리 분류 기준

| 카테고리 | 설명 | 주요 대상 예시 |
|---|---|---|
| `SOURCE_CODE` | 실제 비즈니스 및 애플리케이션 로직 | `src/*`, `frontend/src/*`, `backend/src/*` (테스트 제외) |
| `TEST_CODE` | 단위, 통합, E2E 테스트 코드 및 설정 | `*.spec.ts`, `*.test.ts`, `tests/*`, `qa-automation/*` |
| `DOCS` | 기획, 아키텍처, 가이드, 할 일 문서 | `docs/*.md`, `sub-tasks/**/*.md`, `README.md` |
| `MAINTENANCE` | 빌드, 인프라, 마이그레이션, AI 규칙·스킬 | `.bin/*`, `.github/*`, `.agents/*`, `migrations/*` |
| `ASSETS_DATA` | 번역 리소스, 정적 설정, 데이터 파일 | `i18n/*`, `translations/*`, `*.json`, `*.yaml` |

## 3. 타 프로젝트 이식을 위한 표준 템플릿 자산

### 3.1 PostgreSQL DDL 스키마 템플릿
```sql
-- 일별 전체 메트릭 요약 테이블
CREATE TABLE IF NOT EXISTS daily_codebase_metrics (
    id SERIAL PRIMARY KEY,
    date DATE NOT NULL UNIQUE,
    total_file_count INT NOT NULL,
    total_line_count INT NOT NULL,
    total_size_bytes BIGINT NOT NULL,
    commit_hash VARCHAR(40),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 카테고리/폴더별 세부 메트릭 테이블
CREATE TABLE IF NOT EXISTS codebase_folder_metrics (
    id SERIAL PRIMARY KEY,
    date DATE NOT NULL,
    category VARCHAR(50) NOT NULL,
    target_path VARCHAR(100) NOT NULL,
    file_count INT NOT NULL,
    line_count INT NOT NULL,
    size_bytes BIGINT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_codebase_folder_date_target UNIQUE (date, target_path)
);
```

### 3.2 Prisma Schema 템플릿 (선택 사항)
```prisma
model DailyCodebaseMetric {
  id             Int      @id @default(autoincrement())
  date           DateTime @unique @db.Date
  totalFileCount Int      @map("total_file_count")
  totalLineCount Int      @map("total_line_count")
  totalSizeBytes BigInt   @map("total_size_bytes")
  commitHash     String?  @map("commit_hash") @db.VarChar(40)
  createdAt      DateTime @default(now()) @map("created_at") @db.Timestamptz(6)

  @@index([date])
  @@map("daily_codebase_metrics")
}

model CodebaseFolderMetric {
  id         Int      @id @default(autoincrement())
  date       DateTime @db.Date
  category   String   @db.VarChar(50)
  targetPath String   @map("target_path") @db.VarChar(100)
  fileCount  Int      @map("file_count")
  lineCount  Int      @map("line_count")
  sizeBytes  BigInt   @map("size_bytes")
  createdAt  DateTime @default(now()) @map("created_at") @db.Timestamptz(6)

  @@unique([date, targetPath], map: "uq_codebase_folder_date_target")
  @@index([date])
  @@index([category])
  @@map("codebase_folder_metrics")
}
```

## 4. 표준 실행 절차 및 쿼리

### 4.1 측정 및 DB 일괄 적재
```bash
# 측정 실행 및 DB 업서트 스크립트 실행
.bin/import-codebase-metrics.sh --measure
```

### 4.2 데이터베이스 검증 쿼리 예시
```sql
-- 최근 5일간의 전체 요약 통계 확인
SELECT date, total_file_count, total_line_count, total_size_bytes, commit_hash, created_at
FROM daily_codebase_metrics
ORDER BY date DESC
LIMIT 5;

-- 오늘 날짜의 카테고리/폴더별 상세 통계 확인
SELECT category, target_path, file_count, line_count, size_bytes
FROM codebase_folder_metrics
WHERE date = CURRENT_DATE
ORDER BY category, target_path;
```

## 5. 핵심 원칙 및 안전 수칙

- **환경변수 보호**: DB URL이나 인증 토큰은 스크립트에 하드코딩하지 않고 `.env` 또는 키링(Secret Service)을 통해 주입한다.
- **Gitignore 처리**: 측정 중 생성되는 임시 CSV 파일은 `.gitignore`에 등록하여 저장소 오염을 방지하고, 최종 진실 공급원은 DB와 마크다운 문서로 삼다.
- **비간섭 크론 실행**: 크론 작업은 다른 운영 배치 작업과 겹치지 않는 새벽 시간대에 배치하고, 로그는 전용 로그 파일로 리다이렉트한다.

---

## Bound Tools

- `.bin/import-codebase-metrics.sh` — 코드베이스 측정 및 DB 적재 파이프라인
- `.github/scripts/measure_codebase.py` — 파일 분류 및 통계 산출 스크립트

## Input Schema

| Field | Required | Description |
|---|---|---|
| `action` | required | Action to execute: `measure` \| `import` \| `query` \| `sync-docs` |
| `date` | optional | Target date filter (YYYY-MM-DD) for queries |
