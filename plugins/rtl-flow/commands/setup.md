---
description: 自动连接或检查 rtl-flow 的远程 VCS / SpyGlass 环境
---

读取 `skills/rtl-design-flow/references/eda-connect.md`，使用当前 Python 运行：

`python $SKILL/scripts/rtlflow.py connect`

按返回的 JSON action 执行下一步：

- 缺少地址或账号时，合并为一次提问。FTP 端口默认使用 21，不询问用户。区分 VPN 入口、VNC 地址和内部 FTP 地址。
- 已保存凭据时自动复用；缺少凭据时在 Windows 本机使用 `--credential-dialog` 打开系统凭据窗口，由用户直接输入。不要在聊天中索取密码，也不要把密码放入工具参数、命令、日志或环境变量。
watcher 已在线则验证并复用；首次连接由 `rtlflow.py connect` 通过 FTP 上传文件，然后请用户在远端 EDA 环境的终端执行 `bash ~/setup_watcher.sh --if-stopped`，完成后重试 connect。密码只在本机凭据窗口或用户终端输入。
- 仅 FTP/VNC 时，说明没有远程命令通道，只提供返回的那条启动命令；没有本机凭据弹窗能力时，才回退为用户自行运行 `setup`。
- 只有 action 为 `ready` 且退出码为 0，才报告配置验证通过；其他 action 按指南处理，不循环猜密码或覆盖现有配置。

交互式 `setup` 仍保留作兼容入口，不要默认要求用户另开 PowerShell。
