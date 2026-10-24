# rtl-flow：RTL 设计与文档规范插件

把「不规范的需求/规格」变成「RTL + 一整套标准化文档」的 Claude Code 插件。文档体系参考 OpenTitan。

## 包含内容

```
plugins/rtl-flow/
├── commands/                    # 斜杠命令
│   ├── ip-new.md                #   /rtl-flow:ip-new   新建 IP（从需求开始；--auto 跳过审核停顿）
│   ├── ip-check.md              #   /rtl-flow:ip-check 生成 + 检查文档
│   └── ip-iter.md               #   /rtl-flow:ip-iter  记录一次验证/修改迭代
└── skills/rtl-design-flow/
    ├── SKILL.md                 # 流程 P0–P6、闸门 G0–G3、人工审核点 G0/G1/G2（AI 自动加载）
    ├── references/              # 文档规范、术语表、yaml schema、RTL 编码规范
    ├── templates/               # README、CHANGELOG、data/ip.yaml、doc/00–10 模板
    ├── scripts/gen_docs.py      # yaml → 接口文档 / 寄存器文档 / C 头文件
    ├── scripts/check_style.py   # 编码规范检查（华为 Verilog 规范，HW-xx 规则）
    ├── scripts/run_lint.py      # 风格检查 + lint → reports/lint.log（Verilator / Verible）
    ├── scripts/check_docs.py    # 分阶段检查：结构、ID 追溯、审核记录、RTL 端口/模块一致性、lint 报告、签核
    └── examples/demo_timer/     # 完整标杆示例：真实运行的 RTL、验证、综合与全套文档
```

依赖：Python 3.8+、PyYAML；lint 需要 Verilator 或 Verible。

## 人工审核点

流程在 G0（需求）、G1（规格）、G2（架构）停下来等待审核，通过后才继续；G3 之后只汇报不停顿。审核结果写在 00 / 01 / 02 的 front matter（`reviewer`、`approved: <version>@<日期>`），文档审核后再改版本会要求重新审核，签核时三处都必须是人工通过。详见 `SKILL.md` §3。

## 用户如何使用

### 方式 1：插件市场（推荐，可统一升级）

本仓库就是一个插件市场：<https://github.com/rtl-workflow/rtl_doc_agent>。

1. 在 Claude Code 里添加市场并安装插件：
   ```
   /plugin marketplace add rtl-workflow/rtl_doc_agent
   /plugin install rtl-flow@rtl-flow
   ```
   也可以写完整地址：`/plugin marketplace add https://github.com/rtl-workflow/rtl_doc_agent.git`。
2. 安装后重启 Claude Code（或执行 `/reload-plugins`），输入 `/rtl-flow:` 能看到 `ip-new`、`ip-check`、`ip-iter` 即安装成功。
3. 升级：维护者修改后提升 `plugins/rtl-flow/.claude-plugin/plugin.json` 的 `version` 并推送，用户执行 `/plugin marketplace update rtl-flow`。

本地调试也可以直接添加目录：`/plugin marketplace add C:/path/to/rtl_doc_agent`。

### 方式 2：项目仓库内自动启用（团队零配置）

在每个 RTL 项目仓库提交 `.claude/settings.json`，成员信任该目录后会被提示安装：

```json
{
  "extraKnownMarketplaces": {
    "rtl-flow": {
      "source": { "source": "github", "repo": "rtl-workflow/rtl_doc_agent" }
    }
  },
  "enabledPlugins": {
    "rtl-flow@rtl-flow": true
  }
}
```

### 方式 3：直接拷贝 skill（离线 / 不用插件）

把 `plugins/rtl-flow/skills/rtl-design-flow/` 复制到：
- 个人全局：`~/.claude/skills/rtl-design-flow/`
- 或某个项目：`<repo>/.claude/skills/rtl-design-flow/`（随仓库提交，所有人可用）

斜杠命令同理复制到 `.claude/commands/`。

### 非 Claude 工具

规则全部是 Markdown + Python 脚本，与工具无关。其他 AI 编码工具可在其规则文件（如 `AGENTS.md`）中引用 `SKILL.md` 与 `references/`；脚本可直接接入 CI。

## 日常使用示例

```
/rtl-flow:ip-new uart_lite ./inputs/uart需求.docx ./inputs/接口说明.xlsx
/rtl-flow:ip-check uart_lite rtl
/rtl-flow:ip-iter uart_lite test_parity_err 失败：奇校验时 rx_err 未拉高
```

也可以不用命令，直接说「根据这份需求生成 RTL 和文档」，skill 会自动加载。

## 接入 CI

```yaml
# .github/workflows/doc-check.yml 片段
- run: pip install pyyaml
- run: python rtl-flow/plugins/rtl-flow/skills/rtl-design-flow/scripts/run_lint.py hw/ip/uart_lite   # 需安装 verilator
- run: python rtl-flow/plugins/rtl-flow/skills/rtl-design-flow/scripts/gen_docs.py hw/ip/uart_lite --check
- run: python rtl-flow/plugins/rtl-flow/skills/rtl-design-flow/scripts/check_docs.py hw/ip/uart_lite --stage rtl
```

## 定制与维护

| 想改什么 | 改哪里 |
|---|---|
| 流程、闸门 | `SKILL.md` |
| 文档章节 | `templates/doc/*.md`（二级标题即必填章节，检查脚本自动跟随） |
| 术语、命名后缀、访问类型 | `references/glossary.md`（访问类型还需同步 `gen_docs.py` 中的 `SWACCESS/HWACCESS`） |
| RTL 编码规范 | `references/rtl-coding-style.md`（华为 Verilog 规范）；自动检查规则在 `scripts/check_style.py` 的 `PATTERNS` |
| 标杆示例 | `examples/` |

规则本身的修改也应走评审（MR/PR），并在 `plugin.json` 中提升版本号。
