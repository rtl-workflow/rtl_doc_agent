#!/usr/bin/tclsh
#/**********************************************************************************
#    Copyright(c) 2014 Huawei Technologies Co., Ltd, All rights reserved
#    Department   :   Network Product Line(NPL), R&D Logic IC Chip Department
#    Filename     :   run.tcl
#    Author       :   shenyue/00159590
#    ===============================================================================
#    Description  :   1, module example
#    ===============================================================================
#    Modification History:
#    Date        By                      Rev.    Prj.    Change Description
#    -------------------------------------------------------------------------------
#    2014-03-07  shenyue                 1.0     PL381   Create
#    2017-10-12  GaeaPlatform            1.1     GaeaPlatform fsdb or vpd
#**********************************************************************************/

# Load cpu_wr and cpu_rd runtime scirpt
#source ../../tb/bfm/cpu_proc.tcl

# If found case_id.tcl in current testcase directory, then load it.
if {$env(gui_en) == "on"} {
    #stop
} elseif {$env(load_script) == "on"} {
    if {[file exists $env(case_id).tcl]} {
        puts "Found the $env(case_id).tcl , loading ..."
        source $env(case_id).tcl
    } else {
        puts "The $env(case_id).tcl file does not exist, please confirm! Or you can manually source *.tcl file, or just run"
    }
} elseif {$env(vpd_dump) == "on"} {
    dump -file $env(case_id).vpd -type VPD
    dump -add  $env(th_top) -depth 0 
    run
} elseif {$env(fsdb_dump) == "on"} {
    # Limit the fsdb file size <= 1G
    fsdbAutoSwitchDumpfile 1000 $env(case_id) 40
    # Suppress unusefull modules to speed up the simulation
    fsdbSuppress "module_base="  "altsyncram" ;# suppress the basic ram sim model of ALTERA
    fsdbSuppress "module_base="  "altsyncram" ;# suppress the basic ram sim model of ALTERA
    fsdbSuppress "module_base="  "RAMB16"     ;# suppress the basic ram sim model of XILINX
    fsdbSuppress "module_base="  "RAMB16BWER" ;# suppress the basic ram sim model of XILINX
    fsdbSuppress "module_base="  "RAMB18E1"   ;# suppress the basic ram sim model of XILINX
    fsdbSuppress "module_base="  "RAMB36E1"   ;# suppress the basic ram sim model of XILINX
    fsdbSuppress "module_base="  "RAMB8BWER"  ;# suppress the basic ram sim model of XILINX
    # Start dumping, default dump all signals.
    #fsdbDumpvars "+parameter"
    #fsdbDumpMDA
    fsdbDumpSVA
    fsdbDumpflush
    fsdbDumpvars 0 $env(th_top)
    puts "$env(fsdbontime)"
    puts "$env(fsdbruntime)"
    if {$env(fsdbontime) != ""} {
        fsdbDumpoff
        run $env(fsdbontime)
        fsdbDumpon
        if {$env(fsdbruntime) == "on"} {
            run $env(fsdbruntime)
            fsdbDumpoff
        }
    }
    run
} else {
    run
}
stop
# Quit ucli when finished so coverage result can be saved.
# Dont't remove it or the coverage may not be saved correctly!
#quit
