---
name: topic-history-search
description: 과거 진행했던 주제에 대해 Git 커밋 이력, GitHub 이슈/PR, AI 대화 트랜스크립트 로그 및 프로젝트 학습 문서에서 통합 탐색하고 맥락을 복원하는 스킬.
---

# 통합 주제 및 과거 히스토리 탐색 스킬 (`topic-history-search`)

사용자가 과거 작업했던 기록, 비슷한 주제의 이슈/커밋, 또는 과거 AI 에이전트와의 대화 내용을 찾고자 할 때 통합 검색 및 맥락 복원을 수행한다.

---

## 1. 트리거 조건
다음과 같은 사용자 요청이 있을 때 이 스킬을 호출합니다:
- "이전에 이 관련 작업 한 적 있나?"
- "과거 대화나 커밋에서 X 주제 찾아줘"
- "비슷한 이슈나 해결 이력 검색해줘"
- "과거 기록/주제 찾아보기"

---

## 2. 통합 탐색 4대 영역 및 명령

### A. AI 대화 트랜스크립트 (Conversation History) 검색
AI 에이전트의 과거 대화 로그에서 키워드를 탐색한다.
- **기본 경로**: `/data/hyuk/.gemini/antigravity/brain/`
- **검색 명령**:
  ```bash
  grep -rnI --include="transcript.jsonl" "<키워드>" /data/hyuk/.gemini/antigravity/brain/ 2>/dev/null | head -n 20
  ```
- **맥락 추출**:
  검색된 line에서 `conversation_id`(경로상의 UUID)를 파악하고, 해당 대화의 `summary` 및 주요 질의/답변을 확인한다.

### B. Git 커밋 이력 (Git Commit Logs) 검색
현재 저장소 및 로컬 저장소의 모든 브랜치 커밋 로그에서 키워드 또는 특정 코드 변경을 탐색한다.
- **메시지 검색**:
  ```bash
  git log --all --grep="<키워드>" -n 10 --oneline
  ```
- **코드/문자열 변경 검색**:
  ```bash
  git log --all -S "<키워드>" -n 10 --oneline
  ```

### C. GitHub 이슈 및 PR (GitHub Issues & PRs) 검색
GitHub CLI(`gh`)를 활용하여 등록된 이슈 및 PR 목록에서 검색한다.
- **이슈 검색**:
  ```bash
  gh issue list --state all --search "<키워드>" --limit 10
  ```
- **PR 검색**:
  ```bash
  gh pr list --state all --search "<키워드>" --limit 10
  ```

### D. 프로젝트 학습 및 저장소 문서 (Project Learnings & Docs) 검색
프로젝트 내 기록된 레슨, 워크플로, 문서 등을 탐색한다.
- **레슨/문서 검색**:
  ```bash
  grep -rnI "<키워드>" .agents/learnings/ docs/ archive/ 2>/dev/null | head -n 15
  ```

---

## 3. 결과 보고 템플릿

검색을 수행한 후 발견된 이력을 아래 구조로 정돈하여 보고합니다:

```markdown
### 🔍 주제 히스토리 탐색 결과: `<검색어>`

#### 1. 💬 과거 AI 대화 기록
- **대화 ID**: `<conversation-id>` (날짜: YYYY-MM-DD)
  - **주요 내용**: <대화 내용 요약>

#### 2. 🔀 관련 Git 커밋
- `<commit-hash>` <커밋 제목> (`<작성일자>`)

#### 3. 📌 관련 GitHub 이슈 & PR
- `#<이슈번호>` <이슈/PR 제목> (`<상태: OPEN/CLOSED>`)

#### 4. 📚 프로젝트 문서 및 레슨
- `[파일명](file:///상세경로)`: <주요 언급 내용>

---
💡 **결론 및 추천 조치**: <과거 맥락 기반의 추천 또는 다음 단계 지침>
```

---

## 4. 주의사항 (Safety Rules)
1. **시크릿 노출 금지**: 검색 결과에 자격 증명, 토큰, 비밀번호 등이 포함된 경우 결코 화면에 출력하지 않으며 마스킹 처리한다.
2. **원격 push 금지**: 정보 조회 도중 어떠한 수정이나 원격 push도 수행하지 않다.
