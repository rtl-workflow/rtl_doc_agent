import re
import os
from pathlib import Path
from typing import List, Set



def read_file_list(
    file_list_path: str,
    visited_files: Set[str] = None,
    _recursion_depth: int = 0
) -> List[str]:
    """
    递归解析文件列表（兼容 `-f/-F path` 风格，跳过注释和空行）
    
    Args:
        file_list_path (str): 文件列表路径（支持 `-f/-F` 前缀或裸路径）
        visited_files (Set[str]): 已解析的路径（防循环）
        _recursion_depth (int): 递归深度（调试）

    Returns:
        List[str]: 去重后的文件绝对路径列表（保持原始顺序）

    Raises:
        FileNotFoundError: 文件不存在
    """
    if visited_files is None:
        visited_files = set()

    # 统一处理 `-f` 或 `-F` 前缀
    file_list_path = file_list_path.strip()
    if file_list_path.lower().startswith(("-f ", "-f\t")):
        file_list_path = file_list_path[2:].strip()
    elif file_list_path.lower().startswith(("-f", "-F")) and len(file_list_path) > 2 and not file_list_path[2].isspace():
        # 处理无空格的格式（如 -Fpath/to/file）
        file_list_path = file_list_path[2:]

    # 转为绝对路径
    file_list_path = os.path.abspath(file_list_path)
    
    # 防循环引用
    if file_list_path in visited_files:
        # print(f"[WARN] 跳过循环引用: {file_list_path}")
        return []
    visited_files.add(file_list_path)

    if not os.path.exists(file_list_path):
        raise FileNotFoundError(f"文件列表不存在: {file_list_path}")

    file_dir = os.path.dirname(file_list_path)
    files = []
    
    with open(file_list_path, 'r') as f:
        for line in f:
            line = line.strip()
            
            # 跳过空行、注释行
            if not line or line.startswith('//'):
                continue

            # 统一处理当前行的 `-f/-F` 前缀（支持任意大小写和空格）
            if line.lower().startswith(("-f ", "-f\t", "-f", "-f")):  # 兼容 -f, -F, -f path, -Fpath
                line = line[2:].strip()

            # 处理相对路径
            abs_path = (
                os.path.normpath(os.path.join(file_dir, line))  # 规范化路径分隔符
                if not os.path.isabs(line) 
                else line
            )

            # 递归解析 .f/.list 文件
            ext = os.path.splitext(abs_path)[1].lower()
            if ext in ('.f', '.list'):
                nested_files = read_file_list(
                    abs_path,
                    visited_files,
                    _recursion_depth + 1
                )
                files.extend(nested_files)
            else:
                if os.path.exists(abs_path):
                    files.append(abs_path)
                # else:
                #     print(f"[WARN] 文件不存在: {abs_path}")

    # 去重并保留原始顺序
    return list(dict.fromkeys(files))

def replace_in_files(
    file_paths: List[str],
    old_pattern: str,
    new_replacement: str,
    dry_run: bool = False
) -> None:
    """
    替换文件列表中的指定字符串模式（排除前后是 '_'、字母或数字的情况）。
    
    :param file_paths: 待处理文件路径列表
    :param old_pattern: 需要替换的旧字符串（如 "bfm_temp_driver"）
    :param new_replacement: 替换后的新字符串（如 "pkt_fifo_driver"）
    :param dry_run: 若为 True，仅显示替换结果但不实际修改文件
    """
    # 构造正则表达式，确保匹配的单词边界不是 '_'、字母或数字
    pattern = rf'(?<![_a-zA-Z0-9]){re.escape(old_pattern)}(?![_a-zA-Z0-9])'
    
    for file_path in file_paths:
        if not os.path.isfile(file_path):
            #print(f"警告: 文件不存在，跳过 -> {file_path}")
            continue
            
        with open(file_path, 'r', encoding='utf-8') as f:
            original_content = f.read()
        
        new_content, count = re.subn(pattern, new_replacement, original_content)
        
        if count == 0:
            #print(f"无替换: {file_path}")
            continue
            
        #print(f"替换 {count} 处: {file_path}")
        if not dry_run:
            with open(file_path, 'w', encoding='utf-8') as f:
                f.write(new_content)

def replace_classname(file_list_path: str,old_pattern: str,new_replacement: str):             
    target_files = read_file_list(file_list_path)   
    replace_in_files(target_files, old_pattern, new_replacement) 

if __name__ == "__main__":
    import argparse

    parser = argparse.ArgumentParser(
        description='批量替换文件中的 `bfm_temp_driver`（支持 .f 文件列表）'
    )
    parser.add_argument(
        'input',
        help='目标文件路径或 .f 文件列表（每行一个路径）'
    )
    parser.add_argument(
        '--dry-run', 
        action='store_true',
        help='仅打印替换结果，不修改文件'
    )
    args = parser.parse_args()

    if args.input.endswith('.f'):
        # 从 .f 文件读取列表
        target_files = read_file_list(args.input)
    else:
        # 直接处理单个文件
        target_files = [args.input]

    replace_in_files(target_files, "bfm_temp_driver","pkt_fifo_driver",args.dry_run)