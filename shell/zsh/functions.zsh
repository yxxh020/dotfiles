# ==============================================================================
# Zsh Functions (functions.zsh)
# ==============================================================================

# ------------------------------------------------------------------------------
# 1. GitHub CLI (gh) 디렉토리별 계정 자동 전환 래퍼
# ------------------------------------------------------------------------------
gh() {
  local target_user=""
  if [[ "$PWD" == "$HOME/personal"* ]]; then
    target_user="yxxh020"
  elif [[ "$PWD" == "$HOME/orca"* ]]; then
    target_user="YiranHwang"
  fi

  if [[ -n "$target_user" && "$1" != "auth" ]]; then
    local token
    token=$(command gh auth token --user "$target_user" 2>/dev/null)
    if [[ -n "$token" ]]; then
      GH_TOKEN="$token" command gh "$@"
      return
    fi
  fi

  command gh "$@"
}

# ------------------------------------------------------------------------------
# 2. 포트 점유 프로세스 강제 종료 (killport)
# ------------------------------------------------------------------------------
killport() {
  if [ -z "$1" ]; then
    echo "사용법: killport [포트번호]  (예: killport 3000)"
    return 1
  fi

  local port="$1"
  echo "🔍 포트 $port 점유 프로세스 검색 중..."
  local pids
  pids=$(lsof -t -i :"$port" 2>/dev/null || true)

  if [ -z "$pids" ]; then
    echo "✅ 포트 $port 를 사용 중인 프로세스가 없습니다."
    return 0
  fi

  echo "🛑 PID [$pids] 프로세스를 종료합니다..."
  for pid in $pids; do
    kill -9 "$pid" 2>/dev/null || sudo kill -9 "$pid" 2>/dev/null || true
  done

  sleep 0.5
  local remaining
  remaining=$(lsof -t -i :"$port" 2>/dev/null || true)
  if [ -z "$remaining" ]; then
    echo "✔ 포트 $port 가 깨끗하게 정리되었습니다."
  else
    echo "⚠️ 일부 프로세스(PID: $remaining)가 아직 남아있습니다. sudo 권한으로 다시 시도해보세요."
  fi
}

# ------------------------------------------------------------------------------
# 3. 디렉토리 생성 후 즉시 이동 (mkcd)
# ------------------------------------------------------------------------------
mkcd() {
  mkdir -p "$1" && cd "$1"
}

# ------------------------------------------------------------------------------
# 4. Chrome 프로필별 브라우저 실행 (chro)
# ------------------------------------------------------------------------------
chro() {
  local target_dir=""
  local remaining_args=()

  if [ $# -gt 0 ]; then
    if [[ "$1" == "new" ]]; then
      target_dir=$(chrome-profiles --get-dir 0 2>/dev/null || true)
      if [[ "$OSTYPE" == "darwin"* ]]; then
        open -na "Google Chrome" --args --profile-directory="${target_dir:-Default}" --new-window "${@:2}"
      else
        google-chrome --profile-directory="${target_dir:-Default}" --new-window "${@:2}" >/dev/null 2>&1 &
      fi
      return
    elif [[ "$1" =~ ^[0-9]+$ || "$1" == "Default" || "$1" == Profile* ]]; then
      target_dir=$(chrome-profiles --get-dir "$1" 2>/dev/null || true)
      shift
      remaining_args=("$@")
    else
      target_dir=$(chrome-profiles --get-dir 0 2>/dev/null || true)
      remaining_args=("$@")
    fi
  else
    target_dir=$(chrome-profiles --get-dir 0 2>/dev/null || true)
  fi

  if [[ "$OSTYPE" == "darwin"* ]]; then
    if [ -n "$target_dir" ]; then
      open -a "Google Chrome" --args --profile-directory="$target_dir" "${remaining_args[@]}"
    else
      open -a "Google Chrome" "${remaining_args[@]}"
    fi
  else
    local bin
    for b in google-chrome google-chrome-stable chromium-browser chromium; do
      if command -v "$b" >/dev/null 2>&1; then
        bin="$b"
        break
      fi
    done
    if [ -n "$bin" ]; then
      if [ -n "$target_dir" ]; then
        "$bin" --profile-directory="$target_dir" "${remaining_args[@]}" >/dev/null 2>&1 &
      else
        "$bin" "${remaining_args[@]}" >/dev/null 2>&1 &
      fi
    else
      echo "❌ Chrome 실행 파일을 찾을 수 없습니다."
      return 1
    fi
  fi
}

# ------------------------------------------------------------------------------
# 5. Antigravity Fast Model (agfm)
# ------------------------------------------------------------------------------
agfm() {
  if [ $# -eq 0 ]; then
    agy --model "Gemini 3.5 Flash (Medium)"
  else
    agy --model "Gemini 3.5 Flash (Medium)" --print "$*"
  fi
}

# ------------------------------------------------------------------------------
# 6. KeePassXC Google Drive 3-Way 동기화 (keesync, keestat)
# ------------------------------------------------------------------------------
keesync() {
  local sync_script="$HOME/dotfiles/tasks/keepass-gdrive-sync/sync_keebox.py"
  if [ ! -f "$sync_script" ]; then
    echo "❌ 동기화 엔진($sync_script)을 찾을 수 없습니다."
    return 1
  fi

  if [ $# -eq 0 ]; then
    python3 "$sync_script" sync
  else
    python3 "$sync_script" sync --db "$1"
  fi
}

keestat() {
  local sync_script="$HOME/dotfiles/tasks/keepass-gdrive-sync/sync_keebox.py"
  if [ ! -f "$sync_script" ]; then
    echo "❌ 동기화 엔진($sync_script)을 찾을 수 없습니다."
    return 1
  fi

  if [ $# -eq 0 ]; then
    python3 "$sync_script" status
  else
    python3 "$sync_script" status --db "$1"
  fi
}
