#!/usr/bin/env python3
"""
统计Mermaid代码中:
1. 以u_gen_xx为源的边数量
2. 每个u_bfm_xx的work_mode

对于mermaid中的每个u_bfm_xx实例，统计其连接并计算work_mode
"""

import re
import sys


def count_edges_from_u_gen(mermaid_code: str) -> dict:
    """
    统计以u_gen_xx为源的边数量

    Args:
        mermaid_code: mermaid图表代码

    Returns:
        dict: 例化名 -> 边数
    """
    edge_counts = {}
    edges = parse_edges(mermaid_code)

    for edge in edges:
        source = edge['source']
        if source.startswith('u_gen_'):
            edge_counts[source] = edge_counts.get(source, 0) + 1

    return edge_counts


def validate_mermaid_syntax(mermaid_code: str) -> tuple:
    """
    验证Mermaid代码格式是否正确

    Returns:
        tuple: (是否有效, 错误信息列表)
    """
    errors = []
    lines = mermaid_code.split('\n')

    # 检查必要的头部 - 如果有代码块，检查mermaid声明；否则只检查flowchart/graph
    has_code_block = any('```mermaid' in line for line in lines[:3])
    if has_code_block and not any('flowchart' in line or 'graph' in line for line in lines[:5]):
        errors.append("缺少 flowchart 或 graph 声明")
    elif not any('flowchart' in line or 'graph' in line for line in lines[:5]):
        errors.append("缺少 flowchart 或 graph 声明")

    # 检查节点定义格式: node_id[display_text] 或 node_id(display_text) 等
    node_def_pattern = re.compile(r'^\s*(\S+)\s*(\[[\s\S]*\]|\([\s\S]*\)|\{[\s\S]*\}|<[\s\S]*\|>)')

    # 边的各种格式 (使用\s*$允许尾随空格)
    edge_formats = [
        r'^\s*\S+\s*-->\s*\S+\s*$',                    # A --> B
        r'^\s*\S+\s*---\s*\S+\s*$',                    # A --- B
        r'^\s*\S+\s*--o\s*\S+\s*$',                    # A --o B
        r'^\s*\S+\s*--x\s*\S+\s*$',                    # A --x B
        r'^\s*\S+\s*==>\s*\S+\s*$',                    # A ==> B
        r'^\s*\S+\s*==\s*\S+\s*$',                     # A == B
        r'^\s*\S+\s*--+\s*"[^"]*"\s*-->\s*\S+\s*$',   # A -- "label" --> B
        r'^\s*\S+\s*--+\s+\S+\s*-->\s*\S+\s*$',       # A -- label --> B (无引号)
    ]

    in_code_block = False
    for line_num, line in enumerate(lines, 1):
        line_stripped = line.strip()

        # 跟踪code block状态
        if '```mermaid' in line_stripped:
            in_code_block = True
            continue
        if line_stripped.startswith('```') and in_code_block:
            in_code_block = False
            continue

        # 跳过注释、空行、code block边界
        if not line_stripped or line_stripped.startswith('%%') or line_stripped.startswith('```'):
            continue

        # 只在code block内检查格式；如果没有code block，则检查所有非空非注释行
        if not in_code_block and '```mermaid' not in mermaid_code:
            pass  # 没有code block，检查所有行
        elif not in_code_block:
            continue  # 在code block外，跳过

        # 检查节点定义
        if '[' in line or '(' in line or '{' in line or '<' in line:
            # 这行可能是节点定义
            if not node_def_pattern.match(line_stripped):
                # 检查是否是无效的节点定义
                if re.search(r'^\s*\S+\s*\[.*\[', line_stripped):
                    errors.append(f"行 {line_num}: 节点定义格式错误，双重方括号 - {line_stripped[:50]}")

        # 检查边定义 - 只要包含箭头符号但不符合任何边的格式就报错
        if any(arrow in line_stripped for arrow in ['-->', '---', '--o', '--x', '==>', '==']):
            is_valid_edge = any(re.match(pattern, line_stripped) for pattern in edge_formats)
            if not is_valid_edge:
                errors.append(f"行 {line_num}: 边定义格式错误 - {line_stripped[:60]}")

    return len(errors) == 0, errors


def parse_edges(mermaid_code: str) -> list:
    """解析mermaid代码中的所有边"""
    edges = []

    for line in mermaid_code.split('\n'):
        line = line.strip()
        if not line or line.startswith('%%') or line.startswith('```'):
            continue

        # 匹配边的源节点、标签（port信息）、目标节点
        # 格式: NodeA --> NodeB
        # 或:   NodeA -- "label" --> NodeB
        # 也支持: NodeA-- "label" --> NodeB (源节点后无空格)
        match = re.match(r'^(\S+)\s*--+\s+(?:"([^"]+)"\s*)?-->\s*(\S+)', line)
        if not match:
            # 尝试简单箭头（无标签），支持无空格情况
            match = re.match(r'^(\S+)\s*-->\s*(\S+)', line)
            if match:
                edges.append({
                    'source': match.group(1),
                    'target': match.group(2),
                    'label': ''
                })
        else:
            edges.append({
                'source': match.group(1),
                'target': match.group(3),
                'label': (match.group(2) or '').strip()
            })

    return edges


def classify_port_for_source(label: str) -> str:
    """当bfm作为源时，根据label前半部分分类端口类型"""
    label_lower = label.lower()

    if 'outport_of_drv' in label_lower:
        return 'outport_of_drv'
    elif 'outport' in label_lower:
        return 'outport'
    elif 'inport' in label_lower:
        return 'inport'
    return 'other'


def classify_port_for_target(label: str) -> str:
    """当bfm作为目标时，根据label后半部分分类端口类型"""
    label_lower = label.lower()

    # label格式通常是 "src_port --> dst_port"
    if '-->' in label_lower:
        parts = label_lower.split('-->')
        dst_part = parts[-1].strip()  # 取后半部分
        if 'outport_of_drv' in dst_part:
            return 'outport_of_drv'
        elif 'outport' in dst_part:
            return 'outport'
        elif 'inport' in dst_part:
            return 'inport'

    # 简单标签的情况
    if 'outport_of_drv' in label_lower:
        return 'outport_of_drv'
    elif 'outport' in label_lower:
        return 'outport'
    elif 'inport' in label_lower:
        return 'inport'
    return 'other'


def get_bfm_instances(mermaid_code: str) -> set:
    """获取所有u_bfm_xx实例"""
    instances = set()
    for line in mermaid_code.split('\n'):
        match = re.match(r'^\s*(\S+)\s*\[', line.strip())
        if match:
            node_name = match.group(1)
            if node_name.startswith('u_bfm_'):
                instances.add(node_name)
    return instances


def calculate_work_mode(inport_count: int, outport_count: int, outport_of_drv_count: int) -> str:
    """根据端口数量计算work_mode"""
    if inport_count >= 1 and outport_count == 0 and outport_of_drv_count == 0:
        return "DRIVER"
    elif inport_count == 0 and outport_count >= 1 and outport_of_drv_count == 0:
        return "RECEIVER"
    elif inport_count >= 1 and outport_count >= 1 and outport_of_drv_count == 0:
        return "NORMAL"
    elif inport_count >= 1 and outport_count >= 1 and outport_of_drv_count >= 1:
        return "NORMAL_WITH_MONITOR"
    elif inport_count == 0 and outport_count == 0 and outport_of_drv_count >= 1:
        return "MONITOR"
    elif inport_count >= 1 and outport_count == 0 and outport_of_drv_count >= 1:
        return "DRIVER_WITH_MONITOR"
    else:
        return "UNKNOWN"


def calculate_bfm_work_mode(mermaid_code: str) -> dict:
    """计算每个u_bfm_xx的work_mode"""
    edges = parse_edges(mermaid_code)
    bfm_instances = get_bfm_instances(mermaid_code)

    results = {}

    for bfm in sorted(bfm_instances):
        inport_count = 0
        outport_count = 0
        outport_of_drv_count = 0

        for edge in edges:
            # 检查该bfm是否是边的端点
            if edge['source'] == bfm:
                # bfm作为源，目标不是DUT
                if edge['target'] != 'DUT':
                    port_type = classify_port_for_source(edge['label'])
                    if port_type == 'inport':
                        inport_count += 1
                    elif port_type == 'outport':
                        outport_count += 1
                    elif port_type == 'outport_of_drv':
                        outport_of_drv_count += 1

            elif edge['target'] == bfm:
                # bfm作为目标，源不是DUT
                if edge['source'] != 'DUT':
                    port_type = classify_port_for_target(edge['label'])
                    if port_type == 'inport':
                        inport_count += 1
                    elif port_type == 'outport':
                        outport_count += 1
                    elif port_type == 'outport_of_drv':
                        outport_of_drv_count += 1

        work_mode = calculate_work_mode(inport_count, outport_count, outport_of_drv_count)
        results[bfm] = {
            'inport': inport_count,
            'outport': outport_count,
            'outport_of_drv': outport_of_drv_count,
            'work_mode': work_mode
        }

    return results


def extract_mermaid_code(text: str) -> str:
    """
    从文本中提取mermaid代码块

    支持的格式:
    1. ```mermaid ... ``` 代码块
    2. 单行 flowchart LR ... 直接内联在文本中

    Args:
        text: 包含mermaid代码的文本

    Returns:
        提取出的mermaid代码
    """
    lines = text.split('\n')

    # 优先查找 ```mermaid 代码块
    in_block = False
    block_lines = []
    for line in lines:
        if '```mermaid' in line:
            in_block = True
            continue
        if in_block:
            if line.strip().startswith('```'):
                break
            block_lines.append(line)

    if block_lines:
        return '\n'.join(block_lines)

    # 如果没有代码块，尝试直接在文本中查找 flowchart 或 graph
    for i, line in enumerate(lines):
        stripped = line.strip()
        if stripped.startswith('flowchart') or stripped.startswith('graph'):
            # 从这行开始提取到结束
            return '\n'.join(lines[i:])

    # 如果都没有，返回原文（可能是裸mermaid代码）
    return text.strip()


def analyze_mermaid(text: str, verbose: bool = True) -> dict:
    """
    分析文本中的mermaid代码

    支持两种调用方式:
    1. 模块调用: analyze_mermaid("...mermaid code...")
    2. 从文本中自动提取mermaid代码块进行分析

    Args:
        text: 包含mermaid代码的文本（可以是纯代码，也可以是描述文本中嵌入的代码）
        verbose: 是否打印详细输出

    Returns:
        dict: 包含分析结果的字典
    """
    # 提取mermaid代码
    mermaid_code = extract_mermaid_code(text)

    if not mermaid_code.strip():
        if verbose:
            print("未找到Mermaid代码")
        return {'error': '未找到Mermaid代码'}

    # 0. 格式检查
    is_valid, errors = validate_mermaid_syntax(mermaid_code)
    if not is_valid:
        if verbose:
            print("\n❌ Mermaid格式错误:")
            for err in errors:
                print(f"  - {err}")
        return {'error': '格式错误', 'errors': errors}

    if verbose:
        print("✅ Mermaid格式检查通过")

    results = {}

    # 1. 统计u_gen_xx的边数
    gen_edge_counts = count_edges_from_u_gen(mermaid_code)
    if verbose:
        print("\n以u_gen_xx为源的边数统计:")
        print("-" * 60)
        for node, count in sorted(gen_edge_counts.items()):
            print(f"  {node}_cnt: {count}")
    results['u_gen_edges'] = gen_edge_counts

    # 2. 计算u_bfm_xx的work_mode
    bfm_results = calculate_bfm_work_mode(mermaid_code)
    if verbose:
        print("\n每个u_bfm_xx的work_mode:")
        print("-" * 60)
        for bfm, info in sorted(bfm_results.items()):
            print(f"{bfm}的work_mode: {info['work_mode']}")
    results['u_bfm_work_mode'] = bfm_results

    return results


def main():
    if len(sys.argv) > 1:
        file_path = sys.argv[1]
        with open(file_path, 'r', encoding='utf-8') as f:
            text = f.read()
        analyze_mermaid(text)
    else:
        # 从标准输入读取
        print("请输入包含Mermaid代码的文本（输入完成后按Ctrl+D结束）:")
        text = sys.stdin.read()
        analyze_mermaid(text)


if __name__ == '__main__':
    main()
