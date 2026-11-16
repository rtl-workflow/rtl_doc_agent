#*******************************************************************************
source ../../sim/scripts/disturb_new.tcl
fsdbSuppress "module_base="  "altsyncram" ;# suppress the basic ram sim model of ALTERA
fsdbSuppress "module_base="  "altsyncram" ;# suppress the basic ram sim model of ALTERA
fsdbSuppress "module_base="  "RAMB16"     ;# suppress the basic ram sim model of XILINX
fsdbSuppress "module_base="  "RAMB16BWER" ;# suppress the basic ram sim model of XILINX
fsdbSuppress "module_base="  "RAMB18E1"   ;# suppress the basic ram sim model of XILINX
fsdbSuppress "module_base="  "RAMB36E1"   ;# suppress the basic ram sim model of XILINX
fsdbSuppress "module_base="  "RAMB8BWER"  ;# suppress the basic ram sim model of XILINX
fsdbSuppress "module_base="  "GTP_DRM18K" ;# suppress the basic ram sim model of PANGO
fsdbSuppress "module_base="  "GTP_DRM18K_E1" ;# suppress the basic ram sim model of PANGO
fsdbSuppress "module_base="  "GTP_DRM36K_E1" ;# suppress the basic ram sim model of PANGO
fsdbSuppress "module_base="  "GTP_RAM64X1DP" ;# suppress the basic ram sim model of PANGO
fsdbSuppress "module_base="  "GTP_RAM32X1DP" ;# suppress the basic ram sim model of PANGO

fsdbDumpMDA
fsdbDumpSVA
fsdbDumpflush

fsdbDumpvars "top.DUT_A.u_tnv1t502_a_fpga_top.u_cbb_top" ; #只抓取top.DUT_A路径下面的波形

run 100us #等待业务流打通
for {set times 0} {$times < 10} {incr times} { #控制加扰次数为10次
    disturb_module {top.DUT_A.u_tnv1t502_a_fpga_top.u_cbb_top} #控制加扰模块
    run 100us #等待100us，看在这100us内数据流能不能恢复
}
run
