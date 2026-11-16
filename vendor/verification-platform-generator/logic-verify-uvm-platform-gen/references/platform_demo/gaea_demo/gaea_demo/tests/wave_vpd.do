#############################################################################
# This script is to be used for people who would like VPD waves.
# Uncomment the lines between the dividers.
#
#############################################################################
# This section is be to used for people who would like DVE waves(.vpd). only 
# part of wave.
# You can change the level,The default level value is 0. Level values have 
#  the following meanings: 
#  0: all signals in all scopes.
#  1: all signals in current scope.
#  2: all signals in the current scope and all scopes one level below.
#  n: all signals in the current scope and all scopes n-1 levels below
#  E.G.  set fid [dump -file $env(VPDFILE)]
#        dump -autoflush on
#        dump -flush -interval 5
#        dump -add . -depth 1 -fid $fid
#
#############################################################################
# This section is be to used for people who would like dump memoey waves(.vpd).  
#  E.G.  set fid [dump -file $env(VPDFILE)]
#        call \$vcdplusmemon "tb_top.U_stat_top.memory"
#
#############################################################################
# This section is be to used for people who would like to dump all varibles including memory.  
#  E.G.  set fid [dump -file $env(VPDFILE)]
#        dump -autoflush on 
#        dump -flush -interval 5
#        dump -add tb_top.U_stat_top -aggregates
#
#  For detail information about vpd wave, please refer to:
#  "/software/synopsys/vcs/2011.03-3/doc/UserGuide/pdf/ucli_ug.pdf"
#############################################################################

set fid [dump -file $env(VPDFILE)]
dump -autoflush on

if { [info exists env(MEM_SWITCH)] && $env(MEM_SWITCH) == "on"} {
    dump -add tb_top -aggregates
} else {
    dump -add . -fid $fid
}

# Uncomment the below line for "Turns dumping delta cycle information without using -fid".
#dump -deltaCycle on

#############################################################################
# run simulation directly except gui!=on
#############################################################################
if { [info exists env(gui)] && $env(gui) != "off"} {
} else {
    run
}
