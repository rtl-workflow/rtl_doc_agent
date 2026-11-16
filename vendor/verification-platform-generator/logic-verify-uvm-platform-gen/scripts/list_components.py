#!/usr/bin/env python3
"""
组件目录扫描脚本

扫描 components_root 下的所有组件目录，生成 JSON 格式的目录树。

用法:
    python list_components.py <components_root>
    python list_components.py <components_root> GEN
"""

import os
import sys
import json
import glob
from pathlib import Path
from datetime import datetime


def get_dir_mtime(path: str) -> float:
    """获取目录的修改时间"""
    try:
        return os.path.getmtime(path)
    except:
        return 0


def scan_component_dir(root: str, comp_type: str) -> dict:
    """
    扫描单个组件目录

    Args:
        root: 组件根目录
        comp_type: 组件类型 (GEN/BFM/RM/SVA/FUNC/DUT_CFG)

    Returns:
        包含目录信息的字典
    """
    comp_path = os.path.join(root, comp_type)
    result = {
        "type": comp_type,
        "path": comp_path,
        "exists": os.path.isdir(comp_path),
        "subdirs": []
    }

    if not result["exists"]:
        return result

    # 获取所有子目录并按修改时间排序（最新的在前）
    try:
        subdirs = [d for d in os.listdir(comp_path)
                  if os.path.isdir(os.path.join(comp_path, d))]
        subdirs.sort(key=lambda d: get_dir_mtime(os.path.join(comp_path, d)),
                    reverse=True)
    except Exception as e:
        result["error"] = str(e)
        return result

    # 扫描每个子目录
    for subdir in subdirs:
        subdir_path = os.path.join(comp_path, subdir)
        subdir_info = {
            "name": subdir,
            "path": subdir_path,
            "files": [],
            "subfolders": []
        }

        # 获取该子目录下的所有 .sv 文件和一级子文件夹
        try:
            for f in sorted(os.listdir(subdir_path)):
                full_path = os.path.join(subdir_path, f)
                if os.path.isfile(full_path) and f.endswith('.sv'):
                    subdir_info["files"].append({
                        "name": f,
                        "path": full_path
                    })
                elif os.path.isdir(full_path):
                    # 统计子文件夹中的 .sv 文件数量
                    sv_count = len([fi for fi in os.listdir(full_path) 
                                   if os.path.isfile(os.path.join(full_path, fi)) and fi.endswith('.sv')])
                    subdir_info["subfolders"].append({
                        "name": f,
                        "path": full_path,
                        "sv_count": sv_count
                    })
        except Exception as e:
            subdir_info["error"] = str(e)

        result["subdirs"].append(subdir_info)

    return result


def scan_all_components(root: str, comp_types: list = None) -> dict:
    """
    扫描所有组件目录

    Args:
        root: 组件根目录
        comp_types: 要扫描的组件类型列表，None 表示所有类型

    Returns:
        包含所有组件目录信息的字典
    """
    if comp_types is None:
        comp_types = ["TRANS", "BFM", "RM", "SVA", "FUNC", "DUT_CFG"]

    result = {}
    for comp_type in comp_types:
        result[comp_type] = scan_component_dir(root, comp_type)

    return result


def format_for_user(components: dict) -> str:
    """
    格式化输出给用户选择的目录列表

    Args:
        components: 组件目录信息字典

    Returns:
        格式化后的字符串
    """
    lines = []
    for comp_type, comp_info in components.items():
        if not comp_info.get("exists", False):
            lines.append(f"## {comp_type}: 目录不存在")
            continue

        lines.append(f"## {comp_type}:")

        subdirs = comp_info.get("subdirs", [])
        if not subdirs:
            lines.append("  (无子目录)")
            continue

        for idx, subdir in enumerate(subdirs, 1):
            files = subdir.get("files", [])
            subfolders = subdir.get("subfolders", [])
            file_count = len(files)
            
            # 构建显示字符串
            info_parts = [f"{file_count} 个 .sv 文件"]
            if subfolders:
                folder_names = [sf["name"] for sf in subfolders]
                info_parts.append(f"子文件夹: {', '.join(folder_names)}")
            
            lines.append(f"  {idx}. {subdir['name']} ({', '.join(info_parts)})")

        lines.append("")

    return "\n".join(lines)


def main():
    if len(sys.argv) < 2:
        print("用法: python list_components.py <components_root> [COMP_TYPE]")
        print("示例: python list_components.py D:/AI_BT/components")
        print("      python list_components.py D:/AI_BT/components GEN")
        sys.exit(1)

    components_root = sys.argv[1]

    if not os.path.isdir(components_root):
        print(f"错误: 目录不存在: {components_root}")
        sys.exit(1)

    # 可选：指定要扫描的组件类型
    comp_types = None
    if len(sys.argv) >= 3:
        comp_types = [sys.argv[2].upper()]

    # 扫描组件目录
    result = scan_all_components(components_root, comp_types)

    # 输出 JSON 格式
    print(json.dumps(result, indent=2, ensure_ascii=False))

    # 同时输出用户友好的格式（作为注释）
    print("\n# 可选择的组件目录：")
    print(format_for_user(result))


if __name__ == "__main__":
    main()