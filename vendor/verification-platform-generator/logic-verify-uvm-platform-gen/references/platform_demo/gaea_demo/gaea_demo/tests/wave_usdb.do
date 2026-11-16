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
#  E.G.  call \$fsdbDumpvars 1 "tb_top.U_stat_top"
#
################################################################################
# This section is be to used for people want to dump big Verdi waves(.fsdb).
# To automatically switch to a new dump file when the working FSDB file hits 
# the specified size limitation. The unit associated with $fsdbAutoSwitchDumpfile's
# File_Size parameter is a megabyte.
#  E.G.  call \$fsdbAutoSwitchDumpfile 1000 \"$env(FSDBFILE)\" 10 \"$env(WAVE_DIR)/fsdb_dump.log\"
#        call \$fsdbDumpvars 0 "tb_top"
#
################################################################################
# This section is be to used for people want to dump Verdi waves(.fsdb). want 
# to stop in some time. You can change "1000ns" as you need. E.G.
#  E.G.  run 5000ns 
#        call \$fsdbDumpvars 0 "tb_top"
#        run 1000ns
#        call \$fsdbDumpoff
#        run 1000ns
#        call \$fsdbDumpon
#
################################################################################
# This section is be to used for people want to dump memory waves(.fsdb). E.G.
#  E.G   call \$fsdbDumpvars 0 "tb_top.U_stat_top" \"+mda\"
#
#  For detail information about $fsdbDumpvars, please refer to:
#  "/software/novas/verdi/2008.10/doc/linking_dumping.pdf"
################################################################################
# Uncomment the below line when dump big Verdi waves(.fsdb)

#if { [info exists env(wave)] && $env(wave) == "usdb"} {
#    call {$usdbDumpvars(0,tb_top)}
#}
call {$usdbDumpvars(0,tb_top)}
if { [info exists env(mem)] && $env(mem) == "on"} {
    call {$usdbDumpMDA(0,tb_top)}
}
if { [info exists env(assert)] && $env(assert) == "on"} {
    call {$usdbDumpSVA(0,tb_top)}
}
run
#############################################################################
# run simulation directly except gui!=off
#############################################################################
#if { [info exists env(gui)] && $env(gui) != "off"} {
#} else {
#    run
#}
