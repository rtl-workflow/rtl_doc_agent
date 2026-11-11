# UVM integration fixture

This is a small runner test fixture, not a completed P0–P6 IP or a signed-off
verification example. Its specification is in doc/07_dv_plan.md. It contains a
real interface, sequence, driver/monitor agent, reference model, two-FIFO
scoreboard, coverage subscriber and test. There are no proprietary platform
base classes. RAL is not applicable to this register-free DUT.

Use `prepare_fixture(target)` from `scripts/tests/test_uvm.py` to materialize it
in a temporary directory. That function installs the maintained
`templates/dv/env/common/rtlflow_test_base.svh`; the fixture deliberately does
not keep a second copy of the base class. The fixture source directory is not
directly runnable until prepared.

The Python unit tests mock simulator processes to verify command construction,
result parsing, isolation, caching and failure handling. The optional
`scripts/tests/check_uvm_syntax.py --uvm-src <official-uvm-1.2-src>` checks the
actual classes and connections against UVM using pyslang, both with the real
fixture DUT and with an SSOT-generated stub. It does not simulate.

In a configured VCS environment, the prepared directory can be passed to
`run_regress.py` with `--stub` or `--no-fsdb`. The real DUT should produce four
matching transactions; the stub should complete with functional errors and
zero observed outputs. A stub-check PASS must never be reported as functional
verification of the DUT. Formal IP work still requires the normal G3 gate.
