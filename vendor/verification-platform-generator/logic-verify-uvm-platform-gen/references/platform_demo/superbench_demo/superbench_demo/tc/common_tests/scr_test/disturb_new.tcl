#/**********************************************************************************
#    Copyright(c) 2014 Huawei Technologies Co., Ltd, All rights reserved
#    Department   :   Network Product Line(NPL), R&D Logic IC Chip Department
#    Filename     :   disturb_new.tcl
#    Author       :   shenyue/00159590
#    ===============================================================================
#    Description  :   1, module example
#    ===============================================================================
#    Modification History:
#    Date        By                      Rev.    Prj.    Change Description
#    -------------------------------------------------------------------------------
#    2014-04-24  shenyue                 1.0     PL381   Create
#    2015-07-08  shenyue                 1.1     PL501   1. Fix is_real_reg function issue.
#                                                        2. Fix get_instance issue.
#    2016-09-03  shenyue                 1.2     PL506   1. Fix rand error
#    2017-04-22  shenyue                 1.3     PL520   1. Fix syntax error
#**********************************************************************************/

set DISTURB_SCRIPT_VERSION 1.3

global module_filter_list
global instance_filter_list
global signal_filter_list
global module_disturbed

set module_disturbed "top.u_tunl.XXXXXX" ;#  set full path of instance to be disturbed
set disturb_time     10 ;#  set disturb time
set delay_time       20 ;#  unit: us
set rand_seed       [clock seconds]
#set rand_seed      1694856703  ;# if you need reappear disturb stimulation,replace line above with this line after set target seed
puts "rand_seed value is $rand_seed"
set reset_seed      [expr srand($rand_seed)]

# set the module you don't want to disturb
set module_filter_list {
    DCSDP_RAM_v
    SDP_RAM_v
    XILINX_DCSDP_RAM_v
    *xilinx*
    *_mib
    sem
    cib_*
    syn_rst
    shub_cib_oam_adapt
    MPI_OTNOH_TOP
    MPI_CLK_GATE
    *TPRAM_WRAP4*
    *FIFO_SYNC*
}

# set the instance you don't want to disturb
set instance_filter_list {
    *.u_cib*
    *.u_sem
    *.U_MPI*
    *.*_CHK*
    *.*_FIFO_SYNC*
    *.*TPRAM_WRAP4*
    #adder
}

set signal_filter_list {
}

config resultlimit 4096 ;# set max result limit to 4096(default 1024)

proc split_para {seg_num pos argv} {
    set size [llength $argv]
    set result ""
    for {set index 0} {$index < ($size / $seg_num)} {incr index} {
        lappend result [lindex $argv [expr $index * $seg_num + $pos]]
    }
    return $result
}

proc get_instance {modulename {level 0}} {
    #puts "\[get_instance\] $modulename"
    set result_list [show -instances -fullname $modulename]

    set inst_list [split_para 2 1 $result_list]
    set inst_list [filter_module $inst_list]
    set inst_num [llength $inst_list]
    if {$inst_list == 0} {return ""}

    set sub_level 0
    if {$level == 1} {
        return $inst_list
    } elseif {$level == 0} {
        set sub_level 0
    } else {
        set sub_level [expr $level - 1]
    }

    for {set index 0} {$index < $inst_num} {incr index} {
        set sub_inst [lindex $inst_list $index]
        set sub_inst_list [get_instance $sub_inst $sub_level]

        # uncomment the code following if you want to get the full instance list which may be really large
        if {[llength $sub_inst_list] != 0} {
            set inst_list [concat $inst_list $sub_inst_list]
        }
    }
    return $inst_list
}

proc filter_module {inst_list } {
    global module_filter_list
    global instance_filter_list
    set new_inst_list ""
    foreach inst $inst_list {
        set info [show -type $inst]
        set module_name [lindex [lindex $info 1] 1]
        set inst_type [lindex [lindex $info 1] 2]
        if {$inst_type != "module"} {
            #puts "not module ignore $inst" ;
            continue
        }

        set match_result 0
        foreach inst_pattern $instance_filter_list {
            if {[string match $inst_pattern $inst] == 1} {
                puts "\[instance_filter_list\]$inst was filter by $inst_pattern"
                set match_result 1
                break
            }
        }

        if {$match_result == 1} {continue}

        #puts $module_name
        if {[lsearch $module_filter_list $module_name] == -1} {
            lappend new_inst_list $inst
        } else {
            puts "\[module_filter_list\]$inst was filter"
        }
    }
    return $new_inst_list
}

proc filter_signal {sig_list } {
    global signal_filter_list
    set new_sig_list ""
    set sig_filter_num [llength $signal_filter_list]

    foreach sig $sig_list {
        set match_result 0
        if {$sig_filter_num > 0} {
            foreach siginst_pattern $signal_filter_list {
                if {[string match $siginst_pattern $sig] == 1} {
                    puts "\[sig_filter_list\]$sig was filter by $siginst_pattern"
                    set match_result 1
                    break
                }
            }
        }

        if {$match_result == 0} {
            lappend new_sig_list $sig
        }
    }
    return $new_sig_list
}

proc get_signal {{inst_name .} {type *} {level 0}} {
    set result_list [show -signals -fullname $inst_name]
    append result_list "\n"
    append result_list [show -port -fullname $inst_name]

    set signal_list [split_para 2 1 $result_list]
    set signal_list [filter_signal_bytype $type $signal_list]
    set signal_list [filter_signal $signal_list]

    if {$level == 1} {
        return $signal_list
    }
    set sub_inst_list [get_instance $inst_name 0]
    foreach sub_inst $sub_inst_list {
        set sub_signal_list [get_signal $sub_inst $type 1]
        #puts $sub_signal_list
        if {[llength $sub_signal_list] != 0} {
            set signal_list [concat $signal_list $sub_signal_list]
        }
    }

    return $signal_list
}

proc filter_signal_bytype {type signal_list} {
    if {$type == "*"} {
        return $signal_list
    }
    set result ""
    foreach signal_name $signal_list {
        set signal_type [lindex [show -type $signal_name] 1]
        set dimention   [lindex $signal_type 0]
        set signal_type [lindex $signal_type [expr [llength $signal_type] - 1]]
        #puts $signal_type
        if {$dimention != "ARRAY" && $type == $signal_type} {
            lappend result $signal_name
        } elseif {$type == "reg" && $signal_type == "PORT"} {
            lappend result $signal_name
        } else {
            #puts "\[filter_signal_bytype\] $signal_name was filter"
        }
    }
    return $result
}

global SRC_FILE_NAME
global SRC_LINES

set SRC_FILE_NAME ""
set SRC_LINES ""

proc is_real_reg {signal_name} {
    global SRC_FILE_NAME
    global SRC_LINES
    #show -type $signal_name
    #set info [drivers $signal_name  -nowarn -verbose]
    set info [drivers $signal_name  -verbose]
    set bbb  [regexp {\S+\.(sv|v)\s*\d+\s+} $info aaa]
    if {$bbb == 0 } { return 0}

    set file_path [lindex $aaa 0]
    set line_no   [lindex $aaa 1]

    if {$SRC_FILE_NAME != $file_path} {
        set SRC_FILE_NAME $file_path
        set ptr [open $file_path "r"]
        set txt_info [read -nonewline $ptr]
        set SRC_LINES [split $txt_info \n]
        close $ptr
    }

    set real_reg 0
    #for {set cur_line_no [expr $line_no - 1]} {$cur_line_no >= 0}  {incr cur_line_no -1} {
    for {set cur_line_no [expr $line_no]} {$cur_line_no >= 0}  {incr cur_line_no -1} {
        set code_line [lindex $SRC_LINES $cur_line_no]
        #puts $cur_line_no
        #puts $code_line
        if {[regexp {^\s*\\.*} $code_line]} {
            #puts "comment"
            continue
        } elseif {[regexp {^\s*always\s*@\s*\((.*)\)} $code_line var sense_list]} {
            #puts "match"
            #puts $cur_line_no
            #puts $code_line
            #puts $sense_list
            if {[regexp {posedge|negedge} $sense_list]} {
                #puts "real reg"
                set real_reg 1
            }
            break
        } elseif {[regexp {^\s*reg\s*\w*} $code_line]} {
            set real_reg 1
            break
        }

    }
    return $real_reg
}

proc disturb_signal {signal_list {disturb_time 10}} {
    set sig_num [llength $signal_list]
    set sig_real_list ""

    for {set i 0} {$i < $sig_num} {incr i} {
        set signal [lindex $signal_list $i]
        puts "check $signal"
        set check_result  [is_real_reg $signal]
        if {$check_result == 1} {
            lappend sig_real_list  $signal
        } else {
            puts "\[INFO\]$signal was not real reg!"
        }
    }

    for {set i 0} {$i < $disturb_time} {incr i} {
        foreach signal $sig_real_list  {
            while {1} {
                set val [expr rand()]
                set ret [regexp {(0\.)(.*)} $val total f1 f2]
                if {$ret == 0} {
                    continue
                }

                puts "force $signal \t 'd$f2"
                force $signal    'd$f2
                release $signal
                puts "release $signal "
                break
            }
        }
    }
}

proc disturb_module {modulename {level 0} {disturb_time 10}} {
    #puts "\[get_instance\] $modulename"
    set result_list [show -instances -fullname $modulename]
    set inst_list [split_para 2 1 $result_list]
    set inst_list [filter_module $inst_list]
    set inst_num [llength $inst_list]

    # disturb signal in current instance
    set siglist [get_signal $modulename reg 1]
    disturb_signal $siglist $disturb_time

    if {$inst_num == 0} {return ""}

    set sub_level 0
    if {$level == 1} {
        return ""
    } elseif {$level == 0} {
        set sub_level 0
    } else {
        set sub_level [expr $level - 1]
    }


    for {set index 0} {$index < $inst_num} {incr index} {
        set sub_inst [lindex $inst_list $index]
        set sub_inst_list [disturb_module $sub_inst $sub_level $disturb_time]

        ## uncomment the code following if you want to get the full instance list which may be really large
        #if {[llength $sub_inst_list] != 0} {
        #    set inst_list [concat $inst_list $sub_inst_list]
        #}
    }
    return $inst_list
}

proc dump_signal_value {{modulename .} {type "*"} {level 0} {filename "DEFAULF_FILENAME"}} {
    set fileon 0
    if {$filename != "DEFAULF_FILENAME"} {
        set ptr [open $filename "w"]
        set fileon 1
    }
    set signal_list [get_signal $modulename $type $level]
    foreach signal $signal_list {
        set val [get $signal -radix hex]
        if {$fileon == 1} {
            puts $ptr "$signal: $val"
        }
        puts "$signal: $val"
    }
    if {$fileon == 1} {
        close $ptr
    }
}

proc dump_x {{modulename .} {type "*"} {level 0} {filename "DEFAULF_FILENAME"} } {
    set fileon 0
    if {$filename != "DEFAULF_FILENAME"} {
        set ptr [open $filename "w"]
        set fileon 1
    }
    set list [get_signal $modulename $type $level]
    foreach signal_name $list {
        set val [get  $signal_name -radix bin]
        if {[string match *x* $val] | [string match *z* $val]} {
            puts "$signal_name: $val"
            if {$fileon == 1} {
                puts $ptr "$signal_name: $val"
            }
        }
    }
    if {$fileon == 1} {
        close $ptr
    }
}

proc get_define {objectname} {
    set info [lindex [show -where $objectname] 1]
    return $info
}

proc dump_filelist {{modulename .} {filename "DEFAULF_FILENAME"}} {
    set fileon 0
    if {$filename != "DEFAULF_FILENAME"} {
        set ptr [open $filename "w"]
        set fileon 1
    }
    set file_name_list ""
    set inst_list [get_instance $modulename 0]
    set inst_list "$modulename $inst_list"
    foreach inst_name $inst_list {
        set signal_name [lindex [get_signal $inst_name * 1] 0]
        set file_name [lindex [get_define  $signal_name] 0]
        #puts $inst_name
        #puts $file_name
        if {[lsearch $file_name_list $file_name] == -1} {
            lappend file_name_list $file_name
            puts $file_name
            if {$fileon == 1} {
                puts $ptr $file_name
            } else {
            }
        } else {
            puts "$file_name was repeat"
        }
    }
    if {$fileon == 1} {
        close $ptr
    }
}

proc usage {} {
    puts "==========Usage================"
    puts "disturb_module     <module_name> <disturb_level> <disturb_time>;# disturb the signal defined in module_name and submodule of module_name."
    puts "disturb_signal     <signal_list> <disturb_time>;# disturb the signal  in signal_list."
    puts "get_instance       <modulename .> <level 0> "
    puts "get_signal         <inst_name .> <type *> <level 0>"
    puts "dump_signal_value  <modulename .> <type *> <level 0> <filename DEFAULF_FILENAME>"
    puts "dump_x             <odulename .> <type *> <level 0> <filename DEFAULF_FILENAME > "
    puts "dump_filelist proc <modulename .> <filename DEFAULF_FILENAME> "
}

proc disturb_tutor {} {
    set inst_list [get_instance {.} 3]
    puts "Which module do you want to disturb:"
    set len [llength $inst_list]
    for {set i 0} {$i < $len} {incr i} {
        puts "[format \[%2d\] $i]: [lindex $inst_list $i]"
    }
    puts "Please input the index of the module you want to disturb or press ENTER to continue!(0~[expr $len-1])"
    set choose_num [gets stdin]
    if {$choose_num != "" } {
        disturb_module [lindex $inst_list $choose_num]
    } else {
        usage
    }
}

#puts [info level]
#if {$module_disturbed != ""} {
#    disturb_module $module_disturbed $disturb_time
#} else {
#    disturb_tutor
#}

#for {set index 0} {$index < $disturb_time} {incr index} {
#    disturb_module $module_disturbed
#    run ${delay_time}us
#}

# example
#for {set index 0} {$index < $disturb_time} {incr index} {
#    disturb_module {top.u_pl501_top.u_oam_adapt_top.u_ioam_mac}
#    disturb_module {top.u_pl501_top.u_oam_adapt_top.u_irmux}
#    disturb_module {top.u_pl501_top.u_oam_adapt_top.u_itun}
#    disturb_module {top.u_pl501_top.u_oam_adapt_top.u_iped}
#    disturb_module {top.u_pl501_top.u_oam_adapt_top.u_iadapt_mac}
#    run 200us
#}
