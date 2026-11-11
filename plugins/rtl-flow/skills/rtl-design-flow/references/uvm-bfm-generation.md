# BFM 生成参考

来源：`logic-verify-uvm-bfm-gen` v2.0.0 的 `SKILL.md`、`references/prompt_templates.md`，以及平台 skill 的 `bfm_temp` 结构。本文整理接口分析、驱动、采样和组件交付规则；平台接线与编译依赖统一见 [平台生成参考](uvm-platform-generation.md)，测试场景见 [用例生成参考](uvm-testcase-generation.md)。

## 1. 适用方式与输入

在生成或修复 driver、monitor、receiver、接口激励任务时阅读。rtl-flow 默认使用标准 SystemVerilog/UVM，BFM 位于 `dv/env/bfm/`，interface 位于 `dv/top/`，通过 manifest/filelist 接入 runner。语法、clocking block / 采样调度、公共基类与自检协议遵循 [rtl-coding-style.md §10](rtl-coding-style.md#10-断言与-testbench)。没有 manifest 的旧 Verilog 项目仅复用协议建模方法，不直接加入 UVM class。

先形成接口契约，写入 `07_dv_plan.md` §2 或其引用的 `dv/` 说明：

| 输入 | 要提取的内容 |
|---|---|
| 接口表 / Excel / Markdown / JSON | 信号原名、方向、位宽、参数、功能、有效条件；明确 I/O 是 DUT 视角还是 BFM 视角 |
| WaveDrom / 时序描述 | 时钟、复位极性、采样沿、握手条件、背压、SOP/EOP、空闲值、复位中断行为 |
| 补充说明 | 字节序、位序、尾拍有效字节编码、错误标记有效周期、跨拍关系 |
| 可选 transaction 定义 | 类名、字段、位宽、字段含义、打包顺序、已有序列接口 |
| 可选生成选项 | 自测试、带激励：未指定时均关闭；开启带激励时才解析相应 transaction 列 |

显式指定的 sheet 优先；只有一个 sheet 时可直接读取；多 sheet 且无法由任务确定目标时报告待澄清项，不因等待超时而选择示例 `pkt_fifo`。保留输入文件、sheet 和行号，原始材料只读。信号方向、尾拍编码或时序描述矛盾时不能靠名称猜测。

## 2. 生成顺序

1. 从规格 / SSOT 核对接口契约与参数，不读取 DUT RTL。
2. 读取可访问的已有 VIP / BFM，确认实际类名、端口类型、配置类和编译组织，优先复用。
3. 列出输出文件、驱动方与观察方，以及 transaction 与接口字段映射。
4. 先定义复位 / 空闲 / 握手行为，再实现打包、逐拍驱动、采样和重组。
5. 用独立预期数据检查数据顺序、帧边界、尾拍及复位；记录实际完成的自测和未测项。
6. 更新平台文件列表和连接，按平台参考完成自检并交接。

不修改源 VIP / 组件库；复制并适配的代码放在本 IP 的 `dv/` 中。原 skill 的独立 `BFM/<时间戳>/` 输出约定不替代 rtl-flow 的产物目录。

## 3. UVM 组件与文件契约

标准 UVM BFM 由 cfg、agent、driver、monitor 和 virtual interface 构成；独立 receiver 按接口职责决定是否需要。sequencer 放 `env/gen/` 或实际 agent 中。使用标准 UVM TLM API；interface 独立编译在 package 前，class 头文件由 env package include，避免重复编译。未命名新组件按项目约定命名。

继承原 Gaea/Superbench BFM 时，其契约是一个目录内的六类源码和两份元数据，示意如下；flist/ini 只在该平台消费者需要时生成，不是默认标准 UVM 的强制产物：

```text
bfm_<interface>/
  src/
    bfm_<interface>.sv            # 组件集成、build/connect、work_mode
    bfm_<interface>_cfg.sv        # 配置对象
    bfm_<interface>_intf.sv       # 信号、时钟块 / modport
    bfm_<interface>_driver.sv
    bfm_<interface>_monitor.sv
    bfm_<interface>_receiver.sv
  flist
  ini
```

- 每个源码使用唯一且配对的 include guard；重命名时同步类名、factory 注册、virtual interface 类型、flist 和 ini。
- 原 skill 的文字示例省略了部分文件名的 `bfm_` 前缀，实际 `bfm_temp` 模板保留该前缀；选择项目的一套命名并保证全部引用一致，不重命名既有对象。
- `ini` 描述 TOP、CFG、INTERFACE、DRIVER、MONITOR、事务类型和支持模式等元数据；以平台消费者支持的字段为准，不复制 demo 的人员信息。
- 核对 cfg 创建 / 传递时机、`uvm_config_db` 的 key、作用域与参数化 interface 类型。原模板用 key `bus`；调用方与被调用方必须一致，获取失败应明确报错。
- driver 消费输入 transaction；monitor/receiver 发布实际观察结果。标准 UVM 使用 active/passive 配置和 analysis port；原模板专有工作模式与 port 关系由平台参考定义。
- 源模板写 SV 2012 / UVM 1800.2-2020，当前默认 runner 选择 VCS UVM 1.2；使用兼容 API并记录实际库版本，不能把库版本名称当作同一标准混用。

## 4. Driver：transaction 到时序

- task 的局部声明放在语句之前。只驱动 BFM 拥有的信号；不得初始化或驱动 DUT 输出。时钟由时钟源负责。
- 原模板的“除 clk 外全 0”仅作为普通数据 / 控制输出的空闲示例。复位、电平有效信号和协议空闲值以接口契约为准，禁止覆盖有效低复位等要求。
- 使用 transaction 的 `pack()` 得到 `bit bitstream[]`，核对字段注册 / `do_pack`、packer 的位序与长度元数据；再按 `DAT_WIDTH` 分拍组成 `bit [DAT_WIDTH-1:0] payload[]`。不能假定打包结果天然等于协议字节流。
- 驱动沿、非阻塞赋值 `<=`、时钟块 skew 与采样区域需一致。原 UVM 模板采用上升沿驱动、小端顺序；只有接口契约相同时才能沿用。原生 TB 的沿后调度继续按编码规范 §10。
- 根据真实握手条件推进 payload；背压时按协议保持数据 / 指示信号。不能仅凭 valid 已拉高就消耗事务。
- SOP/EOP、valid、error 及尾拍掩码须与数据同步。显式处理单拍、连续帧、空闲间隔、复位中断和非整拍长度。
- 对字节流且数据位宽为 8 的倍数，拍数可按 `ceil(byte_count / (DAT_WIDTH / 8))` 计算；尾拍有效位位置与编码另由协议确定。其他位宽按位级契约处理。

源示例中 `DAT_WIDTH=32`、5 字节需 2 拍、最后一拍 `imod=3`，其描述规定高字节有效；同时模板写“小端低位在前”。这两条不能直接拼接成实现，必须明确“字节发送顺序”和“尾拍有效 lane”各自含义并核对时序，未澄清时上报。

## 5. Monitor / Receiver：时序到 transaction

- 按规格的时钟事件和有效 / 握手条件采样；UVM 采样代码不以任意 `#` 延时模拟协议拍数，也不在过程代码中使用 SVA 的 `$past`。这不禁止原生 TB 按 §10 采用消除竞争的采样延时。
- 用协议状态机管理帧首、帧中、帧尾、错误和复位；valid 无效时不消费 payload，不能把 X 当作有效数据。
- 原 pkt_fifo 示例只在 `idval=1` 时解释 `idata/imod/isop/ieop/ierr`，在有效 EOP 时发布重组结果；其他接口按自己的握手定义实现。
- 动态数组不能使用队列的 `push_back()` / `pop_front()`。需要逐步收集时使用队列或显式扩容，发布前转换成实际 transaction 字段类型。
- 检查过早 / 缺失 EOP、重复 SOP、非法尾拍编码、数据截断、复位后的残留事务；是否合法及期望处理由规格决定。
- 发布事务时避免后续采样修改已交给 scoreboard 的同一对象；多路转发的对象所有权见平台参考。
- monitor 的实际结果从接口观察产生，不能直接复制 driver 的输入作为“已观察结果”；参考模型也必须独立计算预期。

原模板的“不能使用不可综合语法”不作为 UVM class 的通用限制：class / 动态数组本来属于验证代码；保留的是合法 SV 语法、正确集合 API 和无采样竞争的要求。

## 6. 可选自测试与检查清单

自测试开启时生成 transaction 和逐周期信号向量；带激励开启时优先使用输入指定的 transaction，而不是固定 `Packet` 类。固定 8 字节、元素依次递增仅可作为确定性的自测样例，正式随机用例取值来自规格。

若目标平台消费原模板的 `yaml.txt`：信号按时序定义顺序排列，省略 clk/rst，名称左对齐占 25 字符；单比特用数值，多比特用合法宽度字面量（如 `32'h0`、`2'h3`），不写 `x`。不要把该自测格式当作 SSOT YAML，也不要因此禁止在正式 monitor 中检测 X。

- 标准 UVM 的 agent/cfg/driver/monitor/interface 及按需 receiver 齐全，package/filelist 引用一致；继承专有平台时检查其六类源码和 flist/ini 契约。
- 参数化宽度、空闲值、复位、字节序、握手和尾拍行为均有规格依据。
- cfg、virtual interface、模式与端口匹配；编译依赖和测试入口按平台参考检查。
- 自测至少覆盖短帧、整拍 / 非整拍、多帧、背压（适用时）、复位中断和错误场景。
- 保留命令、工具版本、退出状态与日志；不能删除编译证据，不能把未执行写成通过。

来源中的 `platform_demo`、`bfm_temp` 及 Excel 样表未打包到本参考目录。本文不依赖原 skill 安装路径；需要精确兼容 Gaea / Superbench 模板 API 时，由项目提供可读的实际平台 / 组件副本，再按平台参考核对依赖。
