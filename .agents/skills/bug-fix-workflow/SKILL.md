---
name: bug-fix-workflow
description: 서비스 버그 제보(Bug Report) 테이블에서 미처리 버그를 조회(트리아지)하여 GitHub 이슈(버그 번호 명시)로 등록하고, 버그 제보에 이슈 번호 댓글을 남기며, 수정 완료 시 패치 버전 bump·이슈 종료(처리완료 라벨 및 다음 버전 댓글)·버그 완료 처리까지 수행하는 버그 처리 전체 워크플로우 스킬.
---

> **[안내]** 이 파일은 각 프로젝트가 복사하거나 심볼릭 링크하여 프로젝트 상황에 맞게 사용하는 템플릿이다.

# Bug Fix Workflow — 버그 처리 전체 워크플로우

접수된 사용자 버그 제보를 체계적으로 분류(트리아지)하고, 버그 번호를 포함한 GitHub 이슈 생성 및 버그 게시판 댓글 연동, 해결 후 릴리스 버전 계산·처리완료 라벨 적용·배포 반영 안내 댓글 등록까지 완결하는 전주기 워크플로우이다.

---

## 관련 스킬
* `prod-server-guard` — 운영 DB 접근 전 경고 가드
* `github-issue` / `github-issue-expert` — GitHub CLI 표준 이슈 생성 및 관리
* `issues-plan-and-resolve` — GitHub 이슈 처리 파이프라인
* `version-expert` — 패치 버전 bump 및 Git 태그

---

## 버그 제보 데이터 접근 환경 — prod 전용

버그 처리 시 제보 데이터의 모든 읽기와 쓰기는 **항상 운영 환경(prod)에서만** 수행한다.
제보 목록·상세·첨부·댓글 조회, 처리 상태 변경, GitHub 이슈 연동 댓글 및 완료 안내 댓글 등록 모두 이 규칙을 적용한다.

실제 운영 서비스의 DB·API·게시판 또는 해당 운영 사이트의 브라우저 저장소를 사용한다. 로컬·개발·테스트·스테이징 데이터나 코드의 모의 데이터를 실제 접수 내역으로 대신 사용하지 않는다.

접근 전에 대상 URL과 데이터 저장소가 prod인지 확인한다. prod에 접근할 수 없으면 필요한 접속 정보나 실제 제보 내용을 요청하며, 다른 환경에 대신 읽기·쓰기를 수행하지 않는다.

이 규칙은 버그 제보 데이터에 적용한다. 코드 수정과 수정 사항 검증은 로컬 개발 환경에서 수행할 수 있다.
운영 환경 접근 시에는 `prod-server-guard`와 사용자의 기존 승인 범위를 함께 따른다.

### 읽기 접근 방법 선택
1. 먼저 프로젝트의 제보 저장·조회 코드를 확인하여 실제 저장소를 식별한다. 운영 사이트가 있다는 이유만으로 운영 DB에 제보가 저장된다고 가정하지 않는다.
2. 운영 DB에 실제 제보가 저장되어 있고 접근할 수 있으면 **운영 DB 읽기 전용 조회를 우선**한다. 읽기 전용 계정 또는 읽기 전용 트랜잭션으로 필요한 필드만 SELECT하고, 상태 변경·댓글 등록 등의 쓰기는 조회와 분리한다. DB 직접 접근이 없으면 운영 API의 조회 기능을 사용한다.
3. 제보가 브라우저 localStorage 또는 IndexedDB에만 저장되면 **제보가 저장된 기존 운영 브라우저 프로필**에서 조회한다. 기존 탭의 정확한 origin을 확인한 뒤 해당 저장소만 읽는다. 새로운 브라우저·프로필·탭에서 데이터가 없더라도 전체 미처리 제보가 0건이라고 결론 내리지 않는다. origin과 프로필이 다르면 같은 운영 사이트라도 저장 데이터가 다르며, 다른 사용자의 제보도 자동 공유되지 않는다.
4. 코드의 기본값·샘플·시드 데이터와 실제 저장된 접수 내역을 구별한다. 브라우저 방식에서는 UI가 샘플을 합쳐 표시할 수 있으므로 저장소 원본을 확인한다.
5. 사용자에게 선택한 접근 방법과 근거를 짧게 알린다. 사용자가 운영 읽기 접근을 이미 승인했다면 같은 대상·범위의 읽기 조회에 다시 승인받지 않는다. 그 승인을 운영 데이터 쓰기나 배포 승인으로 확대하지 않는다.
6. 실제 운영 저장소에 접근할 수 없으면 확인한 접근 오류와 필요한 접속 정보 또는 브라우저를 알린다. 로컬·테스트 데이터로 대체하지 않는다.

---

## 📋 BugReport & BugComment 모델 참조 (예시 스키마)

```prisma
model BugReport {
  id          String       // cuid / uuid / "BUG-101"
  category    String       // "버그" | "기능개선" | "기타"
  title       String
  description String?      // 문제 설명
  url         String       // 제보가 발생한 절대 URL
  userAgent   String       // 제보자 환경 정보
  screenshot  String?      // 스크린샷 이미지 경로 또는 URL
  status      BugStatus    // OPEN | IN_PROGRESS | ON_HOLD | CLOSED
  reporterId  String?      // 제보자 식별자 또는 이름
  createdAt   DateTime     @default(now())
  updatedAt   DateTime     @updatedAt
  comments    BugComment[]
}

model BugComment {
  id          String       // cuid / uuid / autoincrement ID
  bugId       String       // FK to BugReport.id
  author      String       // 작성자 이름 또는 login_id
  role        String?      // 작성자 역할 (어드민, 코치 등)
  content     String       // 댓글 본문 (GitHub 이슈 링크, 진행 상황 등)
  createdAt   DateTime     @default(now())
  updatedAt   DateTime?    @updatedAt
}
```

---

## PHASE 1 — 버그 트리아지 ("버그 처리하자", "버그 트리아지", "버그 목록")

> **💡 트리아지(Triage)란?**  
> 프랑스어 *trier(선별·분류하다)*에서 유래한 용어로, 응급실에서 환자의 위급도에 따라 우선순위를 나누듯, **접수된 버그 제보들을 검토하여 실제 결함 여부와 재현성을 확인하고, 심각도와 우선순위를 매겨 실제 실행 가능한 작업(GitHub 이슈)으로 분류·전환하는 초기 선별 과정**을 의미한다.

**트리거**: "버그 처리 하자", "버그 처리하자", "버그 처리", "버그 트리아지", "버그 목록", "대기중인 버그", "버그 등록", "버그 이슈 만들어줘", "버그 처리 중으로 바꿔줘"

### Step 1. 미처리 버그 제보 조회
대상이 운영 환경(prod)인지 확인하고 접근 가드 및 기존 승인 범위를 확인한 후, 위 선택 기준에 따라 실제 운영 저장소에서 미처리 제보를 조회합니다. 아래 SQL은 운영 DB에 제보가 저장되는 경우의 예시이며, 프로젝트의 실제 스키마에 맞게 적용합니다:

```sql
SELECT
  id,
  category,
  title,
  description,
  url,
  screenshot,
  status,
  reporter_id,
  created_at
FROM bug_reports
WHERE status = 'OPEN'
ORDER BY created_at DESC;
```

### Step 2. 버그 분석 및 재현성 검토
조회된 제보를 **최신순**으로 분석:
* `title` / `description`: 문제 요약 및 설명 파악
* `url`: 에러 발생 페이지 경로 및 파라미터 확인 (로컬 URL인 경우 테스트/운영 서버 URL로 매핑)
* `screenshot`: 첨부된 화면 캡처 확인
* `userAgent`: 브라우저 및 OS 환경 특정
* `category`: 버그 / 기능개선 / 단순 문의 분류
* `reporter_id`: 제보자 연락처(이메일 등) 조회 가능 여부 확인

#### (선택적) Jev 기반 고속 트리아지
`jev` CLI가 환경에 있을 경우, 제보 데이터의 카테고리·심각도·재현 충분성을 고속으로 분류한다. `jev`가 없거나 실패하면 에이전트가 직접 분석하는 기존 방식으로 자동 진행한다.

```bash
CATEGORY=""
SEVERITY=""
HAS_REPRO=""

if command -v jev &>/dev/null; then
  # 카테고리 자동 분류
  CATEGORY=$(jev "$TITLE. $DESCRIPTION" -c "bug,enhancement,question,invalid" -q 2>/dev/null) || true

  # 심각도 즉시 판정
  SEVERITY=$(jev "$TITLE. $DESCRIPTION" -c "critical,major,minor,trivial" -q 2>/dev/null) || true

  # 재현 충분성 판단
  HAS_REPRO=$(jev "$DESCRIPTION" -y "Does this report have enough steps and context to reproduce?" -q 2>/dev/null) || true
fi

# 변수가 비어있으면 에이전트가 기존 방식(제보 내용 직접 분석)으로 판단
```
> **Jev Graceful Fallback**: `jev` 미설치·API 키 미등록·네트워크 불가 환경에서는 에러를 내지 않고 기존 수동/AI 직접 분석으로 자연스럽게 진행한다.

### Step 3. GitHub 이슈 등록 (버그 번호 필수 기록)

> [!IMPORTANT]
> **이슈 제목과 본문 모두에 버그 번호(DB ID / 제보 번호)를 명시적으로 기록**해야 합니다.  
> 제목 형식: `fix: [Bug #<버그ID>] <제목>`

```bash
gh issue create \
  --title "fix: [Bug #[버그ID]] [title 내용]" \
  --body "## 버그 번호 (Bug ID)
- Bug ID: [버그ID]

## 문제 설명
[description]

## 발생 URL
[url]

## 환경 정보
[userAgent]

## 스크린샷
[screenshot 경로 또는 이미지 URL]

## 제보 메타데이터
- 제보 일시: [created_at]
- 제보자: [reporter]" \
  --label "bug"
```
> [!NOTE]
> `category`가 기능개선인 경우 `--label "enhancement"`를 부여합니다.

### Step 4. 상태 갱신 (IN_PROGRESS)
중복 작업 방지를 위해 DB/스토리지 상태를 즉시 `IN_PROGRESS`(처리중)로 갱신합니다:

```sql
UPDATE bug_reports
SET status = 'IN_PROGRESS', updated_at = NOW()
WHERE id = '[bug_id]';
```

### Step 5. 버그 제보에 GitHub 이슈 연동 댓글 등록 (MANDATORY)

> [!IMPORTANT]
> 이슈 생성 및 처리중 전환 직후, **반드시 버그 제보(게시판)의 댓글(`bug_comments`)에 생성된 GitHub 이슈 번호와 링크를 등록**합니다. 이 단계를 수행해야 버그 제보와 GitHub 이슈 간 추적성(Traceability)이 보장됩니다. 버그 게시판에 댓글 기능이 없는 경우, BugComment 시스템(UI 및 스토리지)을 우선 구축합니다.

**댓글 템플릿**:
```text
📌 GitHub 이슈 #[이슈번호]가 생성되어 개발 트래킹에 등록되었습니다.
- 이슈 링크: https://github.com/[owner]/[repo]/issues/[이슈번호]
- 현재 상태: 처리중 (IN_PROGRESS)
```

### Step 6. 이슈 처리 파이프라인으로 위임
등록된 이슈 번호를 바탕으로 수정 작업 계획 수립 및 코드 수정을 진행합니다 (`issues-plan-and-resolve` 또는 `ralph-loop` 스킬 연계).

---

## PHASE 2 — 버그 처리 완료 ("버그 N번 처리 완료", "버그 완료")

**트리거**: "버그 [이슈번호]번 처리 완료", "버그 완료", "처리완료로 바꿔줘", "이슈 닫아줘"

### Step 1. 다음 버전 번호 계산 (패치 버전 + 1)
현재 `package.json`의 버전을 읽고 특별한 사유가 없다면 **패치 버전에 1을 더해** 다음 버전 번호를 산출합니다:

```bash
# 예: 0.1.4 -> 다음 버전: 0.1.5
CURRENT_VER=$(node -p "require('./package.json').version")
NEXT_VER=$(node -p "
  const [major, minor, patch] = require('./package.json').version.split('.').map(Number);
  \`\${major}.\${minor}.\${patch + 1}\`
")
```

### Step 2. 버전 bump 및 태그 생성
`version-expert` 스킬을 호출하여 버전을 `NEXT_VER`로 올립니다:
```bash
# package.json 버전 수정 및 커밋, Git 태그 생성
```

### Step 3. 연동 버그 번호 확인 및 DB 상태 → CLOSED(처리완료) 변경
GitHub 이슈 제목이나 본문에서 연동된 버그 번호를 확인한 후, DB의 제보 상태를 **처리완료 (`CLOSED`)**로 변경합니다:

```sql
UPDATE bug_reports
SET status = 'CLOSED', updated_at = NOW()
WHERE id = '[bug_id]';
```

### Step 4. GitHub 이슈 라벨 '처리완료' 변경 및 완료 댓글 등록 종료
GitHub 이슈에 `처리완료` 라벨을 부착하고(기존 in progress 라벨 제거), 다음 배포 반영 안내 댓글을 작성한 뒤 이슈를 닫습니다:

```bash
# 1. 처리완료 라벨 부여 (라벨이 없으면 자동 생성 후 부착)
gh label create "처리완료" --color "0e8a16" --description "버그 또는 이슈 해결 완료" 2>/dev/null || true
gh issue edit [이슈번호] --add-label "처리완료"

# 2. 다음 버전 해결 및 배포 반영 안내 댓글 작성과 이슈 종료
gh issue close [이슈번호] \
  --comment "v${NEXT_VER}에서 해결될 것이고 다음 배포 시 반영됩니다."
```

### Step 5. 버그 제보에 배포 반영 안내 댓글 등록 (MANDATORY)
버그 게시판의 제보 상세 댓글에도 동일하게 다음 배포 반영 안내 댓글을 등록합니다:

**댓글 템플릿**:
```text
✅ v[NEXT_VER]에서 해결될 것이고 다음 배포 시 반영됩니다.
이용해 주셔서 감사합니다.
```

### Step 6. 제보자 완료 안내 알림/이메일 발송
제보자의 연락처(이메일, 슬랙, 텔레그램 등)가 존재하는 경우 완료 알림을 발송합니다.

---

## 빠른 참조 명령

```bash
# 미처리 버그 건수 확인
SELECT COUNT(*) FROM bug_reports WHERE status = 'OPEN';

# GitHub 관련 이슈 목록
gh issue list --label "bug" --state open
```
