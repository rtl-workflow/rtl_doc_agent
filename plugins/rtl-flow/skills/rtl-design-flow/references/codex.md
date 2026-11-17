# Codex 运行适配

仅在 Codex 执行 RTL Flow 任务时读取。安装后的 `rtl-design-flow` skill 与 Claude Code / OpenCode 共用脚本、模板和角色正文；安装检查不需要启动设计流程。

## 路径与 Python

- `$SKILL` 表示当前加载的 `SKILL.md` 所在目录，不是固定环境变量。插件根目录是其上两级目录，角色文件在 `<插件根>/agents/<角色>.md`。使用当前已安装副本的绝对路径，不假定源码克隆目录或旧缓存仍有效。
- 使用已核验的 Python 3.8+ 和 PyYAML。每次 shell 调用都给子进程 PATH 加上同一 Python 所在目录，设置 UTF-8 输出；`flow.py` 的内部命令仍会调用 `python`。不要假定跨 shell 调用保留虚拟环境激活状态。
- `commands/*.md` 是操作参考，不依赖 `/rtl-flow:*` 被注册。用户可用自然语言要求新建、继续、检查状态或迭代。

## 派发角色

`flow.py next` 输出中的 `subagent_type` 是角色标识，不是 Codex 已注册工具类型。不要把 `rtl-flow:tb-engineer` 等值直接当作 Codex 的 `agent_type`。

收到 `dispatch` 后，对每项任务：

1. 从 `subagent_type` 去掉 `rtl-flow:` 前缀，核对是 `spec-author`、`architect`、`rtl-engineer`、`tb-engineer` 或 `debugger`，读取对应角色 Markdown 正文。其 front matter 的 Claude 工具列表不用于配置 Codex。
2. 用当前会话实际提供的子 agent 工具（例如 `spawn_agent`）启动独立角色。任务消息包含角色正文、下述 Codex 权限边界、已核验的 Python / skill / IP 路径，以及状态机给出的完整 `prompt`；不改任务要求、task ID 或交接文件格式。
3. 每个角色使用新上下文；工具支持 `fork_turns` 时设为 `none`。尤其不能把主会话历史或其他 agent 的 RTL、回归日志、定位报告带给 tb-engineer。只给它规格、SSOT、允许的参考资料与状态机生成的验证任务；调试材料仅使用允许的 `*_tb.md`。
4. 多项任务分别派发，可用槽位允许时并行；槽位不足时分批，全部完成后再执行 `next`。通过当前环境的等待工具等待结果，并检查交接文件存在。没有可用子 agent 能力时说明缺失，保留当前状态，不自行替代全部角色并声称多 agent 成功。

交接、状态推进、重试和生成内容检查仍由脚本决定。不要将全部主 skill 当作子 agent 的编排任务；子 agent 只执行被派发的角色任务，不运行 `flow.py` 管理命令。

## 权限边界与审核

Codex 清单显式指向空的 `codex/hooks.json`，避免自动加载针对 Claude Code 工具事件编写的 `hooks/hooks.json`；不使用会在部分客户端触发默认发现的空数组。因此本接入没有 hook 强制读写隔离、写后风格检查或 SubagentStop 校验；角色正文中的相关描述在 Codex 中是行为约束，不能当作已执行的保护措施。`flow.py guard on` 也不会为 Codex 启用这些 hook。

仍遵守角色读写范围、生成文件和原始输入只读、审核字段只能由编排者通过 `flow.py review` 写入的规则。tb-engineer 不读取 RTL、syn、reports、doc/05、真实回归日志、其他角色交接和完整状态文件；只有自身任务指定的交接文件可写。新上下文不等于文件权限隔离；若任务要求强制隔离，应说明当前接入不满足该要求。

`ask_user` / `review` 使用当前可用的用户提问工具或直接在对话中提问并等待，不能假定存在 Claude 的 `AskUserQuestion`。用户未答复不表示通过。G0–G3、`--auto` 仅跳过 G0–G2、G3 必须人工审核的规则保持不变。

`setup_required` 按共用的 [EDA 连接协议](eda-connect.md) 执行；插件安装阶段不启动连接或交互式 setup，不在聊天中收集密码。
