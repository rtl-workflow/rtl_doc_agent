# UVM runner integration fixture

This is a tool test fixture, not a signed-off IP. The contract is an 8-bit
registered loopback: each valid input sampled on a rising edge appears at the
output after that edge; asynchronous low reset clears the output valid/data.
No output transaction is produced when input valid is low.

## 2. Verification environment

Standard UVM: sequencer/driver/monitor agent, independently computed expected
transactions, two scoreboard FIFOs, coverage subscriber and base-test reporting.
Drive 1 ns after the falling edge; observe just before the next falling edge.
Clock period is 10 ns. The monitor sees both input and registered output after
the intervening rising edge. The test sends four bytes: 0, 255, 1, 2.

## 3. Test points and cases

| Feature编号 | Feature描述 | Sub-Feature | Test point | 测试点编号 | 测试点是否被测试用例覆盖 | 备注 |
|---|---|---|---|---|---|---|
| loopback | registered byte | data | preserve byte value and order | tp_loopback_data | Yes | fixture |

| 字段 | 内容 |
|---|---|
| 测试用例编号 | tc_loopback_smoke |
| 所覆盖测试点编号 | tp_loopback_data |
| TC 描述 | Reset, send 0/255/1/2, allow ten monitor cycles to drain, check all four results and empty FIFOs. |
| 预期结果 | Exactly four matching output transactions, zero errors. |
| 测试活动 | 仿真 |

## 5. Coverage

Export real scoreboard comparisons and monitor output hits as COVER counters.
This fixture does not assert production coverage closure.
