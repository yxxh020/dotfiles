#!/usr/bin/env bash
# 공통 node 개발 서버 시작 스크립트 라이브러리
# 이 스크립트는 각 프로젝트의 로컬 구동 스크립트에서 source 하여 사용합니다.

set -e

# 호출한 스크립트가 정의한 변수가 없을 때의 기본값 설정
PROJ_NAME="${PROJ_NAME:-Node App}"
DEFAULT_PORT="${PORT:-}" # 기본 포트 (비어있을 수 있음)
CLEAN_CACHE=false
PORT="$DEFAULT_PORT"

# 전달된 아규먼트 파싱
for arg in "$@"; do
  if [ "$arg" = "-rm" ]; then
    CLEAN_CACHE=true
  elif [[ "$arg" =~ ^[0-9]+$ ]]; then
    PORT="$arg"
  fi
done

# ── 포트 SSOT 검증 (PORT 필수 선언) ──
if [ -z "$PORT" ]; then
  echo "❌ [오류] 개발 서버 포트(PORT)가 선언되지 않았습니다."
  echo "   포트 SSOT 원칙에 따라 구동 스크립트(예: .bin/start-svr.sh)에 프로젝트 고유 포트를 선언해야 합니다."
  echo "   (예: PORT=\"3084\" — 3001-9999 범위 권장, 기본 3000 사용 금지)"
  exit 1
fi

# PROJ_ROOT가 정의되지 않았다면 호출 스크립트 기준으로 탐색
if [ -z "$PROJ_ROOT" ]; then
  # source 한 스크립트 파일의 경로를 추적
  # BASH_SOURCE[1]은 source를 호출한 스크립트
  CALLER_SOURCE="${BASH_SOURCE[1]}"
  if [ -z "$CALLER_SOURCE" ]; then
    CALLER_SOURCE="${BASH_SOURCE[0]}"
  fi
  PROJ_ROOT="$(cd "$(dirname "$CALLER_SOURCE")/.." && pwd)"
fi
cd "$PROJ_ROOT"

# 0. .env 로드
load_env() {
  local env_file="$1"
  if [ -f "$env_file" ]; then
    while IFS= read -r line || [ -n "$line" ]; do
      case "$line" in
        \#*|""|[[:space:]]*) continue ;;
      esac
      eval "export $line" 2>/dev/null || true
    done < "$env_file"
  fi
}
load_env "$PROJ_ROOT/.env"
load_env "$PROJ_ROOT/.env.local"

echo "======================================"
echo "  ${PROJ_NAME} 로컬 개발 서버 시작"
echo "  포트: ${PORT}"
if [ "$CLEAN_CACHE" = true ]; then
  echo "  옵션: 캐시 제거 활성화 (-rm)"
fi
echo "======================================"

# 1. PostgreSQL 연결 확인 (DATABASE_URL이 설정된 경우만)
if [ -n "$DATABASE_URL" ]; then
  echo ""
  echo "[1/3] PostgreSQL 연결 확인..."
  db_ok=false
  # Prisma 전용 파라미터(?schema=public 등)를 제거하여 psql 호환 URL 생성
  DB_URL_FOR_PSQL="${DATABASE_URL%%\?*}"
  if command -v psql >/dev/null 2>&1; then
    if psql "$DB_URL_FOR_PSQL" -c "SELECT 1;" > /dev/null 2>&1; then
      db_ok=true
    fi
  elif command -v node >/dev/null 2>&1; then
    if node -e "
      try {
        const raw = process.env.DATABASE_URL || '';
        const u = new URL(raw.replace(/^(postgresql|postgres):/, 'http:'));
        const net = require('net');
        const s = net.createConnection({ port: Number(u.port) || 5432, host: u.hostname || 'localhost', timeout: 3000 }, () => {
          s.end();
          process.exit(0);
        });
        s.on('error', () => process.exit(1));
        s.on('timeout', () => { s.destroy(); process.exit(1); });
      } catch (_) { process.exit(1); }
    " >/dev/null 2>&1; then
      db_ok=true
    fi
  fi

  if [ "$db_ok" = true ]; then
    echo "  ✅ DB 연결 성공"
  else
    echo "  ❌ DB 연결 실패 - PostgreSQL이 실행 중인지 확인하세요"
    echo "     DATABASE_URL: ${DATABASE_URL}"
    exit 1
  fi
else
  echo ""
  echo "[1/3] PostgreSQL 연결 확인 건너뜀 (DATABASE_URL 미설정)"
fi

# 2. 레거시 MySQL 컨테이너 상태 확인 (설정된 컨테이너가 있고 docker가 구동 중인 경우만)
if [ -n "$LEGACY_MYSQL_CONTAINER" ]; then
  echo ""
  echo "[2/3] 레거시 MySQL 컨테이너 상태..."
  if command -v docker >/dev/null 2>&1 && docker ps --format '{{.Names}}' 2>/dev/null | grep -q "$LEGACY_MYSQL_CONTAINER"; then
    echo "  ✅ ${LEGACY_MYSQL_CONTAINER} 실행 중"
  else
    echo "  ℹ️  레거시 MySQL 미실행 (마이그레이션 작업 시에만 필요)"
  fi
else
  echo ""
  echo "[2/3] 레거시 MySQL 컨테이너 확인 건너뜀"
fi

# 3. 포트 충돌 해소
echo ""
echo "[3/4] 포트 ${PORT} 점유 확인..."
if fuser "${PORT}/tcp" >/dev/null 2>&1; then
  echo "  ⚠️  포트 ${PORT}을 사용 중인 프로세스 발견 → 종료합니다"
  fuser -k "${PORT}/tcp" >/dev/null 2>&1 || true
  sleep 1
  # SIGTERM으로 안 죽으면 SIGKILL
  if fuser "${PORT}/tcp" >/dev/null 2>&1; then
    fuser -k -KILL "${PORT}/tcp" >/dev/null 2>&1 || true
    sleep 1
  fi
  echo "  ✅ 기존 프로세스 종료 완료"
else
  echo "  ✅ 포트 ${PORT} 사용 가능"
fi

# 4. 캐시 제거 및 Next.js 개발 서버 실행
CACHE_DIR="${CACHE_DIR:-$PROJ_ROOT/.next}"
echo ""
if [ "$CLEAN_CACHE" = true ] && [ -d "$CACHE_DIR" ]; then
  echo "[4/4] 캐시 디렉터리 제거 중 (${CACHE_DIR})..."
  rm -rf "$CACHE_DIR"
  echo "  ✅ 캐시 제거 완료"
  echo ""
else
  echo "[4/4] 개발 서버 시작 중..."
fi

# 시작 명령어 설정 (START_CMD가 없으면 pnpm exec next dev 기본)
if [ -z "$START_CMD" ]; then
  START_CMD="pnpm exec next dev --port $PORT"
fi

echo "  → ${START_CMD}"
echo ""

eval "$START_CMD"
