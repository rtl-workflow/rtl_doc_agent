# BT UVM 可执行门禁（首版）

运行环境：Python 3.10+ 标准库；在解压后的包根目录运行 `python -m bt_uvm --help`。若系统 `python` 是 Windows Store 占位符，用实际 Python 可执行路径。`bt_uvm` 不安装 SV 编译器，也不生成真实 DUT/UVM 平台；生成源码由 agent 按主入口流程完成。历史判定器源文本已移出发布树，不是此CLI的依赖。

## 已选后端与当前实现

目标部署采用 [SSH transport + 仿真器 profile](ssh-backend-contract.md)，具体仿真器尚未确定。下文命令仍是当前本机执行接口；配置示例不会自动启用 SSH。现有 `run` 不强制消费前置 static gate 回执，必须显式运行和审查各项门禁；后续编排器才负责绑定全链路证据。

## 输入契约

静态门禁读取 JSON，不执行不修改被检查文件。所有 `--contract`、`--plan` 应由设计评审者批准并在生成者**不可改**的目录维护；若由生成者自行编写，匹配只能证明自洽，不能证明批准。完整字段参考 `bt_uvm/static_gates.py` 函数 docstring 和 `tests/test_static_gates.py` 的正反例。最小示意：

```json
{"dut":{"name":"unit","top":"unit_top"},"requirements":["R1"],"interfaces":[{"name":"req","direction":"input"}],"features":["F1"],"components":[{"id":"monitor","kind":"monitor","path":"tb/monitor.sv"},{"id":"checker","kind":"checker","path":"tb/checker.sv"}],"connections":[{"from":"monitor","to":"checker","role":"actual"}],"design_sha256":"<64位真实十六进制摘要>"}
```

`plan.json` 需有 `features` 列表，以及 `tests`：每条至少有 `name/type/source_id/features/seeds/kind`，其中 `kind` 为 `data`、`reject` 或 `reset`。manifest 按计划精确对齐并补 `preconditions/stimulus/expected/monitor/checker/coverage/run_command`。`design.json`、`ir.json`、`platform.json` 使用结构化字段，不能用 Markdown 中含关键词代替。

## 使用步骤

```powershell
$py = 'C:\path\to\python.exe'
& $py -B -m unittest discover -s tests -p 'test_*.py' -v
& $py -B -m bt_uvm static design --input design.json --contract contract.json
& $py -B -m bt_uvm static ir --input ir.json --contract contract.json
& $py -B -m bt_uvm static platform --input platform.json --contract contract.json --project . --design design.md
& $py -B -m bt_uvm static manifest --input manifest.json --contract plan.json
```

`static platform` 除声明检查外，独立测量 `design.md` 与各 `components[].path` 的 SHA-256。设计文件必须在项目根内；通过不代表实际 SV 接线正确或编译通过。

创建 `compile-command.json`，内容是编译器命令参数数组，如 `["uvs","-sv","-filelist","dv/sim/filelist.f",...]`；必须是真正编译用户 DUT 的命令，不能用 `echo` 替代。针对每个批准的 test/seed 运行：

```powershell
& $py -B -m bt_uvm run --project . --runs-dir runs --read-only rtl spec plan.json --plan plan.json --compile-json compile-command.json --test sanity --seed 1 --kind data --dut real --timeout 120 -- uvsim +UVM_TESTNAME=sanity +ntb_random_seed=1
& $py -B -m bt_uvm aggregate --plan plan.json --runs-dir runs
```

`run` 先编译后运行；编译失败不启动仿真。每次创建唯一目录，存 `compile.log`、`compile.err`、`stdout.log`、`stderr.log`、`run.json`，比较只读文件前后散列，并把输入计划摘要绑定到结果。CLI 非 pass 退出码为 1。`aggregate` 要求每个计划 test/seed 唯一且通过；额外、重复、缺失、旧计划或缺 `run.json` 的目录都会失败。若需单独重判：`python -m bt_uvm evaluate --run-dir runs/<id> --test sanity --seed 1`。

仿真须在 stdout/stderr 输出独立行 `BT_TEST_PASS <test>`，以及每项一次的 `BT_METRIC <name>=<nonnegative integer>`：`stimulus/accepted/executed/returned/expected/actual/compared/rejected/cancelled/outstanding/mismatch/coverage_samples`。这些指标需由真实 monitor、RM、scoreboard 和 coverage 组件各自提供，不能在命令包装脚本里凭空打印。`data` 要求真实执行与比较；`reject` 要求拒绝且无执行；`reset` 要求取消；所有类别检查接受=返回+取消+拒绝、无未结算和 mismatch。输出格式/计数语义是集成契约，不是已有任何 UVM 平台自动支持的日志格式。

## 能力边界（必须如实声明）

- 此执行器当前是**检测式只读**：对给定路径做前后散列，不能阻止中途修改后恢复，不能阻止未列入路径的文件被修改；同权限的进程可改证据、计划或代码。真实强制只读需要独立账号/容器/只读挂载及受保护的日志与批准计划。
- `--dut real` 是调用者的声明；编译命令、真实 RTL 身份及测试指标可被同权限的不可信运行者伪造。结果 `status=pass` 表示**给定证据符合本地合同**，不是经过独立硬件验证机构认证。可信部署须由独立执行服务固定 RTL 摘要、工具/命令、计划版本和证据写权限，并审查编译 log 和二进制产物来源。
- 当前静态门禁是结构验证，不替代 SV 解析、lint、elaboration、运行语义及覆盖充分性；`coverage_samples>0` 不等于达到覆盖目标。故障注入、真实 EDA 集成、RTL/UVM 实测尚未完成。
- 计划不能将 blocked/N/A 项偷偷移出分母；批准计划一旦变更，必须重新运行，人工审查其变更理由。
