//##################################################################
//Copyright(c) 2017,Huawei Technologies Co.,Ltd.
//All rights reserved
//Project name    :
//File name       :
//Author          : gaea_platform
//Initial-Date    : 2017-06-19 17:08
//Abstract        : environment
//Description   :   this class is the basic logic verification property of report
//Called by       :
//##################################################################
//Modification History
//--------------------------
//Revision 1.0  ( 2017-06-19 17:08 ,)
//  ... version info ...
//v1.0 new
//##################################################################
`ifndef GAEA_DISPAY_REPORT
`define GAEA_DISPAY_REPORT

class base_report_server extends uvm_report_server;

    virtual function void summarize(UVM_FILE file=0);
        //int max_quit_count = get_max_quit_count();
        int quit_count = get_quit_count();
        int fatal_count = get_severity_count(UVM_FATAL);
        int error_count = get_severity_count(UVM_ERROR);

        super.summarize(file);
        if (fatal_count > 0 ||error_count >0 || quit_count > 0 ) begin
            f_display(file, testcase_nok());
        end
        else begin
            f_display(file, testcase_ok());
        end
    endfunction

    function string testcase_ok(string prefix = "");
        int ptr;
        string str;

        $sformat(str,"%s%s\033[46;34;1m+------------------------------------------------------------------+\033[0m%s\n",str,prefix,prefix);
        $sformat(str,"%s%s\033[46;34;1m| PPPPPPP               A              SSSSSSSSSSS    SSSSSSSSSSS  |\033[0m%s\n",str,prefix,prefix);
        $sformat(str,"%s%s\033[46;34;1m| PPPPPPPPP            AAA            SSSSSSSSSSSSS  SSSSSSSSSSSSS |\033[0m%s\n",str,prefix,prefix);
        $sformat(str,"%s%s\033[46;34;1m| PP      PP          AA AA           SS         SS  SS         SS |\033[0m%s\n",str,prefix,prefix);
        $sformat(str,"%s%s\033[46;34;1m| PP       PP        AA   AA          SS             SS            |\033[0m%s\n",str,prefix,prefix);
        $sformat(str,"%s%s\033[46;34;1m| PP      PP        AA     AA         SS             SS            |\033[0m%s\n",str,prefix,prefix);
        $sformat(str,"%s%s\033[46;34;1m| PPPPPPPPP        AA       AA        SSSSSSSSSSSS   SSSSSSSSSSSS  |\033[0m%s\n",str,prefix,prefix);
        $sformat(str,"%s%s\033[46;34;1m| PPPPPPP         AAAAAAAAAAAAA        SSSSSSSSSSSS   SSSSSSSSSSSS |\033[0m%s\n",str,prefix,prefix);
        $sformat(str,"%s%s\033[46;34;1m| PP             AAAAAAAAAAAAAAA                 SS             SS |\033[0m%s\n",str,prefix,prefix);
        $sformat(str,"%s%s\033[46;34;1m| PP            AA             AA                SS             SS |\033[0m%s\n",str,prefix,prefix);
        $sformat(str,"%s%s\033[46;34;1m| PP           AA               AA    SS         SS  SS         SS |\033[0m%s\n",str,prefix,prefix);
        $sformat(str,"%s%s\033[46;34;1m| PP          AA                 AA   SSSSSSSSSSSSS  SSSSSSSSSSSSS |\033[0m%s\n",str,prefix,prefix);
        $sformat(str,"%s%s\033[46;34;1m| PP         AA                   AA   SSSSSSSSSSS    SSSSSSSSSSS  |\033[0m%s\n",str,prefix,prefix);
        $sformat(str,"%s%s\033[46;34;1m+------------------------------------------------------------------+\033[0m%s\n",str,prefix,prefix);
        ptr = $fopen("testcase_ok");
        $fdisplay(ptr, str);
        return str;

    endfunction

    function string testcase_pok(string prefix = "");
        string str;

        $sformat(str,"%s%sO------------------------------------------------------------------O%s\n",str,prefix,prefix);
        $sformat(str,"%s%s| PPPPPPP               A              SSSSSSSSSSS    SSSSSSSSSSS  |%s\n",str,prefix,prefix);
        $sformat(str,"%s%s| PPPPPPPPP            AAA            SSSSSSSSSSSSS  SSSSSSSSSSSSS |%s\n",str,prefix,prefix);
        $sformat(str,"%s%s| PP      PP          AA AA           SS         SS  SS         SS |%s\n",str,prefix,prefix);
        $sformat(str,"%s%s| PP       PP        AA   AA          SS             SS            |%s\n",str,prefix,prefix);
        $sformat(str,"%s%s| PP      PP        AA     AA         SS             SS            |%s\n",str,prefix,prefix);
        $sformat(str,"%s%s| PPPPPPPPP        AA       AA        SSSSSSSSSSSS   SSSSSSSSSSSS  |%s\n",str,prefix,prefix);
        $sformat(str,"%s%s| PPPPPPP         AAE ERROR EAA        SSSSSSSSSSSS   SSSSSSSSSSSS |%s\n",str,prefix,prefix);
        $sformat(str,"%s%s| PP             AAAAAAAAAAAAAAA                 SS             SS |%s\n",str,prefix,prefix);
        $sformat(str,"%s%s| PP            AA             AA                SS             SS |%s\n",str,prefix,prefix);
        $sformat(str,"%s%s| PP           AA               AA    SS         SS  SS         SS |%s\n",str,prefix,prefix);
        $sformat(str,"%s%s| PP          AA                 AA   SSSSSSSSSSSSS  SSSSSSSSSSSSS |%s\n",str,prefix,prefix);
        $sformat(str,"%s%s| PP         AA                   AA   SSSSSSSSSSS    SSSSSSSSSSS  |%s\n",str,prefix,prefix);
        $sformat(str,"%s%sO------------------------------------------------------------------O%s\n",str,prefix,prefix);
        return str;

    endfunction

    function string testcase_nok(string prefix = "");
        string str;

        $sformat(str,"%s%s\033[44;31;1m+------------------------------------------------------------------+\033[0m%s\n",str,prefix,prefix);
        $sformat(str,"%s%s\033[44;31;1m| FFFFFFFFFFFF          A                 IIII       LL            |\033[0m%s\n",str,prefix,prefix);
        $sformat(str,"%s%s\033[44;31;1m| FFFFFFFFFFF          AAA                IIII       LL            |\033[0m%s\n",str,prefix,prefix);
        $sformat(str,"%s%s\033[44;31;1m| FF                  AA AA                II        LL            |\033[0m%s\n",str,prefix,prefix);
        $sformat(str,"%s%s\033[44;31;1m| FF                 AA   AA               II        LL            |\033[0m%s\n",str,prefix,prefix);
        $sformat(str,"%s%s\033[44;31;1m| FFFFFFFFFF        AA     AA              II        LL            |\033[0m%s\n",str,prefix,prefix);
        $sformat(str,"%s%s\033[44;31;1m| FFFFFFFFF        AA       AA             II        LL            |\033[0m%s\n",str,prefix,prefix);
        $sformat(str,"%s%s\033[44;31;1m| FF              AAAAAAAAAAAAA            II        LL            |\033[0m%s\n",str,prefix,prefix);
        $sformat(str,"%s%s\033[44;31;1m| FF             AAAAAAAAAAAAAAA           II        LL            |\033[0m%s\n",str,prefix,prefix);
        $sformat(str,"%s%s\033[44;31;1m| FF            AA             AA          II        LL            |\033[0m%s\n",str,prefix,prefix);
        $sformat(str,"%s%s\033[44;31;1m| FF           AA               AA         II        LL            |\033[0m%s\n",str,prefix,prefix);
        $sformat(str,"%s%s\033[44;31;1m| FF          AA                 AA       IIII       LLLLLLLLLLLLL |\033[0m%s\n",str,prefix,prefix);
        $sformat(str,"%s%s\033[44;31;1m| FF         AA                   AA      IIII       LLLLLLLLLLLLL |\033[0m%s\n",str,prefix,prefix);
        $sformat(str,"%s%s\033[44;31;1m+------------------------------------------------------------------+\033[0m%s\n",str,prefix,prefix);
        return str;

    endfunction

endclass
//---==========================  THE END  ==========================---
`endif
