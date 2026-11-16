################################################################################
# This script is to be used for people who would like Simvision waves.
#
################################################################################
# probe -create tb_top -shm -all -variables -depth all
# probe -create tb_top -shm -all -variables -depth 1
# probe -create tb_top -shm -all -memories -variables -depth all
# -depth all: all signals in all scopes.
# -depth   1: all signals in current scope.
# -memories : To include Verilog memories in the probe.
################################################################################

ida_database -open -name=$env(SHMFILE)

if { [info exists env(MEM_SWITCH)] && $env(MEM_SWITCH) == "on"} {
    ida_probe -log
    if { [info exists env(METHODOLOGY_SWITCH)] && $env(METHODOLOGY_SWITCH) == "UVM" } {
        ida_probe -tb_dut_access -wave -wave_probe_args="tb_top $uvm:{uvm_test_top} -all -depth all -memories -packed 0 -unpacked 0 -dynamic"
    } else {
          ida_probe -wave -wave_probe_args="tb_top -all -depth all -memories -packed 0 -unpacked 0 -dynamic"
    }
} else {
    ida_probe -log
    if { [info exists env(METHODOLOGY_SWITCH)] && $env(METHODOLOGY_SWITCH) == "UVM" } {
        ida_probe -tb_dut_access -wave -wave_probe_args="tb_top -all -depth all"
        ida_probe -tb_dut_access -wave -wave_probe_args="$uvm:{uvm_test_top} -all -depth all"
    } else {
        ida_probe -wave -wave_probe_args="tb_top -all -depth all"
    }
}

#############################################################################
# run simulation directly except gui=on
#############################################################################
if { [info exists env(gui)] && $env(gui) == "on"} {
} else {
    run
}