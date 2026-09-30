# KeePassXC Google Drive 크로스플랫폼 동기화 가이드

본 문서는 macOS, Linux, Windows 전 환경에서 OS 백그라운드 서비스 종속성 없이 단일 Python 스크립트로 동작하는 **KeePassXC ↔ Google Drive 3-Way 충돌 안전 동기화 도구**의 사용법 및 연동 가이드입니다.

---

## 1. 전제 조건 및 준비사항

### A. Python 3
* Python 3.8 이상 (표준 라이브러리만 사용하므로 `pip install` 불필요)

### B. rclone 및 Google Drive 리모트 설정
rclone이 설치되어 있고 `gdrive` 리모트가 구성되어 있어야 합니다.

1. **rclone 설치**:
   - macOS: `brew install rclone`
   - Linux: `sudo apt install rclone` 또는 `sudo dnf install rclone`
   - Windows: `winget install Rclone.Rclone` 또는 공식 홈페이지 다운로드
2. **Google Drive 리모트 등록**:
   ```bash
   rclone config
   # n (New remote) -> 이름: gdrive -> Storage: drive (Google Drive) 설정 진행
   ```
3. **원격 연결 확인**:
   ```bash
   rclone lsd gdrive:
   ```

---

## 2. 기본 경로 및 환경 변수

| 항목 | 기본값 | 환경 변수 (오버라이드) |
| :--- | :--- | :--- |
| **로컬 DB** | `~/dotfiles/login.kdbx` | `KEEBOX_LOCAL_DB` |
| **원격 DB** | `gdrive:dotfiles/login.kdbx` | `KEEBOX_REMOTE_PATH` |
| **상태 디렉토리** | `~/.local/state/keebox-sync` | `KEEBOX_STATE_DIR` |
| **로컬 백업** | `~/.local/state/keebox-sync/backups/` | - (최근 10개 유지) |
| **충돌 보존** | `~/.local/state/keebox-sync/conflicts/` | - (충돌 시 원격 사본 격리) |
| **원격 백업** | `gdrive:dotfiles/backups/` | - |

---

## 3. 사용법 (CLI)

```bash
# 동기화 실행 (기본 동작)
python3 tasks/146-keepass-gdrive-sync/sync_keebox.py sync

# 현재 상태 및 해시 비교 확인 (Dry-run)
python3 tasks/146-keepass-gdrive-sync/sync_keebox.py status

# 충돌 수동 해결 후 명시적 업로드
python3 tasks/146-keepass-gdrive-sync/sync_keebox.py upload

# 원격 사본 명시적 다운로드
python3 tasks/146-keepass-gdrive-sync/sync_keebox.py download
```

---

## 4. OS별 편의 설정 (Alias / 래퍼)

### macOS / Linux (Zsh / Bash)
`~/.zshrc` 또는 `~/.bashrc`에 alias를 추가합니다:
```bash
alias keesync="python3 $HOME/dotfiles/tasks/146-keepass-gdrive-sync/sync_keebox.py"
alias keestat="python3 $HOME/dotfiles/tasks/146-keepass-gdrive-sync/sync_keebox.py status"
```

### Windows (PowerShell)
PowerShell 프로필(`$PROFILE`)에 함수 또는 alias를 추가합니다:
```powershell
function keesync { python3 "$HOME\dotfiles\tasks\146-keepass-gdrive-sync\sync_keebox.py" $args }
function keestat { python3 "$HOME\dotfiles\tasks\146-keepass-gdrive-sync\sync_keebox.py" status }
```

---

## 5. 충돌 발생 시 해결 절차

로컬과 Google Drive 양쪽 모두에서 비밀번호가 추가/수정된 경우:
1. `sync_keebox.py`가 충돌을 감지하고 원격 사본을 `~/.local/state/keebox-sync/conflicts/login.kdbx.remote.<TIMESTAMP>`에 저장한 뒤 안전하게 중단(Exit code 4)합니다.
2. KeePassXC를 열어 로컬 DB(`login.kdbx`)를 잠금 해제합니다.
3. 상단 메뉴에서 **데이터베이스 > 다른 데이터베이스와 병합...**을 선택하고 `conflicts/` 폴더에 저장된 원격 사본 파일을 선택합니다.
4. KeePassXC가 두 DB의 엔트리를 안전하게 병합합니다. 병합된 로컬 DB를 저장합니다.
5. 병합 완료 후 아래 명령어로 구글 드라이브에 명시적으로 반영합니다:
   ```bash
   python3 tasks/146-keepass-gdrive-sync/sync_keebox.py upload
   ```
