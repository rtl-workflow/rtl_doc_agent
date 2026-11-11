# {{ip}} UVM 验证平台

本目录由 P4 的 tb-engineer 根据规格与 SSOT 完成。初始化仅提供运行配置、目录和公共测试基类；尚未生成 DUT 接口、环境或功能用例，不能视为可编译或验证通过。

```text
dv/
├── uvm.yaml                  顶层、UVM 版本、filelist、用例类映射
├── top/dut_if.sv              时钟 / 复位、信号、clocking block / modport
├── top/tb_top.sv              {{ip}}_tb，例化 U_dut、传递 vif、run_test()
├── env/env_pkg.sv             import UVM，按依赖顺序 include 各组件
├── env/env_cfg.svh            环境配置
├── env/env.svh                实例化并连接各组件
├── env/common/               公共定义与 rtlflow_test_base.svh
├── env/trans/                transaction
├── env/gen/                  sequence / sequencer
├── env/bfm/                  agent / cfg / driver / monitor / receiver
├── env/rm/                   独立参考模型
├── env/scb/                  预期 / 实际结果比对
├── env/funcov/               功能覆盖
├── env/ral/                  有寄存器时的 RAL / adapter
├── tests/                    派生测试类，每个用例一个文件
├── sim/scripts/tb_list.f      有序编译单元与 include 搜索目录
└── build/                    自动生成的自检 / 回归产物
```

缺少的组件由 agent 实现；按需求不使用的 RAL 等目录可为空。不引入没有提供的 Gaea / Superbench 专有基类。

用例继承 `rtlflow_test_base`，保留其 run / start_of_simulation / final phase 协议，在 `execute_test()` 中完成激励、等待 scoreboard 清空和结束检查，在 `report_coverage()` 中输出真实 COVER 命中。配置 watchdog 应在调用基类 build_phase 前完成。其他 phase 如重写须调用 super。默认用例类名等于 07 中的测试用例 ID；已有类名通过 uvm.yaml 的 test_map 映射。

filelist 支持 `.sv/.v` 编译单元、`+incdir+路径`、`+define+名称[=值]`、`-f 子清单`。所有路径相对 dv/，不使用环境变量；有空格时对整个 token 加双引号。headers 通过 package include，不重复列为编译单元。DUT RTL 只由 runner 从 SSOT 加入；验证 filelist / include 不能逃出 dv/ 或引用 build/。源码中 UVM 宏由 VCS 库提供。

自检：`python $SKILL/scripts/run_regress.py <ip_dir> --stub`。用 SSOT 端口桩替换 RTL，并定义 RTLFLOW_STUB；允许功能比对失败，但 UVM_FATAL、超时、选错用例、缺少完成标记均失败。不得用该宏关闭 testcase、driver、monitor 或 scoreboard 来伪造自检通过。

真实回归由编排者在 G3 后执行同一命令并去掉 --stub。零进程退出码不代表通过：必须完整运行所选用例、无 UVM_ERROR / UVM_FATAL、有功能覆盖计数，且所有检查通过。详细步骤与需求追溯维护在 doc/07_dv_plan.md。
