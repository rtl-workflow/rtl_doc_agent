#!/bin/csh -f

## *****************************************************************************
## Copyright(c) 2016, Hisilicon Technologies Co, Ltd.
## All rights reserved.
##
## PROJECT_GROUP    : SuperBench
## FILENAME         : project.cshrc
## AUTHOR           : SuperBench Team
## VERSION          : 3.0
## ABSTRACT         : project common cshrc file template
## 
## *****************************************************************************

################################################################################
# common setting user do not change it !!!!!
################################################################################
if(`uname` != "Linux") then
    echo "This is a `uname` host, Please run this script in Linux host"
    echo 'ENVIRONMENT NOT CONFIGURED';
    exit(1);
endif

################################################################################
# user setting area
################################################################################
setenv PROJECT_NAME  "SuperBench"

################################################################################
# If user want to use VC, please "ma verificationcompiler", please don't "ma verdi"
# and "ma vcsmx"
################################################################################
if ( `uname -m` == "x86_64" ) then
    # x86
    # hisi
    #ma vcsmx/2017.12sp2
    #ma verdi/2017.12sp2
    #ma xcelium/18.06.001

    # logic
    set vcs_version = vcsmx_201809sp2
    set verdi_version = verdi_201809sp2
    set uvs_uvd_version = uvs_uvd.latest
    #set uvs_version = uvs_2025.03
    #set uvd_version = uvd_2025.03

    source /home/public/cshrc/vcs/cshrc.${vcs_version}
    source /home/public/cshrc/novas/cshrc.${verdi_version}
    #source /home/public/cshrc/hisi/cshrc.${uvs_version}
    #source /home/public/cshrc/hisi/cshrc.${uvd_version}
    source /home/public/cshrc/hisi/cshrc.${uvs_uvd_version}
else
    # arm
endif

set path = ($SUPERBENCH_HOME/demo/digital_data/verification/ut/sv/rx_descrm/bin $path)
set path = ($SUPERBENCH_HOME/demo/digital_data/verification/ut/vmm_12/rx_descrm/bin $path)

# Define LD_LIBRARY_PATH, Novas FSDB Dumper for IES. Tips: Behind 'ma verdi'
setenv LD_LIBRARY_PATH $VERDI_HOME/share/PLI/IUS/LINUX64:$LD_LIBRARY_PATH
setenv LD_LIBRARY_PATH $VERDI_HOME/share/PLI/IUS/LINUX:$LD_LIBRARY_PATH




