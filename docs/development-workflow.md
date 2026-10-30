# 개발 환경 및 작업 흐름

## 1. 비밀값 관리 — KeePassXC + secret-tool

### 원칙

> **`.env` 파일 금지** — 모든 민감 정보는 KeePassXC 금고에 저장하고, `secret-tool`로 런타임 주입한다.

### 아키텍처

```
KeePassXC 금고 (.kdbx)
    ↓ Secret Service D-Bus API
secret-tool (CLI)
    ↓ 셸 변수 주입
애플리케이션 프로세스
```

### 사용법

```bash
# 비밀값 조회
secret-tool lookup service "myapp" account "db-password"

# 비밀값 저장
echo -n "my-secret-value" | secret-tool store \
  --label="MyApp DB Password" \
  service "myapp" account "db-password"

# 셸 스크립트에서 환경변수로 주입
export DATABASE_URL="postgresql://user:$(secret-tool lookup service myapp account db-password)@localhost:5432/mydb"
```

### macOS 환경

macOS에서는 KeePassXC의 Secret Service 대신 Keychain Access를 활용하거나,
KeePassXC의 CLI(`keepassxc-cli`)를 직접 사용한다:

```bash
keepassxc-cli show -s -a Password ~/Passwords.kdbx "MyApp/DB"
```

---

## 2. Docker Compose PostgreSQL 설정

### 기본 구성

```yaml
# docker-compose.yml
services:
  postgres:
    image: postgres:16-alpine
    container_name: myapp-postgres
    restart: unless-stopped
    ports:
      - "5432:5432"
    environment:
      POSTGRES_USER: myapp
      POSTGRES_PASSWORD_FILE: /run/secrets/db_password
      POSTGRES_DB: myapp_dev
    volumes:
      - postgres_data:/var/lib/postgresql/data
    secrets:
      - db_password

secrets:
  db_password:
    file: /dev/stdin  # 런타임에 secret-tool로 주입

volumes:
  postgres_data:
```

### 시작 스크립트

```bash
#!/bin/bash
# start-db.sh
secret-tool lookup service myapp account db-password | \
  docker compose up -d postgres
```

---

## 3. Prisma 마이그레이션

### 워크플로우

```
schema.prisma 수정
    ↓
prisma migrate dev --name <설명>
    ↓
prisma generate
    ↓
prisma db seed (필요 시)
```

### 규칙

1. 마이그레이션 이름은 한글로 작성 (예: `--name 사용자_프로필_추가`)
2. 프로덕션 마이그레이션은 `prisma migrate deploy`만 사용
3. `prisma db push`는 프로토타이핑 단계에서만 허용
4. 시드 데이터는 `prisma/seed.ts`에서 관리

---

## 4. Git 훅 체계 (6종)

### 설치

프로젝트 루트에서 `install-hooks.sh` 실행 또는 수동으로 `.git/hooks/`에 배치.

### 훅 목록

| # | 훅 | 목적 | 실행 내용 |
|---|-----|------|----------|
| 1 | `pre-commit` | 코드 품질 게이트 | lint-staged (ESLint + Prettier) 실행 |
| 2 | `commit-msg` | 커밋 메시지 규칙 강제 | Conventional Commits 프리픽스 + 한글 검증 |
| 3 | `pre-push` | 배포 안전망 | 단위 테스트 실행 + 타입 체크 |
| 4 | `post-merge` | 의존성 동기화 | `pnpm install` 자동 실행 (lockfile 변경 감지) |
| 5 | `post-checkout` | 브랜치 전환 후 정리 | 의존성 재설치 + Prisma generate |
| 6 | `prepare-commit-msg` | 커밋 템플릿 | 브랜치명에서 이슈 번호 자동 추출 |

### commit-msg 훅 예시

```bash
#!/bin/bash
# .git/hooks/commit-msg

COMMIT_MSG_FILE=$1
COMMIT_MSG=$(cat "$COMMIT_MSG_FILE")

# Conventional Commits 프리픽스 검증
if ! echo "$COMMIT_MSG" | grep -qE "^(feat|fix|docs|style|refactor|perf|test|chore|build|ci|revert)(\(.+\))?: .+"; then
  echo "❌ 커밋 메시지가 Conventional Commits 형식이 아닙니다."
  echo "   예시: feat: 사용자 프로필 페이지 추가"
  exit 1
fi

# 한글 포함 여부 검증
if ! echo "$COMMIT_MSG" | grep -qP '[\x{AC00}-\x{D7A3}]'; then
  echo "❌ 커밋 메시지에 한글이 포함되어야 합니다."
  exit 1
fi
```

---

## 5. 배포 환경 (Rocky Linux + Docker)

### 배포 아키텍처

```
Rocky Linux 9 (프로덕션 서버)
├── Docker Engine
│   ├── nginx (리버스 프록시, SSL 종료)
│   ├── app (Next.js / NestJS 컨테이너)
│   ├── postgres (PostgreSQL 16)
│   └── redis (캐시, 선택사항)
├── systemd (Docker 서비스 자동 시작)
└── firewalld (포트 제어)
```

### 배포 명령

```bash
# 프로덕션 배포
docker compose -f docker-compose.prod.yml up -d --build

# 롤백
docker compose -f docker-compose.prod.yml down
docker compose -f docker-compose.prod.yml up -d --no-build
```

---

## 6. 보안 검사 정책

### 자동 검사 (CI/CD)

- `pnpm audit` — 의존성 취약점 검사
- `eslint-plugin-security` — 정적 보안 분석
- `prisma validate` — 스키마 무결성 검증

### 수동 검사 (배포 전)

- [ ] `.env` 파일이 커밋되지 않았는지 확인
- [ ] 하드코딩된 시크릿이 없는지 `grep` 검색
- [ ] Docker 이미지에 불필요한 파일이 포함되지 않았는지 확인
- [ ] HTTPS 리디렉션 정상 동작 확인

---

## 7. 환경변수 정책

| 구분 | 로컬 개발 | 테스트 | 프로덕션 |
|------|----------|--------|---------|
| DB URL | secret-tool 주입 | Docker 시크릿 | Docker 시크릿 |
| API 키 | secret-tool 주입 | CI/CD 시크릿 | Docker 시크릿 |
| 공개 설정 | `.env.local` 허용 | `.env.test` 허용 | Docker ENV |
| 민감 정보 | ❌ .env 금지 | ❌ .env 금지 | ❌ .env 금지 |

> **규칙**: `NEXT_PUBLIC_*` 등 클라이언트 노출 변수만 `.env.local`에 허용.
> 그 외 모든 민감 변수는 KeePassXC → secret-tool 경로로만 주입한다.
