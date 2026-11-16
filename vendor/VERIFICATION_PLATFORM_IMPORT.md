# Verification platform generator：导入记录与接入边界

本目录保存用户提供的同事资产包 `verification-platform-generator` 1.0.0-rc.1 的完整快照。用户在本次 PR 整理中明确要求将源码、模板及内部规则一并复制到仓库。

- 原始快照：[verification-platform-generator](verification-platform-generator/README.md)。
- 完整文件清单及 SHA-256：[manifest](verification-platform-generator.manifest.json)。
- 源包共 347 个文件，2,731,928 字节；最终导入 346 个文件，2,712,225 字节。源码、模板和内部规则全部保留。除下述两项外，导入文件与来源字节相同。
- 排除生成的 `logic-verify-uvm-platform-gen/references/platform_demo/superbench_demo/superbench_demo/sim/.project_env.mk`：包含历史内网地址、许可证端点和会话环境；其 Makefile 引用本身为存在性条件包含。
- 仅移除 BFM Excel 样表 `xl/workbook.xml` 中记忆的个人绝对目录元数据；保留 19 张工作表，其他 113 个 ZIP 部件逐字节一致。manifest 记录修改前后摘要和原因。
- 模板保留 `/home/public/cshrc`、`/eda` 等站点工具安装示例，不包含可用的工具安装环境；使用时应根据实际站点配置。
- 原版权头、作者署名、权利说明及发布元数据全部保留，不改写为 MIT/Apache 等许可证，不以此记录替代原权利人的许可。
- 原包的 [RIGHTS.md](verification-platform-generator/RIGHTS.md) 和 [release.json](verification-platform-generator/release.json) 仍记录 `redistribution_rights_unresolved` / `public_release_ready=false`。这是来源快照的声明，用户此次复制指示不被改写成已核验的权利人许可证。合并者应明确知悉这一状态。

## 包含哪些内容

| 路径 | 内容 | 使用条件 |
|---|---|---|
| `agent/`、`bt_uvm/`、`tests/` | 总 agent 注册、资产检查、发布工具、本地证据门禁和测试 | Python 3.10+；与 rtl-flow 的 Python 3.8+ 基础要求分开 |
| `logic-verify-uvm-bfm-gen/` | BFM 生成说明、schema、Excel 样表 | 核对接口方向、时序、真实平台类型；Office 依赖按需准备 |
| `logic-verify-uvm-platform-gen/` | 平台辅助工具、Gaea/Superbench 模板及公共组件 | legacy 外部库和工具未随包全部提供，不保证可直接编译 |
| `logic-verify-uvm-tc-gen/` | 测试点处理、用例生成、输入输出合同和规则 | 适配实际平台 API；保留全部测试点及批准排除记录 |
| `rtl-gen/` | RTL 生成规则和辅助资料 | 仅设计角色使用；不得交给黑盒 tb-engineer 作为 RTL 实现输入 |
| `references/`、`assets/` | 组件合同、运行证据约定、状态和 SSH 配置模板 | SSH 后端合同不是可执行适配器，不把禁用示例当真实部署 |

## 接入 rtl-flow

此包保存在仓库根的 `vendor/`，保持原包独立可检查；不注册第二个主编排者，不自动执行模板中的 shell、构建器或网络命令。通过插件缓存只安装 `plugins/rtl-flow/` 的用户可能看不到本目录，需要完整仓库 checkout 才能使用这些可选资产；基础 RTL 流程不依赖它们。

1. 使用 `flow.py` 作为唯一流程状态机；需求/规格/SSOT、07 验证计划与 G0–G3 审核仍是项目事实及授权来源。
2. 原包总 agent 的“读取 RTL”步骤不能覆盖 rtl-flow 的黑盒边界。设计/接口提取角色可读取允许范围内的 RTL，冻结接口合同后交给 tb-engineer；不得把设计上下文或真实回归报告直接交给验证角色。
3. 组件实现前从原包合同中补齐类型、端口、配置路径、采样事件、复位和结束条件。不要把文档要求当作已有代码实现；空 driver/monitor/scoreboard 仍为骨架。
4. legacy Gaea/Superbench 只用于显式选定的继承工程。其 `tc.list`、filelist、UVM 库和运行目录必须按实际源文件核验；不能覆盖 rtl-flow 标准 `dv/` 结构或混用默认 UVM 1.2 与 IEEE 1800.2 标签。
5. 原 `bt_uvm` 的 `BT_TEST_PASS`/`BT_METRIC` 与 rtl-flow 的 `TEST`/`RTL_FLOW_METRIC` 是不同协议。无需同时运行两个 runner。采用本 PR 的 [证据增强协议](../plugins/rtl-flow/skills/rtl-design-flow/references/verification-evidence.md) 时，由实际组件输出新协议；需要单独运行原 CLI 时，使用独立结果目录并分别说明结论范围。
6. 原包 `rtl-gen` 的内部规范仅作明确选择的项目参考，不自动覆盖 rtl-flow 原名保留、SSOT 或编码规则。发生冲突先记录并澄清，不静默重命名。

具体可用命令和局限以原包 [README](verification-platform-generator/README.md)、[RELEASE](verification-platform-generator/RELEASE.md) 和 [能力地图](verification-platform-generator/references/capability-map.md) 为准。所有外部依赖都须按实际项目配置；复制完整资产不等于已经完成 UVM/EDA 验收。

## 维护与校验

在 `vendor/verification-platform-generator/` 内使用 Python 3.10+：

```text
python -B -m agent.doctor
python -B -m unittest discover -s tests -p test_*.py
```

`agent.doctor` 仅检查资产和注册表。本地测试不等于真实 RTL 仿真。打包器会保留原始权利状态，不要通过修改标志绕过来源声明。

Windows 完整 checkout 路径较长时，legacy 模板可能超过传统 MAX_PATH；Git 可为这个 checkout 设置 `core.longpaths=true`，或把仓库克隆到较短路径。源快照按 `.gitattributes` 禁用自动换行转换，确保 Git 中字节与 manifest 一致。Python/工具不支持长路径时优先使用短 checkout，不扁平化模板目录破坏相对引用。

后续若修改导入资产，应保留原始来源信息，明确记录修改内容并更新 manifest；不要把改过的文件继续声称为原始快照。
