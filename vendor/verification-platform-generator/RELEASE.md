# Release 1.0.0-rc.1

## 安装与依赖

解压后在包根目录加载 [SKILL.md](SKILL.md)，不要只复制主文件而遗漏子目录。宿主应具备本地读写、命令执行及所需Office读取能力；本包不绑定特定宿主MCP名称。

- 核心doctor、release、bt_uvm与标准库测试：Python 3.10+，无第三方Python依赖。
- prepared输入：无需强制安装文档转换器。
- Excel可选：BFM参考依赖openpyxl/PyYAML，TC参考pandas/openpyxl，见各子技能requirements；这些是工作流依赖提示，不是已锁定/已测试的完整环境。可使用宿主已有Office能力替代，不自动安装。
- 实际SV/UVM编译：需要项目选择的仿真器、UVM库、外部VIP/框架库及许可证；不随包提供。
- SSH：只有后端合同和禁用配置示例，未提供可直接运行的SSH adapter。

## 验证与打包

```powershell
python -B -m agent.doctor
python -B -m unittest discover -s tests -p 'test_*.py'
python -B -m agent.release --output-dir ../dist
python -B -m agent.release --verify ../dist/verification-platform-agent-1.0.0-rc.1.zip
```

输出目录必须在源包之外，已存在同名ZIP/校验文件时拒绝覆盖。包根采用ASCII名称；内容顺序、ZIP时间戳固定，相同字节产生相同ZIP摘要。输出ZIP和`.sha256`文件；ZIP内 `RELEASE-MANIFEST.json`列出每个文件路径/大小/SHA-256（清单本身不自哈希），整包SHA覆盖它。verify不解压、不执行包内代码。

打包工具检查注册表、白名单、JSON语法、本地Markdown文件链接、路径/链接逃逸和不应发布的缓存/会话产物。它不会自动运行单元测试；发布前须单独运行。完整性验证不等于来源签名、权利审核、恶意内容扫描或EDA功能验收。

## 清理策略

历史原文/审查/项目示例、旧HTML流程图和GUI solution/scene、disabled遥测配置、Python字节码、仿真日志/空会话key、原宿主环境/参数快照已移出源发布树。工作区保留归档ZIP及逐文件摘要，便于恢复；归档不在include_roots且不随包分发。

保留所有当前合同、测试、源代码、实际被引用的filelist/ini/do及公共模板；不按扩展名盲删源码。旧外部GUI导入和原宿主会话恢复不在候选包支持范围。目标工具配置由项目profile重新建立。

## 发布前提与已知问题

- 源码/目录已整理为发布候选，公开再分发需先解决 [RIGHTS.md](RIGHTS.md) 所列来源授权。
- 两套legacy模板仍有旧UVM、占位行为和外部工具依赖；Gaea实际编译链可能重复包含basic_tc/sanity，且相对路径依赖工作目录。必须按选定工具重新生成/核对filelist，不把文档修正当编译成功。
- 同权限篡改、真实Windows符号链接行为、远端工具身份和真实DUT结果未被打包工具验证。
- JSON Schema文件有语法与代表性合同检查，未宣称完整Draft-07验证器认证。

当前支持的是宿主agent辅助工作流；自检通过只能给出对应范围结论。
