# rtl-flow：RTL 设计与文档规范插件

把「不规范的需求/规格」变成「RTL + 一整套标准化文档」的 Claude Code 插件。文档体系参考 OpenTitan。

## 安装入口（用户与安装 agent 必读）

在 Claude Code 或 OpenCode 中，都只需要发送同一句话：

```text
请按照 https://github.com/rtl-workflow/rtl_doc_agent 的 README 中的提示，为我安装这个插件。
```

**以下步骤由安装 agent 执行，用户无需选择安装指南或补充安装命令：**

1. 识别承载当前对话的工具是 Claude Code 还是 OpenCode。以当前会话环境为准，不根据机器上是否装有某个 CLI 来猜测；确实无法识别时才询问用户。
2. 根据下表读取对应的完整安装指南，再实际执行安装。通过网页读取 README 时，可直接读取表内的原始文档链接；从本地仓库读取时使用相对路径。不要只复述步骤或停在“建议安装”。
3. 检查现有安装，按对应指南复用或更新；首次安装默认面向当前用户，不改项目共享配置。不要因两个工具都已安装就同时给两个工具安装。
4. 按指南核验安装记录和加载结果。只能完成重启前检查时，报告已完成部分和用户需要执行的重启 / 重载操作，不提前宣称全部可用。遇到错误先处理或报告，不自行换成另一种安装方式。
5. 插件安装完成后再说明 EDA 配置入口；不要在安装阶段索取服务器密码或启动交互式配置向导。

| 当前工具 | 安装指南 | 完成标准 |
|---|---|---|
| Claude Code | [市场安装指南](.claude-plugin/INSTALL.md) · [原始文档](https://raw.githubusercontent.com/rtl-workflow/rtl_doc_agent/refs/heads/main/.claude-plugin/INSTALL.md) | 添加 `rtl-flow` 市场，安装并启用 `rtl-flow@rtl-flow`，核验已安装列表与加载结果 |
| OpenCode | [安装指南](.opencode/INSTALL.md) · [原始文档](https://raw.githubusercontent.com/rtl-workflow/rtl_doc_agent/refs/heads/main/.opencode/INSTALL.md) | 克隆完整仓库，运行 `install-opencode` 注册加载器，重启后核验命令、agent 和 skill |

**Claude Code 默认走插件市场。** AI 在 shell 中执行 `claude plugin marketplace add ...` 和 `claude plugin install ...`；用户在聊天输入框使用 `/plugin ...`。仅执行 `git clone`、复制 skill 或使用 `--plugin-dir` 不算完成市场安装。只有用户明确要求源码开发、离线复制或临时调试时，才采用相应方式。不要把 OpenCode 的克隆安装步骤用于 Claude Code。

从 0.4.0 起采用**多 agent 工作流**：主会话担任编排者，由 `flow.py` 状态机决定每一步；5 个角色 agent 分工完成；检查脚本判定能否进入下一阶段；hook 强制执行角色权限。验证 agent 看不到 RTL，与设计相互独立。

## 包含内容

### 微架构HTML架构图

每次生成或更新`doc/02_architecture.md`，同时生成`doc/02_architecture.html`，G2一起审核。HTML为可离线浏览的单文件，图中展示模块原名、职责、层次/时钟域，以及带方向的数据/控制关系；接口表解释箭头编号、位宽与握手。图的数据保存在02的`architecture-graph` JSON块，运行`gen_arch.py <ip_dir>`生成；`check_docs --stage arch`检查缺失、过期、模块遗漏和无效连接。初稿、审核修改、需求变更及RTL修复影响架构时均需同步。

### 验证人工审核 G3

P4生成测试点、测试用例与testbench激励并完成桩自检后，流程停在G3，用户审核`doc/07_dv_plan.md`和`dv/`下激励、参考模型、自检查，通过后才进入正式回归。`--auto`仅跳过G0–G2，不能跳过G3。审核意见派回tb-engineer修改后再次审核；验证内容摘要用于检测修改，测试计划或激励改变后须重新审核。已有项目继续回归/完成流程时也会补审G3。

### UVM 验证平台

新项目默认采用标准 SystemVerilog/UVM 结构：`dv/top/` 连接 interface 与 DUT，`dv/env/` 包含 common、trans、gen、bfm、rm、scb、funcov 和按需 RAL，`dv/tests/` 保存测试类。`flow.py init` 提供配置、目录、filelist 和公共测试基类；P4 验证 agent 根据规格补齐具体平台与场景，初始化骨架本身不代表可编译或功能通过。

`dv/uvm.yaml` 指定顶层、UVM 版本、filelist 和测试类映射；默认 VCS `-sverilog -ntb_opts uvm-1.2`。`dv/sim/scripts/tb_list.f` 的路径统一相对 dv/，只包含验证依赖；真实 RTL 由 runner 从 SSOT 加入，桩检查改用 SSOT 端口桩。07 的用例 ID 通过 `+TEST` 传递，同名类或 `test_map` 对应的类通过 `+UVM_TESTNAME` 选择，随机种子同时传给 VCS 和报告接口。

用例继承 `rtlflow_test_base`，由其管理 objection、watchdog 和开始 / 完成 / TEST 输出，派生类实现激励、收尾检查与功能覆盖。正式回归会检查 UVM_ERROR / UVM_FATAL，不能仅凭进程退出码判通过。桩自检允许正常结束后的功能比对失败，但不允许 UVM_FATAL、超时或缺少完成标记。已有无 manifest 的 `dv/tb/*.v` 项目保持兼容，G3 审核和验证独立性不变。

生成规则见 [平台参考](plugins/rtl-flow/skills/rtl-design-flow/references/uvm-platform-generation.md)、[BFM参考](plugins/rtl-flow/skills/rtl-design-flow/references/uvm-bfm-generation.md)、[用例参考](plugins/rtl-flow/skills/rtl-design-flow/references/uvm-testcase-generation.md)。本地 Python 测试可用 `python -m unittest discover -s plugins/rtl-flow/skills/rtl-design-flow/scripts/tests`；这些测试不替代已配置 VCS 环境上的编译 / 仿真。

### 原始名称保留

需求、规格、接口表及已有设计中的名称原样贯穿文档、SSOT、RTL、验证与软件接口；不为统一风格增删前后缀、改变大小写、缩写或替换同义名。IP名、模块与文件名、端口、时钟复位、参数、寄存器及字段等均适用。未命名对象按项目已有风格命名；冲突或非法标识符先向用户澄清并记录确认后的映射。

命名风格不再作为 `flow.py init`、`gen_docs.py` 或 `check_style.py` 的拒绝条件。`source_naming` 是可选来源记录，不是保留原名的前置条件。语法、模块数量、接口一致性、复位极性等检查继续执行。

**生成接口变化**：C头文件中的IP和枚举名称不再自动转为大写，组合宏保留原名大小写（如 `OriginalIP_Control_Enable_VALUE_On`）。已有项目重新生成头文件后，软件调用方需要使用对应原名宏。示例历史日志中的改名记录只描述当时版本，不作为新设计的命名要求。

```
plugins/rtl-flow/
├── agents/                      # 角色 agent（由编排者派发，不单独调用）
│   ├── spec-author.md           #   需求 00、规格 01、yaml、编程指南 06、需求变更
│   ├── architect.md             #   微架构 02、设计决策 09
│   ├── rtl-engineer.md          #   RTL、05、lint，按定位报告修复
│   ├── tb-engineer.md           #   验证计划 07、黑盒 testbench（看不到 RTL）
│   └── debugger.md              #   回归失败定位与根因分类（rtl / tb / both / spec / tool）
├── hooks/                       # hooks.json + flow_hook.py：角色路径权限、禁改生成文件与审核字段、
│                                #   RTL 写入后自动风格检查、agent 交接文件校验
├── commands/                    # 斜杠命令
│   ├── ip-new.md                #   /rtl-flow:ip-new    新建 IP 并运行完整流程（--auto 跳过审核停顿）
│   ├── ip-run.md                #   /rtl-flow:ip-run    中断后继续流程
│   ├── ip-status.md             #   /rtl-flow:ip-status 查看流程状态
│   ├── ip-iter.md               #   /rtl-flow:ip-iter   验证失败或需求变更
│   └── ip-check.md              #   /rtl-flow:ip-check  生成 + 检查文档
└── skills/rtl-design-flow/
    ├── SKILL.md                 # 原则、角色、流程、编排者协议、审核点（AI 自动加载）
    ├── references/              # 文档规范、术语表、yaml schema、RTL 编码规范与 testbench 约定
    ├── templates/               # README、CHANGELOG、data/ip.yaml、doc/00–10 模板
    ├── scripts/flow.py          # 编排状态机：init / next / answers / review / iter / resume / status / guard
    ├── scripts/gen_docs.py      # yaml → 接口文档 / 寄存器文档 / C 头文件
    ├── scripts/check_style.py   # 编码规范检查（项目 Verilog 规范，RTL-xx 规则）
    ├── scripts/run_lint.py      # 风格检查 + lint → reports/lint.log（SpyGlass lint_rtl，或 --tool vcs）
    ├── scripts/run_regress.py   # 通用回归（VCS）→ reports/regress.json；--stub 用端口桩做 TB 自检
    ├── scripts/remote_exec.py   # 远程 EDA 服务器执行（FTP + watcher）；RTLFLOW_EXEC=remote 时 lint / 回归在服务器上运行
    ├── scripts/check_docs.py    # 分阶段检查：结构、ID 追溯、审核记录、RTL 端口/模块一致性、lint 报告、签核
    └── examples/demo_timer/     # 完整标杆示例：真实运行的 RTL、验证、综合与全套文档
```

依赖：Python 3.8+，且 `python` 命令可用（hook 和流程命令依赖它）；PyYAML 由配置向导自动安装。lint（SpyGlass）和回归（VCS）在远程 EDA 服务器上运行，本机不需要安装 EDA 工具。

服务器需要满足：可以用 FTP 登录（账号的 FTP 根目录为家目录）；账号有 VNC 或其他可以打开终端的方式；已安装 `python3.11` 和 `tmux`；账号登录后的默认环境能直接使用 `vcs` 和 `sg_shell`，并持有相应的 license。

## 首次配置（每台机器一次）

Claude Code 和 OpenCode 共用同一份配置，配好后两者都可以直接使用。

1. 确认本机能访问服务器（需要 VPN 时先连接）。
2. 在**自己的终端**运行（不要在 AI 对话中输入密码）：
   ```
   python plugins/rtl-flow/skills/rtl-design-flow/scripts/rtlflow.py setup
   ```
   只需要输入**服务器地址、自己的账号和密码**。通过插件市场安装时不用找路径：第一次使用工作流时，AI 会给出完整命令，也可以运行 `/rtl-flow:setup`。
3. 按提示打开服务器的 VNC 桌面，粘贴一条命令启动 watcher，向导检测到上线后自动完成验证。

配置保存在 `~/.rtl-flow/`（插件升级和重装都不受影响），密码保存在系统凭据库。之后 lint 和仿真自动在服务器上运行，长任务不占用对话；网络中断或关闭会话后，再次运行流程会接回同一个任务。

环境出问题时运行 `python .../rtlflow.py doctor` 检查。使用时需要保持与服务器的网络连接。

多人共用服务器时，每个账号各运行一次 setup，各有一份 watcher 和签名密钥，工作目录互不影响，但会共享算力和 license。

## 工作流

```
P0  spec-author 写 00 → 编排者合并提问 Q → G0 人工审核
P1  spec-author 写 yaml / 01 / 06          → G1 人工审核
P2  architect 写 02 / 09                   → G2 人工审核
P3‖P4  rtl-engineer（RTL、05、lint） ‖ tb-engineer（07、黑盒 TB，桩检查）
回归  flow.py 运行 run_regress.py → 通过则完成；失败 → debugger 定位 → 对应 agent 修复 → 再回归
```

- 每一步都由 `flow.py next` 给出（dispatch / ask_user / review / escalate / wait / setup_required / finish），编排者照做，不自行判断。
- 产出不通过检查时退回对应 agent，最多重试 3 次；修复最多 3 轮。超出时上报用户。
- 规格不明确（debugger 判定为 spec）、工具问题、agent 报告 blocked 时，都上报用户决定。

## 人工审核点

流程在 G0（需求）、G1（规格）、G2（架构）、G3（测试点、测试用例及激励）停下来等待审核，通过后才继续。审核结果由编排者在用户明确通过后用 `flow.py review` 写入 00 / 01 / 02 / 07 的 front matter（`reviewer`、`approved: <version>@<日期>`；G3另有`approved_dv_digest`），agent 无法修改审核字段。已审核文档提升版本或G3验证内容改变后自动重开审核。签核时四处都必须是人工通过。详见 `SKILL.md` §5。

## 权限隔离（hook）

| 角色 | 可写 | 不可读 |
|---|---|---|
| 编排者（主会话） | `.flow/answers` `reviews` `inputs`、`doc/08` | — |
| spec-author | README、CHANGELOG、data/、doc/00 01 06 08 09 10 | — |
| architect | doc/02 08 09 | — |
| rtl-engineer | rtl/、syn/、doc/02 05 08 09 10、`data/<ip>.yaml` 的 `rtl_files` 字段 | — |
| tb-engineer | dv/、doc/07 08 | rtl/、syn/、reports/、doc/05、真实回归日志、其他 agent 的交接文件 |
| debugger | doc/08、.flow/debug/、dv/build/ | — |

所有角色都不能手改生成文件（03 / 04 / C 头文件）和 `raw/` 中已有的文件；子 agent 不能运行 flow.py 的管理命令。只对含 `.flow/state.json` 的 IP 目录生效；用户需要手工修改时可执行 `flow.py guard <ip_dir> off`。

## 用户如何使用

### 方式 1：插件市场（推荐，可统一升级）

本仓库就是一个插件市场：<https://github.com/rtl-workflow/rtl_doc_agent>。

**让 Claude Code 安装：** 使用本文开头的统一提示词“请按照本仓库的 README 中的提示，为我安装这个插件”。Claude Code 应自动选择市场安装指南。

安装 agent 应读取 [完整指南](.claude-plugin/INSTALL.md)，检查现有安装后，通过 shell 逐条执行（前一步成功后再继续）：

```sh
claude plugin marketplace add https://github.com/rtl-workflow/rtl_doc_agent.git
claude plugin install rtl-flow@rtl-flow --scope user
claude plugin list --json
```

已存在的正确市场无需重复添加；已安装插件按指南更新。安装范围默认为当前用户，不修改项目共享配置。不能只添加市场而跳过插件安装，也不能以克隆目录存在作为成功依据。

**用户手动安装：**

1. 在 Claude Code 的聊天输入框中逐条输入：
   ```
   /plugin marketplace add rtl-workflow/rtl_doc_agent
   /plugin install rtl-flow@rtl-flow
   ```
   也可以写完整地址：`/plugin marketplace add https://github.com/rtl-workflow/rtl_doc_agent.git`。
2. 若打开插件详情面板，选择安装到当前用户并完成安装；在 `/plugin` 的 Installed 页确认 `rtl-flow@rtl-flow` 已安装并启用。
3. 根据安装结果提示执行 `/reload-plugins` 或重启 Claude Code。输入 `/rtl-flow:` 检查命令，`/agents` 中检查 `rtl-flow:spec-author` 等 5 个角色；命令或角色未加载时按完整指南排查。
4. 升级：维护者提升插件版本并推送后，在终端依次执行 `claude plugin marketplace update rtl-flow` 和 `claude plugin update rtl-flow@rtl-flow --scope user`，随后重新加载并验收。只刷新市场目录不能作为已安装插件更新完成的依据。

仅在用户明确要求本地源码调试时，可以添加本地市场：`/plugin marketplace add C:/path/to/rtl_doc_agent`，之后仍须安装 `rtl-flow@rtl-flow`。

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

斜杠命令同理复制到 `.claude/commands/`，agent 复制到 `.claude/agents/`。hooks 需要手工合并到 `.claude/settings.json`（把 `${CLAUDE_PLUGIN_ROOT}` 换成实际路径），否则角色权限隔离不生效。

### 方式 4：OpenCode

与 Claude Code 功能相同：同样的 5 个角色 agent、斜杠命令、skill、状态机和权限隔离。

**让 OpenCode 安装：** 使用本文开头的统一提示词“请按照本仓库的 README 中的提示，为我安装这个插件”。OpenCode 应自动选择自己的安装指南。

只给仓库地址时，也应先读取 [OpenCode 安装指南](.opencode/INSTALL.md)，再执行其中的安装步骤。指南包含 Windows PowerShell、macOS/Linux、重复安装、验收和故障排查。

当前适配器面向 **OpenCode 1.x**；2.x 的插件接口尚未适配。安装会克隆完整仓库并运行 `rtlflow.py install-opencode`，生成全局加载器；无需 npm 安装、软链接或手改 `opencode.json`。插件安装不需要 EDA 账号；需要运行 lint / 仿真时，再由用户在自己的终端执行 [首次配置](#首次配置每台机器一次)。

安装后重启 OpenCode，确认能看到 `/rtl-flow:ip-new`、`/rtl-flow:ip-run` 和 `rtl-design-flow` skill。更新时在安装目录执行 `git pull --ff-only`，重新运行 `install-opencode`，再重启 OpenCode。

`plugins/rtl-flow/opencode/rtl-flow.js` 负责翻译工具调用：agent、命令和 skill 都从同一批 Markdown 动态注册，权限判断调用同一个 `hooks/flow_hook.py`，修改规则时只改一处。

### 其他工具

规则全部是 Markdown + Python 脚本。其他 AI 编码工具可在其规则文件（如 `AGENTS.md`）中引用 `SKILL.md` 与 `references/`，但没有权限隔离；脚本可直接接入 CI。

## 日常使用示例

```
/rtl-flow:ip-new uart_lite ./inputs/uart需求.docx ./inputs/接口说明.xlsx
/rtl-flow:ip-status uart_lite
/rtl-flow:ip-run uart_lite                      # 中断后继续
/rtl-flow:ip-iter uart_lite test_parity_err 失败：奇校验时 rx_err 未拉高
/rtl-flow:ip-iter uart_lite 需求变更：增加 9 bit 数据模式
/rtl-flow:ip-check uart_lite rtl
```

也可以不用命令，直接说「根据这份需求生成 RTL 和文档」，skill 会自动加载并按编排者协议运行。

## 接入 CI

```yaml
# .github/workflows/doc-check.yml 片段
- run: pip install pyyaml
- run: python rtl-flow/plugins/rtl-flow/skills/rtl-design-flow/scripts/run_lint.py hw/ip/uart_lite   # 需要 SpyGlass（或 RTLFLOW_EXEC=remote）
- run: python rtl-flow/plugins/rtl-flow/skills/rtl-design-flow/scripts/gen_docs.py hw/ip/uart_lite --check
- run: python rtl-flow/plugins/rtl-flow/skills/rtl-design-flow/scripts/check_docs.py hw/ip/uart_lite --stage rtl
- run: python rtl-flow/plugins/rtl-flow/skills/rtl-design-flow/scripts/run_regress.py hw/ip/uart_lite      # 需要 VCS（或 RTLFLOW_EXEC=remote）
```

## 定制与维护

编码规则使用中性的 `RTL-xx` 编号。0.7.5 统一调整了文档、模板、检查器诊断和示例注释中的编号，技术规则与检查条件保持不变；依赖旧诊断编号的外部脚本需同步更新。

0.9.0 新增 `references/rtl-implementation-guide.md`：把外部 Verilog 编码规范与逻辑军规（J1–J8）中对设计质量有用的内容整理为 `DG-xx` 参考（分解、编码细则、FSM、RAM、DataPath、低功耗、自检清单、与外规差异），供 architect / rtl-engineer 阅读，debugger 用于分析。它不参与自动检查，冲突时以 `RTL-xx`、SSOT 和原始命名为准；`05_rtl_structure` §6 增加了 DG 偏离表。同版本起 `RTL-43` / `RTL-44` 改为自动检查：时序块敏感列表中的时钟 / 异步复位必须直接是本模块 `input` 端口（模块内生成、取反、门控、分频、位选均报 error）；独立的时钟 / 复位产生模块在 `data/style_waivers.txt` 写 `RTL-43 <模块名> <原因>` 按模块豁免。已有项目若存在内部生成时钟，升级后 lint 会失败，需修改或补豁免。

| 想改什么 | 改哪里 |
|---|---|
| 流程、阶段转移、重试上限 | `scripts/flow.py`（`step` / `collect`、`MAX_ATTEMPTS`、`MAX_ROUNDS`、`TASKS` 中各任务的提示）；`SKILL.md` §3–§4 同步说明 |
| 角色职责与规则 | `agents/*.md` |
| 角色读写权限 | `hooks/flow_hook.py` 中的 `WRITE`、`TB_HIDDEN`、`TB_BASH_DENY` |
| 文档章节 | `templates/doc/*.md`（二级标题即必填章节，检查脚本自动跟随） |
| 术语、命名后缀、访问类型 | `references/glossary.md`（访问类型还需同步 `gen_docs.py` 中的 `SWACCESS/HWACCESS`） |
| RTL 编码规范 | `references/rtl-coding-style.md`（项目 Verilog 规范）；自动检查规则在 `scripts/check_style.py` 的 `PATTERNS` |
| RTL 实现参考 | `references/rtl-implementation-guide.md`（`DG-xx` 设计质量条目，不被脚本检查）；由 `agents/architect.md`、`agents/rtl-engineer.md` 与 `scripts/flow.py` 的 `TASKS` 提示引用 |
| 标杆示例 | `examples/` |

规则本身的修改也应走评审（MR/PR），并在 `plugin.json` 中提升版本号。

## VCS FSDB 与远端 Verdi（0.7.4）

正式 RTL 回归现在默认在同一次 VCS 仿真中生成每用例/种子的 FSDB 和 KDB，保留远端工作目录。`--no-fsdb` 可关闭，桩检查默认关闭。回归报告记录波形绝对路径和大小；大文件保留远端，按需下载。

使用 `/rtl-flow:ip-wave <ip_dir>`，或 `python <skill>/scripts/open_verdi.py <ip_dir> --test <tc_name> --seed 1 --display :1.0`，直接打开已有波形，不重复仿真。启动记录写入 `reports/verdi.json`；真实窗口确认成功才标记 `opened`。远端需 VCS、Verdi/FSDB dumper 和可访问的 VNC/X DISPLAY。
