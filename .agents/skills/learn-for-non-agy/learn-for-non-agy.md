---
name: learn-for-non-agy
title: 피드백을 메모리에 저장
description: 사용자의 피드백이나 규칙을 자동으로 분석하여 메모리 시스템에 저장하고 다음 세션에 반영
trigger: manual
env_vars: []
---

# /learn 워크플로

사용자가 제공한 피드백이나 규칙을 분석하여 메모리 시스템에 자동으로 저장한다.

## 사용법

```bash
/learn 이제부터 모든 커밋 메시지는 한글로 작성해줘

# 또는 에이전트 실수 후
/learn
```

## 동작 방식

1. **입력 분석**
   - 사용자 피드백 또는 규칙 텍스트 파싱
   - 메모리 타입 자동 분류 (user/feedback/project/reference)

2. **메모리 저장**
   - 메모리 디렉터리에 적절한 파일명으로 저장
   - frontmatter 형식 준수:
     ```markdown
     ---
     name: kebab-case-slug
     description: 한 줄 요약
     metadata:
       type: user|feedback|project|reference
     ---
     ```

3. **인덱스 동기화**
   - MEMORY.md에 새 항목 추가
   - 형식: `- [Title](file.md) — one-line hook`

4. **다음 세션 자동 반영**
   - 메모리 시스템이 자동으로 로드
   - 에이전트의 기본 지침으로 적용

## 메모리 타입

- **user**: 사용자 역할, 선호도, 책임 정보
- **feedback**: 에이전트 행동 개선에 대한 지침 (규칙 + Why + How to apply)
- **project**: 진행 중인 작업, 목표, 기한, 이슈 컨텍스트
- **reference**: 외부 시스템(Linear, Slack 등)의 정보 포인터

## 예시

```bash
/learn 모든 Python 함수에는 docstring을 붙여줘. 이유는 타입 힌팅과 IDE 자동완성을 개선하기 위함

/learn 이 프로젝트는 모든 PR을 main으로 병합하기 전에 QA팀의 검증을 거쳐야 함

/learn 버그는 Linear의 "INGEST" 프로젝트에서 추적됨
```
