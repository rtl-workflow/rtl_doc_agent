---
description: 打开最近一次VCS回归的FSDB，在远端Verdi中查看并记录路径
---

使用 rtl-design-flow。用户参数：$ARGUMENTS

正式RTL回归默认同步生成每用例/种子的FSDB和KDB，不要为打开波形重复仿真。
运行 `python $SKILL/scripts/open_verdi.py <ip_dir> [--test <tc_name>] [--seed N] [--display :1.0]`。
脚本读取最近一次回归的 `dv/build/regress/last_result.json`，从保留的远端工作目录打开FSDB。
用户没选用例时默认最近回归第一个匹配种子的用例，说明实际打开的用例名。
必须汇报 `reports/verdi.json` 中的状态、远端FSDB路径、设计数据库、DISPLAY及启动日志；只有status=opened才能宣称窗口已打开。
若旧回归无FSDB或远端文件已被删除，解释原因再用默认FSDB配置重跑所需用例；不得从日志伪造波形。
GUI失败不能改写仿真PASS；保留路径/日志并准确说明环境问题。
