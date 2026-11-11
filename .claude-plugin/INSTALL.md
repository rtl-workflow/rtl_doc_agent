# 通过 Claude Code 插件市场安装 rtl-flow

适用于用户手动安装，以及 Claude Code 收到“帮我安装 https://github.com/rtl-workflow/rtl_doc_agent”后代为执行。目标是让 `rtl-flow@rtl-flow` 出现在 Claude Code 的已安装插件列表中并启用，再核验会话加载结果。

## 安装方式与名称

| 项目 | 值 |
|---|---|
| 市场来源 | `https://github.com/rtl-workflow/rtl_doc_agent.git` |
| 市场名称（marketplace.json 的 name） | `rtl-flow` |
| 插件名称（plugin.json 的 name） | `rtl-flow` |
| 完整安装 ID | `rtl-flow@rtl-flow` |
| 默认安装范围 | `user`，当前用户的所有项目 |

仓库名 `rtl_doc_agent` 不是市场名。不要安装 `rtl-flow@rtl_doc_agent`。

**默认通过市场安装。** 不要用手动 `git clone`、复制 skills / agents / commands、`--plugin-dir` 临时加载、OpenCode 的 `install-opencode` 或直接编辑插件注册文件来替代。市场管理器内部可能使用 Git 下载仓库，这是正常行为；最终要看插件是否已注册安装，而非是否出现过 clone 日志。

## 1. 在正确的环境检查现状

安装 agent 在运行当前 Claude Code 的同一个用户和环境中，通过 shell 工具逐条执行：

```sh
claude --version
claude plugin --help
claude plugin marketplace list --json
claude plugin list --json
```

Windows 原生、WSL、SSH 远程环境可能使用不同配置。若当前会话设置了 `CLAUDE_CONFIG_DIR`，命令应继承该配置，不要切换目录或用户来规避错误。

- 没有 `claude` 命令或缺少插件子命令：报告实际情况，按第 4 节让用户在当前客户端手动安装，或先修复 CLI。不要退回到仅克隆源码并报告安装完成。
- 未配置 `rtl-flow` 市场：继续第 2 节添加。
- 已配置 `rtl-flow`：核对来源是否为 `rtl-workflow/rtl_doc_agent`（HTTPS / SSH 等等价地址均可）。来源正确则复用；如指向其他仓库或旧的本地克隆，说明冲突，让用户决定如何迁移，不自动删除市场或覆盖配置。
- 已安装 `rtl-flow@rtl-flow`：保留其现有 scope，并按第 5 节更新；不要再创建另一个 scope 的重复安装。多个 scope 同时存在时先说明实际状态。

这些都是插件管理命令，不需要启动第二个对话模型。不要使用 `claude -p` 让另一个会话代装，也不要把 `/plugin ...` 斜杠命令当作 shell 命令执行。

## 2. 添加市场并安装插件

**仅在正确市场尚未添加时执行：**

```sh
claude plugin marketplace add https://github.com/rtl-workflow/rtl_doc_agent.git
```

确认退出码为 0，并重新查看 `claude plugin marketplace list --json`，确认市场名称为 `rtl-flow`、来源正确。

**然后安装插件，默认 user scope：**

```sh
claude plugin install rtl-flow@rtl-flow --scope user
```

逐条检查退出码和错误信息。任何一步失败都先解决或报告错误，不继续假定成功。不需要预先克隆仓库，不需要 npm 安装，也不需要手工写 `.claude/settings.json`。用户明确要求共享给项目时才选 `--scope project`；仅当前项目个人使用则选 `--scope local`。

## 3. 安装验收与会话加载

再次执行：

```sh
claude plugin marketplace list --json
claude plugin list --json
```

确认市场来源正确，且**已安装列表**中确实包含 `rtl-flow@rtl-flow`；检查实际版本、scope、启用状态和安装路径（以当前 CLI 提供的字段为准）。不要把 `--available` 列出的可用插件误当成已安装插件。

若插件已安装但禁用，启用它（下面以本次默认的 user scope 为例；已有安装使用其实际 scope）：

```sh
claude plugin enable rtl-flow@rtl-flow --scope user
```

再次检查状态。若项目 / local 设置覆盖了 user 设置，报告导致禁用的范围，不能仅凭 enable 命令返回成功就判定当前项目已启用；不要改动无关插件或组织管理配置。

接着根据客户端提示，让用户在当前会话运行 `/reload-plugins`，或重启 Claude Code 后开新会话。安装 agent 不应主动关闭用户会话。重载后检查：

- `/plugin` 的 Installed 页中有 rtl-flow，安装范围正确且启用；Errors 页没有该插件的加载错误。
- 输入 `/rtl-flow:` 能找到 `ip-new`、`ip-run`、`ip-status`、`ip-iter`、`ip-check` 等命令。
- `/agents` 中有 `rtl-flow:spec-author`、`rtl-flow:architect`、`rtl-flow:rtl-engineer`、`rtl-flow:tb-engineer`、`rtl-flow:debugger`。

报告时写明完整插件 ID、市场来源、版本、scope，以及“已安装，等待会话重载验证”或“已重载并验证可用”。只看到克隆目录、市场条目、安装命令已发出，都不足以报告安装成功。验证不需要创建 IP 或启动 EDA 回归。

## 4. 用户在 Claude Code 中手动安装

在 **Claude Code 聊天输入框**逐条输入，不能粘贴到 PowerShell / Bash：

```text
/plugin marketplace add https://github.com/rtl-workflow/rtl_doc_agent.git
/plugin install rtl-flow@rtl-flow
```

如果打开插件详情面板，选择安装到当前用户并完成安装；不能只打开详情页就结束。在 `/plugin` 的 Installed 页检查安装状态，再按照第 3 节重载并验收。若客户端要求用户完成信任或范围选择，准确说明当前等待的操作，不假称已完成。

## 5. 更新已有安装

以下以 user scope 为例；已有安装使用其实际 scope。前一步成功后再运行下一步：

```sh
claude plugin marketplace update rtl-flow
claude plugin update rtl-flow@rtl-flow --scope user
claude plugin list --json
```

第一条刷新市场，第二条更新已安装插件。随后按第 3 节重载并验收。不要通过在手动克隆目录执行 `git pull` 来声称市场中安装的副本已经更新。

## 6. EDA 配置在插件安装之后进行

安装插件不需要 EDA 服务器账号。首次需要 lint / 仿真时，可使用 `/rtl-flow:setup` 获取配置指引，由用户在自己的交互式终端运行插件提供的 `rtlflow.py setup`。使用实际已安装插件路径，不猜测缓存目录；路径可结合安装列表、插件加载信息和真实文件确认。

不要在聊天中索取服务器密码，不要在非交互式工具中启动向导等待输入。现有 `~/.rtl-flow/` 配置保留。EDA 连通性与插件市场安装是两个独立验收项。

## 故障排查

| 现象 | 处理 |
|---|---|
| 以前只做了 `git clone` | 保留原目录和本地修改，按本指南添加远程市场并安装；无需先删除克隆。 |
| 市场已添加，Installed 页没有插件 | 执行 `claude plugin install rtl-flow@rtl-flow --scope user`，再核验安装列表。 |
| 找不到市场 / 插件 | 检查市场名称和来源，完整 ID 必须是 `rtl-flow@rtl-flow`；必要时刷新正确市场。 |
| 网络或认证失败 | 报告失败命令和错误，修复连接后重试；不要改用源码克隆冒充安装。 |
| 提示市场受组织策略限制 | 说明策略拒绝的具体信息，保留管理配置；由用户或管理员处理。 |
| 已安装但命令没有出现 | 检查启用状态、scope 覆盖、客户端使用的配置目录，以及 `/plugin` 的 Errors 页；按提示重载。 |
| 先前曾手动复制 skill / commands / agents | 检查是否存在重复入口，向用户说明冲突；不要删除无法确认来源的文件，也不要覆盖用户自定义内容。 |
| 远程 INSTALL.md 尚不存在 | 使用当前本地文档；需将文档推送到仓库对应分支后，远程安装提示词才可读取。 |

命令形式与验收方式参照 [Claude Code 官方插件安装文档](https://code.claude.com/docs/en/discover-plugins)，插件和市场名称以本仓库的清单为准。
