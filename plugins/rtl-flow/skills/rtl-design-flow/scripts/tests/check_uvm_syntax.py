"""Optional semantic compile of the UVM fixture; does not run a simulator.

Requires pyslang and an unpacked official UVM 1.2 distribution:
    python check_uvm_syntax.py --uvm-src /path/to/uvm-1.2/src
Neither dependency is required by rtl-flow's VCS runner or Python unit tests.
"""
import argparse
from pathlib import Path
import tempfile

from test_uvm import prepare_fixture
import run_regress
import uvm_support


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--uvm-src", type=Path, required=True)
    args = parser.parse_args()
    try:
        from pyslang.driver import Driver
    except ImportError:
        parser.error("pyslang is required for this optional static check")
    src = args.uvm_src.resolve()
    if not (src / "uvm_pkg.sv").is_file():
        parser.error("--uvm-src must contain uvm_pkg.sv")
    with tempfile.TemporaryDirectory(prefix="rtlflow-uvm-syntax-") as folder:
        ip = prepare_fixture(Path(folder) / "uvm_loopback")
        platform = uvm_support.load(ip)
        data, errors, _ = run_regress.gen_docs.outputs(ip)
        if errors:
            parser.error("; ".join(errors))
        stub = ip / "dv/build/stub/uvm_loopback_stub.v"
        stub.parent.mkdir(parents=True)
        stub.write_text(run_regress.gen_stub(data), encoding="utf-8")
        for mode, dut in (("rtl", [ip / p for p in data["rtl_files"]]), ("stub", [stub])):
            options = ["slang", "--top", platform.top, "--timescale=1ns/1ps",
                       "+incdir+" + src.as_posix(), str(src / "uvm_pkg.sv")]
            options += ["+incdir+" + p.as_posix() for p in platform.incdirs]
            if mode == "stub":
                options.append("+define+RTLFLOW_STUB")
            options += [str(p) for p in dut + platform.sources]
            driver = Driver()
            driver.addStandardArgs()
            command = " ".join('"' + s.replace("\\", "/") + '"' for s in options)
            if not driver.parseCommandLine(command) or not driver.processOptions() or not driver.parseAllSources():
                raise SystemExit(1)
            compilation = driver.createCompilation()
            driver.reportCompilation(compilation, False)
            if not driver.reportDiagnostics(False):
                raise SystemExit(1)
            print(f"{mode}: UVM fixture semantic compilation passed (not a VCS simulation)")


if __name__ == "__main__":
    main()
