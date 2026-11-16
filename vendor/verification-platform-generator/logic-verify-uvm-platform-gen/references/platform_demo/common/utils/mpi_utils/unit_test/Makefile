.PHONY : default compile batch_run run help \
	clean clean_all clean_cov clean_wave clean_log

default: run

##==============================================================================
# Define SIMULATOR, default is VCS if not define it here
##==============================================================================
SIMULATOR          = IES

##==============================================================================
# Add your macros, or other compile parameter here
# e.g.	USER_COMPILE_OPTS := +define+MY_MACRO_1 +define+MY_MACRO_2=123 
##==============================================================================
ifneq ($(SIMULATOR),IES)
USER_COMPILE_OPTS	:= -ntb_opts uvm-1.1 -sverilog \
	                   -timescale=1ns/1ps \
                       +define+UVM_REG_DATA_WIDTH=32 +define+UVM_REG_ADDR_WIDTH=32 \
					   +incdir+$(SUPERBENCH_HOME)/common/basic_class_uvm \
					   +incdir+/data/VIP/CCL/src \
                       $(SUPERBENCH_HOME)/common/basic_class_uvm/basic_class.sv \
					   +incdir+../src \
					   +incdir+../unit_test
else
USER_COMPILE_OPTS	:= -uvm -access rwc \
	                   -timescale 1ns/1ps \
                       +define+UVM_REG_DATA_WIDTH=32 +define+UVM_REG_ADDR_WIDTH=32 \
					   +incdir+$(SUPERBENCH_HOME)/common/basic_class_uvm \
					   +incdir+/data/VIP/CCL/src \
					   $(SUPERBENCH_HOME)/common/basic_class_uvm/basic_class.sv \
					   +incdir+../src \
					   +incdir+../unit_test
endif

##==============================================================================
# Add your own run options here, must obey the syntax of VCS
# e.g.	USER_RUN_OPTS 	:= -assert nopostproc
##==============================================================================
ifneq ($(SIMULATOR),IES)
USER_RUN_OPTS	   := 
else
USER_RUN_OPTS	   := 
endif

##==============================================================================
# Define -full64 switch, pls:
# value  on | off
##==============================================================================
FULL64_SWITCH  	   := on

##==============================================================================
# Please define your VMM planner file name, it must be put in doc direcroty
# and must use .xml as suffix, default is $(ve_name).xml
# e.g. VMM_PLAN_FILE := my_plan.xml
##==============================================================================
VMM_PLAN_FILE 		:=

##==============================================================================
# Define test file name
# Default is empty, then you must specify test file on the command when run
# e.g.	tc := test_file_name
##==============================================================================
tc   := tc_sanity

##==============================================================================
# Define print level for vmm_log, pls:
# value: UVM_NONE | UVM_LOW | UVM_MEDIUM | UVM_HIGH | UVM_FULL | UVM_DEBUG
##==============================================================================
pl   := UVM_NONE

##==============================================================================
# Define wave type, pls:
# value: null | fsdb | vpd
# Default value is "null", then will not dump wave
##==============================================================================
wave := null

##==============================================================================
# Define code coverage switch, pls:
# value  on | off
# Default value is "off", then vcs will not compile for coverage
##==============================================================================
ccov := off

##==============================================================================
# Define specify coverage data dir
# e.g. covdirs := "dir1 dir2"
# Default is empty, then coverage data dir is sim/$(mode)/cov/simv*
##==============================================================================
covdirs :=

##==============================================================================
# Define vcs run mode, pls:
# value: on | off, on:gui; off:cmd
# Default value is "off", then use command line mode
##==============================================================================
gui  := off

##==============================================================================
# Define mode
# the prefix of output directory name. For example, if mode=pacific, the
# corresponding output directories is "pacific/log","pacific/wave",
# "pacific/verdi".
##==============================================================================
mode := base_fun

##==============================================================================
# Define nostring and space
##==============================================================================
nostring:=#space
empty_nostring:=#space
space:=$(nostring) $(nostring)

##==============================================================================
# Define Variables 
##==============================================================================
VE_NAME	     := $(notdir $(shell dirname `pwd` ) )
HOST_NAME	 := $(shell hostname)

ifeq ($(mode),$(nostring))
    $(error Invalid/absent mode on command line: mode=$(mode))
endif

DOC_DIR         := ../doc
TC_DIR          := ./tc
OUTPUT_DIR 	    := ./$(mode)/exec
LOG_DIR 	    := ./$(mode)/log
WAVE_DIR 	    := ./$(mode)/wave
COV_DIR 	    := ./$(mode)/cov
ANN_PLAN_FILE 	:= $(DOC_DIR)/$(VE_NAME)_$(mode)_ann.xml

##==============================================================================
# Compile & Run Options
##==============================================================================
CMP_OPTIONS  := $(USER_COMPILE_OPTS) $(udc) $(USER_TIMESCALE)
RUN_OPTIONS  := $(USER_RUN_OPTS) $(udr)

##==============================================================================
# Define source filelist, src/vmm_src/verdi_src
##==============================================================================
ifneq ($(udl),$(nostring))
    SRC  	 := -f $(udl) 
else
    SRC  	 := -f unit_test.list
endif

##==============================================================================
# Define FULL64_SWITCH options
##==============================================================================
ifeq ($(FULL64_SWITCH),on)
    ifneq ($(SIMULATOR),IES)
        CMP_OPTIONS += -full64
        DVE_OPTS    += -full64
        NOVAS_LIB_B := LINUX64
    else
        CMP_OPTIONS += -64bit
        RUN_OPTIONS += -64bit
    endif
else
    NOVAS_LIB_B := LINUX
endif

##==============================================================================
# Define tc options
##==============================================================================
TC           := $(tc)

##==============================================================================
# Define seed options
##==============================================================================
ifneq ($(seed),$(nostring))
    SEED     := $(seed)
else
    ifneq ($(TC),$(nostring))
        SEED := $(shell str2seed $(TC))
    endif
endif

##==============================================================================
# Define pl options
##==============================================================================
ifneq ($(pl),$(nostring))
    RUN_OPTIONS  += +UVM_VERBOSITY=$(pl)
endif

##==============================================================================
# Define gui options
##==============================================================================
ifeq ($(gui),on)
    ifneq ($(SIMULATOR),IES)
        RUN_OPTIONS += -gui
        DBG_OPTS    ?= -debug_all
    else
        RUN_OPTIONS += -gui -linedebug
    endif
endif

##==============================================================================
# Dump Options
##==============================================================================
export VPDFILE	:= $(WAVE_DIR)/$(TC)_$(SEED).vpd
export FSDBFILE	:= $(WAVE_DIR)/$(TC)_$(SEED).fsdb
export SHMFILE	:= $(WAVE_DIR)/$(TC)_$(SEED).shm
export MEM_SWITCH := off

ifneq ($(SIMULATOR),IES)
    CMP_OPTIONS		+= -P $(NOVAS)/share/PLI/VCS/$(NOVAS_LIB_B)/novas.tab \
				       $(NOVAS)/share/PLI/VCS/$(NOVAS_LIB_B)/pli.a
    ifeq ($(wave),fsdb)
        DBG_OPTS    ?= -debug_pp
        WAVE_FILE 	:= wave_fsdb.do
        TC_DO_FILE 	:= $(TC)_fsdb.do
        RUN_OPTIONS += $(WAVE_DUMP_OPTS) +fsdbfile+$(WAVE_DIR)/$(TC)_$(SEED).fsdb -ucli -do $(OUTPUT_DIR)/pre_wave_$(TC)_$(SEED).do
    else
        ifeq ($(wave),vpd)
            DBG_OPTS	?= -debug_pp
            WAVE_FILE 	:= wave_vpd.do
            TC_DO_FILE 	:= $(TC)_vpd.do
            RUN_OPTIONS += $(WAVE_DUMP_OPTS) +vpdfile+$(WAVE_DIR)/$(TC)_$(SEED).vpd -ucli -do $(OUTPUT_DIR)/pre_wave_$(TC)_$(SEED).do
        else
            DBG_OPTS    ?= -debug
        endif
    endif
else
    ifeq ($(wave),fsdb)
        DBG_OPTS    ?= +debug
        WAVE_FILE 	:= wave_fsdb.do
        TC_DO_FILE 	?= $(tc)_fsdb.do
        TC_SEED_DO_FILE 	:= $(tc)_$(SEED)_fsdb.do
        RUN_OPTIONS += $(WAVE_DUMP_OPTS) +fsdbfile+$(WAVE_DIR)/$(TC)_$(SEED).fsdb -input $(OUTPUT_DIR)/pre_wave_$(TC)_$(SEED).do
    else
        ifeq ($(wave),shm)
            WAVE_FILE 	:= wave_shm.do
            TC_DO_FILE 	:= $(TC)_shm.do
            RUN_OPTIONS += $(WAVE_DUMP_OPTS) -input $(OUTPUT_DIR)/pre_wave_$(TC)_$(SEED).do
        endif
    endif

    ifeq ($(mem),on)
        export MEM_SWITCH ?= on
    else
        export MEM_SWITCH ?= off
    endif	
	
endif

##==============================================================================
# Define coverage directory lists for urg or plan
##==============================================================================
ifneq ($(SIMULATOR),IES)
    ifeq ($(ccov),on)
        CMP_OPTIONS += -cm_dir $(COV_DIR)/simv.vdb
        RUN_OPTIONS += -cm_dir $(COV_DIR)/simv.vdb -cm_name $(TC)_$(SEED)
    endif
    ifeq ($(covdirs), $(nostring))
        COV_DIR_LIST	:= $(wildcard $(COV_DIR)/simv*)
    else
        COV_DIR_LIST 	:= $(foreach dir, $(covdirs), $(wildcard $(dir)/simv*))
    endif
else
    ifeq ($(ccov),on)
        CMP_OPTIONS     += $(USER_COV_OPTS) $(USER_COV_CMP_OPTS)
        RUN_OPTIONS     += $(USER_COV_OPTS) $(USER_COV_RUN_OPTS) \
					       -covoverwrite \
						   -covworkdir $(COV_DIR) -covtest $(TC)_$(SEED)
    endif
endif

##==============================================================================
# Define PLAN Options and PLAN NAME
##==============================================================================
USER_DATA_FILE 	:= $(DOC_DIR)/$(VE_NAME)_$(mode).txt
ifneq ($(wildcard $(USER_DATA_FILE)),$(nostring))
    PLAN_OPTS  	:= -userdata $(USER_DATA_FILE) 
endif
ifneq ($(VMM_PLAN_FILE),$(nostring))
    PLAN_NAME  	:= $(basename $(VMM_PLAN_FILE))
else
    PLAN_NAME  	:= $(VE_NAME)
endif

##==============================================================================
# Other Compile Options 
##==============================================================================
SIM_EXE_FILE := $(OUTPUT_DIR)/uvm_test_simv
CMP_OPTIONS  += -l $(LOG_DIR)/uvm_test.cmp_log
ifneq ($(SIMULATOR),IES)
CMP_OPTIONS  += -Mdir=$(OUTPUT_DIR)/uvm_test_csrc
CMP_OPTIONS	 += -o $(SIM_EXE_FILE)
simulator    := vcs
else
CMP_OPTIONS	 += -nclibdirname $(SIM_EXE_FILE)
IES_CMP_OPTIONS := -c
IES_RUN_OPTIONS := irun -R -nclibdirname
simulator    := irun
endif

##==============================================================================
# Other Run Options 
##==============================================================================
RUN_OPTIONS  += +UVM_TESTNAME=$(TC) -l $(LOG_DIR)/$(TC)_$(SEED).log

ifneq ($(SIMULATOR),IES)
RUN_OPTIONS  += +ntb_random_seed=$(SEED) 
else
RUN_OPTIONS  += -seed $(SEED) 
endif

##==============================================================================
# Get sanity tc list
##==============================================================================
ifeq ($(SANITY_LIST),$(nostring))
    SANITY_LIST := $(notdir $(wildcard $(TC_DIR)/*sanity.sv) )
else
    SANITY_LIST := $(subst /, $(space),$(SANITY_LIST))
    SANITY_LIST := $(addsuffix .sv, $(SANITY_LIST))
endif

CUR_TIME        := `date "+%m/%d-%H:%M:%S"`

##==============================================================================
# Compile and Run targets
##==============================================================================
cmp: compile
compile: make_dir
	@echo "--------------------------------------------------------------------"
	@echo "[STB::Info $(CUR_TIME) compile] Compile TestBench."
	${simulator} $(IES_CMP_OPTIONS) $(CMP_OPTIONS) $(SRC) $(DBG_OPTS)
	@echo "[STB::Info $(CUR_TIME) compile] Done. "
	@echo "===================================================================="

ncrun: batch_run
batch_run: $(SIM_EXE_FILE)
	@echo "--------------------------------------------------------------------"
	@echo "[STB::Info $(CUR_TIME) batch_run] $(TC) is running with Dump_wave_mode = $(wave), Run_code_coverage = $(ccov) ."
	@rm -rf $(OUTPUT_DIR)/pre_wave_$(TC)_$(SEED).do
	@if [ -r $(TC_DO_FILE) ] ;  then printf "source $(TC_DO_FILE)" >> $(OUTPUT_DIR)/pre_wave_$(TC)_$(SEED).do ; else printf "source $(WAVE_FILE)" >> $(OUTPUT_DIR)/pre_wave_$(TC)_$(SEED).do ; fi
	$(IES_RUN_OPTIONS) $(SIM_EXE_FILE) $(RUN_OPTIONS)
	@echo "[STB::Info $(CUR_TIME) batch_run] Done. "
	@echo "===================================================================="

run: compile batch_run

verdi:
	@verdi

make_dir:
	@if [ ! -d $(OUTPUT_DIR) ] 	;  	then mkdir -p $(OUTPUT_DIR) 	; fi
	@if [ ! -d $(LOG_DIR) ] 	;  	then mkdir -p $(LOG_DIR) 		; fi
	@if [ ! -d $(WAVE_DIR) ] 	;  	then mkdir -p $(WAVE_DIR)		; fi
	@if [ ! -d $(COV_DIR) ] 	;  	then mkdir -p $(COV_DIR) 		; fi		

##==============================================================================
# Accessories
##==============================================================================
$(SIM_EXE_FILE):
	@$(MAKE) compile tc=$(TC) mode=$(mode)

plan:
	@hvp annotate $(VMM_PLAN_OPTS) --ss_in=$(DOC_DIR)/$(PLAN_NAME).xml --ss_out=$(ANN_PLAN_FILE) \
		 --covdb "$(COV_DIR_LIST)" $(PLAN_OPTS) -log $(LOG_DIR)/vmm_plan.ann_log -lca
	@strip-xml-comments $(ANN_PLAN_FILE)

cov:
	@dve $(DVE_OPTS) -covdir $(COV_DIR_LIST)

sanity: compile_sanity $(SANITY_LIST)

compile_sanity:
	@if [ $(VMM_TEST_SWITCH)x != "offx" ] ; then $(MAKE) compile tc=$(TC) wave=$(wave) ccov=on gui=$(gui) mode=$(mode) udc="$(udc)" udl=$(udl); fi

%.sv:
	@if [ $(VMM_TEST_SWITCH)x != "offx" ] ; then $(MAKE) batch_run tc=$* wave=$(wave) ccov=on gui=$(gui) mode=$(mode) udr="$(udr)" ; else $(MAKE) run tc=$* wave=$(wave) ccov=on gui=$(gui) mode=$(mode) udc="$(udc)" udr="$(udr)" udl=$(udl); fi

##==============================================================================
# Cleans
##==============================================================================
clean_all:
	@\rm -rf $(WAVE_DIR)/*.fsdb*
	@\rm -rf $(WAVE_DIR)/*.vpd*
	@\rm -rf $(LOG_DIR)/*
	@\rm -rf $(COV_DIR)/*
	@\rm -rf $(OUTPUT_DIR)
	@\rm -rf  *.svshell verdiLog vc_hdrs.h vericomLog work.lib++ .vcsmx_rebuild cm.log vcs.log DVEfiles ucli.* novas*

clean:
	@\rm -rf $(OUTPUT_DIR)
	@\rm -rf  *.svshell verdiLog vc_hdrs.h vericomLog work.lib++ .vcsmx_rebuild cm.log vcs.log DVEfiles ucli.* novas*

clean_cov:
	@\rm -rf $(COV_DIR)/*

clean_wave:
	@\rm -rf $(WAVE_DIR)/*.fsdb*
	@\rm -rf $(WAVE_DIR)/*.vpd*

clean_log:
	@\rm -rf $(LOG_DIR)/*

##==============================================================================
# Help
##==============================================================================
help:
	@echo "===================================================================="
	@echo  " 								    "
	@echo  " USAGE: %make targets {mode=xxxx} <tc=xxx> <seed=xxx> <wave=null|fsdb|vpd> <udl=xxx>"
	@echo  "              <ccov=on|off> <gui=on|off> <udc=xxx> <udr=xxx> <wave=null|fsdb|vpd> <pl=xxx>"
	@echo  " 								    "
	@echo  " compile        => Compile all source code, must use some paremeters as upper "
	@echo  " batch_run      => Run simulation, must use some paremeters as upper, used by regression "
	@echo  " run            => Compile and run simulation, must use some paremeters as upper "
	@echo  " verdi          => Only execute verdi command"
	@echo  " 								    "
	@echo  " --------------------  Accessorial  Targets  ----------------------"
	@echo  " help           => Displays this message. "
	@echo  "								    "
	@echo  " ---------------------- clean commands ----------------------------"
	@echo  " clean_all      => Clean all temproray and result files."
	@echo  " clean          => Clean all temproray files. "
	@echo  " clean_cov      => Clean coverage files. "
	@echo  " clean_wave     => Clean wave files. "
	@echo  " clean_log      => Clean log files. "
	@echo  "								    "
	@echo  "==================================================================="

