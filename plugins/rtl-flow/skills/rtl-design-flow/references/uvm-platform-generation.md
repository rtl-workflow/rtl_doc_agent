# 验证平台生成与集成参考

来源：`logic-verify-uvm-platform-gen` v2.0.1 的 `SKILL.md`、`count_u_gen_edges.py` 及平台模板；合并三个 skill 的目录、组件集成、编译与交付约定。BFM 实现见 [BFM 生成参考](uvm-bfm-generation.md)，用例实现见 [用例生成参考](uvm-testcase-generation.md)。

## 1. rtl-flow 接入边界（生成前必读）

rtl-flow 新项目默认采用标准 SystemVerilog/UVM 平台。需求 / 规格 / SSOT 确定功能行为；agent 权限、G3 审核和运行入口确定工作方式。原 skill 的 Gaea/Superbench 特定基类、端口和默认值不能直接覆盖标准 UVM 组件。

```text
dv/
  uvm.yaml                    # 顶层、UVM版本、filelist、测试类映射
  top/dut_if.sv, tb_top.sv     # interface、时钟复位、U_dut、vif、run_test()
  env/env_pkg.sv              # UVM import、按依赖顺序 include 各组件
  env/env_cfg.svh, env.svh    # 配置、组件实例及 TLM 连接
  env/common/                # 公共类型、rtlflow_test_base.svh
  env/trans/                 # transaction
  env/gen/                   # sequence / sequencer
  env/bfm/                   # cfg / agent / driver / monitor，按需 receiver
  env/rm/                    # 独立参考模型
  env/scb/                   # scoreboard
  env/funcov/                # 功能覆盖
  env/ral/                   # 有寄存器时生成 frontdoor RAL / adapter
  tests/                     # 继承公共测试基类的用例
  sim/scripts/tb_list.f       # 有序验证编译单元
  build/                     # runner产物，非源文件
```

`flow.py init` 创建配置、目录、filelist 和公共测试基类，P4 必须根据规格补齐接口、环境和实际用例。初始化骨架本身不能编译或通过验证。标准结构使用 UVM sequencer/driver、analysis port/FIFO 等 API，不依赖未提供的 Gaea/Superbench 基类。

`dv/uvm.yaml` 示例：

```yaml
schema_version: 1
top: example_tb
uvm_version: uvm-1.2
filelist: sim/scripts/tb_list.f
test_map: {}                 # 默认 07 ID == UVM 类名；也可 {tc_read: svf_read}
```

runner 使用 `-sverilog -ntb_opts <uvm_version>`，当前配置支持 VCS 内置选择器 `uvm-1.2`（默认）、`uvm-1.1`、`uvm`（具体版本由 VCS 安装决定）。库缺失应报环境问题，不假装已切换到 IEEE 1800.2 或替换未知专有基类。默认采用 UVM 1.2 可用 API。

filelist 支持 `.sv/.v` 编译单元、`+incdir+目录`、`+define+名称[=值]`、`-f 子清单`；注释使用独立 `//` 行或 `#`。所有路径均相对 dv/，包括子清单中的路径。带空格或带单引号的 define 值需对整个 token 加双引号；不做环境变量展开。header 由 package include，不重复编译。所有项目验证依赖必须位于 dv/ 且不能引用 build/；`uvm_macros.svh` 来自 VCS 库。外部 VIP 先复制到 dv/ 后集成，不能通过 include / filelist 读取 RTL。

07 的仿真用例通过 `+TEST/+SEED` 标识，类名和仿真随机种子通过 `+UVM_TESTNAME/+ntb_random_seed` 传入。test_map 中的键必须存在于仿真计划。TEST 结果和 UVM 开始/完成标记由公共基类输出，完整协议见编码规范 §10。

`run_regress.py --stub` 编译同一 UVM 平台，但以 SSOT 端口桩替换真实 RTL；不读取 RTL 源码。正式回归由编排者在 G3 后执行。变异测试同样使用 manifest 的编译 / 用例 / 结果协议。没有 `dv/uvm.yaml` 的已有项目保留 `dv/tb/*.v` + `+v2k` 入口；manifest 配置无效时直接报错，不悄悄退回旧入口。

tb-engineer 只能用规格、SSOT 和允许读取的验证文件；不能读取 RTL、真实回归报告或通过外部模板绕过隔离。原 skill 的交互选择并入现有任务输入，缺少决定实现的必要信息时交由编排者澄清；已有输入不重复询问。遥测、评分、独立 Todo 门禁、自动调用外部 skill 不迁入此参考。

## 2. 输入与环境理解

默认输入是规格 / SSOT、验证计划、`dv/uvm.yaml` 和组件连接图。继承原模板时才使用 `components_root`、`output_root`、`platform_name`、`platform_type`（1=Superbench，2=Gaea）及选定组件。记录 `dv/` 平台根目录、组件来源 / 版本和类型，不默认选择最新组件或 Superbench。

生成前读取可访问的 env_cfg、dut_cfg、基础测试类、transaction / sequence、env、tb_top 和 filelist，形成：

- 类名、实例名、参数形参、实参来源、virtual interface 与配置传递路径。
- 组件输入 / 输出 port 的名称和数据类型，GEN→BFM、GEN→RM→scoreboard、receiver→scoreboard 等路径。
- 时钟 / 复位、驱动 / 采样顺序、寄存器抽象访问、参考模型的预期来源、终止与清空条件。
- 可用编译工具 / 库、源文件顺序、测试发现机制、桩自检及正式回归入口。

该理解写在 `07_dv_plan.md` §2；细节较多时放 `dv/platform_understanding.md` 并从 §2 引用，不另建一份相互冲突的平台说明。

## 3. 继承 Gaea / Superbench 的平台路径

以下仅用于继承已有 Gaea / Superbench 组件，均相对已识别的 `platform_dir`；新建标准 UVM 工程使用 §1 的结构。继承目录放入 dv/ 后必须提供 manifest，将其入口适配为本文的 filelist 与基类输出协议，不能直接把专有 `.f` 或 tc.list 当作已经兼容。

| 内容 | Superbench | Gaea |
|---|---|---|
| 测试代码 | `tc/` | `tests/` |
| 用例清单 | `tc/tc.list` | `sim/scripts/tc.list` |
| 编译 filelist | `cfg/env.f` | `sim/scripts/tb_list.f` |
| 平台理解的历史位置 | `tc/platform_understanding.md` | `tests/platform_understanding.md` |

源 TC skill 的最后编译步骤把 Gaea filelist 写成 `sim/scripts/env.f`，与其前文和平台 skill 不一致。本参考统一为模板采用的 `tb_list.f`；继承工程必须读取实际入口验证，不能按名称猜文件。

## 4. 组件集成

先固定选择结果，再复制到目标验证目录。只改目标副本，源组件库与 `raw/` 保持只读。保留既有名称；仅把新复制模板的占位名称替换成任务指定名称。

| 组件来源 | 目标与适配要点 |
|---|---|
| TRANS 一级 `.sv` | `env/trans/`；确认 transaction 打包与类型参数 |
| TRANS 下的 GEN 子目录 | `env/gen/`；核对 generator、sequence、cfg 的类名 |
| BFM 目录 | `env/bfm/`；核对 cfg / interface / 模式和端口 |
| RM 目录 | `env/rm/`；规格驱动的参考模型，不为 RM 添加 BFM 的 work_mode |
| SVA 的 `*assert.sv` | UVM 工程的 top include；已 include 的源码避免再次独立编译。原生 TB 用 §10 的监视器检查 |
| FUNC 的 `*fcov.sv` | 适配 `env/funcov/basic_fcov.sv`，保留平台类壳与采样连接 |
| DUT_CFG 的 `*dut_cfg*.sv` | 适配现有模板 DUT cfg，核对实际基类、类名、文件名及 env 引用 |
| DUT_CFG 的 `*ral*.sv` | `env/ral/`；保留寄存器模型原名，核对顶层 block、adapter、map 和配置类引用 |

标准 UVM 工程在 common package / cfg 中管理参数；继承模板时可采用实际 `env/common/glb_dec.sv`（有些工程为 `.svh`）。每个实例的配置参数应唯一，如 `U_BFM_<INSTANCE>_<PARAM>`，多实例不能共享错误的位宽常量。非整型 / 类型参数也要查源声明，不能只处理 int。

组件的 `DATA_TYPE`、`IN_DATA_TYPE`、`OUT_DATA_TYPE` 使用连接图声明的真实 transaction 类型，逐端校验兼容性，禁止统一回退为 `uvm_sequence_item`。实例化参数来自接口规格、连接图和全局参数定义，不猜测类的形参顺序。

## 5. 连接图、work_mode 与广播

节点写明实例与类，例如 `u_gen_a[gen_packet]`；边写明两端 port，例如 `u_gen_a -- "outport --> inport" --> u_bfm_a`。实例名沿用输入；原脚本仅识别 `u_gen_*` / `u_bfm_*`，其他命名须显式建立等价映射，不能为了脚本而给已有对象改名。

默认标准 UVM agent 按配置创建 active/passive 组件，通过 seq_item_port 和 analysis port 连接；不要求实现专有 `work_mode`。继承原 BFM 时才根据图中事务端口边确定其模式，忽略 BFM↔DUT 的信号边。下表是原 `count_u_gen_edges.py` 的判定规则，I / O / M 分别表示该 BFM 的 `inport`、`outport`、`outport_of_drv` 是否有连接：

| I | O | M | work_mode |
|---|---|---|---|
| 有 | 无 | 无 | DRIVER |
| 无 | 有 | 无 | RECEIVER |
| 有 | 有 | 无 | NORMAL |
| 有 | 有 | 有 | NORMAL_WITH_MONITOR |
| 无 | 无 | 有 | MONITOR |
| 有 | 无 | 有 | DRIVER_WITH_MONITOR |

其他组合视为未定义，先检查连接图 / 组件能力；不能以默认 NORMAL 掩盖。记录各端口计数和模式，检查组件的 build / connect 分支是否真正创建并暴露所需 port。原 demo 在 MONITOR 模式下创建 monitor，但其 `connect_phase` 未覆盖该模式的 `outport_of_drv` 赋值；参考副本时应核对并修复目标副本，不能照抄即认定可用。

GEN 一对多时：

1. 按连接图统计每个 GEN 的事务输出目标，排除注释和重复边。
2. 对原模板的单输出 put / peek 结构，目标数 N > 1 时插入 `rm_broadcast_for_gen`：GEN.outport → broadcast.inport → outport[0..N-1] → 各目标。
3. 在 env_cfg 中设 `outport_num=N`，广播的 transaction 类型与 GEN 一致。
4. 核对广播的对象所有权；下游会修改事务时必须有独立副本，避免同一对象被不同路径互相污染。已有支持广播的 analysis 接口按其实际 API 处理，不重复叠加适配器。

在已有模板 env / env_cfg 内完成实例、配置、连接修改，移除图中未使用的 demo RM / GEN / BFM。BFM↔DUT 的信号接线在 tb_top / interface 中实现，不放入 env 的事务连接；只使用 DUT 顶层端口。

## 6. 完成平台适配

1. 将模板测试目录中的 `gen_temp`、`gen_temp_sequence`、`gen_temp_cfg` 精确替换为对应组件。多个 GEN 按引用所属实例逐一映射，不能全局替换成一个类；按平台类型同时检查 `tc/` 或 `tests/`。
2. 在 tb_top 添加实际 interface / BFM 信号连接与配置传递，移除无用模板接线。
3. 仅清理本次生成副本中、连接图未使用且无引用的 `gen_temp` / `bfm_temp` / `rm_temp`；不得删除已有用户组件。
4. DUT cfg 替换后同步真实文件、类名、env 和 filelist；确认原 demo cfg 已无引用再清理。RAL 保留其源名称。
5. 从最新 filelist 增量更新；按真实依赖排序，参考顺序为 common → ral → trans → gen → rm → bfm → funcov → dut_cfg → env → top。路径按消费者的解析基准验证，不假定每个工具都相对 filelist 所在目录。
6. 需要替换 demo 平台名时同步目标副本中的文件名、类名、include、filelist 和配置引用；不得把用户既有名称当占位符改写。
7. 搜索目标副本中遗留的 demo / temp 引用、缺失文件、重复编译项和未接 port，逐项说明保留原因或修复。

## 7. 编译、自检与交接

默认 UVM 平台及旧 Verilog TB 的运行输出、采样和桩检查规则统一维护在 [rtl-coding-style.md §10](rtl-coding-style.md#10-断言与-testbench) 及 tb-engineer 角色中。统一通过 run_regress.py 执行，不重复采用源 skill 的 UVS 编译命令。

标准工程：先加载 UVM 库，编译 interface，再编译 env package（按 common → trans → cfg → gen/bfm → rm/scb/funcov → env → test 的实际依赖 include），最后编译 tb_top。继承 Gaea/Superbench 时，还需先提供 `glb_dec.sv` 的模式与基础类型，再编译依赖它的 BFM / env。以真实依赖为准，不能套顺序造成重复编译或引用未定义。

- 缺少 `if_vip_work_mode`：检查 glb_dec 的位置和作用域；缺少 UVM 类型 / 宏：检查库、import / include 所属编译单元，不能机械删除它们。
- BFM port 不存在：检查 work_mode、build / connect 分支与连接图。
- 找不到 `gen_temp_sequence`：检查实际测试目录中的 GEN 替换与编译清单。
- RM 无 work_mode：移除误套的 BFM 配置；DUT cfg 编译失败：核对实际文件名、基类和 filelist。
- 通过本地静态检查不等于通过仿真器编译；通过编译不等于通过功能验证。明确分别记录状态。
- 记录命令、工具 / 库版本、退出码、日志位置和未解决错误。修复循环遵循 rtl-flow 的最多 3 轮约定，工具 / license / 远端环境错误按 blocked 上报。

交接列出环境结构、组件与模式、接口时序、测试与覆盖范围、静态检查 / 桩自检证据、未验证项。完成后等待 G3；验证内容变更需重新审核，只有编排者可运行正式回归和填写审核字段。

## 8. 原 skill 工具的迁移说明

rtl-flow 已提供标准 UVM 初始化模板、manifest/filelist 解析、编译 / 回归 / 桩检查入口；未安装原脚本、专有 demo 或 `logic-verify-uvs-remote-compile`。不应调用 `$SKILL/scripts/` 下并不存在的原 skill 同名脚本。原工具职责已在本文展开：

| 原工具 | 对应规则 |
|---|---|
| `create_bt_platform.py` / `list_components.py` / `find_files.py` | 选择平台、固定组件来源、复制目标副本（§2–4） |
| `count_u_gen_edges.py` | 连接计数、BFM 模式、GEN 广播（§5） |
| `dut_cfg_apt.py` / `ral_apt.py` / `fun_apt.py` | 配置、寄存器模型、功能覆盖适配（§4、§6） |
| `bt_rename.py` 及类名 / 文件名辅助脚本 | 目标副本内占位名称同步（§6） |

如果项目已提供这些工具，可在确认输入与输出范围后使用；仍需检查实际代码和结果。缺少专有基类 / VIP / 库时应列明依赖，不能以本文代替依赖并宣称平台可编译。
