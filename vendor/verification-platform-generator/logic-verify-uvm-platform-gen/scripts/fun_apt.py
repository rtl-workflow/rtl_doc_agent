import re
import os
from pathlib import Path
from typing import Optional
import argparse

def extract_class_content(file_path):
    """从文件中提取class到endclass之间的内容（不包含边界行）"""
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # 改进后的正则表达式，处理带类名的情况
    pattern = re.compile(
        r'^\s*class\s+\w+\s*(?:#\(.*?\))?.*?$(?P<content>[\s\S]*?)^\s*endclass(?:\s*:\s*\w+)?\s*$',
        re.MULTILINE | re.IGNORECASE
    )
    
    match = pattern.search(content)
    if not match:
        raise ValueError(f"在文件 {file_path} 中未找到 class/endclass 定义")
    
    return match.group('content').strip()

def replace_class_content(source_file, target_file):
    """将源文件的class内容替换到目标文件中"""
    try:
        # 提取源文件和目标文件的class内容
        source_content = extract_class_content(source_file)
        target_full_content = open(target_file, 'r', encoding='utf-8').read()
        
        # 改进后的正则表达式，处理以下情况：
        # 1. class可能有参数(ex: class my_class #(param))
        # 2. endclass后面可能有扩展(ex: endclass : my_class)
        pattern = re.compile(
            r'(^\s*class\s+\w+\s*(?:#\(.*?\))?.*?$)([\s\S]*?)(^\s*endclass(?:\s*:\s*\w+)?\s*$)',
            re.MULTILINE | re.IGNORECASE
        )
        
        # 进行替换
        new_content = pattern.sub(
            lambda m: m.group(1) + '\n' + source_content + '\n' + m.group(3),
            target_full_content
        )
        
        # 写入修改后的内容
        with open(target_file, 'w', encoding='utf-8') as f:
            f.write(new_content)
            
        #print(f"成功将 {source_file} 的class内容替换到 {target_file}")
        return True
    
    except Exception as e:
        print(f"处理失败: {str(e)}")
        return False


def main(file_a,file1):
       
    if file_a == None:
        print("No func SV file found.")
        return

    file_b = file1
    
    replace_class_content(file_a, file_b)

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='FUNC Generator')
    parser.add_argument('--selected_fcov', required=True, help='selected_fcov sv path')
    parser.add_argument('--demo_fcov', required=True, help='demo_fcov sv path')
    args = parser.parse_args()
    main(args.selected_fcov,args.demo_fcov)