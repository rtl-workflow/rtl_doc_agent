source $env(VE_VERIF_PATH)/bt/lg_sdsf_rr/disturb_new.tcl
puts "-----------------step debug-----------------"
if { [info exists env(mode)] && $env(mode) == "disturb"} {
                                           
} else {
    call \$fsdbDumpvars 0 "harness" \"+mda\"
}

if { [info exists env(ASSERT_SWITCH)] && $env(ASSERT_SWITCH) == "on"} {
    call \$fsdbDumpSVA 0 "harness"
}

# Uncomment the below line for "Forces the signal values to flushed to the FSDB file while the simulation running"
#call \$fsdbDumpflush

run 100us
puts "-----------------start module disturb-----------------"
for {set times 0} {$times < 30} {incr times} {
    puts "-----------------start $times the module disturb-----------------"
    disturb_module {harmess.U_LG_SDSF_RR.U_LG_OTN_EXT_RR_CMP}
    disturb_module {harmess.U_LG_SDSF_RR.U_LG_OTN_EXT_RR_PKTGEN}
run 200us
}
puts "-----------------end module disturb-----------------"
run

#######################################################################
# run simulation directly except gui!=off
#######################################################################
if { [info exists env(gui)] && $env(gui) == "off"} {
} else {
    run
}
