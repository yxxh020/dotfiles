---
description: GitHub CLI(gh)로 이슈·PR을 즉시 조회하고 상호작용한다.
skills: [github-issue]
---

사용자가 특정 이슈 번호나 PR 번호를 언급하면, 터미널에서 즉시 아래 명령을 실행한다.
  - 이슈일 경우: `gh issue view [이슈번호]`
  - PR일 경우: `gh pr diff [PR번호]`

1. 명령어 실행 결과를 분석하여 맥락을 파악하고 사용자에게 브리핑한다.
   - **(선택적) Jev 고속 트리아지**: 이슈 조회 시 `jev`로 즉시 착수 가능 여부나 카테고리를 사전 진단할 수 있다.
     ```bash
     gh issue view [이슈번호] --json body -q .body | jev -y "Is this issue ready to implement immediately?" -q
     ```
2. 필요 시 `gh pr review` 또는 `gh issue comment`로 워크플로우 내에서 바로 코멘트를 작성한다.

## gh CLI 본문 줄바꿈 규칙

`gh issue create`, `gh issue edit`, `gh issue comment` 등 본문(`--body`)을 포함하는 명령어에서 `\n`이 리터럴 문자로 입력되어 줄바꿈이 깨지는 문제를 방지하기 위해 다음 방법을 사용한다:

- **방법 1 (권장):** 임시 마크다운 파일을 생성한 뒤 `--body-file` 옵션으로 전달한다. (예: `gh issue create --title "제목" --body-file issue_body.md`) 실행 후 임시 파일을 삭제한다.
- **방법 2 (짧은 내용):** `printf`를 사용하여 줄바꿈을 변환한다. (예: `gh issue create --title "제목" --body "$(printf '첫 번째 줄\n두 번째 줄')"`)
- **금지:** `--body "첫 번째 줄\n두 번째 줄"` 형태로 쌍따옴표 안에 직접 `\n`을 적어 전달하는 방식은 절대 사용하지 않는다.