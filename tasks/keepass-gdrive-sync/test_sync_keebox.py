#!/usr/bin/env python3
"""
KeeBoxSyncEngine 단위 테스트 (Zero Third-Party Dependency)
가상 임시 디렉토리 및 Mock rclone 환경에서 3-way 충돌 및 백업 회전 검증
"""

import hashlib
import os
import shutil
import tempfile
import time
import unittest
from pathlib import Path
from unittest.mock import MagicMock

# 대상 엔진 모듈 import
from sync_keebox import KeeBoxSyncEngine, SyncLock


class TestKeeBoxSyncEngine(unittest.TestCase):
    def setUp(self):
        # 격리된 임시 작업 디렉토리 생성
        self.test_dir = tempfile.mkdtemp(prefix="keebox_test_")
        self.test_root = Path(self.test_dir)

        self.local_db = self.test_root / "login.kdbx"
        self.state_dir = self.test_root / "state"
        self.remote_path = "gdrive:dotfiles/login.kdbx"

        self.engine = KeeBoxSyncEngine(
            local_db=self.local_db,
            remote_path=self.remote_path,
            state_dir=self.state_dir,
        )

    def tearDown(self):
        shutil.rmtree(self.test_dir, ignore_errors=True)

    # ------------------------------------------------------------------
    # 1. SyncLock 검증
    # ------------------------------------------------------------------
    def test_sync_lock_acquire_and_release(self):
        lock_dir = self.state_dir / "test.lock"
        lock1 = SyncLock(lock_dir)
        self.assertTrue(lock1.acquire())
        self.assertTrue(lock_dir.is_dir())
        self.assertTrue((lock_dir / "PID").is_file())

        # 동일 락 재획득 시 실패해야 함
        lock2 = SyncLock(lock_dir)
        self.assertFalse(lock2.acquire())

        # 해제 후 재획득 성공
        lock1.release()
        self.assertFalse(lock_dir.exists())
        self.assertTrue(lock2.acquire())
        lock2.release()

    def test_sync_lock_stale_pid_recovery(self):
        """존재하지 않는 가상 PID가 기록된 오래된 락 자동 복구 검증"""
        lock_dir = self.state_dir / "stale.lock"
        lock_dir.mkdir(parents=True, exist_ok=True)
        # 매우 큰 가상의 미존재 PID 기록
        (lock_dir / "PID").write_text("9999999", encoding="utf-8")

        lock = SyncLock(lock_dir)
        self.assertTrue(lock.acquire())
        lock.release()

    # ------------------------------------------------------------------
    # 2. 해시 및 로컬 백업 회전(10개 제한) 검증
    # ------------------------------------------------------------------
    def test_md5_calculation(self):
        sample_file = self.test_root / "sample.txt"
        content = b"KeePassXC Safe Sync Data"
        sample_file.write_bytes(content)

        expected_md5 = hashlib.md5(content).hexdigest()
        actual_md5 = self.engine.get_file_md5(sample_file)
        self.assertEqual(actual_md5, expected_md5)

    def test_local_backup_rotation_limit_10(self):
        """백업이 10개를 초과할 때 가장 오래된 파일이 삭제되는지 검증"""
        self.local_db.write_bytes(b"initial db")

        # 15회 연속 백업 수행 (타임스탬프 고유성을 위해 약간의 간격 또는 명시적 파일 생성)
        for i in range(15):
            backup_file = self.engine.backup_dir / f"login.kdbx.local.20260101-{100000 + i}"
            backup_file.write_bytes(f"backup {i}".encode())
            # mtime 간격 부여
            os.utime(backup_file, (time.time() - (100 - i), time.time() - (100 - i)))

        # 새로운 백업 트리거
        self.engine.backup_local()

        # 백업 디렉토리 파일 수 확인 (정확히 10개 유지)
        remaining = list(self.engine.backup_dir.glob("login.kdbx.local.*"))
        self.assertEqual(len(remaining), 10)

    # ------------------------------------------------------------------
    # 3. 3-Way 충돌 감지 및 동기화 판정 로직 검증 (Mock rclone)
    # ------------------------------------------------------------------
    def test_case_sync_initial_only_local(self):
        """초기 상태: 원격 없음, 로컬만 있음 -> 업로드 및 기준 해시 생성"""
        self.local_db.write_bytes(b"local content")
        local_hash = self.engine.get_file_md5(self.local_db)

        # Mock: 원격 없음
        self.engine.get_remote_state = MagicMock(return_value=("NOT_FOUND", None))
        self.engine.backup_remote = MagicMock(return_value=True)
        self.engine.run_rclone = MagicMock(return_value=MagicMock(returncode=0))

        code = self.engine.sync()
        self.assertEqual(code, 0)
        self.assertEqual(self.engine.get_last_synced_hash(), local_hash)

    def test_case_sync_remote_updated(self):
        """일반 상태: 로컬은 이전 기준과 일치, 원격만 변경됨 -> 원격 다운로드"""
        # 기준 해시 설정
        old_content = b"old base content"
        self.local_db.write_bytes(old_content)
        base_hash = self.engine.get_file_md5(self.local_db)
        self.engine.update_last_synced_hash(base_hash)

        # 원격은 새로운 내용
        new_remote_hash = "remote_new_md5_hash"
        self.engine.get_remote_state = MagicMock(return_value=("OK", new_remote_hash))
        self.engine.backup_local = MagicMock()

        # rclone copyto 시뮬레이션: 로컬 파일을 새 내용으로 바꿈
        def fake_copyto(args):
            if "copyto" in args:
                self.local_db.write_bytes(b"new remote downloaded content")
                return MagicMock(returncode=0)
            return MagicMock(returncode=0)

        self.engine.run_rclone = MagicMock(side_effect=fake_copyto)

        code = self.engine.sync()
        self.assertEqual(code, 0)
        self.engine.backup_local.assert_called_once()
        self.assertEqual(self.engine.get_last_synced_hash(), self.engine.get_file_md5(self.local_db))

    def test_case_sync_local_updated(self):
        """일반 상태: 원격은 이전 기준과 일치, 로컬만 변경됨 -> 로컬 업로드"""
        base_hash = "base_md5_hash_123"
        self.engine.update_last_synced_hash(base_hash)

        # 원격은 이전 기준 그대로
        self.engine.get_remote_state = MagicMock(return_value=("OK", base_hash))
        self.engine.backup_remote = MagicMock(return_value=True)
        self.engine.run_rclone = MagicMock(return_value=MagicMock(returncode=0))

        # 로컬은 새로 수정됨
        self.local_db.write_bytes(b"new local updated content")
        new_local_hash = self.engine.get_file_md5(self.local_db)

        code = self.engine.sync()
        self.assertEqual(code, 0)
        self.engine.backup_remote.assert_called_once()
        self.assertEqual(self.engine.get_last_synced_hash(), new_local_hash)

    def test_case_sync_conflict_both_modified(self):
        """충돌 상태: 로컬과 원격이 모두 이전 기준과 다름 -> 원격 사본 보존 후 Exit 4"""
        base_hash = "base_md5_hash_old"
        self.engine.update_last_synced_hash(base_hash)

        # 로컬 수정
        self.local_db.write_bytes(b"local conflict content")
        # 원격도 수정됨
        self.engine.get_remote_state = MagicMock(return_value=("OK", "remote_conflict_md5"))

        # 충돌 시 rclone copyto로 conflicts/ 디렉토리에 사본을 복사함
        def fake_copyto(args):
            if "copyto" in args:
                dst = Path(args[2])
                dst.write_bytes(b"downloaded conflict remote content")
                return MagicMock(returncode=0)
            return MagicMock(returncode=0)

        self.engine.run_rclone = MagicMock(side_effect=fake_copyto)

        # SystemExit(4)가 발생해야 함
        with self.assertRaises(SystemExit) as cm:
            self.engine.sync()
        self.assertEqual(cm.exception.code, 4)

        # conflicts 디렉토리에 파일이 저장되었는지 확인
        conflicts = list(self.engine.conflict_dir.glob("login.kdbx.remote.*"))
        self.assertEqual(len(conflicts), 1)


if __name__ == "__main__":
    unittest.main()
