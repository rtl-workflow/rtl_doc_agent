//##################################################################
//Copyright(c) 2017,Huawei Technologies Co.,Ltd.
//All rights reserved
//Project name    :
//File name       :
//Author          : gaea_platform
//Initial-Date    : 2017-06-19 17:08
//Abstract        : func_single_scoreboard
//Called by       :
//##################################################################
//Modification History
//--------------------------
//Revision 1.0  ( 2017-06-19 17:08 ,)
//  ... version info ... 
//v1.0 new
//##################################################################
`ifndef FUNC_SINGLE_SCOREBOARD_SV
`define FUNC_SINGLE_SCOREBOARD_SV

class func_single_scoreboard // GAEA_PLATFORM::CLASSNAME
 extends uvm_component; // GAEA_PLATFORM::TYPE
    base_peek_port  exp_port; // GAEA_PLATFORM::INPORT
    base_peek_port  real_port; // GAEA_PLATFORM::INPORT

    func_single_scoreboard_cfg  cfg;

    uvm_sequence_item expect_queue[$];
    uvm_sequence_item tmp_tran;
    uvm_sequence_item trans_rcv_real,trans_exp_real;
    uvm_sequence_item trans_rcv_req,trans_exp_req;

    int unsigned n_matched    = 0;
    int unsigned n_mismatched = 0;
    int unsigned n_dropped    = 0;
    int unsigned n_expect     = 0;
    int unsigned n_actual     = 0;
    int unsigned n_orphan     = 0;

    extern function new(string name, uvm_component parent = null);
    extern virtual function void build_phase(uvm_phase phase);
    extern virtual task run_phase(uvm_phase phase);
    extern virtual task expect_in_order();
    extern virtual task expect_with_losses();
    extern virtual task expect_out_order();

    extern virtual function void scoreboard_report();
    extern virtual function void report_phase(uvm_phase phase);

    `uvm_component_utils(func_single_scoreboard)
endclass

function func_single_scoreboard::new(string name, uvm_component parent = null);
    super.new(name,parent);
    this.exp_port = new($sformatf("exp_port"), this);
    this.real_port = new($sformatf("real_port"), this);
endfunction

function void func_single_scoreboard::build_phase(uvm_phase phase);
    super.build_phase(phase);
endfunction


task func_single_scoreboard::run_phase(uvm_phase phase);
  super.run_phase(phase); 
  `uvm_info(get_type_name(),"run_phase is called",UVM_MEDIUM);
  fork
      forever
      begin
          exp_port.get(trans_exp_req);
          if(!$cast(trans_exp_real,trans_exp_req.clone()))
              `uvm_fatal(get_type_name(),"the data cast is failed,please check");
          `uvm_info(get_type_name(),$psprintf("expect packet\n%0s",trans_exp_real.sprint()),UVM_MEDIUM)
          expect_queue.push_back(trans_exp_real);
          n_expect++;
      end

      forever
      begin
          real_port.get(trans_rcv_req);
          n_actual++;
          if(!$cast(trans_rcv_real,trans_rcv_req.clone()))
               `uvm_fatal(get_type_name(),"the data cast is failed,please check");
          `uvm_info(get_type_name(),$psprintf("get packet\n%0s",trans_rcv_real.sprint()),UVM_MEDIUM)
          if(cfg.comp_mode==glb_dec::IN_ORDER)
              expect_in_order();
          else if(cfg.comp_mode==glb_dec::WITH_LOSSES)
              expect_with_losses();
          else
              expect_out_order();
      end
  join
endtask

task func_single_scoreboard::expect_in_order();
    if(expect_queue.size()>0)begin
        tmp_tran = expect_queue.pop_front();
         if(trans_rcv_real.compare(tmp_tran))begin 
            n_matched++;
            `uvm_info(get_type_name(),"TRANS Matched in expect_in_order",UVM_LOW);
        end
        else begin
            n_mismatched++;
            `uvm_error(get_type_name(),"TRANS MissMatched in expect_in_order");
            `uvm_info(get_type_name(),$psprintf("the expect TRANS is\n%0s",tmp_tran.sprint()),UVM_LOW)
            `uvm_info(get_type_name(),$psprintf("the actual TRANS is\n%0s",trans_rcv_real.sprint()),UVM_LOW)
        end
    end
    else begin
        `uvm_error(get_type_name(),"receive form DUT,while expect queue is empty");
    end
endtask

task func_single_scoreboard::expect_with_losses();
    while(expect_queue.size()>0)begin
        tmp_tran = expect_queue.pop_front();
        if(trans_rcv_real.compare(tmp_tran))begin 
            n_matched++;
            `uvm_info(get_type_name(),"TRANS Matched in expect_with_losses",UVM_LOW);
            if(this.cfg.mode_switch_en == 1)begin
                this.cfg.comp_mode = glb_dec::IN_ORDER;
            end
            break;
        end
        else begin
            n_dropped++;
            if(expect_queue.size()==0)begin
                n_mismatched++;
                `uvm_error(get_type_name(),"TRANS MissMatched in expect_with_losses");
                `uvm_info(get_type_name(),$psprintf("the actual TRANS is\n%0s",trans_rcv_real.sprint()),UVM_LOW)
            end
            else begin
                //n_dropped++;
                `uvm_info(get_type_name(),"TRANS Losses",UVM_LOW);
                `uvm_info(get_type_name(),$psprintf("the Losses TRANS is\n%0s",tmp_tran.sprint()),UVM_LOW)
            end
        end
    end
endtask

task func_single_scoreboard::expect_out_order();
    for(int i=0; i<expect_queue.size(); i++)
    begin
        tmp_tran=expect_queue[i];
        if(trans_rcv_real.compare(tmp_tran))begin 
            n_matched++;
            `uvm_info(get_type_name(),"TRANS Matched in expect_out_order",UVM_LOW);
            expect_queue.delete(i);
            break;
        end
        else begin
            if(i==expect_queue.size()-1)begin
                n_mismatched++;
                `uvm_error(get_type_name(),"TRANS MissMatched in expect_out_order");
                `uvm_info(get_type_name(),$psprintf("the actual TRANS is\n%0s",trans_rcv_real.sprint()),UVM_LOW)
            end
            else begin
                `uvm_info(get_type_name(),"TRANS is out_order",UVM_LOW);
                continue;
            end
        end
    end
endtask

function void func_single_scoreboard::scoreboard_report();
    string str_tmp = "";
    string str = "";

    str = get_name();
    if (str.len() < 30) str = {str, {(30 - str.len()){" "}}};
    else if (str.len() > 30) str = str.substr(0, 29);

    n_orphan = expect_queue.size();

    $sformat(str_tmp, "\n\n+--------------------------------+------+------+------+------+------+------+\n");
    $sformat(str_tmp, "%s| %s |%s|%s|%s|%s|%s|%s|\n", str_tmp, str,
           "Insert", "Actual", "Matchd", "MsMtch", "Droppd", "Orphan");        
    $sformat(str_tmp, "%s+--------------------------------+------+------+------+------+------+------+\n", str_tmp);

    str = {30{" "}};
    $sformat(str_tmp, "%s| %0s | %04d | %04d | %04d | %04d | %04d | %04d |\n",
                       str_tmp, str, this.n_expect, this.n_actual, this.n_matched, this.n_mismatched,this.n_dropped, this.n_orphan);
    $sformat(str_tmp, "%s+--------------------------------+------+------+------+------+------+------+\n", str_tmp);

    `uvm_info(get_type_name(), $sformatf("%s", str_tmp), UVM_LOW);
    //`uvm_info("TRACE",$psprintf("u_sb:n_expect(%0d),n_actual(%0d),n_matched(%0d),n_mismatched(%0d),n_dropped(%0d)",n_expect,n_actual,n_matched,n_mismatched,n_dropped),UVM_LOW);
    if(n_expect!=n_actual)
    begin
        `uvm_error("TRACE",$psprintf("u_sb:n_expect(%0d),n_actual(%0d),n_matched(%0d),n_mismatched(%0d),n_dropped(%0d),n_dropped(%0d)",n_expect,n_actual,n_matched,n_mismatched,n_dropped,n_orphan));
    end
endfunction

function void func_single_scoreboard::report_phase(uvm_phase phase);
    scoreboard_report();
endfunction: report_phase

`endif

