import re,sys
import argparse
from pathlib import Path
import os
from typing import Optional
import extract_classname,classname_replace,filename_replace


def main():
    parser = argparse.ArgumentParser(description='dut_cfg Generator')
    parser.add_argument('--source_file', required=True, help='Comma-separated DUT_CFG folder paths')
    parser.add_argument('--dest_file', required=True, help='Target DUT_CFG directory path')
    parser.add_argument('--flist', required=True, help='flist file path')
    parser.add_argument('--bt_index', required=True, help='bt_index')
    args = parser.parse_args()    
    
    source_file = args.source_file
    dest_file = args.dest_file
    flist = args.flist
    bt_index = args.bt_index
    
    if source_file == None:
        print("No dut_cfg SV file found.")
        return

        
    try:
        with open(source_file,'r', encoding='utf-8') as f:
            src_content = f.read()
    except Exception as e:
        print(f"Error reading file {source_file}: {e}", file=sys.stderr)
        return {}

    try:
        with open(dest_file,'r', encoding='utf-8') as f:
            dest_content = f.read()
    except Exception as e:
        print(f"Error reading file {dest_file}: {e}", file=sys.stderr)
        return {}

    if src_content:
        if bt_index == "2":
            last_endtask_pos = dest_content.rfind('`define gaea_demo_dut_cfg')
        else:
            last_endtask_pos = dest_content.rfind('`define superbench_demo_dut_cfg')
        if last_endtask_pos != -1:
            # 查找最后一个 endtask 之后的行结束位置
            remainder = dest_content[last_endtask_pos:]
            next_newline = remainder.find('\n')
            insertion_point = last_endtask_pos + next_newline + 1 if next_newline != -1 else len(dest_content)
            
            # 追加剩余的 tasks，每个 task 之间加换行符
            dest_content = (
                dest_content[:insertion_point] +
                '\n' +  # 确保插入之前有换行
                src_content +
                '\n'+  # 确保末尾有空行
                '`endif'
            )    

    #提取类名   
    classname = extract_classname.extract_class(source_file)            
    
    try:
        with open(dest_file, 'w', encoding='utf-8') as f:
            f.write(str(dest_content).replace("extends uvm_object","extends lvp_dut_cfg_base"))
    except Exception as e:
        print(f"Error writing file {dest_file}: {e}", file=sys.stderr)
        return {}

    
    #获取文件名
    filename = os.path.splitext(os.path.basename(source_file))[0]

    #提取类名   
    #classname = extract_classname.extract_class(source_file)
    
    print("dut_cfg file name:"+filename)
    print("dut_cfg class name:"+classname)
    
    if bt_index == "2":
        #类名替换
        classname_replace.replace_classname(flist,"gaea_demo_dut_cfg",classname)
        #文件名替换
        filename_replace.replace_in_files(flist, "gaea_demo_dut_cfg", filename)
    else:
        #类名替换
        classname_replace.replace_classname(flist,"superbench_demo_dut_cfg",classname)
        #文件名替换
        filename_replace.replace_in_files(flist, "superbench_demo_dut_cfg", filename)

            

if __name__ == '__main__':
    main()