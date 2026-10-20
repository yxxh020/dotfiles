#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
KeePass Database Merger
Merge secrets-db.kdbx and next-coach.kdbx into login.kdbx as separate root-level groups.
"""

import os
import sys
import shutil
import getpass
from datetime import datetime
from pykeepass import PyKeePass
from pykeepass.exceptions import CredentialsError

DOTFILES_DIR = "DOTFILES_DIR"
MAIN_DB_PATH = os.path.join(DOTFILES_DIR, "login.kdbx")
TARGETS = [
    {
        "path": os.path.join(DOTFILES_DIR, "secrets-db.kdbx"),
        "group_name": "secrets-db"
    },
    {
        "path": os.path.join(DOTFILES_DIR, "next-coach.kdbx"),
        "group_name": "next-coach"
    }
]

def copy_entry(target_kp, target_group, src_entry):
    """Deep copy a single KeePass entry including custom properties and attachments."""
    new_entry = target_kp.add_entry(
        destination_group=target_group,
        title=src_entry.title or "",
        username=src_entry.username or "",
        password=src_entry.password or "",
        url=src_entry.url,
        notes=src_entry.notes,
        expiry_time=src_entry.expiry_time,
        tags=src_entry.tags,
        otp=src_entry.otp,
        icon=src_entry.icon
    )

    # Copy custom string properties
    if src_entry.custom_properties:
        for k, v in src_entry.custom_properties.items():
            new_entry.set_custom_property(k, v)

    # Copy attachments
    if src_entry.attachments:
        for att in src_entry.attachments:
            try:
                new_entry.add_attachment(att.data, att.filename)
            except Exception as e:
                print(f"    [!] 첨부파일 복사 경고 ({att.filename}): {e}")

    return new_entry

def copy_group_contents(target_kp, target_group, src_group, recycle_bin_group=None):
    """Recursively copy entries and subgroups into target group, skipping recycle bin."""
    entry_count = 0
    group_count = 0

    # 1. Copy entries in current group
    for entry in src_group.entries:
        copy_entry(target_kp, target_group, entry)
        entry_count += 1

    # 2. Copy subgroups
    for sub_group in src_group.subgroups:
        # Skip recycle bin if present
        if recycle_bin_group and sub_group == recycle_bin_group:
            print(f"    [-] 휴지통 그룹 건너뜀: {sub_group.name}")
            continue

        new_sub = target_kp.add_group(
            destination_group=target_group,
            group_name=sub_group.name,
            icon=sub_group.icon,
            notes=sub_group.notes
        )
        group_count += 1
        sub_e, sub_g = copy_group_contents(target_kp, new_sub, sub_group, recycle_bin_group)
        entry_count += sub_e
        group_count += sub_g

    return entry_count, group_count

def open_db_with_prompt(path, prompt_label):
    """Prompt for master password and open the KeePass database."""
    while True:
        try:
            pwd = getpass.getpass(f"🔑 [{prompt_label}] 마스터 비밀번호 입력: ")
            if not pwd:
                print("비밀번호가 비어 있습니다. 다시 입력해주세요.")
                continue
            kp = PyKeePass(path, password=pwd)
            print(f"  ✓ {os.path.basename(path)} 인증 성공 (항목: {len(kp.entries)}개, 그룹: {len(kp.groups)}개)")
            return kp
        except CredentialsError:
            print("  ❌ 비밀번호가 올바르지 않습니다. 다시 시도해주세요.")
        except Exception as e:
            print(f"  ❌ 데이터베이스 열기 실패: {e}")
            sys.exit(1)

def main():
    print("=" * 60)
    print(" KeePass 데이터베이스 통합 도구")
    print("=" * 60)
    print(f" 메인 DB    : {MAIN_DB_PATH}")
    for t in TARGETS:
        print(f" 추가 대상  : {t['path']} -> 루트 밑 그룹 [{t['group_name']}]")
    print("=" * 60)

    # 0. 파일 존재 여부 검증
    for f in [MAIN_DB_PATH] + [t["path"] for t in TARGETS]:
        if not os.path.exists(f):
            print(f"❌ 오류: 파일을 찾을 수 없습니다: {f}")
            sys.exit(1)

    # 1. 자동 백업 생성
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    backup_path = f"{MAIN_DB_PATH}.bak_{timestamp}"
    try:
        shutil.copy2(MAIN_DB_PATH, backup_path)
        print(f"\n[1/4] 메인 DB 안전 백업 완료:")
        print(f"      -> {backup_path}")
    except Exception as e:
        print(f"❌ 백업 생성 실패로 작업을 중단합니다: {e}")
        sys.exit(1)

    # 2. 마스터 비밀번호 순차 입력 및 DB 열기
    print("\n[2/4] 각 데이터베이스의 마스터 비밀번호를 입력해주세요:")
    main_kp = open_db_with_prompt(MAIN_DB_PATH, "login.kdbx (메인)")
    
    src_databases = []
    for t in TARGETS:
        basename = os.path.basename(t["path"])
        kp = open_db_with_prompt(t["path"], basename)
        src_databases.append((t, kp))

    # 3. 그룹 생성 및 데이터 복사
    print("\n[3/4] 데이터 통합 진행 중...")
    for t, src_kp in src_databases:
        group_name = t["group_name"]
        print(f"\n  ▶ '{group_name}' 그룹 생성 및 데이터 이전 중...")

        # 루트 하위에 새 그룹 생성
        dest_group = main_kp.add_group(
            destination_group=main_kp.root_group,
            group_name=group_name
        )

        e_cnt, g_cnt = copy_group_contents(
            target_kp=main_kp,
            target_group=dest_group,
            src_group=src_kp.root_group,
            recycle_bin_group=src_kp.recyclebin_group
        )
        print(f"    ✓ 완료: 총 {e_cnt}개 항목, {g_cnt}개 서브그룹 통합됨")

    # 4. 저장 및 완료 검증
    print("\n[4/4] 변경사항 저장 중...")
    try:
        main_kp.save()
        print(f"  ✓ {MAIN_DB_PATH} 파일 저장 성공!")
    except Exception as e:
        print(f"❌ 저장 실패: {e}")
        print(f"  복원을 위해 백업 파일이 보존되어 있습니다: {backup_path}")
        sys.exit(1)

    print("\n" + "=" * 60)
    print("🎉 모든 KeePass 데이터베이스가 성공적으로 통합되었습니다!")
    print(f"   - 백업 파일 : {backup_path}")
    print(f"   - 최종 DB   : {MAIN_DB_PATH}")
    print("=" * 60)

if __name__ == "__main__":
    main()
