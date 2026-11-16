# 开源选型与本轮架构决定

本轮依据用户确认：P3 采用 SSH；仿真器尚未确定。以下是调研后的接入设计，**不是依赖已安装或 SSH 已联通的声明**。本地现有 `bt_uvm run` 仍是本机 subprocess 执行器。

## P0：默认不内置文档解析，只保留输入追溯

首版 `prepared` 模式接收已整理的 Markdown、CSV、JSON 与 RTL/filelist。既有 Office 工具或用户已有转换流程可在外部做提取；skill 保留原件 SHA-256、提取件 SHA-256、来源位置、转换器/版本、遗漏与低置信度项。没有原件时明确 `original_unavailable`，不得编造页码/来源。`prepared` 是默认设计选择，可换为外部转换器；不是删除输入版本控制、冲突记录或来源追溯。

本轮 GitHub API 返回的热度快照（2026-11-13；仅这三个候选之间比较，不宣称全球最高星）：

| 候选 | stars / 最近 push | 核实能力 | 建议 |
| --- | --- | --- | --- |
| [MarkItDown](https://github.com/microsoft/markitdown) | 195,191 / 2026-11-07 | 多格式转 Markdown，MIT；图片描述/语音等部分功能依赖网络服务 | 轻量外部转换可选；转换为 Markdown 不保证时序图、单元格合并和页码完整 |
| [MinerU](https://github.com/opendatalab/MinerU) | 83,620 / 2026-11-12 | PDF/Office 转 Markdown/JSON；API license=Other/NOASSERTION | 保留候选；先核定所选版本 LICENSE、模型与部署依赖，不能默认按 MIT 分发 |
| [Docling](https://github.com/docling-project/docling) | 70,542 / 2026-11-13 | 版面/表格/OCR、统一 DoclingDocument 与 JSON、本地执行；代码 MIT，模型独立许可证 | 若以后必须内置复杂 PDF 输入，优先做可选 adapter；预下载模型并核对许可，保持原始定位 |

核查来源：[MarkItDown API](https://api.github.com/repos/microsoft/markitdown)、[Docling API](https://api.github.com/repos/docling-project/docling)、[MinerU API](https://api.github.com/repos/opendatalab/MinerU)。功能依据 [MarkItDown 官方 README](https://raw.githubusercontent.com/microsoft/markitdown/main/README.md)、[Docling 官方 README](https://raw.githubusercontent.com/docling-project/docling/main/README.md)。API 活跃度不是长期维护承诺，集成前锁定 release/commit 并用自己的输入样本比较转换保真度。

**验收样本**：至少包含端口表、跨页表格、带上下标的时序参数、状态图与扫描页。检查负号/单位/位宽/表头/图片关联是否丢失。解析器输出只是候选事实，不自动批准握手与时序。

## P1：复用成熟方法与工具，自己保留语义契约

成熟工具并不等于“任意自然语言需求→正确 RM”。建议拆成三层：来源事实 → 已批准的 verification IR → 组件规格与生成后端。

| 项目/参考 | 已核实能力及依据 | 在本 skill 中的位置 / 限制 |
| --- | --- | --- |
| [OpenTitan DV methodology](https://raw.githubusercontent.com/lowRISC/opentitan/master/doc/contributing/dv/methodology/README.md) | UVM、testplan、DV document、阶段性验证与评审；项目以 VCS 为签核基准，其他工具成熟度不同 | **采用方法**：计划与用例/覆盖映射、里程碑与证据。不要整体复制 SoC/IP 特定基类、TL-UL/寄存器假设或指定 VCS |
| [OpenTitan Testplanner](https://opentitan.org/book/util/dvsim/doc/testplanner.html) | Hjson testpoints、covergroups，测试与 testpoint 多对多映射，关联仿真结果 | 参考 P1 schema；本项目继续 JSON 为唯一机器格式。N/A 必须有批准理由，不能照搬映射跳过后当通过 |
| [slang/pyslang](https://raw.githubusercontent.com/MikePopoloski/slang/master/README.md) | MIT；SystemVerilog 解析、类型检查、elaboration、AST/Python 绑定 | 优先候选：从真实 RTL 获取端口/参数/类型并做静态检查；需真实宏/include/参数/UVM库。不能从 RTL 推导功能期望或代替目标仿真器运行 |
| [Siemens UVMF 的官方生态示例](https://uk.mathworks.com/help/releases/R2026b/hdlverifier/ug/generate-uvm-framework-testbench-for-verification.html) | 结构化 YAML 生成 UVMF 基础设施；sequence/predictor 需先设计；示例借助商业 HDL Verifier 与 Questa | P2 后端候选，**不默认依赖 MATLAB 或 Questa**。本轮未核验可分发 UVMF 包的精确版本/许可证，不复制来源不明镜像 |
| [Edalize](https://raw.githubusercontent.com/olofk/edalize/master/README.rst) | 将 HDL 文件、defines、参数、plusargs 映射到多种 EDA 配置/build/run | 可作为远端 profile 的工具适配层。其 README 示例不是本项目 UVM 兼容性证明；先选定具体工具版本再验收，不绑定为首版强制依赖 |

OpenTitan 仓库默认 [Apache-2.0](https://raw.githubusercontent.com/lowRISC/opentitan/master/LICENSE)，具体文件例外仍逐一核对。本轮部分旧 dvgen 源路径返回 404，因此**未把 dvgen 列作已核实的可直接调用生成器**。UVMF/Easier UVM 等可继续评估，但不凭名称或热度宣称已经满足本项目生成合同。

### P1 应落地的合同（下一轮实现，不等于现有字段已支持）

- `sources`：原件/提取件摘要、来源定位与可信状态。
- `dut`：top、参数、宏、filelist、编译语言、真实 RTL 版本。
- `interfaces`：逐信号方向/宽度/类型、clock/reset 域、驱动者、采样沿及接受条件。
- `events`：offered、accepted、issued、completed、rejected、cancelled、reset_epoch；显式规定计数单位与关联键。
- `requirements`：稳定 ID、source_refs、确认/推断/冲突、适用配置、判定规则。
- `testpoints`：刺激、可观察点、checker、coverage、test IDs；允许一个用例覆盖多个 testpoint，不能强迫一一对应。
- `components`：职责、文件、依赖、接口/方法、连接、reset 清理、完成条件、允许编辑槽位。
- `open_questions`：只阻塞依赖该事实的组件；保留全量需求分母和获批子集，不能通过删除未决项让全计划变绿。

agent 提出候选模型/架构，由合同检查器与设计责任方确认语义；确定性渲染器生成骨架，协议行为由 agent 在指定槽位实现，再真实编译。独立 RM 不直接复刻 DUT 算法。新 JSON schema 应版本化，旧 `static_gates` 需显式迁移，而不是把本表未经验证的字段硬塞入 v1。

## P3：SSH 已选定，仿真器未选定

见 [SSH 后端合同](ssh-backend-contract.md)及 [配置示例](../assets/ssh-profile.example.json)。transport 和 simulator profile 分离：前者负责身份校验、上传、启动、查询、取消和下载；后者负责工具版本、编译/elaborate、test/seed 参数、日志解析与覆盖格式。可先用受控假命令测试传输，但结果必须标 transport-only，不能入 DUT pass。

## 比继续堆判定器更优先的补齐项

1. **端到端强制顺序**：当前 CLI 的 static/run/aggregate 可独立运行，run 没有强制消费前置 gate receipt。需要 orchestrator 将 design/IR/platform/manifest 的版本与通过结果绑定到 run；缺任何前置证据不得推进。
2. **统一事件语义**：当前 accepted=returned+cancelled+rejected 对“未接受便拒绝”“无数据返回的写完成”等协议未必成立。应将 offered/accepted/pre_accept_rejected/post_accept_cancelled/completed 分开，使用类型化事件台账，逐事务核对；不能只改字段名。
3. **运行集合与重跑**：建立 campaign_id、attempt_id、supersedes；保留失败尝试，明确哪次修复后的运行被接受。不能删除失败目录获得聚合 pass，也不能永远拒绝正常重跑。
4. **构建与身份绑定**：证据关联 RTL、TB、filelist、宏/参数、工具版本、UVM版本、编译产物摘要和适配器版本。SSH 连接成功/退出 0 都不能证明工具或 DUT 身份。
5. **故障注入资格测试**：除 Python 假日志反例，还必须用真实 UVM 小 DUT 验证断开 monitor/scoreboard、数据翻转、丢重事务及 reset 世代混淆能报错。
6. **首版只承诺一个经过实测的组合**：一个 OS/SSH 服务、一个仿真器版本、一个 UVM 版本、一个小 DUT。后续逐 profile 增加覆盖；不把对 Verilator/Icarus 的工具支持宣传为完整 UVM 等价替代。

本轮只完成有来源的选型与实现合同、配置示例和 skill 接入；未安装第三方包、下载模型、上传项目、连接远端或运行真实 EDA。
