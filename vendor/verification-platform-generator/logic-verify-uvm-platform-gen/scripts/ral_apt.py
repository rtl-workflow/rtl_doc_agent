import re,sys
import argparse
from pathlib import Path
import os
from typing import Optional
import extract_classname,classname_replace,filename_replace
from collections import defaultdict
import shutil
import time

def extract_class_definitions(sv_file_path):
    """提取所有 class 的定义内容及类名"""
    with open(sv_file_path, 'r') as f:
        content = f.read()

    # 匹配 class 定义（包括 extends 和可选的关键字）
    class_pattern = re.compile(
        r'(class\s+(\w+)(?:\s+extends\s+\w+)?\s*;.*?endclass\b.*?)', 
        re.DOTALL
    )

    classes = {}
    for match in re.finditer(class_pattern, content):
        class_def = match.group(1).strip()
        class_name = match.group(2)
        classes[class_name] = class_def
    return classes

def find_instances(sv_content, class_names):
    """找出类实例化关系，兼容 rand/virtual 等修饰符"""
    instance_pattern = re.compile(
        r'(?:\b(?:rand|virtual|const)\s+)*\b({})\b\s+(\w+)\s*(?:=|;|\()'.format(
            '|'.join(map(re.escape, class_names))  # 转义类名避免特殊字符
        ), 
        re.DOTALL
    )
    
    # 记录哪些类被实例化 {被实例化的类: [实例化它的类]}
    dependency = defaultdict(set)
    for instance_match in re.finditer(instance_pattern, sv_content):
        target_class = instance_match.group(1)  # 被实例化的类名
        for class_name in class_names:
            # 检查实例化语句是否发生在当前 class 的定义块内
            class_def_start = sv_content.find(f"class {class_name}")
            class_def_end = sv_content.find("endclass", class_def_start) + len("endclass")
            if class_def_start <= instance_match.start() <= class_def_end:
                dependency[target_class].add(class_name)
    return dependency

def find_top_classes(sv_file_path):
    """主函数：提取顶层类定义"""
    classes = extract_class_definitions(sv_file_path)
    if not classes:
        print("未找到任何 class 定义！")
        return {}

    with open(sv_file_path, 'r') as f:
        sv_content = f.read()

    dependency = find_instances(sv_content, classes.keys())
    top_class_names = set(classes.keys()) - set(dependency.keys())
    
    return {name: classes[name] for name in top_class_names}   

def copy_sv_file_with_retry(src_file, dest_path, max_retries=3, retry_delay=1):
    """
    安全复制文件到目标路径，如果遇到文件占用错误会自动重试
    Args:
        src_file: 源文件路径
        dest_path: 目标文件夹路径
        max_retries: 最大重试次数
        retry_delay: 每次重试间隔（秒）
    Returns:
        bool: 是否成功复制
    """
    filename = os.path.basename(src_file)
    dest_file = os.path.join(dest_path, filename)

    for attempt in range(max_retries + 1):
        try:
            shutil.copy2(src_file, dest_file)  # 保留文件元数据
            #print(f"成功复制文件: {src_file} -> {dest_file}")
            return True
        except PermissionError as e:
            if attempt == max_retries:
                print(f"复制失败（达到最大重试次数）: {e}")
                return False
            print(f"文件被占用，正在重试 ({attempt + 1}/{max_retries})...")
            time.sleep(retry_delay)
        except Exception as e:
            print(f"复制文件时发生未知错误: {e}")
            return False
    return False


def main(sv_file_path,dest_path,flist):     
    
    if sv_file_path == None:
        print("No ral SV file found.")
        return
    top_classes = find_top_classes(sv_file_path)
    ral_name=""

    if top_classes:
        #print("顶层 class 定义（未被其他 class 实例化）：")
        for name, class_def in top_classes.items():
            print(f"// ------ Class: {name} ------")
            #print(class_def)
            #print("\n")
        ral_name=name

    else:
        print("未找到顶层 class（所有 class 均被其他 class 实例化）。")

    #获取文件名
    filename = os.path.splitext(os.path.basename(sv_file_path))[0]

    #将sv_file_path对应的文件拷贝到dest_path
     # 检查目标目录是否存在，不存在则创建
    if not os.path.exists(dest_path):
        os.makedirs(dest_path)
    
    
    
    #删除原文件dest_path+"top_cib_model.sv"
    old_file = os.path.join(dest_path, "top_cib_model.sv")
    #print("要删除的文件"+old_file)
    # if os.path.exists(old_file):
    #     try:
    #         #os.remove(old_file)  # 删除旧文件
    #         print(f"✅ 已删除旧文件：{old_file}")
    #     except Exception as e:
    #         print(f"❌ 删除旧文件失败：{e}")
            
    #类名替换
    classname_replace.replace_classname(flist,"top_cib_model",ral_name)

    #文件名替换
    filename_replace.replace_in_files(flist, "top_cib_model", filename)  

    # 安全复制文件
    # print("sv_file_path:"+sv_file_path)
    # print("dest_path:"+dest_path)
    success = copy_sv_file_with_retry(sv_file_path, dest_path)      

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='RAL Generator')
    parser.add_argument('--sv_file_path', required=True, help='source ral path')
    parser.add_argument('--dest_path', required=True, help='dest ral path')
    parser.add_argument('--flist', required=True, help='flist file path')
    args = parser.parse_args()
    main(args.sv_file_path,args.dest_path,args.flist)