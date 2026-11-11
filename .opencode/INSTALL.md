# 在 OpenCode 中安装 rtl-flow

这份指南既供用户手动执行，也供收到“帮我安装 rtl-flow”的 OpenCode agent 执行。按顺序完成环境检查、克隆、注册和验收；每一步失败都先处理错误，不要跳过并报告成功。

## 1. 检查环境与安装方式

在运行 OpenCode 的同一个环境中执行：

```sh
opencode --version
git --version
python --version
```

- 当前适配器使用 OpenCode **1.x** 的 `config`、`tool.execute.before/after` 和 `task` 接口。若检测到 2.x，停止这套安装步骤并说明当前适配器尚未适配；不要仅改配置键就宣称兼容。
- 需要 Git、Python 3.8+，并且 `python` 命令可用。仅有 `python3` 或 `py` 时，先让 OpenCode 的运行环境提供 `python`；工作流命令仍会调用它。
- Desktop 若没有可用的 `opencode` 命令，从应用中确认版本，并确认其后台服务的运行用户和环境。Windows 原生、WSL、远程服务的配置目录彼此独立；安装到实际运行 OpenCode 服务的环境。
- 这是含有 Claude Code 市场元数据和 OpenCode 适配器的仓库，不是 npm 插件包。不要执行 `npm install rtl-flow`，不要把仓库 URL 填入 `opencode.json` 的 `plugin` / `plugins`，也不要在 OpenCode 中执行 Claude Code 的 `/plugin marketplace` 命令。
- 使用仓库自带的 `install-opencode` 生成加载器。不要单独复制 `plugins/rtl-flow/opencode/rtl-flow.js`：它只导出工厂函数，并按相对位置读取 agents、commands、skills 和 hooks，必须保留完整仓库。

## 2. 确定安装位置

安装脚本按以下规则确定全局配置目录，Windows 也使用这套规则：

| 条件 | OpenCode 配置目录 |
|---|---|
| 已设置 `XDG_CONFIG_HOME` | `<XDG_CONFIG_HOME>/opencode` |
| 未设置 | `<用户主目录>/.config/opencode` |

默认把完整仓库放在该目录下的 `rtl-flow`，加载器放在 `plugins/rtl-flow.js`。仓库必须长期保留，不要放进临时目录。

若用户已经有本仓库的固定克隆目录，可以直接复用；后续把 `rtlFlowRepo` 设为其绝对路径。不要把项目工作目录误当作安装目录，也不要覆盖现有用户配置。

**重复安装 / 目录已存在：** 先检查 `git -C <安装目录> remote -v`、`git -C <安装目录> status --short --branch`。只有确认这是 `rtl-workflow/rtl_doc_agent`、工作区干净且处于跟踪 `origin/main` 的 `main` 分支，才运行 `git -C <安装目录> pull --ff-only`。如有本地修改、其他分支、分叉历史或目录不属于本仓库，保留现状，报告具体冲突并让用户选择复用位置；不要 reset、清空或覆盖。

## 3. 克隆并注册

选择与当前 shell 相符的一组命令。以下代码针对首次安装；目录已存在时按上一节处理，再从设置脚本路径开始执行。

注册前，若 `<配置目录>/plugins/rtl-flow.js` 已存在，先读取确认其用途；若是手工定制内容，先备份。安装脚本会覆盖此单个文件，不合并自定义代码。

### Windows PowerShell

```powershell
$rtlFlowConfig = if ($env:XDG_CONFIG_HOME) {
    Join-Path $env:XDG_CONFIG_HOME 'opencode'
} else {
    Join-Path ([Environment]::GetFolderPath('UserProfile')) '.config/opencode'
}
$rtlFlowRepo = Join-Path $rtlFlowConfig 'rtl-flow'
New-Item -ItemType Directory -Force -Path $rtlFlowConfig | Out-Null
git clone https://github.com/rtl-workflow/rtl_doc_agent.git "$rtlFlowRepo"
if ($LASTEXITCODE -ne 0) { throw '克隆失败，请先处理错误。' }

$rtlFlowScript = Join-Path $rtlFlowRepo 'plugins/rtl-flow/skills/rtl-design-flow/scripts/rtlflow.py'
python "$rtlFlowScript" install-opencode
if ($LASTEXITCODE -ne 0) { throw '注册失败，请先处理错误。' }
Get-Content -LiteralPath (Join-Path $rtlFlowConfig 'plugins/rtl-flow.js')
```

### macOS / Linux / WSL（Bash）

```bash
rtlFlowConfig="${XDG_CONFIG_HOME:-$HOME/.config}/opencode"
rtlFlowRepo="$rtlFlowConfig/rtl-flow"
mkdir -p "$rtlFlowConfig" &&
git clone https://github.com/rtl-workflow/rtl_doc_agent.git "$rtlFlowRepo" &&
python "$rtlFlowRepo/plugins/rtl-flow/skills/rtl-design-flow/scripts/rtlflow.py" install-opencode &&
cat "$rtlFlowConfig/plugins/rtl-flow.js"
```

`install-opencode` 无需 EDA 连接或密码，也不运行交互式 `setup`。它会创建或更新 `plugins/rtl-flow.js`，其中包含：

- 指向完整仓库中适配器的绝对 `file://` 导入地址；
- 执行安装脚本时所用 Python 解释器的绝对路径；
- `export const RtlFlow = createPlugin(...)`，供 OpenCode 加载。

正常的重复安装可重建加载器，不需要修改 `opencode.json` 或创建软链接。

### 检查 Python 依赖

```sh
python -c "import yaml; print('PyYAML OK')"
```

若提示缺少 `yaml`，在同一 Python 环境安装后重新检查：

```sh
python -m pip install pyyaml
```

如系统禁止向该 Python 安装包，使用受支持的 Python / 虚拟环境，并确保 OpenCode 启动时的 `python` 指向它，再重新运行 `install-opencode`。不要通过破坏系统包管理限制来安装。后续 EDA `setup` 会检查 PyYAML 和凭据库依赖 `keyring`。

## 4. 验收：区分文件注册与实际加载

**重启前，agent 必须检查：**

1. 加载器文件存在；其中导入的适配器和 Python 路径真实存在，指向本次安装位置。
2. 完整仓库中的 `plugins/rtl-flow/agents/`、`commands/`、`skills/rtl-design-flow/SKILL.md`、`hooks/flow_hook.py` 均存在。
3. `python` 可运行、PyYAML 可导入。记录仓库实际路径、`git -C <安装目录> rev-parse --short HEAD` 和 `plugins/rtl-flow/.claude-plugin/plugin.json` 中的版本。

然后提示用户**退出并重新启动 OpenCode，开启新会话**。不要在执行安装的会话里主动关闭用户正在使用的 OpenCode，也不要把旧会话里尚未出现命令判为安装失败。

**重启后确认：**

- 命令列表出现 `/rtl-flow:ip-new`、`/rtl-flow:ip-run`、`/rtl-flow:ip-status` 等命令。
- 可用子 agent 中包含 `rtl-flow:spec-author`、`rtl-flow:architect`、`rtl-flow:rtl-engineer`、`rtl-flow:tb-engineer`、`rtl-flow:debugger`。
- 原生 `skill` 工具能发现并加载 `rtl-design-flow`。插件加载时会在 `<配置目录>/skills/rtl-design-flow/SKILL.md` 生成带真实路径的 skill；安装脚本本身不会生成这个文件。

可以在新会话中输入：

```text
请验证 rtl-flow 是否加载：检查 rtl-flow 命令和五个角色 agent 是否可用，
并用 skill 工具加载 rtl-design-flow。只检查安装，不创建 IP、不启动 EDA 配置或回归。
```

仅有 skill 文件不足以证明插件加载成功，旧文件可能残留。必须结合命令和 agent 注册一起检查。

安装 agent 的结果应明确写出“文件注册完成，等待重启验收”或“重启后的加载验收通过”，并附实际安装路径、版本、提交号和未完成项。没有观察到重启后的结果时，不要宣称工作流已经验证可用。

## 5. EDA 服务器配置（安装完成后的独立步骤）

安装插件不需要服务器账号。需要运行 lint / 仿真时，由用户在**自己的交互式终端**执行一次：

```text
python "<安装目录>/plugins/rtl-flow/skills/rtl-design-flow/scripts/rtlflow.py" setup
```

提供命令时，把 `<安装目录>` 换成实际绝对路径。不要让用户在 AI 聊天中发送服务器密码，也不要在 agent 的非交互 shell 中启动此向导等待密码。配置保存在 `~/.rtl-flow/`，已配置的用户无需为了安装或更新插件重新配置。

`doctor` 用来检查 EDA 连接与工具，会联系服务器；不要把它作为单纯插件安装的必过条件。服务器配置详见 [README 首次配置](../README.md#首次配置每台机器一次)。

## 更新

确认仓库和工作区状态满足第 2 节的条件，并按第 3 节检查、备份手工定制的加载器后，执行（将占位符换成实际绝对路径）：

```text
git -C "<安装目录>" pull --ff-only
python "<安装目录>/plugins/rtl-flow/skills/rtl-design-flow/scripts/rtlflow.py" install-opencode
```

前一步成功后再执行下一步，随后重启 OpenCode，按第 4 节验收。仓库移动、Python 路径变化时，也需要重新运行注册命令。保留 `~/.rtl-flow/` 中的 EDA 配置。

## 故障排查

| 现象 | 检查与处理 |
|---|---|
| 安装指南 URL 返回 404 或无法读取 | 不要猜测安装命令；确认仓库分支上已有 `.opencode/INSTALL.md`。已有本地克隆时可直接读取该文件；网络失败则报告实际错误。 |
| 克隆成功但没有命令 | 确认执行了 `install-opencode`，加载器位于运行 OpenCode 的配置目录，并已重启。仅克隆不会注册插件。 |
| 报 `createPlugin`、导出或模块路径错误 | 检查加载器是否由脚本生成、导入地址是否存在；不要把适配器当加载器复制。修复仓库位置后重新注册。 |
| Windows 安装后 WSL 看不到（或反过来） | 在实际运行 OpenCode 的那一侧安装；检查用户主目录和 `XDG_CONFIG_HOME`。 |
| 使用了自定义配置目录 | 当前安装脚本只读取 `XDG_CONFIG_HOME` 和用户主目录，不读取 `OPENCODE_CONFIG_DIR`。若只设置了后者，先统一为本指南支持的布局，并确保安装脚本与 OpenCode 服务使用相同环境，再安装。 |
| 插件加载，但工作流提示 Python / yaml 错误 | 在 OpenCode 的执行环境检查 `python` 和 `import yaml`；选择可长期使用的解释器并重新注册，避免退出临时虚拟环境后失效。 |
| 只有 skill，没有命令和 agent | skill 可能是旧副本；检查插件加载日志与加载器，恢复完整安装，不要只复制 skill。 |
| OpenCode 启动出现配置错误 | 检查此前是否把本仓库误加为 npm 插件。只修正已确认属于 rtl-flow 的错误配置项，保留其他插件及用户设置。 |
| OpenCode 2.x 无法加载 | 当前适配器尚未适配 2.x；报告版本和错误，不套用其他插件的 2.x 配置来掩盖接口不兼容。 |

本指南参考 [superpowers 的 OpenCode 安装入口](https://github.com/obra/superpowers#opencode) 的组织方式；具体命令以本仓库的 `rtlflow.py` 安装脚本和 OpenCode 适配器为准。
