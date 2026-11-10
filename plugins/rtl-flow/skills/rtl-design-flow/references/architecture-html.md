# HTML架构图交付规范

每次编写或更新`doc/02_architecture.md`，同时交付`doc/02_architecture.html`，G2审核两者。HTML由`python $SKILL/scripts/gen_arch.py <ip_dir>`生成，可离线用浏览器直接打开，不依赖CDN、服务器或JavaScript。不要手改HTML。

## 图的数据与布局

在02的§1保留Mermaid总览，并添加且只添加一个`architecture-graph`代码块，内容为合法JSON：

```architecture-graph
{
  "title": "原始IP名 · 系统微架构",
  "summary": "从左侧请求进入接口模块，经核心处理后输出结果；控制路径单独标注。",
  "nodes": [
    {"id": "host", "name": "Host", "role": "外部请求方", "group": "系统外部", "layer": 0},
    {"id": "core", "name": "OriginalCore", "role": "处理请求并返回状态", "group": "原始IP名 / PCLK域", "layer": 1}
  ],
  "edges": [
    {"from": "host", "to": "core", "kind": "data", "label": "Request[31:0]，valid/ready"},
    {"from": "core", "to": "host", "kind": "control", "label": "Done，完成响应"}
  ]
}
```

- `id`仅作为连接引用，唯一；`name`是图中可见的原始模块/接口名，必须覆盖§2模块表中的每个模块。同一模块多实例可用不同id，在role中说明原始实例名。
- `role`用短句说明职责；`group`说明系统层次/所属子系统与时钟域，外部参与方明确标记“系统外部”。
- `layer`是0–20的布局列，从左向右；同列按nodes顺序从上到下。按输入→接口→处理→输出安排，控制模块与数据模块分行。通过列和节点顺序减少交叉，禁止把所有模块挤在一列。
- `edges`明确源/目的、原始接口名、关键位宽/握手。类型为`data/control/clock/reset`，分别蓝/棕/紫/红色。双向关系写两条有方向的边；CDC连接注明两侧时钟域和同步方式。共享时钟复位可用专门节点或group/role说明，避免大量重复线淹没主数据通路。
- 每个节点应关联清楚的关系；大系统用合理层次组织，摘要解释主要路径和反馈环。卡片保持短小，详细接口放在边标签，渲染后下方表格完整展示。
- HTML图使用箭头编号对应接口表，原始名称不缩写、不改名。生成后检查模块卡片可读性、连接方向、图文一致性，不能只交付JSON或HTML中的代码文本。

## 同步与检查

运行`gen_arch.py <ip_dir>`生成，再运行`check_docs.py <ip_dir> --stage arch`。从arch阶段开始，HTML缺失、过期、端点不存在、模块遗漏会报ERROR。02正文改变时也必须重新生成HTML；仅审核字段变化不使图过期。P2初稿、G2审核修改、需求变更以及RTL修复影响微架构时均适用。

G2汇报必须给出HTML文件路径、主要模块关系和图的阅读顺序，邀请用户在浏览器查看后审核。
