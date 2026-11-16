---
description: 自动连接或检查 rtl-flow 的远程 VCS / SpyGlass 环境
---

读取 `skills/rtl-design-flow/references/eda-connect.md`，使用当前 Python 运行：

`python $SKILL/scripts/rtlflow.py connect`

按返回的 JSON action 执行下一步：

- 缺少地址、账号或端口时，合并为一次提问。区分 VPN 入口、VNC 地址和内部 FTP/SSH 地址。
- 已保存凭据时自动复用；缺少凭据时在 Windows 本机使用 `--credential-dialog` 打开系统凭据窗口，由用户直接输入。不要在聊天中索取密码，也不要把密码放入工具参数、命令、日志或环境变量。
- watcher 已在线则验证并复用，不重启。首次启动且服务器提供同一账号的 SSH 时，使用 `--start-watcher ssh`；缺少 Paramiko 时按返回的依赖提示安装到当前独立 Python 环境。
- 未知 SSH 主机密钥时向用户展示指纹，等待其确认或与管理员核对后，才能使用 `--ssh-fingerprint`。不要自动接受未知指纹。
- 仅 FTP/VNC 时，说明没有远程命令通道，只提供返回的那条启动命令；没有本机凭据弹窗能力时，才回退为用户自行运行 `setup`。
- 只有 action 为 `ready` 且退出码为 0，才报告配置验证通过；其他 action 按指南处理，不循环猜密码或覆盖现有配置。

交互式 `setup` 仍保留作兼容入口，不要默认要求用户另开 PowerShell。
