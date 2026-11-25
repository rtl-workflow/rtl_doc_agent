# EDA 自动连接（agent 协议）

目标是把网络检查、配置复用、watcher 启动和工具验证交给 agent，用户只补充必要信息。通过 `rtlflow.py connect` 执行；兼容的交互式 `setup` 保留，不能在非交互工具中直接启动它等待密码。

## 1. 从已有配置开始

```sh
python <skill>/scripts/rtlflow.py connect
```

`connect` 不调用终端 `input()` 或 `getpass()`，输出 JSON action。先读返回结果，不要让用户重复填写已知信息。只在 `action=ready` 且退出码为 0 时报告配置验证通过。

需要区分三个地址：VPN 公网入口用于接入网络；内部 FTP 地址用于 EDA 任务；VNC 的 `host:display` 用于桌面。不能把 VPN HTTPS 端口或 VNC 显示号填成 FTP 端口。

缺少地址和账号时，合并为一次提问，随后执行（替换示例占位符）：

```sh
python <skill>/scripts/rtlflow.py connect --host <内部服务器> --user <Linux账号> --port 21
```

主机名不带 URL 协议或 `:端口`；FTP 端口单独指定。FTP 根目录必须对应该账号家目录。

## 2. 密码只在本机输入

已有系统凭据库中的密码自动复用，不读取给模型，也不要求用户发到聊天。

Windows 本机首次缺少密码时，agent 可以执行：

```sh
python <skill>/scripts/rtlflow.py connect --host <内部服务器> --user <Linux账号> --credential-dialog
```

这会在运行 agent 的 Windows 机器上打开系统凭据窗口。用户在窗口中输入密码，密码只留在本机进程和系统凭据库，不输出到 JSON 或放入命令行。远程浏览器用户需要能访问运行 DSH 的机器桌面；不能假设该窗口出现在手机或另一台电脑上。用户取消时停止，不反复弹窗。显式传入 `--credential-dialog` 会重新输入并更新凭据，可用于修正输错或已变更的密码；取消不覆盖原凭据。

系统凭据库不可用时，自动连接不降级为明文文件保存。没有本机图形窗口的平台可复用已经配置的凭据；首次输入可由用户在自己的交互终端运行兼容 `setup`。不要让用户在聊天中发送密码，不要把聊天中的密码嵌入命令、临时脚本、工具参数或环境变量。

## 3. 手动启动 watcher

watcher 已在线且签名探测通过时直接复用。首次连接或离线时，connect 通过 FTP 上传 watcher、启动脚本和任务签名文件，返回 bootstrap_required。请用户在远端 EDA 环境（VNC 桌面）的终端执行：

```sh
bash ~/setup_watcher.sh --if-stopped
```

必须先完成 FTP 配置和上传，再执行此命令。完成后 agent 重试 connect，只有 ready 才算连接验证通过。FTP 本身不能执行 shell。

## 4. 返回动作与处理

| action | agent 应做什么 |
|---|---|
| `ready` | 报告 watcher、签名任务与工具检查通过。后续正常运行 RTL 流程。 |
| `input_required` | 合并询问缺失的地址、账号、端口等非敏感信息。 |
| `credentials_required` | 复用安全凭据或在 Windows 本机使用 `--credential-dialog`，不在聊天中索取密码。 |
| `credential_store_required` / `credential_dialog_unavailable` | 说明缺失的本机能力，不静默保存明文；必要时回退到用户自己的终端。 |
| `dependency_required` | 在当前 Python 环境安装返回的依赖，然后重试。 |
| `endpoint_change_required` | 保留现有配置；新服务器使用独立 `REXEC_CONFIG` 目录，不覆盖已有工作环境。 |
| `signing_key_required` / `signing_key_mismatch` | 停止接管；核对原机器和签名密钥，不自动覆盖服务器密钥。 |
| `active_jobs` | 不重启 watcher；等待现有任务完成或由用户决定。 |

退出码：0 为验证通过；2 为需要用户或环境补充；3 为拒绝/失败；124 为超时；130 为取消。超时或取消不代表回滚已完成的远程操作，重试时先检查当前状态，不盲目再次部署。

所有报告都不能包含密码或签名密钥。探测成功表示远程命令可执行且工具可找到，不证明 license 可用，也不代替实际 lint、编译、UVM 或仿真验证。

## 5. Agent 环境注意事项

DSH 每次 shell 调用可能是新进程。每次都使用实际 Python 解释器，设置子进程 PATH 和 UTF-8；使用已安装的工作区封装脚本也可以。`--credential-dialog` 是本机窗口，不是聊天输入框。


任务签名文件由插件管理，用户无需配置登录密钥。
