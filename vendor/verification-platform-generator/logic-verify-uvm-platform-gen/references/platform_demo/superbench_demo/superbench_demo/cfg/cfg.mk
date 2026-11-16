default:run
#========================================
# Load environment variable
#========================================
ifneq ($(REGRESS_NAME),$(nostring))
    ifneq ($(wildcard $(REGRESS_NAME)/.project_env.mk),$(nostring))
        include $(REGRESS_NAME)/.project_env.mk
    endif
else
    ifneq ($(wildcard .project_env.mk),$(nostring))
        include .project_env.mk
    endif
endif


#========================================
# User customize variable
#========================================
export TC_LIST = ../../tests/tc.list


#========================================
# Makefile Global Variable
#========================================
export  ram_mode = sim
export  debug_all = off
export  init_en = on
export  init_0 = on
export  init_1 = off
export  init_x = off
export  init_random = off
export  cov_hier = ../cfg/cov_hier.cfg
export  PROJECT_CSHRC = ../cfg/project.cshrc
export  PROJECT_INI = ../cfg/project.ini
export  REGRESS_COMMON = ../cfg/regress_common.ini
export  REGRESS_LIST = ../cfg/regress_list.py
export  PARTCOMP_INI = ../cfg/partcomp.ini
export  PASS_KEYWORD = "PPPPPPP         AAAAAAAAAAAAA        SSSSSSSSSSSS   SSSSSSSSSSSS"
export  FAIL_KEYWORD_LIST = "FAILED","failed","corruption","problem","Error","ERROR"
export  IGNORE_KEYWORD_LIST = "DDRDLPI","TVSENSE"
export  TOOL_ERR_KEYWORD_LIST = "SLI error","core dumped","SIGHUP"
export  udl = ../cfg/tb.f
export  udc = 
export  udr = 
export  lmn = 
export  tc = 
export  seed = 
export  mode = base_fun
export  vmode = 
export  pl = UVM_NONE
export  ccov = off
export  fcov = off
export  assert = off
export  xprop = off
export  prof = off
export  initreg = on
export  wave = null
export  gui = off
export  mem = on
export  covdirs = 
export  simv_tc_s = off
export  analyze_log = on
export  use_local_disk = off
export  SIM_DIR = 
export  SIMULATOR = UVS
export  FULL64_SWITCH = on
export  DB_VE_NAME = 
export  SHARE_SIMV_SWITCH = on
export  METHODOLOGY_SWITCH = UVM
export  PARTITION_COMPILE_SWITCH = off
export  INDIVIDUL_TC_SIM_SWITCH = off
export  USER_PLAN_OPTS = 
export  VERIF_PLAN_FILE = 
export  USER_VERDI_OPTS = $(CMP_OPTIONS) $(SRC) \
                          -disable_protect \
                          -2001 -sv +systemverilogext+sv+v +ignorefileext+.o+.so \
                          -errormax 100000 -syntaxerrormax 200000 -autoendcelldef
export  PROJECT_BSUB_GROUP = 
export  AFTER_TC_PASS_CMD = 
export  AFTER_TC_FAIL_CMD = 
export  PRE_CMP_CMD = 
export  POST_CMP_CMD = 
export  PRE_RUN_CMD = 
export  POST_RUN_CMD = 
export  SKIP_PRE_CMP_SWITCH = off
export  SKIP_POST_CMP_SWITCH = off
export  SKIP_PRE_RUN_SWITCH = off
export  SKIP_SIMULATION_SWITCH = off
export  SKIP_POST_RUN_SWITCH = off
export  REMOVE_LOG_AFTER_TC_PASS = off
export  REMOVE_WAVE_AFTER_TC_PASS = off
export  REMOVE_COV_AFTER_TC_FAIL = off
export  REMOVE_TC_SIM_DIR_AFTER_TC_PASS = off
export  TC_SIM_DIR_REFRESH_SWITCH = off
export  MACROS_DEFINE_OPTS = 
export  USER_TB_TOP = -top tb_top -top TCL_CMD


#========================================
# Makefile Condition Variable
#========================================
ifeq ($(SIMULATOR),VCS)
    export  USER_CMP_OPTS = +define+U_DLY=0.1 \
                            -debug_access+f \
                            +ntb_stop_on_constraint_solver_error=1
    export  USER_RUN_OPTS = 
    export  USER_URG_OPTS = 
    export  PROJECT_CMP_OPTS = -sverilog +v2k +plusarg_save \
                               +verilog2001ext+.v \
                               +define+UVM_REGEX_NO_DPI \
                               +vcs+lic+wait -kdb -lca \
                               +error+100000 +libext+.sv+.v -picarchive \
                               +ntb_solver_array_size_warn=2000000 \
                               +vcs+initreg+random \
                               +define+UVM_NO_VERDI_RECORD \
                               +noportcoerce
    export  PROJECT_RUN_OPTS = +vcs+lic+wait \
                               +ntb_random_seed=$(SEED) \
                               +fsdb+force \
                               +fsdb+gate=off
endif

ifeq ($(SIMULATOR),IES)
    export  USER_CMP_OPTS = 
    export  USER_RUN_OPTS = 
    export  USER_URG_OPTS = 
    export  PROJECT_CMP_OPTS = -sv -v200x -licqueue
    export  PROJECT_RUN_OPTS = -licqueue -seed $(SEED)
endif

ifeq ($(SIMULATOR),XCELIUM)
    export  USER_CMP_OPTS = 
    export  USER_RUN_OPTS = 
    export  USER_URG_OPTS = 
    export  PROJECT_CMP_OPTS = -sv -v200x -licqueue -mccodegen \
                               -warn_multiple_driver
    export  PROJECT_RUN_OPTS = -licqueue -seed $(SEED)
    export  MULTI_CORE_ENGINE = off
    export  MCE_DRYRUN = off
    export  MCE_ANALYSIS = off
    export  MCE_XRAY = off
    export  MCE_CPU_CFG = single-socket
    export  MCE_CPU_ENGINES_CNT = 2
    export  MCE_SPLITS_MAX_CONCURENCY = 4
    export  MCE_TOP = harness.U_BLK_B
    export  MCE_NACC_FILE = ../cfg/mce_nacc.list
endif

ifeq ($(SIMULATOR),UVS)
    export  USER_CMP_OPTS = -define U_DLY=0.1 \
                            -debug f
    export  USER_RUN_OPTS = 
    export  USER_URG_OPTS = 
    export  PROJECT_CMP_OPTS = -define UVM_REGEX_NO_DPI \
                               -disable specify -disable timingcheck -sv \
                               -max_error_cnt 100000 -libsuffix .sv,v \
                               -deposit_initval \
                               -define UVM_NO_VERDI_RECORD \
                               -v2 -emit_obj
    export  PROJECT_RUN_OPTS = -fixed_seed $(SEED) \
                               -usdb force
endif

ifeq ($(SIMULATOR),VCS)
ifeq ($(init_en),on)
ifeq ($(init_0),on)
    export  USER_INIT_RUN_OPTS = +vcs+initreg+0
endif
endif
endif

ifeq ($(SIMULATOR),VCS)
ifeq ($(init_en),on)
ifeq ($(init_1),on)
    export  USER_INIT_RUN_OPTS = +vcs+initreg+1
endif
endif
endif

ifeq ($(SIMULATOR),VCS)
ifeq ($(init_en),on)
ifeq ($(init_x),on)
    export  USER_INIT_RUN_OPTS = +vcs+initreg+x
endif
endif
endif

ifeq ($(SIMULATOR),VCS)
ifeq ($(init_en),on)
ifeq ($(init_random),on)
    export  USER_INIT_RUN_OPTS = +vcs+initreg+random ++vcs+initreg+$(SEED)
endif
endif
endif

ifeq ($(SIMULATOR),UVS)
ifeq ($(init_en),on)
ifeq ($(init_0),on)
    export  USER_INIT_RUN_OPTS = -deposit_initval 0
endif
endif
endif

ifeq ($(SIMULATOR),UVS)
ifeq ($(init_en),on)
ifeq ($(init_1),on)
    export  USER_INIT_RUN_OPTS = -deposit_initval 1
endif
endif
endif

ifeq ($(SIMULATOR),UVS)
ifeq ($(init_en),on)
ifeq ($(init_x),on)
    export  USER_INIT_RUN_OPTS = -deposit_initval x
endif
endif
endif

ifeq ($(SIMULATOR),UVS)
ifeq ($(init_en),on)
ifeq ($(init_random),on)
    export  USER_INIT_RUN_OPTS = -deposit_initval random=$(SEED)
endif
endif
endif

ifeq ($(company),xilinx)
    export  USER_COMPANY_CMP_OPTS = -top glbl
endif

ifeq ($(METHODOLOGY_SWITCH),UVM)
    export  USER_TB_TOP = -top stb_realtime -top tb_top -top TCL_CMD
endif

ifeq ($(METHODOLOGY_SWITCH),VMM)
    export  USER_TB_TOP = -top sd_realtime -top tb_top -top TCL_CMD
endif

ifeq ($(SIMULATOR),VCS)
    export  USER_TIMESCALE = -timescale=1ns/1ps -unit_timescale=1ns/1ps
endif

ifeq ($(SIMULATOR),IES)
    export  USER_TIMESCALE = -timescale 1ns/1ps
endif

ifeq ($(SIMULATOR),XCELIUM)
    export  USER_TIMESCALE = -timescale 1ns/1ps
endif

ifeq ($(SIMULATOR),UVS)
    export  USER_TIMESCALE = -timescale 1ns/1ps -unit_timescale 1ns/1ps
endif

ifeq ($(SIMULATOR),IES)
    export  USER_BT_CMP_OPTS = 
    export  USER_BT_RUN_OPTS = 
endif

ifeq ($(SIMULATOR),VCS)
    export  USER_BT_CMP_OPTS = 
    export  USER_BT_RUN_OPTS = 
endif

ifeq ($(SIMULATOR),VCS)
ifeq ($(FULL64_SWITCH),on)
    export  USER_FULL64_CMP_OPTS = -full64
endif
endif

ifeq ($(SIMULATOR),VCS)
ifeq ($(METHODOLOGY_SWITCH),UVM)
    export  PROJECT_UVM_CMP_OPTS = -ntb_opts uvm-1.1 \
                                   +incdir+/data/VIP/CCL/src \
                                   +incdir+$(SUPERBENCH_HOME)/common/basic_class_uvm \
                                   $(SUPERBENCH_HOME)/common/basic_class_uvm/basic_class.sv
    export  PROJECT_UVM_RUN_OPTS = +UVM_VERBOSITY=$(pl) \
                                   +UVM_TESTNAME=$(tc) \
                                   +tc=$(tc) +mode=$(mode) +seed=$(SEED) \
                                   +uvm_set_severity=*,RNDFLD,UVM_WARNING,UVM_FATAL
endif
endif

ifeq ($(SIMULATOR),VCS)
ifeq ($(METHODOLOGY_SWITCH),VMM)
    export  PROJECT_VMM_CMP_OPTS = +warn=noSV-IIS \
                                   -ntb_opts rvm \
                                   +define+VMM_SB_DS_IN_STDLIB \
                                   +define+VMM_RAL_ADDR_WIDTH=48 \
                                   +define+VMM_RAL_DATA_WIDTH=32 \
                                   +incdir+/data/VIP/CCL/src \
                                   +incdir+$(SUPERBENCH_HOME)/common/basic_class \
                                   $(SUPERBENCH_HOME)/common/basic_class/basic_class.sv
    export  PROJECT_VMM_RUN_OPTS = +vmm_test=$(tc) \
                                   +vmm_log_default=$(pl) \
                                   +vmm_cfg_test=$(tc) +vmm_cfg_mode=$(mode) +seed=$(SEED)
endif
endif

ifeq ($(SIMULATOR),VCS)
ifeq ($(ccov),on)
    export  PROJECT_CCOV_CMP_OPTS = -cm line+fsm+cond
    export  PROJECT_CCOV_RUN_OPTS = -cm line+fsm+cond
endif
endif

ifeq ($(SIMULATOR),VCS)
ifeq ($(fcov),on)
    export  PROJECT_FCOV_CMP_OPTS = +define+FCOV_ON -cm assert +define+COVER_ON
    export  PROJECT_FCOV_RUN_OPTS = 
endif
endif

ifeq ($(SIMULATOR),VCS)
ifeq ($(assert),on)
    export  PROJECT_ASSERT_CMP_OPTS = +define+ASSERT_ON
    export  PROJECT_ASSERT_RUN_OPTS = 
endif
endif

ifeq ($(SIMULATOR),VCS)
ifeq ($(xprop),on)
    export  PROJECT_XPROP_CMP_OPTS = -xprop=tmerge
    export  PROJECT_XPROP_RUN_OPTS = 
endif
endif

ifeq ($(SIMULATOR),VCS)
ifeq ($(prof),on)
    export  PROJECT_PROF_CMP_OPTS = -simprofile
    export  PROJECT_PROF_RUN_OPTS = -simprofile mem+time
endif
endif

ifeq ($(SIMULATOR),VCS)
ifeq ($(prof),mem)
    export  PROJECT_PROF_CMP_OPTS = -simprofile
    export  PROJECT_PROF_RUN_OPTS = -simprofile mem
endif
endif

ifeq ($(SIMULATOR),VCS)
ifeq ($(prof),time)
    export  PROJECT_PROF_CMP_OPTS = -simprofile
    export  PROJECT_PROF_RUN_OPTS = -simprofile time
endif
endif

ifeq ($(SIMULATOR),VCS)
ifeq ($(prof),uvm)
    export  PROJECT_PROF_CMP_OPTS = -simprofile=uvm
    export  PROJECT_PROF_RUN_OPTS = 
endif
endif

ifeq ($(SIMULATOR),VCS)
ifeq ($(wave),fsdb)
    export  PROJECT_WAVE_CMP_OPTS = -debug_access+f
    export  PROJECT_WAVE_RUN_OPTS = 
endif
endif

ifeq ($(SIMULATOR),VCS)
ifeq ($(wave),vpd)
    export  PROJECT_WAVE_CMP_OPTS = -debug_access+f
    export  PROJECT_WAVE_RUN_OPTS = 
endif
endif

ifeq ($(SIMULATOR),VCS)
ifeq ($(gui),on)
    export  PROJECT_GUI_CMP_OPTS = -debug_access+all -kdb -lca
    export  PROJECT_GUI_RUN_OPTS = -gui=verdi
endif
endif

ifeq ($(SIMULATOR),VCS)
ifeq ($(mem),on)
    export  PROJECT_MEM_CMP_OPTS = +vcsd +memcbk +vpi
    export  PROJECT_MEM_RUN_OPTS = 
endif
endif

ifeq ($(SIMULATOR),VCS)
ifeq ($(mem),all)
    export  PROJECT_MEM_CMP_OPTS = -debug_region=cell+lib +vcsd +memcbk +vpi
    export  PROJECT_MEM_RUN_OPTS = 
endif
endif

ifeq ($(SIMULATOR),VCS)
ifeq ($(fgp),on)
    export  PROJECT_FPG_CMP_OPTS = -fgp
    export  PROJECT_FPG_RUN_OPTS = -fgp=num_threads:6
endif
endif

ifeq ($(SIMULATOR),IES)
ifeq ($(FULL64_SWITCH),on)
    export  USER_FULL64_CMP_OPTS = -64bit
endif
endif

ifeq ($(SIMULATOR),IES)
ifeq ($(METHODOLOGY_SWITCH),UVM)
    export  PROJECT_UVM_CMP_OPTS = -uvm \
                                   +incdir+/data/VIP/CCL/src \
                                   +incdir+$(SUPERBENCH_HOME)/common/basic_class_uvm \
                                   $(SUPERBENCH_HOME)/common/basic_class_uvm/basic_class.sv
    export  PROJECT_UVM_RUN_OPTS = +UVM_VERBOSITY=$(pl) \
                                   +UVM_TESTNAME=$(tc) \
                                   +tc=$(tc) +mode=$(mode) +seed=$(SEED) \
                                   +uvm_set_severity=*,RNDFLD,UVM_WARNING,UVM_FATAL
endif
endif

ifeq ($(SIMULATOR),IES)
ifeq ($(METHODOLOGY_SWITCH),VMM)
    export  PROJECT_VMM_CMP_OPTS = +define+VMM_SB_DS_IN_STDLIB \
                                   +define+VMM_RAL_ADDR_WIDTH=48 \
                                   +define+VMM_RAL_DATA_WIDTH=32 \
                                   +incdir+/data/VIP/CCL/src \
                                   +incdir+$(SUPERBENCH_HOME)/common/basic_class \
                                   $(SUPERBENCH_HOME)/common/basic_class/basic_class.sv
    export  PROJECT_VMM_RUN_OPTS = +vmm_test=$(tc) \
                                   +vmm_log_default=$(pl) \
                                   +vmm_cfg_test=$(tc) +vmm_cfg_mode=$(mode) +seed=$(SEED)
endif
endif

ifeq ($(SIMULATOR),IES)
ifeq ($(ccov),on)
    export  PROJECT_CCOV_CMP_OPTS = -coverage b:e:f:t
    export  PROJECT_CCOV_RUN_OPTS = -covoverwrite
endif
endif

ifeq ($(SIMULATOR),IES)
ifeq ($(fcov),on)
    export  PROJECT_FCOV_CMP_OPTS = -coverage u +define+FCOV_ON +define+COVER_ON
    export  PROJECT_FCOV_RUN_OPTS = -covoverwrite
endif
endif

ifeq ($(SIMULATOR),IES)
ifeq ($(assert),on)
    export  PROJECT_ASSERT_CMP_OPTS = +define+ASSERT_ON
    export  PROJECT_ASSERT_RUN_OPTS = 
endif
endif

ifeq ($(SIMULATOR),IES)
ifeq ($(initreg),on)
    export  PROJECT_INITREG_CMP_OPTS = -initreg0 -initmem0
    export  PROJECT_INITREG_RUN_OPTS = -initreg0 -initmem0
endif
endif

ifeq ($(SIMULATOR),IES)
ifeq ($(xprop),on)
    export  PROJECT_XPROP_CMP_OPTS = -xfile ../cfg/xfile.cfg
    export  PROJECT_XPROP_RUN_OPTS = 
endif
endif

ifeq ($(SIMULATOR),IES)
ifeq ($(prof),on)
    export  PROJECT_PROF_CMP_OPTS = -iprof
    export  PROJECT_PROF_RUN_OPTS = -iprof
endif
endif

ifeq ($(SIMULATOR),IES)
ifeq ($(prof),mem)
    export  PROJECT_PROF_CMP_OPTS = -mem_iprof
    export  PROJECT_PROF_RUN_OPTS = -mem_iprof
endif
endif

ifeq ($(SIMULATOR),IES)
ifeq ($(prof),time)
    export  PROJECT_PROF_CMP_OPTS = -iprof
    export  PROJECT_PROF_RUN_OPTS = -iprof
endif
endif

ifeq ($(SIMULATOR),IES)
ifeq ($(wave),fsdb)
    export  PROJECT_WAVE_CMP_OPTS = -access +rwc
    export  PROJECT_WAVE_RUN_OPTS = 
endif
endif

ifeq ($(SIMULATOR),IES)
ifeq ($(wave),shm)
    export  PROJECT_WAVE_CMP_OPTS = -access +rwc
    export  PROJECT_WAVE_RUN_OPTS = 
endif
endif

ifeq ($(SIMULATOR),IES)
ifeq ($(gui),on)
    export  PROJECT_GUI_CMP_OPTS = -linedebug
    export  PROJECT_GUI_RUN_OPTS = -gui
endif
endif

ifeq ($(SIMULATOR),IES)
ifeq ($(mem),on)
    export  PROJECT_MEM_CMP_OPTS = 
    export  PROJECT_MEM_RUN_OPTS = 
endif
endif

ifeq ($(MCE_XRAY),on)
ifeq ($(MULTI_CORE_ENGINE),off)
    export  PROJECT_MCE_XARY_RUN_OPTS = -loadvpisim $(XCELIUM_HOME)/tools/lib/64bit/mce_xray64.so:mce_xray_init
endif
endif

ifeq ($(SIMULATOR),XCELIUM)
ifeq ($(MULTI_CORE_ENGINE),on)
ifeq ($(MCE_DRYRUN),on)
    export  PROJECT_MCE_BUILED_CMP_OPTS = -mce -mce_dryrun
    export  PROJECT_MCE_RUN_OPTS = -mce
endif
endif
endif

ifeq ($(SIMULATOR),XCELIUM)
ifeq ($(MULTI_CORE_ENGINE),on)
ifneq ($(MCE_DRYRUN),on)
    export  PROJECT_MCE_BUILED_CMP_OPTS = -mce \
                                          -mce_cpu_configuration $(MCE_CPU_CFG) \
                                          -mce_cpu_engines_count $(MCE_CPU_ENGINES_CNT) \
                                          -mce_top $(MCE_TOP) \
                                          -mce_splits_max_concurrency $(MCE_SPLITS_MAX_CONCURENCY) \
                                          -mce_access_suppress_errors 1 \
                                          -mce_initial_block_to_value 1 \
                                          -mce_nacc_file $(MCE_NACC_FILE) \
                                          -mce_default_work_lib worklib
    export  PROJECT_MCE_RUN_OPTS = -mce
endif
endif
endif

ifeq ($(SIMULATOR),XCELIUM)
ifeq ($(MULTI_CORE_ENGINE),on)
ifeq ($(MCE_ANALYSIS),on)
ifneq ($(MCE_DRYRUN),on)
    export  MCE_PIE_VIP_CMP_OPTS = -mce_pie -mce_vpi_analysis
endif
endif
endif
endif

ifeq ($(SIMULATOR),XCELIUM)
ifeq ($(FULL64_SWITCH),on)
    export  USER_FULL64_CMP_OPTS = -64bit
    export  USER_FULL64_RUN_OPTS = -64bit
endif
endif

ifeq ($(SIMULATOR),XCELIUM)
ifeq ($(METHODOLOGY_SWITCH),UVM)
    export  PROJECT_UVM_CMP_OPTS = -uvm \
                                   +incdir+/data/VIP/CCL/src \
                                   +incdir+$(SUPERBENCH_HOME)/common/basic_class_uvm \
                                   $(SUPERBENCH_HOME)/common/basic_class_uvm/basic_class.sv
    export  PROJECT_UVM_RUN_OPTS = +UVM_VERBOSITY=$(pl) \
                                   +UVM_TESTNAME=$(tc) \
                                   +tc=$(tc) +mode=$(mode) +seed=$(SEED) \
                                   +uvm_set_severity=*,RNDFLD,UVM_WARNING,UVM_FATAL
endif
endif

ifeq ($(SIMULATOR),XCELIUM)
ifeq ($(METHODOLOGY_SWITCH),VMM)
    export  PROJECT_VMM_CMP_OPTS = +define+VMM_SB_DS_IN_STDLIB \
                                   +define+VMM_RAL_ADDR_WIDTH=48 \
                                   +define+VMM_RAL_DATA_WIDTH=32 \
                                   +incdir+/data/VIP/CCL/src \
                                   +incdir+$(SUPERBENCH_HOME)/common/basic_class \
                                   $(SUPERBENCH_HOME)/common/basic_class/basic_class.sv
    export  PROJECT_VMM_RUN_OPTS = +vmm_test=$(tc) \
                                   +vmm_log_default=$(pl) \
                                   +vmm_cfg_test=$(tc) +vmm_cfg_mode=$(mode) +seed=$(SEED)
endif
endif

ifeq ($(SIMULATOR),XCELIUM)
ifeq ($(ccov),on)
    export  PROJECT_CCOV_CMP_OPTS = -coverage b:e:f:t
    export  PROJECT_CCOV_RUN_OPTS = -covoverwrite -write_metrics
endif
endif

ifeq ($(SIMULATOR),XCELIUM)
ifeq ($(fcov),on)
    export  PROJECT_FCOV_CMP_OPTS = -coverage u +define+FCOV_ON +define+COVER_ON
    export  PROJECT_FCOV_RUN_OPTS = -covoverwrite -write_metrics
endif
endif

ifeq ($(SIMULATOR),XCELIUM)
ifeq ($(assert),on)
    export  PROJECT_ASSERT_CMP_OPTS = +define+ASSERT_ON
    export  PROJECT_ASSERT_RUN_OPTS = 
endif
endif

ifeq ($(SIMULATOR),XCELIUM)
ifeq ($(initreg),on)
    export  PROJECT_INITREG_CMP_OPTS = -initreg0 -initmem0
    export  PROJECT_INITREG_RUN_OPTS = -initreg0 -initmem0
endif
endif

ifeq ($(SIMULATOR),XCELIUM)
ifeq ($(xprop),on)
    export  PROJECT_XPROP_CMP_OPTS = -xfile ../cfg/xfile.cfg
    export  PROJECT_XPROP_RUN_OPTS = 
endif
endif

ifeq ($(SIMULATOR),XCELIUM)
ifeq ($(prof),on)
    export  PROJECT_PROF_CMP_OPTS = -xprof
    export  PROJECT_PROF_RUN_OPTS = -xprof
endif
endif

ifeq ($(SIMULATOR),XCELIUM)
ifeq ($(prof),mem)
    export  PROJECT_PROF_CMP_OPTS = -mem_xprof
    export  PROJECT_PROF_RUN_OPTS = -mem_xprof
endif
endif

ifeq ($(SIMULATOR),XCELIUM)
ifeq ($(prof),time)
    export  PROJECT_PROF_CMP_OPTS = -xprof
    export  PROJECT_PROF_RUN_OPTS = -xprof
endif
endif

ifeq ($(SIMULATOR),XCELIUM)
ifeq ($(wave),fsdb)
    export  PROJECT_WAVE_CMP_OPTS = -access +rwc
    export  PROJECT_WAVE_RUN_OPTS = 
endif
endif

ifeq ($(SIMULATOR),XCELIUM)
ifeq ($(wave),shm)
    export  PROJECT_WAVE_CMP_OPTS = -access +rwc
    export  PROJECT_WAVE_RUN_OPTS = 
endif
endif

ifeq ($(SIMULATOR),XCELIUM)
ifeq ($(wave),ida)
    export  PROJECT_WAVE_CMP_OPTS = -access +rwc  -createdebugdb
    export  PROJECT_WAVE_RUN_OPTS = 
endif
endif

ifeq ($(SIMULATOR),XCELIUM)
ifeq ($(gui),on)
    export  PROJECT_GUI_CMP_OPTS = -linedebug
    export  PROJECT_GUI_RUN_OPTS = -gui
endif
endif

ifeq ($(SIMULATOR),XCELIUM)
ifeq ($(mem),on)
    export  PROJECT_MEM_CMP_OPTS = 
    export  PROJECT_MEM_RUN_OPTS = 
endif
endif

ifeq ($(SIMULATOR),UVS)
ifeq ($(METHODOLOGY_SWITCH),UVM)
    export  PROJECT_UVM_CMP_OPTS = -uvm1.1 -pstat \
                                   $(SUPERBENCH_HOME)/common/basic_class_uvm/stb_realtime.sv
    export  PROJECT_UVM_RUN_OPTS = +UVM_VERBOSITY=$(pl) \
                                   +UVM_TESTNAME=$(tc) \
                                   +tc=$(tc) +mode=$(mode) +seed=$(SEED) \
                                   +uvm_set_severity=*,RNDFLD,UVM_WARNING,UVM_FATAL
endif
endif

ifeq ($(SIMULATOR),UVS)
ifeq ($(METHODOLOGY_SWITCH),VMM)
    export  PROJECT_VMM_CMP_OPTS = -define VMM_SB_DS_IN_STDLIB \
                                   -define VMM_RAL_ADDR_WIDTH=48 \
                                   -define VMM_RAL_DATA_WIDTH=32 \
                                   $(SUPERBENCH_HOME)/common/basic_class_uvm/stb_realtime.sv
    export  PROJECT_VMM_RUN_OPTS = +vmm_test=$(tc) \
                                   +vmm_log_default=$(pl) \
                                   +vmm_cfg_test=$(tc) +vmm_cfg_mode=$(mode) +seed=$(SEED)
endif
endif

ifeq ($(SIMULATOR),UVS)
ifeq ($(ccov),on)
    export  PROJECT_CCOV_CMP_OPTS = -cov stmt,cond,fsm,tgl
    export  PROJECT_CCOV_RUN_OPTS = -cov stmt,cond,fsm,tgl
endif
endif

ifeq ($(SIMULATOR),UVS)
ifeq ($(fcov),on)
    export  PROJECT_FCOV_CMP_OPTS = -define FCOV_ON -cov group  -define COVER_ON
    export  PROJECT_FCOV_RUN_OPTS = -cov group
endif
endif

ifeq ($(SIMULATOR),UVS)
ifeq ($(assert),on)
    export  PROJECT_ASSERT_CMP_OPTS = -define ASSERT_ON -cov assert
    export  PROJECT_ASSERT_RUN_OPTS = -cov assert
endif
endif

ifeq ($(SIMULATOR),UVS)
ifeq ($(initreg),on)
    export  PROJECT_INITREG_CMP_OPTS = 
    export  PROJECT_INITREG_RUN_OPTS = 
endif
endif

ifeq ($(SIMULATOR),UVS)
ifeq ($(xprop),on)
    export  PROJECT_XPROP_CMP_OPTS = 
    export  PROJECT_XPROP_RUN_OPTS = 
endif
endif

ifeq ($(SIMULATOR),UVS)
ifeq ($(prof),mem)
    export  PROJECT_PROF_CMP_OPTS = 
    export  PROJECT_PROF_RUN_OPTS = 
endif
endif

ifeq ($(SIMULATOR),UVS)
ifeq ($(prof),time)
    export  PROJECT_PROF_CMP_OPTS = 
    export  PROJECT_PROF_RUN_OPTS = 
endif
endif

ifeq ($(SIMULATOR),UVS)
ifeq ($(prof),uvm)
    export  PROJECT_PROF_CMP_OPTS = 
    export  PROJECT_PROF_RUN_OPTS = 
endif
endif

ifeq ($(SIMULATOR),UVS)
ifeq ($(wave),usdb)
    export  PROJECT_WAVE_CMP_OPTS = 
    export  PROJECT_WAVE_RUN_OPTS = 
endif
endif

ifeq ($(SIMULATOR),UVS)
ifeq ($(gui),on)
    export  PROJECT_GUI_CMP_OPTS = 
    export  PROJECT_GUI_RUN_OPTS = 
endif
endif

ifeq ($(SIMULATOR),UVS)
ifeq ($(mem),on)
    export  PROJECT_MEM_CMP_OPTS = 
    export  PROJECT_MEM_RUN_OPTS = 
endif
endif

ifeq ($(SIMULATOR),UVS)
ifeq ($(mem),all)
    export  PROJECT_MEM_CMP_OPTS = 
    export  PROJECT_MEM_RUN_OPTS = 
endif
endif

ifeq ($(SIMULATOR),UVS)
ifeq ($(fgp),on)
    export  PROJECT_FPG_CMP_OPTS = 
    export  PROJECT_FPG_RUN_OPTS = 
endif
endif

ifneq (,$(findstring base_fun,$(mode)))
    export  ram_mode = sim
endif

ifneq (,$(findstring env_debug,$(mode)))
    export  ram_mode = sim
endif

ifeq ($(SIMULATOR),VCS)
ifneq (,$(findstring env_debug,$(mode)))
    export  PROJECT_MODE_CMP_OPTS = +define+ENV_DEBUG +define+V_ENV_DEBUG +define+TB_SELF_TEST
endif
endif

ifeq ($(SIMULATOR),UVS)
ifneq (,$(findstring env_debug,$(mode)))
    export  PROJECT_MODE_CMP_OPTS = -define ENV_DEBUG -define V_ENV_DEBUG -define TB_SELF_TEST
endif
endif

ifneq (,$(findstring sim_reg,$(mode)))
    export  ram_mode = sim
    export  mode_select = rtl_sim
endif

ifneq (,$(findstring asic_reg,$(mode)))
    export  ram_mode = asic
    export  mode_select = rtl_sim
endif

ifneq (,$(findstring fpga_reg,$(mode)))
    export  ram_mode = fpga
    export  mode_select = rtl_sim
endif

ifneq (,$(findstring power,$(mode)))
    export  ram_mode = asic
    export  mode_select = rtl_sim
    export  PARTITION_COMPILE_SWITCH = off
endif

ifeq ($(SIMULATOR),VCS)
ifneq (,$(findstring power,$(mode)))
    export  PROJECT_MODE_CMP_OPTS = -debug_access+all \
                                    -debug_region=cell+lib +vcsd +memcbk +vpi
    export  PROJECT_MODE_RUN_OPTS = +fsdb+skip_cell_instance=0
endif
endif

ifeq ($(SIMULATOR),UVS)
ifneq (,$(findstring power,$(mode)))
    export  PROJECT_MODE_CMP_OPTS = -debug all \
                                    -debug_cell -debug_lib -debug
endif
endif

ifneq (,$(findstring net,$(mode)))
    export  ram_mode = asic
    export  mode_select = syn_sim
    export  PARTITION_COMPILE_SWITCH = off
endif

ifeq ($(SIMULATOR),VCS)
ifneq (,$(findstring net,$(mode)))
    export  PROJECT_MODE_CMP_OPTS = -debug_access+pp \
                                    -debug_region=cell+lib
endif
endif

ifeq ($(SIMULATOR),UVS)
ifneq (,$(findstring net,$(mode)))
    export  PROJECT_MODE_CMP_OPTS = -debug \
                                    -debug_cell -debug_lib
endif
endif

ifneq (,$(findstring wc,$(mode)))
    export  ram_mode = asic
    export  mode_select = post_sim
    export  PARTITION_COMPILE_SWITCH = off
endif

ifeq ($(SIMULATOR),VCS)
ifneq (,$(findstring wc,$(mode)))
    export  PROJECT_MODE_CMP_OPTS = +define+WC_SDF
endif
endif

ifeq ($(SIMULATOR),UVS)
ifneq (,$(findstring wc,$(mode)))
    export  PROJECT_MODE_CMP_OPTS = -define WC_SDF
endif
endif

ifneq (,$(findstring bc,$(mode)))
    export  ram_mode = asic
    export  mode_select = post_sim
    export  PARTITION_COMPILE_SWITCH = off
endif

ifeq ($(SIMULATOR),VCS)
ifneq (,$(findstring bc,$(mode)))
    export  PROJECT_MODE_CMP_OPTS = +define+BC_SDF
endif
endif

ifeq ($(SIMULATOR),UVS)
ifneq (,$(findstring bc,$(mode)))
    export  PROJECT_MODE_CMP_OPTS = -define BC_SDF
endif
endif

ifeq ($(SIMULATOR),VCS)
ifeq ($(ram_mode),sim)
    export  PROJECT_RAM_MODE_CMP_OPTS = +define+SIM_RAM_V2
endif
endif

ifeq ($(SIMULATOR),VCS)
ifeq ($(ram_mode),asic)
endif
endif

ifeq ($(SIMULATOR),VCS)
ifeq ($(ram_mode),fpga)
endif
endif

ifeq ($(SIMULATOR),VCS)
ifeq ($(mode_select),rtl_sim)
    export  PROJECT_RTL_SIM_CMP_OPTS = +nospecify +notimingcheck
endif
endif

ifeq ($(SIMULATOR),VCS)
ifeq ($(mode_select),syn_sim)
    export  PROJECT_SYN_SIM_CMP_OPTS = +nospecify +notimingcheck
endif
endif

ifeq ($(SIMULATOR),VCS)
ifeq ($(mode_select),post_sim)
    export  PROJECT_SYN_SIM_CMP_OPTS = +define+SDF_SIM \
                                       +no_notifier \
                                       +neg_tchk \
                                       -negdelay \
                                       +overlap \
                                       +no_pulse_msg \
                                       +transport_path_delays \
                                       +transport_int_delays \
                                       +multisource_int_delays \
                                       +pulse_int_e/0 \
                                       +pulse_int_r/0 \
                                       +pulse_e/100 \
                                       +pulse_r/60 \
                                       +tchk+edge+warn \
                                       +sdfverbose \
                                       -sdfretain -xlrm alt_retain \
                                       -sdfretain=warning \
                                       +warn=noSDFCOM_SWC \
                                       +warn=noSDFCOM_IWSBA \
                                       +warn=noSDFCOM_RLTPD
endif
endif

ifeq ($(SIMULATOR),UVS)
ifeq ($(ram_mode),sim)
    export  PROJECT_RAM_MODE_CMP_OPTS = -define SIM_RAM_V2
endif
endif

ifeq ($(SIMULATOR),UVS)
ifeq ($(ram_mode),asic)
endif
endif

ifeq ($(SIMULATOR),UVS)
ifeq ($(ram_mode),fpga)
endif
endif

ifeq ($(SIMULATOR),UVS)
ifeq ($(mode_select),rtl_sim)
    export  PROJECT_RTL_SIM_CMP_OPTS = -disable specify -disable timingcheck
endif
endif

ifeq ($(SIMULATOR),UVS)
ifeq ($(mode_select),syn_sim)
    export  PROJECT_SYN_SIM_CMP_OPTS = -disable specify -disable timingcheck
endif
endif

ifeq ($(SIMULATOR),UVS)
ifeq ($(mode_select),post_sim)
    export  PROJECT_SYN_SIM_CMP_OPTS = -define SDF_SIM \
                                       -disable notifier \
                                       -neg_tchk \
                                       -negdelay \
                                       -transport_path_delays \
                                       -transport_int_delays \
                                       -msid \
                                       -pulse_int_e/0 \
                                       -pulse_int_r/0 \
                                       -pulse_e/100 \
                                       -pulse_r/60
endif
endif

ifeq ($(SIMULATOR),VCS)
ifeq ($(PARTITION_COMPILE_SWITCH),on)
    export  PARTITION_MODE = manu_part_three_step
    export  SYNOPSYS_SIM_SETUP = synopsys_sim_$(mode).setup
    export  TOPCFG_FILE = ../cfg/topcfg.v
    export  FAST_PART_COMP = -fastpartcomp=j4
    export  PARTCOMP_DIR = -partcomp_dir=$(OUTPUT_DIR)/$(worklib)_partitionlib
endif
endif

ifeq ($(SIMULATOR),VCS)
ifeq ($(PARTITION_COMPILE_SWITCH),on)
ifeq ($(PARTITION_MODE),auto_part)
    export  USER_PART_CMP_OPTS = -pcmakeprof -partcomp $(FAST_PART_COMP) $(PARTCOMP_DIR)
endif
endif
endif

ifeq ($(SIMULATOR),VCS)
ifeq ($(PARTITION_COMPILE_SWITCH),on)
ifeq ($(PARTITION_MODE),manu_part_two_step)
    export  USER_TB_TOP = -top topcfg
    export  USER_PART_CMP_OPTS = -pcmakeprof -partcomp $(FAST_PART_COMP) $(TOPCFG_FILE) $(PARTCOMP_DIR)
endif
endif
endif

ifeq ($(SIMULATOR),VCS)
ifeq ($(PARTITION_COMPILE_SWITCH),on)
ifeq ($(PARTITION_MODE),manu_part_three_step)
    export  USER_PARTITION_CFG = topcfg
    export  USER_TB_TOP = -top topcfg
    export  PNAME_LIST = DUT
    export  USER_DUT_VLOG_OPTS = -f ../cfg/dut.f
    export  USER_ENV_CMP_OPTS = -f ../cfg/env.f
    export  USER_ELAB_OPTS = -pcmakeprof -partcomp $(FAST_PART_COMP) $(PARTCOMP_DIR)
endif
endif
endif

ifeq ($(SIMULATOR),IES)
ifeq ($(PARTITION_COMPILE_SWITCH),on)
    export  USER_TB_TOP = 
    export  pname = common
    export  USER_GEN_HREF_OPTS = -f ../cfg/ies_prim.f -f ../cfg/ies_incr.f -primtop blk_b -top tb_top \
                                 -genhref ies_href.txt
endif
endif

ifeq ($(SIMULATOR),IES)
ifeq ($(pname),common)
    export  USER_PRIM_CMP_OPTS = -f ../cfg/ies_prim.f -top blk_b \
                                 -href ies_href.txt
endif
endif

ifeq ($(SIMULATOR),IES)
ifeq ($(PARTITION_COMPILE_SWITCH),on)
ifeq ($(mode),duttc)
    export  USER_INCR_CMP_OPTS = -f ../cfg/ies_incr.f -top tb_top -top stb_realtime
    export  PNAME_LIST = common
endif
endif
endif

ifeq ($(SIMULATOR),XCELIUM)
ifeq ($(PARTITION_COMPILE_SWITCH),on)
    export  USER_TB_TOP = 
    export  pname = common
    export  USER_GEN_HREF_OPTS = -f ../cfg/tb.f -primtop blk_b -top tb_top \
                                 -genhref ies_href.txt
endif
endif

ifeq ($(SIMULATOR),XCELIUM)
ifeq ($(pname),common)
    export  USER_PRIM_CMP_OPTS = -f ../cfg/ies_prim.f  -top blk_b \
                                 -href ies_href.txt
endif
endif

ifeq ($(SIMULATOR),XCELIUM)
ifeq ($(PARTITION_COMPILE_SWITCH),on)
ifeq ($(mode),duttc)
    export  USER_INCR_CMP_OPTS = -f ../cfg/ies_incr.f -top tb_top -top stb_realtime
    export  PNAME_LIST = common
endif
endif
endif

ifeq ($(SIMULATOR),UVS)
ifeq ($(PARTITION_COMPILE_SWITCH),on)
    export  PARTITION_MODE = manu_part_three_step
    export  UVS_SETUP_FILE = uvs.setup
    export  TOPCFG_FILE = 
    export  FAST_PART_COMP = 
    export  PARTCOMP_DIR = 
endif
endif

ifeq ($(SIMULATOR),UVS)
ifeq ($(PARTITION_COMPILE_SWITCH),on)
ifeq ($(PARTITION_MODE),manu_part_three_step)
    export  USER_PARTITION_CFG = 
    export  USER_TB_TOP = -top tb_top
    export  PNAME_LIST = DUT ENV
    export  USER_DUT_VLOG_OPTS = -filelist ../cfg/dut.f -work dut_lib
    export  USER_ENV_VLOG_OPTS = -filelist ../cfg/env.f -work env_lib
    export  USER_ELAB_OPTS = 
endif
endif
endif

ifeq ($(SIMULATOR),GLX)
ifeq ($(PARTITION_COMPILE_SWITCH),on)
    export  PARTITION_MODE = manu_part_three_step
    export  XEPIC_SIM_SETUP = xepic_sim.setup
    export  TOPCFG_FILE = 
    export  FAST_PART_COMP = 
    export  PARTCOMP_DIR = 
endif
endif

ifeq ($(SIMULATOR),GLX)
ifeq ($(PARTITION_COMPILE_SWITCH),on)
ifeq ($(PARTITION_MODE),manu_part_three_step)
    export  USER_PARTITION_CFG = 
    export  USER_TB_TOP = -top tb_top
    export  PNAME_LIST = DUT ENV
    export  USER_DUT_VLOG_OPTS = -f ../cfg/glx_dut.f -work dut_lib
    export  USER_ENV_VLOG_OPTS = -f ../cfg/glx_env.f -work env_lib
    export  USER_ELAB_OPTS = 
endif
endif
endif


#========================================
# Generate Compile and Simulation Option
#========================================
export CMP_OPTIONS = $(PROJECT_CMP_OPTS) $(USER_FULL64_CMP_OPTS) $(PROJECT_UVM_CMP_OPTS) $(PROJECT_VMM_CMP_OPTS) $(PROJECT_CCOV_CMP_OPTS) $(PROJECT_FCOV_CMP_OPTS) $(PROJECT_ASSERT_CMP_OPTS) $(PROJECT_XPROP_CMP_OPTS) $(PROJECT_PROF_CMP_OPTS) $(PROJECT_WAVE_CMP_OPTS) $(PROJECT_GUI_CMP_OPTS) $(PROJECT_MEM_CMP_OPTS) $(PROJECT_FPG_CMP_OPTS) $(PROJECT_INITREG_CMP_OPTS) $(PROJECT_MCE_BUILED_CMP_OPTS) $(MCE_PIE_VIP_CMP_OPTS) $(PROJECT_MODE_CMP_OPTS) $(PROJECT_RAM_MODE_CMP_OPTS) $(PROJECT_RTL_SIM_CMP_OPTS) $(PROJECT_SYN_SIM_CMP_OPTS) $(USER_CMP_OPTS) $(USER_COMPANY_CMP_OPTS) $(USER_BT_CMP_OPTS) $(USER_PART_CMP_OPTS) $(USER_TIMESCALE) $(MACROS_DEFINE_OPTS) $(USER_TB_TOP) $(udc)

export RUN_OPTIONS = $(PROJECT_RUN_OPTS) $(PROJECT_UVM_RUN_OPTS) $(PROJECT_VMM_RUN_OPTS) $(PROJECT_CCOV_RUN_OPTS) $(PROJECT_FCOV_RUN_OPTS) $(PROJECT_ASSERT_RUN_OPTS) $(PROJECT_XPROP_RUN_OPTS) $(PROJECT_PROF_RUN_OPTS) $(PROJECT_WAVE_RUN_OPTS) $(PROJECT_GUI_RUN_OPTS) $(PROJECT_MEM_RUN_OPTS) $(PROJECT_FPG_RUN_OPTS) $(PROJECT_INITREG_RUN_OPTS) $(PROJECT_MCE_XARY_RUN_OPTS) $(PROJECT_MCE_RUN_OPTS) $(USER_FULL64_RUN_OPTS) $(PROJECT_MODE_RUN_OPTS) $(USER_RUN_OPTS) $(USER_INIT_RUN_OPTS) $(USER_BT_RUN_OPTS) $(udr)

export VERDI_OPTIONS = $(USER_VERDI_OPTS)



#========================================
# Regression Configure Option
#========================================
ifeq ($(regress),on)
    export  PRE_REGRESSION_CMD = 
    export  POST_REGRESSION_CMD = 
    export  PRE_GEN_REPORT_CMD = 
    export  POST_GEN_REPORT_CMD = 
    export  PRE_MERGE_CMD = 
    export  POST_MERGE_CMD = 
    export  PRE_PLAN_CMD = 
    export  POST_PLAN_CMD = 
    export  PRE_CHECKOUT_CMD = 
    export  POST_CHECKOUT_CMD = 
    export  GLOBAL_COMPILE_OPTS = ccov=on fcov=on assert=on wave=null
    export  LOCAL_COMPILE_SWITCH = off
    export  SKIP_PRIM_COMPILE_SWITCH = off
    export  SKIP_COMPILE_SWITCH = off
    export  SKIP_RERUN_COMPILE_SWITCH = off
    export  GLOBAL_RUN_OPTS = ccov=on fcov=on assert=on  wave=null
    export  GLOBAL_RERUN_OPTS = wave=fsdb pl=UVM_DEBUG
    export  TOOL_ERR_WITH_RERUN_OPTS = off
    export  REMOVE_LOG_AFTER_TC_PASS = off
    export  REMOVE_WAVE_AFTER_TC_PASS = on
    export  REMOVE_COV_AFTER_TC_FAIL = on
    export  REMOVE_TC_SIM_DIR_AFTER_TC_PASS = off
    export  REGRESS_MODE = donau
    export  RR_SCHEDULING = on
    export  RERUN_SWITCH = off
    export  MAX_FAIL_NUM_FOR_ALL_TC = 
    export  MAX_FAIL_NUM_FOR_SINGLE_TC = 
    export  MAX_RERUN_WAVEFORM_NUM_FOR_ALL_TC = 100
    export  MAX_RERUN_WAVEFORM_NUM_FOR_SINGLE_TC = 10
    export  MAX_NUM_FOR_REGRESS_FOLDER = 3
    export  MAX_JOBS_NUM_FOR_BSUB = 500
    export  MAX_JOBS_NUM_FOR_OWNED_MACHINE = 16
    export  USER_BSUB_OPTS = -A lj1 -q normal
    export  JOB_SUBMIT_INTERVAL = 0.5
    export  WATCHDOG_TIME_FOR_SINGLE_TC = 
    export  use_local_disk = off
    export  NAS_DISK_LIMIT = 3
    export  LOCAL_MODE = 
    export  COPY_LOG_FROM_LOCAL_AFTER_TC_FAIL = 
    export  DELETE_LOG_FROM_LOCAL_AFTER_TC_PASS = 
    export  INSTANCE_NAME = 
    export  FCOV_INSTANCE_SWITCH = off
    export  INCREMENTAL_MERGE_SWITCH = on
    export  REMOVE_COVERAGE_AFTER_MERGE_SUCCESS = off
    export  PACKET_COVERAGE_AFTER_MERGE_SUCCESS = off
    export  EXPLORER = gvim
    export  SEND_MAIL_ENABLE = on
    export  SEND_USER_LIST = $(USER)
    export  LOCAL_GEN_REPORT_SWITCH = off
    export  CM_TOOL = svn
    export  SVN_PATH = 
    export  RTL_CO_URL = 
    export  VE_CO_URL = 
    export  SCRIPTS_CO_URL = 
    export  OTHER_CO_URLS = 
    export  REGRESSION_WORKCOPY_DIR = 
    export  REGRESSION_WORKCOPY_SIM_DIR = 
endif


#========================================
# path : $SUPERBENCH_HOME/template/prj_adm/partcomp.mk
#========================================
include $(SUPERBENCH_HOME)/template/prj_adm/partcomp.mk


#========================================
# include the main makefile
# path : $SUPERBENCH_HOME/template/prj_adm/sim_v6.mk
#========================================
include $(SUPERBENCH_HOME)/template/prj_adm/sim_v6.mk
#========================================
# include ide.mk
# path : $REGRESS_NAME/ide.mk
#========================================
ifneq ($(REGRESS_NAME), $(nostring))
    ifneq ($(wildcard $(REGRESS_NAME)/ide.mk), $(nostring))
        include $(REGRESS_NAME)/ide.mk
    endif
else
    ifneq ($(wildcard ../cfg/ide.mk), $(nostring))
        include ../cfg/ide.mk
    endif
endif
