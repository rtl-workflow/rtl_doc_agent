
ifneq ($(REGRESS_NAME),$(nostring))
    include $(REGRESS_NAME)/cfg.mk
else
    $(shell $(SUPERBENCH_HOME)/bin/update_makefile)
    include ../cfg/cfg.mk
endif

