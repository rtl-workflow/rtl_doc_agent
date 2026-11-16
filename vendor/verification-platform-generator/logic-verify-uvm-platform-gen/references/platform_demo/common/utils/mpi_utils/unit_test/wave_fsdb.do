################################################################################
# This script is to be used for people who would like Verdi waves. 
#
################################################################################
# You can change the level, The default level value is 0. Level values have 
#  the following meanings: 
#  0: all signals in all scopes.
#  1: all signals in current scope.
#  2: all signals in the current scope and all scopes one level below.
#  n: all signals in the current scope and all scopes n-1 levels below
#  You also can change the module name.
#  E.G.  call \$fsdbDumpvars 1 "harness.U_stat_top"
#
################################################################################
# This section is be to used for people want to dump big Verdi waves(.fsdb).
# To automatically switch to a new dump file when the working FSDB file hits 
# the specified size limitation. The unit associated with $fsdbAutoSwitchDumpfile's
# File_Size parameter is a megabyte.
#  E.G.  call \$fsdbAutoSwitchDumpfile 1000 \"$env(FSDBFILE)\" 10 \"$env(WAVE_DIR)/fsdb_dump.log\"
#        call \$fsdbDumpvars 0 "harness"
#
################################################################################
# This section is be to used for people want to dump Verdi waves(.fsdb). want 
# to stop in some time. You can change "1000ns" as you need. E.G.
#  E.G.  run 5000ns 
#        call \$fsdbDumpvars 0 "harness"
#        run 1000ns
#        call \$fsdbDumpoff
#        run 1000ns
#        call \$fsdbDumpon
#
################################################################################
# This section is be to used for people want to dump memory waves(.fsdb). E.G.
#  E.G   call \$fsdbDumpvars 0 "harness.U_stat_top" \"+mda\"
#
#  For detail information about $fsdbDumpvars, please refer to:
#  "/software/novas/verdi/2008.10/doc/linking_dumping.pdf"
################################################################################

# Uncomment the below line when dump big Verdi waves(.fsdb)
#call \$fsdbAutoSwitchDumpfile 1000 \"$env(FSDBFILE)\" 10 \"$env(WAVE_DIR)/fsdb_dump.log\"

if { [info exists env(MEM_SWITCH)] && $env(MEM_SWITCH) == "on"} {
    call \$fsdbDumpvars 0 "harness" \"+mda\"
} else {
    call \$fsdbDumpvars 0 "harness"
}

if { [info exists env(ASSERT_SWITCH)] && $env(ASSERT_SWITCH) == "on"} {
    call \$fsdbDumpSVA 0 "harness"
}

# Uncomment the below line for "Forces the signal values to flushed to the FSDB file while the simulation running".
#call \$fsdbDumpflush

#############################################################################
# run simulation directly except gui!=off
#############################################################################
if { [info exists env(gui)] && $env(gui) != "off"} {
} else {
    run
}
