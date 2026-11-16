# 模板结构与构建清单链

以下路径均基于包内实际文件静态核对；没有执行VCS、runvcs或编译脚本，不能据此宣称模板已编译。`platform_type`与创建器的`--bt_index`一致：**1=Superbench，2=Gaea**。框架标识分别为legacy_superbench和legacy_gaea。

## 两套工程的实际位置

模板复制源分别为 `platform_demo/superbench_demo/superbench_demo` 和 `platform_demo/gaea_demo/gaea_demo`（相对本references目录）。工程内关键文件如下：

| 项目 | Superbench (1) | Gaea (2) |
| --- | --- | --- |
| env | `env/superbench_demo_env.sv` | `env/gaea_demo_env.sv` |
| env_cfg | `env/superbench_demo_env_cfg.sv` | `env/gaea_demo_env_cfg.sv` |
| DUT配置 | `env/superbench_demo_dut_cfg.sv` | `env/gaea_demo_dut_cfg.sv` |
| BFM接口 | `env/bfm/bfm_temp/src/bfm_temp_intf.sv` | 同左 |
| BFM行为 | 同目录bfm_temp_driver/monitor/receiver.sv | 同左 |
| GEN/RM | `env/gen/gen_temp/src`、`env/rm/rm_temp/src` | 同左 |
| coverage/RAL | `env/funcov/basic_fcov.sv`、`env/ral` | 同左 |
| 顶层 | `top/tb_top.sv` | `top/tb_top.sv` |
| 平台filelist | `cfg/env.f` | `sim/scripts/tb_list.f` |
| 用例目录/可扩展清单 | `tc/`、`tc/tc.list` | `tests/`、`tests/tc.list` |
| 附加基础类清单 | 按现有工程引用核对 | `sim/scripts/tc_list.f` |
| 回归/工具配置 | `cfg/regress_list.py`、`cfg/project.ini` | `sim/scripts/runvcs`、`sim/scripts/sim.cfg` |

两套实际接口均叫bfm_temp_intf.sv，不存在原说明中的bfm_temp_driver_intf.sv。Superbench平台filelist不是cfg/tb_list.f，Gaea工程也不带原说明混入的Superbench cfg树。

## Gaea：真实启动及工作目录

以下链接指向模板证据，行号以本次静态检查为准：

1. [runvcs](platform_demo/gaea_demo/gaea_demo/sim/scripts/runvcs)第47–56行先查找并source当前目录的sim.cfg。因此模板预期从工程 `sim/scripts` 启动，而不是工程根目录直接运行。
2. [sim.cfg](platform_demo/gaea_demo/gaea_demo/sim/scripts/sim.cfg)第12–15行定义script_path=../scripts、tests_dir=../../tests、filelist=`-f ../scripts/tb_list.f -f ../scripts/dut_list.f`。
3. runvcs第530–531行从tests_dir查找指定用例；第598–612行创建并切换到 `sim/<case_id>`，指定suffix则为 `sim/<case_id>.<suffix>`。第921–952行在该目录调用VCS，展开filelist，并另外传入test_dir；第979行开始调用simv。
4. 因而编译时顶层 `-f ../scripts/tb_list.f` 指向工程的sim/scripts/tb_list.f；清单里的普通相对路径须结合编译cwd理解，不能简单认为所有条目相对filelist。

## Gaea：保留的用例清单链

[tb_list.f](platform_demo/gaea_demo/gaea_demo/sim/scripts/tb_list.f)第64–65行同时引用：

```text
-F ../../sim/scripts/tc_list.f
-F ../../tests/tc.list
```

- [tc_list.f](platform_demo/gaea_demo/gaea_demo/sim/scripts/tc_list.f)现有内容为 `../../tests/basic_tc.sv` 和 `../../tests/svf_sanity/svf_sanity.sv`。这是现有基础类/样例链；TC生成不能把它误当不存在的sim/scripts/tc.list、替换为仅包含新用例的文件，或删除该引用。
- [tests/tc.list](platform_demo/gaea_demo/gaea_demo/tests/tc.list)现有顺序为tc_define.sv、basic_tc.sv、svf_sanity/svf_sanity.sv、tc_undef.sv。**新增用例的映射为tests/tc.list**；保留已有包装/基础条目，将新条目登记在tc_undef.sv前并按目标构建规则核对相对路径。
- `sim/scripts/tc.list`不在该模板中。`tc_list.f`与`tc.list`不是可互换的名字。

## 仍需项目构建适配的legacy限制

- 文件存在不等于路径解析正确。VCS的`-f`与`-F`对相对路径处理不同；这里顶层用-f、嵌套用-F，而tc_list.f仍使用../../tests前缀。必须在选定工具profile上核对展开结果；本次不改这些脚本或宣称正确可编译。
- basic_tc与sanity在两个清单中重复出现，runvcs还把test_dir直接加入编译命令，存在重复编译风险。保留原链并将问题报告总agent；未经审核不得以删基础类清单“修复”。
- tb_list.f第8–12行引用的 `../LVP/...` 及sim.cfg中的公共环境脚本/旧工具版本需要环境核验；不由TC自动制造库文件或改路径。
- runvcs还把tc_list.f用于`-list`与数字用例选择（第243–254、364行），用途与源码清单混杂。新增测试应使用经审核的工具profile及实际类名，不把这个遗留菜单行为当可靠用例注册器。
- 原启动脚本含清理旧产物行为。发布说明仅记录事实，不授权自动运行；实际SSH执行应使用总agent审核的唯一attempt与日志保留策略。

若项目另有已验证构建入口，优先复用并显式记录映射、cwd、-f/-F语义和依赖，禁止只改文档假设便报告编译通过。
