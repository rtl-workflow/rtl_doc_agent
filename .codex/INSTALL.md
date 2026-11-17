# 在 Codex 中安装 rtl-flow

本指南供 Codex 用户及收到“请按照本仓库 README 为我安装这个插件”的安装 agent 使用。默认通过 **Codex 原生插件市场**安装到当前用户；安装完成后，新会话可发现 `rtl-design-flow` skill。不要只复述步骤或只克隆仓库就报告成功。

## 1. 识别环境与能力

以承载当前对话的环境识别 Codex，不根据机器上是否存在 Claude Code / OpenCode 判断。确认实际执行环境是 Windows 原生、WSL、macOS/Linux 还是远程主机；应安装到运行当前 Codex 的同一用户与环境。

在该环境检查：

```sh
codex --version
codex plugin --help
codex plugin marketplace add --help
codex plugin add --help
git --version
```

本指南的 CLI 命令已用 `codex-cli 0.169.0-alpha.11.1` 验证，不把这个版本号当作最低版本；以当前客户端的实际帮助和能力为准。桌面版没有 `codex` PATH 入口时，先检查客户端提供的 CLI / 插件管理能力，不猜测或硬编码应用安装目录。

- 若提供等价的原生插件工具，可按其实际 schema 添加本仓库市场、安装并启用插件，然后进行同样的验收。
- 若没有 `plugin` 子命令且无等价管理工具，说明客户端缺少原生安装入口，提供升级客户端后重试的步骤；不要凭空改成 `codex plugin install` 或 Claude 的 `/plugin marketplace` 命令，也不要静默退化成复制 skill / 修改 `AGENTS.md`。
- 默认使用当前 Codex 的用户配置目录（通常为 `~/.codex`；若已配置 `CODEX_HOME`，沿用它）。不要为安装创建另一套用户配置、覆盖 `config.toml` 或改变模型、沙箱、审批设置。

## 2. 检查已有安装

```sh
codex plugin marketplace list --json
codex plugin list --marketplace rtl-flow --json
```

市场尚未配置时，第二条可能报告找不到市场；确认这个原因后继续首次安装。其他错误先处理。检查：

- 市场名是 `rtl-flow`，来源是 `https://github.com/rtl-workflow/rtl_doc_agent.git`（等价 GitHub URL 也可），或用户明确使用的本仓库本地目录。
- `rtl-flow@rtl-flow` 是否已安装、启用，版本是否与目标版本一致。市场可用列表中出现不代表已经安装。
- 同名市场指向其他仓库时保留现状，报告具体冲突，不删除或覆盖。已有正确安装无需重复添加市场；需要更新时按第 6 节操作。
- 如果用户之前单独安装了同名 skill，确认其来源并报告可能的重复加载；不要删除来源不明的个人 skill。

## 3. 安装市场和插件

首次安装在 PowerShell、Bash 中均可逐条执行下列命令，**每条成功后再执行下一条**：

```sh
codex plugin marketplace add https://github.com/rtl-workflow/rtl_doc_agent.git --json
codex plugin add rtl-flow@rtl-flow --json
codex plugin list --marketplace rtl-flow --json
```

记录 `add` 返回的 `pluginId`、`version`、`installedPath`，后续从实际安装路径读取脚本。检查 `list` 的已安装记录中 `installed: true`、`enabled: true`。如果被用户或管理策略禁用，查明来源并通过当前客户端支持的设置处理，不能用重新安装掩盖策略限制。

本仓库的 Codex 市场入口是 `.agents/plugins/marketplace.json`，插件清单是 `plugins/rtl-flow/.codex-plugin/plugin.json`。安装器复制完整插件到缓存，角色、模板、脚本和参考资料都随插件保留；不要手工构造缓存目录或仅复制 `SKILL.md`。

**仅在用户明确要求本地源码安装 / 调试时**，将第一条来源替换为完整本地仓库绝对路径，然后照常 `plugin add` 和验收。已有本地克隆更新前检查 `git remote -v`、`git status --short --branch`；仅在来源正确、工作区干净、main 跟踪 origin/main 时运行 `git pull --ff-only`。保留本地修改，不 reset 或清空目录。

## 4. 检查 Python 与完整安装内容

依赖 Python 3.8+、PyYAML，且子进程需要能执行 `python`。先实际运行解释器，路径存在或 Windows 商店别名不表示可用。Codex 提供运行时发现工具时可使用它返回的 Python 路径，不猜测内置运行时位置。

在同一解释器上验证：

```sh
python --version
python -c "import sys, yaml; print(sys.executable); print(yaml.__version__)"
```

若缺少 PyYAML，在选定的用户 Python / 独立虚拟环境中执行 `python -m pip install PyYAML` 后重试。系统 Python 禁止安装包时创建用户虚拟环境，不破坏系统包管理限制；不要把虚拟环境放在会被插件更新替换的缓存里。

以下占位符由安装 agent 替换为已验证的本机绝对路径。`<插件安装绝对路径>` 来自上一步的 `installedPath`，不是源码仓库根目录。

### Windows PowerShell

```powershell
$rtlFlowPython = '<Python绝对路径>'
$rtlFlowPlugin = '<插件安装绝对路径>'
$rtlFlowSkill = Join-Path $rtlFlowPlugin 'skills/rtl-design-flow'
$env:PATH = "$(Split-Path $rtlFlowPython);$env:PATH"
$env:PYTHONIOENCODING = 'utf-8'
& $rtlFlowPython -c "import sys, yaml; assert sys.version_info >= (3, 8); print(sys.executable); print(yaml.__version__)"
if ($LASTEXITCODE -ne 0) { throw 'Python 依赖检查失败' }
python -c "import sys, yaml; print(sys.executable)"
if ($LASTEXITCODE -ne 0) { throw '子进程 python 不可用' }
& $rtlFlowPython (Join-Path $rtlFlowSkill 'scripts/flow.py') --help
if ($LASTEXITCODE -ne 0) { throw '流程脚本检查失败' }
```

### macOS / Linux / WSL（Bash）

```bash
rtlFlowPython='<Python绝对路径>'
rtlFlowPlugin='<插件安装绝对路径>'
rtlFlowSkill="$rtlFlowPlugin/skills/rtl-design-flow"
export PATH="$(dirname "$rtlFlowPython"):$PATH"
export PYTHONIOENCODING=utf-8
"$rtlFlowPython" -c 'import sys, yaml; assert sys.version_info >= (3, 8); print(sys.executable); print(yaml.__version__)' &&
python -c 'import sys, yaml; print(sys.executable)' &&
"$rtlFlowPython" "$rtlFlowSkill/scripts/flow.py" --help
```

两次输出的解释器应一致；只有 `python3` 而没有 `python` 时，可在独立虚拟环境中提供 `python` 后重试。后续每次 shell 调用都重新设置这些路径与 PATH，不能假定上次激活环境仍有效。不要通过修改全局系统 PATH 解决单个插件的运行环境。

检查安装副本中存在：

- `.codex-plugin/plugin.json`，版本与安装记录相同，且 `hooks` 指向 `./codex/hooks.json`；该文件内容为 `{"hooks": {}}`。不要改为空数组，部分客户端仍会回退发现 Claude hook。
- `agents/` 下的五个角色定义，以及 `commands/`。
- `skills/rtl-design-flow/SKILL.md`、`references/codex.md`、`templates/`、`scripts/flow.py`。

最后在**新的临时目录**执行 `flow.py init <临时IP目录> --input "installation smoke test"` 和 `flow.py status <临时IP目录>`，验证模板和状态初始化正常，状态为 `P0`、`mode=manual`，审核未通过。使用上述同一 Python 和 PATH，并报告测试目录位置。不在用户已有 IP 或示例目录上运行 init；不执行 `next`、lint、回归或 EDA 配置作为安装测试。

## 5. 新会话加载验收与使用

安装记录与文件检查通过后，在当前客户端**新建会话**；必要时按客户端提示重载或重启，但不要主动关闭用户正在进行的会话。验收提示词：

```text
请验证刚安装的 RTL Flow 插件：确认 rtl-design-flow 出现在可用 skill 中，
读取它和 references/codex.md，检查实际安装目录中的五个角色文件、模板、
Python、PyYAML 和 flow.py --help。只验证安装，不新建 IP，不启动 EDA 或回归。
```

区分以下结果：

1. **安装完成**：插件有安装记录、已启用，安装内容与脚本检查通过。
2. **加载通过**：新会话实际发现并读取 `rtl-design-flow`（客户端可能显示带插件前缀的 `rtl-flow:rtl-design-flow`）。未完成这一步时明确报告“安装与脚本检查通过，等待新会话加载验收”。不能把直接读到磁盘上的 skill 当作自动发现成功。
3. **完整设计流程通过**：需要后续角色派发、人工审核和真实 EDA 执行；不属于安装测试。

安装后可直接说“按 RTL Flow 根据这些需求生成 RTL 和文档”或“继续这个 IP 的 RTL Flow 流程”。`/rtl-flow:*` 命令和 `rtl-flow:<角色>` 命名 agent 不作为 Codex 安装完成标准。角色通过当前 Codex 的子 agent 工具读取共享角色正文并派发，具体映射见安装副本的 `references/codex.md`。

**能力边界：** 当前 Codex 清单显式禁用本插件的 Claude hook；规则约束和全新子 agent 上下文不能代替文件访问权限隔离。不宣称 tb-engineer 在系统层面无法读取 RTL，也不声称写后自动检查 / agent 退出 hook 已生效。缺少子 agent 工具时可以完成安装，但应报告多 agent 执行能力尚未满足。

## 6. 更新、卸载与 EDA 配置

更新 Git 市场时逐条执行：

```sh
codex plugin marketplace upgrade rtl-flow --json
codex plugin add rtl-flow@rtl-flow --json
codex plugin list --marketplace rtl-flow --json
```

第一步刷新市场，第二步安装当前市场版本；仅刷新市场不算插件更新完成。重新记录 `installedPath` 和版本，重复文件 / 脚本与新会话检查；不能继续使用旧版本缓存路径。维护者需要同步提升两份插件清单的版本号。升级命令或重新添加行为与本机帮助不符时先报告实际错误，不先卸载工作中的插件。不要编辑缓存里的文件来定制插件。

本地源码市场按第 3 节安全更新源码，再运行 `plugin add`；`marketplace upgrade` 针对 Git 市场，不代替本地源码更新。

用户要求卸载时执行：

```sh
codex plugin remove rtl-flow@rtl-flow --json
codex plugin list --marketplace rtl-flow --json
```

确认已安装记录消失，下一会话不再加载该插件。无需移除整个市场或其他插件，保留用户 IP、Python 环境及 `~/.rtl-flow/` 的 EDA 配置。

插件安装不需要 EDA 地址、账号或密码。完成后告知用户 [首次配置入口](../README.md#首次配置每台机器一次)；实际需要 lint / 仿真时按 `references/eda-connect.md` 运行 `rtlflow.py connect`，复用已有配置。不要在安装阶段索取密码或自动启动交互式 setup。

## 故障排查

| 现象 | 处理 |
|---|---|
| 没有 `codex plugin` 或管理工具 | 检查当前客户端能力并升级；不执行 Claude / OpenCode 命令代替。 |
| Git 下载失败 | 检查实际错误、网络和 Git；不把缓存或克隆目录存在当作安装成功。 |
| 市场存在但插件未安装 / 未启用 | 检查 `plugin add` 结果及已安装记录，区分用户设置与管理策略。 |
| 安装成功但旧会话没有 skill | 新建会话或按客户端要求重载；核对同一用户、运行环境和配置目录。 |
| Python 存在但缺 yaml / 子进程失败 | 核对实际解释器和每次 shell 调用的 PATH，确保 `python` 指向同一环境。 |
| 更新后仍加载旧版 | 对比市场版本、已安装版本和实际 skill 路径；重新安装当前版本并在新会话验收。 |
| Codex 尝试调用 Claude 命名角色或 hook | 检查已加载新版 skill 及 `references/codex.md`，核对 Codex 清单显式指向空的 `codex/hooks.json`。 |

插件清单、市场路径和 hook 显式覆盖方式参考 [OpenAI 插件打包文档](https://developers.openai.com/plugins/build/plugins)；CLI 参数以当前 `codex plugin ... --help` 为准。
