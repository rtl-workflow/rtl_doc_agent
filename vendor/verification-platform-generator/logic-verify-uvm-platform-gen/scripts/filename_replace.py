import os
import re
import argparse
from typing import List, Tuple
from pathlib import Path


def read_file_list(file_list_path: str) -> Tuple[List[str], str]:
    """从.f文件中读取文件列表，并处理相对路径"""
    file_dir = os.path.dirname(os.path.abspath(file_list_path))
    with open(file_list_path, 'r') as f:
        lines = [line.strip() for line in f.readlines()]
    
    file_paths = []
    for line in lines:
        if not line or line.startswith('#'):
            continue
        abs_path = os.path.join(file_dir, line) if not os.path.isabs(line) else line
        file_paths.append(abs_path)
    
    return file_paths, file_dir




def replace_in_files(
    file_list_path: str,
    old_pattern: str,
    new_pattern: str,
    dry_run: bool = False
) -> None:
    """
    目标：严格匹配 文件名（去除扩展名后）的 old_pattern
    
    示例：
    - 输入 `old_pattern=rm_temp` 会匹配 `rm_temp.txt`，不匹配 `rm_temp_data.txt`
    - 输入 `old_pattern=rm_temp.txt` 会精确匹配 `rm_temp.txt`（含扩展名）
    """
    file_list_path = Path(file_list_path).resolve()
    file_dir = file_list_path.parent
    
    with open(file_list_path, 'r') as f:
        original_lines = f.readlines()
    
    new_lines = []
    renamed_files = []
    
    for line in original_lines:
        line = line.strip()
        
        # 跳过注释行和空行
        if line.startswith('#') or not line:
            new_lines.append(line + '\n')
            continue
        
        # 解析文件名（不含路径）
        old_path = file_dir / line if not os.path.isabs(line) else Path(line)
        old_name = old_path.name  # 完整文件名，如 `rm_temp.txt`

                
        # 提取 **无扩展名** 的部分（严格匹配）
        old_basename = old_path.stem  # `rm_temp.txt` → `rm_temp`
        
        # 仅当 basename（无扩展名）完全匹配时才替换
        if old_basename == old_pattern:
            # 构造新文件名（保留原扩展名）
            new_name = f"{new_pattern}{old_path.suffix}"  # `new_pattern` + `.ext`
            new_path = old_path.parent / new_name
            
            if old_path.exists():
                renamed_files.append((old_path, new_path))
                #print(f"[重命名] {old_path} → {new_path}")
            else:
                print(f"[警告] 文件不存在，跳过: {old_path}")
            
            # 更新 .f 文件中的引用（保持相对/绝对路径）
            if not os.path.isabs(line):
                new_line = str(Path(line).parent / new_name) if Path(line).parent != Path('.') else new_name
            else:
                new_line = str(new_path)
            
            new_lines.append(new_line.replace("\\", "/") + '\n')
        else:
            new_lines.append(line.replace("\\", "/") + '\n')
    
    if not renamed_files:
        print(f"未找到匹配 '{old_pattern}' 的文件名（不含扩展名），无需修改。")
        return
    
    # 实际重命名或模拟运行
    if not dry_run:
        for old_path, new_path in renamed_files:
            os.rename(old_path, new_path)
        with open(file_list_path, 'w') as f:
            f.writelines(new_lines)
        #print(f"成功: 重命名了 {len(renamed_files)} 个文件，并更新了 {file_list_path}")
    else:
        print(f"[模拟运行] 将重命名 {len(renamed_files)} 个文件，但不实际修改。")



if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="批量重命名文件及文件列表引用（可自定义替换规则）"
    )
    parser.add_argument(
        "file_list",
        help="包含文件列表的.f文件路径"
    )
    parser.add_argument(
        "-o", "--old",
        required=True,
        help="要被替换的原文件名模式（支持正则表达式）"
    )
    parser.add_argument(
        "-n", "--new",
        required=True,
        help="新文件名模式"
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="仅预览更改，不实际执行"
    )
    args = parser.parse_args()

    if not args.file_list.endswith(('.f', '.flist')):
        print("错误：输入必须是.f/.flist文件列表！")
        exit(1)

    replace_in_files(args.file_list, args.old, args.new, args.dry_run)