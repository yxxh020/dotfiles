---
name: prisma-docker-deploy-expert
description: 프로덕션 Docker 환경에서 Prisma 시드/마이그레이션 스크립트와 TypeScript CLI 도구를 설정하고 디버깅하는 배포 전문가 스킬.
---

> **[안내]** 이 파일은 각 프로젝트가 복사해갈 때 프로젝트 상황에 맞게 수정하여 사용하는 템플릿이다.
> 적용 시 이 안내 문구를 제거하고 프로젝트에 맞게 내용을 수정한다.

# Prisma Docker 배포 전문가

## 1. 목적 (Purpose)

로컬 개발 환경(`ts-node` 중심)과 프로덕션 도커 환경(컴파일된 `js` 파일과 `devDependencies` 부재) 간의 불일치로 인해 발생하는 Prisma seed 및 일회성 스크립트 실행 오류를 사전에 예방하고 올바른 아키텍처로 수정하기 위한 에이전트 지침이다.

(예: `Cannot find module`, `ts-node: not found` 에러 방지)

## 2. 핵심 원칙 (Core Principles)

- **개발 의존성 제거:** 프로덕션 Docker 이미지(Node.js multi-stage 빌드)에는 `ts-node`나 `typescript`가 포함되지 않음을 항상 전제로 한다 (예: `npm ci --only=production`).
- **스크립트 사전 컴파일:** 프로덕션 컨테이너 내부에서 실행되어야 할 모든 `.ts` 스크립트는 **빌드 파이프라인에 포함되는 `src/` 하위**로 이동시켜 함께 트랜스파일되도록 한다.
- **실행 명령어 분리 (Local vs Prod):** `package.json`에서 로컬 개발용 명령어와 프로덕션 배포용 실행 명령어를 명확히 분리한다.

## 3. 작업 절차 (Action Guidelines)

1. **스크립트 위치 강제 적용:**
   - `scripts/*.ts` 또는 `prisma/seed.ts` 파일이 프로덕션에서 실행될 필요가 있다면 즉시 `src/scripts/` 내부로 이동한다.

2. **`package.json` 스크립트 구성:**
   ```json
   "scripts": {
     "seed:example": "ts-node src/scripts/seed_example.ts",
     "seed:example:prod": "node dist/src/scripts/seed_example.js"
   }
   ```
   - 프로덕션 커맨드는 반드시 순수 `node`를 사용하며, 빌드 결과물인 `dist/src/scripts/...` 경로를 정확히 참조해야 한다.

3. **CI/CD 파이프라인 적용 (마이그레이션 & 시드):**
   - 새 컨테이너 구동 직후 반드시 `docker compose exec -T <service> npx prisma migrate deploy`가 포함되어 있는지 확인하여 스키마 불일치 사고를 예방한다.
   - Docker 컨테이너로 원격 실행하는 구문을 작성할 때는 반드시 `:prod`가 붙은 명령어를 사용한다.

4. **빌드 검증:**
   - 로컬에서 `yarn build` 또는 `npm run build` 실행 후 `dist/src/scripts/` 하위에 해당 파일의 트랜스파일된 `.js` 파일이 실제로 생성되는지 검증한다.

## 4. 트리거 조건 (When to Invoke)

- "시드가 배포 환경에서 안 돌아가요", "도커 안에서 파일을 찾을 수 없대요"라고 피드백할 때.
- `package.json`의 `seed` 관련 스크립트나 일회성 데이터 스크립트를 신규 작성할 때.
- CI/CD 배포 프로세스 내에서 `docker exec` 또는 `docker compose exec`로 백엔드 스크립트를 호출하는 부분을 작성/디버깅할 때.

---

## 하네스 연동

### 단계 0 — 레슨 로드
이 스킬을 사용하는 작업을 시작하기 전에 다음을 읽는다:
- `.agents/learnings/general.md`
- `.agents/learnings/prisma-docker-deploy-expert.md`

관련 레슨을 먼저 적용한 뒤 진행한다.

### 단계 5 — 레슨 기록
중요한 작업 완료 후, 다음 경우에 해당하면 `.agents/learnings/prisma-docker-deploy-expert.md`에 레슨을 추가한다:
- 예상보다 어려웠던 부분이 있었을 때
- 반복될 패턴이 발견되었을 때
- 다음에 방지해야 할 실수를 했을 때
- 사용자가 출력 결과를 의미 있게 수정했을 때

> 레슨이 **3회 이상** 반복되면 → `rules-project.md` 또는 프로젝트 규칙 반영 후보로 승격한다.

### ⛔ 혼자 결정하면 안 되는 사항
- 프로덕션 Docker 컨테이너에 시드 스크립트 실행
- Dockerfile 베이스 이미지 버전 변경
- 사전 DB 연결 확인 스킵 미수행
