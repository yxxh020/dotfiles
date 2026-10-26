---
name: prevent-root-files
description: "프로젝트 루트 디렉터리에 불필요한 파일이 직접 생성되거나 커밋되는 것을 감지하고 차단하는 가이드 및 스크립트 템플릿"
---

# 프로젝트 루트 파일 생성 방지 스킬 (prevent-root-files)

이 스킬은 프로젝트 루트 디렉터리가 깔끔하게 유지되도록 불필요한 임시 파일이나 소스 코드 파일 등이 루트 디렉터리에 직접 생성 또는 커밋되는 것을 방지하기 위한 지침과 스크립트 템플릿을 정의한다.

## 1. 개요 및 목적
- 프로젝트 루트 디렉터리는 프로젝트 설정 파일 및 핵심 문서(`README.md`, `package.json`, `.gitignore` 등)로만 한정하여 깨끗하게 유지해야 한다.
- 개발 과정에서 실수로 생성되는 디버그 로그, 덤프 데이터, 임시 쿼리 결과물 등이 루트에 방치되어 불필요하게 커밋되는 상황을 예방한다.

## 2. 작동 방식 및 검증 게이트
이 스킬은 커밋 단계(Pre-commit)에서 다음 두 가지 이중 검증을 실행하여 정책을 준수하게 한다.

### A. 물리적 파일 스캔 (Disk Scan)
로컬 프로젝트 루트 폴더에 존재하는 물리적인 파일들을 감지하여, 사전 승인된 파일 목록(허용 리스트)에 속하지 않은 임시 파일이 발견되면 커밋을 중단시킵니다.

### B. Git 스테이징 스캔 (Git Stage Scan)
`git add`를 통해 루트 디렉터리에 직접적인 경로로 추가(A)되거나 변경(M)되는 새로운 파일이 스테이징 영역에 존재하는지 확인하고, 승인되지 않은 파일의 커밋을 차단한다.

**(선택적) Jev 고속 사전 판정**:
`command -v jev` 확인 시 스테이징된 파일 목록을 Jev에 주입하여 루트 오염 여부를 0.1초 만에 검증할 수 있다:
```bash
STAGED_FILES=$(git diff --cached --name-only)
HAS_ROOT_FILES=$(echo "$STAGED_FILES" | jev -y "Are there any files located directly in the root directory rather than subdirectories?" -q)
```

## 3. 스크립트 템플릿 (`harness-check.sh` 연동)
프로젝트 무결성 검사 스크립트(`.bin/harness-check.sh` 등)에 아래 검증 로직을 추가하여 Husky 등 Git 훅 도구와 연동한다.

```bash
# Project Root File Creation Prevention Check
echo "🔍 Checking for unauthorized files in project root..."

# Regex pattern of allowed files directly in the root directory
# (프로젝트 환경에 따라 허용 목록을 업데이트하십시오)
ALLOWED_FILES="^(AGENTS\.md|CLAUDE\.md|Dockerfile|README\.md|docker-compose\.yml|hyanglin\.conf|remote_setup\.sh|skills-lock\.json|\.env|\.env\.example|\.env\.local|\.env\.production|\.env\.test|\.gitignore)$"

UNAUTHORIZED_FILES=""

# Physical scan of the root directory for any unauthorized files
PHYSICAL_FILES=$(find "$ROOT_DIR" -maxdepth 1 -type f)
if [ -n "$PHYSICAL_FILES" ]; then
  while IFS= read -r filepath; do
    filename=$(basename "$filepath")
    if ! echo "$filename" | grep -qE "$ALLOWED_FILES"; then
      UNAUTHORIZED_FILES="$UNAUTHORIZED_FILES\n  - $filename"
    fi
  done <<< "$PHYSICAL_FILES"
fi

# Git stage scan for unauthorized staged files in root
STAGED_ROOT_FILES=$(git diff --cached --name-only | grep -v '/' || true)
if [ -n "$STAGED_ROOT_FILES" ]; then
  for file in $STAGED_ROOT_FILES; do
    if ! echo "$file" | grep -qE "$ALLOWED_FILES"; then
      UNAUTHORIZED_FILES="$UNAUTHORIZED_FILES\n  - $file (staged)"
    fi
  done
fi

if [ -n "$UNAUTHORIZED_FILES" ]; then
  echo -e "[ERROR] Unauthorized files detected in project root directory:$UNAUTHORIZED_FILES"
  echo "Root folder must remain clean. Please create files inside appropriate subdirectories (e.g. tmp/ for temporary files, web/ for code, docs/ for documents)."
  exit 1
else
  echo "  ✓ [OK] No unauthorized files found in root directory."
fi
```

## 4. 적용 절차 및 팁
1. **허용 패턴(Whitelist) 설정**: 각 프로젝트의 성격에 맞춰 루트에 보존해야 할 파일 목록을 `ALLOWED_FILES` 정규식에 정확하게 기재한다.
2. **Husky 연동**: `pre-commit` 훅에서 검사 스크립트를 먼저 실행하도록 트리거를 구성한다.
3. **팀 간 공유**: `package.json` 등의 `prepare` 단계에 `git config core.hooksPath`를 등록하여 팀원 전체가 패키지 설치 시 자동으로 동일한 검증이 동작하도록 설정한다.
