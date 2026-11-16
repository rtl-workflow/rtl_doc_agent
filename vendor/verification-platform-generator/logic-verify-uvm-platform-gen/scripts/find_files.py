#!/usr/bin/env python3
"""
文件模式匹配脚本

根据模式搜索文件，支持基础模式和子目录模式。

用法:
    python find_files.py <root_dir> "<pattern>"
    python find_files.py <root_dir> --subdir "GEN/*" "*.sv"
    python find_files.py <root_dir> --type GEN --pattern "*.sv"
"""

import os
import sys
import json
import glob
import argparse
from pathlib import Path


def find_files_basic(root: str, pattern: str) -> list:
    """
    基础模式搜索：在根目录下搜索匹配的文件

    Args:
        root: 根目录
        pattern: 文件模式（如 *.sv）

    Returns:
        文件路径列表
    """
    search_path = os.path.join(root, pattern)
    files = glob.glob(search_path)
    return sorted([os.path.relpath(f, root) for f in files])


def find_files_subdir(root: str, subdir_pattern: str, file_pattern: str) -> list:
    """
    子目录模式搜索：列出每个子目录下匹配的文件

    Args:
        root: 根目录
        subdir_pattern: 子目录模式（如 GEN/* 或 *）
        file_pattern: 文件模式（如 *.sv）

    Returns:
        每个子目录下文件的字典
    """
    result = {}

    # 获取子目录路径
    subdir_base = os.path.join(root, subdir_pattern.replace("/*", ""))

    if not os.path.isdir(subdir_base):
        return {"error": f"目录不存在: {subdir_base}"}

    # 遍历子目录
    try:
        subdirs = [d for d in os.listdir(subdir_base)
                  if os.path.isdir(os.path.join(subdir_base, d))]
    except Exception as e:
        return {"error": str(e)}

    for subdir in sorted(subdirs):
        subdir_path = os.path.join(subdir_base, subdir)
        search_path = os.path.join(subdir_path, file_pattern)
        files = glob.glob(search_path)

        if files:
            result[subdir] = sorted([
                os.path.relpath(f, root) for f in files
            ])

    return result


def find_files_by_type(root: str, comp_type: str, pattern: str) -> list:
    """
    按组件类型搜索文件

    Args:
        root: 组件根目录
        comp_type: 组件类型（GEN/BFM/RM/SVA/FUNC/DUT_CFG）
        pattern: 文件模式

    Returns:
        文件路径列表
    """
    comp_path = os.path.join(root, comp_type)
    if not os.path.isdir(comp_path):
        return []

    # 递归搜索所有 .sv 文件
    search_path = os.path.join(comp_path, "**", pattern)
    files = glob.glob(search_path, recursive=True)

    return sorted([
        os.path.relpath(f, root) for f in files
    ])


def find_all_sv_files(root: str, comp_type: str = None) -> dict:
    """
    查找目录下所有 SV 文件

    Args:
        root: 根目录
        comp_type: 可选的组件类型过滤

    Returns:
        组件类型到文件列表的字典
    """
    result = {}
    comp_types = [comp_type] if comp_type else ["GEN", "BFM", "RM", "SVA", "FUNC", "DUT_CFG"]

    for ct in comp_types:
        comp_path = os.path.join(root, ct)
        if os.path.isdir(comp_path):
            search_path = os.path.join(comp_path, "**", "*.sv")
            files = glob.glob(search_path, recursive=True)
            result[ct] = sorted([
                os.path.relpath(f, comp_path) for f in files
            ])

    return result


def main():
    parser = argparse.ArgumentParser(
        description="文件模式匹配工具",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
示例:
  python find_files.py D:/AI_BT/components "*.sv"
  python find_files.py D:/AI_BT/components --subdir "GEN/*" "*.sv"
  python find_files.py D:/AI_BT/components --type GEN --pattern "*.sv"
  python find_files.py D:/AI_BT/components --all-sv
        """
    )

    parser.add_argument("root", help="根目录路径")
    parser.add_argument("pattern", nargs="?", help="文件模式（如 *.sv）")
    parser.add_argument("--subdir", help="子目录模式（如 GEN/* 或 *）")
    parser.add_argument("--type", "-t", dest="comp_type", help="组件类型（GEN/BFM/RM/SVA/FUNC/DUT_CFG）")
    parser.add_argument("--all-sv", action="store_true", help="查找所有 SV 文件")
    parser.add_argument("--json", action="store_true", help="JSON 格式输出")

    args = parser.parse_args()

    root = args.root

    if not os.path.isdir(root):
        print(f"错误: 目录不存在: {root}", file=sys.stderr)
        sys.exit(1)

    result = {}

    if args.all_sv:
        # 查找所有 SV 文件
        result = find_all_sv_files(root, args.comp_type)
    elif args.subdir and args.pattern:
        # 子目录模式搜索
        result = find_files_subdir(root, args.subdir, args.pattern)
    elif args.comp_type and args.pattern:
        # 按组件类型搜索
        result[args.comp_type] = find_files_by_type(root, args.comp_type, args.pattern)
    elif args.pattern:
        # 基础模式搜索
        result["files"] = find_files_basic(root, args.pattern)
    else:
        print("错误: 请指定搜索模式", file=sys.stderr)
        parser.print_help()
        sys.exit(1)

    # 输出结果
    if args.json:
        print(json.dumps(result, indent=2, ensure_ascii=False))
    else:
        # 友好的文本输出
        if isinstance(result, dict):
            for key, value in result.items():
                if isinstance(value, list):
                    print(f"## {key}:")
                    for f in value:
                        print(f"  - {f}")
                    print()
                else:
                    print(f"{key}: {value}")
        else:
            for f in result.get("files", []):
                print(f)


if __name__ == "__main__":
    main()