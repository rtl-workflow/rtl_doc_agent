# 在 DeepSeek Harness（DSH）中接入 rtl-flow

本指南供 DSH 用户和收到“帮我安装 rtl-flow”的安装 agent 使用。采用 README 的“其他工具”方式，在**当前工作区**接入完整仓库、Python 脚本和工作区规则；目前没有 DSH 原生插件适配器。

## 1. 确认环境与范围

以承载当前对话的环境识别 DSH，不根据机器上是否存在 `claude` / `opencode` 命令猜测。通过工作目录工具或 `pwd` / `Get-Location` 确定当前工作区，不把 DSH 应用安装目录当作工作区。

本方式支持：读取 skill、参考资料、模板和五个角色定义，运行 `flow.py` 状态机及文档检查脚本，并通过当前 DSH 可用的子 agent 工具派发任务。以下能力**不包含在本次接入中**：

- DSH 插件管理器中的原生插件注册；本仓库不是可直接安装的 DSH npm bundle。
- `/rtl-flow:*` 斜杠命令、`rtl-flow:<角色>` agent 类型或原生 skill 的自动注册。
- hook 强制角色权限、验证 agent 的文件访问隔离和写入后自动检查。角色提示及全新上下文只能约束协作，不能替代权限隔离。

不要执行 Claude Code 市场命令、`install-opencode`，也不要把本仓库 URL 交给 DSH 插件管理器冒充原生插件。安装结果必须保留上述范围说明。

## 2. 准备完整仓库

默认在当前工作区使用 `rtl_doc_agent/` 保存源码；用户已有固定安装位置时可复用。保留整个仓库，不要只复制 `SKILL.md`，它依赖同目录参考资料、模板、脚本以及插件目录下的 agents 和 commands。

首次安装且目标目录不存在时：

```sh
git clone https://github.com/rtl-workflow/rtl_doc_agent.git rtl_doc_agent
```

每一步成功后再继续。目录已存在时，先检查来源、分支及本地修改：

```sh
git -C rtl_doc_agent remote -v
git -C rtl_doc_agent status --short --branch
```

仅当它确属本仓库、工作区干净且处于跟踪 `origin/main` 的 `main` 分支时，才可以 `git -C rtl_doc_agent pull --ff-only`。遇到其他内容或本地修改时保留现状，说明冲突，不清空、覆盖或 reset。

**没有 Git：** 可以下载 [main 分支完整 ZIP](https://github.com/rtl-workflow/rtl_doc_agent/archive/refs/heads/main.zip)，解压至新的空目录。ZIP 顶层目录通常是 `rtl_doc_agent-main/`；后文所有源码路径要替换为这个实际目录。记录来源 URL、下载时间、ZIP 的 SHA-256 和插件版本；它是源码快照，不是 Git 克隆，不能声称可以 `git pull`。不要为了本接入强制安装系统级 Git。

例如 Windows PowerShell（先确认 ZIP 和解压目标不存在；每条成功后再运行下一条）：

```powershell
Invoke-WebRequest 'https://github.com/rtl-workflow/rtl_doc_agent/archive/refs/heads/main.zip' -OutFile 'rtl_doc_agent-main.zip'
Get-FileHash 'rtl_doc_agent-main.zip' -Algorithm SHA256
Expand-Archive 'rtl_doc_agent-main.zip' -DestinationPath '.'
```

## 3. 准备 Python

需要 Python 3.8+ 和 PyYAML。先实际运行解释器确认可用；Windows 的 `WindowsApps/python.exe` 可能只是商店别名，路径存在不代表 Python 可运行。

DSH 提供 `load_workspace_dependencies` 工具时，可以用它返回的 Python **绝对路径**；不要硬编码安装 agent 所在机器的用户名或猜测 DSH 内置运行时路径。没有该工具时，使用已验证可用的系统 Python。

推荐创建工作区独立虚拟环境，不修改 DSH 内置 Python 的包。以下命令在工作区根目录执行。`.rtl-flow-venv` 已存在时，先核验其中的 Python 和 PyYAML；不要覆盖其他用途的环境。虚拟环境、下载文件和本地安装路径不应提交到项目共享仓库，可使用项目现有忽略规则或本地 Git exclude。

### Windows PowerShell

将第一行替换为检查得到的真实解释器路径；如果使用源码 ZIP，同时替换 `$rtlFlowRepo` 的目录名。

```powershell
$rtlFlowBasePython = 'C:\path\to\python.exe'
& $rtlFlowBasePython --version
if ($LASTEXITCODE -ne 0) { throw 'Python 不可用' }
& $rtlFlowBasePython -m venv .rtl-flow-venv
if ($LASTEXITCODE -ne 0) { throw '创建虚拟环境失败' }
$rtlFlowPython = (Resolve-Path '.rtl-flow-venv/Scripts/python.exe').Path
& $rtlFlowPython -m pip install PyYAML
if ($LASTEXITCODE -ne 0) { throw '安装 PyYAML 失败' }
$env:PATH = "$(Split-Path $rtlFlowPython);$env:PATH"
$env:PYTHONIOENCODING = 'utf-8'
$rtlFlowRepo = (Resolve-Path 'rtl_doc_agent').Path
$rtlFlowScripts = Join-Path $rtlFlowRepo 'plugins/rtl-flow/skills/rtl-design-flow/scripts'
& $rtlFlowPython -c "import sys, yaml; print(sys.executable); print(yaml.__version__)"
if ($LASTEXITCODE -ne 0) { throw 'Python 依赖检查失败' }
& $rtlFlowPython (Join-Path $rtlFlowScripts 'flow.py') --help
if ($LASTEXITCODE -ne 0) { throw '流程脚本不可用' }
```

### macOS / Linux / WSL（Bash）

同样替换第一行解释器路径，源码 ZIP 用户替换仓库目录名：

```bash
rtlFlowBasePython='/absolute/path/to/python3'
"$rtlFlowBasePython" --version &&
"$rtlFlowBasePython" -m venv .rtl-flow-venv &&
rtlFlowPython="$PWD/.rtl-flow-venv/bin/python" &&
"$rtlFlowPython" -m pip install PyYAML &&
export PATH="$PWD/.rtl-flow-venv/bin:$PATH" &&
export PYTHONIOENCODING=utf-8 &&
rtlFlowRepo="$PWD/rtl_doc_agent" &&
rtlFlowScripts="$rtlFlowRepo/plugins/rtl-flow/skills/rtl-design-flow/scripts" &&
"$rtlFlowPython" -c 'import sys, yaml; print(sys.executable); print(yaml.__version__)' &&
"$rtlFlowPython" "$rtlFlowScripts/flow.py" --help
```

**DSH 的每次 shell 调用可能都是新进程。** 后续每次运行脚本时，都要重新设置实际的 Python / 脚本路径、UTF-8 编码和子进程 PATH，或使用经过验证的本地封装脚本。不能假设前一次设置的 shell 变量或虚拟环境激活状态会保留。上游任务提示可能包含 `python`，因此只用绝对路径启动最外层脚本还不够，子进程也应能找到同一个 Python。

虚拟环境创建或 pip 失败时，先处理实际错误；不要跳过依赖检查。无需为安装启动 EDA `setup` 或 `doctor`。

## 4. 合并工作区规则

先读取工作区现有 `AGENTS.md`，保留所有原有内容，合并一个独立的 RTL Flow 小节；文件不存在时才创建。重复安装时更新同一小节，不反复追加。不把下面规则写到 DSH 应用安装目录。

下面是模板。安装 agent 必须把 `<仓库绝对路径>`、`<Python绝对路径>` 替换为本机实际路径，并记录每次 shell 调用需要设置的 Python PATH。用户希望在团队共享仓库中使用时，应改为团队可解析的路径或单独的本地规则入口，避免提交个人绝对路径。

```markdown
## RTL Flow（DSH 工作区接入）

仅在 RTL/IP 设计、设计文档、验证或继续 RTL Flow 项目时使用本节。
先完整读取 <仓库绝对路径>/plugins/rtl-flow/skills/rtl-design-flow/SKILL.md，
并按其指引读取 references/。插件根目录为 <仓库绝对路径>/plugins/rtl-flow。

使用 <Python绝对路径> 执行 scripts/ 下的脚本，并在每次 shell 调用时
把该 Python 所在目录加入子进程 PATH，使用 UTF-8 输出。
由 flow.py next 的输出决定下一步；不直接改状态文件或伪造审核通过。
G0–G3 及 auto 模式遵守上游协议，G3 不可跳过。

dispatch 时读取 agents/<角色>.md，将角色正文和状态机给出的任务提示
交给当前可用的 DSH 子 agent 工具；不要假设 rtl-flow:<角色> 已注册。
需要并行的角色分别派发，完成后再继续 next；没有子 agent 能力时说明
缺少能力，不宣称多 agent 流程已完整运行。
tb-engineer 使用全新上下文，不继承主会话的 RTL、reports、doc/05、
其他角色交接或调试内容，仅提供规格及其验证任务所需材料。
本接入没有 hook 强制文件访问隔离，不将提示约束声称为安全隔离。

提问和审核映射到当前 DSH 用户提问工具；没有该工具时直接在对话中
提问并等待。保留原始名称，遵守生成文件和原始输入只读规则。
commands/ 下的文档可作操作参考，但 /rtl-flow:* 未自动注册。
EDA setup 由用户在自己的终端执行，不在对话中索要服务器密码。
```

这一步通过工作区规则引用 skill，**不会让原生 `skill` 工具自动发现它**。实际任务中可通过文件读取工具加载该文件。不要仅因为 skill 没出现在菜单里就重复安装。

## 5. 验收

安装 agent 应检查并报告：

1. 相对 `plugins/rtl-flow/` 检查 `agents/` 和 `commands/`；相对 `plugins/rtl-flow/skills/rtl-design-flow/` 检查 `SKILL.md`、`references/`、`templates/` 和 `scripts/flow.py`，确认完整。
2. Python 可运行、PyYAML 可导入，`flow.py --help` 正常退出；记录解释器路径、仓库路径和 `plugins/rtl-flow/.claude-plugin/plugin.json` 中的版本。Git 克隆另记录 `git -C rtl_doc_agent rev-parse HEAD`；ZIP 按第 2 节记录来源和摘要。
3. 工作区 `AGENTS.md` 中路径全部真实有效，原规则保留，重复接入没有重复小节。
4. 在**新的临时测试目录**执行 `flow.py init <测试目录> --input "installation smoke test"` 和 `flow.py status <测试目录>`，确认处于 `P0`、`mode=manual`，审核未通过。不要在用户已有 IP 或官方示例上执行 init；官方示例不一定带 `.flow/state.json`。不要执行 `next`、EDA setup、lint 或仿真作为安装测试。说明生成的测试目录位置。

第 4 步也需要使用第 3 节的解释器与 PATH 设置。`init` 只验证模板和状态初始化，不能证明 RTL、UVM、VCS 或完整多 agent 流程通过。

随后在**同一工作区的新 DSH 会话**输入：

```text
请验证 RTL Flow 工作区接入：确认已加载 AGENTS.md 的 RTL Flow 小节，
读取其中指向的 SKILL.md，并验证 Python、PyYAML 和 flow.py --help。
只检查接入，不创建 IP、不启动 EDA 配置或回归。
```

新会话未验证时报告“文件与脚本检查通过，等待新会话规则加载验收”。不必为了本接入重启整个 DSH 服务，也不要主动关闭用户会话。只有实际看到新会话加载结果才报告规则加载通过；命令菜单和插件列表不是本方式的完成标准。

安装完成后可以直接说“根据这份需求生成 RTL 和文档”，由工作区规则引导主会话读取 skill。

## 6. EDA 配置、更新与移除

需要 lint / 仿真时，由用户在自己的交互式终端运行：

```text
"<Python绝对路径>" "<仓库绝对路径>/plugins/rtl-flow/skills/rtl-design-flow/scripts/rtlflow.py" setup
```

Windows PowerShell 在可执行文件路径前加 `&`，并按第 3 节设置 PATH。安装 agent 应提供替换完占位符的本机命令，不索取密码，不自动启动向导。`doctor` 会检查远程环境，不作为接入的必过条件。沿用 `~/.rtl-flow/` 中已有配置，详见 [首次配置](../README.md#首次配置每台机器一次)。

- **Git 更新：** 按第 2 节检查来源、分支和本地修改后执行 `pull --ff-only`，重新检查版本和脚本；规则路径不变时无需重复追加。路径变化时更新规则及本地封装。
- **ZIP 更新：** 下载到新的独立目录，核验内容、版本与摘要，再更新规则引用；保留旧目录与本地修改直到验证完成。不要在快照目录执行 `git pull`。
- **移除：** 删除或撤回自己加入的 RTL Flow 规则小节；确认没有项目依赖后才移除独立源码和虚拟环境。保留用户 IP、其他规则及 `~/.rtl-flow/` 的 EDA 配置。

## 故障排查

| 现象 | 处理 |
|---|---|
| DSH 插件管理器无法安装仓库 URL | 本方式不是原生 bundle，按本指南接入工作区规则与脚本。 |
| 安装后没有斜杠命令、命名 agent 或 skill 菜单项 | 属于本方式的边界；在新会话核验规则加载与文件读取。 |
| Python 路径存在但不能运行 | 检查 Windows 商店别名，使用实际解释器或 DSH 工具返回的路径。 |
| 第一条命令成功，后续提示找不到 Python / yaml | shell 环境可能不持久；每次重设虚拟环境 Python、PATH 和脚本路径。 |
| 新会话未读取规则 | 确认会话实际工作区、AGENTS.md 位置和引用路径；不要用应用安装路径代替工作区。 |
| 验证 agent 可以读取 RTL | 本接入没有强制隔离；不要报告隔离成功。需要强制隔离时使用已适配的 Claude Code / OpenCode。 |

## 安装完成后的 EDA 启动提示

安装完成后必须明确告诉用户：远端连接采用 FTP + 手动启动 watcher。先由 agent 执行 `rtlflow.py connect` 配置 FTP 并上传启动文件；返回 `bootstrap_required` 后，请在远端 EDA 环境（VNC 桌面）的终端执行以下具体命令：

```sh
bash ~/setup_watcher.sh --if-stopped
```

然后由 agent 再次执行 `rtlflow.py connect` 验证，返回 `ready` 才表示 EDA 连接就绪。仅安装插件并不会上传服务器文件，不应让用户在上传前执行命令。watcher 已在线时直接复用，无需再次启动。
