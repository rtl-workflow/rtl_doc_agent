# 验证平台交付模板

这是字段模板，所有 `TODO` 都必须替换成真实事实、明确的待确认问题或 `不适用`（附原因）。项目已有格式时沿用原格式，但保留追溯关系。默认目录以项目根为基准；不可把“待确认”填为“通过”。

## `dv/spec/requirements_trace.md`

| ID | 需求/版本/原文位置 | 状态 | 配置/边界 | 刺激和接受事件 | 独立预期与观测点 | checker | coverage | test ID | 证据/未决 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| REQ-001 | TODO | 已确认/推断/冲突/待确认 | TODO | TODO | TODO | TODO | TODO | TEST-001 | TODO |

检查：每个已批准的功能都映射到测试及可观察结果；功能在外部时明确归属；撤销的需求不进入覆盖分母。推断规则必须有依据，不可混入已确认规则。

## `dv/spec/testbench_design.md`

1. **范围**：DUT top、参数、真实 RTL/替身模型、外部模块与各自责任；来源与版本。
2. **接口**：表列信号、方向、宽度、时钟域、复位值、唯一驱动者、采样点、接口定义文件。未知项标 `待确认`。
3. **事件与事务**：意图/接受/执行/返回/取消/复位清理各自判据；事务关联键；延迟、超时、并发及顺序约束。
4. **数据流**：sequence → driver → DUT → 下游 BFM/模型 → DUT 返回；输入与输出 monitor → RM/checker/scoreboard → coverage。列出两端真实观测信号与何时采样。
5. **参考模型**：独立的预期状态转移、协议非法条件、取消策略、复位世代；不得以 DUT 实际输出来修改预测。下游模型根据真实执行维护响应所需状态，两种状态分别记录。
6. **比对**：请求身份及归属、预期/实际配对队列、允许的延迟与重排、丢重错检查、排空和未结算条件、故障时最小诊断信息。
7. **覆盖与用例**：REQ-ID × TEST-ID × checker × coverpoint × 配置；负例和复位在途；明确 coverage 采样事件和批准阈值。
8. **实现/验收**：文件树、编译顺序、运行入口、工具版本、sanity 的有效活动与独立比较证据、已知阻塞。

## `dv/spec/open_questions.md`

| Q-ID | 对应需求 | 缺少的判定/接口事实 | 影响的组件或测试 | 决策责任方 | 当前处理 |
| --- | --- | --- | --- | --- | --- |
| Q-001 | REQ-001 | TODO | TODO | TODO | blocked/暂缓/按已批准子集继续 |

## `dv/tests/test_manifest.*`

推荐字段（JSON/YAML/表格均可，按项目约定）：`id`、`requirement_ids`、`status`、`preconditions`、`stimulus`、`accepted_event`、`expected`、`actual_observation`、`checker`、`coverage`、`seed_policy`、`run_command`、`source_files`。`status` 可为 `ready`、`blocked`、`not_implemented` 等；运行结论另外记录，不把清单状态误作测试结果。

| ID | 需求 | 前提 | 激励 | 期待及检查 | 覆盖 | 状态 |
| --- | --- | --- | --- | --- | --- | --- |
| TEST-001 | REQ-001 | TODO | TODO | 通过独立 monitor/RM 比较 TODO | TODO | not_implemented |

## `runs/<run_id>/result.md`

| 字段 | 记录 |
| --- | --- |
| DUT 类型/版本 | 真实 RTL 或替身模型；提交/文件版本 |
| test、seed、配置、时间 | TODO |
| 编译/仿真命令与工具版本 | TODO |
| 退出码与原始日志路径 | TODO |
| 活动计数 | 刺激/接受/执行/返回/预期/实际/比较/mismatch/取消/在途 |
| 覆盖证据 | 原始报告路径与未覆盖项 |
| 结论 | pass / fail / blocked / not_run；仅真实证据支持 pass |
| 残余问题 | TODO |

验收顺序：逐需求查 trace → manifest → 源码检查点 → 编译日志 → test/seed 仿真日志 → 活动计数与覆盖。缺其中一环即明确缺口，不用主观总结填补。
