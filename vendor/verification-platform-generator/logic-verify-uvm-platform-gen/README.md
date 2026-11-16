# logic-verify-uvm-platform-gen 2.1.0

本包是[总agent](../SKILL.md)调用的UVM平台集成子技能。现有实现包含**安全骨架创建器、legacy Superbench/Gaea模板和局部辅助脚本**；组件行为、env/env_cfg、顶层连接及最终filelist仍由agent依据批准合同完成。不是自然语言到完整平台的独立自动生成器。

## 能力与输入

| 输入 | 含义 |
| --- | --- |
| components_root | 已批准的TRANS/BFM/GEN/RM/SVA/FUNC/DUT_CFG/RAL组件及版本 |
| output_root | 获准的新输出根目录 |
| platform_name | ASCII标识符；创建器额外拒绝设备保留名及路径 |
| platform_type | 必须明确：1=Superbench，2=Gaea |

集成还需要真实的组件class/参数/TLM类型、连接合同、DUT端口、clock/reset、驱动方向及UVM库身份。Mermaid可供展示与辅助解析，不能替代类型化连接检查。详细步骤以[子技能入口](SKILL.md)及[manifest](manifest.yaml)为准。

## 骨架创建与agent集成

```text
python scripts/create_bt_platform.py --template_dir references/platform_demo --output_root <approved_output_root> --bt_index <1|2> --p_name <platform_name>
```

创建器产生唯一 `BT_PLATFORM/<timestamp>_<unique>/<platform_name>` 目录，拒绝越界/链接及覆盖既有目标，输出文件SHA-256清单。其结果为 `scaffold_created` 或 `failed`，编译和仿真均为 `not_run`；没有自动集成components_root或自动生成协议行为。

总agent随后集成组件、修改env/env_cfg与top、更新filelist、检查遗留模板引用并重算摘要，才可给出 `integrated`。`bt_rename.py`、`dut_cfg_apt.py`、`ral_apt.py`、`fun_apt.py`等legacy工具仍有正则处理及失败传播局限，不能无条件执行或只看退出0。

## 模板与执行边界

- [模板结构与真实清单链](references/template_structure.md)给出正确平台编号、接口文件及Gaea编译工作目录。Gaea新增用例登记在 `tests/tc.list`；保留 `sim/scripts/tc_list.f` 的基础类链。
- 模板默认UVM1.1，包含旧EDA路径和外部项目库，尚未验收IEEE1800.2兼容性；部分driver/monitor/RM仍有占位行为。
- 本包没有内置远程编译器，不再依赖固定的UVS技能。编译/仿真交总agent按[SSH合同](../references/ssh-backend-contract.md)和已审核工具profile执行；SSH适配器尚未实现，具体仿真器未定。
- 工具缺失时交付源码与阻塞项。保留原始日志及失败attempt，源码变化后必须重新编译。骨架创建、零错误或模板旧OK均不证明DUT通过。

## 文件导航

- [SKILL.md](SKILL.md)：总agent调用流程和边界。
- [manifest.yaml](manifest.yaml)：2.1.0输入输出合同。
- [模板结构](references/template_structure.md)：两套legacy工程及构建引用证据。
- [创建器](scripts/create_bt_platform.py)：唯一目录、拒绝覆盖、结构化骨架回执。
- scripts中的其他工具：组件发现、边数统计、类名/文件名/配置适配；使用前按入口说明逐项审查。

发布包不包含自动遥测或评分流程。测试命令为从总agent根目录执行 `python -B -m unittest discover -s tests -p test_platform_creation.py -v`；测试仅证明创建器文件操作，不证明模板真实编译或仿真通过。
