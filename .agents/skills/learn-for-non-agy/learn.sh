#!/bin/bash
# /learn 워크플로 - 피드백을 메모리에 저장

set -e

# 색상 정의 (tput 사용 또는 ANSI 코드)
if command -v tput &> /dev/null; then
    GREEN=$(tput setaf 2)
    YELLOW=$(tput setaf 3)
    RED=$(tput setaf 1)
    NC=$(tput sgr0)
else
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    RED='\033[0;31m'
    NC='\033[0m'
fi

# 메모리 디렉터리 결정
MEMORY_DIR=""
if [ -d "/data/hyuk/.claude/projects/-data-hyuk-dotfiles/memory" ]; then
    MEMORY_DIR="/data/hyuk/.claude/projects/-data-hyuk-dotfiles/memory"
elif [ -d "/data/hyuk/.claude/memory" ]; then
    MEMORY_DIR="/data/hyuk/.claude/memory"
else
    printf "${RED}❌ 메모리 디렉터리를 찾을 수 없습니다${NC}\n"
    exit 1
fi

# 입력 텍스트 가져오기
INPUT="${*}"

if [ -z "$INPUT" ]; then
    printf "${YELLOW}⚠️  피드백 내용을 입력해주세요${NC}\n"
    echo "사용법: /learn [기억할 내용]"
    echo ""
    echo "예시:"
    echo "  /learn 이제부터 모든 함수에 docstring을 붙여줘"
    echo "  /learn 이 프로젝트는 PR 전에 QA 검증이 필수"
    exit 0
fi

# 메모리 타입 자동 감지
detect_type() {
    local text="$1"

    # feedback 키워드 (규칙, 방향 지시)
    if [[ "$text" =~ (이제부터|앞으로|항상|절대|금지|금지하지 말고|해줘|주셨|피해줘|다음부터) ]]; then
        echo "feedback"
    # project 키워드 (일정, 진행 상태, 이슈)
    elif [[ "$text" =~ (마감|기한|일정|이슈|버그|프로젝트|진행|완료|예정) ]]; then
        echo "project"
    # reference 키워드 (외부 시스템, 위치)
    elif [[ "$text" =~ (Linear|Slack|Grafana|문서|저장소|URL|링크|위치|찾기) ]]; then
        echo "reference"
    # user 키워드 (역할, 특성, 선호도)
    elif [[ "$text" =~ (나는|하고 있|전문|경험|선호|좋아|싫어) ]]; then
        echo "user"
    else
        # 기본값: feedback (대부분의 에이전트 행동 개선)
        echo "feedback"
    fi
}

# kebab-case slug 생성
create_slug() {
    local text="$1"
    # 첫 40글자를 기준으로 slug 생성 (한글/영문 섞임 지원)
    local slug=$(echo "$text" | head -c 40 | tr '[:upper:]' '[:lower:]' | perl -pe 's/[^a-z0-9가-힣]/-/g' | perl -pe 's/-+/-/g' | perl -pe 's/^-+|-+$//g')

    # slug가 비어있으면 timestamp 사용
    if [ -z "$slug" ]; then
        slug="memory-$(date +%s)"
    fi
    echo "$slug"
}

# 타입에 맞는 설명 생성
create_description() {
    local text="$1"
    # 첫 60자를 설명으로 사용
    echo "$text" | head -c 70 | sed 's/[[:space:]]*$//'
}

# 메모리 파일 생성
MEMORY_TYPE=$(detect_type "$INPUT")
SLUG=$(create_slug "$INPUT")
DESCRIPTION=$(create_description "$INPUT")

# 타임스탬프로 고유성 보장
TIMESTAMP=$(date +%s)
MEMORY_FILE="${MEMORY_DIR}/${MEMORY_TYPE}_${SLUG}_${TIMESTAMP}.md"

# 파일 경로 단축 (같은 이름 파일이 있으면 번호 추가)
BASE_FILE="${MEMORY_DIR}/${MEMORY_TYPE}_${SLUG}.md"
if [ -f "$BASE_FILE" ]; then
    MEMORY_FILE="$BASE_FILE"
    echo -e "${YELLOW}⚠️  기존 메모리 파일을 업데이트합니다${NC}"
fi

# frontmatter 생성
cat > "$MEMORY_FILE" << EOF
---
name: $(echo "$SLUG" | perl -pe 's/_/-/g')
description: $DESCRIPTION
metadata:
  type: $MEMORY_TYPE
  created_at: $(date -Iseconds)
---

$INPUT
EOF

cat << RESULT
${GREEN}✅ 메모리 저장 완료${NC}
   타입: ${YELLOW}$MEMORY_TYPE${NC}
   파일: $(basename "$MEMORY_FILE")

RESULT

# MEMORY.md 인덱스 업데이트 (존재할 경우)
MEMORY_INDEX="${MEMORY_DIR}/MEMORY.md"
if [ -f "$MEMORY_INDEX" ]; then
    # 이미 인덱스에 있는지 확인
    if ! grep -q "$(basename "$MEMORY_FILE")" "$MEMORY_INDEX"; then
        # 새 항목 추가
        cat >> "$MEMORY_INDEX" << INDEX_ENTRY
- [$DESCRIPTION]($(basename "$MEMORY_FILE")) — $MEMORY_TYPE
INDEX_ENTRY
        cat << RESULT
${GREEN}✅ MEMORY.md에 인덱스 추가${NC}

RESULT
    else
        cat << RESULT
${YELLOW}ℹ️  인덱스는 이미 존재합니다${NC}

RESULT
    fi
else
    cat << RESULT
${YELLOW}⚠️  MEMORY.md를 찾을 수 없습니다${NC}

RESULT
fi

echo "다음 세션에서 자동으로 반영됩니다 🚀"
