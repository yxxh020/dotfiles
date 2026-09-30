#!/usr/bin/env python3
"""
KeePassXC Google Drive 3-way 충돌 안전 동기화 엔진 (Cross-Platform)
macOS, Linux, Windows 전 플랫폼 호환 (Python 표준 라이브러리 전용)
"""

from __future__ import annotations

import argparse
import datetime
import hashlib
import os
import shutil
import subprocess
import sys
import tempfile
import time
from pathlib import Path
from typing import Optional, Tuple


class SyncLock:
    """원자적(Atomic) 디렉토리 생성을 이용한 크로스플랫폼 동시성 락"""

    def __init__(self, lock_dir: Path, stale_timeout_sec: int = 1800):
        self.lock_dir = lock_dir
        self.pid_file = lock_dir / "PID"
        self.stale_timeout_sec = stale_timeout_sec

    def _is_process_alive(self, pid: int) -> bool:
        if pid <= 0:
            return False
        try:
            if os.name == "nt":
                # Windows
                import ctypes
                kernel32 = ctypes.windll.kernel32
                handle = kernel32.OpenProcess(0x100000, False, pid)  # SYNCHRONIZE
                if handle:
                    kernel32.CloseHandle(handle)
                    return True
                return False
            else:
                # POSIX (macOS / Linux)
                os.kill(pid, 0)
                return True
        except (OSError, PermissionError):
            return False

    def acquire(self) -> bool:
        self.lock_dir.parent.mkdir(parents=True, exist_ok=True)
        try:
            self.lock_dir.mkdir(parents=False, exist_ok=False)
            self.pid_file.write_text(str(os.getpid()), encoding="utf-8")
            return True
        except FileExistsError:
            # 락이 이미 존재하는 경우 stale 여부 검사
            if self.pid_file.exists():
                try:
                    pid = int(self.pid_file.read_text(encoding="utf-8").strip())
                    if not self._is_process_alive(pid):
                        print(f"⚠️  이전 비정상 종료된 락 감지(PID: {pid}) -> 락 해제 후 재시도")
                        shutil.rmtree(self.lock_dir, ignore_errors=True)
                        self.lock_dir.mkdir(parents=False, exist_ok=False)
                        self.pid_file.write_text(str(os.getpid()), encoding="utf-8")
                        return True
                except Exception:
                    pass

            # 파일 생성 시간 기준으로 타임아웃 검사
            try:
                mtime = self.lock_dir.stat().st_mtime
                if time.time() - mtime > self.stale_timeout_sec:
                    print("⚠️  오래된 락 디렉토리(타임아웃 초과) 감지 -> 강제 회수")
                    shutil.rmtree(self.lock_dir, ignore_errors=True)
                    self.lock_dir.mkdir(parents=False, exist_ok=False)
                    self.pid_file.write_text(str(os.getpid()), encoding="utf-8")
                    return True
            except Exception:
                pass

            return False

    def release(self) -> None:
        if self.lock_dir.exists():
            shutil.rmtree(self.lock_dir, ignore_errors=True)

    def __enter__(self) -> SyncLock:
        if not self.acquire():
            print("❌ 오류: 다른 동기화 프로세스가 이미 실행 중입니다. (락 획득 실패)", file=sys.stderr)
            sys.exit(1)
        return self

    def __exit__(self, exc_type, exc_val, exc_tb) -> None:
        self.release()


class KeeBoxSyncEngine:
    """KeePassXC ↔ Google Drive 3-way 충돌 안전 동기화 엔진"""

    def __init__(
        self,
        local_db: Path,
        remote_path: str,
        state_dir: Path,
        rclone_bin: str = "rclone",
    ):
        self.local_db = local_db.resolve()
        self.remote_path = remote_path
        self.state_dir = state_dir.resolve()
        self.rclone_bin = rclone_bin

        self.hash_file = self.state_dir / "last-synced-md5"
        self.backup_dir = self.state_dir / "backups"
        self.conflict_dir = self.state_dir / "conflicts"
        self.lock_dir = self.state_dir / "sync.lock"

        # 디렉토리 초기화
        self.backup_dir.mkdir(parents=True, exist_ok=True)
        self.conflict_dir.mkdir(parents=True, exist_ok=True)

    # ----------------------------------------------------------------------
    # 유틸리티 메서드
    # ----------------------------------------------------------------------
    @staticmethod
    def get_file_md5(file_path: Path) -> Optional[str]:
        """로컬 파일의 MD5 해시 계산 (대용량 청크 방식)"""
        if not file_path.is_file():
            return None
        hasher = hashlib.md5()
        with open(file_path, "rb") as f:
            while chunk := f.read(65536):
                hasher.update(chunk)
        return hasher.hexdigest()

    def run_rclone(self, args: list[str], check: bool = False) -> subprocess.CompletedProcess[str]:
        """rclone 서브프로세스 실행 래퍼"""
        cmd = [self.rclone_bin] + args
        return subprocess.run(
            cmd,
            capture_output=True,
            text=True,
            check=check,
        )

    def get_remote_state(self) -> Tuple[str, Optional[str]]:
        """
        원격 파일 상태 및 해시 조회
        반환: (상태코드, 해시값)
        - 상태코드: 'OK', 'NOT_FOUND', 'ERROR_RCLONE'
        """
        # 1. 파일 존재 여부 확인
        res_lsf = self.run_rclone(["lsf", self.remote_path])
        if res_lsf.returncode != 0:
            combined_err = (res_lsf.stderr + res_lsf.stdout).lower()
            # 원격 디렉토리나 파일이 아직 존재하지 않는 경우
            if "directory not found" in combined_err or "not found" in combined_err:
                return "NOT_FOUND", None
            return "ERROR_RCLONE", None

        output = res_lsf.stdout.strip()
        if not output:
            return "NOT_FOUND", None

        # 2. MD5 해시 조회 시도
        res_md5 = self.run_rclone(["md5sum", self.remote_path])
        if res_md5.returncode == 0 and res_md5.stdout.strip():
            remote_hash = res_md5.stdout.strip().split()[0]
            return "OK", remote_hash

        # 3. md5sum 실패 시 임시 파일로 다운로드하여 해시 비교
        with tempfile.NamedTemporaryFile(delete=False) as tmp:
            tmp_path = Path(tmp.name)

        try:
            res_copy = self.run_rclone(["copyto", self.remote_path, str(tmp_path)])
            if res_copy.returncode == 0:
                tmp_hash = self.get_file_md5(tmp_path)
                return "OK", tmp_hash
            else:
                return "ERROR_RCLONE", None
        finally:
            if tmp_path.exists():
                tmp_path.unlink()

    def backup_local(self) -> Optional[Path]:
        """로컬 DB 백업 및 최근 10개 유지 회전(Rotation)"""
        if not self.local_db.is_file():
            return None

        now_str = datetime.datetime.now().strftime("%Y%m%d-%H%M%S")
        backup_path = self.backup_dir / f"login.kdbx.local.{now_str}"
        shutil.copy2(self.local_db, backup_path)
        print(f"💾 로컬 DB 백업 완료: {backup_path}")

        # 최근 10개 파일만 유지하고 삭제 (수정 시간 기준 내림차순 정렬)
        backups = sorted(
            self.backup_dir.glob("login.kdbx.local.*"),
            key=lambda p: p.stat().st_mtime,
            reverse=True,
        )
        if len(backups) > 10:
            for old_file in backups[10:]:
                try:
                    old_file.unlink()
                except OSError:
                    pass
            print(f"🧹 오래된 로컬 백업 정리 완료 ({len(backups) - 10}개 삭제)")

        return backup_path

    def backup_remote(self) -> bool:
        """원격 DB 백업"""
        now_str = datetime.datetime.now().strftime("%Y%m%d-%H%M%S")
        # gdrive:dotfiles/login.kdbx -> gdrive:dotfiles/backups/login.kdbx.remote.TIMESTAMP
        remote_parts = self.remote_path.rsplit("/", 1)
        if len(remote_parts) == 2:
            remote_base = remote_parts[0]
            remote_backup_path = f"{remote_base}/backups/login.kdbx.remote.{now_str}"
        else:
            remote_backup_path = f"{self.remote_path}.remote.{now_str}"

        print("📡 원격 DB 백업 복사 중...")
        res = self.run_rclone(["copyto", self.remote_path, remote_backup_path])
        if res.returncode != 0:
            print("⚠️  원격 DB 백업 생성 실패! (원격 파일 미존재 또는 네트워크 오류)", file=sys.stderr)
            return False
        print(f"💾 원격 DB 백업 완료: {remote_backup_path}")
        return True

    def get_last_synced_hash(self) -> Optional[str]:
        if self.hash_file.is_file():
            content = self.hash_file.read_text(encoding="utf-8").strip()
            return content if content else None
        return None

    def update_last_synced_hash(self, hash_value: str) -> None:
        self.hash_file.write_text(hash_value.strip(), encoding="utf-8")

    # ----------------------------------------------------------------------
    # 서브커맨드 동작
    # ----------------------------------------------------------------------
    def status(self) -> int:
        """현재 상태 조회 (Dry-run)"""
        local_hash = self.get_file_md5(self.local_db)
        remote_status, remote_hash = self.get_remote_state()
        last_hash = self.get_last_synced_hash()

        print("🔍 동기화 상태 분석:")
        print(f"  - 로컬 DB 경로: {self.local_db}")
        print(f"  - 로컬 해시:    {local_hash or '[파일 없음]'}")
        print(f"  - 원격 경로:    {self.remote_path}")
        if remote_status == "ERROR_RCLONE":
            print("  - 원격 해시:    [조회 오류: 네트워크 또는 rclone 설정 확인 필요]")
        elif remote_status == "NOT_FOUND":
            print("  - 원격 해시:    [파일 없음]")
        else:
            print(f"  - 원격 해시:    {remote_hash}")
        print(f"  - 최종 기준:    {last_hash or '[기준 해시 없음]'}")

        return 0

    def trigger_conflict(self, remote_status: str) -> None:
        """충돌 발생 시 원격 사본 보존 및 안전 종료"""
        now_str = datetime.datetime.now().strftime("%Y%m%d-%H%M%S")
        conflict_path = self.conflict_dir / f"login.kdbx.remote.{now_str}"

        print("⚠️  [충돌 감지] 로컬과 원격 데이터베이스가 모두 마지막 동기화 이후 수정되었습니다!", file=sys.stderr)
        if remote_status == "OK":
            print(f"📥 안전 조치: 원격 사본을 충돌 폴더로 보존합니다...", file=sys.stderr)
            res = self.run_rclone(["copyto", self.remote_path, str(conflict_path)])
            if res.returncode == 0:
                print(f"💾 충돌 사본 보존 완료: {conflict_path}", file=sys.stderr)
            else:
                print(f"❌ 원격 충돌 사본 다운로드 실패!", file=sys.stderr)

        print("🚫 자동 동기화 및 실행을 중단합니다.", file=sys.stderr)
        print("💡 해결 방법: KeePassXC 병합 기능을 통해 로컬 DB와 충돌 사본을 수동 병합한 뒤,", file=sys.stderr)
        print("   'upload' 명령어를 실행하여 최종 업로드하십시오.", file=sys.stderr)
        sys.exit(4)

    def sync(self) -> int:
        """3-Way 충돌 안전 동기화"""
        with SyncLock(self.lock_dir):
            local_hash = self.get_file_md5(self.local_db)
            remote_status, remote_hash = self.get_remote_state()

            if remote_status == "ERROR_RCLONE":
                print("❌ 오류: rclone 원격 조회 실패. 네트워크 혹은 rclone 설정을 점검하십시오.", file=sys.stderr)
                sys.exit(3)

            last_hash = self.get_last_synced_hash()

            print("🔍 동기화 상태 분석:")
            print(f"  - 로컬 해시: {local_hash or '[없음]'}")
            print(f"  - 원격 해시: {remote_hash or ('[파일 없음]' if remote_status == 'NOT_FOUND' else '[오류]')}")
            print(f"  - 최종 기준: {last_hash or '[없음]'}")

            # CASE 1: 로컬과 원격 파일이 모두 없음
            if not local_hash and remote_status == "NOT_FOUND":
                print("ℹ️  로컬 및 원격 데이터베이스 파일이 존재하지 않습니다. 동기화를 중단합니다.")
                return 0

            # CASE 2: 최초 실행 (최종 기준 해시 없음)
            if not last_hash:
                if remote_status == "NOT_FOUND" and local_hash:
                    print("🆕 최종 기준 해시가 없고 원격 파일이 없습니다. 로컬 DB를 업로드합니다.")
                    self.backup_remote()
                    res = self.run_rclone(["copyto", str(self.local_db), self.remote_path])
                    if res.returncode != 0:
                        print("❌ 업로드 실패!", file=sys.stderr)
                        sys.exit(5)
                    self.update_last_synced_hash(local_hash)
                    print("✅ 업로드 완료.")
                    return 0

                elif not local_hash and remote_status == "OK":
                    print("🆕 최종 기준 해시가 없고 로컬 파일이 없습니다. 원격 DB를 다운로드합니다.")
                    self.backup_local()
                    self.local_db.parent.mkdir(parents=True, exist_ok=True)
                    res = self.run_rclone(["copyto", self.remote_path, str(self.local_db)])
                    if res.returncode != 0:
                        print("❌ 다운로드 실패!", file=sys.stderr)
                        sys.exit(6)
                    new_local_hash = self.get_file_md5(self.local_db)
                    if new_local_hash:
                        self.update_last_synced_hash(new_local_hash)
                    print("✅ 다운로드 완료.")
                    return 0

                elif local_hash and remote_hash and local_hash == remote_hash:
                    print("🆕 로컬과 원격 파일이 이미 일치합니다. 기준 해시를 생성합니다.")
                    self.update_last_synced_hash(local_hash)
                    return 0

                else:
                    print("⚠️  경고: 최종 기준 해시가 없으나 로컬과 원격 DB 내용이 서로 다릅니다.", file=sys.stderr)
                    self.trigger_conflict(remote_status)

            # CASE 3: 일반 동기화 루프
            if local_hash == remote_hash:
                print("⚖️  로컬과 원격 DB 상태가 동일합니다. 기준 해시를 갱신합니다.")
                if local_hash:
                    self.update_last_synced_hash(local_hash)
                return 0

            elif local_hash == last_hash and remote_hash != last_hash and remote_status != "NOT_FOUND":
                # 원격만 변경됨 -> 다운로드
                print("📥 원격 DB가 업데이트되었습니다. 로컬 DB를 갱신합니다.")
                self.backup_local()
                self.local_db.parent.mkdir(parents=True, exist_ok=True)
                res = self.run_rclone(["copyto", self.remote_path, str(self.local_db)])
                if res.returncode != 0:
                    print("❌ 다운로드 실패!", file=sys.stderr)
                    sys.exit(6)
                new_local_hash = self.get_file_md5(self.local_db)
                if new_local_hash:
                    self.update_last_synced_hash(new_local_hash)
                print("✅ 다운로드 완료.")
                return 0

            elif remote_hash == last_hash and local_hash != last_hash and local_hash:
                # 로컬만 변경됨 -> 업로드
                print("📤 로컬 DB가 업데이트되었습니다. 원격 DB를 갱신합니다.")
                self.backup_remote()
                res = self.run_rclone(["copyto", str(self.local_db), self.remote_path])
                if res.returncode != 0:
                    print("❌ 업로드 실패!", file=sys.stderr)
                    sys.exit(5)
                self.update_last_synced_hash(local_hash)
                print("✅ 업로드 완료.")
                return 0

            else:
                # 양쪽 모두 변경되었거나 기준 해시와 불일치 -> 충돌
                self.trigger_conflict(remote_status)

        return 0

    def upload(self) -> int:
        """명시적 로컬 DB 업로드 (충돌 수동 해결 후 사용)"""
        with SyncLock(self.lock_dir):
            if not self.local_db.is_file():
                print(f"❌ 오류: 업로드할 로컬 DB 파일이 존재하지 않습니다. ({self.local_db})", file=sys.stderr)
                sys.exit(5)

            print("📤 로컬 DB를 원격 저장소에 명시적으로 업로드합니다...")
            self.backup_remote()
            res = self.run_rclone(["copyto", str(self.local_db), self.remote_path])
            if res.returncode != 0:
                print("❌ 업로드 실패!", file=sys.stderr)
                sys.exit(5)

            local_hash = self.get_file_md5(self.local_db)
            if local_hash:
                self.update_last_synced_hash(local_hash)
            print("✅ 업로드 완료 및 기준 해시 갱신 성공.")
            return 0

    def download(self) -> int:
        """명시적 원격 DB 다운로드"""
        with SyncLock(self.lock_dir):
            remote_status, remote_hash = self.get_remote_state()
            if remote_status != "OK" or not remote_hash:
                print("❌ 오류: 다운로드할 원격 DB를 가져올 수 없습니다.", file=sys.stderr)
                sys.exit(6)

            print("📥 원격 DB를 로컬 저장소에 명시적으로 다운로드합니다...")
            self.backup_local()
            self.local_db.parent.mkdir(parents=True, exist_ok=True)
            res = self.run_rclone(["copyto", self.remote_path, str(self.local_db)])
            if res.returncode != 0:
                print("❌ 다운로드 실패!", file=sys.stderr)
                sys.exit(6)

            new_local_hash = self.get_file_md5(self.local_db)
            if new_local_hash:
                self.update_last_synced_hash(new_local_hash)
            print("✅ 다운로드 완료 및 기준 해시 갱신 성공.")
            return 0


def resolve_paths(
    db_arg: Optional[str],
    local_db_arg: Optional[Path],
    remote_path_arg: Optional[str],
    state_dir_arg: Optional[Path],
) -> Tuple[Path, str, Path]:
    """다중 kdbx DB 지원을 위한 경로 자동 산출 및 분리"""
    home = Path.home()
    dotfiles_root = Path(os.environ.get("DOTFILES_ROOT", str(home / "dotfiles")))

    # 1. 로컬 DB 결정
    if db_arg:
        db_path = Path(db_arg).expanduser()
        if not db_path.is_absolute():
            # 상대 경로인 경우 현재 디렉토리 또는 dotfiles_root 탐색
            if (Path.cwd() / db_path).exists():
                local_db = (Path.cwd() / db_path).resolve()
            else:
                local_db = (dotfiles_root / db_path).resolve()
        else:
            local_db = db_path.resolve()
    elif local_db_arg:
        local_db = local_db_arg.resolve()
    else:
        local_db_env = os.environ.get("KEEBOX_LOCAL_DB")
        local_db = Path(local_db_env).resolve() if local_db_env else (dotfiles_root / "login.kdbx")

    db_filename = local_db.name
    db_stem = local_db.stem

    # 2. 원격 경로 결정
    if remote_path_arg:
        remote_path = remote_path_arg
    else:
        remote_base = os.environ.get("KEEBOX_REMOTE_BASE", "gdrive:dotfiles")
        remote_path_env = os.environ.get("KEEBOX_REMOTE_PATH")
        if remote_path_env and not db_arg:
            remote_path = remote_path_env
        else:
            remote_path = f"{remote_base}/{db_filename}"

    # 3. 상태 디렉토리 결정 (기본 login은 하위호환 유지, 기타 DB는 서브폴더로 격리)
    if state_dir_arg:
        state_dir = state_dir_arg.resolve()
    else:
        base_state_env = os.environ.get("KEEBOX_STATE_DIR")
        base_state_dir = Path(base_state_env).resolve() if base_state_env else (home / ".local" / "state" / "keebox-sync")
        if db_stem == "login":
            state_dir = base_state_dir
        else:
            state_dir = base_state_dir / db_stem

    return local_db, remote_path, state_dir


def main():
    parser = argparse.ArgumentParser(
        description="KeePassXC Google Drive 3-way 충돌 안전 동기화 엔진 (Cross-Platform)"
    )
    parser.add_argument(
        "action",
        choices=["sync", "upload", "download", "status"],
        nargs="?",
        default="sync",
        help="수행할 작업 (기본값: sync)",
    )
    parser.add_argument(
        "--db",
        type=str,
        default=None,
        help="동기화할 kdbx 파일명 또는 경로 (다중 프로젝트 지원, 예: projectA.kdbx)",
    )
    parser.add_argument(
        "--local-db",
        type=Path,
        default=None,
        help="로컬 kdbx 파일 절대/상대 경로",
    )
    parser.add_argument(
        "--remote-path",
        type=str,
        default=None,
        help="원격 rclone 경로 (기본값: gdrive:dotfiles/<DB파일명>)",
    )
    parser.add_argument(
        "--state-dir",
        type=Path,
        default=None,
        help="상태/백업/충돌 저장소 디렉토리",
    )
    parser.add_argument(
        "--rclone-bin",
        type=str,
        default="rclone",
        help="rclone 실행 바이너리 경로 (기본값: rclone)",
    )

    args = parser.parse_args()

    local_db, remote_path, state_dir = resolve_paths(
        db_arg=args.db,
        local_db_arg=args.local_db,
        remote_path_arg=args.remote_path,
        state_dir_arg=args.state_dir,
    )

    engine = KeeBoxSyncEngine(
        local_db=local_db,
        remote_path=remote_path,
        state_dir=state_dir,
        rclone_bin=args.rclone_bin,
    )

    if args.action == "sync":
        sys.exit(engine.sync())
    elif args.action == "upload":
        sys.exit(engine.upload())
    elif args.action == "download":
        sys.exit(engine.download())
    elif args.action == "status":
        sys.exit(engine.status())
    else:
        parser.print_help()
        sys.exit(1)


if __name__ == "__main__":
    main()
