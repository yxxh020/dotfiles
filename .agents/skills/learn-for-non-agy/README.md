# /learn 워크플로

사용자 피드백과 규칙을 자동으로 메모리 시스템에 저장하고, 다음 세션에서 자동으로 반영하는 워크플로이다.

## 설치

```bash
# 옵션 1: 프로젝트에 직접 복사
cp -r ~/tmp/learn .agents/workflows/learn

# 옵션 2: 심볼릭 링크 (권장)
ln -s ~/tmp/learn ~/.agents/workflows/learn
```

## 사용법

### 기본 사용
```bash
/learn 이제부터 모든 Python 함수에는 docstring을 붙여줘
```

### 에이전트 실수 후 교정
```bash
# 에이전트가 실수했을 때
/learn 커밋 메시지는 항상 한글로 작성해줘. 지금까지 영어로만 써서 일관성이 없었음

# 더 자세한 feedback
/learn 모든 스크립트는 .bin 폴더에 저장하고, harness-check.sh로 검증해줘. 
이전에 스크립트를 잘못된 위치에 넣었거든
```

## 메모리 타입

워크플로가 입력을 분석하여 자동으로 다음 4가지 중 하나로 분류합니다:

| 타입 | 특징 | 예시 |
|------|------|------|
| **feedback** | 에이전트 행동 개선 규칙 | "이제부터 항상 X 해줘", "X 하지 말아줘" |
| **project** | 진행 중인 작업, 기한, 이슈 | "마감은 3월 5일", "이 프로젝트는 QA 검증 필수" |
| **user** | 사용자 역할, 선호도, 특성 | "나는 Go 전문가", "한국어 설명 선호" |
| **reference** | 외부 시스템 정보 | "버그는 Linear에서 추적", "Grafana 대시보드는 ..." |

## 동작 원리

```
사용자 입력
    ↓
타입 자동 감지
    ↓
slug & description 생성
    ↓
메모리 파일 저장 (frontmatter 포함)
    ↓
MEMORY.md 인덱스 업데이트
    ↓
✅ 다음 세션 자동 로드
```

### 생성되는 메모리 파일 예

```markdown
---
name: python-docstring-rule
description: 이제부터 모든 Python 함수에는 docstring을...
metadata:
  type: feedback
  created_at: 2026-08-04T17:01:23+09:00
---

이제부터 모든 Python 함수에는 docstring을 붙여줘
```

## 메모리 디렉터리

- **프로젝트 메모리**: `/data/hyuk/.claude/projects/-data-hyuk-dotfiles/memory/`
- **글로벌 메모리**: `/data/hyuk/.claude/memory/`

스크립트가 자동으로 감지하여 첫 번째로 찾은 디렉터리를 사용한다.

## 테스트

```bash
# 기본 테스트
~/tmp/learn/learn.sh "이제부터 한글로만 답변해줘"

# 타입 감지 테스트
~/tmp/learn/learn.sh "이 프로젝트는 2월 28일에 배포해야 함"

# 메모리 확인
ls -la ~/.claude/projects/-data-hyuk-dotfiles/memory/
cat ~/.claude/projects/-data-hyuk-dotfiles/memory/MEMORY.md
```

## 주의사항

- 메모리 디렉터리가 없으면 오류가 발생한다
- 기존 메모리 파일이 있으면 내용을 덮어씁니다
- MEMORY.md의 인덱스는 수동으로 정렬되지 않으니 필요시 직접 정렬해라
- 너무 긴 입력은 70자로 자동 잘림됩니다 (더 자세한 내용은 본문에 저장)

## 앞으로의 확장

- [ ] 기존 메모리 파일 병합 (자동 중복 제거)
- [ ] MEMORY.md 자동 정렬
- [ ] 피드백 Why/How to apply 구조 자동 추출
- [ ] 슬래시 커맨드 통합 (`/learn` → 직접 워크플로 실행)
