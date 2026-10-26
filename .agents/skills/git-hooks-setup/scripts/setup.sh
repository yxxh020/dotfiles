#!/bin/bash
# Git Hooks 설정 스크립트 템플릿

# 에러 발생 시 즉시 중단
set -e

# 스크립트 위치 기준 경로 감지
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Git 저장소의 최상위 루트 탐색
PROJECT_ROOT=$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel 2>/dev/null)

if [ -z "$PROJECT_ROOT" ]; then
    echo "❌ 에러: Git 저장소 내부에서 실행해 주세요."
    exit 1
fi

HOOKS_DIR="$PROJECT_ROOT/.git/hooks"
SOURCE_HOOK="$SCRIPT_DIR/commit-msg"
TARGET_HOOK="$HOOKS_DIR/commit-msg"

echo "🔄 Git Hook 설정을 시작합니다..."

# hooks 디렉터리가 없으면 생성
mkdir -p "$HOOKS_DIR"

# commit-msg 복사 및 권한 부여
if [ -f "$SOURCE_HOOK" ]; then
    cp "$SOURCE_HOOK" "$TARGET_HOOK"
    chmod +x "$TARGET_HOOK"
    echo "✅ Git commit-msg 훅이 성공적으로 설정되었습니다."
else
    echo "❌ 에러: 원본 commit-msg 훅 파일을 찾을 수 없습니다 ($SOURCE_HOOK)."
    exit 1
fi
