---
name: node-start-expert
description: Next.js 등 Node.js 개발 서버 구동 스크립트를 표준화하고 PostgreSQL 및 MySQL 컨테이너 연결을 검증하며 포트 충돌을 해소하는 범용 쉘 스크립트 라이브러리이다.
---

# node-start-expert

이 스킬은 프로젝트의 로컬 개발 서버 시작 스크립트를 표준화하여 보일러플레이트 코드를 줄이고 일관된 구동 환경을 제공하기 위한 공통 쉘 라이브러리이다.

## 포트 SSOT 정책 (MANDATORY)

> **원칙**: 프로젝트의 개발 서버 포트는 **단일 진실 공급원(Single Source of Truth)**으로만 관리하며, 여러 파일에 포트 번호를 하드코딩하지 않는다.

### 규칙

1. **SSOT 위치**: 포트 번호는 프로젝트의 `.bin/start-svr.sh` (또는 유사 구동 스크립트) 내 `PORT` 변수 **한 곳에만** 선언한다.
2. **하드코딩 금지**: `package.json`의 `scripts`, `next.config.js`, `.env`, `docker-compose.yml` 등 다른 파일에 동일 포트를 중복 기재하지 않는다. 필요하면 환경 변수 `$PORT`를 참조한다.
3. **기본값 3000 사용 금지**: Next.js, Vite, CRA 등 프레임워크 기본 포트(3000)를 그대로 사용하면 여러 프로젝트를 동시에 개발할 때 충돌이 발생한다.
4. **프로젝트별 고유 포트 고정 배정**: 새 프로젝트를 생성할 때 3001-9999 범위 중 다른 프로젝트와 겹치지 않는 임의의 고유 포트(예: 프로젝트 A는 항상 3084, 프로젝트 B는 항상 3154)를 1회 선정하여 SSOT에 선언하고 계속 고정으로 사용한다. (실행할 때마다 포트가 바뀌는 런타임 동적 할당이 아님!)
5. **PORT 선언 필수**: `PORT` 변수가 누락된 경우 서버 실행을 즉시 중단하고 고유 포트 설정을 요구한다. (명시적 실행 인자로 포트를 전달한 경우는 예외)

### 포트 결정 흐름

```
실행 인자로 포트 지정? (예: ./start-svr.sh 4000)  ──YES──▶  임시 커스텀 포트 사용
        │ NO
        ▼
SSOT(start-svr.sh)에 PORT 선언?                 ──YES──▶  프로젝트 고유 포트 사용 (예: 3084)
        │ NO
        ▼
에러 발생: PORT 미선언 (3001-9999 중 고유 포트를 SSOT에 선언해야 함)
```

## 주요 기능

1. **환경 변수 로드**: `.env` 및 `.env.local` 자동 감지 및 내보내기.
2. **포트 및 캐시 제거 옵션**: 실행 인자로 커스텀 포트 지정 및 캐시 디렉터리 제거 (`-rm`) 지원.
3. **포트 충돌 해소**: 프로젝트 고유 포트를 점유하고 있는 기존 프로세스를 `fuser`를 사용해 강제 종료 후 깨끗하게 재시작.
4. **의존 데이터베이스 검증**: PostgreSQL 연결 상태(`psql`) 및 레거시 MySQL 도커 컨테이너 실행 상태 확인.

## 설치 및 사용 방법

### 1. 공통 라이브러리 스크립트 위치
- 스크립트 파일: `~/ai-agent-configs/library/skills/node-start-expert/scripts/node-start.sh`

### 2. 프로젝트에 이식하는 방법
프로젝트의 `.bin/start-svr.sh` (혹은 유사한 개발 시작 스크립트)에 다음과 같이 변수를 선언한 뒤 공통 스크립트를 호출하도록 교체한다.

```bash
#!/usr/bin/env bash
set -e

# 프로젝트 고유 설정 정의
PROJ_NAME="prokseoul"
PORT="3084"                                    # ← 포트 SSOT: 3001-9999 중 고유 포트 1개 선언
LEGACY_MYSQL_CONTAINER="church_seoul_legacy_mysql"

# 공통 라이브러리 경로 지정
LIB_SCRIPT="$HOME/ai-agent-configs/library/skills/node-start-expert/scripts/node-start.sh"

if [ ! -f "$LIB_SCRIPT" ]; then
  echo "❌ 공통 라이브러리 스크립트를 찾을 수 없습니다: $LIB_SCRIPT"
  exit 1
fi

# 라이브러리 실행 (인자 전달)
source "$LIB_SCRIPT" "$@"
```
