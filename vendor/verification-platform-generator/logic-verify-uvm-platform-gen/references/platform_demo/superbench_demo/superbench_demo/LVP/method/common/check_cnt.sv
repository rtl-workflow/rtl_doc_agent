// ---------------------------------------------------------------------
//                  OTN  Verification Project
//======================================================================
// File			:	check_cnt.sv
// Author		:	liutianzhu 48758  
// Email       :  liutianzhu@huawei.com
// Created		:	Wed Sep 09 09:48:12 2009
// Copyright (c)2009 by Huawei. 
// ---------------------------------------------------------------------
// Description	:  This file implement a common count for the result of a checking action
// 
// ---------------------------------------------------------------------

`ifndef CHECK_CNT__SV
`define CHECK_CNT__SV

class check_result_store extends uvm_object; 
    
    string vr_name;
    int    cnt_is_ok;
    int    cnt_is_fail;

    `uvm_object_utils(check_result_store);

endclass:check_result_store

class check_cnt extends uvm_object;

   string              vr_name ;
   check_result_store  result_store_l[$];

   `uvm_object_utils(check_cnt);

   extern function  new(string  name="check_cnt");   

   extern virtual function void add_result(string      vr_name,
                                           bit         vr_is_ok // 1 means ok, 0 means error
                                     );   

   extern virtual function void chk_report();   

endclass:check_cnt

function check_cnt::new(string        name);

    super.new(name);
    this.vr_name = name;
endfunction:new


function void check_cnt::add_result(string        vr_name,
                                    bit           vr_is_ok);

    check_result_store  vr_new_check;
    foreach (result_store_l[i]) begin
        if (result_store_l[i].vr_name == vr_name) begin
            if (vr_is_ok == 1) begin
                result_store_l[i].cnt_is_ok ++;  
            end 
            else begin
                result_store_l[i].cnt_is_fail ++;  
            end
            return;
        end
    end 
    vr_new_check = new();
    vr_new_check.vr_name = vr_name;
    if (vr_is_ok == 1) begin
        vr_new_check.cnt_is_ok ++;  
    end 
    else begin
        vr_new_check.cnt_is_fail ++;  
    end    
    result_store_l.push_back(vr_new_check);

endfunction:add_result

function void check_cnt::chk_report();   
   if (result_store_l.size > 0) begin
       string s = this.vr_name;
       $write("******* Report : %s *******\n",s);
       $write("+---------------------------+------+------+\n");
       $write("| %s |%s|%s|\n", "Checking Action          ",
              "  OK  ", " FAIL ");
       $write("+---------------------------+------+------+\n");
       foreach(result_store_l[i]) begin
            s = result_store_l[i].vr_name;
          if (s.len() < 25) s = {s, {(25 - s.len()){" "}}};
          else if (s.len() > 25) s = s.substr(0, 24);   
          $write("| %s | %04d | %04d |\n", s, result_store_l[i].cnt_is_ok,result_store_l[i].cnt_is_fail);
          $write("+---------------------------+------+------+\n");
       end   
   end 
endfunction:chk_report

`endif

// ---------------------------------------------------------------------
// Modification History
//  $Log: check_cnt.sv,v $
//  Revision 1.1  2010/08/18 01:27:39  l54766
//  no message
//
//  Revision 1.1  2009/09/14 05:56:00  l48758
//  no message
//  
//
// ---------------------------------------------------------------------

 


