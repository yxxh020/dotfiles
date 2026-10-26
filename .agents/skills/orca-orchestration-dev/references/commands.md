# Orca 오케스트레이션 명령 레퍼런스

> **기준**: appVersion 1.4.161 계열에서 실측 검증.
> **우선순위**: `orca skills get orchestration --full` > `orca agent-context --json` > 이 문서 > `orca --help` > 웹 문서(onorca.dev/docs).
> 버전이 올라갔으면 위 두 명령의 출력을 따르고 이 문서는 참고로만 쓴다.

## 목차

1. 웹 문서와의 차이
2. Task
3. 워커와 dispatch
4. 메시징
5. 워커 완료 보고
6. 게이트
7. 감시·복구
8. 트러블슈팅
9. 쿼터

---

## 1. 웹 문서와의 차이

| 목적 | 웹 문서 (❌ 이 빌드에 없음) | ✅ 이 빌드 |
|---|---|---|
| Run 시작 | `run-create` | `orchestration run --spec` (또는 수동 루프) |
| 워커 생성 | `worker-start` | `terminal create --command "<agent>"` |
| Task 배치 | worker-start에 통합 | `dispatch --task <id> --to <handle> --inject` |
| 완료 대기 타입 | `question` | `decision_gate` |
| 워커 질문 | `ask` | `ask` (동일, `--help` 목록에는 미표기) |

수동 루프(`task-create` → 워커 준비 → `dispatch --inject` → `check --wait`)를 기본으로 쓴다. `orchestration run`은 코디네이터 루프를 자동화하지만 통제력이 낮다.

---

## 2. Task

```bash
orca orchestration task-create --spec <text> [--task-title <name>] [--deps <json_array>] [--parent <task_id>] --json
orca orchestration task-list [--status <s>] [--ready] [--brief] --json
orca orchestration task-update --id <task_id> --status <s> [--result <json>] --json
```

상태: `pending` `ready` `dispatched` `completed` `failed` `blocked`

- `--deps`는 JSON 배열: `'["task_abc123"]'`
- `--brief`는 spec을 160자로 잘라 표시 (`spec_truncated` 표시). 코디네이터 스윕용
- `task-update`는 복구·override 전용. 정상 완료는 `worker_done`이 자동 처리

---

## 3. 워커와 dispatch

```bash
orca terminal create --worktree active --title <name> --command "claude" --json
orca terminal wait --terminal <handle> --for tui-idle --timeout-ms 60000 --json
orca orchestration dispatch --task <task_id> --to <handle> --inject --json
orca orchestration dispatch --task <task_id> --to <handle> --dry-run --return-preamble --json
orca orchestration dispatch-show --task <task_id> [--preamble] --json
```

- `--command`에 다른 에이전트 CLI를 넣어 멀티 프로바이더 구성 가능
- dispatch 전에 반드시 `tui-idle` 대기. 안 하면 프롬프트가 유실된다
- 3회 연속 실패하면 dispatch 컨텍스트가 회로 차단되고 Task가 `failed`로 표시된다
- 새 워크트리가 꼭 필요하면 `worktree create --agent <id>`로 **에이전트 우선 생성**한다. 두 단계로 나누면 불필요한 셸이 하나 더 생긴다

### 프리앰블이 워커에게 강제하는 것

- `worker_done`을 **실패해도** 정확히 1회 (`Failed: <reason>` 제목)
- `--body`는 3문장 요약 (한 것 / 발견한 것 / 남은 것). 빈 body 금지
- 5분마다 heartbeat (`--phase`)
- `AskUserQuestion` 금지, `orca orchestration ask` 사용
- `worker_done` 후 idle 복귀. 새 작업 시작 금지, 폴링 금지, 셸 종료 금지

### stale 프리앰블 처리

같은 터미널을 재사용해도 이전 컨텍스트가 섞이지 않는다. 3중 장치:

1. 매 dispatch마다 프리앰블 전면 재생성 — 이전 taskId 미등장
2. "새 프리앰블이 오면 reset하고 새 Task를 시작, 이전 Task의 후속은 무시" 지시 포함
3. TASK 블록 전면 교체

실측: 워커 1개를 3회 연속 재사용해도 ID 혼용 0건.

---

## 4. 메시징

```bash
orca orchestration check --wait --types worker_done,escalation,decision_gate --timeout-ms 900000 --json
orca orchestration check [--peek|--all] [--types <t,...>] --json
orca orchestration send --to <handle> --type status --subject <text> --body <text> --json
orca orchestration reply --id <msg_id> --body <text> --json
orca orchestration ask --to <handle> --question <text> [--options <csv>] [--timeout-ms <n>] --json
orca orchestration inbox [--limit <n>] [--full] --json
```

- `check` / `check --unread`는 **읽음 처리한다**. 소비 없이 보려면 `--peek`(미읽음만) 또는 `--all`(전체 이력)
- 메시지 타입: `status` `dispatch` `worker_done` `merge_ready` `escalation` `handoff` `decision_gate` `heartbeat`
- 그룹 주소(`@all` `@idle` `@claude` `@codex` 등)는 broadcast용. **dispatch 라이프사이클 메시지를 그룹으로 보내지 않는다**
- `worker_done`은 구체적 코디네이터 핸들로만. 그룹 fanout은 무관한 터미널에 거짓 완료 메일을 만든다

---

## 5. 워커 완료 보고

개별 플래그 방식(권장 — JSON 이스케이프 사고가 없다):

```bash
orca orchestration send --to <coordinator_handle> --from <worker_handle> \
  --type worker_done --subject "<short status>" \
  --body "<3문장 요약>" \
  --task-id <task_id> --dispatch-id <dispatch_id> \
  --files-modified "path/a,path/b" --report-path "<optional>"
```

`--payload` JSON 방식도 동작한다:

```bash
--payload '{"taskId":"...","dispatchId":"...","filesModified":["path/a"]}'
```

`taskId`와 `dispatchId`를 **둘 다** 넣는다. 실패한 재시도의 늦은 완료가 현재 dispatch를 완료 처리하는 것을 막는다.

heartbeat:

```bash
orca orchestration send --to <coordinator_handle> --from <worker_handle> \
  --type heartbeat --subject "alive" \
  --task-id <task_id> --dispatch-id <dispatch_id> \
  --phase "<investigating|implementing|reviewing|waiting>"
```

---

## 6. 게이트

```bash
orca orchestration gate-create --task <task_id> --question <text> [--options <json_array>] --json
orca orchestration gate-resolve --id <gate_id> --resolution <text> --json
orca orchestration gate-list [--task <id>] [--status <s>] --json
```

- `gate-create`는 해당 Task를 `ready` → `blocked`로 내려 dispatch를 막는다 (의도된 동작)
- `gate-create`는 **코디네이터가 관리하는 DAG 결정용**. 워커의 `ask`에 답하는 용도가 아니다. 워커 `ask`는 `reply`로 답한다
- `gate-resolve` 후 `ready` 복귀를 `task-list`로 확인한다

---

## 7. 감시·복구

```bash
orca worktree ps --json          # 워크트리 전반 오케스트레이션 요약
orca terminal list --json
orca terminal read --terminal <handle> --json
orca orchestration reset --tasks|--messages|--all --json
```

`reset`은 런타임 전역이다. 다른 코디네이터가 활동 중이면 그것까지 지운다. 사용자가 명시적으로 폐기를 요청할 때만 실행한다.

---

## 8. 트러블슈팅

| 증상 | 원인 | 조치 |
|---|---|---|
| `task-list`가 빈 배열 | 감독 키워드 누락 → handoff로 분류 | 감독 의도를 명시해 재요청 |
| `only ready tasks can be dispatched` | ready 승격 비소급 | `task-update --status ready` |
| 워커 세션 영구 정지 | 워커가 `AskUserQuestion` 사용 | `ask`를 쓰도록 재지시 |
| 워커 완료했는데 코디가 대기 | 누군가 `check`로 메일 소비 | `inbox`로 확인, 워커에 재전송 요청 |
| 게이트 답변이 워커에 반영 안 됨 | 프리앰블이 게이트 결정을 안 실음 | dispatch 전 릴레이 + 접수 확인 |
| 후속 Task가 pending | ① 사후 생성 ② 완료 하나를 못 받음 | 선행 Task 상태로 구분 (`completed`면 ①, `dispatched`면 ②) |
| `--types question` 오류 | 이 빌드는 `decision_gate` | 타입 수정 |
| Task가 계속 blocked | pending gate 존재 | `gate-list` 확인 후 resolve |
| 15분 무응답 | 정상일 수 있음 | 롤링 대기 유지, `terminal read`로 liveness 확인 |
| 5분마다 대기가 깨짐 | `--types`에 heartbeat 포함 | heartbeat 제거 |
| 워커가 미설치 라이브러리를 쓰려 함 | 환경 조사 생략 | 조사 후 spec 재작성 |
| 병렬 워커가 빌드 캐시 충돌 | 동시 사용 자원 미예측 | 양쪽 spec에 재시도+escalation 지시, 오면 직렬화 |
| 프리앰블이 잘린 spec을 담음 | spec이 너무 길다 | spec을 줄이고 상세는 문서 파일로 넘긴다 |

### ready 승격 비소급 (가장 자주 밟는 함정)

`ready` 승격은 선행 Task 완료 시점의 **이벤트**로만 발생하고, Task 생성 시 의존성 상태를 소급 계산하지 않는다.

- 선행 Task 완료 **전에** 생성된 Task → 자동 승격 ✅
- 선행 Task 완료 **후에** 생성된 Task → 영구 `pending` ❌

복구는 `task-update --status ready`. 의존성이 실제로 충족된 상태이므로 우회가 아니라 실태 반영이며, 가이드가 허용하는 명시적 recovery 케이스다.

**예방**: DAG 전체를 dispatch 전에 한 번에 생성한다.

---

## 9. 쿼터

| 구성 | 실측 |
|---|---|
| 코디 1 + 워커 1, 51분 | 약 22% |
| 코디 1 + 워커 3, 20분 | 미측정 |

에이전트 수에 비례해 소모된다. 멀티 프로바이더 배분은 스타일이 아니라 **쿼터 관리 수단**이다.

- 코디네이터만 최상위 모델, 워커는 하위 모델
- 미사용 쿼터가 남은 모델을 워커로 배치
- 첫 회차는 단일 프로바이더로 — 원인 추적이 우선
