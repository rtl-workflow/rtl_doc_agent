# SSH 执行后端合同（设计已定，尚未实现）

用户已确认采用 SSH，仿真器未确定。本合同是后续开发接口，不是现有 `bt_uvm` 的新子命令；现有 `run` 仍调用本机 subprocess。凭据、主机和许可证信息不得填进版本控制的示例。

## 两层边界

1. SSH transport：`probe / stage / submit / status / cancel / collect`，与 VCS/Questa/Xcelium/UVS 名称无关。
2. Simulator profile：`probe_version / compile / elaborate / simulate / parse / coverage`，包含 argv 模板、环境白名单、退出码与错误分类、可执行产物位置、支持的 UVM/SVA/coverage/DPI 能力。只读已审核 profile，不能由输入需求文本指定 shell 命令。

传输候选为 Paramiko（[SSHClient 官方文档](https://docs.paramiko.org/en/stable/api/client.html)）；OpenSSH CLI 可作为部署替代。首版只实现一种，避免两套行为。已知主机校验使用明确 known_hosts 和 RejectPolicy，不默认 AutoAddPolicy；认证由 ssh-agent/key-ref 提供。SSH 认证和传输加密不构成服务器端写权限隔离。

## 最小配置

[ssh-profile.example.json](../assets/ssh-profile.example.json) 是**未就绪模板**：`enabled=false`、`simulator.id=null`、`validated=false`。没有工具/版本/profile 时应 `blocked: simulator_profile_unconfigured`，不能猜测为 UVS/VCS。`null` 字段在执行前必须由真实部署值替换；不能给模板自动补一个能退出 0 的命令。

- transport：host alias、port、known_hosts 路径、auth reference、remote_root、连接/命令/作业超时。
- tool：simulator ID、版本探测 argv、UVM版本、compile/elaborate/run argv、产物相对路径、seed/test 映射、环境白名单与所需能力。
- policy：输入只读/输出可写路径、传输清单、主机身份、最大并发、不可重用 run 目录。
- evidence：campaign/attempt/run ID、plan/RTL/TB/profile 摘要、原始日志、远端退出码、工具版本、产物摘要、采集状态。

## 执行协议

1. `probe`：验证主机身份、认证、远端 Python/worker 版本、root 写权限、剩余空间、仿真器/UVM版本及能力。许可可单独探测；SSH 通但工具缺失为 blocked。
2. `stage`：只上传获批文件清单，先规范化路径并拒绝越界/链接逃逸；SFTP 到唯一 staging 目录，逐文件 SHA-256 核对后标记 staged。不能解压有 `../` 或绝对路径的归档。
3. `submit`：以 run_id/operation_id 幂等提交给固定远端 worker。worker 接收结构化 job JSON、用 argv 调用工具，不拼接需求中的 shell 文本。SSH `exec_command` 本身接收字符串，只允许固定入口和经正确 shell quoting 的受控标识；JSON 经 SFTP 传输。
4. `compile/elaborate`：记录版本/环境白名单、日志/退出码和输出工件摘要；失败禁止进入 simulate。编译缓存键包括 RTL/TB/filelist/includes/宏/参数/UVM/tool/profile，不能只用顶层文件名。
5. `simulate`：绑定编译工件、test、seed、配置；超时由远端 worker 管理进程组。客户端断开不等于任务结束；不得仅杀 SSH 客户端便声称模拟器已取消。
6. `status/reconnect`：连接中断记 outcome_unknown，按同一个 run_id 查询；禁止盲目重提。只有 worker 的终态回执和日志齐全才允许判定。
7. `collect`：下载 stdout/stderr、编译及仿真回执、工件/覆盖/波形 manifest；校验散列后独立 evaluate。下载不全为 evidence_incomplete，不能退回只看末尾 PASS。
8. `cancel`：worker 终止该 run 的整个进程组，记录 cancelled 回执并确认无残留进程；不删除失败证据。

## 强制只读的部署条件

批准输入、工具 profile、门禁代码由受保护账户维护；生成者/仿真进程只获得必要读权限，输出限制到 run 专用目录。worker 的结果/日志清单不得由被测进程覆盖。独立账户/容器只读挂载是可选实现手段；只有实际权限测试证明修改被拒绝，报告才能说“强制只读生效”。同账号 SFTP 后 chmod 再自称不可篡改不成立。

## 失败与状态

- `blocked`：未配置 simulator、工具/许可证/必要能力缺失、输入语义未确认。
- `fail`：编译/elaboration失败、assertion/mismatch、非法修改、故障注入未检出。
- `outcome_unknown`：SSH 断线或回执丢失；查询原任务，不提升为 pass。
- `evidence_incomplete`：日志/工件缺失或散列不一致；不得聚合通过。
- `cancelled/timeout/not_run`：分别保留，不映射为 pass。
- `pass`：仅远端作业、编译/运行身份、必要活动、全量证据和 gate 全部合格。transport-only 自检使用独立 scope，不进入 DUT结果。

## 必测验收

主机密钥不匹配；认证失败；无仿真器/无许可；上传截断；编译失败；模拟器非零退出；输出大量日志无死锁；断线后按同 ID 找回；重复提交不重复执行；超时/取消无残留；远端输入写入被拒绝；错误 test/seed；旧二进制/旧日志复用；日志删除；下载中断；正常和故障 DUT 各一例。模拟 transport 的单测和真实远端联调分别报告，不能互相替代。
