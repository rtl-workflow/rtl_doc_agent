# BFM 生成规则参考（3.0.0）

本文件是agent编写代码的参考，不是可执行渲染器。先满足[子技能输入合同](../SKILL.md)，遵循批准UVM库/平台profile及[上级SSH合同](../../references/ssh-backend-contract.md)。不调用遥测或默认UVS。

## 参考资产与输出布局

Gaea参考目录：`../../logic-verify-uvm-platform-gen/references/platform_demo/gaea_demo/gaea_demo/env/bfm/bfm_temp/`。读取对应源码后再适配；其中注释示意、空task和旧UVM接口不能算作生成完成。

| 组件 | 参考文件（相对上述目录） | 输出职责 |
| --- | --- | --- |
| 集成类 | src/bfm_temp.sv | 创建/配置组件，连接TLM与virtual interface，验证各work mode输出 |
| 配置类 | src/bfm_temp_cfg.sv | 只表达批准协议参数、角色和reset行为 |
| driver | src/bfm_temp_driver.sv | 仅驱动属于环境的信号，执行真实握手 |
| interface | src/bfm_temp_intf.sv | 方向、modport、clocking/skew及reset视角明确 |
| monitor | src/bfm_temp_monitor.sv | 只观测真实接受/完成事件并发布事务 |
| receiver | src/bfm_temp_receiver.sv | 按职责采样/响应，禁止与driver争用输出 |
| filelist/ini | flist、ini | 显式编译依赖与顺序，不依赖目录名猜测类/类型 |

默认命名 `bfm_<interface_name>*.sv`；总agent指定不同ABI时以批准ABI为准。guard与factory类名应匹配；参数宽度、transaction类型、analysis/TLM类型和cfg路径必须可追溯到组件合同。

## Driver

- 初始化仅限本组件拥有的驱动信号，值来自批准reset/idle合同。时钟由指定时钟源负责，不把除clk以外信号一律驱为0；DUT输出只能观测。
- 驱动沿、采样沿、clocking skew、复位极性/同步性、背压、完成与取消条件由协议决定；不默认上升沿、小端、sop/eop/vld或固定网络报文。
- 选择有明确定义的事务序列化方式。使用UVM pack时检查字段顺序、packer设置、位/字节序、尾拍有效位，不能认为pack天然符合总线字节序。
- 完成阻塞握手须有超时/reset退出；发布“发出意图”不能冒充“DUT已接受”。reset后清理在途项并保留世代关联。
- 具体赋值区域由clocking/时序合同决定；避免驱动和采样竞态。合法SV声明在使用前，不强制牺牲可读性实现固定模板写法。

## Monitor / receiver

- monitor独立采样真实信号，按接受事件、事务关联键、尾拍/完成与reset规则组包。不能用driver意图填充actual，也不能回写黄金预期。
- 不硬编码idval/imod/idata/ieop；它们只是旧pkt_fifo例子的信号名。只有输入合同明确使用该协议时才采用。
- UVM测试平台通常不可综合；class、queue、dynamic array等可合法使用，不设置“必须可综合”假门槛。queue可push_back/pop_front，dynamic array须用其合法操作；断言系统函数按合法SVA上下文使用。
- 不用任意延迟代替握手；clocking skew或协议规定的延迟必须显式表达其依据。
- receiver若要驱动ready/ack，先冻结所有权；pure monitor模式不得驱动信号。检查各模式TLM端口实际连接，不能仅实例化monitor就认为有输出。

## Transaction 与自测试

由获批transaction类名/字段/约束生成。`Packet`、八字节`1..8`、固定yaml向量不是通用默认值，不能自动生成作真实协议验证依据。

自测试可使用小型定向向量，但必须说明向量来源、独立预期、实际观测、比较与结束条件。只有实际运行后才报告selftest结果，不能将model/selftest提升为真实DUT通过。Wavedrom中的X/未知值不能强制改成0；明确允许未知区间和检测规则。数值编码必须符合实际位宽，禁止截断掩盖错误。

## 编译与证据

先形成最终package/import/include及filelist，再交总agent编译。Gaea需要glb_dec类型时保留正确作用域/顺序；不得为“清理”删除日志，或编译后删import/include继续沿用通过。每次修改使相关编译/仿真结果过期，重新记录源码摘要并保留全部attempt日志。

SSH与仿真器由总agent配置，本包未实现该执行器。没有编译工具时交付generated/not_run或generated/blocked，真实功能结论由上级门禁形成。
