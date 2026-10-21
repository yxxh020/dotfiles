#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
KeePass Verification Tool
Print group structure and entry count for login.kdbx
"""

import os
import sys
import getpass
from pykeepass import PyKeePass
from pykeepass.exceptions import CredentialsError

DB_PATH = os.path.join(os.path.dirname(os.path.abspath(__file__)), "login.kdbx")

def print_group_tree(group, depth=0):
    indent = "    " * depth
    prefix = "📁 " if depth > 0 else "🗄️ "
    entry_count = len(group.entries)
    print(f"{indent}{prefix}{group.name} (항목: {entry_count}개)")
    
    for entry in group.entries:
        item_indent = "    " * (depth + 1)
        user_info = f" [{entry.username}]" if entry.username else ""
        print(f"{item_indent}📄 {entry.title}{user_info}")

    for sub in group.subgroups:
        print_group_tree(sub, depth + 1)

def main():
    print("=" * 60)
    print(f" KeePass 구조 확인: {DB_PATH}")
    print("=" * 60)

    while True:
        try:
            pwd = getpass.getpass("🔑 [login.kdbx] 마스터 비밀번호 입력: ")
            if not pwd:
                continue
            kp = PyKeePass(DB_PATH, password=pwd)
            print("\n[데이터베이스 그룹 및 항목 구조]")
            print_group_tree(kp.root_group)
            print("=" * 60)
            print(f"총 항목 수: {len(kp.entries)}개 / 총 그룹 수: {len(kp.groups)}개")
            break
        except CredentialsError:
            print("❌ 비밀번호가 올바르지 않습니다. 다시 입력해주세요.")
        except Exception as e:
            print(f"❌ 오류 발생: {e}")
            break

if __name__ == "__main__":
    main()
