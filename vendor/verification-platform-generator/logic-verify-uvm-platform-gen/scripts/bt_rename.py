import os
import argparse
import shutil
from pathlib import Path

def replace_in_file(file_path, search_str, replace_str, dry_run=False):
    """替换文件内容中的字符串"""
    try:
        with open(file_path, 'r', encoding='utf-8') as file:
            content = file.read()
        
        if search_str in content:
            new_content = content.replace(search_str, replace_str)
            
            if dry_run:
                print(f"[Dry Run] 将修改文件内容: '{file_path}'")
                return False
            else:
                # 创建一个临时文件保存修改后的内容
                temp_file = f"{file_path}.tmp"
                with open(temp_file, 'w', encoding='utf-8') as file:
                    file.write(new_content)
                
                # 覆盖原文件
                shutil.move(temp_file, file_path)
                #print(f"已修改文件内容: '{file_path}'")
                return True
    except UnicodeDecodeError:
        #print(f"警告: 文件 '{file_path}' 可能不是文本文件，跳过内容替换")
        return False
    except Exception as e:
        print(f"错误: 处理文件 '{file_path}' 时出错: {e}")
        return False

def rename_files_and_dirs(root_dir, search_str, replace_str, recursive=True, dry_run=False):
    """递归重命名目录中的文件、文件夹及其内容"""
    # 采用自底向上遍历，先处理子目录再处理父目录
    for root, dirs, files in os.walk(root_dir, topdown=False):
        # 处理文件内容
        for file in files:
            file_path = os.path.join(root, file)
            try:
                # 如果是文本文件，替换内容
                if os.path.isfile(file_path) and not file_path.endswith('.tmp'):
                    replace_in_file(file_path, search_str, replace_str, dry_run)
            except Exception as e:
                print(f"错误: 处理文件内容 '{file_path}' 时出错: {e}")

        # 处理文件名
        for file in files:
            if search_str in file:
                old_path = os.path.join(root, file)
                new_file = file.replace(search_str, replace_str)
                new_path = os.path.join(root, new_file)
                
                if dry_run:
                    print(f"[Dry Run] 将重命名文件: '{old_path}' -> '{new_path}'")
                else:
                    try:
                        os.rename(old_path, new_path)
                        #print(f"已重命名文件: '{old_path}' -> '{new_path}'")
                    except OSError as e:
                        print(f"错误: 无法重命名文件 '{old_path}': {e}")

        # 处理目录名
        for dir_name in dirs:
            if search_str in dir_name:
                old_path = os.path.join(root, dir_name)
                new_dir = dir_name.replace(search_str, replace_str)
                new_path = os.path.join(root, new_dir)
                
                if dry_run:
                    print(f"[Dry Run] 将重命名目录: '{old_path}' -> '{new_path}'")
                else:
                    try:
                        os.rename(old_path, new_path)
                        #print(f"已重命名目录: '{old_path}' -> '{new_path}'")
                    except OSError as e:
                        print(f"错误: 无法重命名目录 '{old_path}': {e}")

        if not recursive:
            break  # 不递归处理子目录

def main():
    parser = argparse.ArgumentParser(
        description="递归重命名目录中的文件、文件夹及其内容",
        epilog="示例: python rename_all.py /path/to/dir 'old_text' 'new_text' --dry-run"
    )
    parser.add_argument("--root_dir", help="要处理的根目录")
    parser.add_argument("--search_str", help="要查找的字符串")
    parser.add_argument("--replace_str", help="替换为的字符串")
    parser.add_argument("--no-recursive", dest="recursive", action="store_false",
                       help="不递归处理子目录")
    parser.add_argument("--dry-run", action="store_true",
                       help="仅预览操作而不实际执行")

    args = parser.parse_args()
    
    if not os.path.isdir(args.root_dir):
        print(f"错误: '{args.root_dir}' 不是一个有效的目录")
        return
    
    rename_files_and_dirs(
        args.root_dir,
        args.search_str,
        args.replace_str,
        recursive=args.recursive,
        dry_run=args.dry_run
    )
    
    print("处理完成")

if __name__ == "__main__":
    main()