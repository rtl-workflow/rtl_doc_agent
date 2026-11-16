import re
import sys
from typing import List, Dict, Optional

def extract_sv_classes(file_path: str) -> List[Dict[str, Optional[str]]]:
    """
    从 SystemVerilog 文件中提取类定义，包括：
    - 类名
    - 泛型参数（如 `#(type T=int, int WIDTH=32)`）
    - 继承关系（如 `extends uvm_component`）
    - 完整的类定义（含 `uvm_component_utils` 等宏）

    Args:
        file_path: SystemVerilog 文件路径。

    Returns:
        List[Dict]: 提取的类信息，格式示例：
            {
                "name": "pkt_fifo_driver",
                "params": "type DATA_TYPE=uvm_sequence_item, int DATA_WIDTH=32",
                "parent": "uvm_component",
                "full_def": "class pkt_fifo_driver #(...) extends uvm_component; ..."
            }
    """
    with open(file_path, "r", encoding="utf-8") as f:
        content = f.read()

    # 正则表达式匹配 SystemVerilog 类定义：
    # 1. 匹配 `class` 关键字
    # 2. 类名
    # 3. 可选泛型参数（如 `#(type T=int, ...)`）
    # 4. 可选的继承（`extends ParentClass`）
    # 5. 匹配到分号结束或宏（如 `uvm_component_utils`）
    class_pattern = re.compile(
        r"class\s+"                # 'class' 关键字
        r"(\w+)"                   # 类名
        r"(?:\s*#\((.*?)\))?"      # 泛型参数（可选）
        r"(?:\s+extends\s+(\w+))?" # 继承的父类（可选）
        r"[^;]*;"                  # 匹配到分号结束
        r"(?:\s*`uvm_component.*?;)?"  # 可选的 UVM 宏
    )

    classes = []
    for match in class_pattern.finditer(content):
        class_name = match.group(1)
        type_params = match.group(2)  # 泛型参数
        parent_class = match.group(3) # 继承的父类
        full_definition = match.group(0).strip()

        classes.append({
            "name": class_name,
            "params": type_params.strip() if type_params else None,
            "parent": parent_class,
            "full_def": full_definition,
        })

    return classes

def print_classes(classes: List[Dict]) -> None:
    """打印提取的类信息"""
    for i, cls in enumerate(classes, 1):
        print(f"Class {i}:")
        print(f"  Name: {cls['name']}")
        if cls["params"]:
            print(f"  Params: {cls['params']}")
        if cls["parent"]:
            print(f"  Parent: {cls['parent']}")
        print(f"  Definition: {cls['full_def']}\n")

def main():
    if len(sys.argv) != 2:
        print("Usage: python extract_sv_classes.py <file.sv>")
        sys.exit(1)

    file_path = sys.argv[1]
    classes = extract_sv_classes(file_path)

    if not classes:
        print("No classes found.")
    else:
        print(f"Found {len(classes)} classes in {file_path}:")
        print_classes(classes)

def extract_class(file_path: str):
    
    classes = extract_sv_classes(file_path)

    if not classes:
        print("No classes found.")
    else:
        for i, cls in enumerate(classes, 1):
            return f"{cls['name']}"


if __name__ == "__main__":
    main()