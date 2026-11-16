################################################################################
# This script is to be used for people who would like Simvision waves. 
#
################################################################################
# probe -create harness -shm -all -variables -depth all
# probe -create harness -shm -all -variables -depth 1
# probe -create harness -shm -all -memories -variables -depth all
# -depth all: all signals in all scopes.
# -depth   1: all signals in current scope.
# -memories : To include Verilog memories in the probe.
################################################################################

database -open waves -into $env(SHMFILE) -default

if { [info exists env(MEM_SWITCH)] && $env(MEM_SWITCH) == "on"} {
    probe -create harness -shm -all -memories -variables -depth all
} else {
    probe -create harness -shm -all -variables -depth all
}

#############################################################################
# run simulation directly except gui=on
#############################################################################
if { [info exists env(gui)] && $env(gui) == "on"} {
} else {
    run
}
