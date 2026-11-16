---
name: logic-verify-uvm-platform-gen
skill_id: logic-verify-uvm-platform-gen
description: 由验证平台总agent调度，基于批准组件与连接合同集成legacy Superbench/Gaea UVM平台；包含安全骨架创建器和未完成通用化的集成辅助脚本。
version: 2.1.0
---

# UVM 平台集成子技能

## 调度与权限

本技能归属 [验证平台总agent](../SKILL.md)，读取其批准的项目范围、组件清单、连接合同、UVM库版本和SSH profile。已有选择直接复用，不重复询问评分、组件或模式；只将影响正确性的缺失事实报告给总agent。总agent统一维护任务清单、源文件只读边界、证据和最终结论。

不调用运营遥测、不要求用户评分、不静默上传摘要、不安装依赖。此子技能只在本地获准的新输出目录创建和集成源码；远端编译/仿真交给总agent使用已审核SSH及仿真器profile。工具未选定时完成允许的生成并报告 `not_run`，不得默认UVS或运行模板中的shell/Makefile。

## 能力与版本边界

| platform_type | framework_profile | 模板 |
| --- | --- | --- |
| 1 | legacy_superbench | `references/platform_demo/superbench_demo/superbench_demo` |
| 2 | legacy_gaea | `references/platform_demo/gaea_demo/gaea_demo` |

模板配置默认UVM1.1，带旧EDA路径、SUPERBENCH/CCL及其他外部项目依赖；尚未验证IEEE1800.2兼容性。总agent必须冻结实际 `uvm_version/library_identity/framework_profile/simulator_profile`，不得仅改标签宣称升级。标准factory/config_db/TLM机制可复用，项目GEN/BFM/RM/work_mode约定不是UVM强制规范。

创建器只复制骨架，不能根据自然语言生成协议行为。driver/monitor/RM中的注释占位、空DUT接线、零活动可通过的旧report/scoreboard判据**仍未修复**。不得以骨架创建、零error日志或模板旧OK作为真实DUT通过。

## 输入与输出

输入：`components_root`、`output_root`、`platform_name`、`platform_type`，以及总agent已批准的组件版本、类/参数/TLM端口、事务类型、连接图、信号驱动者、clock/reset和DUT边界。四个基础路径参数不足以完成接线；schema见 [manifest](manifest.yaml)。

输出合同 `bt-platform-result/v1`：`status` 为 scaffold_created/integrated/blocked/failed；含platform_path、framework_profile、uvm_compatibility、compile_status、simulation_status、artifacts（相对路径及SHA-256）和errors。创建器仅产生scaffold_created/failed，`uvm_compatibility=unverified_legacy`，编译/仿真均为not_run。`integrated`由总agent完成源代码集成和静态审查后生成；必须重新测量最终源码摘要。编译和仿真证据另存，不能将此结果改成pass。

## 1. 创建唯一输出

```text
python scripts/create_bt_platform.py --template_dir references/platform_demo --output_root <approved_output_root> --bt_index <1|2> --p_name <platform_name>
```

- 名称只能为ASCII标识符，拒绝Windows设备保留名、路径分隔符、绝对路径及空字符串。
- 输出为 `output_root/BT_PLATFORM/<timestamp>_<unique>/<platform_name>`；使用原子唯一目录分配，不重用同秒目录。
- 禁止输出到模板内部；检查输出containment，拒绝符号链接/Windows reparse point以及模板中的特殊文件。
- 不删除、不覆盖既有路径，不合并复制。保留模板字节（不对二进制/缓存作全局换行替换）。
- stdout为结构化JSON，失败退出非零。复制失败可能留下新attempt供诊断，不能将其视为完成或删除其他attempt。
- 这是本地防误操作边界，不抵抗同权限恶意并发替换；不在其他进程可任意改写的目录运行。

## 2. 冻结组件与连接

可用 `scripts/list_components.py` 辅助列组件；修改时间排序只是展示，不是批准版本。按总agent选择记录版本和摘要，不自动挑“最新”。

| 来源 | 集成位置/用途 |
| --- | --- |
| BFM | `env/bfm`，驱动/观测与virtual interface |
| TRANS | 一级事务文件到`env/trans`；已确认GEN子组件到`env/gen` |
| RM | `env/rm`，独立expected预测与实际观测分离 |
| SVA | 顶层绑定/include，按具体filelist避免重复编译 |
| FUNC | `env/funcov`，覆盖采样与目标 |
| DUT_CFG/RAL | 配置对象、寄存器模型及adapter，不能默认CBUS适用 |

连接必须记录实例class、参数、source/target port及事务类型。不得将类型静默回退成 `uvm_sequence_item`。Mermaid只作展示/辅助输入；`count_u_gen_edges.py`是有限正则解析器，存在支持语法与实际解析不一致的限制，不能作为唯一正确性来源。总agent复核结构化连接与脚本结果；不保留未经证实的work_mode默认值。保留连接输入和摘要，不删除唯一来源。

GEN一对多可用已有broadcast组件，但须确认各分支语义，设置正确outport_num和数据类型；不能将复制刺激当成DUT独立观测。

## 3. 集成与适配

仅编辑新attempt中的源文件，禁止改components_root、批准RTL或本技能模板。

1. 复制已批准组件，按真实class形参实例化；参数宏按实例唯一命名。
2. 修改env/env_cfg：build/create、config_db、连接、active/passive/work_mode；BFM与DUT信号连接放在顶层，不放env。
3. 修改顶层：virtual interface、clock/reset、DUT端口、单一驱动者与采样时序。接口方向基于批准合同，不按名称猜测。
4. 替换GEN及用例引用；Superbench用例目录为`tc/`，Gaea为`tests/`。先查真实class/factory/文件名，不能只批量替换字符串。
5. 只在新attempt内清理确认不再引用的gen_temp/bfm_temp/rm_temp；删除前核对绝对路径、源文件引用和摘要。不得清理组件库或旧attempt。
6. 更新filelist：Superbench为`cfg/env.f`，Gaea为`sim/scripts/tb_list.f`；按实际package/类型依赖排序，通常common→ral→trans→gen→rm→bfm→funcov→dut_cfg→env→top，不能机械套顺序。RAL名称保持其真实定义；SVA的include与filelist只能按真实编译组织去重。
7. 重新扫描未定义类型、遗留demo引用、重复驱动、未连接端口、reset清理和空行为；形成最终artifacts摘要。

## 辅助脚本限制（不得视为已加固总入口）

- `create_bt_platform.py`已加固并有标准库测试；仅做创建。
- `bt_rename.py`全目录替换/改名、`dut_cfg_apt.py`类体拼接及强制LVP基类、`ral_apt.py`正则选顶层、`fun_apt.py`类体替换仍是legacy辅助工具，部分错误路径不可靠传播非零状态。
- 本轮未修改这些辅助脚本。不要强制无条件执行；总agent应优先按合同定点编辑新attempt。如选择使用，必须先确认目标在本次输出、输入和语法符合受限范围，并检查实际产物和编译证据，不能只信退出0或“完成”文字。
- 不把正则解析当作SV AST，也不假设extern方法、factory、多个顶层类会被正确迁移。

## 4. 编译交接与完成定义

将最终filelist、源码摘要、框架/UVM版本、依赖清单和未决问题交给总agent。总agent通过已审核SSH profile调用实际仿真器，保留原始stdout/stderr/退出码、工具版本和编译产物摘要；未配置时blocked/not_run。任何编译后源码修改必须重编译。

集成完成只说明批准组件已落实到文件和连接；编译完成必须有真实工具证据；真实DUT验证仍需要有效刺激、独立monitor/RM/scoreboard比较、排空、覆盖和故障注入。旧testcase_ok和0==0计数不是验收依据。

本次开发测试（从总agent根目录）：

```text
python -B -m unittest discover -s tests -p test_platform_creation.py -v
```

测试使用临时目录和最小虚拟模板，验证路径/覆盖/证据状态，不执行EDA或证明192个SV模板已修复。
